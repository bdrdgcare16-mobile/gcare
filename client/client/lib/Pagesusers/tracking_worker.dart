// import 'dart:ui';
// import 'package:workmanager/workmanager.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;

// const bgTaskName = 'track-every-20-min';

// @pragma('vm:entry-point')
// void trackingCallbackDispatcher() {
//   Workmanager().executeTask((task, input) async {
//     try {
//       final token = input?['token'] as String?;
//       final apiBase = input?['apiBase'] as String?;
//       if (token == null || apiBase == null) return false;

//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       var perm = await Geolocator.checkPermission();
//       if (!serviceEnabled) return false;
//       if (perm == LocationPermission.denied) {
//         perm = await Geolocator.requestPermission();
//         if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return false;
//       }

//       final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       final now = DateTime.now();
//       final dateIso = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

//       final uri = Uri.parse('$apiBase/api/tracking/point');
//       final res = await http.post(
//         uri,
//         headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
//         body: '{"dateIso":"$dateIso","lat":${pos.latitude},"lng":${pos.longitude},"atMs":${now.millisecondsSinceEpoch}}',
//       );
//       return res.statusCode < 400;
//     } catch (_) {
//       return false;
//     }
//   });
// }
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';

import 'package:serv_app/models/company_data.dart';
// ⬇️ add: bring in the background helpers defined in main.dart

// ==== Colors ====
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ---- API base ----
const String _apiBase = 'https://api-zmj7dqloiq-uc.a.run.app/api';

