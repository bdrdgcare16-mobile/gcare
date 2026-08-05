import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:serv_app/shared/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Web-only localStorage (safe to import; it’s ignored on mobile/desktop)
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;
import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/services/api_service.dart';

const Color kPrimaryBackgroundTop = Colors.white;
const Color kPrimaryBackgroundBottom = kPrimaryLight;
const Color kAppBarColor = kPrimary;
const Color kButtonColor = kPrimaryDark;

final String _apiBase = ApiConfig.baseUrl;

class FeedbackPage extends StatefulWidget {
  const FeedbackPage(
      {super.key, required String employeeName, required String employeeId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _feedbackList = const [];

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<String?> _getToken() async {
    // Try web localStorage first
    try {
      final t = html.window.localStorage['token'];
      if (t != null && t.isNotEmpty) return t;
    } catch (_) {}
    // Fallback to SharedPreferences (mobile/desktop or web)
    final sp = await SharedPreferences.getInstance();
    final t2 = sp.getString('token');
    return (t2 != null && t2.isNotEmpty) ? t2 : null;
  }

  Future<void> _fetchFeedbacks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final res =
          await http.get(Uri.parse('${ApiService.baseUrl}/feedback'), headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          // Normalize items to Map<String, dynamic>
          _feedbackList = decoded.map<Map<String, dynamic>>((e) {
            final m =
                (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{};
            return {
              'employeeId': (m['empid'] ?? '').toString(),
              'employeeName': (m['name'] ?? '').toString(),
              'message': (m['message'] ?? '').toString(),
              // Expect ISO string from your controller; fallback to empty
              'date': (() {
                final iso = (m['date'] ?? '').toString();
                // Show as YYYY-MM-DD like your UI
                if (iso.length >= 10) return iso.substring(0, 10);
                return iso;
              })(),
            };
          }).toList();
        } else {
          _feedbackList = const [];
        }
        setState(() => _loading = false);
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed: ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Network error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI kept the same; only the data source is dynamic now.
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kAppBarColor, kButtonColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Text(
              'Feedback',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        toolbarHeight: 60,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(_error!,
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _fetchFeedbacks,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchFeedbacks,
                        child: ListView(
                          children: [
                            const SizedBox(height: 10),
                            const Text(
                              'Submitted Feedback',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Cards (same look, now from API)
                            ..._feedbackList.map((fb) {
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Employee ID: ${fb['employeeId'] ?? ''}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                          "Employee Name: ${fb['employeeName'] ?? ''}"),
                                      const SizedBox(height: 6),
                                      Text("Message: ${fb['message'] ?? ''}"),
                                      const SizedBox(height: 6),
                                      Text("Date: ${fb['date'] ?? ''}"),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
