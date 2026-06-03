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
import 'package:serv_app/services/connectivity_service.dart';

const _kChannelId = 'serv_tracking';
const _kChannelName = 'SERV Tracking';
const _kChannelDesc = 'Foreground location tracking';
const _kNotifId = 1212;

bool get _isAndroid => !kIsWeb && Platform.isAndroid;

// Workmanager names & keys
const _wmUniqueTask = 'serv_location_periodic';
const _wmSimpleTask = 'serv_location_oneoff';
const _kEmpKey = 'empid';
const _kTokKey = 'token';

// Persist keys
const _spEmp = 'bg_empid';
const _spTok = 'bg_token';
const _kPendingLocationsKey = 'tracking_pending_locations';
const _kLastLocationEnabledKey = 'tracking_last_location_enabled';

// In-memory identity
String? _empid, _token;

const Duration _kForegroundServiceInterval = Duration(minutes: 10);
Timer? _foregroundServiceTimer;
bool _foregroundServiceTickRunning = false;

// Single notifications plugin
final _flnp = FlutterLocalNotificationsPlugin();

/// Create the Android notification channel & ask notification permission (13+)
Future<void> _ensureNotifChannel() async {
  if (!_isAndroid) return;

  // Init plugin once
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _flnp.initialize(const InitializationSettings(android: androidInit));

  final android =
      _flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

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
}

// ────────────────────────────────────────────────────────────────────────────
// Public API
// ────────────────────────────────────────────────────────────────────────────

Future<void> initializeBackgroundSystems() async {
  if (!_isAndroid) return;

  await _ensureNotifChannel();

  // Configure foreground service (does NOT auto-start)
  final service = FlutterBackgroundService();
  debugPrint('[FG TEST] startForegroundTracking entered');
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: false,
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
}) async {
  final cleanEmpid = empid.trim();
  final cleanToken = token.trim();

  _empid = cleanEmpid;
  _token = cleanToken;

  final sp = await SharedPreferences.getInstance();
  await sp.setString(_spEmp, cleanEmpid);
  await sp.setString(_spTok, cleanToken);
  await sp.setString('empid', cleanEmpid);
  await sp.setString('token', cleanToken);

  debugPrint(
    '[BG] setTrackingIdentity saved empid=$cleanEmpid tokenEmpty=${cleanToken.isEmpty}',
  );

  if (_isAndroid) {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();

    if (running) {
      service.invoke('updateIdentity', {
        'empid': cleanEmpid,
        'token': cleanToken,
      });
      debugPrint('[BG] updateIdentity invoked for running foreground service');
    }
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
    granted =
        await (androidImpl?.requestNotificationsPermission() ?? Future.value(false));
  }

  // 3) If still not granted, DO NOT start the service (it would crash).
  if (!granted!) {
    debugPrint(
      '[FG] Notifications permission not granted – skip startForeground to avoid crash.',
    );
    return;
  }

  // OK to start
  final service = FlutterBackgroundService();
  if (!await service.isRunning()) {
    await service.startService();
    final runningAfter = await service.isRunning();
    debugPrint('[FG TEST] service running after start=$runningAfter');
  } else {
    service.invoke('setAsForeground');
  }
}

