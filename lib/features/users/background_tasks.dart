import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/services/tracking_events.dart';
import 'package:serv_app/services/tracking_payload.dart';
import 'package:serv_app/services/tracking_post_result.dart';

const _kChannelId = 'serv_tracking';
const _kChannelName = 'SERV Tracking';
const _kChannelDesc = 'Foreground location tracking';
const _kNotifId = 1212;

// General/updates channel (task notifications, etc.) - used by FCM handling.
const kUpdatesChannelId = 'serv_updates';
const _kUpdatesChannelName = 'SERV Updates';
const _kUpdatesChannelDesc = 'Task and general notifications';

bool get _isAndroid => !kIsWeb && Platform.isAndroid;

// Workmanager names & keys
const _wmUniqueTask = 'serv_location_periodic';
const _wmSimpleTask = 'serv_location_oneoff';
const _kEmpKey = 'empid';
const _kTokKey = 'token';

// Persist keys
const _spEmp = 'bg_empid';
const _spTok = 'bg_token';
// Tracking-document date pinned at session start (kTrackingSessionDateKey
// lives in tracking_post_result.dart, shared with the other producers).
// Epoch ms of the most recent /tracking/pos post the backend CONFIRMED is in
// pathMap. Ticks skip a fresh GPS capture when it is younger than the
// backend's 15-min throttle window - capturing would only be rejected.
const _spLastPosMs = kLastPersistedPosMsKey;
// Epoch ms of the last VALID device fix (accuracy-filtered capture),
// independent of whether the backend stored it. Sent in heartbeats.
const _spLastFixMs = kLastGpsFixMsKey;
const _kPendingLocationsKey = 'tracking_pending_locations';

// Persisted tracking-startup state (owned by the attendance page). Bound to
// the employee id + session date so one employee's recovery state can never
// be reused after another employee logs in on the same device.
const kTrackingStateKey = 'tracking_state';
const kTrackingStateEmpKey = 'tracking_state_empid';
const kTrackingStateDateKey = 'tracking_state_date';

/// True while the foreground tracking service is actually running. A
/// persisted flag alone does not prove the Android service is alive.
Future<bool> isForegroundTrackingRunning() async {
  if (!_isAndroid) return true;
  try {
    return await FlutterBackgroundService().isRunning();
  } catch (_) {
    return false;
  }
}

// In-memory identity
String? _empid, _token;

const Duration _kForegroundServiceInterval = Duration(minutes: 15);
Timer? _foregroundServiceTimer;
bool _foregroundServiceTickRunning = false;
StreamSubscription<ServiceStatus>? _serviceStatusSub;

// Single notifications plugin (this class is a singleton internally, so any
// other module that does `FlutterLocalNotificationsPlugin()` gets this same
// instance — see [sharedLocalNotificationsPlugin] below for safe reuse).
final _flnp = FlutterLocalNotificationsPlugin();

// Guards against calling plugin.initialize() more than once, since the
// plugin instance is process-wide: a second call would silently overwrite
// the notification-tap callback registered by the first call.
bool _flnpInitialized = false;

// Other modules (e.g. FCM foreground/tap handling) can register a callback
// here *before* the first _ensureNotifChannel() run to receive local
// notification taps without fighting over plugin.initialize().
void Function(NotificationResponse)? notificationTapHandler;

/// Exposes the shared (singleton) plugin instance for other modules that
/// need to `.show()` notifications on channels created here.
FlutterLocalNotificationsPlugin get sharedLocalNotificationsPlugin => _flnp;

/// Public wrapper so other modules can make sure the plugin + channels are
/// ready before calling `.show()`, without duplicating initialization logic.
Future<void> ensureNotificationChannelsReady() => _ensureNotifChannel();

/// Create the Android notification channel & ask notification permission (13+)
Future<void> _ensureNotifChannel() async {
  if (!_isAndroid) return;

  if (!_flnpInitialized) {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _flnp.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (details) =>
          notificationTapHandler?.call(details),
    );
    _flnpInitialized = true;
  }

  final android = _flnp.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  // Android 13+ runtime permission
  final enabled = await android?.areNotificationsEnabled();
  if (enabled == false) {
    await android?.requestNotificationsPermission();
  }

  // Create (idempotent) low-importance channel for foreground notification
  await android?.createNotificationChannel(const AndroidNotificationChannel(
    _kChannelId,
    _kChannelName,
    description: _kChannelDesc,
    importance: Importance.low,
  ));

  // Create (idempotent) high-importance channel for task/general updates
  await android?.createNotificationChannel(const AndroidNotificationChannel(
    kUpdatesChannelId,
    _kUpdatesChannelName,
    description: _kUpdatesChannelDesc,
    importance: Importance.high,
  ));
}

