// lib/background/background_tasks.dart
import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const String kBgTaskName = 'tracking_15min_task';
const String kApiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

// Keys stored so the background isolate can authenticate
const String _kBgToken = 'bg_token';
const String _kBgEmpid = 'bg_empid';

// Use the SAME checked-in flag key pattern as your UI
const String _kCheckedInKeyBase = 'att_checked_in_';

/// Background entry-point. Must be a top-level function and annotated so
/// the VM doesn't tree-shake it in release builds.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Defensive plugin usage in a background isolate
      final prefs = await SharedPreferences.getInstance();

      // Prefer persisted values; fall back to inputData
      final String token =
          prefs.getString(_kBgToken) ?? (inputData?['token'] as String? ?? '');
      final String empid =
          prefs.getString(_kBgEmpid) ?? (inputData?['empid'] as String? ?? '');

      if (token.isEmpty || empid.isEmpty) {
        // Nothing we can do—report success to avoid reschedules
        return true;
      }

      // Only send points while "checked in"
      final bool isCheckedIn =
          prefs.getBool('$_kCheckedInKeyBase$empid') ?? false;
      if (!isCheckedIn) return true;

      // In background we cannot request permissions interactively; just skip
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return true;
      }

      // Try current position first, then fall back to last-known
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) return true;

      final uri = Uri.parse('$kApiBase/tracking/pos');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': empid,
        },
        body: jsonEncode({
          'lat': pos.latitude,
          'lng': pos.longitude,
          'ts': DateTime.now().toIso8601String(),
        }),
      );

      // Always return true to signal the task finished successfully
      return true;
    } catch (_) {
      // Never crash the worker; report success to avoid exponential retries
      return true;
    }
  });
}

/// Persist auth for use by the background isolate
Future<void> persistBgAuth({
  required String token,
  required String empid,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kBgToken, token);
  await prefs.setString(_kBgEmpid, empid);
}

/// Clear persisted background auth
Future<void> clearBgAuth() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kBgToken);
  await prefs.remove(_kBgEmpid);
}

/// Schedule a 15-minute periodic tracking task.
/// Requires: workmanager compatible with your platform_interface (0.9.x), Android minSdkVersion >= 23.
Future<void> scheduleBackgroundTracking({
  required String empid,
  required String token,
}) async {
  await persistBgAuth(token: token, empid: empid);

  final uniqueName = 'track15_$empid';

  await Workmanager().registerPeriodicTask(
    uniqueName,              // uniqueName
    kBgTaskName,             // taskName
    frequency: const Duration(minutes: 15), // Android minimum
    initialDelay: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
    inputData: {'empid': empid, 'token': token},

    // ✅ Param name expected by your installed API + enum type required:
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,

    // Backoff policy still supported:
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 5),
  );
}

/// Cancel the periodic tracking task for a given employee
Future<void> cancelBackgroundTracking({required String empid}) async {
  final uniqueName = 'track15_$empid';
  await Workmanager().cancelByUniqueName(uniqueName);
  await clearBgAuth();
}