Future<void> stopForegroundTracking() async {
  if (!_isAndroid) return;
  final service = FlutterBackgroundService();
  final runningBefore = await service.isRunning();
  debugPrint('[FG TEST] service running before stop=$runningBefore');
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
      '[BG] starting GPS sampling: max=$maxSamples, target=$targetAccuracyMeters m, max=$maxAccuracyMeters m',
    );

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
            '[BG] sample $sampleCount: acc=${pos.accuracy.toStringAsFixed(1)}m (best so far)',
          );
        }

        // Early exit if accuracy is excellent
        if (pos.accuracy <= targetAccuracyMeters) {
          debugPrint(
            '[BG] target accuracy reached after $sampleCount samples, stopping',
          );
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
        '[BG] SKIPPED: accuracy=${bestPosition.accuracy.toStringAsFixed(1)}m exceeds max=${maxAccuracyMeters}m after $sampleCount samples',
      );
      return null;
    }

    debugPrint(
      '[BG] selected best position: acc=${bestPosition.accuracy.toStringAsFixed(1)}m lat=${bestPosition.latitude} lng=${bestPosition.longitude}',
    );
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

    final emp = inputData?[_kEmpKey]?.toString();
    final tok = inputData?[_kTokKey]?.toString();
    debugPrint('[Workmanager] Task=$task empid=$emp');

    try {
      if ((emp ?? '').isNotEmpty && (tok ?? '').isNotEmpty) {
        debugPrint('[Workmanager] pending sync started (sync-only mode)');
        await _syncPendingLocations(emp!, tok!);
        debugPrint('[Workmanager] pending sync completed');

        final enabled = await Geolocator.isLocationServiceEnabled();
        await _updateLocationEnabledEventState(emp!, tok!, enabled, 'workmanager');

        final service = FlutterBackgroundService();
        final fgRunning = await service.isRunning();
        if (fgRunning) {
          debugPrint(
            '[Workmanager] foreground service already running; skipping fresh location capture',
          );
        } else if (!enabled) {
          debugPrint(
            '[Workmanager] GPS disabled during workmanager task; skipping capture',
          );
        } else {
          debugPrint(
            '[Workmanager] foreground service not running; Workmanager fresh location capture started',
          );
          final position = await _captureBestPositionWithSampling(
            maxSamples: 5,
            targetAccuracyMeters: 10.0,
            maxAccuracyMeters: 50.0,
            sampleTimeout: const Duration(seconds: 15),
            totalTimeout: const Duration(seconds: 120),
          );
          if (position != null) {
            debugPrint(
              '[Workmanager] fresh location captured; posting or queueing based on connectivity',
            );
            await _pingServer(
              emp!,
              tok!,
              lat: position.latitude,
              lng: position.longitude,
              accuracy: position.accuracy,
            );
          } else {
            debugPrint(
              '[Workmanager] fresh location capture failed during Workmanager task',
            );
          }
        }
      } else {
        debugPrint(
          '[Workmanager] skipped because user is not checked in or identity is missing',
        );
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
      networkType: NetworkType.notRequired,
      requiresCharging: false,
      requiresBatteryNotLow: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );
  debugPrint('[Workmanager] scheduled for $empid');
}