// ────────────────────────────────────────────────────────────────────────────
// Public API
// ────────────────────────────────────────────────────────────────────────────

Future<void> initializeBackgroundSystems() async {
  if (!_isAndroid) return;

  await _ensureNotifChannel();

  // Configure foreground service (does NOT auto-start on app launch)
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: false,
      // Reboot recovery: the plugin's BootReceiver may restart the service
      // after BOOT_COMPLETED. _onStart immediately stops itself when the
      // persisted tracking identity was cleared (checkout/logout), so a
      // reboot can never resurrect a dead session. Android 12+ may refuse
      // background FGS starts - the plugin handles that internally; this
      // is best-effort recovery, never a guarantee.
      autoStartOnBoot: true,
      isForegroundMode: true,
      notificationChannelId: _kChannelId,
      initialNotificationTitle: 'SERV App',
      initialNotificationContent: 'Preparing location tracking…',
      foregroundServiceNotificationId: _kNotifId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    // not const on some versions; harmless on Android
    iosConfiguration: IosConfiguration(),
  );
}

Future<void> setTrackingIdentity({
  required String empid,
  required String token,
  // True only from a fresh attendance check-in: the session date is
  // re-pinned to today. Recovery paths (app restart, connectivity return)
  // must NOT re-pin - an overnight shift would otherwise start writing to
  // a new document that has no attendance record behind it.
  bool newSession = false,
}) async {
  _empid = empid;
  _token = token;
  final sp = await SharedPreferences.getInstance();
  await sp.setString(_spEmp, empid);
  await sp.setString(_spTok, token);
  final existing = sp.getString(kTrackingSessionDateKey);
  if (newSession || existing == null || existing.isEmpty) {
    await sp.setString(kTrackingSessionDateKey, trackingDateIso());
  }
}

/// SAFE start: only starts if Android 13+ notification permission is granted.
Future<void> startForegroundTracking() async {
  if (!_isAndroid) return;

  // Make sure channel + (13+) permission exist before we show a foreground notif
  await _ensureNotifChannel();

  final androidImpl = _flnp.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  // 1) Are notifications enabled?
  bool? granted =
      await (androidImpl?.areNotificationsEnabled() ?? Future.value(true));

  // 2) If not, try requesting once.
  if (!granted!) {
    granted = await (androidImpl?.requestNotificationsPermission() ??
        Future.value(false));
  }

  // 3) If still not granted, DO NOT start the service (it would crash).
  if (!granted!) {
    debugPrint(
        '[FG] Notifications permission not granted – skip startForeground to avoid crash.');
    return;
  }

  // OK to start
  final service = FlutterBackgroundService();
  if (!await service.isRunning()) {
    await service.startService();
  } else {
    service.invoke('setAsForeground');
  }
}

Future<void> stopForegroundTracking() async {
  if (!_isAndroid) return;
  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    service.invoke('stopService');
  }
}

