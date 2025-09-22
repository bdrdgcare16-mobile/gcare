// // lib/services/tracking_service.dart
// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:workmanager/workmanager.dart';

// /// Firestore structure:
// /// Collection: "X"
// ///   Doc: <empId>
// ///     Subcollection: "days"
// ///       Doc: <yyyy-MM-dd>
// ///         { pathMap: [ {lat: <double>, lng: <double>, ts: <iso>}, ... ] }
// ///
// /// If you prefer "X/<empId>-<yyyy-MM-dd>" as a single doc, adjust _docRef().

// class TrackingService {
//   static const String _rootCollection = 'X';
//   static const String _daysSub = 'days';

//   final String apiBase; // not used here (Firestore direct), kept if you extend later
//   final String jwtToken; // not used here
//   final String empId;

//   Timer? _foregroundTimer;

//   TrackingService({
//     required this.apiBase,
//     required this.jwtToken,
//     required this.empId,
//   });

//   /// Call this after a successful Check-In.
//   /// It resets today's pathMap to [] and starts a 20-minute foreground timer.
//   Future<void> startAfterCheckIn() async {
//     await _ensureFirebase();
//     await _ensureLocationPermission();

//     // Reset today's pathMap to empty:
//     await _docRef(DateTime.now()).set({'pathMap': []}, SetOptions(merge: true));

//     // Save an immediate point (so there's at least one sample at check-in)
//     await _captureAndAppendPoint();

//     // Start foreground timer: every 20 minutes
//     _foregroundTimer?.cancel();
//     _foregroundTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
//       await _captureAndAppendPoint();
//     });

//     // Also ensure background task is registered (runs even when app inactive)
//     await _registerBackgroundTask(empId);
//   }

//   /// Call this after a successful Check-Out.
//   /// It cancels the foreground timer and background task.
//   Future<void> stopAfterCheckOut() async {
//     _foregroundTimer?.cancel();
//     _foregroundTimer = null;
//     await _cancelBackgroundTask();
//   }

//   /// Append current GPS point to today's pathMap.
//   Future<void> _captureAndAppendPoint() async {
//     try {
//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best,
//       );
//       final nowIso = DateTime.now().toIso8601String();

//       await _docRef(DateTime.now()).set({
//         'pathMap': FieldValue.arrayUnion([
//           {
//             'lat': pos.latitude,
//             'lng': pos.longitude,
//             'ts': nowIso,
//           }
//         ])
//       }, SetOptions(merge: true));
//     } catch (e) {
//       // Intentionally swallow errors – tracking should not crash the app
//       // You may log this to your crash/analytics tool.
//     }
//   }

//   /// Firestore doc for the given date.
//   DocumentReference<Map<String, dynamic>> _docRef(DateTime d) {
//     final id =
//         '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
//     return FirebaseFirestore.instance
//         .collection(_rootCollection)
//         .doc(empId)
//         .collection(_daysSub)
//         .doc(id);
//   }

//   static Future<void> _ensureFirebase() async {
//     // If Firebase is already initialized, this is a no-op.
//     try {
//       Firebase.apps.isNotEmpty
//           ? null
//           : await Firebase.initializeApp();
//     } catch (_) {
//       // ignore
//     }
//   }

//   static Future<void> _ensureLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       // You could prompt user to enable GPS; here we just request anyway.
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//     if (permission == LocationPermission.deniedForever) {
//       // Permission permanently denied, cannot proceed.
//       throw Exception('Location permission denied forever');
//     }
//   }

//   // ---------------- Background (Workmanager) ----------------

//   static const String _taskUniqueName = 'tracking_pathmap_20min';

//   /// Must be called once in your app (e.g., in main()) before using background.
//   static Future<void> ensureWorkmanagerInitialized() async {
//     await Workmanager().initialize(
//       callbackDispatcher,
//       isInDebugMode: false,
//     );
//   }

