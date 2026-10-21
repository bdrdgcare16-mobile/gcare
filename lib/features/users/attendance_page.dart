import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/features/users/background_tasks.dart';
import 'package:serv_app/services/tracking_service.dart';
import 'package:serv_app/services/tracking_events.dart';
import 'package:serv_app/services/tracking_payload.dart';
import 'package:serv_app/services/tracking_post_result.dart';
import 'package:serv_app/services/connectivity_service.dart';
import 'package:serv_app/services/tracking_retry_policy.dart';
import 'package:serv_app/main_common.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/utils/performance_logger.dart';
import 'package:serv_app/utils/office_presence.dart';
import 'package:serv_app/utils/battery_optimization.dart';
import 'package:serv_app/debug/native_gps_diagnostic.dart';
import 'package:permission_handler/permission_handler.dart'
    hide ServiceStatus;
import 'package:android_intent_plus/android_intent.dart';

void _log(String message) {
  if (kDebugMode) {
    debugPrint('[${DateTime.now().toIso8601String()}] $message');
  }
}

/// Diagnostic fix logger: accuracy, fix timestamp (device-local ISO),
/// capture age, and mocked flag. geolocator's Position model does not
/// surface the originating provider (GPS/NETWORK/FUSED) to Dart at all -
/// noted explicitly so a "200m" reading can't be mistaken for
/// network-provider output without evidence. Use NativeGpsDiagnostic for
/// provider-level comparison.
void _logGpsFix(String label, Position p) {
  if (!kDebugMode) return;
  final age = DateTime.now().difference(p.timestamp);
  debugPrint('[GPS_FIX] $label: accuracy=${p.accuracy.toStringAsFixed(1)}m, '
      'fixTimestamp=${p.timestamp.toIso8601String()}, age=${age.inSeconds}s, '
      'mocked=${p.isMocked}, provider=unavailable via geolocator');
}

// ==== Colors ====
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ---- API base ----
final String _apiBase = ApiService.baseUrl;

// ---- Local persistence keys ----
const String _kCheckedInKeyBase = 'att_checked_in_';
const String _kCheckInDateKeyBase = 'att_checkin_date_';
const String _kCheckInTimeKeyBase = 'att_checkin_time_';

// ---- Check-in time cache keys ----
const String _kCheckInTimeCacheKeyBase = 'attendance_checkin_';

class ShiftTimes {
  final TimeOfDay start;
  final TimeOfDay end;
  const ShiftTimes(this.start, this.end);
}

class _Branch {
  final String name;
  final double lat;
  final double lng;
  final double radius;
  const _Branch(this.name, this.lat, this.lng, this.radius);
}

// Result of the employee assigned-office lookup: the office geo config (when
// one is configured) plus the company-level geofencing policy reported by the
// backend. [lookupOk] is false when no endpoint answered authoritatively.
// [legacyCompatibilityMode] marks legacy tenants whose historical implicit
// radius enforcement still applies when an office config exists.
class _AssignedGeo {
  final _Branch? branch;
  final bool geofencingEnabled;
  final bool legacyCompatibilityMode;
  final bool lookupOk;
  const _AssignedGeo(this.branch, this.geofencingEnabled,
      this.legacyCompatibilityMode, this.lookupOk);
}

class AttendanceScreen extends StatefulWidget {
  final String employeeDocId;
  final Map<String, dynamic>? preloadedUserInfo;