// ────────────────────────────────────────────────────────────────────────────
// GPS Accuracy Improvement
// ────────────────────────────────────────────────────────────────────────────
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

    debugPrint(
        '[BG] starting GPS sampling: max=$maxSamples, target=$targetAccuracyMeters m, max=$maxAccuracyMeters m');

    // Try quick single-shots first
    for (int i = 0; i < maxSamples; i++) {
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds > totalTimeout.inMilliseconds) {
        debugPrint('[BG] sampling timeout reached after $sampleCount samples');
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
          debugPrint(
              '[BG] sample $sampleCount: acc=${pos.accuracy.toStringAsFixed(1)}m (best so far)');
        }

        // Early exit if accuracy is excellent
        if (pos.accuracy <= targetAccuracyMeters) {
          debugPrint(
              '[BG] target accuracy reached after $sampleCount samples, stopping');
          break;
        }
      } catch (e) {
        debugPrint('[BG] sample $sampleCount failed: $e');
        // Continue to next sample on error
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Validate final position
    if (bestPosition == null) {
      debugPrint('[BG] no valid GPS position obtained');
      return null;
    }

    if (bestPosition.accuracy > maxAccuracyMeters) {
      debugPrint(
          '[BG] SKIPPED: accuracy=${bestPosition.accuracy.toStringAsFixed(1)}m exceeds max=${maxAccuracyMeters}m after $sampleCount samples');
      return null;
    }

    debugPrint(
        '[BG] selected best position: acc=${bestPosition.accuracy.toStringAsFixed(1)}m');
    return bestPosition;
  } catch (e) {
    debugPrint('[BG] GPS sampling error: $e');
    return null;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Workmanager (fallback / legacy periodic scheduling)
// ────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    // ✅ Ensure plugins (e.g., shared_preferences, geolocator) are registered
    DartPluginRegistrant.ensureInitialized();

    // inputData is a registration-time snapshot; the live persisted
    // identity below is authoritative (see the logout guard).
    debugPrint('[Workmanager] Task=$task');

    // inputData is a registration-time snapshot. Re-check the persisted
    // identity: logout clears bg_empid / bg_token and cancels this task,
    // but a task already dispatched must not sync with a stale token.
    var loggedOut = false;
    try {
      final sp = await SharedPreferences.getInstance();
      final liveEmp = sp.getString(_spEmp);
      final liveTok = sp.getString(_spTok);
      loggedOut = (liveEmp ?? '').isEmpty || (liveTok ?? '').isEmpty;
    } catch (_) {}
    if (loggedOut) {
      debugPrint('[Workmanager] tracking identity cleared - skipping task');
      return Future.value(true);
    }

    try {
      // OS-scheduled fallback cycle.
      //
      // The foreground service owns the 15-min cadence, but it is not
      // immortal: an OEM task killer, memory pressure or a process freeze
      // can stop it, and the device then goes completely silent until the
      // employee next opens the app. WorkManager survives process death
      // and reboots, so it runs the SAME cycle as a safety net.
      //
      // Double posting is not a concern: the cycle skips capture when a
      // point was accepted <14 min ago, and a fix captured by both
      // schedulers carries one capture-instant pointId, so the backend
      // stores it once.
      final ended = await runTrackingCycle(origin: 'wm');

      // Backend says the session is closed: this isolate has no service
      // to stop, so do the equivalent teardown - cancel this task and
      // clear the persisted identity so no future WM run or FG restart
      // keeps posting against a dead session.
      if (ended) {
        debugPrint('[Workmanager] session ended on server - tearing down');
        try {
          await Workmanager().cancelByUniqueName(_wmUniqueTask);
        } catch (_) {}
        await clearTrackingSessionIdentity();
        return true;
      }

      // Self-healing: if the foreground service is gone while a session
      // is still active, bring it back. newSession:false preserves the
      // pinned session date so an overnight shift keeps one document.
      try {
        if (!await isForegroundTrackingRunning()) {
          final sp = await SharedPreferences.getInstance();
          final liveEmp = sp.getString(_spEmp) ?? '';
          final liveTok = sp.getString(_spTok) ?? '';
          if (liveEmp.isNotEmpty && liveTok.isNotEmpty) {
            debugPrint('[Workmanager] FG service not running - restarting');
            // newSession:false - the pinned session date must survive so
            // an overnight shift keeps writing to its original document.
            await setTrackingIdentity(
                empid: liveEmp, token: liveTok, newSession: false);
            await startForegroundTracking();
          }
        }
      } catch (e) {
        debugPrint('[Workmanager] FG service restart check failed: $e');
      }
    } catch (e) {
      debugPrint('[Workmanager] task error: $e');
    }
    return Future.value(true);
  });
}

Future<void> scheduleBackgroundTracking({
  required String empid,
  required String token,
}) async {
  if (!_isAndroid) return;

  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  } catch (_) {}

  await Workmanager().cancelByUniqueName(_wmUniqueTask);

  await Workmanager().registerPeriodicTask(
    _wmUniqueTask,
    _wmSimpleTask,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 1),
    inputData: {_kEmpKey: empid, _kTokKey: token},
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresCharging: false,
      requiresBatteryNotLow: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );
  debugPrint('[Workmanager] scheduled');
}

Future<void> cancelBackgroundTracking({required String empid}) async {
  if (!_isAndroid) return;
  await Workmanager().cancelByUniqueName(_wmUniqueTask);
  debugPrint('[Workmanager] cancelled');
}

/// One-shot tracking cleanup used at logout.
///
/// Stops the foreground service, cancels the tracking Workmanager task,
/// performs a best-effort final sync of this employee's pending queue while
/// the session is still open, then clears the persisted background
/// credentials (bg_empid / bg_token) so no isolate can capture or submit
/// locations after logout.
///
/// Idempotent: every step is safe to repeat or to run while tracking is
/// inactive. Never throws.
Future<void> stopTrackingForLogout({
  required String empid,
  required String token,
}) async {
  if (_isAndroid) {
    try {
      await stopForegroundTracking();
    } catch (e) {
      debugPrint('[Logout] stopForegroundTracking error: $e');
    }
    try {
      await cancelBackgroundTracking(empid: empid);
    } catch (e) {
      debugPrint('[Logout] cancelBackgroundTracking error: $e');
    }

    // Best-effort final sync while the tracking session is still open and
    // the session token is valid. Records that fail to upload stay queued
    // for this employee's next session - they are never deleted here.
    if (empid.isNotEmpty && token.isNotEmpty) {
      try {
        await _syncPendingLocations(empid, token);
      } catch (e) {
        debugPrint('[Logout] final pending sync error: $e');
      }
    }
  }

  // Clear persisted background credentials. The service isolate re-reads
  // these on every tick, so clearing them makes any surviving isolate stop
  // capturing and submitting.
  await clearTrackingSessionIdentity();
}

