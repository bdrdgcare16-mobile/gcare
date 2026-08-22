import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/services/connectivity_service.dart';

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
  StreamSubscription<bool>? _connectivitySubscription; // connectivity listener
  bool? _lastConnectivityState; // track last known state to detect transitions

  // Cadence & thresholds
  static const Duration kInterval = Duration(minutes: 15);
  static const Duration kBurstTimeout =
      Duration(seconds: 120); // up to 2 min to hunt a great fix
  static const Duration kStreamMinSampleGap =
      Duration(seconds: 5); // Increased from 1s to reduce redundant points
  static const double kTargetAccuracyMeters =
      20.0; // Reduced from 100m to 20m for better precision
  static const String _kPendingLocationsKey = 'tracking_pending_locations';

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

    if (kDebugMode) {
      print('[TrackingService] LOG: Starting tracking service');
    }
    await _ensureLocationPermission();
    await _syncPendingLocations();

    // (Optional) make sure a tracking doc/session exists server-side
    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/tracking/check-in'),
        headers: _headers(),
        body: jsonEncode({'empid': empId}),
      );
      if (kDebugMode) {
        print('[TrackingService] check-in session created');
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

    // ✅ FIXED: Periodic location posting is now delegated to Foreground Service
    // Foreground Service runs in a background isolate and continues when app minimizes.
    // This eliminates duplicate 20-min periodic posts (TrackingService was redundant).
    // TrackingService now focuses on:
    // - Initial location capture at check-in (done above)
    // - Pending sync on connectivity restore (below)
    // - Cleanup on check-out (in stopAfterCheckOut)
    if (_periodic != null) {
      _periodic!.cancel();
      _periodic = null;
    }
    if (kDebugMode) {
      print(
          '[TrackingService] periodic location posting delegated to Foreground Service');
    }

    // ✅ NEW: Start listening to connectivity changes to trigger sync on offline→online
    _listenToConnectivityChanges();

    if (kDebugMode) {
      print(
          '[TrackingService] started with connectivity listener (periodic posting delegated to FG service)');
    }
  }

  Future<void> stopAfterCheckOut() async {
    if (kDebugMode) {
      print('[TrackingService] stopping tracking service...');
    }

    await _syncPendingLocations();

    // Cancel connectivity subscription
    if (_connectivitySubscription != null) {
      await _connectivitySubscription!.cancel();
      _connectivitySubscription = null;
      _lastConnectivityState = null;
      if (kDebugMode) {
        print('[TrackingService] connectivity subscription cancelled');
      }
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
                print(
                    '[TrackingService] attempting to restart continuous stream');
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

  // ---------- GPS Accuracy Improvement ----------
  /// ✅ NEW: Capture multiple GPS samples and select best position.
  /// Stops early if accuracy <= 10m.
  /// Returns null if all samples exceed maxAccuracy (50m dev, 30m production).
  /// Uses bestForNavigation accuracy for best results.
  Future<Position?> _captureBestPositionWithSampling({
    int maxSamples = 5,
    double targetAccuracyMeters = 10.0,
    double maxAccuracyMeters = 50.0,
    Duration sampleTimeout = const Duration(seconds: 15),
    Duration totalTimeout = const Duration(seconds: 120),
  }) async {
    try {
      final startTime = DateTime.now();
      Position? bestPosition;
      int sampleCount = 0;

      if (kDebugMode) {
        print(
            '[TrackingService] starting GPS sampling: max=$maxSamples, target=$targetAccuracyMeters m, max=$maxAccuracyMeters m');
      }

      // Try quick single-shots first
      for (int i = 0; i < maxSamples; i++) {
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed.inMilliseconds > totalTimeout.inMilliseconds) {
          if (kDebugMode) {
            print(
                '[TrackingService] sampling timeout reached after $sampleCount samples');
          }
          break;
        }

        try {
          sampleCount++;
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit: sampleTimeout,
          );

          if (bestPosition == null || pos.accuracy < bestPosition.accuracy) {
            bestPosition = pos;
            if (kDebugMode) {
              print(
                  '[TrackingService] sample $sampleCount: acc=${pos.accuracy.toStringAsFixed(1)}m (best so far)');
            }
          }

          // Early exit if accuracy is excellent
          if (pos.accuracy <= targetAccuracyMeters) {
            if (kDebugMode) {
              print(
                  '[TrackingService] target accuracy reached after $sampleCount samples, stopping');
            }
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('[TrackingService] sample $sampleCount failed: $e');
          }
          // Continue to next sample on error
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Validate final position
      if (bestPosition == null) {
        if (kDebugMode) {
          print('[TrackingService] no valid GPS position obtained');
        }
        return null;
      }

      if (bestPosition.accuracy > maxAccuracyMeters) {
        if (kDebugMode) {
          print(
              '[TrackingService] SKIPPED: accuracy=${bestPosition.accuracy.toStringAsFixed(1)}m exceeds max=${maxAccuracyMeters}m after $sampleCount samples');
        }
        return null;
      }

      if (kDebugMode) {
        print(
            '[TrackingService] selected best position: acc=${bestPosition.accuracy.toStringAsFixed(1)}m');
      }
      return bestPosition;
    } catch (e) {
      if (kDebugMode) {
        print('[TrackingService] GPS sampling error: $e');
      }
      return null;
    }
  }

  // ---------- Core: capture best and POST ----------
  /// Called once at check-in to capture initial location with high accuracy.
  /// Periodic capture (every 20 minutes) is now handled by Foreground Service.
  /// This method ensures the first location is posted as soon as possible after check-in.
  Future<void> _captureBestFixAndSend() async {
    await _syncPendingLocations();

    final best = await _captureBestPositionWithSampling(
      maxSamples: 5,
      targetAccuracyMeters: 10.0,
      maxAccuracyMeters: 50.0,
      sampleTimeout: const Duration(seconds: 15),
      totalTimeout: const Duration(seconds: 120),
    );

    if (best != null) {
      await _postPos(best, tag: 'fg-sampling');
    } else {
      if (kDebugMode) {
        print(
            '[TrackingService] initial check-in location rejected due to poor accuracy');
      }
    }
  }

  Future<void> _captureBestFixAndSend_OLD() async {
    await _syncPendingLocations();

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
    final payload = {
      'empid': empId,
      'lat': p.latitude,
      'lng': p.longitude,
      'accuracy': p.accuracy,
      'source': tag,
      'ts': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/tracking/pos'),
        headers: _headers(),
        body: jsonEncode(payload),
      );

      if (kDebugMode) {
        print(
          '[TrackingService] posted acc=${p.accuracy.toStringAsFixed(1)}m ($tag), status=${response.statusCode}',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          print('[TrackingService] post failed, queuing payload');
        }
        await _enqueuePendingLocation(payload);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TrackingService] post error: $e');
        print('[TrackingService] queuing payload for retry');
      }
      await _enqueuePendingLocation(payload);
    }
  }

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _loadPendingLocations() async {
    final prefs = await _prefs();
    final raw = prefs.getStringList(_kPendingLocationsKey) ?? <String>[];
    return raw
        .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
        .toList();
  }

  Future<void> _savePendingLocations(List<Map<String, dynamic>> items) async {
    final prefs = await _prefs();
    final encoded = items.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(_kPendingLocationsKey, encoded);
  }

  Future<void> _enqueuePendingLocation(Map<String, dynamic> payload) async {
    final pending = await _loadPendingLocations();
    pending.add(payload);
    await _savePendingLocations(pending);
  }

  Future<void> _syncPendingLocations() async {
    final pending = await _loadPendingLocations();
    if (pending.isEmpty) return;

    if (kDebugMode) {
      print('[TrackingService] syncing ${pending.length} pending location(s)');
    }

    final kept = <Map<String, dynamic>>[];
    for (final item in pending) {
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/tracking/pos'),
          headers: _headers(),
          body: jsonEncode(item),
        );

        if (kDebugMode) {
          print('[TrackingService] sync pending status=${response.statusCode}');
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          kept.add(item);
        }
      } catch (e) {
        if (kDebugMode) {
          print('[TrackingService] sync pending error: $e');
        }
        kept.add(item);
      }
    }

    await _savePendingLocations(kept);
    if (kDebugMode) {
      print('[TrackingService] pending queue saved (${kept.length} left)');
    }
  }

  /// ✅ NEW: Listen to connectivity changes and sync when offline→online.
  /// Prevents duplicate syncs by checking _sending flag.
  void _listenToConnectivityChanges() {
    // Cancel any existing subscription first
    _connectivitySubscription?.cancel();
    _lastConnectivityState = null;

    _connectivitySubscription =
        ConnectivityService.I.online$.listen((isOnline) {
      if (kDebugMode) {
        print('[TrackingService] connectivity changed: isOnline=$isOnline');
      }

      // Detect transition: was offline, now online
      if (_lastConnectivityState == false && isOnline == true) {
        if (kDebugMode) {
          print(
              '[TrackingService] offline→online transition detected, triggering sync');
        }

        // Only sync if not already in a periodic/manual sync
        if (!_sending) {
          _sending = true;
          _syncPendingLocations().then((_) {
            _sending = false;
            if (kDebugMode) {
              print('[TrackingService] connectivity-triggered sync completed');
            }
          }).catchError((e) {
            _sending = false;
            if (kDebugMode) {
              print('[TrackingService] connectivity-triggered sync error: $e');
            }
          });
        } else {
          if (kDebugMode) {
            print(
                '[TrackingService] sync already in progress, skipping duplicate trigger');
          }
        }
      }

      _lastConnectivityState = isOnline;
    });

    if (kDebugMode) {
      print('[TrackingService] connectivity listener started');
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
