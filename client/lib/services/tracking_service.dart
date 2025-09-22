import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Foreground tracking only (timer while app is open).
/// Android true background every ~15 min is handled by Workmanager in main.dart.
class TrackingService {
  final String apiBase;   // e.g. https://api-...run.app/api
  final String jwtToken;  // Bearer token
  final String empId;     // employee id

  Timer? _foregroundTimer;

  TrackingService({required this.apiBase, required this.jwtToken, required this.empId});

  Future<void> startAfterCheckIn() async {
    await _ensureLocationPermission();

    try {
      await http.post(
        Uri.parse('$apiBase/tracking/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
          'x-empid': empId,
        },
        body: jsonEncode({}),
      );
    } catch (_) {}

    await _sendCurrentPos();

    // ✅ Foreground timer every 15 minutes
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _sendCurrentPos();
    });

    if (kDebugMode) {
      // ignore: avoid_print
      print('[TrackingService] foreground timer started (15 min)');
    }
  }

  Future<void> stopAfterCheckOut() async {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;

    if (kDebugMode) {
      // ignore: avoid_print
      print('[TrackingService] foreground timer stopped');
    }
  }

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
        body: jsonEncode({'lat': pos.latitude, 'lng': pos.longitude}),
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
    if (!serviceEnabled) {}

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }
  }
}