/// Clears tracking-specific persisted identity and session state only:
/// bg_empid / bg_token, the last-persisted-point marker, the GPS service
/// dedup state and the attendance page's recovery keys. The login session
/// ('token', 'empid', user profile) and the pending upload queues are left
/// untouched - safe to call on check-out while the employee stays signed in.
Future<void> clearTrackingSessionIdentity() async {
  try {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_spEmp);
    await sp.remove(_spTok);
    await sp.remove(_spLastPosMs);
    await sp.remove(_spLastFixMs);
    await sp.remove(kGpsServiceStateKey);
    await sp.remove(kTrackingStateKey);
    await sp.remove(kTrackingStateEmpKey);
    await sp.remove(kTrackingStateDateKey);
    await sp.remove(kTrackingSessionDateKey);
    await sp.remove(kPermissionRevokedKey);
  } catch (_) {}
  _empid = null;
  _token = null;
}

/// Backend confirmed the tracking session is closed. Stop everything this
/// isolate owns: timer, GPS-status listener, Workmanager fallback, the
/// persisted tracking identity, then the service itself. Any surviving or
/// restarted isolate finds empty credentials and self-disables on its
/// first tick.
Future<void> _handleSessionEnded(ServiceInstance service) async {
  debugPrint('[BG] tracking session ended on server - stopping service');
  try {
    await _serviceStatusSub?.cancel();
  } catch (_) {}
  _serviceStatusSub = null;
  _foregroundServiceTimer?.cancel();
  _foregroundServiceTimer = null;
  try {
    await Workmanager().cancelByUniqueName(_wmUniqueTask);
  } catch (_) {}
  await clearTrackingSessionIdentity();
  try {
    service.stopSelf();
  } catch (_) {}
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

Future<List<Map<String, dynamic>>> _loadPendingLocations() async {
  final prefs = await _prefs();
  final raw = prefs.getStringList(_kPendingLocationsKey) ?? <String>[];
  final items = <Map<String, dynamic>>[];

  for (final entry in raw) {
    final parsed = decodePendingLocation(entry);
    if (parsed == null) {
      if (kDebugMode) {
        debugPrint('[BG] skipped corrupted pending location entry');
      }
      continue;
    }
    final lat = parsed['lat'];
    final lng = parsed['lng'];
    if (lat is num && lng is num) {
      items.add(parsed);
    } else {
      if (kDebugMode) {
        debugPrint('[BG] skipped pending entry without valid lat/lng');
      }
    }
  }

  return items;
}

Future<void> _savePendingLocations(List<Map<String, dynamic>> items) async {
  final prefs = await _prefs();
  final trimmed =
      items.length <= 200 ? items : items.sublist(items.length - 200);
  final encoded = trimmed.map((item) => jsonEncode(item)).toList();
  await prefs.setStringList(_kPendingLocationsKey, encoded);
}

Future<void> _enqueuePendingLocation(Map<String, dynamic> payload) async {
  final lat = payload['lat'];
  final lng = payload['lng'];
  if (lat == null || lng == null || lat is! num || lng is! num) {
    if (kDebugMode) {
      debugPrint('[BG] skipped queueing payload without lat/lng');
    }
    return;
  }

  final pending = await _loadPendingLocations();
  final newSig = trackingPayloadSignature(payload);
  final duplicate =
      pending.any((item) => trackingPayloadSignature(item) == newSig);
  if (duplicate) {
    if (kDebugMode) {
      debugPrint('[BG] duplicate pending location skipped');
    }
    return;
  }

  pending.add(payload);
  await _savePendingLocations(pending);
}

Future<void> _syncPendingLocations(String empid, String token) async {
  final pending = await _loadPendingLocations();
  if (pending.isEmpty) return;

  if (kDebugMode) {
    debugPrint('[BG] syncing ${pending.length} pending location(s)');
  }

  final kept = <Map<String, dynamic>>[];
  for (final item in pending) {
    // Only upload records owned by this employee. Records queued under a
    // previous login stay queued - they are never posted under another
    // employee's identity.
    if (item['empid']?.toString() != empid) {
      kept.add(item);
      continue;
    }
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/tracking/pos');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'x-empid': empid,
            },
            body: jsonEncode(item),
          )
          .timeout(const Duration(seconds: 10));

      final result = TrackingPostResult.fromResponse(response);
      if (kDebugMode) {
        debugPrint('[BG] sync pending $result');
      }
      if (!result.httpOk) {
        kept.add(item);
      } else if (result.recentPointExists) {
        try {
          final sp = await _prefs();
          await sp.setInt(
              _spLastPosMs, DateTime.now().millisecondsSinceEpoch);
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BG] sync pending error: $e');
      }
      kept.add(item);
    }
  }

  await _savePendingLocations(kept);
  if (kDebugMode) {
    if (kept.isEmpty) {
      debugPrint('[BG] pending offline locations synced successfully');
    } else {
      debugPrint(
          '[BG] pending offline locations sync completed with ${kept.length} remaining');
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Foreground-service entrypoint isolate
// ────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  // ✅ Ensure plugins are available in this background isolate
  WidgetsFlutterBinding.ensureInitialized();

  // Rehydrate identity from prefs
  final sp = await SharedPreferences.getInstance();
  _empid ??= sp.getString(_spEmp);
  _token ??= sp.getString(_spTok);

  // Boot/sticky restart after check-out or logout: the tracking identity
  // was cleared, so there is no active authorized session. Stop the
  // service rather than running a foreground notification with nothing
  // to do (autoStartOnBoot must never resurrect dead tracking).
  if ((_empid ?? '').isEmpty || (_token ?? '').isEmpty) {
    debugPrint('[BG] service started without tracking identity - stopping');
    try {
      service.stopSelf();
    } catch (_) {}
    return;
  }

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    await service.setForegroundNotificationInfo(
      title: 'SERV App',
      content: 'Location tracking active',
    );
  }

  service.on('setAsForeground').listen((_) async {
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
      await service.setForegroundNotificationInfo(
        title: 'SERV App',
        content: 'Location tracking active',
      );
    }
  });

  service.on('stopService').listen((_) async {
    if (_serviceStatusSub != null) {
      _serviceStatusSub!.cancel();
      _serviceStatusSub = null;
      debugPrint('[BG] GPS service-status listener stopped');
    }
    if (_foregroundServiceTimer != null) {
      _foregroundServiceTimer!.cancel();
      _foregroundServiceTimer = null;
      debugPrint('[BG] foreground service timer stopped');
    }
    debugPrint('[BG] foreground service stopped');
    service.stopSelf();
  });

  debugPrint('[BG] foreground service started');

  // GPS OFF/ON detection inside the service isolate: transitions are
  // recorded against the shared prefs dedup store and emitted via
  // /tracking/event (queued when offline). Seeded lazily so the first
  // observation never emits a spurious event.
  await seedGpsServiceState(onlyIfAbsent: true);
  _serviceStatusSub?.cancel();
  _serviceStatusSub =
      Geolocator.getServiceStatusStream().listen((status) async {
    try {
      final p = await SharedPreferences.getInstance();
      final empid = p.getString(_spEmp);
      final token = p.getString(_spTok);
      if ((empid ?? '').isEmpty || (token ?? '').isEmpty) return;
      await recordGpsServiceTransition(
        enabled: status == ServiceStatus.enabled,
        empid: empid!,
        token: token!,
      );
    } catch (e) {
      debugPrint('[BG] service-status transition error: $e');
    }
  }, onError: (Object e) {
    debugPrint('[BG] service-status stream error: $e');
  });

  Future<void> tick({DateTime? scheduledAt}) async {
    final ended = await runTrackingCycle(origin: 'fg', scheduledAt: scheduledAt);
    if (ended) {
      await _handleSessionEnded(service);
      return;
    }
    if (service is AndroidServiceInstance) {
      try {
        await service.setForegroundNotificationInfo(
          title: 'SERV',
          content: 'Location tracking active',
        );
      } catch (_) {}
    }
  }

  // First capture is immediate on service start (unscheduled).
  await tick();

  if (_foregroundServiceTimer == null || !_foregroundServiceTimer!.isActive) {
    // Anchor the expected-fire timeline at timer creation: periodic tick n
    // is DUE at anchor + n*interval, so diag can report the real delay
    // between the scheduled instant and when the OS actually ran it.
    final timerAnchor = DateTime.now();
    var periodicTickCount = 0;
    _foregroundServiceTimer = Timer.periodic(
      _kForegroundServiceInterval,
      (_) {
        periodicTickCount++;
        final scheduled =
            timerAnchor.add(_kForegroundServiceInterval * periodicTickCount);
        tick(scheduledAt: scheduled).catchError((e) {
          debugPrint('[BG] foreground timer tick error: $e');
        });
      },
    );
    debugPrint(
      '[BG] foreground timer scheduled every ${_kForegroundServiceInterval.inMinutes} minutes',
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tracking cycle – shared by the foreground service timer and the
// WorkManager fallback
// ────────────────────────────────────────────────────────────────────────────

/// One complete tracking cycle: queue sync, GPS state reporting, capture
/// and upload. Returns true when the BACKEND reports the session ended -
/// the caller must then tear tracking down.
///
/// Runs identically from the foreground-service timer ([origin] 'fg') and
/// from the WorkManager periodic task ([origin] 'wm'). The guard below is
/// per-isolate, so the two schedulers can still overlap; that is safe and
/// deliberate - a fix captured twice carries ONE capture-instant pointId,
/// so the backend stores it once and treats the second delivery as an
/// idempotent duplicate rather than a replayed timestamp.
///
/// Never throws.
Future<bool> runTrackingCycle({required String origin, DateTime? scheduledAt}) async {
  if (_foregroundServiceTickRunning) {
    debugPrint('[BG] tick already running ($origin); skipping');
    return false;
  }
  _foregroundServiceTickRunning = true;

  // Capture-attempt diagnostics: one record per cycle, whatever the
  // outcome. Written to a bounded local ring buffer AND carried to the
  // backend (diag on /pos and /heartbeat) so the 15-minute cadence is
  // provable end-to-end - including attempts that never produced a point.
  // For the WM path the OS does not disclose the due time, so callers pass
  // no scheduledAt and "scheduled" collapses to dispatch time.
  scheduledAt ??= DateTime.now();
  final diag = <String, dynamic>{
    'captureId':
        'cap-$origin-${scheduledAt.toUtc().millisecondsSinceEpoch}',
    'origin': origin,
    'scheduledCaptureAt': scheduledAt.toUtc().toIso8601String(),
  };
  Future<bool> finish(String result, {String? reason, bool ended = false}) {
    diag['captureResult'] = result;
    if (reason != null) diag['failureReason'] = reason;
    return _recordCaptureDiag(diag).then((_) => ended);
  }

  try {
    // Re-read persisted identity on every tick. Logout clears bg_empid /
    // bg_token, which makes any surviving isolate stop capturing and
    // submitting, and a new login is picked up automatically.
    final prefs = await SharedPreferences.getInstance();
    _empid = prefs.getString(_spEmp);
    _token = prefs.getString(_spTok);
    if ((_empid ?? '').isEmpty || (_token ?? '').isEmpty) {
      debugPrint('[BG] tracking identity cleared - skipping tick ($origin)');
      return await finish('aborted', reason: 'identity_missing');
    }

    await _syncPendingLocations(_empid!, _token!);
    await syncPendingTrackingEvents(_empid!, _token!);

    // Record GPS OFF/ON transitions before any early-return so even
    // capture-skipping ticks keep the state machine current.
    final gpsEnabledNow = await Geolocator.isLocationServiceEnabled();
    await recordGpsServiceTransition(
      enabled: gpsEnabledNow,
      empid: _empid!,
      token: _token!,
    );

    // Skip the GPS burst if a position was accepted very recently (e.g.
    // the attendance check-in seed seconds before this service started).
    // The backend throttles posts closer than 15 min, so a capture now
    // would only produce a rejected record and burn battery.
    final lastPosMs = prefs.getInt(_spLastPosMs) ?? 0;
    if (lastPosMs > 0 &&
        DateTime.now().millisecondsSinceEpoch - lastPosMs <
            const Duration(minutes: 14).inMilliseconds) {
      debugPrint('[BG] accepted position <14min old - skipping fresh capture');
      // Still beat: a skipped capture must not read as silence.
      final ended = await _sendHeartbeat(
          _empid!, _token!, TrackingGpsState.ok, diag: diag);
      return await finish('skipped_recent', reason: 'accepted_<14min',
          ended: ended);
    }

    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      debugPrint('[BG] permission denied');
      // Confirmed permission loss is a reportable event (deduped once
      // per revocation) - distinct from GPS-off, which is a service
      // toggle the device reports via the status stream.
      await recordPermissionRevoked(empid: _empid!, token: _token!);
      // The heartbeat continuously re-confirms perm_denied so the
      // server shows a live 'permission_revoked' status rather than
      // a cause-less gap.
      diag['actualCaptureStartedAt'] = DateTime.now().toUtc().toIso8601String();
      final ended = await _sendHeartbeat(
          _empid!, _token!, TrackingGpsState.permDenied, diag: diag);
      return await finish('perm_denied', reason: '$perm', ended: ended);
    }
    // Permission healthy: re-arm the dedup so a future revocation is
    // reported as a new event.
    await clearPermissionRevokedReported();
    if (!gpsEnabledNow) {
      debugPrint('[BG] GPS disabled');
      // Confirmed GPS-off (location service toggle). The transition
      // event above already notified once; the heartbeat keeps the
      // server status current for the gap's whole duration.
      diag['actualCaptureStartedAt'] = DateTime.now().toUtc().toIso8601String();
      final ended = await _sendHeartbeat(
          _empid!, _token!, TrackingGpsState.serviceOff, diag: diag);
      return await finish('service_off', reason: 'gps_disabled', ended: ended);
    }

    // ✅ IMPROVED: Use multi-sample GPS with accuracy validation
    diag['actualCaptureStartedAt'] = DateTime.now().toUtc().toIso8601String();
    final p = await _captureBestPositionWithSampling(
      maxSamples: 5,
      targetAccuracyMeters: 10.0,
      maxAccuracyMeters: 50.0,
      sampleTimeout: const Duration(seconds: 15),
      totalTimeout: const Duration(seconds: 120),
    );

    if (p == null) {
      debugPrint('[BG] location rejected due to poor accuracy in tick()');
      // Service alive, GPS produced no usable fix - the server sees
      // contact but a missing fix, i.e. gps_delayed after grace.
      final ended = await _sendHeartbeat(
          _empid!, _token!, TrackingGpsState.noFix, diag: diag);
      return await finish('no_fix', reason: 'accuracy_or_timeout', ended: ended);
    }

    debugPrint('[BG] location captured acc=${p.accuracy.toStringAsFixed(1)}m');
    diag['gpsFixCapturedAt'] = p.timestamp.toUtc().toIso8601String();

    // Persist the fix time BEFORE posting: a skipped (throttled/too-close)
    // point is still a valid fix whose freshness heartbeats can report.
    try {
      await (await _prefs())
          .setInt(_spLastFixMs, p.timestamp.millisecondsSinceEpoch);
    } catch (_) {}

    // Re-verify identity immediately before submitting: GPS sampling can
    // take up to ~2 minutes, and logout may have cleared the credentials
    // while the capture was in flight.
    final recheck = await SharedPreferences.getInstance();
    _empid = recheck.getString(_spEmp);
    _token = recheck.getString(_spTok);
    if ((_empid ?? '').isEmpty || (_token ?? '').isEmpty) {
      debugPrint(
          '[BG] tracking identity cleared during capture - dropping location');
      return await finish('aborted', reason: 'identity_cleared_during_capture');
    }

    diag['apiRequestStartedAt'] = DateTime.now().toUtc().toIso8601String();
    final postResult = await _pingServer(
      _empid!,
      _token!,
      lat: p.latitude,
      lng: p.longitude,
      accuracy: p.accuracy,
      mocked: p.isMocked,
      capturedAt: p.timestamp,
      diag: diag,
    );

    // Backend says this session is closed (check-out, logout, or the
    // server-side close when attendance ended). The caller tears down so
    // no further captures or uploads run from a dead session.
    if (postResult.sessionEnded) {
      return await finish('session_ended', reason: 'backend_closed', ended: true);
    }

    if (postResult.persisted) {
      debugPrint('[BG] location post success ($origin) - point persisted');
    }
    return await finish(postResult.status,
        reason: postResult.httpOk ? null : 'http_${postResult.httpStatus}');
  } catch (e) {
    debugPrint('[BG] tick error ($origin): $e');
    return finish('error', reason: '$e');
  } finally {
    _foregroundServiceTickRunning = false;
  }
}

/// Append a capture-attempt record to the bounded local ring buffer and
/// logcat it. `bg_capture_log` keeps the last 60 attempts - the device-side
/// evidence for the 15-minute cadence audit when Firestore only stores
/// accepted points.
const String _spCaptureLog = 'bg_capture_log';
const int _kCaptureLogMax = 60;

Future<void> _recordCaptureDiag(Map<String, dynamic> diag) async {
  diag['recordedAt'] = DateTime.now().toUtc().toIso8601String();
  debugPrint('[BG] capture diag: ${jsonEncode(diag)}');
  try {
    final sp = await _prefs();
    final raw = sp.getStringList(_spCaptureLog) ?? <String>[];
    raw.add(jsonEncode(diag));
    while (raw.length > _kCaptureLogMax) {
      raw.removeAt(0);
    }
    await sp.setStringList(_spCaptureLog, raw);
  } catch (_) {}
}

// ────────────────────────────────────────────────────────────────────────────
// API ping – uses your existing /api/tracking/pos endpoint
// ────────────────────────────────────────────────────────────────────────────

/// Posts a lightweight liveness + GPS-state ping to /tracking/heartbeat.
/// Called on EVERY tick path that produces no /pos contact - without it a
/// live service with dead GPS is indistinguishable from a killed app.
/// Returns true when the backend reports the session ended (the caller
/// must then tear down local tracking). Best-effort: a failed heartbeat
/// is dropped, never queued - the contact gap itself is the signal the
/// server monitors, and the next tick retries anyway.
Future<bool> _sendHeartbeat(
  String empid,
  String token,
  String gpsState, {
  Map<String, dynamic>? diag,
}) async {
  try {
    final sp = await _prefs();
    final fixMs = sp.getInt(_spLastFixMs) ?? 0;
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/tracking/heartbeat'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-empid': empid,
          },
          body: jsonEncode(buildTrackingHeartbeatPayload(
            empid: empid,
            gpsState: gpsState,
            dateIso: await trackingSessionDateIso(),
            gpsFixAt: fixMs > 0
                ? DateTime.fromMillisecondsSinceEpoch(fixMs)
                : null,
            diag: diag,
          )),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      return body is Map && body['status'] == 'session_ended';
    }
    // 404 = pre-upgrade backend (deployment skew). Heartbeats are
    // optional; the /pos contact path keeps liveness there.
    if (kDebugMode) {
      debugPrint('[BG] heartbeat status=${res.statusCode}');
    }
  } catch (e) {
    debugPrint('[BG] heartbeat error: $e');
  }
  return false;
}

