import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/services/connectivity_service.dart';
import 'package:serv_app/services/tracking_events.dart';
import 'package:serv_app/services/tracking_payload.dart';
import 'package:serv_app/services/tracking_post_result.dart';

/// Foreground-only tracker that guarantees one save every 15 minutes,
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
  StreamSubscription<ServiceStatus>?
      _serviceStatusSub; // GPS OFF/ON detection

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

  /// [initialPosition]: the GPS fix already validated and submitted by the
  /// attendance check-in flow. When provided, the service skips its own
  /// initial capture burst - posting the same fix again would be throttled
  /// by the backend (<15 min) anyway, and re-sampling wastes 2+ minutes of
  /// GPS time per check-in.
  Future<void> startAfterCheckIn({Position? initialPosition}) async {
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

    // The tracking session is created by the caller (attendance page) before
    // this service starts. A second /tracking/check-in here is redundant, and
    // older backends reset pathMap on it - wiping the just-persisted seed.

    // Immediate first capture after check-in - skipped when the caller
    // supplied the check-in position whose persistence it already confirmed.
    if (initialPosition != null) {
      if (kDebugMode) {
        print(
            '[TrackingService] initial capture skipped - check-in seed persistence confirmed '
            '(acc=${initialPosition.accuracy.toStringAsFixed(1)}m)');
      }
    } else if (!_sending) {
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
    // This eliminates duplicate 15-min periodic posts (TrackingService was redundant).
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

    // GPS OFF/ON detection while tracking is active. Clear any stale state
    // from a previous session, then seed non-destructively: whichever
    // isolate seeds first wins, and a transition observed between session
    // start and the seeds is preserved rather than overwritten.
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(kGpsServiceStateKey);
    } catch (_) {}
    await seedGpsServiceState(onlyIfAbsent: true);
    await syncPendingTrackingEvents(empId, jwtToken);
    _listenToGpsServiceStatus();

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
    await syncPendingTrackingEvents(empId, jwtToken);

    // Cancel GPS service-status listener (no events after check-out)
    if (_serviceStatusSub != null) {
      await _serviceStatusSub!.cancel();
      _serviceStatusSub = null;
      if (kDebugMode) {
        print('[TrackingService] GPS service-status listener cancelled');
      }
    }

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
  /// Periodic capture (every 15 minutes) is now handled by Foreground Service.
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
    if (p.isMocked) {
      debugPrint(
          '[TrackingService] mock-location provider reported ($tag) - posting flagged');
    }
    final payload = buildTrackingPointPayloadFromPosition(
      empid: empId,
      position: p,
      source: tag,
      // Capture-instant identity, not producer identity: a fix the
      // foreground service also submitted must dedupe server-side
      // instead of being flagged as a replayed timestamp.
      pointId: trackingPointIdFor(p.timestamp),
      // Pinned session date keeps an overnight shift writing to the same
      // tracking document instead of a new midnight-rollover doc.
      dateIso: await trackingSessionDateIso(),
    );

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/tracking/pos'),
        headers: _headers(),
        body: jsonEncode(payload),
      );
      final result = TrackingPostResult.fromResponse(response);

      if (kDebugMode) {
        print(
          '[TrackingService] posted acc=${p.accuracy.toStringAsFixed(1)}m ($tag), $result',
        );
      }

      if (!result.httpOk) {
        if (kDebugMode) {
          print('[TrackingService] post failed, queuing payload');
        }
        await _enqueuePendingLocation(payload);
      } else if (result.recentPointExists) {
        // Only a backend-confirmed point lets the FG service skip a
        // would-be-throttled capture (<15 min since last stored position).
        final prefs = await _prefs();
        await prefs.setInt(
            kLastPersistedPosMsKey, DateTime.now().millisecondsSinceEpoch);
        if (result.persisted) trackingPointPersisted.value++;
      } else if (kDebugMode) {
        print('[TrackingService] point skip reason=${result.status}');
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
    // Corrupted entries are dropped silently here; the FG-service copy of
    // this loader logs them. `mocked` and other metadata ride inside the
    // JSON map untouched.
    return raw
        .map((entry) => decodePendingLocation(entry))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _savePendingLocations(List<Map<String, dynamic>> items) async {
    final prefs = await _prefs();
    final encoded = items.map(encodePendingLocation).toList();
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

    // Do not upload after logout. A live 'token' entry is the canonical
    // signed-in signal; logout() removes it. This also covers a
    // TrackingService instance whose stopAfterCheckOut() was never called
    // (e.g. logout while still checked in).
    final prefs = await _prefs();
    if ((prefs.getString('token') ?? '').isEmpty) {
      if (kDebugMode) {
        print('[TrackingService] no active session - pending sync skipped');
      }
      return;
    }

    if (kDebugMode) {
      print('[TrackingService] syncing ${pending.length} pending location(s)');
    }

    final kept = <Map<String, dynamic>>[];
    for (final item in pending) {
      // Only upload records owned by this employee; other accounts' records
      // stay queued for their own session.
      if (item['empid']?.toString() != empId) {
        kept.add(item);
        continue;
      }
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
          _syncPendingLocations()
              .then((_) => syncPendingTrackingEvents(empId, jwtToken))
              .then((_) {
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

  /// Watches Android location-service state while tracking is active and
  /// emits location_disabled / location_enabled events on transitions.
  /// Transitions are deduped against the shared prefs store, so a state
  /// already recorded by the FG-service isolate is never re-reported.
  void _listenToGpsServiceStatus() {
    // getServiceStatusStream is unsupported on web (throws
    // UnsupportedError). Web has no device-level GPS toggle - permission
    // state covers it.
    if (kIsWeb) return;
    _serviceStatusSub?.cancel();
    _serviceStatusSub =
        Geolocator.getServiceStatusStream().listen((status) {
      final enabled = status == ServiceStatus.enabled;
      if (kDebugMode) {
        print('[TrackingService] GPS service status changed: enabled=$enabled');
      }
      recordGpsServiceTransition(
        enabled: enabled,
        empid: empId,
        token: jwtToken,
      );
    }, onError: (Object e) {
      if (kDebugMode) {
        print('[TrackingService] service-status stream error: $e');
      }
    });
    if (kDebugMode) {
      print('[TrackingService] GPS service-status listener started');
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