//   static Future<void> _registerBackgroundTask(String empId) async {
//     // Minimum reliable period on Android is 15 minutes; we choose 20 min.
//     // For iOS, Workmanager has limitations (requires BG modes).
//     await Workmanager().registerPeriodicTask(
//       _taskUniqueName,
//       _taskUniqueName,
//       frequency: const Duration(minutes: 15),
//       initialDelay: const Duration(minutes: 15),
//       inputData: {'empId': empId},
//       constraints: Constraints(
//         networkType: NetworkType.connected,
//         requiresBatteryNotLow: false,
//         requiresCharging: false,
//       ),
//       existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
//       backoffPolicy: BackoffPolicy.linear,
//       backoffPolicyDelay: const Duration(minutes: 5),
//     );
//   }

//   static Future<void> _cancelBackgroundTask() async {
//     await Workmanager().cancelByUniqueName(_taskUniqueName);
//   }
// }

// /// Background entry point.
// /// IMPORTANT: Keep this a top-level or static function.
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     try {
//       await TrackingService._ensureFirebase();
//       await TrackingService._ensureLocationPermission();

//       final empId = (inputData?['empId'] as String?) ?? '';
//       if (empId.isEmpty) return Future.value(true);

//       final now = DateTime.now();
//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best,
//       );

//       // Append point to "X/<empId>/days/<yyyy-MM-dd>"
//       final id =
//           '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

//       await FirebaseFirestore.instance
//           .collection('X')
//           .doc(empId)
//           .collection('days')
//           .doc(id)
//           .set({
//         'pathMap': FieldValue.arrayUnion([
//           {
//             'lat': pos.latitude,
//             'lng': pos.longitude,
//             'ts': now.toIso8601String(),
//           }
//         ])
//       }, SetOptions(merge: true));
//     } catch (_) {
//       // avoid failing the task; just report success to let scheduler continue
//     }
//     return Future.value(true);
//   });
// }
// lib/services/tracking_service.dart
// lib/services/tracking_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Foreground tracking only (timer while app is open).
/// Android true background every ~20 min is handled by Workmanager in main.dart.
///
/// Server shape:
///   POST {apiBase}/tracking/check-in   (optional safety)
///   POST {apiBase}/tracking/pos        { lat, lng } with Bearer token and x-empid
class TrackingService {
  final String apiBase;   // e.g. https://api-...run.app/api
  final String jwtToken;  // Bearer token
  final String empId;     // employee id

  Timer? _foregroundTimer;

  TrackingService({
    required this.apiBase,
    required this.jwtToken,
    required this.empId,
  });

  /// Call after successful check-in.
  /// - (Safely) ensure server doc exists
  /// - send an immediate point
  /// - start a 20-minute foreground timer
  Future<void> startAfterCheckIn() async {
    await _ensureLocationPermission();

    // Create/ensure today's doc on server (safe if already exists)
    try {
      await http.post(
        Uri.parse('$apiBase/tracking/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
          'x-empid': empId,
        },
        body: jsonEncode({}), // server defaults to today
      );
    } catch (_) {
      // ignore; we'll still send the point
    }

    // Immediate point
    await _sendCurrentPos();

    // Foreground timer every 20 minutes while app is open
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(minutes: 20), (_) async {
      await _sendCurrentPos();
    });

    if (kDebugMode) {
      // helpful trace in debug
      // ignore: avoid_print
      print('[TrackingService] foreground timer started (20 min)');
    }
  }

  /// Call after successful check-out.
  /// Stops the foreground timer. (Android background is stopped via main.dart helpers.)
  Future<void> stopAfterCheckOut() async {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;

    if (kDebugMode) {
      // ignore: avoid_print
      print('[TrackingService] foreground timer stopped');
    }
  }

  /* ---------------- internal helpers ---------------- */

  Future<void> _sendCurrentPos() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      await http.post(
        Uri.parse('$apiBase/tracking/pos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
          'x-empid': empId,
        },
        body: jsonEncode({
          'lat': pos.latitude,
          'lng': pos.longitude,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[TrackingService] send pos error: $e');
      }
    }
  }

  static Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Optionally prompt to enable Location Services in UI layer.
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }
  }
}