Future<TrackingPostResult> _pingServer(
  String empid,
  String token, {
  double? lat,
  double? lng,
  double? accuracy,
  bool? mocked,
  DateTime? capturedAt,
  Map<String, dynamic>? diag,
}) async {
  // If lat/lng not provided, try to get a good fix with accuracy validation
  double? lat0 = lat, lng0 = lng;
  double? acc0 = accuracy;
  bool mocked0 = mocked ?? false;
  DateTime? capturedAt0 = capturedAt;

  try {
    if (lat0 == null || lng0 == null) {
      final p = await _captureBestPositionWithSampling(
        maxSamples: 5,
        targetAccuracyMeters: 10.0,
        maxAccuracyMeters: 50.0,
        sampleTimeout: const Duration(seconds: 15),
        totalTimeout: const Duration(seconds: 120),
      );

      if (p == null) {
        debugPrint(
            '[BG] SKIPPED: location rejected due to poor accuracy in _pingServer');
        return const TrackingPostResult(0, 'no_fix', null);
      }

      lat0 = p.latitude;
      lng0 = p.longitude;
      acc0 = p.accuracy;
      mocked0 = p.isMocked;
      capturedAt0 = p.timestamp;
      if (p.isMocked) {
        debugPrint(
            '[BG] mock-location provider reported - point will be sent flagged');
      }
      debugPrint(
          '[BG] captured location for _pingServer: acc=${acc0.toStringAsFixed(1)}m');
    }
  } catch (e) {
    debugPrint('[BG] GPS capture error in _pingServer: $e');
    // If we already have lat/lng passed in, we can still try to post with that
    if (lat0 == null || lng0 == null) {
      return const TrackingPostResult(0, 'capture_error', null);
    }
  }

  final uri = Uri.parse('${ApiService.baseUrl}/tracking/pos');

  final payload = buildTrackingPointPayload(
    empid: empid,
    lat: lat0,
    lng: lng0,
    accuracy: acc0,
    mocked: mocked0,
    source: 'fg/worker',
    // Capture-instant identity, not producer identity: the same fix
    // delivered by another producer must dedupe, not look like a replay.
    pointId: trackingPointIdFor(capturedAt0 ?? DateTime.now()),
    diag: diag,
    capturedAt: capturedAt0,
    // Pinned session date keeps an overnight shift writing to the same
    // tracking document instead of a new midnight-rollover doc.
    dateIso: await trackingSessionDateIso(),
  );

  try {
    debugPrint('[BG] DEBUG VERSION 2 - before tracking API call');

    final response = await http
        .post(uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'x-empid': empid,
            },
            body: jsonEncode(payload))
        .timeout(const Duration(seconds: 10));

    final result = TrackingPostResult.fromResponse(response);
    debugPrint('[BG] tracking pos $result');
    if (result.httpOk) {
      // HTTP 200 is not proof of storage - only a backend-confirmed point
      // may suppress the next capture.
      if (result.recentPointExists) {
        try {
          final sp = await _prefs();
          await sp.setInt(
              _spLastPosMs, DateTime.now().millisecondsSinceEpoch);
        } catch (_) {}
      } else {
        debugPrint('[BG] point skip reason=${result.status}');
      }
      return result;
    }

    debugPrint(
        '[BG] location post failed and queued status=${response.statusCode}');
    await _enqueuePendingLocation(payload);
    return result;
  } catch (e) {
    debugPrint('[BG] ping error: $e');
    await _enqueuePendingLocation(payload);
    debugPrint('[BG] location post failed and queued');
    return const TrackingPostResult(0, 'http_error', null);
  }
}
