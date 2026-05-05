import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==== Colors ====
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ------- API base (using centralized config) -------
final String apiBase = ApiConfig.baseUrl;
// To resolve /uploads/... into a full URL
final String _apiOrigin = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

class UserEventUpdatesPage extends StatefulWidget {
  const UserEventUpdatesPage({super.key});

  @override
  State<UserEventUpdatesPage> createState() => _UserEventUpdatesPageState();
}

class _UserEventUpdatesPageState extends State<UserEventUpdatesPage> {
  late Future<List<Map<String, String>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = fetchEventData();
  }

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$_apiOrigin$url';
    return '$_apiOrigin/$url';
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '';
    final parts = d.split('T').first.split('-');
    if (parts.length != 3) return d;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Future<String?> _getToken() async {
    // Try web localStorage first
    if (kIsWeb) {
      try {
        final tokenKeys = ['token', 'jwt', 'access_token', 'auth_token'];
        for (final key in tokenKeys) {
          final value = html.window.localStorage[key];
          if (value != null && value.isNotEmpty) {
            debugPrint('[Events] Token found in localStorage: $key');
            return value;
          }
        }
      } catch (e) {
        debugPrint('[Events] Error reading token from localStorage: $e');
      }
    }
    
    // Try mobile SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenKeys = ['token', 'jwt', 'access_token', 'auth_token'];
      for (final key in tokenKeys) {
        final value = prefs.getString(key);
        if (value != null && value.isNotEmpty) {
          debugPrint('[Events] Token found in SharedPreferences: $key');
          return value;
        }
      }
    } catch (e) {
      debugPrint('[Events] Error reading token from SharedPreferences: $e');
    }
    
    // Try centralized CompanyData token
    if (CompanyData.token != null && CompanyData.token.toString().isNotEmpty) {
      debugPrint('[Events] Token found in CompanyData');
      return CompanyData.token.toString();
    }
    
    debugPrint('[Events] No token found in any source');
    return null;
  }

  Future<List<Map<String, String>>> fetchEventData() async {
  try {
    final token = await _getToken();

    debugPrint('[Events] Fetching events from: ${ApiService.baseUrl}/events');
    debugPrint(
      '[Events] Token available: ${token != null ? 'Yes (${token.length} chars)' : 'No'}',
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      debugPrint('[Events] Authorization header added');
    } else {
      debugPrint('[Events] WARNING: No token available, request may fail');
    }

    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/events'),
      headers: headers,
    );

    debugPrint('[Events] Response status code: ${res.statusCode}');
    debugPrint('[Events] Response body: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    List rawEvents = [];

    if (decoded is List) {
      rawEvents = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded['events'] is List) {
        rawEvents = decoded['events'] as List;
      } else if (decoded['data'] is List) {
        rawEvents = decoded['data'] as List;
      } else {
        throw Exception('Invalid response format: no events list found');
      }
    } else {
      throw Exception('Invalid response format');
    }

    return rawEvents.map<Map<String, String>>((e) {
      final event = Map<String, dynamic>.from(e as Map);

      final title = (event['title'] ?? '').toString();
      final location = (event['location'] ?? '').toString();
      final desc = (event['description'] ?? '').toString();
      final fromDateStr = (event['fromDate'] ?? '').toString();
      final toDateStr = (event['toDate'] ?? '').toString();
      final imageUrl = _resolveUrl((event['imageUrl'] ?? '').toString());

      return {
        'event': title,
        'from': _fmtDate(fromDateStr),
        'to': _fmtDate(toDateStr),
        'location': location,
        'image': imageUrl,
        'desc': desc,
      };
    }).toList();
  } catch (e) {
    throw Exception('Error fetching events: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Event Updates'),
        backgroundColor: const Color(0xFF8C6EAF),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: FutureBuilder<List<Map<String, String>>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No events found.'));
            }

            final events = snapshot.data!;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: kButtonColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text(
                            "Event Name",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            "From",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            "To",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            "Location",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: Text(
                            "Description",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...events.map((event) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 2),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(event['event'] ?? ''),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(event['from'] ?? ''),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(event['to'] ?? ''),
                          ),
                          SizedBox(
                            width: 110,
                            child: Text(event['location'] ?? ''),
                          ),
                          SizedBox(
                            width: 220,
                            child: Text(event['desc'] ?? ''),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}