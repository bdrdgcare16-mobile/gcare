// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html show window; // used only on web for localStorage
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// /// Single place to talk to the backend.
// class LeaveApiService {
//   LeaveApiService._();
//   static final LeaveApiService instance = LeaveApiService._();

//   /// Base API origin — change if your server URL differs.
//   static const String apiBase = 'https://api-zmj7dqloiq-uc.a.run.app/api';

//   Future<void> saveToken(String token) async {
//     try {
//       final sp = await SharedPreferences.getInstance();
//       await sp.setString('authToken', token);
//     } catch (_) {}
//     if (kIsWeb) {
//       try { html.window.localStorage['authToken'] = token; } catch (_) {}
//     }
//   }

//   Future<String?> _getToken() async {
//     try {
//       final sp = await SharedPreferences.getInstance();
//       final t = sp.getString('authToken') ?? sp.getString('token') ?? sp.getString('jwt');
//       if (t != null && t.isNotEmpty) return t;
//     } catch (_) {}
//     if (kIsWeb) {
//       try {
//         final t = html.window.localStorage['authToken'] ??
//             html.window.localStorage['token'] ??
//             html.window.localStorage['jwt'];
//         if (t != null && t.isNotEmpty) return t;
//       } catch (_) {}
//     }
//     return null;
//   }

//   Map<String, String> _headers(String? token) => {
//         'Content-Type': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       };

//   // ----------------- AUTH (optional helper) -----------------
//   Future<void> login({required String username, required String password}) async {
//     final url = Uri.parse('$apiBase/auth/login');
//     final res = await http.post(url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'username': username, 'password': password}));
//     if (res.statusCode != 200) {
//       throw Exception('Login failed (${res.statusCode}): ${res.body}');
//     }
//     final data = jsonDecode(res.body);
//     final token = data['token']?.toString();
//     if (token == null || token.isEmpty) {
//       throw Exception('No token in login response');
//     }
//     await saveToken(token);
//   }

//   // ----------------- APPROVALS LIST -----------------
//   /// Fetch approvals list. `type` can be one of your dropdown values (e.g. 'All', 'Late check in').
//   /// `status` can be 'All' | 'Pending' | 'Approved' | 'Rejected'.
//   Future<List<Map<String, dynamic>>> fetchApprovals({
//     required String type,
//     required String status,
//   }) async {
//     final token = await _getToken();
//     final q = <String, String>{};
//     if (type.isNotEmpty && type != 'All') q['type'] = type;
//     if (status.isNotEmpty && status != 'All') q['status'] = status;
//     final uri = Uri.parse('$apiBase/attendance/approvals').replace(queryParameters: q.isEmpty ? null : q);

//     final res = await http.get(uri, headers: _headers(token));
//     if (res.statusCode != 200) {
//       throw Exception('Failed to fetch approvals (${res.statusCode}): ${res.body}');
//     }
//     final raw = jsonDecode(res.body);
//     if (raw is List) {
//       return raw.cast<Map>().map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList();
//     }
//     return const [];
//   }

//   // ----------------- DECISION (Approve/Reject) -----------------
//   /// Decide attendance request.
//   /// Required by backend: source='attendance', requestId, status, empid, date (YYYY-MM-DD).
//   Future<void> decideAttendance({
//     required String requestId,
//     required String status, // 'Approved' | 'Rejected'
//     required String empid,
//     required String date,   // 'YYYY-MM-DD'
//     String reviewer = 'admin001',
//     String remarks = 'OK',
//   }) async {
//     final token = await _getToken();
//     final uri = Uri.parse('$apiBase/attendance/approvals/decision');

//     final payload = {
//       'source': 'attendance',
//       'requestId': requestId,
//       'status': status,
//       'empid': empid,
//       'date': date,
//       'reviewer': reviewer,
//       'remarks': remarks,
//     };

//     final res = await http.post(
//       uri,
//       headers: _headers(token),
//       body: jsonEncode(payload),
//     );

//     if (res.statusCode != 200) {
//       throw Exception('Decision failed (${res.statusCode}): ${res.body}');
//     }
//   }
// }