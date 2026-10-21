// lib/utils/logout.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/features/users/login_page.dart';
import 'package:serv_app/features/users/background_tasks.dart';
import 'package:serv_app/services/fcm_test_service.dart';
import 'package:serv_app/services/feature_service.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/services/tracking_events.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;
import 'package:intl/intl.dart';

Future<void> logout(BuildContext context) async {
  // Deactivate this device's FCM token on the backend before the JWT that
  // authorizes the request is cleared.
  try {
    await FcmTestService.instance.unregisterDevice();
  } catch (_) {}

  // Stop all location tracking before session teardown. This cancels the
  // periodic timer, stops the foreground service, cancels the tracking
  // Workmanager task, performs a best-effort final sync and clears the
  // persisted background credentials (bg_empid / bg_token). Local cleanup
  // always runs, even if the backend check-out call below fails.
  try {
    final spForCleanup = await SharedPreferences.getInstance();
    final cleanupEmpId =
        spForCleanup.getString('empid') ?? spForCleanup.getString('empId') ?? '';
    await stopTrackingForLogout(
      empid: cleanupEmpId,
      token: CompanyData.token,
    );
  } catch (_) {}

  // Call tracking check-out to create logout event before clearing token
  try {
    final sp = await SharedPreferences.getInstance();
    final empId = sp.getString('empid') ?? sp.getString('empId');
    final token = CompanyData.token;

    if (empId != null && token.isNotEmpty) {
      // Local date only matters for the dedupe eventId — the server resolves
      // the tracking day itself (Asia/Kolkata).
      final localDateIso = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final eventId = 'logout_${empId}_$localDateIso';

      bool delivered = false;
      final trackingUri = Uri.parse('${ApiService.baseUrl}/tracking/check-out');
      try {
        final response = await http
            .post(
              trackingUri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'empid': empId,
                'dateIso': localDateIso,
                'eventId': eventId,
              }),
            )
            .timeout(const Duration(seconds: 10));

        debugPrint('[Logout] Tracking check-out status: ${response.statusCode}');
        delivered = response.statusCode == 200;
      } catch (_) {}

      if (!delivered) {
        // Offline/failed — persist the logout event so it syncs later while
        // the stored JWT is still unexpired (Workmanager / next app launch).
        await TrackingEvents.enqueue({
          'type': 'account_logged_out',
          'message': 'User logged out',
          'empid': empId,
          'eventId': eventId,
          '__token': token,
        });
      }
    }
  } catch (e) {
    debugPrint('[Logout] Tracking check-out error occurred');
  }

  // Clear cached tenant entitlements
  await FeatureAccess.clear();

  try {
    try {
      html.window.localStorage.remove('token');
      html.window.localStorage.remove('role');
      html.window.localStorage.remove('displayRole');
      html.window.localStorage.remove('name');
      html.window.localStorage.remove('empId');
      html.window.localStorage.remove('empid');
      html.window.localStorage.remove('userDocId');
      html.window.localStorage.remove('employeeProfile');
    } catch (_) {}

    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
    await sp.remove('role');
    await sp.remove('displayRole');
    CompanyData.role = '';
    CompanyData.displayRole = '';
    await sp.remove('name');
    await sp.remove('empId');
    await sp.remove('empid');
    await sp.remove('userDocId');
    await sp.remove('employeeProfile');
  } catch (_) {}

  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (r) => false,
    );
  }
}
