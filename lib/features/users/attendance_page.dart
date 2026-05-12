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

  // ✅ SAFETY: Cache the user info future to prevent duplicate calls
  Future<void>? _loadUserInfoFuture;


  // ✅ FIX: prevent multiple checkout taps / duplicate API calls
  bool _checkoutInProgress = false;
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

  // Load cached check-in time and start timer immediately if found
  Future<void> _loadCachedCheckInAndStartTimer() async {
    debugPrint('[Cache] Loading cached check-in time...');
    
    // First try to get cached check-in time
    final cachedCheckInTime = await _getCachedCheckInTime();
    
    if (cachedCheckInTime != null && _isCachedTimeForToday(cachedCheckInTime)) {
      debugPrint('[Cache] Using cached check-in time: $cachedCheckInTime');
      
      // Set check-in time from cache and start timer immediately
      _checkInTime = cachedCheckInTime;
      _checkOutTime = null;
      
      // Start timer with cached time
      _startWorkTimer();
      
      // Then call API to sync with server in background
      _loadTodayStatus();
    } else {
      debugPrint('[Cache] No valid cached check-in time found, loading from API');
      
      // No cached time, load from API normally
      await _restoreCheckInFromPrefs();
      _loadTodayStatus();
    }
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
  });

  if (_lastStatusFetch != null &&
      DateTime.now().difference(_lastStatusFetch!) < const Duration(minutes: 2)) {
    debugPrint('[Attendance] Using cached status (last fetch < 2 minutes ago)');
    if (!mounted) return;
    setState(() {
      _isAttendanceStatusLoading = false;
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
      return;
    }

    if (checkIn != null && checkIn.isNotEmpty) {
      // User is checked in - apply check-in data and start timer
      _applyCheckedInFromServer(checkIn);
      await _saveCheckInToPrefs();
      print("WORKING TIMER STARTED");
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
    });
  }
}
  void _applyCheckedInFromServer(String hhmmss) {
    try {
      final now = DateTime.now();
      final parts = hhmmss.split(':').map((s) => int.tryParse(s) ?? 0).toList();
      
      // Use actual server check-in time, not current time
      final checkInDateTime = DateTime(now.year, now.month, now.day, parts[0], parts[1],
          parts.length > 2 ? parts[2] : 0);
      
      debugPrint('[Attendance] API check-in time: $checkInDateTime');
      debugPrint('[Attendance] Current time: $now');

      // Check if server time is different from current check-in time
      final timeChanged = _checkInTime == null || 
                         _checkInTime!.hour != checkInDateTime.hour ||
                         _checkInTime!.minute != checkInDateTime.minute ||
                         _checkInTime!.second != checkInDateTime.second;
      
      if (timeChanged) {
        debugPrint('[Attendance] Server check-in time differs from current, updating timer');
        
        // Update check-in time and cache it
        _checkInTime = checkInDateTime;
        _checkOutTime = null;
        
        // Cache the server check-in time
        _cacheCheckInTime(checkInDateTime);
        
        // Calculate duration from actual check-in time
        final diff = now.difference(checkInDateTime).inSeconds;
        final startSeconds = diff > 0 ? diff : 0;
        
        debugPrint('[Attendance] Final timer start time: $startSeconds seconds');

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
        debugPrint('[Attendance] Server check-in time matches current, no timer adjustment needed');
        // Just ensure cache is up to date
        _cacheCheckInTime(checkInDateTime);
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
    double maxAccuracyMeters = 50.0, // Updated to 50 meters threshold
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    debugPrint('[GPS] Starting high-accuracy location fetch...');
    debugPrint('[GPS] Required accuracy: ≤${maxAccuracyMeters}m');
    
    // Step 1: Check location permission
    final hasPermission = await _ensurePermissionDemo(quiet: quiet);
    if (!hasPermission) {
      debugPrint('[GPS] ❌ Permission denied');
      if (!quiet && mounted) {
        _showLocationPermissionDialog();
      }
      return null;
    }

    // Step 2: Check if GPS/location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[GPS] ❌ Location services disabled');
      if (!quiet && mounted) {
        _showLocationServiceDialog();
      }
      return null;
    }

    Position? bestPosition;
    int attempts = 0;
    final startTime = DateTime.now();

    // Show improving message if not quiet
    if (!quiet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting accurate location, please wait...'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );
    }

    while (attempts < maxRetries) {
      attempts++;
      debugPrint('[GPS] 🔄 Attempt $attempts/$maxRetries');

      try {
        // Use best accuracy for navigation
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: timeout,
          forceAndroidLocationManager: false,
        );

        debugPrint('[GPS] 📍 Got position: lat=${pos.latitude.toStringAsFixed(6)}, lng=${pos.longitude.toStringAsFixed(6)}, accuracy=${pos.accuracy.toStringAsFixed(1)}m');

        // What is location accuracy: 
        // Location accuracy (in meters) represents the radius of uncertainty around the reported GPS position.
        // A 20m accuracy means the actual location is somewhere within a 20-meter radius of the reported coordinates.
        // Lower accuracy values = more precise location. Higher values = less precise location.
        // For attendance check-in, we need good accuracy to ensure the employee is actually at the correct location.

        // Validate accuracy
        if (pos.accuracy <= maxAccuracyMeters) {
          debugPrint('[GPS] ✅ Good accuracy (${pos.accuracy.toStringAsFixed(1)}m ≤ ${maxAccuracyMeters}m)');
          bestPosition = pos;
          break;
        } else {
          debugPrint('[GPS] ⚠️ Poor accuracy (${pos.accuracy.toStringAsFixed(1)}m > ${maxAccuracyMeters}m)');
          
          // Keep the best position found so far
          if (bestPosition == null || pos.accuracy < bestPosition.accuracy) {
            bestPosition = pos;
            debugPrint('[GPS] 📊 Best position so far: ${bestPosition!.accuracy.toStringAsFixed(1)}m');
          }

          // Check if we've exceeded total timeout
          if (DateTime.now().difference(startTime) > const Duration(seconds: 12)) {
            debugPrint('[GPS] ⏰ Total timeout reached, using best available');
            break;
          }

          // Short delay before retry
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      } on TimeoutException catch (e) {
        debugPrint('[GPS] ⏱️ Timeout on attempt $attempts: $e');
        if (attempts >= maxRetries) break;
        await Future.delayed(const Duration(milliseconds: 500));
      } on LocationServiceDisabledException catch (e) {
        debugPrint('[GPS] 📡 Location service disabled: $e');
        if (!quiet && mounted) {
          _showLocationServiceDialog();
        }
        return null;
      } on PermissionDeniedException catch (e) {
        debugPrint('[GPS] 🔒 Permission denied: $e');
        if (!quiet && mounted) {
          _showLocationPermissionDialog();
        }
        return null;
      } catch (e) {
        debugPrint('[GPS] ❌ Error on attempt $attempts: $e');
        if (attempts >= maxRetries) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Final decision
    if (bestPosition != null) {
      if (bestPosition.accuracy <= maxAccuracyMeters) {
        debugPrint('[GPS] ✅ ACCEPTED: lat=${bestPosition.latitude.toStringAsFixed(6)}, lng=${bestPosition.longitude.toStringAsFixed(6)}, accuracy=${bestPosition.accuracy.toStringAsFixed(1)}m');
        
        // Clear the improving message and show success
        if (!quiet && mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Location accurate (${bestPosition.accuracy.toStringAsFixed(1)}m) - Proceeding with check-in'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        return bestPosition;
      } else {
        debugPrint('[GPS] ❌ REJECTED: Best accuracy ${bestPosition.accuracy.toStringAsFixed(1)}m > ${maxAccuracyMeters}m');
        
        // Show low accuracy warning
        if (!quiet && mounted) {
          _showLowAccuracyWarningDialog(bestPosition.accuracy);
        }
        
        return null;
      }
    }

    debugPrint('[GPS] ❌ FAILED: Could not get accurate location');
    if (!quiet && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Unable to get accurate location. Please move to open area and try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
    return null;
  }

  // Show dialog for low accuracy scenarios
  void _showLowAccuracyDialog(double accuracy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Accuracy Issue'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your location accuracy is low. Please retry and click check-in again.'),
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
            onPressed: () {
              Navigator.of(context).pop();
              // Retry with manual trigger
              _retryLocationFetch();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Show low accuracy warning dialog with detailed information
  void _showLowAccuracyWarningDialog(double accuracy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Accuracy Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your location accuracy is low (${accuracy.toStringAsFixed(1)}m).'),
            const SizedBox(height: 8),
            const Text('For accurate attendance check-in, we need location accuracy within 50 meters.'),
            const SizedBox(height: 8),
            const Text('Suggestions to improve accuracy:'),
            const SizedBox(height: 4),
            const Text('• Move to an open area with clear sky view'),
            const Text('• Stay away from tall buildings or trees'),
            const Text('• Wait a few seconds for GPS to stabilize'),
            const Text('• Ensure GPS/location services are enabled'),
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
            onPressed: () {
              Navigator.of(context).pop();
              // Retry location fetch
              _retryLocationFetch();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
    String branchName,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Other location'),
            content: const Text(
              'You are in other location. Do you want to proceed with check-in here?',
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Proceed')),
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
      await _performCheckIn('biometric');
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

  if (wasCheckedIn) {
    await _saveCheckInToPrefs();
  } else {
    await _clearCheckInFromPrefs();
  }
}

 // 5) UPDATE check-in flow so it also has a second safety check BEFORE reason popup.
//    This prevents the popup from opening if this method is called from anywhere else.
Future<void> _performCheckIn(String type) async {
  final canProceed = await _canProceedWithCheckIn();
  if (!canProceed) return;

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

  final pos = await _getHighAccuracyPosition();
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
      final ok = await _confirmOutside(distance, branch.radius, branch.name);
      if (!ok) return;
    }
  } else {
    final ok = await _confirmOutside(
      0,
      0,
      location.isEmpty ? 'Unknown' : location,
    );
    if (!ok) return;
    within = false;
  }

  final token = CompanyData.token;
  final url = Uri.parse('${ApiService.baseUrl}/attendance/check-in');

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

  final now = DateTime.now();
  setState(() {
    isCheckedIn = true;
    _checkInSource = type.toLowerCase();
    _checkInTime = now;
    _checkOutTime = null;
  });
  _startWorkTimer();
  await _saveCheckInToPrefs();
  await _cacheCheckInTime(now); // Cache check-in time after successful check-in

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
      setState(() => _checkInSource = '');
      _showInfoDialog('Already checked in today');
      return;
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      debugPrint('[TRACKING] Check-in success - Starting tracking flow');
      debugPrint('[TRACKING] User ID: $userId, isCheckedIn: $isCheckedIn');
      
      unawaited(_trackingCheckInAndSeed(pos));
      unawaited(_ensureNotificationPermission());
      unawaited(_maybePromptBatteryOptimization());
      unawaited(startFgTracking(empid: userId, token: CompanyData.token));
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

      if (!mounted) return;
      _showSuccessDialog(
        responseData['message']?.toString() ?? 'Checked in successfully!',
      );
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
    setState(() => _checkInSource = '');
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
    setState(() => _checkInSource = '');
    _showErrorDialog(_getUserFriendlyErrorMessage(e));
  }
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
        _confirmCheckOut(proceedAction: () => _performCheckOut());
      } else {
        _showErrorDialog('Biometric verification was not completed. Please try again or use manual attendance.');
      }
    } catch (e) {
      debugPrint('[BIOMETRIC] CheckOut authentication error: $e');
      _showErrorDialog('Biometric verification was not completed. Please try again or use manual attendance.');
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

      final pos = await _getHighAccuracyPosition(quiet: silent);
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
                                'In: ${_formatTime(_checkInTime)}',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isCheckedIn
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Out: ${_formatTime(_checkOutTime)}',
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
                              print("ATTENDANCE DATE API: $_checkInTime");
                              print("FORMATTED DATE: $formattedDate");
                              
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
                    child: Image.asset('assets/images/splash2.jpg',
                        fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 15),
                // Show loading state while fetching attendance status
                if (_isAttendanceStatusLoading)
                  const Text(
                    'Syncing attendance...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 169, 163, 182),
                      fontWeight: FontWeight.w500,
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
                          onPressed: _checkoutInProgress
                              ? null
                              : () {
                                  if (_checkInSource == 'biometric') {
                                    _authenticateAndCheckOut();
                                  } else {
                                    _confirmCheckOut(proceedAction: () => _performCheckOut());
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
