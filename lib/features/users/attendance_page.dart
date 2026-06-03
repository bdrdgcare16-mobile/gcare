import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/features/users/background_tasks.dart';
import 'package:serv_app/services/tracking_service.dart';
import 'package:serv_app/main_common.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/utils/performance_logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:firebase_auth/firebase_auth.dart';

void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
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
const String _kCheckInSourceKeyBase = 'att_checkin_source_';

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
  bool isFaceRegistered = false;
  bool isShiftSelected = false;
  bool isCheckedIn = false;
  bool isTimerRunning = false;
  bool _locationPermissionGranted = false;
  bool _isLoadingUserInfo = false;
  List<Map<String, String>>? _cachedReasons;
  bool _reasonsLoading = false;
  bool _isAttendanceStatusLoading = false;
  bool _hasAttendanceApiConfirmed = false;
  // ✅ FIX: Track if check-in source is being restored from cache
  bool _isAttendanceSourceLoading = false;

  // ✅ SAFETY: Cache the user info future to prevent duplicate calls
  Future<void>? _loadUserInfoFuture;


  // ✅ FIX: prevent multiple checkout taps / duplicate API calls
  bool _checkoutInProgress = false;

  // ✅ SAFETY: only allow manual checkout by explicit user action
  bool _manualCheckOutOnly = true;

  _Branch? _cachedBranch;

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

  // 🔹 cache the dynamic shift times loaded from Firestore
  ShiftTimes? _shiftTimes;

  Future<void> _authenticateWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[FIREBASE AUTH] Already authenticated as: ${user.uid}');
        return;
      }

      final token = CompanyData.token;
      if (token.isEmpty) {
        print('[FIREBASE AUTH] No token available for Firebase authentication');
        return;
      }

      // Use the JWT token as a custom token for Firebase Auth
      await FirebaseAuth.instance.signInWithCustomToken(token);
      print('[FIREBASE AUTH] Successfully authenticated with Firebase');
    } catch (e) {
      print('[FIREBASE AUTH] Authentication error: $e');
      // Try anonymous authentication as fallback
      try {
        await FirebaseAuth.instance.signInAnonymously();
        print('[FIREBASE AUTH] Using anonymous authentication as fallback');
      } catch (e2) {
        print('[FIREBASE AUTH] Anonymous authentication failed: $e2');
      }
    }
  }

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
    _checkLocationPermission();
  }

  // Load cached check-in state and sync with API for actual check-in time
  Future<void> _loadCachedCheckInAndStartTimer() async {
    debugPrint('[Cache] Loading cached check-in state...');

    // Restore only safe local state/source. Do not start the timer from local time.
    // The timer must start only after /attendance/live confirms the real server check-in time.
    await _restoreCheckInFromPrefs();
    await _loadTodayStatus();
  }

    @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_authInProgress) return;
      
      // ✅ FIX: Restore check-in source and then load status
      _restoreCheckInSourceFromPrefs().then((_) {
        // ✅ SAFETY: Use cached future to prevent duplicate auth/me calls
        if (_loadUserInfoFuture != null) {
          _loadUserInfoFuture!.then((_) => _loadTodayStatus());
        } else {
          _loadTodayStatus();
        }
      });
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
    if (_checkInSource.isNotEmpty) {
      await prefs.setString(_key(_kCheckInSourceKeyBase), _checkInSource);
    } else {
      await prefs.remove(_key(_kCheckInSourceKeyBase));
    }
    debugPrint('[Cache] Saved check-in source: $_checkInSource');
  }

  Future<void> _clearCheckInFromPrefs() async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    await prefs.remove(_key(_kCheckedInKeyBase));
    await prefs.remove(_key(_kCheckInDateKeyBase));
    await prefs.remove(_key(_kCheckInTimeKeyBase));
    await prefs.remove(_key(_kCheckInSourceKeyBase));
  }


  DateTime? _todayDateTimeFromHms(String? hhmmss) {
    final value = (hhmmss ?? '').trim();
    if (value.isEmpty) return null;

    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) {
      return null;
    }

    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day, hour, minute, second);
  }

  void _startTimerFromCheckInTime(DateTime checkInDateTime) {
    final now = DateTime.now();
    final diff = now.difference(checkInDateTime).inSeconds;
    final startSeconds = diff > 0 ? diff : 0;

    _timer?.cancel();
    _timer = null;

    _checkInTime = checkInDateTime;
    _checkOutTime = null;

    if (!mounted) return;
    setState(() {
      isCheckedIn = true;
      isTimerRunning = true;
      totalSeconds = startSeconds;
      hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
      minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
      seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    });

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

  // ✅ FIX: Separate method to restore only check-in source for quick restoration
  Future<void> _restoreCheckInSourceFromPrefs() async {
    if (userId.isEmpty) return;
    
    if (!mounted) return;
    setState(() => _isAttendanceSourceLoading = true);
    
    try {
      final prefs = await _prefs();
      final sourceStr = prefs.getString(_key(_kCheckInSourceKeyBase))?.toLowerCase();
      final locallyCheckedIn = prefs.getBool(_key(_kCheckedInKeyBase)) ?? false;
      final dateStr = prefs.getString(_key(_kCheckInDateKeyBase));
      
      if (!locallyCheckedIn || dateStr == null) {
        if (mounted) setState(() => _checkInSource = '');
        return;
      }
      
      // Check if cache is for today
      final today = DateTime.now();
      final todayStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      if (dateStr != todayStr) {
        await prefs.remove(_key(_kCheckInSourceKeyBase));
        if (mounted) setState(() => _checkInSource = '');
        return;
      }
      
      if (mounted) {
        setState(() {
          _checkInSource = (sourceStr == 'biometric' || sourceStr == 'manual') ? sourceStr! : '';
          debugPrint('[Cache] Restored check-in source from prefs: $_checkInSource');
        });
      }
    } catch (e) {
      debugPrint('[Cache] Error restoring check-in source: $e');
      if (mounted) setState(() => _checkInSource = '');
    } finally {
      if (mounted) setState(() => _isAttendanceSourceLoading = false);
    }
  }

  Future<void> _restoreCheckInFromPrefs() async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    final locallyCheckedIn = prefs.getBool(_key(_kCheckedInKeyBase)) ?? false;
    final dateStr = prefs.getString(_key(_kCheckInDateKeyBase));
    final sourceStr = prefs.getString(_key(_kCheckInSourceKeyBase))?.toLowerCase();

    if (!locallyCheckedIn || dateStr == null) return;

    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (dateStr != todayStr) {
      await _clearCheckInFromPrefs();
      await _clearCheckInCache();
      _checkInSource = '';
      return;
    }

    // Restore only check-in state/source from local prefs.
    // Do not restore or start timer from local time because local time can become stale/wrong.
    // /attendance/live is the only source of truth for the actual check-in time.
    _checkInSource = (sourceStr == 'biometric' || sourceStr == 'manual') ? sourceStr! : '';
    debugPrint('[Cache] Restored check-in source from prefs: $_checkInSource');

    if (!mounted) return;
    setState(() {
      isCheckedIn = true;
      isTimerRunning = false;
      _checkOutTime = null;
    });
  }

  // ---- Check-in time cache methods ----
  String _getCheckInCacheKey() {
    final today = DateTime.now();
    final dateKey = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return '${_kCheckInTimeCacheKeyBase}${userId}_$dateKey';
  }

  Future<void> _cacheCheckInTime(DateTime checkInTime) async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    final cacheKey = _getCheckInCacheKey();
    final checkInString = checkInTime.toIso8601String();
    
    debugPrint('[Cache] Storing check-in time - Key: $cacheKey, Time: $checkInString');
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
        debugPrint('[Cache] Found cached check-in time - Key: $cacheKey, Time: $cachedTime');
        return cachedTime;
      } catch (e) {
        debugPrint('[Cache] Error parsing cached time: $e');
        // Clear invalid cache entry
        await prefs.remove(cacheKey);
      }
    } else {
      debugPrint('[Cache] No cached check-in time found - Key: $cacheKey');
    }
    return null;
  }

  Future<void> _clearCheckInCache() async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    final cacheKey = _getCheckInCacheKey();
    
    debugPrint('[Cache] Clearing check-in time cache - Key: $cacheKey');
    await prefs.remove(cacheKey);
  }

  // ---- Check if cached time is for today ----
  bool _isCachedTimeForToday(DateTime cachedTime) {
    final today = DateTime.now();
    final isToday = cachedTime.year == today.year &&
                   cachedTime.month == today.month &&
                   cachedTime.day == today.day;
    debugPrint('[Cache] Checking if cached time is for today: $cachedTime -> IsToday: $isToday');
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
      location = (profile['location'] ?? userData['location'] ?? "") as String;
      selectedShift = (profile['shiftGroup'] ??
          userData['shiftGroup'] ??
          "Shift") as String;

      final hasShift = selectedShift.isNotEmpty && selectedShift != "Shift";
      shiftClicked = hasShift;
      isShiftSelected = hasShift;
    });

    debugPrint('[Attendance] Applied preloaded user info: $userName, $userId, $dept');
    
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
    debugPrint('[Attendance] User info already in progress, waiting for completion');
    return;
  }
  
  _isLoadingUserInfo = true;
  final startTime = DateTime.now();

  try {
    final token = CompanyData.token;
    debugPrint('[Attendance] Loading user info from: ${ApiService.baseUrl}/auth/me');
    
    if (token.isEmpty) {
      debugPrint('[Attendance] WARNING: No token available for auth/me call');
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
    final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    
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
      debugPrint('[Attendance] Auth/me response data keys: ${data.keys.toList()}');
      debugPrint('[Attendance] Auth/me companyId from data: ${data['companyId']}');
      debugPrint('[Attendance] Auth/me companyId from profile: ${profile['companyId']}');

      setState(() {
        userName = (data['name'] ?? profile['name'] ?? "") as String;
        userId = (data['empid'] ?? profile['empid'] ?? "") as String;
        dept = (profile['dept'] ?? data['dept'] ?? "") as String;
        location = (profile['location'] ?? data['location'] ?? "") as String;
        selectedShift = (profile['shiftGroup'] ??
            data['shiftGroup'] ??
            "Shift") as String;
        companyId = (data['companyId'] ?? profile['companyId'] ?? "") as String;

        final hasShift = selectedShift.isNotEmpty && selectedShift != "Shift";
        shiftClicked = hasShift;
        isShiftSelected = hasShift;
      });

      debugPrint('[Attendance] User info loaded: $userName, $userId, $dept');
      
      // OPTIMIZATION: Load dependent data in parallel where possible
      await Future.wait([
        _loadShiftTimes(),
        _restoreCheckInFromPrefs(),
      ]);
      await _loadTodayStatus();
    } else {
      debugPrint('[Attendance] Auth/me failed: ${res.statusCode} - ${res.body}');
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
    debugPrint('[Attendance] Auth/me error: $e');
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
  });

  if (_lastStatusFetch != null &&
      DateTime.now().difference(_lastStatusFetch!) < const Duration(minutes: 2)) {
    debugPrint('[Attendance] Using cached status (last fetch < 2 minutes ago)');
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

  try {
    final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    
    final endTime = DateTime.now();
    PerformanceLogger.logApiCall(
      screen: 'AttendanceScreen',
      endpoint: '/attendance/live',
      startTime: startTime,
      endTime: endTime,
      statusCode: res.statusCode,
      itemCount: res.statusCode == 200 ? (jsonDecode(res.body) as List).length : 0,
    );
    
    print("ATTENDANCE API STATUS: ${res.statusCode}");
    print("ATTENDANCE API BODY: ${res.body}");

    if (res.statusCode != 200) return;

    _lastStatusFetch = DateTime.now();

    final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    final me = list.firstWhere(
      (e) => (e['empid']?.toString() ?? '') == userId,
      orElse: () => const {},
    );

    final checkIn = (me['checkIn'] ?? '').toString().trim();
    final checkOut = (me['checkOut'] ?? '').toString().trim();
    _checkInSource =
        (me['checkInSource'] ?? me['source'] ?? '').toString().toLowerCase();

    print("CHECK IN TIME: $_checkInTime");
    print("CHECK OUT TIME: $_checkOutTime");

    if (checkOut.isNotEmpty) {
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
      return;
    }

    if (checkIn.isNotEmpty) {
      // User is checked in - use only the backend/server check-in time as source of truth.
      final serverCheckInTime = _applyCheckedInFromServer(checkIn);
      if (serverCheckInTime == null) {
        debugPrint('[Attendance] Invalid check-in time from backend: $checkIn');
        return;
      }
      
      // ✅ SAFETY: If source is missing from backend, default to 'manual' to allow checkout
      if (_checkInSource.isEmpty) {
        debugPrint('[Attendance] Backend returned empty check-in source, defaulting to manual');
        setState(() => _checkInSource = 'manual');
      }
      
      // Save the actual backend check-in time, never DateTime.now().
      await _saveCheckInToPrefs(at: serverCheckInTime);
      await _cacheCheckInTime(serverCheckInTime);
      print("WORKING TIMER STARTED");
      return;
    }

    // No check-in found - reset state and show not checked in
    _resetTimerAndState();
    await _clearCheckInFromPrefs();
    await _clearCheckInCache();
    if (!mounted) return;
    setState(() {
      isCheckedIn = false;
      _checkInSource = '';
    });
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
  } finally {
    // Always clear loading state
    if (!mounted) return;
    setState(() {
      _isAttendanceStatusLoading = false;
      _isAttendanceSourceLoading = false; // ✅ FIX: Clear source loading state
      _hasAttendanceApiConfirmed = true;
    });
  }
}
  DateTime? _applyCheckedInFromServer(String hhmmss) {
    final checkInDateTime = _todayDateTimeFromHms(hhmmss);
    if (checkInDateTime == null) {
      debugPrint('[Attendance] Could not parse backend check-in time: $hhmmss');
      return null;
    }

    final now = DateTime.now();
    debugPrint('[Attendance] API check-in time: $checkInDateTime');
    debugPrint('[Attendance] Current time: $now');
    debugPrint('[Attendance] Current _checkInTime: $_checkInTime');

    final timeChanged = _checkInTime == null ||
        _checkInTime!.hour != checkInDateTime.hour ||
        _checkInTime!.minute != checkInDateTime.minute ||
        _checkInTime!.second != checkInDateTime.second;

    if (timeChanged || !isTimerRunning) {
      debugPrint('[Attendance] Starting timer from backend check-in time');
      _startTimerFromCheckInTime(checkInDateTime);
    } else {
      debugPrint('[Attendance] Server check-in time matches current, no timer adjustment needed');
    }

    return checkInDateTime;
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
        const SnackBar(content: Text('Location request timed out. Please try again.')),
      );
    }
    _log('Location timeout: $e');
    return null;
  } on LocationServiceDisabledException catch (e) {
    if (!quiet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are turned off. Please enable GPS.')),
      );
    }
    _log('Location services disabled: $e');
    return null;
  } on PermissionDeniedException catch (e) {
    if (!quiet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied. Please allow location access.')),
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

  // High-accuracy location fetching with validation
  Future<Position?> _getHighAccuracyPosition({
    bool quiet = false,
    String actionLabel = 'check-in',
    double maxAccuracyMeters = 50.0,
    Duration collectionDuration = const Duration(seconds: 5),
  }) async {
    debugPrint('[GPS] GPS collection started for $actionLabel');
    debugPrint('[GPS] Required accuracy threshold: ≤${maxAccuracyMeters}m');
    debugPrint('[GPS] Collecting location samples for ${collectionDuration.inSeconds}s');

    final hasPermission = await _ensurePermissionDemo(quiet: quiet);
    if (!hasPermission) {
      debugPrint('[GPS] ❌ Permission denied');
      if (!quiet && mounted) {
        _showLocationPermissionDialog();
      }
      return null;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[GPS] ❌ Location services disabled');
      if (!quiet && mounted) {
        _showLocationServiceDialog();
      }
      return null;
    }

    Position? bestPosition;
    final startTime = DateTime.now();
    final endTime = startTime.add(collectionDuration);
    int attempt = 0;

    while (DateTime.now().isBefore(endTime)) {
      attempt++;
      final remaining = endTime.difference(DateTime.now());
      final attemptTimeout = remaining > const Duration(seconds: 5)
          ? const Duration(seconds: 5)
          : remaining;

      debugPrint('[GPS] 🔄 Sample attempt $attempt - remaining ${remaining.inSeconds}s');

      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: attemptTimeout,
          forceAndroidLocationManager: false,
        );

        debugPrint('[GPS] 📍 Got position: lat=${pos.latitude.toStringAsFixed(6)}, lng=${pos.longitude.toStringAsFixed(6)}, accuracy=${pos.accuracy.toStringAsFixed(1)}m');

        if (bestPosition == null || pos.accuracy < bestPosition.accuracy) {
  bestPosition = pos;
  debugPrint('[GPS] Best location updated: accuracy=${bestPosition.accuracy.toStringAsFixed(1)}m');
}

if (pos.accuracy <= maxAccuracyMeters) {
  debugPrint('[GPS] Good accuracy received. Stopping GPS collection early.');
  return pos;
}
      } on TimeoutException catch (e) {
        debugPrint('[GPS] ⏱️ Attempt $attempt timed out: $e');
      } on LocationServiceDisabledException catch (e) {
        debugPrint('[GPS] 📡 Location service disabled during check: $e');
        if (!quiet && mounted) {
          _showLocationServiceDialog();
        }
        return null;
      } on PermissionDeniedException catch (e) {
        debugPrint('[GPS] 🔒 Permission denied during check: $e');
        if (!quiet && mounted) {
          _showLocationPermissionDialog();
        }
        return null;
      } catch (e) {
        debugPrint('[GPS] ❌ Error during location sampling attempt $attempt: $e');
      }

      if (DateTime.now().isBefore(endTime)) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    debugPrint('[GPS] 15 seconds completed');
    if (bestPosition != null) {
      debugPrint('[GPS] Proceeding with best available accuracy: ${bestPosition.accuracy.toStringAsFixed(1)}m');
      return bestPosition;
    }

    debugPrint('[GPS] ❌ FAILED: Could not get any location during 15s collection');
    if (!quiet && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get location. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }

    return null;
  }

  // Show location permission dialog
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location permission is required for attendance check-in.'),
            SizedBox(height: 8),
            Text('This helps us verify you are at the correct location.'),
            SizedBox(height: 8),
            Text('Please grant location permission to continue.'),
          ],
        ),
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
              if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location permission denied. Please enable it in settings.'),
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GPS/Location services are turned off on your device.'),
            SizedBox(height: 8),
            Text('Please enable location services to use attendance check-in.'),
            SizedBox(height: 8),
            Text('This helps us verify your location for accurate attendance tracking.'),
          ],
        ),
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
                    content: Text('Please enable location services and try again.'),
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

  // Retry location fetch manually
  void _retryLocationFetch() {
    debugPrint('[GPS] Manual retry triggered');
    // This will be called from the dialog, implementation depends on context
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _locationPermissionGranted = permission == LocationPermission.always;
      });
    }
  }

  
  Future<bool> _ensurePermissionDemo({bool quiet = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (quiet) return false;
      if (!mounted) return false;

      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
              'Please enable location services to use this feature.'),
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

      if (go != true) return false;
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (quiet) return false;
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted && !quiet) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Location permissions are required for this feature')),
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
          content: const Text(
              'Location permissions are permanently denied. Please enable them in app settings.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (go != true) return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<_Branch?> _fetchMyBranch() async {
  // ✅ Use cached branch if already loaded
  if (_cachedBranch != null) return _cachedBranch;

  try {
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/office/locations'),
      headers: _authHeaders(),
    );

    if (res.statusCode != 200) return null;

    final list = (jsonDecode(res.body) as List)
        .cast<Map<String, dynamic>>();

    final match = list.firstWhere(
      (m) =>
          (m['branchName'] ?? m['name'] ?? '')
              .toString()
              .trim()
              .toLowerCase() ==
          location.trim().toLowerCase(),
      orElse: () => const {},
    );

    if (match.isEmpty) return null;

    final branch = _Branch(
      (match['branchName'] ?? match['name'] ?? '').toString(),
      (match['latitude'] as num).toDouble(),
      (match['longitude'] as num).toDouble(),
      (match['radius'] as num).toDouble(),
    );

    // ✅ Save in cache
    _cachedBranch = branch;

    return branch;

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

  Future<bool> _confirmOutside(
  double distance,
  double radius,
  String branchName, {
  String actionLabel = 'check-in',
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Other location'),
          content: Text(
            'You are outside the office location for $branchName.\n\n'
            'Distance from branch: ${distance.toStringAsFixed(1)}m\n'
            'Allowed radius: ${radius.toStringAsFixed(1)}m\n\n'
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
      _log('Failed to load reasons: ${res.statusCode} ${res.body}');
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
    return <Map<String, String>>[];
  } finally {
    _reasonsLoading = false;
  }
}
  Future<Map<String, String>?> _pickReason(String title, {String? prefer}) async {
  final reasons = await _fetchAllReasons();
  if (reasons.isEmpty) {
    _showInfoDialog('No reasons configured.');
    return null;
  }

  String? selectedId;
  bool confirmed = false;

  if ((prefer ?? '').isNotEmpty) {
    final match = reasons.firstWhere(
      (r) => (r['reason'] ?? '').toLowerCase().contains(prefer!.toLowerCase()),
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
  
  final canProceed = await _canProceedWithCheckIn();
  if (!canProceed) return;

  if (!mounted) return;
  
  _isManualLoading = true;
  setState(() {});
  
  try {
    await _performCheckIn('manual', alreadyValidated: true);
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
  
  final canProceed = await _canProceedWithCheckIn();
  if (!canProceed) return;

  _isBiometricLoading = true;
  setState(() {});

  try {
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
      _showInfoDialog('Biometric authentication is not available on this device. Please use manual attendance or enable biometric authentication on your phone.');
      _isBiometricLoading = false;
      setState(() {});
      return;
    }

    final ok = await _localAuth.authenticate(
      localizedReason: 'Authenticate to check in',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false,
        useErrorDialogs: false, // Disable system error dialogs to show custom messages
        sensitiveTransaction: true,
      ),
    );

    if (!mounted) {
      _isBiometricLoading = false;
      setState(() {});
      return;
    }

    if (ok) {
      await _performCheckIn('biometric', alreadyValidated: true);
    } else {
      _showErrorDialog('Biometric verification was not completed. Please try again or use manual attendance.');
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
    _showErrorDialog('Biometric verification was not completed. Please try again or use manual attendance.');
    _isBiometricLoading = false;
    setState(() {});
  } finally {
    _authInProgress = false;
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

  if (wasCheckedIn && _checkInTime != null) {
    await _saveCheckInToPrefs(at: _checkInTime);
  } else if (!wasCheckedIn) {
    await _clearCheckInFromPrefs();
  }
}

 // 5) UPDATE check-in flow so it also has a second safety check BEFORE reason popup.
//    This prevents the popup from opening if this method is called from anywhere else.
Future<void> _performCheckIn(String type, {bool alreadyValidated = false}) async {
  if (!alreadyValidated) {
    final canProceed = await _canProceedWithCheckIn();
    if (!canProceed) return;
  }

  // Ensure shift times are loaded before validation
  if (_shiftTimes == null) {
    await _loadShiftTimes();
  }

  if (_shiftTimes == null) {
    _showInfoDialog('Shift time is not loaded. Please refresh or contact admin.');
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

  final pos = await _getHighAccuracyPosition(
  actionLabel: 'check-in',
 );
  if (pos == null) return;

  final branch = await _fetchMyBranch();

  bool within = true;
  double distance = 0.0;
  String branchName = location;
  double expLat = 0, expLng = 0, expRad = 0;

  if (branch != null) {
    branchName = branch.name;
    expLat = branch.lat;
    expLng = branch.lng;
    expRad = branch.radius;
    distance = _distanceMeters(
      lat1: pos.latitude,
      lng1: pos.longitude,
      lat2: branch.lat,
      lng2: branch.lng,
    );
    within = distance <= branch.radius;

    if (!within) {
      final ok = await _confirmOutside(
  distance,
  branch.radius,
  branch.name,
  actionLabel: 'check-in',
);
      if (!ok) return;
    }
  } else {
    final ok = await _confirmOutside(
     0,
     0,
     location.isEmpty ? 'Unknown' : location,
     actionLabel: 'check-in',
    );
    
    if (!ok) return;
    within = false;
  }

  final token = CompanyData.token;
  final url = Uri.parse('${ApiService.baseUrl}/attendance/check-in');

  debugPrint('[CHECKIN] Starting check-in with method: $type');

  final bodyMap = {
    'empid': userId,
    'name': userName,
    'location': location,
    'latitude': pos.latitude,
    'longitude': pos.longitude,
    'accuracy': pos.accuracy,
    'source': type,
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

  // ✅ FIX: Do NOT set _checkInTime to DateTime.now() before backend confirmation
  // Only set UI state, let _loadTodayStatus() set the actual backend check-in time
  setState(() {
    _isAttendanceStatusLoading = true;
    _hasAttendanceApiConfirmed = false;
    isCheckedIn = true;
    _checkInSource = type.toLowerCase();
    // ✅ FIX: Leave _checkInTime as null until backend confirms
    // _checkInTime will be set by _loadTodayStatus() after successful API response
    _checkOutTime = null;
  });
  debugPrint('[CHECKIN] Set check-in source: $_checkInSource');
  debugPrint('[CHECKIN] Waiting for backend confirmation to set actual check-in time');
  
  // ✅ FIX: Do NOT start timer yet - wait for backend confirmation
  // Timer will be started by _loadTodayStatus() after successful API response
  
  // Do not save local DateTime.now() here.
  // Cache/prefs will be saved only after _loadTodayStatus() gets backend check-in time.

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Checking in… syncing in background')),
  );

  try {
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
    final message = (responseData['error'] ?? responseData['message'] ?? 'Check-in failed').toString();

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
      debugPrint('[TRACKING] User ID: $userId, isCheckedIn: $isCheckedIn');
      
      unawaited(_trackingCheckInAndSeed(pos));
      unawaited(_ensureNotificationPermission());
      // unawaited(_maybePromptBatteryOptimization());
      debugPrint('[TRACKING TEST] Calling startFgTracking empid=$userId tokenEmpty=${CompanyData.token.isEmpty}');

      debugPrint(
  '[CHECKIN TRACKING] before startFgTracking userId=$userId tokenEmpty=${CompanyData.token.isEmpty}',
);

unawaited(
  startFgTracking(empid: userId, token: CompanyData.token).then((_) {
    debugPrint('[TRACKING TEST] startFgTracking completed');
  }).catchError((e) {
    debugPrint('[TRACKING TEST] startFgTracking failed: $e');
  }),
);
      unawaited(
        scheduleBackgroundTracking(empid: userId, token: CompanyData.token),
      );

      _tracking ??= TrackingService(
        apiBase: _apiBase,
        jwtToken: CompanyData.token,
        empId: userId,
      );
      unawaited(_tracking!.startAfterCheckIn());
      
      debugPrint('[TRACKING] Tracking start functions called - UI state: isCheckedIn=$isCheckedIn, isTrackingStarted=false');

      _lastStatusFetch = null;

if (!mounted) return;

_showSuccessDialog(
  responseData['message']?.toString() ?? 'Checked in successfully!',
);

/*
  Do not block the UI here.
  Load today's status in the background after showing success.
*/
unawaited(_loadTodayStatus());

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
  Future<void> _authenticateAndCheckOut() async {
    if (_checkInSource != 'biometric') {
      debugPrint('[CHECKOUT] Biometric checkout blocked for source=$_checkInSource');
      _showInfoDialog('This session requires manual checkout. Please use the checkout button again to proceed.');
      return;
    }

    try {
      _authInProgress = true;

      // Check biometric availability before authentication
      final canBio = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      debugPrint('[BIOMETRIC] CheckOut - canCheckBiometrics: $canBio');
      debugPrint('[BIOMETRIC] CheckOut - isDeviceSupported: $supported');
      debugPrint('[BIOMETRIC] CheckOut - availableBiometrics: $availableBiometrics');
      
      if (!canBio || !supported) {
        _showErrorDialog('Biometric authentication is not available on this device. Please use manual attendance or enable biometric authentication on your phone.');
        return;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to check out',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: false, // Disable system error dialogs to show custom messages
          sensitiveTransaction: true,
        ),
      );

      if (ok) {
        debugPrint('[CHECKOUT] Biometric verification completed for checkout');
        _confirmCheckOut(proceedAction: () => _performCheckOut(checkoutMethod: 'biometric'));
      } else {
        _showErrorDialog('Biometric verification was not completed. Please try again.');
      }
    } catch (e) {
      debugPrint('[BIOMETRIC] CheckOut authentication error: $e');
      _showErrorDialog('Biometric verification was not completed. Please try again.');
    } finally {
  _authInProgress = false;

  if (mounted) {
    _isBiometricLoading = false;
    setState(() {});
  }
}
  }

  Future<void> _handleCheckOutTap() async {
    debugPrint('[CHECKOUT] Checkout button tapped. current source=$_checkInSource');
    if (_checkoutInProgress) return;
    
    // ✅ FIX: Check if source is still loading
    if (_isAttendanceSourceLoading) {
      _showInfoDialog('Loading checkout method... Please wait.');
      return;
    }

    if (_checkInSource == 'biometric') {
      await _authenticateAndCheckOut();
      return;
    }

    if (_checkInSource == 'manual') {
      debugPrint('[CHECKOUT] Manual checkout flow selected');
      _confirmCheckOut(proceedAction: () => _performCheckOut(checkoutMethod: 'manual'));
      return;
    }

    // ✅ FIX: Show informative error message
    debugPrint('[CHECKOUT] Check-in source is empty. Source=$_checkInSource, Loading=$_isAttendanceSourceLoading');
    _showInfoDialog('Checkout method is not available. Please refresh the app or contact support if the issue persists.');
  }

  Future<void> _performCheckOut({bool silent = false, required String checkoutMethod}) async {
    if (!_manualCheckOutOnly) {
      debugPrint('[CHECKOUT] Checkout blocked; user action required');
      return;
    }

    if (_checkoutInProgress) return;
    if (_checkInSource.isEmpty) {
      debugPrint('[CHECKOUT] No check-in source available, blocking checkout');
      if (!silent) _showInfoDialog('Unable to determine checkout method. Please refresh the app.');
      return;
    }

    if (_checkInSource != checkoutMethod) {
      debugPrint('[CHECKOUT] Checkout method mismatch: expected=$_checkInSource requested=$checkoutMethod');
      if (!silent) {
        if (_checkInSource == 'biometric') {
          _showErrorDialog('This session requires biometric checkout.');
        } else {
          _showInfoDialog('This session requires manual checkout.');
        }
      }
      return;
    }

    // ✅ FIX: block multiple checkout calls
    _checkoutInProgress = true;
    debugPrint('[CHECKOUT] Check-out API called with method=$checkoutMethod');

    try {
      // Ensure shift times are loaded before validation
      if (_shiftTimes == null) {
        await _loadShiftTimes();
      }

      if (_shiftTimes == null) {
        _showInfoDialog('Shift time is not loaded. Please refresh or contact admin.');
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

      final pos = await _getHighAccuracyPosition(
  quiet: silent,
  actionLabel: 'check-out',
 );
      if (pos == null) {
        if (!silent) _showErrorDialog('Could not determine location');
        return;
      }

      final branch = await _fetchMyBranch();
      bool within = true;
      double distance = 0.0;
      String branchName = location;
      double expLat = 0, expLng = 0, expRad = 0;

    if (branch != null) {
  branchName = branch.name;
  expLat = branch.lat;
  expLng = branch.lng;
  expRad = branch.radius;

  distance = _distanceMeters(
    lat1: pos.latitude,
    lng1: pos.longitude,
    lat2: branch.lat,
    lng2: branch.lng,
  );

  within = distance <= branch.radius;

  debugPrint('[CHECKOUT RADIUS] Branch: $branchName');
  debugPrint('[CHECKOUT RADIUS] Distance: ${distance.toStringAsFixed(2)}m');
  debugPrint('[CHECKOUT RADIUS] Radius: ${branch.radius.toStringAsFixed(2)}m');
  debugPrint('[CHECKOUT RADIUS] Within radius: $within');

  if (!within) {
    final ok = await _confirmOutside(
      distance,
      branch.radius,
      branch.name,
      actionLabel: 'check-out',
    );

    if (!ok) {
      if (!silent) {
        _showInfoDialog('Checkout cancelled');
      }
      return;
    }
  }
} else {
  debugPrint('[CHECKOUT RADIUS] Branch not found. Asking confirmation.');

  final ok = await _confirmOutside(
    0,
    0,
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
      final token = CompanyData.token;
      final url = Uri.parse('${ApiService.baseUrl}/attendance/check-out');

      final bodyMap = {
        'empid': userId,
        'location': location,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
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
      debugPrint('[CHECKOUT] Check-out request sent: status=${res.statusCode}, method=$checkoutMethod');

      if (res.statusCode == 200) {
        await stopFgTracking();
        await cancelBackgroundTracking(empid: userId);
        await _tracking?.stopAfterCheckOut();

        _stopWorkTimer();
        await _clearCheckInFromPrefs();
        await _clearCheckInCache(); // Clear cache on successful check-out
        setState(() {
          isCheckedIn = false;
          _checkOutTime = DateTime.now();
          _checkInSource = '';
        });
        await _trackingCheckOut();
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

  Future<void> _trackingCheckInAndSeed(Position pos) async {
    final token = CompanyData.token;
    if (token.isEmpty || userId.isEmpty) return;
    
    debugPrint('[TRACKING] Starting tracking check-in for userId: $userId');
    
    try {
      final base = '${ApiService.baseUrl}/tracking';

      final checkInRes = await http.post(
        Uri.parse('$base/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': userId,
        },
        body: jsonEncode({}),
      );
      
      debugPrint('[TRACKING] Check-in API response status: ${checkInRes.statusCode}');

      final posRes = await http.post(
        Uri.parse('$base/pos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': userId,
        },
        body: jsonEncode({'lat': pos.latitude, 'lng': pos.longitude}),
      );
      
      debugPrint('[TRACKING] Position API response status: ${posRes.statusCode}');
      debugPrint('[TRACKING] Tracking check-in completed successfully');
    } catch (e) {
      debugPrint('[TRACKING] Tracking check-in error: $e');
    }
  }

  Future<void> _trackingCheckOut() async {
    final token = CompanyData.token;
    if (token.isEmpty || userId.isEmpty) return;
    try {
      final base = '${ApiService.baseUrl}/tracking';
      await http.post(
        Uri.parse('$base/check-out'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': userId,
        },
        body: jsonEncode({}),
      );
    } catch (_) {}
  }

  Future<void> _ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _maybePromptBatteryOptimization() async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      );
      await intent.launch();
    } catch (_) {
      try {
        final intent = AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMATION_SETTINGS',
        );
        await intent.launch();
      } catch (_) {}
    }
  }

  void _startWorkTimer() {
    // Only start timer if check-in data is available
    if (_checkInTime == null) return;
    
    _timer?.cancel();
    
    // Calculate elapsed time from actual check-in time
    final now = DateTime.now();
    final elapsedSeconds = now.difference(_checkInTime!).inSeconds;
    final startSeconds = elapsedSeconds > 0 ? elapsedSeconds : 0;
    
    debugPrint('[Timer] Starting timer - Check-in time: $_checkInTime');
    debugPrint('[Timer] Current time: $now');
    debugPrint('[Timer] Elapsed seconds: $startSeconds');
    
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
Future<void> _loadShiftTimes() async {
  try {
    final shiftName = selectedShift.trim();

    print('[SHIFT DEBUG] selectedShift: [$shiftName]');
    print('[SHIFT DEBUG] companyId: [$companyId]');

    // Authenticate with Firebase using custom token
    await _authenticateWithFirebase();

    // If companyId is empty, try to extract it from JWT token
    if (companyId.isEmpty) {
      try {
        final token = CompanyData.token;
        if (token.isNotEmpty) {
          // Parse JWT token to extract companyId
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            // Fix base64 padding if needed
            String normalizedPayload = payload;
            while (normalizedPayload.length % 4 != 0) {
              normalizedPayload += '=';
            }
            final decodedBytes = base64.decode(normalizedPayload);
            final decodedJson = utf8.decode(decodedBytes);
            final payloadData = jsonDecode(decodedJson) as Map<String, dynamic>;
            companyId = payloadData['companyId']?.toString() ?? '';
            print('[SHIFT DEBUG] Extracted companyId from JWT: [$companyId]');
          }
        }
      } catch (e) {
        print('[SHIFT DEBUG] Error extracting companyId from JWT: $e');
      }
    }

    if (shiftName.isEmpty || shiftName == "Shift") {
      _shiftTimes = null;
      return;
    }

    if (companyId.isEmpty) {
      print('[SHIFT DEBUG] companyId is empty, cannot query shifts');
      _shiftTimes = null;
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('shifts')
        .where('shiftname', isEqualTo: shiftName)
        .where('companyId', isEqualTo: companyId)
        .limit(1)
        .get();

    print('[SHIFT DEBUG] shift docs found: ${snap.docs.length}');

    if (snap.docs.isEmpty) {
      print('[SHIFT DEBUG] No shift docs found - checking if query was successful');
      print('[SHIFT DEBUG] Query completed without permission errors');
      _shiftTimes = null;
      return;
    }

    final data = snap.docs.first.data();

    final startStr = (data['startTime'] ?? '').toString().trim();
    final endStr = (data['endTime'] ?? '').toString().trim();

    print('[SHIFT DEBUG] startTime: $startStr');
    print('[SHIFT DEBUG] endTime: $endStr');

    TimeOfDay? start = _parseHHmm(startStr);
    TimeOfDay? end = _parseHHmm(endStr);

    if (start == null || end == null) {
      final nameStr = (data['name'] ?? '').toString();
      final pair = _parseNameRange(nameStr);
      start ??= pair?.start;
      end ??= pair?.end;
    }

    if (start != null && end != null) {
      _shiftTimes = ShiftTimes(start, end);
      print('[SHIFT DEBUG] _shiftTimes loaded successfully');
    } else {
      _shiftTimes = null;
      print('[SHIFT DEBUG] Failed to parse shift times');
    }
  } catch (e) {
    print('[SHIFT DEBUG] _loadShiftTimes error: $e');
    _shiftTimes = null;
  }

  if (mounted) setState(() {});
}
ShiftTimes? _getShiftTimes(String shift) {
  print('[SHIFT DEBUG] _getShiftTimes called for: [$shift]');
  print('[SHIFT DEBUG] _shiftTimes: $_shiftTimes');
  
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
                                    ? 'In: Syncing '
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
                                    ? 'Out: Syncing '
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
                              final formattedDate = "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
                              
                              // Debug logs
                              // print("ATTENDANCE DATE API: $_checkInTime");
                              // print("FORMATTED DATE: $formattedDate");
                              
                              // Use check-in date if available, otherwise today's date
                              if (_checkInTime != null) {
                                final checkInDate = DateTime(_checkInTime!.year, _checkInTime!.month, _checkInTime!.day);
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
                    child: Image.asset('assets/images/native_splash_logo-removebg.png',
                        fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 15),
                // Show syncing text until backend-confirmed check-in time is available.
                if (!_hasAttendanceApiConfirmed ||
                    _isAttendanceStatusLoading ||
                    (isCheckedIn && _checkInTime == null))
                  const Text(
                    'Syncing attendance...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                else
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
                                onPressed: (_isManualLoading || _isBiometricLoading) ? null : () async {
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
                                                  AlwaysStoppedAnimation<Color>(
                                                      kTextColor),
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
                                onPressed: (_isManualLoading || _isBiometricLoading) ? null : () async {
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
                                                  AlwaysStoppedAnimation<Color>(
                                                      kTextColor),
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
                          // ✅ FIX: Disable button while source is loading or checkout is in progress
                          onPressed: (_checkoutInProgress || _isAttendanceSourceLoading || _checkInSource.isEmpty)
                              ? null
                              : _handleCheckOutTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ✅ FIX: Show loading indicator when source is being loaded or checkout in progress
                              if (_isAttendanceSourceLoading || _checkoutInProgress)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(kTextColor),
                                  ),
                                )
                              else
                                const Icon(Icons.logout, color: kTextColor, size: 13),
                              const SizedBox(width: 8),
                              Text(
                                _isAttendanceSourceLoading ? 'Loading...' : (_checkoutInProgress ? 'Checking out...' : 'Check Out'),
                                style: const TextStyle(
                                    color: kTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, color: Colors.green, size: 16),
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