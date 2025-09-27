import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

const String _taskName = 'serv_tracking_ping';
const String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api/tracking';

Future<void> scheduleBackgroundTracking({
  required String empid,
  required String token,
}) async {
  if (kIsWeb || !Platform.isAndroid) return;

  await Workmanager().registerPeriodicTask(
    '$_taskName-$empid',
    _taskName,
    frequency: const Duration(minutes: 15), // minimum interval on Android
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false,
      requiresCharging: false,
    ),
    inputData: {'empid': empid, 'token': token},
  );
}

Future<void> cancelBackgroundTracking({required String empid}) async {
  if (kIsWeb || !Platform.isAndroid) return;
  await Workmanager().cancelByUniqueName('$_taskName-$empid');
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      final empid = (inputData?['empid'] ?? '').toString();
      final token = (inputData?['token'] ?? '').toString();
      if (empid.isEmpty || token.isEmpty) return true;

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      ).catchError((_) => null);

      final body = {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
        'source': 'bg-workmanager',
        'ts': DateTime.now().toIso8601String(),
      };

      await http.post(
        Uri.parse('$_apiBase/pos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-empid': empid,
        },
        body: jsonEncode(body),
      );
        } catch (e) {
      if (kDebugMode) {
        print('Background task error: $e');
      }
    }
    return true;
  });
}