  const AttendanceScreen({
    super.key,
    required this.employeeDocId,
    this.preloadedUserInfo,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  // TEMPORARY DIAGNOSTIC ONLY: guards _runGpsDiagnosticComparison against
  // duplicate/overlapping taps. Unrelated to check-in/check-out state.
  bool _gpsDiagnosticRunning = false;
  bool isFaceRegistered = false;
  bool isShiftSelected = false;
  bool isCheckedIn = false;
  bool isTimerRunning = false;
  bool _locationPermissionGranted = false;

  // Device location-service state detected at page open. null = not yet
  // checked (treated as enabled for UI to avoid a false flash).
  bool? _locationServiceEnabled;
  bool _preciseLocationGranted = true;
  bool _locationDialogOpen = false;
  bool _suppressLocationDialog = false;
  StreamSubscription<ServiceStatus>? _pageGpsStatusSub;
  bool _isLoadingUserInfo = false;
  List<Map<String, String>>? _cachedReasons;
  bool _reasonsLoading = false;
  // 'auth' | 'forbidden' | 'network' — set when the last reasons fetch
  // failed so _pickReason can show the correct error instead of the
  // misleading "No reasons configured" empty state.
  String? _reasonsError;
  bool _isAttendanceStatusLoading = false;
  bool _hasAttendanceApiConfirmed = false;
  // Non-null when the last status fetch failed (401/403/5xx/network). The
  // attendance state is then UNKNOWN - the UI must not present "not checked
  // in" and must not offer Check-In as an action.
  String? _attendanceStatusError;

  // ✅ SAFETY: Cache the user info future to prevent duplicate calls
  Future<void>? _loadUserInfoFuture;

  // ✅ FIX: prevent multiple checkout taps / duplicate API calls
  bool _checkoutInProgress = false;
  _AssignedGeo? _cachedGeo;

  DateTime? _lastStatusFetch;

  // Track check-in and check-out times (for UI labels only)
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  // DateTime? _lastStatusFetch;

  // Format time for display (HH:MM AM/PM)
  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  String userName = "";
  String userId = ""; // empid
  String dept = "";
  String location = "";

  String selectedShift = "Shift";
  String companyId = "";
  bool shiftClicked = false;

  Timer? _timer;

  int totalSeconds = 0;
  String hours = "00";
  String minutes = "00";
  String seconds = "00";

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _authInProgress = false;

  // remember the source of today's check-in ('biometric' | 'manual')
  String _checkInSource = '';

  // Optional legacy foreground tracker
  TrackingService? _tracking;

  // 🔹 cache the dynamic shift times loaded from the assigned-shift API
  ShiftTimes? _shiftTimes;
  String? _shiftLoadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ SAFETY: Use preloaded user info when available, otherwise load normally
    if (widget.preloadedUserInfo != null) {
      debugPrint('[Attendance] Using preloaded user info from home page');
      _applyPreloadedUserInfo(widget.preloadedUserInfo!);
    } else {
      debugPrint('[Attendance] No preloaded info, loading auth/me API');
      _loadUserInfoFuture = _loadUserInfo();
    }

    // Load cached check-in time first, then call attendance API
    if (_loadUserInfoFuture != null) {
      _loadUserInfoFuture!.then((_) => _loadCachedCheckInAndStartTimer());
    } else {
      _loadCachedCheckInAndStartTimer();
    }

    _checkUserFaceRegistration();
    // Detect device Location ON/OFF immediately - before the employee taps
    // an attendance button - and keep the state live while the page is
    // open so toggling Location updates the warning/buttons in place.
    _checkLocationStatusOnOpen();
    if (!kIsWeb) {
      // getServiceStatusStream is unsupported on web (throws
      // UnsupportedError). The browser has no OS-level location toggle -
      // permission state alone is checked by _checkLocationStatusOnOpen.
      _pageGpsStatusSub =
          Geolocator.getServiceStatusStream().listen((status) {
        debugPrint('[GPS] service status changed on attendance page: $status');
        _checkLocationStatusOnOpen();
      }, onError: (_) {});
    }
  }

  // Load cached check-in time and start timer immediately if found
  Future<void> _loadCachedCheckInAndStartTimer() async {
    debugPrint('[Cache] Loading cached check-in time...');

    // First try to get cached check-in time
    final cachedCheckInTime = await _getCachedCheckInTime();

    if (cachedCheckInTime != null && _isCachedTimeForToday(cachedCheckInTime)) {
      debugPrint('[Cache] Using cached check-in time');

      // Set check-in time from cache and start timer immediately
      _checkInTime = cachedCheckInTime;
      _checkOutTime = null;

      // Start timer with cached time
      _startWorkTimer();

      // Then call API to sync with server in background
      _loadTodayStatus();
    } else {
      debugPrint(
          '[Cache] No valid cached check-in time found, loading from API');

      // No cached time, load from API normally
      await _restoreCheckInFromPrefs();
      _loadTodayStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageGpsStatusSub?.cancel();
    _timer?.cancel();
    _trackingRetryTimer?.cancel();
    _trackingRecoverySub?.cancel();
    _trackingRecoverySub = null;
    _warmupRetryTimer?.cancel();
    // Force: dispose must never defer - the acquisition result is moot
    // once the page is gone, so the provider subscription dies now.
    _stopGpsWarmup(force: true);
    _gpsSharedStream?.close();
    // TEMPORARY DIAGNOSTIC: if a raw GPS_PROVIDER capture is still running
    // when this page is disposed, stop it immediately rather than let it
    // run for up to 25s against a gone widget. Fire-and-forget: the native
    // side (NativeGpsDiagnostic.onDetachedFromEngine) already tears it down
    // too, this just does it sooner if only the page (not the engine) went
    // away.
    if (_gpsDiagnosticRunning) {
      unawaited(NativeGpsDiagnostic.cancelRawGpsCapture());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Stop warming while the page is not visible (battery).
      _stopGpsWarmup();
    }
    if (state == AppLifecycleState.resumed) {
      // Recheck Location ON/OFF on return (e.g. from Location Settings) -
      // dismisses the warning, refreshes button state and starts warm-up.
      _checkLocationStatusOnOpen();
      if (_authInProgress) return;

      // ✅ SAFETY: Use cached future to prevent duplicate auth/me calls
      if (_loadUserInfoFuture != null) {
        _loadUserInfoFuture!.then((_) => _loadTodayStatus());
      } else {
        _restoreCheckInFromPrefs().then((_) => _loadTodayStatus());
      }
    }
  }

  Map<String, String> _authHeaders() {
    final token = CompanyData.token;
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();
  String _key(String base) => '$base$userId';

  Future<void> _saveCheckInToPrefs({DateTime? at}) async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    final now = at ?? DateTime.now();
    final ymd =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final hms =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    await prefs.setBool(_key(_kCheckedInKeyBase), true);
    await prefs.setString(_key(_kCheckInDateKeyBase), ymd);
    await prefs.setString(_key(_kCheckInTimeKeyBase), hms);
  }

  Future<void> _clearCheckInFromPrefs() async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    await prefs.remove(_key(_kCheckedInKeyBase));
    await prefs.remove(_key(_kCheckInDateKeyBase));
    await prefs.remove(_key(_kCheckInTimeKeyBase));
    // Also drop the cached check-in time so a failed/rolled-back check-in
    // cannot resurface as a ghost "In:" time on the next page load.
    await _clearCheckInCache();
  }

  Future<void> _restoreCheckInFromPrefs() async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    final locallyCheckedIn = prefs.getBool(_key(_kCheckedInKeyBase)) ?? false;
    final dateStr = prefs.getString(_key(_kCheckInDateKeyBase));
    final timeStr = prefs.getString(_key(_kCheckInTimeKeyBase));
    if (!locallyCheckedIn || dateStr == null || timeStr == null) return;

    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (dateStr != todayStr) {
      await _clearCheckInFromPrefs();
      return;
    }

    try {
      final hms = timeStr.split(':');
      final inDT = DateTime(
        today.year,
        today.month,
        today.day,
        int.parse(hms[0]),
        int.parse(hms[1]),
        int.parse(hms[2]),
      );

      // Set _checkInTime first - this is the source of truth
      _checkInTime = inDT;
      _checkOutTime = null;

      final diff = DateTime.now().difference(inDT).inSeconds;
      final startSeconds = diff > 0 ? diff : 0;

      if (!mounted) return;
      setState(() {
        isCheckedIn = true;
        isTimerRunning = true;
        totalSeconds = startSeconds;
        hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
        minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
        seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          totalSeconds++;
          hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
          minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
          seconds = (totalSeconds % 60).toString().padLeft(2, '0');
        });
      });
    } catch (_) {
      // If parsing fails, don't start timer - clear invalid state
      await _clearCheckInFromPrefs();
      if (!mounted) return;
      setState(() {
        isCheckedIn = false;
        isTimerRunning = false;
        totalSeconds = 0;
        hours = "00";
        minutes = "00";
        seconds = "00";
        _checkInTime = null;
        _checkOutTime = null;
      });
    }
  }

  // ---- Check-in time cache methods ----
  String _getCheckInCacheKey() {
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return '${_kCheckInTimeCacheKeyBase}${userId}_$dateKey';
  }

  Future<void> _cacheCheckInTime(DateTime checkInTime) async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    final cacheKey = _getCheckInCacheKey();
    final checkInString = checkInTime.toIso8601String();

    debugPrint('[Cache] Storing check-in time');
    await prefs.setString(cacheKey, checkInString);
  }

  Future<DateTime?> _getCachedCheckInTime() async {
    if (userId.isEmpty) return null;
    final prefs = await _prefs();
    final cacheKey = _getCheckInCacheKey();
    final cachedString = prefs.getString(cacheKey);

    if (cachedString != null && cachedString.isNotEmpty) {
      try {
        final cachedTime = DateTime.parse(cachedString);
        debugPrint('[Cache] Found cached check-in time');
        return cachedTime;
      } catch (e) {
        debugPrint('[Cache] Error parsing cached time: $e');
        // Clear invalid cache entry
        await prefs.remove(cacheKey);
      }
    } else {
      debugPrint('[Cache] No cached check-in time found');
    }
    return null;
  }

  Future<void> _clearCheckInCache() async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    final cacheKey = _getCheckInCacheKey();

    debugPrint('[Cache] Clearing check-in time cache');
    await prefs.remove(cacheKey);
  }

  // ---- Check if cached time is for today ----
  bool _isCachedTimeForToday(DateTime cachedTime) {
    final today = DateTime.now();
    final isToday = cachedTime.year == today.year &&
        cachedTime.month == today.month &&
        cachedTime.day == today.day;
    debugPrint('[Cache] Checking if cached time is for today: $isToday');
    return isToday;
  }

  // ✅ SAFETY: Apply preloaded user info without API calls
  void _applyPreloadedUserInfo(Map<String, dynamic> userData) {
    try {
      final profile = (userData['employeeProfile'] is Map<String, dynamic>)
          ? (userData['employeeProfile'] as Map<String, dynamic>)
          : <String, dynamic>{};

      setState(() {
        userName = (userData['name'] ?? profile['name'] ?? "") as String;
        userId = (userData['empid'] ?? profile['empid'] ?? "") as String;
        dept = (profile['dept'] ?? userData['dept'] ?? "") as String;
        location =
            (profile['location'] ?? userData['location'] ?? "") as String;
        selectedShift = (profile['shiftGroup'] ??
            userData['shiftGroup'] ??
            "Shift") as String;

        final hasShift = selectedShift.isNotEmpty && selectedShift != "Shift";
        shiftClicked = hasShift;
        isShiftSelected = hasShift;
      });

      debugPrint('[Attendance] Applied preloaded user info');

      // Load dependent data only after user info is applied
      _loadShiftTimes();
      _restoreCheckInFromPrefs();
      _loadTodayStatus();
    } catch (e) {
      debugPrint('[Attendance] Error applying preloaded user info: $e');
      setState(() {
        userName = "(error)";
        userId = widget.employeeDocId;
        dept = "";
        location = "";
      });
      _restoreCheckInFromPrefs();
    }
  }

  Future<void> _loadUserInfo() async {
    // Prevent duplicate calls - if already loading, just wait for completion
    if (_isLoadingUserInfo) {
      debugPrint(
          '[Attendance] User info already in progress, waiting for completion');
      return;
    }

    _isLoadingUserInfo = true;
    final startTime = DateTime.now();

    try {
      final token = CompanyData.token;
      debugPrint('[Attendance] Loading user info from /auth/me');

      if (token.isEmpty) {
        debugPrint('[Attendance] No token available for auth/me');
        setState(() {
          userName = "(no token)";
          userId = widget.employeeDocId;
          dept = "";
          location = "";
        });
        await _restoreCheckInFromPrefs();
        return;
      }

      final url = Uri.parse('${ApiService.baseUrl}/auth/me');
      final res =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'AttendanceScreen',
        endpoint: '/auth/me',
        startTime: startTime,
        endTime: endTime,
        statusCode: res.statusCode,
        itemCount: res.statusCode == 200 ? 1 : 0,
      );

      debugPrint('[Attendance] Auth/me response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final profile = (data['employeeProfile'] is Map<String, dynamic>)
            ? (data['employeeProfile'] as Map<String, dynamic>)
            : <String, dynamic>{}; // Fix generic syntax

        // Debug logging to see the actual response structure

        setState(() {
          userName = (data['name'] ?? profile['name'] ?? "") as String;
          userId = (data['empid'] ?? profile['empid'] ?? "") as String;
          dept = (profile['dept'] ?? data['dept'] ?? "") as String;
          location = (profile['location'] ?? data['location'] ?? "") as String;
          selectedShift = (profile['shiftGroup'] ??
              data['shiftGroup'] ??
              "Shift") as String;
          companyId =
              (data['companyId'] ?? profile['companyId'] ?? "") as String;

          final hasShift = selectedShift.isNotEmpty && selectedShift != "Shift";
          shiftClicked = hasShift;
          isShiftSelected = hasShift;
        });

        debugPrint('[Attendance] User info loaded');

        // OPTIMIZATION: Load dependent data in parallel where possible
        await Future.wait([
          _loadShiftTimes(),
          _restoreCheckInFromPrefs(),
        ]);
        await _loadTodayStatus();
      } else {
        debugPrint('[Attendance] Auth/me failed: ${res.statusCode}');
        setState(() {
          userName = "(unknown)";
          userId = widget.employeeDocId;
          dept = "";
          location = "";
        });
        await _restoreCheckInFromPrefs();
      }
    } catch (e) {
      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'AttendanceScreen',
        endpoint: '/auth/me',
        startTime: startTime,
        endTime: endTime,
        statusCode: 0,
        error: e.toString(),
      );
      debugPrint('[Attendance] Auth/me error occurred');
      setState(() {
        userName = "(error)";
        userId = widget.employeeDocId;
        dept = "";
        location = "";
      });
      await _restoreCheckInFromPrefs();
    } finally {
      _isLoadingUserInfo = false;
      // Reset cached future to allow future retries if needed
      _loadUserInfoFuture = null;
    }
  }

  Future<void> _loadTodayStatus() async {
    final startTime = DateTime.now();
    debugPrint('[Attendance] Page opened at: $startTime');
    debugPrint('[Attendance] Local checkInTime: $_checkInTime');

    // Set loading state to prevent showing wrong timer values
    if (!mounted) return;
    setState(() {
      _isAttendanceStatusLoading = true;
      _hasAttendanceApiConfirmed = false;
      _attendanceStatusError = null;
    });

    if (_lastStatusFetch != null &&
        DateTime.now().difference(_lastStatusFetch!) <
            const Duration(minutes: 2)) {
      debugPrint(
          '[Attendance] Using cached status (last fetch < 2 minutes ago)');
      if (!mounted) return;
      setState(() {
        _isAttendanceStatusLoading = false;
        _hasAttendanceApiConfirmed = true;
      });
      return;
    }

    // Prevent repeated API calls (safe protection)
    final token = CompanyData.token;
    if (userId.isEmpty || token.isEmpty) {
      debugPrint('[Attendance] No userId or token available');
      if (!mounted) return;
      setState(() {
        _isAttendanceStatusLoading = false;
        _hasAttendanceApiConfirmed = true;
      });
      return;
    }

    final url = Uri.parse('${ApiService.baseUrl}/attendance/live');
    debugPrint('[Attendance] Fetching attendance status from API');

    bool confirmed = false;
    try {
      final res =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'AttendanceScreen',
        endpoint: '/attendance/live',
        startTime: startTime,
        endTime: endTime,
        statusCode: res.statusCode,
        itemCount:
            res.statusCode == 200 ? (jsonDecode(res.body) as List).length : 0,
      );

      debugPrint('[Attendance] API status: ${res.statusCode}');

      if (res.statusCode != 200) {
        // A non-200 (auth/expired-token/server error) is a data-loading
        // failure, NOT proof the employee hasn't checked in. Keep whatever
        // state the local cache restored, mark the status as unverified so
        // Check-In is not offered, and surface an error to the user.
        if (mounted) {
          setState(() {
            _attendanceStatusError =
                'Status unavailable (${res.statusCode})';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not verify attendance status (server error '
                '${res.statusCode}). Showing last known state.',
              ),
            ),
          );
        }
        return;
      }

      _lastStatusFetch = DateTime.now();

      final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      confirmed = true;
      final wantEmp = userId.trim().toLowerCase();
      final me = list.firstWhere(
        (e) =>
            (e['empid']?.toString().trim().toLowerCase() ?? '') == wantEmp,
        orElse: () => const {},
      );
      if (me.isEmpty) {
        debugPrint(
            '[Attendance] /live returned ${list.length} rows, none matched empid=$userId');
      }

      final checkIn = (me['checkIn']) as String?;
      final checkOut = (me['checkOut']) as String?;
      _checkInSource =
          (me['checkInSource'] ?? me['source'] ?? '').toString().toLowerCase();

      print("CHECK IN TIME: $_checkInTime");
      print("CHECK OUT TIME: $_checkOutTime");

      if (checkOut != null && checkOut.isNotEmpty) {
        // User already checked out - clear state and show not checked in
        debugPrint('[Attendance] User already checked out, clearing cache');
        _resetTimerAndState();
        await _clearCheckInFromPrefs();
        await _clearCheckInCache(); // Clear cache on checkout
        if (!mounted) return;
        setState(() {
          isCheckedIn = false;
          _checkInSource = '';
        });
        // Checked-in state just resolved to false - warm-up may have been
        // skipped at page open while stale prefs said checked-in.
        unawaited(_maybeStartGpsWarmup());
        return;
      }

      if (checkIn != null && checkIn.isNotEmpty) {
        // User is checked in - apply check-in data and start timer
        _applyCheckedInFromServer(checkIn);
        // Persist the SERVER-confirmed time, not the local clock.
        await _saveCheckInToPrefs(at: _checkInTime);
        debugPrint('[Timer] Timer started');
        // Idempotent tracking reconciliation: if the service isn't actually
        // running (fresh start, killed process, failed init), recover it.
        unawaited(_ensureTrackingActive());
        return;
      }

      // No check-in found - reset state and show not checked in
      _resetTimerAndState();
      await _clearCheckInFromPrefs();
      if (!mounted) return;
      setState(() {
        isCheckedIn = false;
        _checkInSource = '';
      });
      unawaited(_maybeStartGpsWarmup());
    } catch (e) {
      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'AttendanceScreen',
        endpoint: '/attendance/live',
        startTime: startTime,
        endTime: endTime,
        statusCode: 0,
        error: e.toString(),
      );
      debugPrint('[Attendance] Error loading attendance status: $e');
      if (mounted) {
        setState(() {
          _attendanceStatusError = 'Status unavailable (network error)';
        });
      }
    } finally {
      // Clear loading state. Only a successful API response confirms the
      // status - failures leave _hasAttendanceApiConfirmed=false so the UI
      // shows the error state instead of "not checked in".
      if (!mounted) return;
      setState(() {
        _isAttendanceStatusLoading = false;
        _hasAttendanceApiConfirmed = confirmed;
      });
    }
  }

  void _applyCheckedInFromServer(String hhmmss) {
    try {
      final now = DateTime.now();
      final parts = hhmmss.split(':').map((s) => int.tryParse(s) ?? 0).toList();

      // Use actual server check-in time, not current time
      final checkInDateTime = DateTime(now.year, now.month, now.day, parts[0],
          parts[1], parts.length > 2 ? parts[2] : 0);

      debugPrint('[Attendance] Server check-in time received');

      // Check if server time is different from current check-in time
      final timeChanged = _checkInTime == null ||
          _checkInTime!.hour != checkInDateTime.hour ||
          _checkInTime!.minute != checkInDateTime.minute ||
          _checkInTime!.second != checkInDateTime.second;

      if (timeChanged) {
        debugPrint(
            '[Attendance] Server check-in time differs from current, updating timer');

        // Update check-in time and cache it
        _checkInTime = checkInDateTime;
        _checkOutTime = null;

        // Cache the server check-in time
        _cacheCheckInTime(checkInDateTime);

        // Calculate duration from actual check-in time
        final diff = now.difference(checkInDateTime).inSeconds;
        final startSeconds = diff > 0 ? diff : 0;

        debugPrint(
            '[Attendance] Final timer start time: $startSeconds seconds');

        _timer?.cancel();
        setState(() {
          isCheckedIn = true;
          isTimerRunning = true;
          totalSeconds = startSeconds;
          hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
          minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
          seconds = (totalSeconds % 60).toString().padLeft(2, '0');
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() {
            totalSeconds++;
            hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
            minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
            seconds = (totalSeconds % 60).toString().padLeft(2, '0');
          });
        });
      } else {
        debugPrint(
            '[Attendance] Server check-in time matches current, no timer adjustment needed');
        // Just ensure cache is up to date
        _cacheCheckInTime(checkInDateTime);
        // The server still reports an active check-in - the UI must reflect
        // it even when _checkInTime already matched (e.g. it survived a
        // local state reset). Leaving isCheckedIn=false here would wrongly
        // re-enable the Check-In button.
        if (!isCheckedIn && mounted) {
          setState(() {
            isCheckedIn = true;
            isTimerRunning = true;
          });
        }
      }
    } catch (_) {
      _startWorkTimer();
      setState(() => isCheckedIn = true);
    }
  }

  void _resetTimerAndState() {
    _timer?.cancel();
    _timer = null; // ✅ FIX: ensure timer is fully stopped
    setState(() {
      isCheckedIn = false;
      isTimerRunning = false;
      totalSeconds = 0;
      hours = "00";
      minutes = "00";
      seconds = "00";
      // Clear the retained check-in time too - a stale _checkInTime that
      // equals the server time makes _applyCheckedInFromServer take the
      // "no change" branch and could suppress the checked-in state.
      _checkInTime = null;
      _checkOutTime = null;
    });
  }

  Future<void> _checkUserFaceRegistration() async {
    setState(() => isFaceRegistered = false);
  }

  bool _isOpenShift(String s) {
    final name = (s).trim().toLowerCase();
    return name.contains('open');
  }

  String _todayYmd() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  //
  Future<Position?> _getPositionUsingDemo({
    bool quiet = false,
    LocationAccuracy accuracy = LocationAccuracy.high, //
  }) async {
    final hasPermission = await _ensurePermissionDemo(quiet: quiet);
    if (!hasPermission) return null;

    //
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!quiet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return null;
    }

    //
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        //
        if (age.inMinutes < 5) {
          _log('Using cached position (${age.inMinutes}min old)');
          return lastKnown;
        }
      }
    } catch (e) {
      _log('Error getting last known position: $e');
    }

    //
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 15), //
      );
      _log('Got fresh GPS position');
      return pos;
    } on TimeoutException catch (e) {
      if (!quiet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location request timed out. Please try again.')),
        );
      }
      _log('Location timeout: $e');
      return null;
    } on LocationServiceDisabledException catch (e) {
      if (!quiet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Location services are turned off. Please enable GPS.')),
        );
      }
      _log('Location services disabled: $e');
      return null;
    } on PermissionDeniedException catch (e) {
      if (!quiet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permission denied. Please allow location access.')),
        );
      }
      _log('Location permission denied: $e');
      return null;
    } on Exception catch (e) {
      if (!quiet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: ${e.toString()}')),
        );
      }
      _log('Location error: $e');
      return null;
    }
  }

  // High-accuracy location fetching with continuous improvement strategy
  Future<Position?> _getHighAccuracyPosition({
    bool quiet = false,
    String actionLabel = 'check-in',
    double maxAccuracyMeters = 50.0,
    // Total budget for ALL phases (initial fix + stream improvement).
    // Indoor GPS convergence typically takes 20-40s; the previous 25s budget
    // (plus an unaccounted 10s initial fix) was too tight indoors.
    Duration overallTimeout = const Duration(seconds: 60),
    // Under the flexible attendance policy the final decision (below)
    // accepts ANY fresh, non-mocked fix regardless of accuracy - the
    // backend classifies office presence from accuracy vs the geofence. So
    // once a candidate fix exists, there is no reason to make the employee
    // wait out the full overallTimeout hoping for <=maxAccuracyMeters: that
    // reproduced a ~60-64s wait even when a usable fix arrived in seconds.
    // This grace window still gives GPS a real chance to converge to a
    // precise fix first; only after it elapses does a degraded-but-fresh
    // fix get accepted early. Freshness (<=5min) and mock-location
    // rejection are unchanged - only the accuracy gate for this flexible
    // path is relaxed, and only after waiting this long.
    Duration flexibleAcceptAfter = const Duration(seconds: 15),
  }) async {
    // Prevent concurrent acquisition requests (e.g. double retry, check-in
    // while a check-out acquisition is running).
    if (_gpsAcquisitionInProgress) {
      _showSingleError(quiet,
          'Location request already in progress. Please wait a moment.');
      return null;
    }
    _gpsAcquisitionInProgress = true;

    debugPrint('[GPS] Acquisition started');
    debugPrint('[GPS] Required accuracy: ≤${maxAccuracyMeters}m');
    debugPrint('[GPS] Overall timeout: ${overallTimeout.inSeconds}s');
    debugPrint('[GPS] Requested LocationAccuracy: bestForNavigation');

    // Step 1: Check location permission
    final hasPermission = await _ensurePermissionDemo(quiet: quiet);
    _log('[Permission] Final permission check result: $hasPermission');
    debugPrint(
        '[GPS] Location permission: ${hasPermission ? "granted" : "denied"}');
    if (!hasPermission) {
      _log('[GPS] Permission denied or unavailable, cannot continue');
      debugPrint('[GPS] Final failure reason: permission denied');
      _gpsAcquisitionInProgress = false;
      _showSingleError(
          quiet, 'Location permission is required for attendance.');
      return null;
    }

    // Step 2: Check if GPS/location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _log('[GPS] Service enabled: $serviceEnabled');
    debugPrint('[GPS] Location service enabled: $serviceEnabled');
    if (!serviceEnabled) {
      _log('[GPS] Service disabled before current location request');
      debugPrint('[GPS] Final failure reason: GPS service disabled');
      _gpsAcquisitionInProgress = false;
      _showSingleError(quiet,
          'GPS is turned off. Please enable location services and try again.');
      return null;
    }

    // Step 3: On Android 12+, whileInUse may be approximate-only. Under the
    // flexible attendance policy coarse fixes are still recorded, so keep
    // acquiring instead of failing fast; the backend classifies them as
    // Location Uncertain when the geofence boundary cannot be established.
    try {
      final accStatus = await Geolocator.getLocationAccuracy();
      debugPrint('[GPS] Location accuracy status: $accStatus');
      if (accStatus == LocationAccuracyStatus.reduced) {
        debugPrint('[GPS] Precise location off - continuing with approximate fixes');
      }
    } catch (_) {
      // getLocationAccuracy unsupported on this platform - continue.
    }

    // Stage 0 - warm-up fast path: the page's shared stream may already hold
    // a converged fix that satisfies the threshold (GPS warmed while the
    // page sat open). Same acceptance rules as last-known.
    final warm = _warmBest;
    if (warm != null) {
      final age = DateTime.now().difference(warm.timestamp);
      debugPrint(
          '[GPS] Warm-up position: acc=${warm.accuracy.toStringAsFixed(1)}m, '
          'age=${age.inSeconds}s, mocked=${warm.isMocked}');
      _logGpsFix('warm-up fast path', warm);
      if (!warm.isMocked &&
          !age.isNegative &&
          age <= _kLastKnownMaxAge &&
          warm.accuracy <= maxAccuracyMeters) {
        debugPrint('[GPS] Warm-up position accepted (fast path)');
        _gpsAcquisitionInProgress = false;
        return warm;
      }
    }

    // Stage 1 - fast path: reuse Fused Location's most recent fix when it is
    // fresh (<60s), meets the accuracy threshold and is not mocked. Fixes
    // produced moments ago (e.g. a tracking tick or an earlier attempt) are
    // just as trustworthy as a new capture and skip the whole wait.
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        debugPrint(
            '[GPS] Last-known: acc=${lastKnown.accuracy.toStringAsFixed(1)}m, '
            'age=${age.inSeconds}s, mocked=${lastKnown.isMocked}');
        _logGpsFix('last-known fast path', lastKnown);
        if (!lastKnown.isMocked &&
            !age.isNegative &&
            age <= _kLastKnownMaxAge &&
            lastKnown.accuracy <= maxAccuracyMeters) {
          debugPrint('[GPS] Last-known accepted (fast path)');
          _gpsAcquisitionInProgress = false;
          return lastKnown;
        }
        debugPrint('[GPS] Last-known rejected - acquiring fresh fix');
      }
    } catch (_) {
      // No usable last-known - continue to fresh acquisition.
    }

    // Show single loading state
    if (!quiet && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Getting your location... GPS may take up to a minute indoors.'),
          duration: Duration(seconds: 60),
          backgroundColor: Colors.blue,
        ),
      );
    }

    Position? bestPosition;
    StreamSubscription<Position>? positionStreamSubscription;
    final startTime = DateTime.now();
    // Single deadline for the WHOLE acquisition: the initial fix consumes
    // part of the budget and the stream gets whatever remains.
    final deadline = startTime.add(overallTimeout);
    bool acquisitionComplete = false;
    bool sawMocked = false;

    debugPrint('[GPS] Acquisition source: '
        '${_gpsWarmSub != null ? "shared warm stream" : "direct probe"}; '
        'tracking=${_tracking != null}');

    try {
      // Step 3: Get initial fresh position - only when no shared stream is
      // running. When warm-up already holds an active subscription the
      // stream phase below receives the same provider flow, and a second
      // getCurrentPosition probe just burns up to 10s of the deadline.
      if (_gpsWarmSub == null) {
        debugPrint('[GPS] Getting initial fresh position...');
        try {
          final initialPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit: const Duration(seconds: 10),
            forceAndroidLocationManager: false,
          );

          final positionAge =
              DateTime.now().difference(initialPosition.timestamp);
          debugPrint(
              '[GPS] Initial position: accuracy=${initialPosition.accuracy.toStringAsFixed(1)}m, age=${positionAge.inSeconds}s');
          _logGpsFix('initial fresh fix', initialPosition);

          // Reject mock locations outright (attendance security): keep
          // listening for a genuine fix, but audit the attempt once.
          if (initialPosition.isMocked) {
            debugPrint('[GPS] Initial position is mocked - rejecting');
            if (!sawMocked) {
              sawMocked = true;
              unawaited(TrackingEvents.report(
                type: 'mock_location_detected',
                message:
                    'Untrusted location source detected during $actionLabel',
                latitude: initialPosition.latitude,
                longitude: initialPosition.longitude,
                accuracy: initialPosition.accuracy,
              ));
            }
          } else
          // Validate freshness (reject if older than 5 minutes)
          if (positionAge.inMinutes > 5) {
            debugPrint(
                '[GPS] Initial position too old (${positionAge.inMinutes}min), will stream for fresh position');
          } else {
            bestPosition = initialPosition;
            debugPrint(
                '[GPS] Best accuracy so far=${bestPosition!.accuracy.toStringAsFixed(1)}m');

            // If already accurate enough, accept immediately
            if (bestPosition!.accuracy <= maxAccuracyMeters) {
              debugPrint('[GPS] Position accepted immediately');
              _log(
                  '[GPS] Position accepted: accuracy ${bestPosition!.accuracy.toStringAsFixed(1)}m ≤ threshold ${maxAccuracyMeters}m');
              acquisitionComplete = true;
              return bestPosition;
            }
          }
        } catch (e) {
          debugPrint('[GPS] Initial position fetch failed: $e');
          // Continue to stream-based approach
        }
      } else {
        debugPrint(
            '[GPS] Skipping initial probe - shared stream already running');
      }

      // Step 4: If not immediately accurate, stream for improvement using
      // whatever time remains in the overall budget (the initial fix already
      // consumed part of it).
      if (!acquisitionComplete) {
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero) {
          debugPrint('[GPS] Overall timeout reached during initial fix');
        } else {
          debugPrint(
              '[GPS] Starting location stream for continuous improvement '
              '(${remaining.inSeconds}s left)...');

          // Extended indoor acquisition - tell the user why it is taking a
          // while and how long it can take.
          if (!quiet && mounted) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                      'Still improving GPS accuracy indoors - up to ${remaining.inSeconds}s left.'),
                  duration: remaining,
                  backgroundColor: Colors.blue,
                ),
              );
          }

          // Explicit 1s cadence - matches the warm-up stream settings.
          final locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            intervalDuration: Duration(seconds: 1),
          );

          // Single shared pipeline: join the page's warm-up stream rather
          // than opening a second concurrent GPS subscription. If the
          // warm-up stream is not running (stopped, permission granted
          // late), fall back to a direct stream as before.
          _ensureSharedGpsStream();
          final Stream<Position> sharedOrDirect =
              (_gpsWarmSub != null && _gpsSharedStream != null)
                  ? _gpsSharedStream!.stream
                  : Geolocator.getPositionStream(
                      locationSettings: locationSettings);

          double lastReportedAccuracy = double.infinity;
          DateTime lastProgressAt = DateTime.now();
          // Diagnostic counters: how many truly new GNSS fixes the provider
          // delivered vs cached repeats (same fix timestamp re-delivered).
          int uniqueFixes = 0;
          int cachedRepeats = 0;
          DateTime? lastFixTs;
          final streamStartAt = DateTime.now();

          final completer = Completer<Position?>();
          final timeoutTimer = Timer(remaining, () {
            if (!acquisitionComplete && !completer.isCompleted) {
              debugPrint('[GPS] Overall timeout reached '
                  '(stream fixes: $uniqueFixes unique, '
                  '$cachedRepeats cached-repeat)');
              completer.complete(bestPosition);
            }
          });

          // Flexible-policy responsiveness: after a shorter grace window,
          // accept whatever fresh non-mocked fix has been seen so far
          // instead of waiting out the full budget. Only fires if the full
          // timeout is further away than the grace window, and only acts
          // if a candidate fix actually exists yet - a device with no fix
          // at all still waits for the full budget for its first fix.
          Timer? flexibleTimer;
          if (remaining > flexibleAcceptAfter) {
            flexibleTimer = Timer(flexibleAcceptAfter, () {
              if (acquisitionComplete || completer.isCompleted) return;
              if (bestPosition == null) return;
              debugPrint('[GPS] Flexible accept after '
                  '${flexibleAcceptAfter.inSeconds}s grace: '
                  'accuracy=${bestPosition!.accuracy.toStringAsFixed(1)}m '
                  '(degraded - presence decided server-side)');
              acquisitionComplete = true;
              timeoutTimer.cancel();
              completer.complete(bestPosition);
            });
          }

          positionStreamSubscription =
              sharedOrDirect.listen(
            (position) {
              if (acquisitionComplete || completer.isCompleted) return;

              final isRepeat = position.timestamp == lastFixTs;
              if (isRepeat) {
                cachedRepeats++;
              } else {
                lastFixTs = position.timestamp;
                uniqueFixes++;
              }

              final positionAge =
                  DateTime.now().difference(position.timestamp);
              debugPrint(
                  '[GPS] Position: accuracy=${position.accuracy.toStringAsFixed(1)}m, '
                  'age=${positionAge.inSeconds}s${isRepeat ? ' [cached-repeat]' : ''}');
              if (!isRepeat) _logGpsFix('stream fix #$uniqueFixes', position);

              // Reject mock locations outright (attendance security) -
              // never trust them, but audit once per acquisition.
              if (position.isMocked) {
                debugPrint('[GPS] Mock location detected - skipping');
                if (!sawMocked) {
                  sawMocked = true;
                  unawaited(TrackingEvents.report(
                    type: 'mock_location_detected',
                    message:
                        'Untrusted location source detected during $actionLabel',
                    latitude: position.latitude,
                    longitude: position.longitude,
                    accuracy: position.accuracy,
                  ));
                }
                return;
              }

              // Validate freshness
              if (positionAge.inMinutes > 5) {
                debugPrint('[GPS] Position too old, skipping');
                return;
              }

              // Track best position
              if (bestPosition == null ||
                  position.accuracy < bestPosition!.accuracy) {
                bestPosition = position;
                debugPrint(
                    '[GPS] Best accuracy so far=${bestPosition!.accuracy.toStringAsFixed(1)}m');

                // Progress feedback while accuracy converges indoors
                // (throttled: >=3s apart, >=10m improvement).
                if (!quiet &&
                    mounted &&
                    bestPosition!.accuracy <= lastReportedAccuracy - 10 &&
                    DateTime.now().difference(lastProgressAt) >=
                        const Duration(seconds: 3)) {
                  lastReportedAccuracy = bestPosition!.accuracy;
                  lastProgressAt = DateTime.now();
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                            'Improving accuracy: ${bestPosition!.accuracy.toStringAsFixed(0)}m - need ${maxAccuracyMeters.toStringAsFixed(0)}m or better'),
                        duration: const Duration(seconds: 4),
                        backgroundColor: Colors.blue,
                      ),
                    );
                }
              }

              // Accept immediately if accuracy is good enough
              if (position.accuracy <= maxAccuracyMeters) {
                debugPrint('[GPS] Position accepted '
                    '(+${DateTime.now().difference(streamStartAt).inMilliseconds}ms stream, '
                    '$uniqueFixes unique fixes)');
                _log(
                    '[GPS] Position accepted: accuracy ${position.accuracy.toStringAsFixed(1)}m ≤ threshold ${maxAccuracyMeters}m');
                acquisitionComplete = true;
                timeoutTimer.cancel();
                flexibleTimer?.cancel();
                completer.complete(position);
              }
            },
            onError: (error) {
              if (!completer.isCompleted) {
                debugPrint('[GPS] Stream error: $error');
                completer.complete(bestPosition);
              }
            },
          );

          // Wait for completion (either good position or timeout)
          bestPosition = await completer.future;
          timeoutTimer.cancel();
          flexibleTimer?.cancel();
        }
      }

      // Step 5: Final decision
      final finalPosition = bestPosition;

      if (finalPosition == null) {
        debugPrint('[GPS] Final result: no position obtained');
        debugPrint('[GPS] Attendance API will be called: false');
        _log('[GPS] Final: No position obtained within timeout');
        _showSingleError(
            quiet,
            sawMocked
                ? 'Location verification failed. Please check your device location settings and try again.'
                : 'Unable to determine your location. Please try again.');
        return null;
      }

      if (finalPosition.isMocked) {
        unawaited(TrackingEvents.report(
          type: 'mock_location_detected',
          message: 'Untrusted location source detected during $actionLabel',
          latitude: finalPosition.latitude,
          longitude: finalPosition.longitude,
          accuracy: finalPosition.accuracy,
        ));
        _showSingleError(quiet,
            'Location verification failed. Please check your device location settings and try again.');
        return null;
      }

      // Flexible attendance: the best non-mocked fix is always accepted and
      // recorded with its real reported accuracy. The backend classifies
      // office presence (inside/outside/uncertain) from accuracy vs the
      // geofence boundary, so a poor indoor fix is never rejected here.
      debugPrint('[GPS] Final result: valid position obtained');
      debugPrint(
          '[GPS] Final accuracy: ${finalPosition.accuracy.toStringAsFixed(1)}m');
      debugPrint('[GPS] Attendance API will be called: true');
      _log(
          '[GPS] Final: Position accepted with accuracy ${finalPosition.accuracy.toStringAsFixed(1)}m'
          '${finalPosition.accuracy > maxAccuracyMeters ? ' (degraded - presence decided server-side)' : ''}');
      return finalPosition;
    } catch (e) {
      debugPrint('[GPS] Unexpected error occurred');
      _log('[GPS] Final: Unexpected error occurred');
      _showSingleError(
          quiet, 'Unable to determine your location. Please try again.');
      return null;
    } finally {
      // Always clean up stream subscription
      if (positionStreamSubscription != null) {
        await positionStreamSubscription.cancel();
        debugPrint('[GPS] Location stream cancelled');
      }
      acquisitionComplete = true;
      _gpsAcquisitionInProgress = false;

      // Clear loading state
      if (!quiet && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    }
  }

  // Helper to show single error message (no duplicate SnackBar + AlertDialog)
  void _showSingleError(bool quiet, String message) {
    if (quiet) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    _showErrorDialog(message);
  }

  // Show location permission dialog
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
            'Location permission is required for attendance. Please allow location access and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Request permission
              final permission = await Geolocator.requestPermission();
              _log(
                  '[PermissionDialog] User selected grant, result: $permission');
              if (permission == LocationPermission.denied ||
                  permission == LocationPermission.deniedForever) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Location permission denied. Please enable it in settings.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location permission granted!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  // Show location service dialog
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
            'GPS is turned off. Please enable location services and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Open location settings
              await Geolocator.openLocationSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please enable location services and try again.'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Unified Location status check used at page open, on app resume and on
  /// service-status stream changes. Updates the OFF warning and button
  /// state, purges stale warm-up fixes when Location turns off, and starts
  /// warm-up when Location is available. Never requests permission and
  /// never launches Settings by itself.
  Future<void> _checkLocationStatusOnOpen() async {
    bool enabled;
    LocationPermission permission;
    try {
      enabled = await Geolocator.isLocationServiceEnabled();
      permission = await Geolocator.checkPermission();
    } catch (_) {
      return;
    }
    var precise = true;
    try {
      precise = (await Geolocator.getLocationAccuracy()) !=
          LocationAccuracyStatus.reduced;
    } catch (_) {}
    if (!mounted) return;

    setState(() {
      _locationServiceEnabled = enabled;
      _locationPermissionGranted =
          permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;
      _preciseLocationGranted = precise;
    });
    debugPrint(
        '[GPS] page-open status: service=$enabled permission=$permission precise=$precise');

    if (!enabled) {
      // Purge any stale warm-up fix - a position captured before Location
      // was switched off must never be reused for attendance.
      _warmBest = null;
      _stopGpsWarmup();
      _maybeShowLocationRequiredDialog();
    } else {
      _suppressLocationDialog = false; // next OFF may prompt again
      _dismissLocationDialogIfShowing();
      _maybeStartGpsWarmup();
      _scheduleWarmupRetry(); // one-shot cover for transient guard races
    }
  }

  /// Shows the one-shot Location Required dialog. Guarded so rebuilds and
  /// repeated status events can never stack dialogs, and so a user who
  /// chose "Not Now" is not re-prompted until the state flips on again.
  void _maybeShowLocationRequiredDialog() {
    if (_locationDialogOpen || _suppressLocationDialog || !mounted) return;
    _locationDialogOpen = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Required'),
        content: const Text(
            "Please enable your device's Location service to use Manual or Biometric Attendance."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Location Settings'),
          ),
        ],
      ),
    ).then((_) {
      _locationDialogOpen = false;
      // Do not re-prompt while Location stays off; the on-page warning
      // remains visible. Cleared when Location turns back on.
      if (_locationServiceEnabled == false) _suppressLocationDialog = true;
    });
  }

  void _dismissLocationDialogIfShowing() {
    if (!_locationDialogOpen || !mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _locationDialogOpen = false;
  }

  Future<bool> _ensurePermissionDemo({bool quiet = false}) async {
    _log('[Permission] Ensure permission flow start. quiet=$quiet');

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('[GPS] Service enabled: $serviceEnabled');
    if (!serviceEnabled) {
      if (quiet) return false;
      if (!mounted) return false;

      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
              'GPS is turned off. Please enable location services and try again.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (go != true) {
        debugPrint('[GPS] User cancelled location settings flow');
        return false;
      }
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint(
          '[GPS] Location service enabled after settings: $serviceEnabled');
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('[GPS] Permission: $permission');
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      if (quiet) return false;
      permission = await Geolocator.requestPermission();
      _log('[Permission] After request: $permission');
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        if (mounted && !quiet) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is required for attendance. Please allow location access and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (quiet) return false;
      if (!mounted) return false;

      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: Text(kIsWeb
              ? 'Location permission is blocked for this site. Enable it in your browser site settings, then try again.'
              : 'Location permission is disabled for this app. Please enable it from App Settings.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                // openAppSettings is unsupported on web - the browser site
                // settings cannot be opened programmatically.
                if (!kIsWeb) await Geolocator.openAppSettings();
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Text(kIsWeb ? 'Retry' : 'Open Settings'),
            ),
          ],
        ),
      );

      if (go != true) {
        debugPrint('[GPS] User cancelled app settings permission flow');
        return false;
      }
      permission = await Geolocator.checkPermission();
      debugPrint('[GPS] Permission after app settings: $permission');
      if (permission == LocationPermission.deniedForever) {
        if (mounted && !quiet) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is disabled for this app. Please enable it from App Settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }

    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    debugPrint('[GPS] Permission granted result: $granted');
    return granted;
  }

  // Employee self-service endpoint: returns the caller's assigned office geo
  // config plus the company geofencing policy. Admin/HR tokens (403 there)
  // fall back to the management listing endpoint.
  Future<_AssignedGeo> _fetchAssignedGeo() async {
    final cached = _cachedGeo;
    if (cached != null) return cached;

    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/office/assigned'),
        headers: _authHeaders(),
      );

      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final enabled = m['geofencingEnabled'] == true;
        final legacy = m['legacyCompatibilityMode'] == true;
        final office = m['office'];
        _Branch? branch;
        if (office is Map<String, dynamic>) {
          branch = _Branch(
            (office['branchName'] ?? office['name'] ?? '').toString(),
            ((office['latitude'] as num?) ?? 0).toDouble(),
            ((office['longitude'] as num?) ?? 0).toDouble(),
            ((office['radius'] as num?) ?? 0).toDouble(),
          );
        }
        final geo = _AssignedGeo(branch, enabled, legacy, true);
        // Only cache a resolved office — a null-office answer is retried so
        // a later HR configuration is picked up on the next attempt.
        if (branch != null) _cachedGeo = geo;
        return geo;
      }

      if (res.statusCode == 403 || res.statusCode == 401) {
        // admin/hr token — fall back to the management listing endpoint
        return _fetchBranchFromLocations();
      }
      return const _AssignedGeo(null, false, false, false);
    } catch (_) {
      return const _AssignedGeo(null, false, false, false);
    }
  }

  // Admin/HR fallback: match the caller's branch string against the office
  // management list. This endpoint carries no entitlement information, so
  // the policy flags are reported as unknown — the backend remains the
  // authority on whether geofencing actually applies at submit time.
  Future<_AssignedGeo> _fetchBranchFromLocations() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/office/locations'),
        headers: _authHeaders(),
      );

      if (res.statusCode != 200) {
        return const _AssignedGeo(null, false, false, false);
      }

      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();

      bool nameMatches(Map<String, dynamic> m) =>
          (m['branchName'] ?? m['name'] ?? '')
              .toString()
              .trim()
              .toLowerCase() ==
          location.trim().toLowerCase();

      final match = list.firstWhere(nameMatches, orElse: () => const {});

      if (match.isEmpty) {
        debugPrint(
            '[Branch] No officeLocations record matches employee location "$location" '
            '(${list.length} records fetched)');
        return const _AssignedGeo(null, false, false, false);
      }

      // Dev-only diagnostic (coords masked to ~1km). Helps verify which
      // officeLocations record the geofence check resolved to.
      final matchCount = list.where(nameMatches).length;
      debugPrint(
          '[Branch] employee location="$location" matched '
          '${match['docId'] ?? match['id'] ?? '?'} '
          'name=${match['branchName'] ?? match['name']} '
          'coords≈${(match['latitude'] as num?)?.toStringAsFixed(2)},'
          '${(match['longitude'] as num?)?.toStringAsFixed(2)} '
          'radius=${match['radius']}'
          '${matchCount > 1 ? ' ($matchCount same-name records - newest used)' : ''}');

      return _AssignedGeo(
        _Branch(
          (match['branchName'] ?? match['name'] ?? '').toString(),
          ((match['latitude'] as num?) ?? 0).toDouble(),
          ((match['longitude'] as num?) ?? 0).toDouble(),
          ((match['radius'] as num?) ?? 0).toDouble(),
        ),
        false,
        false,
        false,
      );
    } catch (_) {
      return const _AssignedGeo(null, false, false, false);
    }
  }

  // Non-blocking, permission-preserving position lookup for companies where
  // geofencing is disabled: uses only already-granted permission and never
  // shows a permission prompt. Returns null when no fix is available.
  Future<Position?> _getBestEffortPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!granted) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  double _distanceMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  Future<bool> _confirmOutside({
    double distance = 0,
    double radius = 0,
    String branchName = '',
    String actionLabel = 'check-in',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Outside Office Location'),
            content: Text(
              (branchName.isNotEmpty
                      ? 'You are outside the office location for $branchName.\n\n'
                      : 'You are outside your office location.\n\n') +
                  (distance > 0
                      ? 'Distance from branch: ${distance.toStringAsFixed(1)}m\n'
                          'Allowed radius: ${radius.toStringAsFixed(1)}m\n\n'
                      : '') +
                  'Do you want to proceed with $actionLabel?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Proceed'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String? _detectCheckInCategory() {
    if (_isOpenShift(selectedShift)) return null;

    final times = _getShiftTimes(selectedShift);
    if (times == null) {
      print('[SHIFT DEBUG] Shift time is null. Stop late/early validation.');
      return null;
    }

    final now = DateTime.now();
    final start = _toDateTime(times.start);

    final graceEnd = start.add(const Duration(minutes: 5));
    if (now.isAfter(graceEnd)) return 'Late Check-in';

    return null;
  }

  String? _detectCheckoutCategory() {
    if (_isOpenShift(selectedShift)) return null;

    final times = _getShiftTimes(selectedShift);
    if (times == null) {
      print('[SHIFT DEBUG] Shift time is null. Stop late/early validation.');
      return null;
    }

    final now = DateTime.now();
    var end = _toDateTime(times.end);
    final start = _toDateTime(times.start);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));

    if (now.isBefore(end)) {
      return 'Early Checkout';
    }

    final graceEnd = end.add(const Duration(minutes: 5));
    if (now.isAfter(graceEnd)) {
      return 'Late Checkout';
    }

    return null;
  }

  Future<List<Map<String, String>>> _fetchAllReasons() async {
    if (_cachedReasons != null) return _cachedReasons!;
    if (_reasonsLoading) return <Map<String, String>>[];
    _reasonsLoading = true;
    _reasonsError = null;

    try {
      final token = CompanyData.token;

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/reasons?limit=200'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) {
        _log('Failed to load reasons: ${res.statusCode}');
        _reasonsError = res.statusCode == 401
            ? 'auth'
            : res.statusCode == 403
                ? 'forbidden'
                : 'network';
        return <Map<String, String>>[];
      }

      final body = jsonDecode(res.body);
      final List items =
          (body is List) ? body : (body['items'] as List? ?? <dynamic>[]);

      final result = items
          .map<Map<String, String>>((raw) {
            final m = (raw as Map).cast<String, dynamic>();
            return {
              'id': (m['id'] ?? m['_id'] ?? '').toString(),
              'reason': (m['reason'] ?? '').toString(),
              'typeId': (m['typeId'] ?? '').toString(),
              'typeName': (m['typeName'] ?? '').toString(),
            };
          })
          .where((e) => (e['reason'] ?? '').trim().isNotEmpty)
          .toList();

      _cachedReasons = result;
      return result;
    } catch (e) {
      _log('Error loading reasons: $e');
      _reasonsError = 'network';
      return <Map<String, String>>[];
    } finally {
      _reasonsLoading = false;
    }
  }

  Future<Map<String, String>?> _pickReason(String title,
      {String? prefer}) async {
    final reasons = await _fetchAllReasons();
    if (reasons.isEmpty) {
      switch (_reasonsError) {
        case 'auth':
          _showInfoDialog(
            'Your session has expired. Please log in again.',
            title: 'Session Expired',
          );
          return null;
        case 'forbidden':
          _showInfoDialog(
            'You do not have permission to view attendance reasons. '
            'Please contact your administrator.',
            title: 'Access Denied',
          );
          return null;
        case 'network':
          final retry = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Connection Error'),
              content: const Text(
                  'Unable to load attendance reasons. Please check your '
                  'connection and try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
          if (retry == true) {
            _cachedReasons = null;
            return _pickReason(title, prefer: prefer);
          }
          return null;
        default:
          _showInfoDialog('No reasons configured.');
          return null;
      }
    }

    String? selectedId;
    bool confirmed = false;

    if ((prefer ?? '').isNotEmpty) {
      final match = reasons.firstWhere(
        (r) =>
            (r['reason'] ?? '').toLowerCase().contains(prefer!.toLowerCase()),
        orElse: () => reasons.first,
      );
      selectedId = match['id'];
    } else {
      selectedId = reasons.first['id'];
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(title),
          content: DropdownButtonFormField<String>(
            initialValue: selectedId,
            isExpanded: true,
            items: reasons
                .map((r) => DropdownMenuItem(
                      value: r['id'],
                      child: Text(r['reason'] ?? ''),
                    ))
                .toList(),
            onChanged: (v) => setSt(() => selectedId = v),
            decoration: const InputDecoration(
              labelText: 'Select reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmed = false;
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () {
                      confirmed = true;
                      Navigator.pop(ctx);
                    },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (!confirmed || selectedId == null) {
      return null;
    }

    final chosen = reasons.firstWhere((r) => r['id'] == selectedId);
    final chosenText = (chosen['reason'] ?? '').toLowerCase();

    if (chosenText.contains('other')) {
      final controller = TextEditingController();
      String? typed;
      bool otherConfirmed = false;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: TextField(
                      controller: controller,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'Type your reason',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          otherConfirmed = false;
                          Navigator.pop(c);
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final v = controller.text.trim();
                          if (v.isNotEmpty) {
                            typed = v;
                            otherConfirmed = true;
                            Navigator.pop(c);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (!otherConfirmed || typed == null || typed!.isEmpty) {
        return null;
      }

      return {
        'reasonId': '',
        'reasonText': typed!,
        'reasonTypeId': chosen['typeId'] ?? '',
        'reasonTypeName': chosen['typeName'] ?? '',
      };
    }

    return {
      'reasonId': chosen['id'] ?? '',
      'reasonText': chosen['reason'] ?? '',
      'reasonTypeId': chosen['typeId'] ?? '',
      'reasonTypeName': chosen['typeName'] ?? '',
    };
  }

  // ===================== REPLACE THESE METHODS IN attendance_page.dart =====================

// 1) Keep this helper, but UPDATE the logic.
//    Your rule is: if there is already a checkIn today, block a second check-in,
//    even if checkout already happened.

  Future<bool> _isAlreadyCheckedInToday() async {
    final token = CompanyData.token;
    if (userId.isEmpty || token.isEmpty) return false;

    final url = Uri.parse('${ApiService.baseUrl}/attendance/live');

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) return false;

      final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      final me = list.firstWhere(
        (e) => (e['empid']?.toString() ?? '') == userId,
        orElse: () => <String, dynamic>{},
      );

      final checkIn = (me['checkIn'] ?? '').toString().trim();

      // IMPORTANT:
      // If a check-in already exists today, block any further check-in attempts.
      // This is true even if checkout is already completed.
      return checkIn.isNotEmpty;
    } catch (e) {
      _log('Error checking existing check-in: $e');
      return false;
    }
  }

  // 2) Use this guard before ANY popup/auth/location/check-in flow starts.
// Optimized: avoid API call if already checked in locally
  Future<bool> _canProceedWithCheckIn() async {
    // First check local state (fast)
    if (isCheckedIn) {
      if (!mounted) return false;
      _showInfoDialog('Already checked in today');
      return false;
    }

    // Only call API if local state is unclear
    final alreadyCheckedIn = await _isAlreadyCheckedInToday();
    if (alreadyCheckedIn) {
      if (!mounted) return false;
      _showInfoDialog('Already checked in today');
      return false;
    }

    return true;
  }

// Check-in progress locks to prevent duplicate taps
  bool _isManualLoading = false;
  bool _isBiometricLoading = false;

  // Prevents concurrent GPS acquisitions (check-in/check-out/retry overlap)
  bool _gpsAcquisitionInProgress = false;

  // GPS warm-up: a single shared position stream that keeps Fused Location
  // hot while the page is visible so check-in can reuse a recently
  // converged <=50m fix instead of cold-starting GNSS on tap. Never
  // uploads positions, never requests permission, never starts tracking;
  // auto-stops to bound battery use.
  StreamSubscription<Position>? _gpsWarmSub;
  StreamController<Position>? _gpsSharedStream;
  Position? _warmBest;
  double? _shownWarmAccuracy; // last accuracy shown in the readiness row
  Timer? _warmStopTimer;
  Timer? _warmupRetryTimer;
  // Diagnostics: unique vs cached-repeat fix accounting per warm session.
  // Identical position timestamps = the provider re-delivered a cached fix
  // rather than a new GNSS sample (key device-side convergence metric).
  int _warmFixUnique = 0;
  int _warmFixRepeats = 0;
  DateTime? _warmLastFixTs;
  static const Duration _kWarmupMaxDuration = Duration(minutes: 4);

  /// Starts the shared warm stream when safe: authenticated, permission
  /// already granted (non-intrusive check only), service enabled, page
  /// mounted and not already checked in (tracking keeps GPS warm anyway).
  /// Every early return is logged - a silently skipped warm-up was a
  /// first-attempt check-in regression (cold GNSS on tap).
  Future<void> _maybeStartGpsWarmup() async {
    if (!mounted) {
      debugPrint('[GPS] warm-up skipped: not mounted');
      return;
    }
    if (_gpsWarmSub != null) return; // already running
    if (isCheckedIn) {
      // isCheckedIn can be transiently true while cached prefs are
      // reconciled by _loadTodayStatus - the false-resolution path calls
      // this again, so skipping here is safe.
      debugPrint('[GPS] warm-up skipped: checked in (or status pending)');
      return;
    }
    if (CompanyData.token.isEmpty) {
      debugPrint('[GPS] warm-up skipped: no auth token yet');
      return;
    }
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        debugPrint('[GPS] warm-up skipped: permission $perm');
        return; // Never trigger a permission prompt from warm-up.
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('[GPS] warm-up skipped: location service off');
        return;
      }
      try {
        final acc = await Geolocator.getLocationAccuracy();
        if (acc == LocationAccuracyStatus.reduced) {
          debugPrint('[GPS] warm-up skipped: approximate-only location');
          return; // Approximate-only fixes can never reach <=50m.
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[GPS] warm-up skipped: status check error $e');
      return;
    }
    _ensureSharedGpsStream();
  }

  /// Idempotently creates the single underlying GPS subscription and its
  /// broadcast fan-out. Both warm-up and check-in acquisition listen to
  /// the same stream, so at most one GPS subscription exists per page.
  void _ensureSharedGpsStream() {
    if (_gpsWarmSub != null || !mounted) return;
    _gpsSharedStream ??= StreamController<Position>.broadcast();
    _warmFixUnique = 0;
    _warmFixRepeats = 0;
    _warmLastFixTs = null;
    debugPrint('[GPS] Warm-up stream started '
        '(bestForNavigation, 1s interval, distanceFilter=0)');
    // AndroidSettings with an explicit 1s interval: the default update
    // cadence converges too slowly to reach <=50m within one page visit.
    _gpsWarmSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: 1),
      ),
    ).listen(
      (p) {
        if (!p.isMocked) _warmBest = p; // keep freshest valid fix
        if (_gpsSharedStream?.isClosed == false) _gpsSharedStream?.add(p);
        if (p.timestamp == _warmLastFixTs) {
          _warmFixRepeats++;
        } else {
          _warmLastFixTs = p.timestamp;
          _warmFixUnique++;
          final age = DateTime.now().difference(p.timestamp);
          debugPrint('[GPS] warm fix #$_warmFixUnique '
              'acc=${p.accuracy.toStringAsFixed(1)}m '
              'age=${age.inSeconds}s');
        }
        // Refresh the on-page GPS-readiness indicator when accuracy
        // improves meaningfully or crosses the 50m threshold.
        final acc = p.isMocked ? null : p.accuracy;
        if (mounted && acc != null &&
            (_shownWarmAccuracy == null ||
                acc <= _shownWarmAccuracy! - 5 ||
                (acc <= 50) != (_shownWarmAccuracy! <= 50))) {
          setState(() => _shownWarmAccuracy = acc);
        }
      },
      onError: (Object e) => debugPrint('[GPS] Warm-up stream error: $e'),
    );
    _warmStopTimer?.cancel();
    _warmStopTimer = Timer(_kWarmupMaxDuration, () {
      if (_gpsAcquisitionInProgress) {
        // Do not cut the stream out from under an active acquisition -
        // self-renewing recheck until the acquisition flag clears.
        _warmStopTimer = Timer(
            const Duration(seconds: 75), () => _stopGpsWarmup());
        return;
      }
      _stopGpsWarmup();
    });
  }

  /// Stops the shared warm stream. Deferral applies only to transient
  /// stops (lifecycle hide, 4-minute cap) while an acquisition consumes
  /// the stream; [force] (dispose/logout) cancels immediately.
  ///
  /// [force] is only ever passed `true` from [dispose]. At that point the
  /// State is being torn down, so this must release the subscription/timer
  /// without touching widget state at all - checking `mounted` is not
  /// sufficient on its own, since the State's element is not detached until
  /// after `dispose()` returns, so `mounted` still reads `true` for the
  /// remainder of the dispose() call. Skipping setState whenever `force` is
  /// set keeps cleanup unconditional while non-dispose callers (lifecycle
  /// hide, warm-up cap, etc.) keep refreshing the on-page accuracy badge as
  /// before.
  void _stopGpsWarmup({bool force = false}) {
    _warmStopTimer?.cancel();
    _warmStopTimer = null;
    if (_gpsWarmSub != null && _gpsAcquisitionInProgress && !force) {
      // An acquisition is consuming this stream - cancelling now would
      // starve it until the deadline. Re-entering this method keeps the
      // recheck alive until the flag clears, so the stream can never be
      // left running permanently.
      _warmStopTimer = Timer(
          const Duration(seconds: 75), () => _stopGpsWarmup());
      return;
    }
    if (_gpsWarmSub != null) {
      debugPrint('[GPS] Warm-up stream stopped '
          '(unique fixes=$_warmFixUnique, cached-repeats=$_warmFixRepeats)');
      _gpsWarmSub!.cancel();
      _gpsWarmSub = null;
    }
    if (!force && mounted && _shownWarmAccuracy != null) {
      setState(() => _shownWarmAccuracy = null);
    }
  }

  /// One delayed retry for warm-up at page open: covers transient guard
  /// failures (token not yet hydrated, permission check racing plugin
  /// init) that previously left GNSS cold until the check-in tap.
  void _scheduleWarmupRetry() {
    _warmupRetryTimer?.cancel();
    _warmupRetryTimer = Timer(const Duration(seconds: 3), () {
      if (mounted &&
          _gpsWarmSub == null &&
          _locationServiceEnabled == true &&
          !isCheckedIn) {
        debugPrint('[GPS] warm-up retry attempt');
        _maybeStartGpsWarmup();
      }
    });
  }

  // Freshness policy for the fast-path last-known fix: a position produced
  // within the last 60s by Fused Location (e.g. a recent tracking tick or a
  // prior check-out attempt) is trustworthy if it also meets the accuracy
  // threshold and is not mocked.
  static const Duration _kLastKnownMaxAge = Duration(seconds: 60);

// Helper function to determine user-friendly error messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Log detailed error for debugging
    debugPrint('[Attendance] Detailed error: $error');

    // Network/connection errors
    if (errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('clientexception') ||
        errorString.contains('connection abort') ||
        errorString.contains('no internet') ||
        errorString.contains('host') ||
        errorString.contains('dns')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    // Timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('timed out') ||
        errorString.contains('deadline')) {
      return 'Request timed out. Please try again.';
    }

    // Server/backend errors
    if (errorString.contains('server') ||
        errorString.contains('internal') ||
        errorString.contains('cloud run') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return 'Something went wrong. Please try again later.';
    }

    // Default fallback
    return 'Something went wrong. Please try again later.';
  }

