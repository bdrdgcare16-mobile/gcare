import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

import 'package:serv_app/models/company_data.dart';

// Background scheduler (WorkManager wrapper)
import 'package:serv_app/background/background_tasks.dart';
import 'package:serv_app/main.dart' show startFgTracking, stopFgTracking;
// Foreground timer (legacy – extra backup)
import 'package:serv_app/services/tracking_service.dart';

// ==== Colors ====
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ---- API base ----
const String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

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

  // No auto-checkout in client
  final bool _autoCheckoutEnabled = false;
  Timer? _autoCheckoutTimer;

  int totalSeconds = 0;
  String hours = "00";
  String minutes = "00";
  String seconds = "00";

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _authInProgress = false;

  // NEW: remember the source of today's check-in ('biometric' | 'manual')
  String _checkInSource = '';

  // Optional legacy foreground tracker
  TrackingService? _tracking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
    _checkUserFaceRegistration();
    _requestBackgroundLocationPermission();
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
      _restoreCheckInFromPrefs().then((_) => _loadTodayStatus());
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

    if (!mounted) return;
    setState(() {
      isCheckedIn = true;
      isTimerRunning = true;
    });

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
  }

  Future<void> _maybeAutoCheckoutImmediatelyIfPastShiftEnd() async {
    if (!_autoCheckoutEnabled) return;
    if (!isCheckedIn) return;
    final times = _getShiftTimes(selectedShift);
    var endDT = _toDateTime(times.end);
    final startDT = _toDateTime(times.start);
    if (endDT.isBefore(startDT)) endDT = endDT.add(const Duration(days: 1));
    if (DateTime.now().isAfter(endDT)) {
      await _performCheckOut(silent: true);
    }
  }

  Future<void> _loadUserInfo() async {
    final token = CompanyData.token;
    final url = Uri.parse('$_apiBase/auth/me');

    try {
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final profile = (data['employeeProfile'] is Map<String, dynamic>)
            ? (data['employeeProfile'] as Map<String, dynamic>)
            : <String, dynamic>{};

        setState(() {
          userName = (data['name'] ?? profile['name'] ?? "") as String;
          userId = (data['empid'] ?? profile['empid'] ?? "") as String;
          dept = (profile['dept'] ?? data['dept'] ?? "") as String;
          location = (profile['location'] ?? data['location'] ?? "") as String;
          selectedShift =
              (profile['shiftGroup'] ?? data['shiftGroup'] ?? "Shift") as String;

          final hasShift = selectedShift.isNotEmpty && selectedShift != "Shift";
          shiftClicked = hasShift;
          isShiftSelected = hasShift;
        });

        await _restoreCheckInFromPrefs();
        await _loadTodayStatus();
      } else {
        setState(() {
          userName = "(unknown)";
          userId = widget.employeeDocId;
          dept = "";
          location = "";
        });
        await _restoreCheckInFromPrefs();
      }
    } catch (_) {
      setState(() {
        userName = "(error)";
        userId = widget.employeeDocId;
        dept = "";
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
      if (res.statusCode != 200) return;

      final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      final me = list.firstWhere(
        (e) => (e['empid']?.toString() ?? '') == userId,
        orElse: () => const {},
      );

      final checkIn = (me['checkIn']) as String?;
      final checkOut = (me['checkOut']) as String?;
      // NEW: read source if API provides it (falls back to 'source')
      _checkInSource = (me['checkInSource'] ?? me['source'] ?? '').toString().toLowerCase();

      if (checkOut != null && checkOut.isNotEmpty) {
        _resetTimerAndState();
        _cancelAutoCheckout();
        await _clearCheckInFromPrefs();
        if (!mounted) return;
        setState(() {
          isCheckedIn = false;
          _checkInSource = ''; // cleared after checkout
        });
        return;
      }

      if (checkIn != null && checkIn.isNotEmpty) {
        _applyCheckedInFromServer(checkIn);
        await _saveCheckInToPrefs();
        return;
      }

      _resetTimerAndState();
      _cancelAutoCheckout();
      await _clearCheckInFromPrefs();
      if (!mounted) return;
      setState(() {
        isCheckedIn = false;
        _checkInSource = '';
      });
    } catch (_) {}
  }

  void _applyCheckedInFromServer(String hhmmss) {
    try {
      final now = DateTime.now();
      final parts = hhmmss.split(':').map((s) => int.tryParse(s) ?? 0).toList();
      final inDT = DateTime(
        now.year, now.month, now.day, parts[0], parts[1], parts[2],
      );
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
    } catch (_) {
      _startWorkTimer();
      setState(() => isCheckedIn = true);
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

  // ---------------- GEO ----------------
  Future<Position?> _getPositionUsingDemo({
    bool quiet = false,
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    final hasPermission = await _ensurePermissionDemo(quiet: quiet);
    if (!hasPermission) return null;

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!quiet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      if (!quiet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
      return null;
    }
  }

  Future<void> _requestBackgroundLocationPermission() async {
    // Check if we already have the permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) return;

    // Show the permission dialog
    if (!mounted) return;
    
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Background Location Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'To track your work hours accurately, please allow background location access:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Location Permission
              _buildPermissionItem(
                icon: Icons.location_on_outlined,
                title: 'Background Location',
                description: 'To track your work hours even when the app is in the background',
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text(
                      'Not Now',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Allow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldRequest == true) {
      // Request background location permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // If still not granted, show settings dialog
      if (permission != LocationPermission.always && mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Background Location Required'),
            content: const Text(
              'Background location is required for accurate work hour tracking. ' 
              'Please enable "Always" location permission in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Open app settings directly to location permissions
                  await openAppSettings();
                  // Also open location settings to enable location if needed
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<_Branch?> _fetchMyBranch() async {
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/office/locations'),
        headers: _authHeaders(),
      );
      if (res.statusCode != 200) return null;
      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
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
      final lat = (match['latitude'] as num).toDouble();
      final lng = (match['longitude'] as num).toDouble();
      final rad = (match['radius'] as num).toDouble();
      final nm = (match['branchName'] ?? match['name'] ?? '').toString();
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

  Future<bool> _confirmOutside(
    double distance,
    double radius,
    String branchName,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Other location'),
            content: Text(
              'You are in other location. Do you want to proceed with check-in here?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Proceed')),
            ],
          ),
        ) ??
        false;
  }

  /// Detect category from time vs shift (for when to ask a reason)
  String? _detectCheckInCategory() {
    final times = _getShiftTimes(selectedShift);
    final now = DateTime.now();
    final start = _toDateTime(times.start);
    if (now.isAfter(start.add(const Duration(minutes: 5)))) return 'Late Check-in';
    if (now.isBefore(start.subtract(const Duration(minutes: 10)))) return 'Early Check-in';
    return null;
  }

  String? _detectCheckoutCategory() {
    final times = _getShiftTimes(selectedShift);
    var end = _toDateTime(times.end);
    final start = _toDateTime(times.start);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    final now = DateTime.now();
    if (now.isBefore(end.subtract(const Duration(minutes: 5)))) return 'Late Checkout';
    return null;
  }

  /// Fetch ALL reasons from /api/reasons (uses 'reason' text)
  Future<List<Map<String, String>>> _fetchAllReasons() async {
    try {
      final res = await http.get(Uri.parse('$_apiBase/reasons?limit=200'));
      if (res.statusCode != 200) return <Map<String, String>>[];

      final body = jsonDecode(res.body);
      final List items = (body is List) ? body : (body['items'] as List? ?? <dynamic>[]);

      return items.map<Map<String, String>>((raw) {
        final m = (raw as Map).cast<String, dynamic>();
        return {
          'id': (m['id'] ?? m['_id'] ?? '').toString(),
          'reason': (m['reason'] ?? '').toString(),
          'typeId': (m['typeId'] ?? '').toString(),
          'typeName': (m['typeName'] ?? '').toString(),
        };
      }).where((e) => (e['reason'] ?? '').toString().isNotEmpty).toList();
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  /// Dialog: dropdown of reason texts
  /// If "Others" is chosen, ask for a custom description and
  /// return it as `reasonText` with empty `reasonId`.
  Future<Map<String, String>?> _pickReason(String title, {String? prefer}) async {
    final reasons = await _fetchAllReasons();
    if (reasons.isEmpty) {
      _showInfoDialog('No reasons configured.');
      return null;
    }

    String? selectedId;
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedId == null ? null : () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (selectedId == null) return null;
    final chosen = reasons.firstWhere((r) => r['id'] == selectedId);
    final chosenText = (chosen['reason'] ?? '').toLowerCase();

    // If the user chose "Other"/"Others", collect a free-text description.
    if (chosenText.contains('other')) {
      final controller = TextEditingController();
      String? typed;
      await showDialog(
        context: context,
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final v = controller.text.trim();
                          if (v.isNotEmpty) {
                            typed = v;
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

      if (typed == null || typed!.isEmpty) return null; // user cancelled

      return {
        'reasonId': '', // free text -> no predefined id
        'reasonText': typed!,
        'reasonTypeId': chosen['typeId'] ?? '',
        'reasonTypeName': chosen['typeName'] ?? '',
      };
    }

    // Regular predefined reason
    return {
      'reasonId': chosen['id'] ?? '',
      'reasonText': chosen['reason'] ?? '',
      'reasonTypeId': chosen['typeId'] ?? '',
      'reasonTypeName': chosen['typeName'] ?? '',
    };
  }

  // -------------------- Check-in / out --------------------
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
        if (mounted) await _performCheckIn('biometric'); // sets _checkInSource
      } else {
        _showInfoDialog('Authentication cancelled');
      }
    } catch (e) {
      _showErrorDialog('Auth error: $e');
    } finally {
      _authInProgress = false;
    }
  }

  /// UPDATED: Optimistic check-in for instant timer + button
  Future<void> _performCheckIn(String type) async {
    Map<String, String>? reasonInfo;
    final category = _detectCheckInCategory();
    if (category != null) {
      reasonInfo = await _pickReason(category, prefer: category);
      if (category.isNotEmpty && reasonInfo == null) return;
    }

    final pos = await _getPositionUsingDemo(
      accuracy: LocationAccuracy.bestForNavigation,
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
    final url = Uri.parse('$_apiBase/attendance/check-in');

    final bodyMap = {
      'empid': userId,
      'name': userName,
      'location': location,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'accuracy': pos.accuracy,
      'source': type, // IMPORTANT
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

    // -------------------- OPTIMISTIC UI START --------------------
    final prevState = (
      wasCheckedIn: isCheckedIn,
      wasTimerRunning: isTimerRunning,
      prevSeconds: totalSeconds,
      prevH: hours, prevM: minutes, prevS: seconds
    );

    setState(() {
      isCheckedIn = true;
      _checkInSource = type.toLowerCase(); // remember how we checked in
    });
    _startWorkTimer();
    await _saveCheckInToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking in… syncing in background')),
    );
    // -------------------- OPTIMISTIC UI END ----------------------

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyMap),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        unawaited(_trackingCheckInAndSeed(pos));
        unawaited(_ensureNotificationPermission());
        unawaited(_maybePromptBatteryOptimization());
        unawaited(startFgTracking(empid: userId, token: CompanyData.token));
        unawaited(scheduleBackgroundTracking(empid: userId, token: CompanyData.token));
        _tracking ??= TrackingService(
          apiBase: _apiBase,
          jwtToken: CompanyData.token,
          empId: userId,
        );
        unawaited(_tracking!.startAfterCheckIn());

        _scheduleAutoCheckout();
        _showSuccessDialog('Checked in successfully!');
      } else {
        final msg = (jsonDecode(res.body)['error'] ?? jsonDecode(res.body)['message']).toString();
        await _rollbackAfterFailedCheckIn(
          wasCheckedIn: prevState.wasCheckedIn,
          wasTimerRunning: prevState.wasTimerRunning,
          prevSeconds: prevState.prevSeconds,
          prevH: prevState.prevH,
          prevM: prevState.prevM,
          prevS: prevState.prevS,
        );
        setState(() => _checkInSource = ''); // rollback source
        _showErrorDialog(msg);
      }
    } catch (e) {
      await _rollbackAfterFailedCheckIn(
        wasCheckedIn: prevState.wasCheckedIn,
        wasTimerRunning: prevState.wasTimerRunning,
        prevSeconds: prevState.prevSeconds,
        prevH: prevState.prevH,
        prevM: prevState.prevM,
        prevS: prevState.prevS,
      );
      setState(() => _checkInSource = ''); // rollback source
      _showErrorDialog('Network error: $e');
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
    await _clearCheckInFromPrefs();
    _timer?.cancel();
    setState(() {
      isCheckedIn = wasCheckedIn;
      isTimerRunning = wasTimerRunning;
      totalSeconds = prevSeconds;
      hours = prevH;
      minutes = prevM;
      seconds = prevS;
    });
  }

  // NEW: biometric-gated checkout when needed
  Future<void> _authenticateAndCheckOut() async {
    try {
      _authInProgress = true;

      final canBio = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      if (!canBio && !supported) {
        _showErrorDialog('Biometric not available on this device');
        return;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to check out',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (ok) {
        _confirmCheckOut(proceedAction: () => _performCheckOut());
      } else {
        _showInfoDialog('Authentication cancelled');
      }
    } catch (e) {
      _showErrorDialog('Auth error: $e');
    } finally {
      _authInProgress = false;
    }
  }

  Future<void> _performCheckOut({bool silent = false}) async {
    Map<String, String>? reasonInfo;
    final category = _detectCheckoutCategory();
    if (category != null) {
      reasonInfo = await _pickReason(category, prefer: category);
      if (category.isNotEmpty && reasonInfo == null) {
        if (!silent) _showInfoDialog('Checkout cancelled');
        return;
      }
    }

    final pos = await _getPositionUsingDemo(
      quiet: silent,
      accuracy: LocationAccuracy.bestForNavigation,
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
    }

    final token = CompanyData.token;
    final url = Uri.parse('$_apiBase/attendance/check-out');

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

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyMap),
      );

      if (res.statusCode == 200) {
        // stop services
        await stopFgTracking();
        await cancelBackgroundTracking(empid: userId);
        await _tracking?.stopAfterCheckOut();

        _stopWorkTimer();
        _cancelAutoCheckout();
        await _clearCheckInFromPrefs();
        setState(() {
          isCheckedIn = false;
          _checkInSource = ''; // clear after successful checkout
        });
        if (!silent) _showSuccessDialog('Checked out successfully!');
        await _trackingCheckOut();
      } else {
        final msg = (jsonDecode(res.body)['error'] ?? jsonDecode(res.body)['message']).toString();
        if (!silent) _showErrorDialog(msg);
      }
    } catch (e) {
      if (!silent) {
        _showErrorDialog('Network error: $e');
      }
    }
  }

  // -------------------- Tracking glue (server) --------------------
  Future<void> _trackingCheckInAndSeed(Position pos) async {
    final token = CompanyData.token;
    if (token.isEmpty || userId.isEmpty) return;
    try {
      final base = 'https://api-zmj7dqloiq-el.a.run.app/api/tracking';

      await http.post(
        Uri.parse('$base/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': userId,
        },
        body: jsonEncode({}),
      );

      await http.post(
        Uri.parse('$base/pos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': userId,
        },
        body: jsonEncode({'lat': pos.latitude, 'lng': pos.longitude}),
      );
    } catch (_) {}
  }

  Future<void> _trackingCheckOut() async {
    final token = CompanyData.token;
    if (token.isEmpty || userId.isEmpty) return;
    try {
      final base = 'https://api-zmj7dqloiq-el.a.run.app/api/tracking';
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

  // ---------- Permissions / Settings nudges ----------
  Future<void> _ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _maybePromptBatteryOptimization() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      );
      await intent.launch();
    } catch (_) {
      try {
        const intent = AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMATION_SETTINGS',
        );
        await intent.launch();
      } catch (_) {}
    }
  }

  // ---------- UI helpers ----------
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
    if (!_autoCheckoutEnabled) return;
    if (!isCheckedIn) return;

    final times = _getShiftTimes(selectedShift);
    var endDT = _toDateTime(times.end);
    final startDT = _toDateTime(times.start);
    if (endDT.isBefore(startDT)) endDT = endDT.add(const Duration(days: 1));

    final now = DateTime.now();
    final wait = endDT.isAfter(now) ? endDT.difference(now) : const Duration(seconds: 1);

    _autoCheckoutTimer = Timer(wait, () async {
      if (!mounted || !isCheckedIn) return;
    });
  }

  void _cancelAutoCheckout() {
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = null;
  }

  // -------------------- UI --------------------
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
          style: TextStyle(color: kTextColor, fontSize: 18, fontWeight: FontWeight.w600),
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
                            '${DateTime.now().year}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Image.asset('assets/images/timer1.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeBox(hours),
                    const SizedBox(width: 6),
                    const Text(':', style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 169, 163, 182), fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    _buildTimeBox(minutes),
                    const SizedBox(width: 6),
                    const Text(':', style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 169, 163, 182), fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    _buildTimeBox(seconds),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: kButtonColor, borderRadius: BorderRadius.circular(4)),
                  child: Text(selectedShift, style: const TextStyle(color: kTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 15),
                if (!isCheckedIn)
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
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face, color: kTextColor, size: 14),
                                SizedBox(height: 2),
                                Text('Biometric', style: TextStyle(color: kTextColor, fontSize: 9, fontWeight: FontWeight.w500)),
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
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app, color: kTextColor, size: 14),
                                SizedBox(height: 2),
                                Text('Manual', style: TextStyle(color: kTextColor, fontSize: 9, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // NEW: gate checkout based on how user checked in
                      onPressed: () {
                        if (_checkInSource == 'biometric') {
                          // must authenticate biometrically to checkout
                          _authenticateAndCheckOut();
                        } else {
                          // manual flow
                          _confirmCheckOut(proceedAction: () => _performCheckOut());
                        }
                      },
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
    const months = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month];
  }

  // UPDATED: confirm dialog accepts an action to run on "Check Out"
  void _confirmCheckOut({required VoidCallback proceedAction}) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        title: const Text('Check Out'),
        content: Text('Are you sure you want to check out?\nWork duration: ${hours}h ${minutes}m ${seconds}s'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c, rootNavigator: true).pop(), child: const Text('Cancel')),
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
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
            onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
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
            onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
