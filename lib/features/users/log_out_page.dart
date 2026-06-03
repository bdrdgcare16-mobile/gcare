import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/utils/logout.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme color constants
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class LogOutPage extends StatelessWidget {
  const LogOutPage({super.key});

  Future<void> _saveLogoutTrackingEvent() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token') ??
        prefs.getString('authToken') ??
        prefs.getString('accessToken') ??
        '';

    final empid = prefs.getString('bg_empid') ??
        prefs.getString('empid') ??
        prefs.getString('empId') ??
        prefs.getString('employeeId') ??
        prefs.getString('userId') ??
        '';

    if (token.isEmpty || empid.isEmpty) {
      if (kDebugMode) {
        debugPrint('[LOGOUT] skipped logout event because empid/token missing');
      }
      return;
    }

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/tracking/gps-event');

      final payload = {
        'empid': empid,
        'type': 'account_logged_out',
        'message': 'User logged out of the account.',
        'source': 'logout',
        'ts': DateTime.now().toIso8601String(),
      };

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
        debugPrint('[LOGOUT] logout event status=${response.statusCode}');
        debugPrint('[LOGOUT] logout event body=${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LOGOUT] failed to save logout event: $e');
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
  debugPrint('[LOGOUT] LOG OUT button clicked');

  await _saveLogoutTrackingEvent();

  debugPrint('[LOGOUT] logout event function completed, now calling logout(context)');

  if (!context.mounted) return;

  logout(context);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar stays at the top
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        title: const Text(
          'Log Out',
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kTextColor),
        centerTitle: false,
        elevation: 0,
      ),
      // Body with gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimaryBackgroundTop,
              kPrimaryBackgroundBottom,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryBackgroundTop,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Log Out?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: kPrimaryBackgroundTop,
                          foregroundColor: kAppBarColor,
                          side: const BorderSide(color: kAppBarColor),
                        ),
                        child: const Text("CANCEL"),
                      ),
                      ElevatedButton(
                        onPressed: () => _handleLogout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kButtonColor,
                          foregroundColor: kTextColor,
                        ),
                        child: const Text("LOG OUT"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}