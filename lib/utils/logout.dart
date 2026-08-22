// lib/utils/logout.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/features/users/login_page.dart';
import 'package:serv_app/services/fcm_test_service.dart';
import 'package:serv_app/services/api_service.dart';
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

  // Call tracking check-out to create logout event before clearing token
  try {
    final sp = await SharedPreferences.getInstance();
    final empId = sp.getString('empid') ?? sp.getString('empId');
    final token = CompanyData.token;

    if (empId != null && token.isNotEmpty) {
      // Use local date for tracking document to match admin view
      final localDateIso = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final trackingUri = Uri.parse('${ApiService.baseUrl}/tracking/check-out');
      final response = await http.post(
        trackingUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'empid': empId,
          'dateIso': localDateIso,
        }),
      );

      debugPrint('[Logout] Tracking check-out status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint(
            '[Logout] Tracking check-out failed: ${response.statusCode}');
      }
    }
  } catch (e) {
    debugPrint('[Logout] Tracking check-out error occurred');
  }

  try {
    try {
      html.window.localStorage.remove('token');
      html.window.localStorage.remove('role');
      html.window.localStorage.remove('name');
      html.window.localStorage.remove('empId');
      html.window.localStorage.remove('empid');
      html.window.localStorage.remove('userDocId');
      html.window.localStorage.remove('employeeProfile');
    } catch (_) {}

    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
    await sp.remove('role');
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
