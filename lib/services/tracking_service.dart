import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/services/api_service.dart';

/// Foreground-only tracker that guarantees one save every 20 minutes,
/// trying hard to get ≤ 5 m accuracy before posting.
///
/// Start when employee checks in; stop on check out.
class TrackingService {
  final String apiBase; // e.g. https://api-...run.app/api
  final String jwtToken; // Bearer token
  final String empId; // employee id

  Timer? _periodic;
  bool _sending = false; // serialize ticks so they don't overlap
  StreamSubscription<Position>? _positionStream; // kept as-is

  // Cadence & thresholds
  static const Duration kInterval = Duration(minutes: 20);
  static const Duration kBurstTimeout =
      Duration(seconds: 120); // up to 2 min to hunt a great fix
  static const Duration kStreamMinSampleGap =
      Duration(seconds: 5); // Increased from 1s to reduce redundant points
  static const double kTargetAccuracyMeters =
      20.0; // Reduced from 100m to 20m for better precision

  TrackingService({
    required this.apiBase,
    required this.jwtToken,
    required this.empId,
  });

  Future<void> startAfterCheckIn() async {
    // Prevent duplicate tracking sessions
    if (_periodic != null || _positionStream != null) {
      if (kDebugMode) {
        print('[TrackingService] already started, skipping duplicate start');
      }
      return;
    }

    print('[TrackingService] LOG: Starting tracking service for empId: $empId');
    await _ensureLocationPermission();

    // (Optional) make sure a tracking doc/session exists server-side
    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/tracking/check-in'),
        headers: _headers(),
        body: jsonEncode({'empid': empId}),
      );
      if (kDebugMode) {
        print('[TrackingService] check-in session created for empId: $empId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TrackingService] check-in session creation failed: $e');
      }
    }

    // Immediate first capture after check-in
    if (!_sending) {
      _sending = true;
      try {
        await _captureBestFixAndSend();
        if (kDebugMode) {
          print('[TrackingService] initial location capture completed');
        }
      } finally {
        _sending = false;
      }
    }

    // Only periodic capture is kept
    _periodic?.cancel();
    _periodic = Timer.periodic(kInterval, (_) async {
      if (_sending) return;
      _sending = true;
      try {
        await _captureBestFixAndSend();
        if (kDebugMode) {
          print('[TrackingService] periodic location capture completed');
        }
      } finally {
        _sending = false;
      }
    });

    if (kDebugMode) {
      print('[TrackingService] started (every ${kInterval.inMinutes} min) with periodic timer only');
    }
  }

  Future<void> stopAfterCheckOut() async {
    if (kDebugMode) {
      print('[TrackingService] stopping tracking service...');
    }

    // Cancel periodic timer
    if (_periodic != null) {
      _periodic!.cancel();
      _periodic = null;
      if (kDebugMode) {
        print('[TrackingService] periodic timer cancelled');
      }
    }

    // Cancel position stream
    if (_positionStream != null) {
      await _positionStream!.cancel();
      _positionStream = null;
      if (kDebugMode) {
        print('[TrackingService] position stream cancelled');
      }
    }

    // Reset sending flag
    _sending = false;

    if (kDebugMode) {
      print('[TrackingService] tracking service stopped completely');
    }
  }

  // Start continuous high-accuracy position tracking
  // Kept unchanged, but no longer called from startAfterCheckIn()
  void _startContinuousTracking() {
    // Cancel any existing stream first
    if (_positionStream != null) {
      if (kDebugMode) {
        print('[TrackingService] canceling existing continuous stream');
      }
      _positionStream?.cancel();
      _positionStream = null;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
      timeLimit: Duration(seconds: 30),
    );

    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          if (position.accuracy <= kTargetAccuracyMeters) {
            await _postPos(position, tag: 'continuous');
          }
        },
        onError: (e) {
          if (kDebugMode) {
            print('[TrackingService] Position stream error: $e');
          }
          if (!_sending && _positionStream != null) {
            _sending = true;
            Future.delayed(const Duration(seconds: 5), () {
              if (kDebugMode) {
                print('[TrackingService] attempting to restart continuous stream');
              }
              _startContinuousTracking();
              _sending = false;
            });
          }
        },
        cancelOnError: false,
      );

      if (kDebugMode) {
        print('[TrackingService] continuous stream started successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TrackingService] failed to start continuous stream: $e');
      }
    }
  }

  // ---------- Core: capture best and POST ----------
  Future<void> _captureBestFixAndSend() async {
    Position? best;
    DateTime lastSampleAt = DateTime.fromMillisecondsSinceEpoch(0);

    // 1) Quick single-shot with the highest accuracy (foreground)
    try {
      final first = await Geolocator.getCurrentPosition(
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

    // 2) Burst sampling stream with bestForNavigation until we hit target or timeout
    final completer = Completer<void>();

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    final sub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((pos) async {
      final now = DateTime.now();
      if (now.difference(lastSampleAt) < kStreamMinSampleGap) return;
      lastSampleAt = now;

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
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/tracking/pos'),
        headers: _headers(),
        body: jsonEncode({
          'empid': empId,
          'lat': p.latitude,
          'lng': p.longitude,
          'accuracy': p.accuracy,
          'source': tag,
          'ts': DateTime.now().toIso8601String(),
        }),
      );

      if (kDebugMode) {
        print(
          '[TrackingService] posted lat=${p.latitude}, lng=${p.longitude}, acc=${p.accuracy}m ($tag), status=${response.statusCode}',
        );
        print('[TrackingService] response body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
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
  }
}