Future<void> cancelBackgroundTracking({required String empid}) async {
  if (!_isAndroid) return;
  await Workmanager().cancelByUniqueName(_wmUniqueTask);
  debugPrint('[Workmanager] cancelled for $empid');
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

String _payloadSignature(Map<String, dynamic> payload) {
  return '${payload['empid'] ?? ''}|${payload['lat'] ?? ''}|${payload['lng'] ?? ''}|${payload['ts'] ?? ''}|${payload['source'] ?? ''}|${payload['type'] ?? ''}';
}

Future<List<Map<String, dynamic>>> _loadPendingLocations() async {
  final prefs = await _prefs();
  final raw = prefs.getStringList(_kPendingLocationsKey) ?? <String>[];
  final items = <Map<String, dynamic>>[];

  for (final entry in raw) {
    try {
      final parsed = jsonDecode(entry);
      if (parsed is Map<String, dynamic>) {
        items.add(parsed);
      } else {
        if (kDebugMode) {
          debugPrint('[BG] skipped non-map pending entry');
        }
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[BG] skipped corrupted pending tracking entry');
      }
    }
  }

  return items;
}

Future<bool?> _loadLastLocationEnabledState() async {
  final prefs = await _prefs();
  return prefs.getBool(_kLastLocationEnabledKey);
}

Future<void> _saveLastLocationEnabledState(bool enabled) async {
  final prefs = await _prefs();
  await prefs.setBool(_kLastLocationEnabledKey, enabled);
}

Future<bool> _isOnline() async {
  try {
    final online = await ConnectivityService.I.isOnline;
    debugPrint('[BG] internet status checked: $online');
    return online;
  } catch (e) {
    debugPrint('[BG] internet status check failed: $e');
    return false;
  }
}

Future<void> _savePendingLocations(List<Map<String, dynamic>> items) async {
  final prefs = await _prefs();
  final trimmed = items.length <= 200 ? items : items.sublist(items.length - 200);
  final encoded = trimmed.map((item) => jsonEncode(item)).toList();
  await prefs.setStringList(_kPendingLocationsKey, encoded);
}

Future<void> _enqueuePendingPayload(Map<String, dynamic> payload) async {
  final pending = await _loadPendingLocations();
  final newSig = _payloadSignature(payload);
  final duplicate = pending.any((item) => _payloadSignature(item) == newSig);
  if (duplicate) {
    if (kDebugMode) {
      debugPrint('[BG] duplicate pending payload skipped');
    }
    return;
  }

  pending.add(payload);
  await _savePendingLocations(pending);
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

  await _enqueuePendingPayload(payload);
}

Future<void> _enqueuePendingEvent(Map<String, dynamic> payload) async {
  await _enqueuePendingPayload(payload);
}

Future<void> _updateLocationEnabledEventState(
  String empid,
  String token,
  bool enabled,
  String source,
) async {
  final previous = await _loadLastLocationEnabledState();

  if (previous == enabled) {
    await _saveLastLocationEnabledState(enabled);
    return;
  }

  if (previous == null && !enabled) {
    await _appendTrackingEvent(
      empid,
      token,
      source,
      'gps_disabled',
      'GPS/location service was disabled by the user.',
    );
  } else if (previous == null && enabled) {
    await _saveLastLocationEnabledState(enabled);
    return;
  } else if (previous == true && !enabled) {
    await _appendTrackingEvent(
      empid,
      token,
      source,
      'gps_disabled',
      'GPS/location service was disabled by the user.',
    );
  }

  await _saveLastLocationEnabledState(enabled);
}

Future<void> _appendTrackingEvent(
  String empid,
  String token,
  String source,
  String type,
  String message, {
  double? accuracy,
}) async {
  if (type != 'poor_gps' && type != 'gps_disabled') {
    if (kDebugMode) {
      debugPrint('[BG] skipped unsupported tracking event type=$type');
    }
    return;
  }

  final payload = {
    'empid': empid,
    'type': type,
    'message': message,
    if (accuracy != null) 'accuracy': accuracy,
    'source': source,
    'ts': DateTime.now().toIso8601String(),
  };

  final online = await _isOnline();

  if (!online) {
    debugPrint('[BG] offline detected, queueing GPS event $type');
    await _enqueuePendingEvent(payload);
    return;
  }

  try {
    final uri = Uri.parse('${ApiService.baseUrl}/tracking/gps-event');

    debugPrint('[BG] posting /tracking/gps-event type=$type empid=$empid');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-empid': empid,
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));

    if (kDebugMode) {
      debugPrint(
        '[BG] /tracking/gps-event response status=${response.statusCode}',
      );
      debugPrint('[BG] /tracking/gps-event response body=${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[BG] GPS event post failed, queueing event $type');
      await _enqueuePendingEvent(payload);
    }
  } catch (e) {
    debugPrint('[BG] GPS event post error: $e');
    await _enqueuePendingEvent(payload);
  }
}