// 3) Add this for manual button flow.
  Future<void> _handleManualCheckInTap() async {
    if (_isManualLoading || _isBiometricLoading) return;
    debugPrint('[Attendance] Manual attendance button pressed');

    // Set the in-flight guard synchronously BEFORE the first await. Setting
    // it after _canProceedWithCheckIn() left a window where a second tap
    // could slip past the check and run a duplicate check-in flow.
    _isManualLoading = true;
    setState(() {});

    try {
      final canProceed = await _canProceedWithCheckIn();
      if (!canProceed) return;

      if (!mounted) return;

      await _performCheckIn('manual');
    } finally {
      if (mounted) {
        _isManualLoading = false;
        setState(() {});
      }
    }
  }

// 4) UPDATE biometric flow so duplicate check is blocked BEFORE biometric auth starts.
  Future<void> _authenticateAndCheckIn() async {
    if (_isManualLoading || _isBiometricLoading) return;

    // Same synchronous in-flight guard as the manual path: set before the
    // first await so a concurrent tap cannot start a second flow.
    _isBiometricLoading = true;
    setState(() {});

    try {
      final canProceed = await _canProceedWithCheckIn();
      if (!canProceed) return;

      _authInProgress = true;

      // Check biometric availability before authentication
      final canBio = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      debugPrint('[BIOMETRIC] canCheckBiometrics: $canBio');
      debugPrint('[BIOMETRIC] isDeviceSupported: $supported');
      debugPrint('[BIOMETRIC] availableBiometrics: $availableBiometrics');

      if (!canBio || !supported) {
        if (!mounted) {
          _isBiometricLoading = false;
          setState(() {});
          return;
        }
        _showInfoDialog(
            'Biometric authentication is not available on this device. Please use manual attendance or enable biometric authentication on your phone.');
        _isBiometricLoading = false;
        setState(() {});
        return;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to check in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs:
              false, // Disable system error dialogs to show custom messages
          sensitiveTransaction: true,
        ),
      );

      if (!mounted) {
        _isBiometricLoading = false;
        setState(() {});
        return;
      }

      if (ok) {
        await _performCheckIn('biometric');
      } else {
        _showErrorDialog(
            'Biometric verification was not completed. Please try again or use manual attendance.');
        _isBiometricLoading = false;
        setState(() {});
      }
    } catch (e) {
      if (!mounted) {
        _isBiometricLoading = false;
        setState(() {});
        return;
      }
      debugPrint('[BIOMETRIC] Authentication error: $e');
      _showErrorDialog(
          'Biometric verification was not completed. Please try again or use manual attendance.');
      _isBiometricLoading = false;
      setState(() {});
    } finally {
      _authInProgress = false;
      // Always release the in-flight guard - including the success path,
      // which previously left _isBiometricLoading stuck true (locking both
      // check-in buttons if the user was not checked in afterwards).
      _isBiometricLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _rollbackAfterFailedCheckIn({
    required bool wasCheckedIn,
    required bool wasTimerRunning,
    required int prevSeconds,
    required String prevH,
    required String prevM,
    required String prevS,
  }) async {
    _timer?.cancel();

    if (!mounted) {
      await _clearCheckInFromPrefs();
      return;
    }

    setState(() {
      isCheckedIn = wasCheckedIn;
      isTimerRunning = wasTimerRunning;
      totalSeconds = prevSeconds;
      hours = prevH;
      minutes = prevM;
      seconds = prevS;

      if (!wasCheckedIn) {
        _checkInTime = null;
        _checkOutTime = null;
      }
    });

    if (wasCheckedIn && wasTimerRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          totalSeconds++;
          hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
          minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
          seconds = (totalSeconds % 60).toString().padLeft(2, '0');
        });
      });
    }

    if (wasCheckedIn) {
      await _saveCheckInToPrefs();
    } else {
      await _clearCheckInFromPrefs();
    }
  }

  // 5) UPDATE check-in flow so it also has a second safety check BEFORE reason popup.
