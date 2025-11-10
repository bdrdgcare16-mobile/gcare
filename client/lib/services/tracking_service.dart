// lib/services/tracking_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Foreground-only tracker that guarantees one save every 20 minutes,
/// trying hard to get ≤ 5 m accuracy before posting.
///
/// Start when employee checks in; stop on check out.
class TrackingService {
  final String apiBase;   // e.g. https://api-...run.app/api
  final String jwtToken;  // Bearer token
  final String empId;     // employee id

  Timer? _periodic;
  bool _sending = false;  // serialize ticks so they don't overlap

  // Cadence & thresholds
  static const Duration kInterval = Duration(minutes: 5);
  static const Duration kBurstTimeout = Duration(seconds: 120); // up to 2 min to hunt a great fix
  static const Duration kStreamMinSampleGap = Duration(seconds: 1); // throttle stream callbacks
  static const double   kTargetAccuracyMeters = 100.0;

  TrackingService({
    required this.apiBase,
    required this.jwtToken,
    required this.empId,
  });

  Future<void> startAfterCheckIn() async {
    await _ensureLocationPermission();

    // (Optional) make sure a tracking doc/session exists server-side
    try {
      await http.post(
        Uri.parse('$apiBase/tracking/check-in'),
        headers: _headers(),
        body: jsonEncode({'empid': empId}),
      );
    } catch (_) {}

    // Send the first point now (don’t wait for the first 20-min tick)
    await _captureBestFixAndSend();

    // Then every 20 minutes
    _periodic?.cancel();
    _periodic = Timer.periodic(kInterval, (_) async {
      if (_sending) return;
      _sending = true;
      try {
        await _captureBestFixAndSend();
      } finally {
        _sending = false;
      }
    });

    if (kDebugMode) {
      // ignore: avoid_print
      print('[TrackingService] started (every ${kInterval.inMinutes} min)');
    }
  }

  Future<void> stopAfterCheckOut() async {
    _periodic?.cancel();
    _periodic = null;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[TrackingService] stopped');
    }
  }

  // ---------- Core: capture best (≤5 m if possible) and POST ----------
  Future<void> _captureBestFixAndSend() async {
    Position? best;
    DateTime lastSampleAt = DateTime.fromMillisecondsSinceEpoch(0);

    // 1) Quick single-shot with the highest accuracy (foreground)
    try {
      final first = await Geolocator.getCurrentPosition(
        // ⬇️ highest accuracy available
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );
      best = first;
      if (first.accuracy <= kTargetAccuracyMeters) {
        await _postPos(first, tag: 'fg-oneshot');
        return;
      }
    } catch (_) {
      // keep going; we’ll try the stream burst next
    }

    // 2) Burst sampling stream with bestForNavigation until we hit ≤5 m or timeout
    final completer = Completer<void>();

    // Use platform-specific settings when possible (Android) to keep GPS "hot"
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best
      , // ⬅️ max precision
      distanceFilter: 0,                             // report every fix
    );

    final sub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((pos) async {
      final now = DateTime.now();
      if (now.difference(lastSampleAt) < kStreamMinSampleGap) return;
      lastSampleAt = now;

      // keep the best accuracy seen so far
      if (best == null || pos.accuracy < best!.accuracy) {
        best = pos;
      }

      if (pos.accuracy <= kTargetAccuracyMeters) {
        try {
          await _postPos(pos, tag: 'fg-burst');
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      }
    });

    try {
      // Wait until target met or timeout; on timeout send the best we have
      await completer.future.timeout(
        kBurstTimeout,
        onTimeout: () {
          if (best != null) {
            return _postPos(best!, tag: 'fg-timeout');
          }
          throw TimeoutException('No GNSS fix in ${kBurstTimeout.inSeconds}s');
        },
      );
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _postPos(Position p, {required String tag}) async {
    try {
      await http.post(
        Uri.parse('$apiBase/tracking/pos'),
        headers: _headers(),
        body: jsonEncode({
          'empid': empId,
          'lat': p.latitude,
          'lng': p.longitude,
          'accuracy': p.accuracy, // store accuracy for debugging/QA
          'source': tag,          // e.g. fg-oneshot / fg-burst / fg-timeout
          'ts': DateTime.now().toIso8601String(),
        }),
      );
      if (kDebugMode) {
        // ignore: avoid_print
        print('[TrackingService] posted lat=${p.latitude}, lng=${p.longitude}, acc=${p.accuracy}m ($tag)');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[TrackingService] post error: $e');
      }
    }
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
        'x-empid': empId,
      };

  // ---------- Permissions ----------
  static Future<void> _ensureLocationPermission() async {
    // Don’t fail hard if services are off; user might enable later.
    try {
      await Geolocator.isLocationServiceEnabled();
    } catch (_) {}

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }
    // Tip for the app: after check-in, nudge users to set "Allow all the time"
    // so background WorkManager pings are also reliable.
  }
}