Future<void> _syncPendingLocations(String empid, String token) async {
  final pending = await _loadPendingLocations();
  if (pending.isEmpty) return;

  if (kDebugMode) {
    debugPrint('[BG] syncing ${pending.length} pending location(s)');
  }

  final kept = <Map<String, dynamic>>[];

  for (final item in pending) {
    try {
      final itemToSend = Map<String, dynamic>.from(item);
      final type = itemToSend['type']?.toString();

      if (type == 'location_enabled') {
        if (kDebugMode) {
          debugPrint('[BG] skipped legacy location_enabled pending event');
        }
        continue;
      }

      if (type == 'location_disabled') {
        itemToSend['type'] = 'gps_disabled';
        itemToSend['message'] = 'GPS/location service was disabled by the user.';
      }

      final isGpsEvent = itemToSend.containsKey('type') &&
          (itemToSend['type'] == 'poor_gps' ||
              itemToSend['type'] == 'gps_disabled');

      final uri = Uri.parse(
        '${ApiService.baseUrl}/${isGpsEvent ? 'tracking/gps-event' : 'tracking/pos'}',
      );

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'x-empid': empid,
            },
            body: jsonEncode(itemToSend),
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint(
          '[BG] sync pending status=${response.statusCode} item=$itemToSend endpoint=${isGpsEvent ? '/tracking/gps-event' : '/tracking/pos'}',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        kept.add(item);
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
        '[BG] pending offline locations sync completed with ${kept.length} remaining',
      );
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
  DartPluginRegistrant.ensureInitialized();

  // Rehydrate identity from prefs
  final sp = await SharedPreferences.getInstance();
  _empid ??= sp.getString(_spEmp) ??
      sp.getString('empid') ??
      sp.getString('empId') ??
      sp.getString('employeeId') ??
      sp.getString('userId');
  _token ??= sp.getString(_spTok) ??
      sp.getString('token') ??
      sp.getString('authToken') ??
      sp.getString('accessToken');

  debugPrint(
    '[BG] restored identity onStart empid=$_empid tokenEmpty=${(_token ?? '').isEmpty}',
  );

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
    if (_foregroundServiceTimer != null) {
      _foregroundServiceTimer!.cancel();
      _foregroundServiceTimer = null;
      debugPrint('[BG] foreground service timer stopped');
    }
    debugPrint('[BG] foreground service stopped');
    service.stopSelf();
  });

  service.on('updateIdentity').listen((event) async {
    final newEmpid = event?['empid']?.toString().trim() ?? '';
    final newToken = event?['token']?.toString().trim() ?? '';

    if (newEmpid.isNotEmpty && newToken.isNotEmpty) {
      _empid = newEmpid;
      _token = newToken;

      final sp = await SharedPreferences.getInstance();
      await sp.setString(_spEmp, newEmpid);
      await sp.setString(_spTok, newToken);
      await sp.setString('empid', newEmpid);
      await sp.setString('token', newToken);

      debugPrint(
        '[BG] updateIdentity received empid=$_empid tokenEmpty=${(_token ?? '').isEmpty}',
      );
    } else {
      debugPrint('[BG] updateIdentity received empty empid/token');
    }
  });

  debugPrint('[BG] foreground service started');

  Future<void> tick() async {
    if (_foregroundServiceTickRunning) {
      debugPrint('[BG] foreground tick already running; skipping');
      return;
    }

    _foregroundServiceTickRunning = true;

    try {
      if (_empid != null && _token != null) {
        await _syncPendingLocations(_empid!, _token!);
      }

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        debugPrint('[BG] permission denied');
        if (_empid != null && _token != null) {
          await _updateLocationEnabledEventState(
            _empid!,
            _token!,
            false,
            'foreground-service',
          );
        }
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (_empid != null && _token != null) {
        await _updateLocationEnabledEventState(
          _empid!,
          _token!,
          enabled,
          'foreground-service',
        );
      }

      if (!enabled) {
        debugPrint('[BG] GPS disabled');
        return;
      }

      // ✅ IMPROVED: Use multi-sample GPS with accuracy validation
      final p = await _captureBestPositionWithSampling(
        maxSamples: 3,
        targetAccuracyMeters: 30.0,
        maxAccuracyMeters: 100.0,
        sampleTimeout: const Duration(seconds: 10),
        totalTimeout: const Duration(seconds: 45),
      );

      if (p == null) {
        debugPrint('[BG] location rejected due to poor accuracy in tick()');

        if ((_empid ?? '').isNotEmpty && (_token ?? '').isNotEmpty) {
          await _appendTrackingEvent(
            _empid!,
            _token!,
            'foreground-service',
            'poor_gps',
            'GPS accuracy was poor. Location point was skipped.',
          );
        }

        return;
      }

      debugPrint(
        '[BG] location captured lat=${p.latitude}, lng=${p.longitude}, acc=${p.accuracy.toStringAsFixed(1)}m',
      );

      // Re-read identity before posting, because foreground service isolate may lose memory values.
      final sp = await SharedPreferences.getInstance();
      final savedEmpid = sp.getString(_spEmp) ??
          sp.getString('empid') ??
          sp.getString('empId') ??
          sp.getString('employeeId') ??
          sp.getString('userId');
      final savedToken = sp.getString(_spTok) ??
          sp.getString('token') ??
          sp.getString('authToken') ??
          sp.getString('accessToken');

      if ((savedEmpid ?? '').isNotEmpty) {
        _empid = savedEmpid;
      }

      if ((savedToken ?? '').isNotEmpty) {
        _token = savedToken;
      }

      debugPrint(
        '[BG] identity check before ping empid=$_empid tokenEmpty=${(_token ?? '').isEmpty}',
      );

      if ((_empid ?? '').isEmpty || (_token ?? '').isEmpty) {
        debugPrint('[BG] missing empid/token. Skipping /tracking/pos post.');
        return;
      }

      final success = await _pingServer(
        _empid!,
        _token!,
        lat: p.latitude,
        lng: p.longitude,
        accuracy: p.accuracy,
      );

      if (success) {
        debugPrint(
          '[BG] location post success from tick() - _pingServer returned true',
        );
      } else {
        debugPrint(
          '[BG] location post failed from tick() - _pingServer returned false',
        );
      }

      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: 'SERV',
          content: 'Location tracking active',
        );
      }
    } catch (e) {
      debugPrint('[BG] tick error: $e');
    } finally {
      _foregroundServiceTickRunning = false;
    }
  }

  await tick();

  if (_foregroundServiceTimer == null || !_foregroundServiceTimer!.isActive) {
    _foregroundServiceTimer = Timer.periodic(
      _kForegroundServiceInterval,
      (_) {
        tick().catchError((e) {
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
// API ping – uses your existing /api/tracking/pos endpoint
// ────────────────────────────────────────────────────────────────────────────
Future<bool> _pingServer(
  String empid,
  String token, {
  double? lat,
  double? lng,
  double? accuracy,
}) async {
  // Use the location already captured by tick() or Workmanager.
  // Do not call /tracking/pos without latitude and longitude.
  final double? lat0 = lat;
  final double? lng0 = lng;
  final double? acc0 = accuracy;

  if (lat0 == null || lng0 == null) {
    debugPrint('[BG] lat/lng missing. Skipping /tracking/pos post.');
    return false;
  }

  final payload = <String, dynamic>{
    'empid': empid,
    'lat': lat0,
    'lng': lng0,
    if (acc0 != null) 'accuracy': acc0,
    'ts': DateTime.now().toIso8601String(),
    'source': 'fg/worker',
  };

  final online = await _isOnline();
  debugPrint('[BG] internet status before /tracking/pos: $online');

  if (!online) {
    debugPrint(
      '[BG] offline detected, queueing payload instead of calling /tracking/pos',
    );
    await _enqueuePendingLocation(payload);
    return false;
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
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);

        final added = decoded['added'];
        final throttled = decoded['throttled'];
        final reason = decoded['reason'];
        final minInterval = decoded['minIntervalMinutes'];
        final minMove = decoded['minMoveMeters'];

        if (added != null && throttled == false) {
          debugPrint('[BG] TRACKING SAVED: point added to pathMap');
        } else {
          debugPrint(
            '[BG] TRACKING SKIPPED: reason=$reason, throttled=$throttled, minInterval=$minInterval, minMove=$minMove',
          );
        }
      } catch (e) {
        debugPrint('[BG] tracking response parse failed: $e');
      }

      return true;
    }

    debugPrint(
      '[BG] location post failed and queued status=${response.statusCode}',
    );
    await _enqueuePendingLocation(payload);
    return false;
  } catch (e) {
    debugPrint('[BG] /tracking/pos error: $e');
    await _enqueuePendingLocation(payload);
    debugPrint('[BG] location post failed and queued');
    return false;
  }
}