// ---- Local persistence keys ----
const String _kCheckedInKeyBase = 'att_checked_in_';
const String _kCheckInDateKeyBase = 'att_checkin_date_';
const String _kCheckInTimeKeyBase = 'att_checkin_time_';

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
  const AttendanceScreen({super.key, required this.employeeDocId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  bool isFaceRegistered = false;
  bool isShiftSelected = false;
  bool isCheckedIn = false;
  bool isTimerRunning = false;

  String userName = "";
  String userId = ""; // empid
  String dept = "";
  String location = "";

  String selectedShift = "Shift";
  bool shiftClicked = false;

  Timer? _timer;
  Timer? _autoCheckoutTimer;
  int totalSeconds = 0;
  String hours = "00";
  String minutes = "00";
  String seconds = "00";

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
    _checkUserFaceRegistration();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _cancelAutoCheckout();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_authInProgress) return;
      _restoreCheckInFromPrefs().then((_) {
        _loadTodayStatus();
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
    if (kDebugMode) {
      print('[AttendanceScreen] persisted check-in for $userId at $ymd $hms');
    }
  }

  Future<void> _clearCheckInFromPrefs() async {
    if (userId.isEmpty) return;
    final prefs = await _prefs();
    await prefs.remove(_key(_kCheckedInKeyBase));
    await prefs.remove(_key(_kCheckInDateKeyBase));
    await prefs.remove(_key(_kCheckInTimeKeyBase));
    if (kDebugMode) {
      print('[AttendanceScreen] cleared persisted check-in for $userId');
    }
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

    if (!mounted) return;
    setState(() {
      isCheckedIn = true;
      isTimerRunning = true;
    });

    try {
      final hms = timeStr.split(':');
      final inDT = DateTime(
        today.year, today.month, today.day,
        int.parse(hms[0]), int.parse(hms[1]), int.parse(hms[2]),
      );
      final diff = DateTime.now().difference(inDT).inSeconds;
      totalSeconds = diff > 0 ? diff : 0;
    } catch (_) {
      totalSeconds = 0;
    }
    hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    seconds = (totalSeconds % 60).toString().padLeft(2, '0');

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

    _scheduleAutoCheckout();
    _maybeAutoCheckoutImmediatelyIfPastShiftEnd();
  }

  Future<void> _maybeAutoCheckoutImmediatelyIfPastShiftEnd() async {
    if (!isCheckedIn) return;
    final times = _getShiftTimes(selectedShift);
    var endDT = _toDateTime(times.end);
    final startDT = _toDateTime(times.start);
    if (endDT.isBefore(startDT)) {
      endDT = endDT.add(const Duration(days: 1));
    }
    if (DateTime.now().isAfter(endDT)) {
      await _performCheckOut(silent: true);
    }
  }

  Future<void> _loadUserInfo() async {
    final token = CompanyData.token;
    final url = Uri.parse('$_apiBase/auth/me');

    try {
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (kDebugMode) {
        print('[AttendanceScreen] /auth/me -> ${res.statusCode}');
        print('[AttendanceScreen] body: ${res.body}');
      }
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final profile = (data['employeeProfile'] is Map<String, dynamic>)
            ? (data['employeeProfile'] as Map<String, dynamic>)
            : <String, dynamic>{};

        setState(() {
          userName = (data['name'] ?? profile['name'] ?? "") as String;
          userId   = (data['empid'] ?? profile['empid'] ?? "") as String;
          dept     = (profile['dept'] ?? data['dept'] ?? "") as String;
          location = (profile['location'] ?? data['location'] ?? "") as String;
          selectedShift = (profile['shiftGroup'] ?? data['shiftGroup'] ?? "Shift") as String;

          final hasShift = selectedShift.isNotEmpty && selectedShift != "Shift";
          shiftClicked    = hasShift;
          isShiftSelected = hasShift;
        });

        await _restoreCheckInFromPrefs();
        await _loadTodayStatus();
      } else {
        setState(() {
          userName = "(unknown)";
          userId   = widget.employeeDocId;
          dept     = "";
          location = "";
        });
        await _restoreCheckInFromPrefs();
      }
    } catch (e) {
      if (kDebugMode) print('[AttendanceScreen] _loadUserInfo error: $e');
      setState(() {
        userName = "(error)";
        userId   = widget.employeeDocId;
        dept     = "";
        location = "";
      });
      await _restoreCheckInFromPrefs();
    }
  }

  Future<void> _loadTodayStatus() async {
    final token = CompanyData.token;
    if (userId.isEmpty || token.isEmpty) return;

    final url = Uri.parse('$_apiBase/attendance/live');

    try {
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (kDebugMode) {
        print('[AttendanceScreen] /attendance/live -> ${res.statusCode}');
        if (res.statusCode == 200) print('[AttendanceScreen] live body: ${res.body}');
      }
      if (res.statusCode != 200) return;

      final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      final me = list.firstWhere(
        (e) => (e['empid']?.toString() ?? '') == userId,
        orElse: () => const {},
      );

      final checkIn  = (me['checkIn']) as String?;
      final checkOut = (me['checkOut']) as String?;

      if (checkOut != null && checkOut.isNotEmpty) {
        _resetTimerAndState();
        _cancelAutoCheckout();
        await _clearCheckInFromPrefs();
        // ⬇️ ensure worker is stopped
        await cancelBackgroundTracking();
        if (!mounted) return;
        setState(() => isCheckedIn = false);
        return;
      }

      if (checkIn != null && checkIn.isNotEmpty) {
        _applyCheckedInFromServer(checkIn);
        await _saveCheckInToPrefs();
        _scheduleAutoCheckout();
        // ⬇️ ensure worker is (re)started, e.g., after app restart
        await registerBackgroundTracking(jwtToken: CompanyData.token, apiBase: _apiBase);
        return;
      }

      _resetTimerAndState();
      _cancelAutoCheckout();
      await _clearCheckInFromPrefs();
      await cancelBackgroundTracking(); // not checked-in -> stop worker
      if (!mounted) return;
      setState(() => isCheckedIn = false);
    } catch (e) {
      if (kDebugMode) print('[AttendanceScreen] _loadTodayStatus error: $e');
    }
  }

  void _applyCheckedInFromServer(String hhmmss) {
    try {
      final now = DateTime.now();
      final parts = hhmmss.split(':').map((s) => int.tryParse(s) ?? 0).toList();
      final inDT = DateTime(now.year, now.month, now.day,
          parts.elementAt(0), parts.elementAt(1), parts.elementAt(2));
      final diff = now.difference(inDT).inSeconds;
      final startSeconds = diff > 0 ? diff : 0;

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

      // ⬇️ Make sure the worker runs after we learned check-in from server
      registerBackgroundTracking(jwtToken: CompanyData.token, apiBase: _apiBase);
    } catch (_) {
      _startWorkTimer();
      setState(() => isCheckedIn = true);
      // still (re)start worker
      registerBackgroundTracking(jwtToken: CompanyData.token, apiBase: _apiBase);
    }
  }

  void _resetTimerAndState() {
    _timer?.cancel();
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

  // -----------------------------------------------------------------
  // GEO helpers
  // -----------------------------------------------------------------
  Future<bool> _ensurePermissionDemo({bool quiet = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (quiet) return false;
      if (!mounted) return false;
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
            const SnackBar(content: Text('Location permissions are required for this feature')),
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
          content: const Text('Location permissions are permanently denied. Please enable them in app settings.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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

    return true;
  }

  Future<Position?> _getPositionUsingDemo({bool quiet = false}) async {
    final ok = await _ensurePermissionDemo(quiet: quiet);
    if (!ok) return null;

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted && !quiet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return null;
    }

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      if (mounted && !quiet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
      pos = await Geolocator.getLastKnownPosition();
    }

    if (pos == null && mounted && !quiet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine location')),
      );
    }
    return pos;
  }

  // -------------------- BRANCH lookup + geofence check --------------------
  Future<_Branch?> _fetchMyBranch() async {
    try {
      final res = await http.get(Uri.parse('$_apiBase/office/locations'), headers: _authHeaders());
      if (res.statusCode != 200) return null;
      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      final match = list.firstWhere(
        (m) => (m['branchName'] ?? m['name'] ?? '').toString().trim().toLowerCase() ==
               location.trim().toLowerCase(),
        orElse: () => const {},
      );
      if (match.isEmpty) return null;
      final lat = (match['latitude'] as num).toDouble();
      final lng = (match['longitude'] as num).toDouble();
      final rad = (match['radius'] as num).toDouble();
      final nm  = (match['branchName'] ?? match['name'] ?? '').toString();
      return _Branch(nm, lat, lng, rad);
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

  Future<bool> _confirmOutside(double distance, double radius, String branchName) async {
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Other location'),
            content: Text(
              'You are ${(distance).toStringAsFixed(0)}m away from "$branchName" '
              '(radius ${radius.toStringAsFixed(0)}m).\n'
              'Do you want to proceed with check-in here?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Proceed')),
            ],
          ),
        ) ??
        false;
  }

  // -------------------- Inline biometric -> Check-in --------------------
  Future<void> _authenticateAndCheckIn() async {
    try {
      _authInProgress = true;

      final canBio = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      if (!canBio && !supported) {
        _showErrorDialog('Biometric not available on this device');
        return;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to check in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (ok) {
        if (mounted) await _performCheckIn('biometric');
      } else {
        _showInfoDialog('Authentication cancelled');
      }
    } catch (e) {
      _showErrorDialog('Auth error: $e');
    } finally {
      _authInProgress = false;
    }
  }

  // -------------------- Check-in / out --------------------
  Future<void> _performCheckIn(String type) async {
    if (kDebugMode) print('[AttendanceScreen] starting _performCheckIn()');

    final pos = await _getPositionUsingDemo();
    if (pos == null) {
      if (kDebugMode) print('[AttendanceScreen] no GPS -> abort');
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
        lat1: pos.latitude, lng1: pos.longitude, lat2: branch.lat, lng2: branch.lng,
      );
      within = distance <= branch.radius;

      if (!within) {
        final ok = await _confirmOutside(distance, branch.radius, branch.name);
        if (!ok) return;
      }
    } else {
      final ok = await _confirmOutside(0, 0, location.isEmpty ? 'Unknown' : location);
      if (!ok) return;
      within = false;
    }

    final token = CompanyData.token;
    final url = Uri.parse('$_apiBase/attendance/check-in');

    final body = jsonEncode({
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
    });

    if (kDebugMode) print('[AttendanceScreen] POST /attendance/check-in body ready');
    _showLoadingDialog('Checking in…');
    try {
      final res = await http.post(
        url, headers: {'Content-Type': 'application/json','Authorization': 'Bearer $token'}, body: body,
      );
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (kDebugMode) {
        print('[AttendanceScreen] check-in ${res.statusCode} ${res.body}');
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final code = (data['code'] ?? '').toString();

          final record = (data['record'] ?? {}) as Map<String, dynamic>;
          final recCheckIn = (record['checkIn'] ?? '') as String?;
          final recCheckOut = (record['checkOut'] ?? '') as String?;

          if (recCheckOut != null && recCheckOut.isNotEmpty) {
            _resetTimerAndState();
            _cancelAutoCheckout();
            await _clearCheckInFromPrefs();
            // ⬇️ stop worker if server says you're already out
            await cancelBackgroundTracking();
            setState(() => isCheckedIn = false);
            _showInfoDialog("You've already checked out today.");
            return;
          }

          if (code == 'ALREADY_CHECKED_IN') {
            if (recCheckIn != null && recCheckIn.isNotEmpty) {
              _applyCheckedInFromServer(recCheckIn);
            } else {
              setState(() => isCheckedIn = true);
              _startWorkTimer();
            }
            await _saveCheckInToPrefs();
            _scheduleAutoCheckout();
            // ⬇️ ensure worker is running
            await registerBackgroundTracking(jwtToken: CompanyData.token, apiBase: _apiBase);
            _showInfoDialog('You are already checked in.');
          } else {
            if (recCheckIn != null && recCheckIn.isNotEmpty) {
              _applyCheckedInFromServer(recCheckIn);
            } else {
              setState(() => isCheckedIn = true);
              _startWorkTimer();
            }
            await _saveCheckInToPrefs();
            _scheduleAutoCheckout();
            // ⬇️ start background tracking after successful check-in
            await registerBackgroundTracking(jwtToken: CompanyData.token, apiBase: _apiBase);
            _showSuccessDialog('Checked in successfully!');
          }

          // 👉 tracking: create day + seed first point with SAME GPS
          await _trackingCheckInAndSeed(pos);

        } catch (_) {
          setState(() => isCheckedIn = true);
          _startWorkTimer();
          await _saveCheckInToPrefs();
          _scheduleAutoCheckout();
          // ⬇️ still start worker
          await registerBackgroundTracking(jwtToken: CompanyData.token, apiBase: _apiBase);
          _showSuccessDialog('Checked in successfully!');
          // 👉 even if parsing fails, still seed tracking
          await _trackingCheckInAndSeed(pos);
        }
      } else {
        final msg =
            (jsonDecode(res.body)['error'] ?? jsonDecode(res.body)['message']).toString();
        if (msg.toLowerCase().contains('already') && msg.toLowerCase().contains('checked out')) {
          _resetTimerAndState();
          _cancelAutoCheckout();
          await _clearCheckInFromPrefs();
          // ⬇️ stop worker
          await cancelBackgroundTracking();
          setState(() => isCheckedIn = false);
          _showInfoDialog("You've already checked out today.");
        } else {
          _showErrorDialog(msg);
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showErrorDialog('Network error: $e');
    }
  }

  Future<void> _performCheckOut({bool silent = false}) async {
    final pos = await _getPositionUsingDemo(quiet: silent);
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
        lat1: pos.latitude, lng1: pos.longitude, lat2: branch.lat, lng2: branch.lng,
      );
      within = distance <= branch.radius;
    }

    final token = CompanyData.token;
    final url = Uri.parse('$_apiBase/attendance/check-out');

    final body = jsonEncode({
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
    });

    if (!silent) _showLoadingDialog('Checking out…');
    try {
      final res = await http.post(
        url, headers: {'Content-Type': 'application/json','Authorization': 'Bearer $token'}, body: body,
      );
      if (!silent && mounted) Navigator.of(context, rootNavigator: true).pop();

      if (kDebugMode) {
        print('[AttendanceScreen] check-out ${res.statusCode} ${res.body}');
      }

      if (res.statusCode == 200) {
        _stopWorkTimer();
        _cancelAutoCheckout();
        await _clearCheckInFromPrefs();
        setState(() => isCheckedIn = false);
        if (!silent) _showSuccessDialog('Checked out successfully!');

        // ⬇️ stop worker on checkout
        await cancelBackgroundTracking();

        // 👉 tracking: mark session ended
        await _trackingCheckOut();
      } else {
        final msg =
            (jsonDecode(res.body)['error'] ?? jsonDecode(res.body)['message']).toString();

        if (msg.toLowerCase().contains('already') && msg.toLowerCase().contains('checked out')) {
          _resetTimerAndState();
          _cancelAutoCheckout();
          await _clearCheckInFromPrefs();
          setState(() => isCheckedIn = false);
          if (!silent) _showInfoDialog("You've already checked out today.");
          // ⬇️ stop worker if server says you're out
          await cancelBackgroundTracking();
          await _trackingCheckOut();
        } else {
          if (!silent) _showErrorDialog(msg);
        }
      }
    } catch (e) {
      if (!silent) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _showErrorDialog('Network error: $e');
      }
    }
  }

  // -------------------- 👉 Tracking glue (server) --------------------
  Future<void> _trackingCheckInAndSeed(Position pos) async {
    final token = CompanyData.token;
    if (token.isEmpty || userId.isEmpty) return;

    try {
      final base = 'https://api-zmj7dqloiq-uc.a.run.app/api/tracking';

      // create/clear today doc
      await http.post(
        Uri.parse('$base/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': userId, // backend fallback if JWT lacks empid
        },
        body: jsonEncode({}), // dateIso defaults to today on server
      );

      // seed first point from the same GPS
      await http.post(
        Uri.parse('$base/pos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': userId,
        },
        body: jsonEncode({
          'lat': pos.latitude,
          'lng': pos.longitude,
        }),
      );
    } catch (e) {
      if (kDebugMode) print('[AttendanceScreen] tracking seed error: $e');
    }
  }

  Future<void> _trackingCheckOut() async {
    final token = CompanyData.token;
    if (token.isEmpty || userId.isEmpty) return;
    try {
      final base = 'https://api-zmj7dqloiq-uc.a.run.app/api/tracking';
      await http.post(
        Uri.parse('$base/check-out'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': userId,
        },
        body: jsonEncode({}),
      );
    } catch (e) {
      if (kDebugMode) print('[AttendanceScreen] tracking checkout error: $e');
    }
  }
  // ---------------------------------------------------------------

  void _startWorkTimer() {
    _timer?.cancel();
    setState(() {
      isTimerRunning = true;
      totalSeconds = 0;
      hours = "00";
      minutes = "00";
      seconds = "00";
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
    _showSuccessDialog('Check-out successful!\nWork duration: ${h}h ${m}m ${s}s');
  }

  ShiftTimes _getShiftTimes(String shift) {
    switch (shift.toLowerCase()) {
      case 'shift1':
      case 'day':
        return const ShiftTimes(TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 18, minute: 0));
      case 'shift2':
      case 'morning':
        return const ShiftTimes(TimeOfDay(hour: 6, minute: 0), TimeOfDay(hour: 15, minute: 0));
      case 'shift3':
      case 'evening':
        return const ShiftTimes(TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 23, minute: 0));
      default:
        return const ShiftTimes(TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 18, minute: 0));
    }
  }

  DateTime _toDateTime(TimeOfDay tod, {DateTime? base}) {
    final b = base ?? DateTime.now();
    return DateTime(b.year, b.month, b.day, tod.hour, tod.minute);
  }

  void _scheduleAutoCheckout() {
    _cancelAutoCheckout();
    if (!isCheckedIn) return;

    final times = _getShiftTimes(selectedShift);
    var endDT = _toDateTime(times.end);
    final startDT = _toDateTime(times.start);
    if (endDT.isBefore(startDT)) {
      endDT = endDT.add(const Duration(days: 1));
    }

    final now = DateTime.now();
    final wait = endDT.isAfter(now) ? endDT.difference(now) : const Duration(seconds: 1);

    if (kDebugMode) {
      print('[AttendanceScreen] Auto-checkout at $endDT (in ${wait.inMinutes} min) for "$selectedShift"');
    }

    _autoCheckoutTimer = Timer(wait, () async {
      if (!mounted || !isCheckedIn) return;
      await _performCheckOut(silent: true);
    });
  }

  void _cancelAutoCheckout() {
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = null;
  }

  // -------------------- UI helpers --------------------
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
            color: kTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
              left: 16, top: 16, right: 16,
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
                      Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$userId | $dept', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            '${DateTime.now().day.toString().padLeft(2, '0')} '
                            '${_getMonthName(DateTime.now().month)} '
                            '${DateTime.now().year}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 65,
                  height: 65,
                  child: Image.asset('assets/images/timer1.png', fit: BoxFit.contain),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeBox(hours), const SizedBox(width: 6),
                    Text(':', style: TextStyle(fontSize: 20, color: kButtonColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    _buildTimeBox(minutes), const SizedBox(width: 6),
                    Text(':', style: TextStyle(fontSize: 20, color: kButtonColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    _buildTimeBox(seconds), const SizedBox(width: 12),
                    Text(isTimerRunning ? 'Work' : 'Hrs',
                        style: TextStyle(fontSize: 14, color: kButtonColor, fontWeight: FontWeight.w500)),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: kButtonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedShift,
                    style: const TextStyle(color: kTextColor, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),

                const SizedBox(height: 15),

                if (!isCheckedIn) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _authenticateAndCheckIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kButtonColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.face, color: kTextColor, size: 14),
                                SizedBox(height: 2),
                                Text('Register', style: TextStyle(color: kTextColor, fontSize: 9, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _performCheckIn('manual'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kButtonColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.touch_app, color: kTextColor, size: 14),
                                SizedBox(height: 2),
                                Text('Check in', style: TextStyle(color: kTextColor, fontSize: 9, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmCheckOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: kTextColor, size: 13),
                          SizedBox(width: 8),
                          Text('Check Out', style: TextStyle(color: kTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],

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
        borderRadius: BorderRadius.circular(6),
        border: isTimerRunning
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isTimerRunning ? Colors.green : kButtonColor,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['', 'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return months[month];
  }

  void _confirmCheckOut() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        title: const Text('Check Out'),
        content: Text(
          'Are you sure you want to check out?\n'
          'Work duration: ${hours}h ${minutes}m ${seconds}s',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c, rootNavigator: true).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(c, rootNavigator: true).pop();
              _performCheckOut();
            },
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
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
          TextButton(onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(), child: const Text('OK')),
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
          TextButton(onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(), child: const Text('OK')),
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
          TextButton(onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(), child: const Text('OK')),
        ],
      ),
    );
  }
}