//    This prevents the popup from opening if this method is called from anywhere else.
  Future<void> _performCheckIn(String type) async {
    debugPrint('[GPS] Check-in started (type=$type)');
    final perfSw = Stopwatch()..start();
    // Cheap local re-check only: the entry handlers already ran the full
    // _canProceedWithCheckIn() (local state + /attendance/live). Calling it
    // again here would double the API round-trip on every tap. The backend
    // 409 remains the authoritative duplicate guard.
    if (isCheckedIn) {
      _showInfoDialog('Already checked in today');
      return;
    }

    // Ensure shift times are loaded before validation
    if (_shiftTimes == null) {
      await _loadShiftTimes();
    }

    if (_shiftTimes == null) {
      _showInfoDialog(_shiftLoadError ??
          'Shift time is not loaded. Please refresh or contact admin.');
      return;
    }

    Map<String, String>? reasonInfo;
    final category = _detectCheckInCategory();

    if (category != null) {
      // Clear cached reasons to reload latest from server
      _cachedReasons = null;

      reasonInfo = await _pickReason(category, prefer: category);

      // If category requires reason but user cancelled
      if (category.isNotEmpty && reasonInfo == null) return;
    }

    // Geofencing is an optional company-level policy. The backend's
    // /office/assigned response is authoritative — the local FeatureAccess
    // snapshot can be stale or legacy-defaulted to "allow everything", so it
    // must never decide whether office/GPS enforcement applies. When geo
    // enforcement is off, normal attendance needs no GPS fix, office config
    // or outside-office confirmation; coordinates are best-effort only.
    final geo = await _fetchAssignedGeo();
    final geoEnabled =
        geo.lookupOk && (geo.geofencingEnabled || geo.legacyCompatibilityMode);

    _log(
        '[ManualAttendance] Starting location acquisition for manual check-in');
    debugPrint('[GPS] Final result: pending');
    Position? pos;
    if (geoEnabled) {
      pos = await _getHighAccuracyPosition(
        actionLabel: 'check-in',
        maxAccuracyMeters: 50.0,
      );
      debugPrint('[GPS] Final result: ${pos == null ? 'null' : 'valid'} '
          '(${perfSw.elapsedMilliseconds}ms)');
      if (pos == null) {
        _log(
            '[ManualAttendance] Location acquisition failed and returned null');
        debugPrint('[GPS] Final failure reason: location null');
        debugPrint('[GPS] Attendance API reached: false');
        return;
      }
    } else {
      pos = await _getBestEffortPosition();
    }
    debugPrint('[Perf] geo/position lookup done (${perfSw.elapsedMilliseconds}ms)');

    bool within = true;
    double distance = 0.0;
    String branchName = location;
    double expLat = 0, expLng = 0, expRad = 0;

    if (geoEnabled) {
      final branch = geo.branch;

      if (branch != null) {
        branchName = branch.name;
        expLat = branch.lat;
        expLng = branch.lng;
        expRad = branch.radius;
        distance = _distanceMeters(
          lat1: pos!.latitude,
          lng1: pos.longitude,
          lat2: branch.lat,
          lng2: branch.lng,
        );
        within = distance <= branch.radius;

        // Dev-only diagnostic (coords masked to ~1km).
        debugPrint(
            '[Branch] device≈${pos.latitude.toStringAsFixed(2)},'
            '${pos.longitude.toStringAsFixed(2)} '
            'distance=${distance.toStringAsFixed(1)}m radius=${branch.radius}');

        // The popup only appears when the fix is confidently outside: the
        // reported accuracy radius must clear the geofence boundary entirely.
        // Ambiguous fixes are recorded silently and the backend classifies
        // office presence as 'uncertain'.
        if (!within) {
          final confidentlyOutside =
              distance - pos.accuracy > branch.radius;
          if (confidentlyOutside) {
            final ok = await _confirmOutside(
              distance: distance,
              radius: branch.radius,
              branchName: branch.name,
              actionLabel: 'check-in',
            );
            if (!ok) return;
          }
        }
      } else if (geo.geofencingEnabled) {
        // Backend will also enforce this (GEO_FENCE_NOT_CONFIGURED); fail
        // early with a clear message instead of recording a bad punch.
        _showErrorDialog(
            'Office location is not configured for your branch. Please contact HR.');
        return;
      } else {
        final ok = await _confirmOutside(
          branchName: location.isEmpty ? 'Unknown' : location,
          actionLabel: 'check-in',
        );

        if (!ok) return;
        within = false;
      }
    }

    final token = CompanyData.token;
    final url = Uri.parse('${ApiService.baseUrl}/attendance/check-in');
    debugPrint('[GPS] Attendance API reached: true');

    final bodyMap = {
      'empid': userId,
      'name': userName,
      'location': location,
      'latitude': pos?.latitude,
      'longitude': pos?.longitude,
      'accuracy': pos?.accuracy,
      'isMocked': pos?.isMocked ?? false,
      'source': type,
      // UTC timestamp of the accepted GPS fix itself (ISO 8601), required by
      // the deployed backend's locationTimestamp validation.
      'locationTimestamp': pos?.timestamp.toUtc().toIso8601String(),
      'branchName': branchName,
      'expectedLatitude': expLat,
      'expectedLongitude': expLng,
      'expectedRadius': expRad,
      'distanceFromBranch': double.parse(distance.toStringAsFixed(2)),
      'withinRadius': within,
      'otherLocation': !within,
      if (reasonInfo != null) 'reasonId': reasonInfo['reasonId'],
      if (reasonInfo != null) 'reasonText': reasonInfo['reasonText'],
      if (reasonInfo != null) 'reasonTypeId': reasonInfo['reasonTypeId'],
      if (reasonInfo != null) 'reasonTypeName': reasonInfo['reasonTypeName'],
    };

    final prevState = (
      wasCheckedIn: isCheckedIn,
      wasTimerRunning: isTimerRunning,
      prevSeconds: totalSeconds,
      prevH: hours,
      prevM: minutes,
      prevS: seconds,
    );

    // Do NOT mark checked-in or persist check-in time yet. The backend is
    // authoritative: on success _loadTodayStatus() applies the server time
    // (and writes prefs/cache). Persisting here would leave a ghost
    // "checked in" state behind if the request fails.
    setState(() {
      _isAttendanceStatusLoading = true;
      _hasAttendanceApiConfirmed = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location verified. Checking in…')),
    );

    try {
      debugPrint('[GPS] API reached: attendance/check-in');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyMap),
      );

      Map<String, dynamic> responseData = <String, dynamic>{};
      try {
        responseData = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      final code = (responseData['code'] ?? '').toString();
      final message = (responseData['error'] ??
              responseData['message'] ??
              'Check-in failed')
          .toString();
      debugPrint('[Perf] attendance API responded ${res.statusCode} '
          '(${perfSw.elapsedMilliseconds}ms)');

      // Duplicate same-day check-in must rollback immediately.
      if (res.statusCode == 409 || code == 'ALREADY_CHECKED_IN') {
        await _rollbackAfterFailedCheckIn(
          wasCheckedIn: prevState.wasCheckedIn,
          wasTimerRunning: prevState.wasTimerRunning,
          prevSeconds: prevState.prevSeconds,
          prevH: prevState.prevH,
          prevM: prevState.prevM,
          prevS: prevState.prevS,
        );

        if (!mounted) return;
        setState(() {
          _checkInSource = '';
          _isAttendanceStatusLoading = false;
          _hasAttendanceApiConfirmed = true;
        });
        _showInfoDialog('Already checked in today');
        return;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint('[TRACKING] Check-in success - Starting tracking flow');

        // Use the authoritative check-in time committed by the backend
        // (checkIn = HH:mm:ss IST / checkInTsUtc = ISO-8601 UTC, written in
        // the same write). Never invent a client timestamp as a substitute.
        final serverCheckIn = (responseData['checkIn'] ?? '').toString();
        final serverCheckInTsUtc =
            (responseData['checkInTsUtc'] ?? '').toString();
        if (serverCheckIn.isNotEmpty) {
          _applyCheckedInFromServer(serverCheckIn);
        } else if (serverCheckInTsUtc.isNotEmpty) {
          final ts = DateTime.tryParse(serverCheckInTsUtc)?.toLocal();
          if (ts != null) {
            _applyCheckedInFromServer(
                '${ts.hour.toString().padLeft(2, '0')}:'
                '${ts.minute.toString().padLeft(2, '0')}:'
                '${ts.second.toString().padLeft(2, '0')}');
          }
        }

        if (_checkInTime != null) {
          // Authoritative time applied - persist exactly that timestamp and
          // skip the redundant status fetch.
          await _saveCheckInToPrefs(at: _checkInTime);
          _lastStatusFetch = DateTime.now();
        } else {
          // Older backend omitted the timestamp - brief confirming state,
          // then reconcile via the authoritative status endpoint.
          if (mounted) {
            setState(() {
              isCheckedIn = true;
              _isAttendanceStatusLoading = true;
            });
          }
          _lastStatusFetch = null;
          await _loadTodayStatus();
        }

        if (!mounted) return;
        setState(() {
          isCheckedIn = true;
          isTimerRunning = true;
          if (_checkInSource.isEmpty) _checkInSource = type.toLowerCase();
          _checkOutTime = null;
          _isAttendanceStatusLoading = false;
          _hasAttendanceApiConfirmed = true;
        });
        _startWorkTimer();
        debugPrint('[Perf] UI confirmed at ${perfSw.elapsedMilliseconds}ms');
        final presenceLabel = officePresenceLabel(
            responseData['officePresence']?.toString());
        _showSuccessDialog(
          (responseData['message']?.toString() ?? 'Checked in successfully!') +
              (presenceLabel != null ? '\n$presenceLabel' : ''),
        );

        // Tracking now owns location capture - release the warm-up stream.
        _stopGpsWarmup();
        _initTrackingAfterCheckIn(pos);
        return;
      }

      await _rollbackAfterFailedCheckIn(
        wasCheckedIn: prevState.wasCheckedIn,
        wasTimerRunning: prevState.wasTimerRunning,
        prevSeconds: prevState.prevSeconds,
        prevH: prevState.prevH,
        prevM: prevState.prevM,
        prevS: prevState.prevS,
      );

      if (!mounted) return;
      setState(() {
        _checkInSource = '';
        _isAttendanceStatusLoading = false;
        _hasAttendanceApiConfirmed = true;
      });
      _showErrorDialog(message);
    } catch (e) {
      // A timeout/network failure is ambiguous - the write may actually have
      // landed. Reconcile with the authoritative status before declaring
      // failure; if the server shows the check-in, treat it as success.
      _lastStatusFetch = null;
      await _loadTodayStatus();
      if (isCheckedIn) {
        if (!mounted) return;
        _stopGpsWarmup();
        _initTrackingAfterCheckIn(pos);
        _showSuccessDialog('Checked in successfully!');
        return;
      }

      await _rollbackAfterFailedCheckIn(
        wasCheckedIn: prevState.wasCheckedIn,
        wasTimerRunning: prevState.wasTimerRunning,
        prevSeconds: prevState.prevSeconds,
        prevH: prevState.prevH,
        prevM: prevState.prevM,
        prevS: prevState.prevS,
      );

      if (!mounted) return;
      setState(() {
        _checkInSource = '';
        _isAttendanceStatusLoading = false;
        _hasAttendanceApiConfirmed = true;
      });
      _showErrorDialog(_getUserFriendlyErrorMessage(e));
    }
  }

  // ── Tracking startup state machine ──────────────────────────────────────
  // Persisted states: not_started / starting / active / failed / recovering.
  // Bound to (empid, session date) so a different employee's or day's state
  // is never recovered after a logout/login on the same device.
  static const String _trkNotStarted = 'not_started';
  static const String _trkStarting = 'starting';
  static const String _trkActive = 'active';
  static const String _trkFailed = 'failed';
  static const String _trkRecovering = 'recovering';
  bool _trackingInitInFlight = false;
  int _trackingInitAttempts = 0;
  Timer? _trackingRetryTimer;
  // One-shot listener armed when timed retries are exhausted while offline
  // (or fail). The next offline->online transition re-runs reconciliation.
  StreamSubscription<bool>? _trackingRecoverySub;

  /// After the bounded backoff retries are exhausted, a failed tracking
  /// init would otherwise stay dead until the employee reopens this page.
  /// Arm a single connectivity listener instead: the first offline->online
  /// transition retries reconciliation once. Cancelled on success,
  /// check-out, or page disposal.
  void _listenForTrackingRecovery() {
    if (_trackingRecoverySub != null) return;
    _trackingRecoverySub = ConnectivityService.I.online$.listen((online) {
      if (!online) return;
      _trackingRecoverySub?.cancel();
      _trackingRecoverySub = null;
      if (!mounted || !isCheckedIn) return;
      unawaited(_ensureTrackingActive());
    });
  }

  Future<void> _setTrackingState(String state) async {
    final sp = await _prefs();
    await sp.setString(kTrackingStateKey, state);
    await sp.setString(kTrackingStateEmpKey, userId);
    await sp.setString(kTrackingStateDateKey, _todayYmd());
  }

  Future<void> _clearTrackingState() async {
    _trackingRetryTimer?.cancel();
    _trackingRecoverySub?.cancel();
    _trackingRecoverySub = null;
    _trackingInitAttempts = 0;
    final sp = await _prefs();
    await sp.remove(kTrackingStateKey);
    await sp.remove(kTrackingStateEmpKey);
    await sp.remove(kTrackingStateDateKey);
  }

  /// Non-blocking tracking startup after a CONFIRMED check-in. Returns
  /// immediately - init runs with persisted state, bounded retries and a
  /// visible failure indicator. Attendance confirmation never waits on it.
  void _initTrackingAfterCheckIn(Position? pos) {
    unawaited(_runTrackingInit(pos, isRecovery: false));
    unawaited(_ensureNotificationPermission());
    unawaited(_maybePromptBatteryOptimization());
  }

  /// Idempotent init: one attempt at a time. Seeding with the validated
  /// attendance position is awaited ONLY inside here (so `bg_last_pos_ms`
  /// lands before the foreground service's immediate tick), then the FG
  /// service, Workmanager and TrackingService launch in order.
  Future<void> _runTrackingInit(Position? pos,
      {required bool isRecovery}) async {
    if (_trackingInitInFlight) return;
    _trackingInitInFlight = true;
    final sw = Stopwatch()..start();
    try {
      await _setTrackingState(isRecovery ? _trkRecovering : _trkStarting);

      if (pos != null) {
        // Validated attendance position - seed once, no second GPS burst.
        await _trackingCheckInAndSeed(pos);
      } else {
        // Recovery: ensure the backend session exists. Never seed a stored
        // or stale position - a live capture is only done by the services.
        await _trackingSessionCheckIn();
      }
      debugPrint('[Perf] tracking session up (${sw.elapsedMilliseconds}ms)');

      // A fresh check-in re-pins the tracking session date to today;
      // recovery keeps the existing pin so overnight shifts stay on their
      // original tracking document.
      await startFgTracking(
          empid: userId,
          token: CompanyData.token,
          newSession: !isRecovery);
      // A persisted flag does not prove the Android service is alive.
      if (!await isForegroundTrackingRunning()) {
        throw StateError('foreground service did not start');
      }
      debugPrint('[Perf] FG service up (${sw.elapsedMilliseconds}ms)');

      await scheduleBackgroundTracking(
          empid: userId, token: CompanyData.token);
      _tracking ??= TrackingService(
        apiBase: _apiBase,
        jwtToken: CompanyData.token,
        empId: userId,
      );
      await _tracking!.startAfterCheckIn(initialPosition: pos);

      await _setTrackingState(_trkActive);
      _trackingInitAttempts = 0;
      _trackingRecoverySub?.cancel();
      _trackingRecoverySub = null;
      debugPrint('[Perf] tracking active (${sw.elapsedMilliseconds}ms)');
      if (isRecovery && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live tracking active')),
        );
      }
    } catch (e) {
      debugPrint('[TRACKING] init failed: $e');
      await _setTrackingState(_trkFailed);
      _scheduleTrackingRetry();
      if (!mounted) return;
      if (_trackingInitAttempts >= kMaxTrackingInitAttempts) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Checked in - tracking could not start. Reopen the app to retry.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Checked in - tracking needs attention. Retrying in background.')));
      }
    } finally {
      _trackingInitInFlight = false;
    }
  }

  /// Bounded backoff retry: max 3 attempts (5s/15s/45s). Never retries after
  /// check-out/logout - isCheckedIn is reconciled with the authoritative
  /// status before the timer fires.
  void _scheduleTrackingRetry() {
    _trackingRetryTimer?.cancel();
    final delay = trackingInitRetryDelay(_trackingInitAttempts);
    if (delay == null) {
      debugPrint('[TRACKING] retry limit reached - arming reconnect recovery');
      _listenForTrackingRecovery();
      return;
    }
    _trackingInitAttempts++;
    _trackingRetryTimer = Timer(delay, () async {
      if (!mounted || !isCheckedIn) return;
      // Do not burn a retry attempt while offline: the init cannot get past
      // the session check-in call without connectivity. Wait for the
      // offline->online transition instead.
      final online = await ConnectivityService.I.isOnline
          .catchError((_) => true); // unknown -> try anyway
      if (!online) {
        _listenForTrackingRecovery();
        return;
      }
      unawaited(_runTrackingInit(null, isRecovery: true));
    });
  }

  /// Idempotent reconciliation: called after the authoritative attendance
  /// status confirms an active check-in (app launch, login, page return,
  /// lifecycle resume). Recovers tracking if it isn't actually running.
  Future<void> _ensureTrackingActive() async {
    if (!isCheckedIn || _trackingInitInFlight || userId.isEmpty) return;
    try {
      final sp = await _prefs();
      final owner = sp.getString(kTrackingStateEmpKey);
      final date = sp.getString(kTrackingStateDateKey);
      // A different employee's or day's recovery state must never be reused.
      if (owner != userId || date != _todayYmd()) {
        await _clearTrackingState();
        unawaited(_runTrackingInit(null, isRecovery: true));
        return;
      }
      final state = sp.getString(kTrackingStateKey) ?? _trkNotStarted;
      if (state == _trkActive && await isForegroundTrackingRunning()) {
        return; // healthy - nothing to do
      }
      unawaited(_runTrackingInit(null, isRecovery: true));
    } catch (_) {}
  }

  Future<void> _authenticateAndCheckOut() async {
    try {
      _authInProgress = true;

      // Check biometric availability before authentication
      final canBio = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      debugPrint('[BIOMETRIC] CheckOut - canCheckBiometrics: $canBio');
      debugPrint('[BIOMETRIC] CheckOut - isDeviceSupported: $supported');
      debugPrint(
          '[BIOMETRIC] CheckOut - availableBiometrics: $availableBiometrics');

      if (!canBio || !supported) {
        _showErrorDialog(
            'Biometric authentication is not available on this device. Please use manual attendance or enable biometric authentication on your phone.');
        return;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to check out',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs:
              false, // Disable system error dialogs to show custom messages
          sensitiveTransaction: true,
        ),
      );

      if (ok) {
        _confirmCheckOut(proceedAction: () => _performCheckOut());
      } else {
        _showErrorDialog(
            'Biometric verification was not completed. Please try again or use manual attendance.');
      }
    } catch (e) {
      debugPrint('[BIOMETRIC] CheckOut authentication error: $e');
      _showErrorDialog(
          'Biometric verification was not completed. Please try again or use manual attendance.');
    } finally {
      _authInProgress = false;
    }
  }

  Future<void> _performCheckOut({bool silent = false}) async {
    // ✅ FIX: block multiple checkout calls
    if (_checkoutInProgress) return;
    _checkoutInProgress = true;

    try {
      // Ensure shift times are loaded before validation
      if (_shiftTimes == null) {
        await _loadShiftTimes();
      }

      if (_shiftTimes == null) {
        _showInfoDialog(_shiftLoadError ??
            'Shift time is not loaded. Please refresh or contact admin.');
        return;
      }

      Map<String, String>? reasonInfo;
      final category = _detectCheckoutCategory();
      if (category != null) {
        reasonInfo = await _pickReason(category, prefer: category);
        if (category.isNotEmpty && reasonInfo == null) {
          if (!silent) _showInfoDialog('Checkout cancelled');
          return;
        }
      }

      // Geofencing is an optional company-level policy resolved
      // authoritatively by the backend — see _performCheckIn.
      final geo = await _fetchAssignedGeo();
      final geoEnabled = geo.lookupOk &&
          (geo.geofencingEnabled || geo.legacyCompatibilityMode);

      Position? pos;
      if (geoEnabled) {
        pos = await _getHighAccuracyPosition(
          quiet: silent,
          actionLabel: 'check-out',
          maxAccuracyMeters: 50.0,
        );
        if (pos == null) {
          _log('[ManualAttendance] Checkout location acquisition failed');
          return;
        }
      } else {
        pos = await _getBestEffortPosition();
      }

      bool within = true;
      double distance = 0.0;
      String branchName = location;
      double expLat = 0, expLng = 0, expRad = 0;

      if (geoEnabled) {
        final branch = geo.branch;

        if (branch != null) {
          branchName = branch.name;
          expLat = branch.lat;
          expLng = branch.lng;
          expRad = branch.radius;

          distance = _distanceMeters(
            lat1: pos!.latitude,
            lng1: pos.longitude,
            lat2: branch.lat,
            lng2: branch.lng,
          );

          within = distance <= branch.radius;

          debugPrint('[CHECKOUT RADIUS] Branch: $branchName');
          debugPrint(
              '[CHECKOUT RADIUS] Distance: ${distance.toStringAsFixed(2)}m');
          debugPrint(
              '[CHECKOUT RADIUS] Radius: ${branch.radius.toStringAsFixed(2)}m');
          debugPrint('[CHECKOUT RADIUS] Within radius: $within');

          if (!within) {
            // Same rule as check-in: prompt only when the fix is
            // confidently outside the geofence (accuracy radius fully
            // clears the boundary).
            final confidentlyOutside =
                distance - pos.accuracy > branch.radius;
            if (confidentlyOutside) {
              final ok = await _confirmOutside(
                distance: distance,
                radius: branch.radius,
                branchName: branch.name,
                actionLabel: 'check-out',
              );

              if (!ok) {
                if (!silent) {
                  _showInfoDialog('Checkout cancelled');
                }
                return;
              }
            }
          }
        } else if (geo.geofencingEnabled) {
          _showErrorDialog(
              'Office location is not configured for your branch. Please contact HR.');
          return;
        } else {
          debugPrint(
              '[CHECKOUT RADIUS] Branch not found. Asking confirmation.');

          final ok = await _confirmOutside(
            branchName:
                location.isEmpty ? 'Unknown location' : location,
            actionLabel: 'check-out',
          );

          if (!ok) {
            if (!silent) {
              _showInfoDialog('Checkout cancelled');
            }
            return;
          }

          within = false;
          branchName = location.isEmpty ? 'Unknown location' : location;
        }
      }
      final token = CompanyData.token;
      final url = Uri.parse('${ApiService.baseUrl}/attendance/check-out');

      final bodyMap = {
        'empid': userId,
        'location': location,
        'latitude': pos?.latitude,
        'longitude': pos?.longitude,
        'accuracy': pos?.accuracy,
        'isMocked': pos?.isMocked ?? false,
        // UTC timestamp of the accepted GPS fix itself (ISO 8601).
        'locationTimestamp': pos?.timestamp.toUtc().toIso8601String(),
        'branchName': branchName,
        'expectedLatitude': expLat,
        'expectedLongitude': expLng,
        'expectedRadius': expRad,
        'distanceFromBranch': double.parse(distance.toStringAsFixed(2)),
        'withinRadius': within,
        'otherLocation': !within,
        if (reasonInfo != null) 'reasonId': reasonInfo['reasonId'],
        if (reasonInfo != null) 'reasonText': reasonInfo['reasonText'],
        if (reasonInfo != null) 'reasonTypeId': reasonInfo['reasonTypeId'],
        if (reasonInfo != null) 'reasonTypeName': reasonInfo['reasonTypeName'],
      };

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checking out…')),
        );
      }

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyMap),
      );

      if (res.statusCode == 200) {
        // Stop retries/recovery BEFORE clearing checked-in state.
        await _clearTrackingState();
        await stopFgTracking();
        await cancelBackgroundTracking(empid: userId);
        await _tracking?.stopAfterCheckOut();
        // Close the tracking doc while the pinned session date is still
        // readable (overnight check-outs need it; the backend also closes
        // server-side and scans the previous day as a fallback).
        await _trackingCheckOut();
        // Drop the tracking-specific persisted identity so a sticky-restarted
        // service isolate finds empty credentials and self-disables. The
        // login session ('token', 'empid') is untouched - the employee stays
        // signed in; only tracking attribution keys are cleared.
        await clearTrackingSessionIdentity();

        _stopWorkTimer();
        await _clearCheckInFromPrefs();
        await _clearCheckInCache(); // Clear cache on successful check-out
        setState(() {
          isCheckedIn = false;
          _checkOutTime = DateTime.now();
          _checkInSource = '';
        });
      } else {
        final msg =
            (jsonDecode(res.body)['error'] ?? jsonDecode(res.body)['message'])
                .toString();
        if (!silent) _showErrorDialog(msg);
      }
    } catch (e) {
      if (!silent) {
        _showErrorDialog(_getUserFriendlyErrorMessage(e));
      }
    } finally {
      // ✅ always release lock
      _checkoutInProgress = false;
    }
  }

  /// POST /tracking/check-in only - ensures the backend session exists.
  /// Idempotent server-side; throws on failure so the startup state machine
  /// can detect and retry.
  Future<void> _trackingSessionCheckIn() async {
    final token = CompanyData.token;
    if (token.isEmpty || userId.isEmpty) {
      throw StateError('missing tracking credentials');
    }
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/tracking/check-in'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-empid': userId,
          },
          body: jsonEncode({'dateIso': trackingDateIso()}),
        )
        .timeout(const Duration(seconds: 15));
    debugPrint('[TRACKING] session creation status=${res.statusCode}');
    if (res.statusCode != 200) {
      throw StateError('tracking check-in HTTP ${res.statusCode}');
    }
    if (kDebugMode) {
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        debugPrint('[TRACKING] tracking document found=${body['existed']} '
            'reopened=${body['reopened']} backend pathMap count=${body['pathMapCount']}');
      } catch (_) {}
    }
  }

  // The validated attendance fix is only used as the seed while it is fresh;
  // an older fix falls through to a live capture by the tracking services.
  static const Duration _kSeedMaxFixAge = Duration(minutes: 5);
  static const List<Duration> _kSeedRetryBackoffs = [
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  /// Ensures the session exists, then persists the validated attendance
  /// position as the first pathMap point. Succeeds only when the backend
  /// confirms the point is stored (or a point < 15 min old already exists).
  /// Throws otherwise so the startup state machine records a failure and
  /// retries with a live capture.
  Future<void> _trackingCheckInAndSeed(Position pos) async {
    debugPrint('[TRACKING] attendance confirmed - starting tracking session');

    // A marker left over from an earlier session must never suppress the
    // first capture of this one. It is re-written only after confirmation.
    final sp = await _prefs();
    await sp.remove(kLastPersistedPosMsKey);

    await _trackingSessionCheckIn();

    final fixAge = DateTime.now().difference(pos.timestamp);
    if (fixAge > _kSeedMaxFixAge) {
      throw StateError('check-in fix too old for seed (${fixAge.inSeconds}s)');
    }

    final dateIso = trackingDateIso();
    // Same id on every retry -> backend stores the seed at most once.
    // `mocked` propagates the platform's mock-location flag so a spoofed
    // check-in seed is flagged server-side rather than trusted silently.
    if (pos.isMocked) {
      debugPrint('[TRACKING] check-in seed position is mocked - flagging');
    }
    final payload = buildTrackingPointPayloadFromPosition(
      empid: userId,
      position: pos,
      source: 'checkin-seed',
      // Capture-instant identity: shared with every other producer so a
      // seed the foreground service also captures dedupes cleanly.
      pointId: trackingPointIdFor(pos.timestamp),
    );
    // The tracking doc key is the SESSION date (today), not the fix's
    // timestamp date - identical unless a <5-min-old seed straddles
    // midnight, in which case the session date must still win.
    payload['dateIso'] = dateIso;

    TrackingPostResult result = const TrackingPostResult(0, 'http_error', null);
    for (var attempt = 0; attempt <= _kSeedRetryBackoffs.length; attempt++) {
      if (attempt > 0) await Future.delayed(_kSeedRetryBackoffs[attempt - 1]);
      try {
        final res = await http
            .post(
              Uri.parse('${ApiService.baseUrl}/tracking/pos'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${CompanyData.token}',
                'x-empid': userId,
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 15));
        result = TrackingPostResult.fromResponse(res);
      } catch (e) {
        result = const TrackingPostResult(0, 'http_error', null);
        debugPrint('[TRACKING] initial point POST error (attempt ${attempt + 1})');
      }
      debugPrint('[TRACKING] initial point POST attempt=${attempt + 1} $result');
      if (!result.retryable) break;
    }

    debugPrint('[TRACKING] initial point persisted=${result.persisted}');
    if (result.recentPointExists) {
      await sp.setInt(
          kLastPersistedPosMsKey, DateTime.now().millisecondsSinceEpoch);
      trackingPointPersisted.value++;
      return;
    }
    if (result.status == 'too_close') {
      // pathMap already has an older point at this spot - nothing lost, but
      // no marker: the FG service's next tick captures normally.
      debugPrint('[TRACKING] point skip reason=too_close');
      return;
    }
    debugPrint('[TRACKING] point skip reason=${result.status}');
    throw StateError('initial tracking point not persisted (${result.status})');
  }

  Future<void> _trackingCheckOut() async {
    final token = CompanyData.token;
    if (token.isEmpty || userId.isEmpty) return;
    try {
      final base = '${ApiService.baseUrl}/tracking';
      // Close the SESSION's document, not today's date - for an overnight
      // shift these differ (check-in before midnight, check-out after).
      // The pinned date is cleared by clearTrackingSessionIdentity, which
      // runs BEFORE this call on the success path, so fall back to today
      // when it is already gone (the backend also scans the previous day).
      final localDateIso = await trackingSessionDateIso();

      final response = await http.post(
        Uri.parse('$base/check-out'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': userId,
        },
        body: jsonEncode({
          'empid': userId,
          'dateIso': localDateIso,
          'eventId': 'logout_${userId}_$localDateIso',
        }),
      );

      debugPrint(
          '[Attendance] Tracking check-out response: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint(
            '[Attendance] Tracking check-out failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Attendance] Tracking check-out error occurred');
    }
  }

  Future<void> _ensureNotificationPermission() async {
    // permission_handler has no web implementation; browsers manage
    // notification permission per-site.
    if (kIsWeb) return;
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// TEMPORARY DIAGNOSTIC ONLY (debug builds, Android). Runs Geolocator's
  /// acquisition and a direct native Fused Location Provider call
  /// (PRIORITY_HIGH_ACCURACY) back-to-back and logs both so results can be
  /// compared on the same device under the same conditions. Does not affect
  /// check-in, geofencing, or tracking - it never writes _checkInTime, never
  /// POSTs anywhere, and runs only when explicitly triggered from a
  /// debug-only button.
  ///
  /// Guarded by [_gpsDiagnosticRunning]: a fast double-tap must not start a
  /// second overlapping native FLP + Geolocator capture (duplicate GPS
  /// sampling, confusing interleaved [GPS_DIAG] logs).
  Future<void> _runGpsDiagnosticComparison() async {
    if (_gpsDiagnosticRunning) {
      debugPrint('[GPS_DIAG] already running - ignoring duplicate trigger');
      return;
    }
    _gpsDiagnosticRunning = true;
    if (mounted) setState(() {});

    debugPrint('[GPS_DIAG] ==== starting Flutter vs native FLP comparison ====');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Running GPS diagnostic - see debug console'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      await _runGpsDiagnosticComparisonBody();
    } finally {
      _gpsDiagnosticRunning = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _runGpsDiagnosticComparisonBody() async {
    Position? flutterPos;
    // Reuse the page's already-running warm-up stream when present - the
    // same pattern _getHighAccuracyPosition uses - instead of opening a
    // second concurrent FLP LocationRequest. Two simultaneous
    // bestForNavigation requests from this app were observed to trigger
    // Android's internal "location delivery blocked (too fast/too
    // close/too inaccurate)" throttling between requests; it never
    // corrupted results, but it's wasted GPS/battery activity and an
    // avoidable extra GPS consumer.
    if (_gpsWarmSub != null && _warmBest != null) {
      flutterPos = _warmBest;
      debugPrint('[GPS_DIAG] Reusing shared warm-up stream fix '
          '(no second concurrent FLP request opened)');
    } else {
      try {
        flutterPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 30),
          forceAndroidLocationManager: false,
        );
      } catch (e) {
        debugPrint('[GPS_DIAG] Geolocator (Flutter/FLP) call failed: $e');
      }
    }
    if (flutterPos != null) {
      debugPrint('[GPS_DIAG] Geolocator result: '
          'accuracy=${flutterPos.accuracy.toStringAsFixed(1)}m, '
          'timestamp=${flutterPos.timestamp.toIso8601String()}, '
          'mocked=${flutterPos.isMocked}, provider=unavailable via geolocator');
    } else {
      debugPrint('[GPS_DIAG] Geolocator result: null (no fix within timeout)');
    }

    final native = await NativeGpsDiagnostic.fusedLocationOnce();
    if (native == null) {
      debugPrint('[GPS_DIAG] Native FLP result: unavailable '
          '(not Android debug build, or call failed - see prior log line)');
    } else {
      final fused = native['fused'] as Map?;
      final gpsLastKnown = native['gpsProviderLastKnown'] as Map?;
      if (fused != null) {
        debugPrint('[GPS_DIAG] Native FLP (PRIORITY_HIGH_ACCURACY) result: '
            'accuracy=${fused['accuracy']}m, '
            'provider=${fused['provider']}, '
            'timestamp=${fused['timestampIso']}, '
            'mocked=${fused['isMocked']}');
      } else {
        debugPrint('[GPS_DIAG] Native FLP result: null (no fix within timeout)');
      }
      if (gpsLastKnown != null) {
        debugPrint('[GPS_DIAG] Raw LocationManager GPS_PROVIDER last-known: '
            'accuracy=${gpsLastKnown['accuracy']}m, '
            'provider=${gpsLastKnown['provider']}, '
            'timestamp=${gpsLastKnown['timestampIso']}');
      } else {
        debugPrint('[GPS_DIAG] Raw LocationManager GPS_PROVIDER last-known: none available');
      }
    }

    if (flutterPos != null && native?['fused'] != null) {
      final nativeAcc = (native!['fused'] as Map)['accuracy'] as num?;
      if (nativeAcc != null) {
        final delta = (flutterPos.accuracy - nativeAcc).abs();
        debugPrint('[GPS_DIAG] Accuracy delta (Geolocator vs native FLP): '
            '${delta.toStringAsFixed(1)}m - both call the same Play Services '
            'API at the same priority, so a large delta points to timing, '
            'not implementation.');
      }
    }

    // Raw GPS_PROVIDER + GnssStatus capture - bypasses FLP entirely, so it
    // can tell apart "no satellite fix" / "GNSS fix with poor accuracy" /
    // "network-only location", none of which the blended `fused` result
    // above can distinguish. ~25s, cancellable, lifecycle-safe (see
    // NativeGpsDiagnostic.kt cleanupRawGpsCapture).
    debugPrint('[GPS_DIAG] ---- starting raw GPS_PROVIDER capture (up to '
        '25s, cancels early on an accurate fix) ----');
    if (!mounted) {
      await NativeGpsDiagnostic.cancelRawGpsCapture();
      debugPrint('[GPS_DIAG] ==== comparison complete (cancelled - page gone) ====');
      return;
    }
    final rawGps = await NativeGpsDiagnostic.rawGpsProviderCapture();
    if (!mounted) {
      // Page was disposed while the capture was running; it already
      // finished/was cancelled on the native side via onDetachedFromEngine
      // or dispose()'s explicit cancel below. Nothing left to log safely.
      return;
    }
    if (rawGps == null) {
      debugPrint('[GPS_DIAG] Raw GPS_PROVIDER capture: unavailable '
          '(not Android debug build, or call failed/cancelled)');
    } else {
      final fixState = rawGps['fixState'];
      final fix = rawGps['fix'] as Map?;
      debugPrint('[GPS_DIAG] Raw GPS_PROVIDER capture result: '
          'fixState=$fixState, '
          'gpsProviderEnabled=${rawGps['gpsProviderEnabled']}, '
          'satelliteCount=${rawGps['satelliteCount']}, '
          'satellitesUsedInFix=${rawGps['satellitesUsedInFix']}, '
          'timeToFirstFixMs=${rawGps['timeToFirstFixMs']}, '
          'captureDurationMs=${rawGps['captureDurationMs']}');
      if (fix != null) {
        debugPrint('[GPS_DIAG] Raw GPS_PROVIDER fix: '
            'accuracy=${fix['accuracy']}m, provider=${fix['provider']}, '
            'timestamp=${fix['timestampIso']}, mocked=${fix['isMocked']}');
      }
      switch (fixState) {
        case 'gps_provider_disabled':
          debugPrint('[GPS_DIAG] Interpretation: GPS_PROVIDER is disabled '
              'at the OS level - enable Location/GPS and retest.');
          break;
        case 'no_satellites_detected':
          debugPrint('[GPS_DIAG] Interpretation: NO GNSS satellite fix - '
              'the chip saw zero satellites in 25s. This is a sky-view/'
              'environment/hardware issue, not an app bug: go outdoors '
              'with a clear view of the sky and retest.');
          break;
        case 'satellites_visible_no_fix':
          debugPrint('[GPS_DIAG] Interpretation: satellites are visible '
              'but none were usable for a fix yet (weak signal / still '
              'acquiring). Retest with more time or a clearer sky view.');
          break;
        case 'satellites_used_but_no_location_yet':
          debugPrint('[GPS_DIAG] Interpretation: satellites are being '
              'used but no Location was emitted in the capture window - '
              'borderline convergence, retest.');
          break;
        case 'gps_fix_poor_accuracy':
          debugPrint('[GPS_DIAG] Interpretation: GENUINE GNSS fix, but '
              'above the 50m check-in threshold - real satellite-based '
              'accuracy limitation (multipath/indoor/cold start), not a '
              'network-only fallback and not an app bug.');
          break;
        case 'gps_fix_accurate':
          debugPrint('[GPS_DIAG] Interpretation: accurate GNSS fix '
              'obtained directly from GPS_PROVIDER (<=50m) - if Geolocator/'
              'FLP above still reported ~200m, the discrepancy is in how '
              'FLP blends/throttles sources, not raw GPS hardware '
              'capability.');
          break;
      }
    }
    debugPrint('[GPS_DIAG] ==== comparison complete ====');
  }

  /// One-time-per-install battery-exemption prompt, shown only when
  /// tracking just started and the app is NOT already exempt. The direct
  /// REQUEST_IGNORE_BATTERY_OPTIMIZATIONS intent is Play-permitted for a
  /// declared foreground-location app; exemption is a convenience, never
  /// required for attendance, and declining it is respected permanently.
  static const String _kBatteryPromptedKey = 'battery_opt_prompted';
  Future<void> _maybePromptBatteryOptimization() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final exempt = await BatteryOptimization.isExempt();
      final sp = await _prefs();
      final promptedBefore = sp.getBool(_kBatteryPromptedKey) ?? false;
      if (!shouldPromptBatteryExemption(
        isAndroid: true,
        alreadyExempt: exempt,
        promptedBefore: promptedBefore,
      )) {
        return;
      }
      // Record BEFORE launching - a dismissed/cancelled dialog still
      // counts as prompted; nagging on every check-in is worse.
      await sp.setBool(_kBatteryPromptedKey, true);
      try {
        await AndroidIntent(
          action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
          arguments: {'package': 'com.serv.serv_app'},
        ).launch();
      } catch (_) {
        // Fallback: some OEMs reject the direct request - open the
        // exemption list instead. (Fixed: was IGNORE_BATTERY_OPTIMATION_,
        // a typo'd nonexistent action.)
        try {
          await AndroidIntent(
            action:
                'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          ).launch();
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _startWorkTimer() {
    // Only start timer if check-in data is available
    if (_checkInTime == null) return;

    _timer?.cancel();

    // Calculate elapsed time from actual check-in time
    final now = DateTime.now();
    final elapsedSeconds = now.difference(_checkInTime!).inSeconds;
    final startSeconds = elapsedSeconds > 0 ? elapsedSeconds : 0;

    debugPrint('[Timer] Timer started');

    setState(() {
      isTimerRunning = true;
      totalSeconds = startSeconds;
      hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
      minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
      seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        totalSeconds++;
        hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
        minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
        seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      });
    });
  }

  void _stopWorkTimer() {
    final h = hours, m = minutes, s = seconds;
    _resetTimerAndState();
    _showSuccessDialog(
        'Check-out successful!\nWork duration: ${h}h ${m}m ${s}s');
  }

  /// Loads the employee's assigned shift via the backend — the server
  /// resolves companyId + empid from the JWT, then the canonical shift doc
  /// (shiftId first, shiftGroup name fallback). This replaces the old
  /// client-side Firestore query, which could not satisfy the shifts
  /// security rules (no Firebase Auth token carries the companyId claim).
  Future<void> _loadShiftTimes() async {
    try {
      final token = CompanyData.token;
      if (token.isEmpty) {
        _shiftTimes = null;
        _shiftLoadError = 'Not signed in. Please log in again.';
        return;
      }

      final res = await http.get(
        Uri.parse('$_apiBase/shifts/assigned'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) {
        debugPrint('[SHIFT] assigned shift fetch failed: ${res.statusCode}');
        _shiftTimes = null;
        _shiftLoadError =
            'Could not load shift details. Please refresh or contact admin.';
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final shift = data['shift'];

      if (shift is! Map<String, dynamic>) {
        final reason = data['reason']?.toString() ?? '';
        debugPrint('[SHIFT] no assigned shift: $reason');
        _shiftTimes = null;
        _shiftLoadError = reason == 'SHIFT_NOT_FOUND'
            ? 'Your assigned shift is no longer available. Please contact admin.'
            : 'No shift is assigned to your account. Please contact admin.';
        return;
      }

      final startStr = (shift['startTime'] ?? '').toString().trim();
      final endStr = (shift['endTime'] ?? '').toString().trim();

      TimeOfDay? start = _parseHHmm(startStr);
      TimeOfDay? end = _parseHHmm(endStr);

      if (start == null || end == null) {
        final nameStr = (shift['name'] ?? '').toString();
        final pair = _parseNameRange(nameStr);
        start ??= pair?.start;
        end ??= pair?.end;
      }

      if (start != null && end != null) {
        _shiftTimes = ShiftTimes(start, end);
        _shiftLoadError = null;
        // Sync the displayed shift name with the resolved assignment.
        final resolvedName =
            (shift['name'] ?? shift['shiftname'] ?? '').toString().trim();
        if (resolvedName.isNotEmpty &&
            (selectedShift.isEmpty || selectedShift == 'Shift')) {
          selectedShift = resolvedName;
          shiftClicked = true;
          isShiftSelected = true;
        }
        debugPrint('[SHIFT] Shift times loaded successfully');
      } else {
        _shiftTimes = null;
        _shiftLoadError =
            'Your shift timings are not configured. Please contact admin.';
        debugPrint('[SHIFT] Failed to parse shift times');
      }
    } catch (e) {
      debugPrint('[SHIFT] _loadShiftTimes error occurred');
      _shiftTimes = null;
      _shiftLoadError =
          'Could not load shift details. Please refresh or contact admin.';
    }

    if (mounted) setState(() {});
  }

  ShiftTimes? _getShiftTimes(String shift) {
    return _shiftTimes;
  }

  TimeOfDay? _parseHHmm(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final min = int.tryParse(m.group(2)!);
    if (h == null || min == null) return null;
    if (h < 0 || h > 23 || min < 0 || min > 59) return null;
    return TimeOfDay(hour: h, minute: min);
  }

  ShiftTimes? _parseNameRange(String s) {
    final m = RegExp(
      r'(\d{1,2})(?:[:\.](\d{1,2}))?\s*(AM|PM)\s*-\s*(\d{1,2})(?:[:\.](\d{1,2}))?\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(s);
    if (m == null) return null;

    int h1 = int.parse(m.group(1)!);
    int m1 = int.tryParse(m.group(2) ?? '0') ?? 0;
    final p1 = (m.group(3) ?? '').toUpperCase();

    int h2 = int.parse(m.group(4)!);
    int m2 = int.tryParse(m.group(5) ?? '0') ?? 0;
    final p2 = (m.group(6) ?? '').toUpperCase();

    h1 = _to24h(h1, p1);
    h2 = _to24h(h2, p2);

    return ShiftTimes(
        TimeOfDay(hour: h1, minute: m1), TimeOfDay(hour: h2, minute: m2));
  }

  int _to24h(int h, String period) {
    int hh = h % 12;
    if (period == 'PM') hh += 12;
    return hh;
  }

  DateTime _toDateTime(TimeOfDay tod, {DateTime? base}) {
    final b = base ?? DateTime.now();
    return DateTime(b.year, b.month, b.day, tod.hour, tod.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
              color: kTextColor, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              top: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('$userId | $dept',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                !_hasAttendanceApiConfirmed ||
                                        _isAttendanceStatusLoading
                                    ? (_attendanceStatusError != null
                                        ? 'In: $_attendanceStatusError'
                                        : 'In: Syncing attendance...')
                                    : _checkInTime != null
                                        ? 'In: ${_formatTime(_checkInTime)}'
                                        : 'In: Not checked in',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isCheckedIn
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                !_hasAttendanceApiConfirmed ||
                                        _isAttendanceStatusLoading
                                    ? (_attendanceStatusError != null
                                        ? 'Out: $_attendanceStatusError'
                                        : 'Out: Syncing attendance...')
                                    : _checkOutTime != null
                                        ? 'Out: ${_formatTime(_checkOutTime)}'
                                        : 'Out: Not checked out',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _checkOutTime != null
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            (() {
                              final today = DateTime.now();
                              final formattedDate =
                                  "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";

                              // Debug logs
                              // print("ATTENDANCE DATE API: $_checkInTime");
                              // print("FORMATTED DATE: $formattedDate");

                              // Use check-in date if available, otherwise today's date
                              if (_checkInTime != null) {
                                final checkInDate = DateTime(_checkInTime!.year,
                                    _checkInTime!.month, _checkInTime!.day);
                                return "${checkInDate.day.toString().padLeft(2, '0')}-${checkInDate.month.toString().padLeft(2, '0')}-${checkInDate.year}";
                              }
                              return formattedDate;
                            })(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 96,
                  height: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                        'assets/images/native_splash_logo-removebg.png',
                        fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 15),
                // Timer remains as 00:00:00 while attendance time is syncing.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeBox(hours),
                    const SizedBox(width: 6),
                    const Text(
                      ':',
                      style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 169, 163, 182),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    _buildTimeBox(minutes),
                    const SizedBox(width: 6),
                    const Text(
                      ':',
                      style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 169, 163, 182),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    _buildTimeBox(seconds),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: kButtonColor,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(selectedShift,
                      style: const TextStyle(
                          color: kTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 15),
                if (_locationServiceEnabled == false)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.location_off,
                            color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location is turned OFF. Enable Location to use Manual or Biometric Attendance.',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_locationServiceEnabled != false &&
                    _locationPermissionGranted &&
                    !_preciseLocationGranted &&
                    !isCheckedIn)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.my_location,
                            color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Precise location is off. Check-in requires high GPS accuracy.',
                            style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Live GPS readiness: shows real warm-up accuracy so the
                // employee knows check-in is ready before tapping.
                if (!isCheckedIn && _locationServiceEnabled != false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Builder(builder: (_) {
                      final ready = _shownWarmAccuracy != null &&
                          _shownWarmAccuracy! <= 50;
                      final label = _gpsWarmSub == null
                          ? 'Preparing GPS…'
                          : _shownWarmAccuracy == null
                              ? 'Finding accurate location…'
                              : ready
                                  ? 'GPS ready for attendance'
                                  : 'GPS accuracy: '
                                      '${_shownWarmAccuracy!.toStringAsFixed(0)}m,'
                                      ' required: 50m';
                      final color = ready ? Colors.green : Colors.blueGrey;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            ready ? Icons.gps_fixed : Icons.gps_not_fixed,
                            color: color, size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    }),
                  ),
                // TEMPORARY DIAGNOSTIC (debug builds, Android only): compares
                // Geolocator's result against a direct native Fused Location
                // Provider call at PRIORITY_HIGH_ACCURACY on the same device
                // under the same conditions. Not part of check-in; never
                // shown in release builds.
                if (kDebugMode && NativeGpsDiagnostic.isSupported && !isCheckedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextButton.icon(
                      onPressed: _gpsDiagnosticRunning
                          ? null
                          : _runGpsDiagnosticComparison,
                      icon: const Icon(Icons.bug_report, size: 14),
                      label: Text(
                          _gpsDiagnosticRunning
                              ? 'Running GPS diagnostic…'
                              : 'Run GPS diagnostic (debug)',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                if (!isCheckedIn)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Biometric Button
                        SizedBox(
                          width: 140,
                          child: Opacity(
                            opacity: _isManualLoading ? 0.5 : 1.0,
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: (_isManualLoading ||
                                        _isBiometricLoading ||
                                        _locationServiceEnabled == false ||
                                        !_hasAttendanceApiConfirmed)
                                    ? null
                                    : () async {
                                        await _authenticateAndCheckIn();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kButtonColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                child: FittedBox(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _isBiometricLoading
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(kTextColor),
                                              ),
                                            )
                                          : const Icon(Icons.face,
                                              color: kTextColor, size: 14),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isBiometricLoading
                                            ? 'Checking...'
                                            : 'Biometric',
                                        style: const TextStyle(
                                          color: kTextColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Manual Button
                        SizedBox(
                          width: 140,
                          child: Opacity(
                            opacity: _isBiometricLoading ? 0.5 : 1.0,
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: (_isManualLoading ||
                                        _isBiometricLoading ||
                                        _locationServiceEnabled == false ||
                                        !_hasAttendanceApiConfirmed)
                                    ? null
                                    : () async {
                                        await _handleManualCheckInTap();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kButtonColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                child: FittedBox(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _isManualLoading
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(kTextColor),
                                              ),
                                            )
                                          : const Icon(Icons.touch_app,
                                              color: kTextColor, size: 14),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isManualLoading
                                            ? 'Checking...'
                                            : 'Manual',
                                        style: const TextStyle(
                                          color: kTextColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isCheckedIn)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _checkoutInProgress
                              ? null
                              : () {
                                  if (_checkInSource == 'biometric') {
                                    _authenticateAndCheckOut();
                                  } else {
                                    _confirmCheckOut(
                                        proceedAction: () =>
                                            _performCheckOut());
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: kTextColor, size: 13),
                              SizedBox(width: 8),
                              Text('Check Out',
                                  style: TextStyle(
                                      color: kTextColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Tracking Active',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox(String time) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kButtonColor,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month];
  }

  void _confirmCheckOut({required VoidCallback proceedAction}) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        title: const Text('Check Out'),
        content: Text(
            'Are you sure you want to check out?\nWork duration: ${hours}h ${minutes}m ${seconds}s'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c, rootNavigator: true).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(c, rootNavigator: true).pop();
              proceedAction();
            },
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String message, {String title = 'Notice'}) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
