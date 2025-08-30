// // // // // // // // lib/services/api_service.dart
// // // // // // // import 'dart:convert';
// // // // // // // import 'dart:io';
// // // // // // // import 'package:flutter/foundation.dart';
// // // // // // // import 'package:http/http.dart' as http;
// // // // // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // // // // import '../models/leave_approval.dart';

// // // // // // // class ApiService {
// // // // // // //   ApiService._();

// // // // // // //   /// If you run on Android emulator, http://10.0.2.2 hits your host.
// // // // // // //   /// On web / desktop it can stay http://localhost.
// // // // // // //   static final String _base =
// // // // // // //       kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

// // // // // // //   static String approvalsUrl([Map<String, String>? qp]) {
// // // // // // //     final b = StringBuffer('$_base/attendance/approvals');
// // // // // // //     if (qp != null && qp.isNotEmpty) {
// // // // // // //       b.write('?');
// // // // // // //       b.write(qp.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&'));
// // // // // // //     }
// // // // // // //     return b.toString();
// // // // // // //   }

// // // // // // //   static Future<String?> _getToken() async {
// // // // // // //     // use whatever key you save the JWT under in your app
// // // // // // //     final sp = await SharedPreferences.getInstance();
// // // // // // //     return sp.getString('token') ?? sp.getString('authToken');
// // // // // // //   }

// // // // // // //   static Future<Map<String, String>> _headers() async {
// // // // // // //     final t = await _getToken();
// // // // // // //     return {
// // // // // // //       HttpHeaders.contentTypeHeader: 'application/json',
// // // // // // //       if (t != null && t.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $t',
// // // // // // //     };
// // // // // // //   }

// // // // // // //   /// GET /attendance/approvals?type=...&status=...
// // // // // // //   static Future<List<LeaveApproval>> fetchApprovals({
// // // // // // //     String? type, // e.g. "Late check in"
// // // // // // //     String? status, // "Pending" | "Approved" | "Rejected"
// // // // // // //   }) async {
// // // // // // //     final qp = <String, String>{};
// // // // // // //     if (type != null && type.trim().isNotEmpty && type != 'All') qp['type'] = type;
// // // // // // //     if (status != null && status.trim().isNotEmpty && status != 'All') qp['status'] = status;

// // // // // // //     final res = await http.get(Uri.parse(approvalsUrl(qp)), headers: await _headers());
// // // // // // //     if (res.statusCode != 200) {
// // // // // // //       throw Exception('Approvals fetch failed (${res.statusCode}): ${res.body}');
// // // // // // //     }
// // // // // // //     final List data = json.decode(res.body) as List;
// // // // // // //     return data.map((e) => LeaveApproval.fromJson(e as Map<String, dynamic>)).toList();
// // // // // // //   }

// // // // // // //   /// Convenience: get counts for each status for a given type by making 3 small calls.
// // // // // // //   static Future<Map<String, int>> fetchCountsForType(String type) async {
// // // // // // //     final statuses = ['Pending', 'Approved', 'Rejected'];
// // // // // // //     final results = await Future.wait(statuses.map((s) => fetchApprovals(type: type == 'All' ? null : type, status: s)));
// // // // // // //     return {
// // // // // // //       for (int i = 0; i < statuses.length; i++) statuses[i]: results[i].length,
// // // // // // //     };
// // // // // // //   }

// // // // // // //   /// POST /attendance/approvals/decision
// // // // // // //   /// Body (attendance): { source:"attendance", requestId, status, empid, date, reviewer, remarks }
// // // // // // //   static Future<void> decideAttendance({
// // // // // // //     required String requestId,
// // // // // // //     required String empid,
// // // // // // //     required String date, // YYYY-MM-DD
// // // // // // //     required String status, // "Approved" | "Rejected"
// // // // // // //     String reviewer = 'admin001',
// // // // // // //     String remarks = '',
// // // // // // //   }) async {
// // // // // // //     final body = json.encode({
// // // // // // //       'source': 'attendance',
// // // // // // //       'requestId': requestId,
// // // // // // //       'status': status,
// // // // // // //       'empid': empid,
// // // // // // //       'date': date,
// // // // // // //       'reviewer': reviewer,
// // // // // // //       'remarks': remarks,
// // // // // // //     });

// // // // // // //     final res = await http.post(
// // // // // // //       Uri.parse('$_base/attendance/approvals/decision'),
// // // // // // //       headers: await _headers(),
// // // // // // //       body: body,
// // // // // // //     );
// // // // // // //     if (res.statusCode != 200) {
// // // // // // //       throw Exception('Decision failed (${res.statusCode}): ${res.body}');
// // // // // // //     }
// // // // // // //   }
// // // // // // // }
// // // // // // // lib/services/api_service.dart
// // // // // // // lib/services/api_service.dart
// // // // // // import 'leave_api_service.dart';

// // // // // // /// Back-compat shim so existing code can keep using `ApiService.*`.
// // // // // // class ApiService {
// // // // // //   static final _svc = LeaveApiService.instance;

// // // // // //   // --- auth/token helpers ---
// // // // // //   static Future<void> saveToken(String token) => _svc.saveToken(token);

// // // // // //   static Future<void> login({
// // // // // //     required String username,
// // // // // //     required String password,
// // // // // //   }) =>
// // // // // //       _svc.login(username: username, password: password);

// // // // // //   // --- approvals list ---
// // // // // //   static Future<List<Map<String, dynamic>>> fetchApprovals({
// // // // // //     required String type,   // e.g. 'Late check in', 'Permission', 'All'
// // // // // //     required String status, // 'Pending' | 'Approved' | 'Rejected' | 'All'
// // // // // //   }) =>
// // // // // //       _svc.fetchApprovals(type: type, status: status);

// // // // // //   // --- approve / reject attendance request ---
// // // // // //   static Future<void> decideAttendance({
// // // // // //     required String requestId,
// // // // // //     required String status, // 'Approved' | 'Rejected'
// // // // // //     required String empid,
// // // // // //     required String date,   // 'YYYY-MM-DD'
// // // // // //     String reviewer = 'admin001',
// // // // // //     String remarks  = 'OK',
// // // // // //   }) =>
// // // // // //       _svc.decideAttendance(
// // // // // //         requestId: requestId,
// // // // // //         status: status,
// // // // // //         empid: empid,
// // // // // //         date: date,
// // // // // //         reviewer: reviewer,
// // // // // //         remarks: remarks,
// // // // // //       );

// // // // // //   static Future fetchCountsForType(String selectedTab) async {}
// // // // // // }
// // // // // // lib/services/api_service.dart
// // // // // import 'dart:convert';
// // // // // import 'package:flutter/foundation.dart' show kIsWeb;
// // // // // import 'package:http/http.dart' as http;

// // // // // // If you store JWT here after login:
// // // // // import 'package:serv_app/models/company_data.dart';
// // // // // // For Web fallback:
// // // // // import 'dart:html' as html;

// // // // // class ApiService {
// // // // //   static const String _base = 'http://localhost:3000';

// // // // //   static Future<Map<String, String>> _authHeaders() async {
// // // // //     String? token = CompanyData.token;
// // // // //     if ((token == null || token.isEmpty) && kIsWeb) {
// // // // //       token = html.window.localStorage['token'];
// // // // //     }
// // // // //     return {
// // // // //       'Content-Type': 'application/json',
// // // // //       if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
// // // // //     };
// // // // //   }

// // // // //   static Future<List<Map<String, dynamic>>> fetchApprovals({
// // // // //     String? type, // "All" | "Late check in" | ...
// // // // //     String? status, // "Pending" | "Approved" | "Rejected"
// // // // //     String? start, // optional
// // // // //     String? end, // optional
// // // // //   }) async {
// // // // //     final uri = Uri.parse('$_base/api/attendance/approvals').replace(
// // // // //       queryParameters: {
// // // // //         if (type != null && type.isNotEmpty) 'type': type,
// // // // //         if (status != null && status.isNotEmpty) 'status': status,
// // // // //         if (start != null && start.isNotEmpty) 'start': start,
// // // // //         if (end != null && end.isNotEmpty) 'end': end,
// // // // //       },
// // // // //     );
// // // // //     final res = await http.get(uri, headers: await _authHeaders());
// // // // //     if (res.statusCode == 401) {
// // // // //       throw Exception('Failed to fetch approvals (401): ${res.body}');
// // // // //     }
// // // // //     if (res.statusCode < 200 || res.statusCode >= 300) {
// // // // //       throw Exception(
// // // // //         'Failed to fetch approvals (${res.statusCode}): ${res.body}',
// // // // //       );
// // // // //     }
// // // // //     final body = jsonDecode(res.body);
// // // // //     final List list = (body is List) ? body : (body['items'] ?? []);
// // // // //     return list.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
// // // // //   }

// // // // //   /// Decide approval for either attendance or leave, based on `source`.
// // // // //   /// `item` must be the object returned by fetchApprovals (it has `source`, `requestId`, `empid`, `requestDate`).
// // // // //   static Future<void> decideApproval({
// // // // //     required Map<String, dynamic> item,
// // // // //     required String status, // "Approved" | "Rejected"
// // // // //     String? remarks, required String requestId, required String empid, required String date,
// // // // //   }) async {
// // // // //     final source = (item['source'] ?? '').toString(); // "attendance" | "leaves"
// // // // //     final payload = <String, dynamic>{
// // // // //       'source': source,
// // // // //       'status': status,
// // // // //       if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
// // // // //     };

// // // // //     if (source == 'attendance') {
// // // // //       // Prefer the unique document id if we have it:
// // // // //       final id = (item['requestId'] ?? '').toString();
// // // // //       if (id.isNotEmpty) {
// // // // //         payload['attendanceId'] = id;
// // // // //       } else {
// // // // //         // Fallback: empid + date (YYYY-MM-DD)
// // // // //         payload['empid'] = (item['empid'] ?? '').toString();
// // // // //         payload['date'] = (item['requestDate'] ?? '').toString();
// // // // //       }
// // // // //     } else if (source == 'leaves') {
// // // // //       payload['leaveId'] = (item['requestId'] ?? '').toString();
// // // // //     } else {
// // // // //       throw Exception('Unknown source: $source');
// // // // //     }

// // // // //     final uri = Uri.parse('$_base/api/attendance/approvals/decision');
// // // // //     final res = await http.post(
// // // // //       uri,
// // // // //       headers: await _authHeaders(),
// // // // //       body: jsonEncode(payload),
// // // // //     );

// // // // //     if (res.statusCode == 401) {
// // // // //       throw Exception('Decision failed (401): ${res.body}');
// // // // //     }
// // // // //     if (res.statusCode < 200 || res.statusCode >= 300) {
// // // // //       throw Exception('Decision failed (${res.statusCode}): ${res.body}');
// // // // //     }
// // // // //   }
// // // // // }
// // // // // lib/services/api_service.dart
// // // // import 'dart:convert';
// // // // import 'package:flutter/foundation.dart' show kIsWeb;
// // // // import 'package:http/http.dart' as http;

// // // // // If you store JWT here after login:
// // // // import 'package:serv_app/models/company_data.dart';

// // // // // NOTE: for web builds this import is fine.
// // // // // If you later build for mobile, guard it with conditional imports.
// // // // import 'dart:html' as html;

// // // // class ApiService {
// // // //   static const String _base = 'http://localhost:3000';

// // // //   // -------------------- helpers --------------------
// // // //   static Future<Map<String, String>> _authHeaders() async {
// // // //     String? token = CompanyData.token;

// // // //     // Avoid null-assert crash; also try localStorage on web.
// // // //     if ((token == null || token.isEmpty) && kIsWeb) {
// // // //       try {
// // // //         final t = html.window.localStorage['token'];
// // // //         if (t != null && t.isNotEmpty) token = t;
// // // //       } catch (_) {/* ignore */}
// // // //     }

// // // //     return {
// // // //       'Content-Type': 'application/json',
// // // //       if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
// // // //     };
// // // //   }

// // // //   static String _ymd(DateTime d) =>
// // // //       '${d.year.toString().padLeft(4, '0')}-'
// // // //       '${d.month.toString().padLeft(2, '0')}-'
// // // //       '${d.day.toString().padLeft(2, '0')}';

// // // //   // Convert “all” to null so we do not send the param at all.
// // // //   static String? _normalizeStatus(String? status) {
// // // //     if (status == null) return null;
// // // //     final s = status.trim();
// // // //     if (s.isEmpty) return null;
// // // //     if (s.toLowerCase() == 'all' || s.toLowerCase() == 'status') return null;
// // // //     final low = s.toLowerCase();
// // // //     if (low == 'pending') return 'Pending';
// // // //     if (low == 'approved') return 'Approved';
// // // //     if (low == 'rejected') return 'Rejected';
// // // //     return s;
// // // //   }

// // // //   // -------------------- ADMIN: approvals list --------------------
// // // //   static Future<List<Map<String, dynamic>>> fetchApprovals({
// // // //     String? type,   // "All" | "Late check in" | ...
// // // //     String? status, // "Pending" | "Approved" | "Rejected" | "All"
// // // //     String? start,  // optional YYYY-MM-DD
// // // //     String? end,    // optional YYYY-MM-DD
// // // //   }) async {
// // // //     final normStatus = _normalizeStatus(status);

// // // //     final qp = <String, String>{};
// // // //     if (type != null && type.isNotEmpty) qp['type'] = type;
// // // //     if (normStatus != null && normStatus.isNotEmpty) qp['status'] = normStatus;
// // // //     if (start != null && start.isNotEmpty) qp['start'] = start;
// // // //     if (end != null && end.isNotEmpty) qp['end'] = end;

// // // //     final uri = Uri.parse('$_base/api/attendance/approvals')
// // // //         .replace(queryParameters: qp);

// // // //     final res = await http.get(uri, headers: await _authHeaders());

// // // //     if (res.statusCode == 401 || res.statusCode == 403) {
// // // //       throw Exception('Failed to fetch approvals (${res.statusCode}): ${res.body}');
// // // //     }
// // // //     if (res.statusCode < 200 || res.statusCode >= 300) {
// // // //       throw Exception(
// // // //         'Failed to fetch approvals (${res.statusCode}): ${res.body}',
// // // //       );
// // // //     }

// // // //     final body = jsonDecode(res.body);
// // // //     final List list = (body is List) ? body : (body['items'] ?? []);
// // // //     return list.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
// // // //   }

// // // //   // -------------------- USER: my-requests (no admin role) --------------------
// // // //   /// Fetch the logged-in user's own requests (attendance + leaves).
// // // //   /// [from] and [to] form the date window (inclusive).
// // // //   /// [status] can be 'Pending' | 'Approved' | 'Rejected' | 'All' | 'Status'
// // // //   static Future<List<Map<String, dynamic>>> fetchMyRequests({
// // // //     required DateTime from,
// // // //     required DateTime to,
// // // //     String status = 'All', required String start, required String end,
// // // //   }) async {
// // // //     final qp = <String, String>{
// // // //       'start': _ymd(from),
// // // //       'end': _ymd(to),
// // // //     };
// // // //     final normStatus = _normalizeStatus(status);
// // // //     if (normStatus != null && normStatus.isNotEmpty) {
// // // //       qp['status'] = normStatus;
// // // //     }

// // // //     final uri = Uri.parse('$_base/api/attendance/my-requests')
// // // //         .replace(queryParameters: qp);

// // // //     final res = await http.get(uri, headers: await _authHeaders());

// // // //     if (res.statusCode == 401 || res.statusCode == 403) {
// // // //       throw Exception('Forbidden: insufficient role');
// // // //     }
// // // //     if (res.statusCode != 200) {
// // // //       throw Exception('HTTP ${res.statusCode}: ${res.body}');
// // // //     }

// // // //     final list = jsonDecode(res.body) as List<dynamic>;
// // // //     return list.cast<Map<String, dynamic>>();
// // // //   }

// // // //   // -------------------- decision API (admin) --------------------
// // // //   /// Approve/Reject any approval card (attendance or leaves).
// // // //   /// Pass the exact map you received from `fetchApprovals()` (admin)
// // // //   /// or from your admin list source.
// // // //   static Future<void> decideApproval({
// // // //     required Map<String, dynamic> item,
// // // //     required String status, // "Approved" | "Rejected"
// // // //     String? remarks,
// // // //   }) async {
// // // //     // 1) Normalize / infer source
// // // //     String src = (item['source'] ?? '').toString().trim().toLowerCase();
// // // //     if (src.isEmpty) {
// // // //       final t = (item['type'] ?? '').toString().toLowerCase();
// // // //       src = t.startsWith('late check') ? 'attendance' : 'leaves';
// // // //     }
// // // //     if (src != 'attendance' && src != 'leaves') {
// // // //       throw Exception('Unknown source: $src');
// // // //     }

// // // //     // 2) Build payload
// // // //     final payload = <String, dynamic>{
// // // //       'source': src,
// // // //       'status': status[0].toUpperCase() + status.substring(1).toLowerCase(),
// // // //       if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
// // // //     };

// // // //     // Prefer the id returned by /approvals
// // // //     final reqId = (item['requestId'] ?? '').toString();

// // // //     if (src == 'attendance') {
// // // //       if (reqId.isNotEmpty) {
// // // //         payload['attendanceId'] = reqId;
// // // //       } else {
// // // //         payload['empid'] = (item['empid'] ?? '').toString();
// // // //         payload['date']  = (item['requestDate'] ?? '').toString(); // YYYY-MM-DD
// // // //       }
// // // //     } else {
// // // //       payload['leaveId'] = reqId;
// // // //     }

// // // //     final uri = Uri.parse('$_base/api/attendance/approvals/decision');
// // // //     final res = await http.post(
// // // //       uri,
// // // //       headers: await _authHeaders(),
// // // //       body: jsonEncode(payload),
// // // //     );

// // // //     if (res.statusCode == 401 || res.statusCode == 403) {
// // // //       throw Exception('Decision failed (${res.statusCode}): ${res.body}');
// // // //     }
// // // //     if (res.statusCode < 200 || res.statusCode >= 300) {
// // // //       throw Exception('Decision failed (${res.statusCode}): ${res.body}');
// // // //     }
// // // //   }

// // // //   // ------- legacy wrapper so old call sites still compile -------
// // // //   static Future<void> decideAttendance({
// // // //     required String requestId,
// // // //     required String empid,
// // // //     required String date,   // YYYY-MM-DD
// // // //     required String status, // "Approved" | "Rejected"
// // // //     String? remarks,
// // // //   }) async {
// // // //     final item = <String, dynamic>{
// // // //       'source': 'attendance',
// // // //       'requestId': requestId,
// // // //       'empid': empid,
// // // //       'requestDate': date,
// // // //     };
// // // //     await decideApproval(item: item, status: status, remarks: remarks);
// // // //   }
// // // // }
// // import 'dart:convert';
// // import 'package:flutter/foundation.dart' show kIsWeb;
// // import 'package:http/http.dart' as http;

// // // Token set at login
// // import 'package:serv_app/models/company_data.dart';

// // // Web only (localStorage)
// // import 'dart:html' as html;

// // class ApiService {
// //   static const String _origin = 'http://localhost:3000';
// //   static const String _approvalsPath = '/api/attendance/approvals';
// //   static const String _myRequestsPath = '/api/attendance/my-requests';

// //   // -------------------- auth headers --------------------
// //   static Future<Map<String, String>> _authHeaders({bool json = true}) async {
// //     String? token = CompanyData.token;
// //     if ((token == null || token.isEmpty) && kIsWeb) {
// //       try {
// //         final t = html.window.localStorage['token'];
// //         if (t != null && t.isNotEmpty) token = t;
// //       } catch (_) {}
// //     }
// //     return {
// //       if (json) 'Content-Type': 'application/json',
// //       if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
// //     };
// //   }

// //   // -------------------- helpers --------------------
// //   static String _ymd(DateTime d) =>
// //       '${d.year.toString().padLeft(4, '0')}-'
// //       '${d.month.toString().padLeft(2, '0')}-'
// //       '${d.day.toString().padLeft(2, '0')}';

// //   /// Map UI labels to API slugs; return '' to omit the param (e.g. "All")
// //   static String _mapType(String? ui) {
// //     if (ui == null || ui.trim().isEmpty) return '';
// //     switch (ui.trim()) {
// //       case 'All':
// //       case 'Type':
// //         return '';
// //       case 'Late check in':
// //         return 'late-check-in';
// //       case 'Early check out':
// //         return 'early-check-out';
// //       case 'Leave Type':
// //         return 'leave';
// //       case 'Permission':
// //         return 'permission';
// //       case 'Over Time':
// //         return 'overtime';
// //       case 'Half Day Leave':
// //         return 'halfday';
// //       case 'Comp Off':
// //         return 'compoff';
// //       default:
// //         return ui.trim();
// //     }
// //   }

// //   static String? _normStatus(String? status) {
// //     if (status == null) return null;
// //     final s = status.trim().toLowerCase();
// //     if (s.isEmpty || s == 'all' || s == 'status') return null;
// //     if (s == 'pending') return 'Pending';
// //     if (s == 'approved') return 'Approved';
// //     if (s == 'rejected') return 'Rejected';
// //     return status.trim();
// //   }

// //   // ======================================================
// //   //                      ADMIN
// //   // ======================================================

// //   /// Fetch approval cards for Admin dashboard.
// //   static Future<List<Map<String, dynamic>>> fetchApprovals({
// //     required String type,     // UI label
// //     required String status,   // Pending | Approved | Rejected | All
// //     String? start,            // YYYY-MM-DD
// //     String? end,              // YYYY-MM-DD
// //   }) async {
// //     final qp = <String, String>{
// //       if (_mapType(type).isNotEmpty) 'type': _mapType(type),
// //       if (_normStatus(status) != null) 'status': _normStatus(status)!,
// //       if (start != null && start.isNotEmpty) 'start': start,
// //       if (end != null && end.isNotEmpty) 'end': end,
// //     };

// //     final uri = Uri.parse('$_origin$_approvalsPath').replace(queryParameters: qp);
// //     final res = await http.get(uri, headers: await _authHeaders());

// //     if (res.statusCode < 200 || res.statusCode >= 300) {
// //       throw Exception('Failed to fetch approvals (${res.statusCode}): ${res.body}');
// //     }

// //     final body = jsonDecode(res.body);
// //     if (body is List) {
// //       return List<Map<String, dynamic>>.from(body.map((e) => Map<String, dynamic>.from(e)));
// //     }
// //     if (body is Map && body['items'] is List) {
// //       return List<Map<String, dynamic>>.from((body['items'] as List).map((e) => Map<String, dynamic>.from(e)));
// //     }
// //     if (body is Map<String, dynamic>) return [body];
// //     return <Map<String, dynamic>>[];
// //   }

// //   /// Approve/Reject by id returned from fetchApprovals().
// //   static Future<void> decideApproval({
// //     required Map<String, dynamic> item,
// //     required String status, // "approved" | "rejected" (any case)
// //   }) async {
// //     final id = (item['id'] ?? item['docId'] ?? item['requestId'])?.toString() ?? '';
// //     if (id.isEmpty) {
// //       throw Exception('Decision failed: missing id in item');
// //     }

// //     final uri = Uri.parse('$_origin$_approvalsPath/decision');
// //     final payload = {
// //       'id': id,
// //       'status': status.toLowerCase(),
// //     };

// //     final res = await http.post(uri, headers: await _authHeaders(), body: jsonEncode(payload));
// //     if (res.statusCode < 200 || res.statusCode >= 300) {
// //       throw Exception('Decision failed (${res.statusCode}): ${res.body}');
// //     }
// //   }

// //   // ======================================================
// //   //                      USER
// //   // ======================================================

// //   /// Logged-in user's own requests in a date window.
// //   static Future<List<Map<String, dynamic>>> fetchMyRequests({
// //     required DateTime from,
// //     required DateTime to,
// //     String status = 'All', required String start, required String end,
// //   }) async {
// //     final qp = <String, String>{
// //       'start': _ymd(from),
// //       'end': _ymd(to),
// //       if (_normStatus(status) != null) 'status': _normStatus(status)!,
// //     };

// //     final uri = Uri.parse('$_origin$_myRequestsPath').replace(queryParameters: qp);
// //     final res = await http.get(uri, headers: await _authHeaders());

// //     if (res.statusCode < 200 || res.statusCode >= 300) {
// //       throw Exception('HTTP ${res.statusCode}: ${res.body}');
// //     }

// //     final body = jsonDecode(res.body);
// //     if (body is List) {
// //       return List<Map<String, dynamic>>.from(body.map((e) => Map<String, dynamic>.from(e)));
// //     }
// //     if (body is Map && body['items'] is List) {
// //       return List<Map<String, dynamic>>.from((body['items'] as List).map((e) => Map<String, dynamic>.from(e)));
// //     }
// //     return <Map<String, dynamic>>[];
// //   }

// //   // Optional legacy wrapper
// //   static Future<void> decideAttendance({
// //     required String requestId,
// //     required String empid,
// //     required String date,
// //     required String status,
// //     String? remarks,
// //   }) async {
// //     await decideApproval(item: {'id': requestId, 'empid': empid, 'requestDate': date}, status: status);
// //   }
// // }
// import 'dart:convert';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:http/http.dart' as http;

// // Token set at login
// import 'package:serv_app/models/company_data.dart';

// // Web only (localStorage)
// import 'dart:html' as html;

// class ApiService {
//   static const String _origin = 'http://localhost:3000';
//   static const String _approvalsPath = '/api/attendance/approvals';
//   static const String _myRequestsPath = '/api/attendance/my-requests';

//   // -------------------- auth headers --------------------
//   static Future<Map<String, String>> _authHeaders({bool json = true}) async {
//     String? token = CompanyData.token;
//     if ((token == null || token.isEmpty) && kIsWeb) {
//       try {
//         final t = html.window.localStorage['token'];
//         if (t != null && t.isNotEmpty) token = t;
//       } catch (_) {}
//     }
//     return {
//       if (json) 'Content-Type': 'application/json',
//       if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };
//   }

//   // -------------------- helpers --------------------
//   static String _ymd(DateTime d) =>
//       '${d.year.toString().padLeft(4, '0')}-'
//       '${d.month.toString().padLeft(2, '0')}-'
//       '${d.day.toString().padLeft(2, '0')}';

//   /// Map UI labels to API slugs; return '' to omit the param (e.g. "All")
//   static String _mapType(String? ui) {
//     if (ui == null || ui.trim().isEmpty) return '';
//     switch (ui.trim()) {
//       case 'All':
//       case 'Type':
//         return '';
//       case 'Late check in':
//         return 'late-check-in';
//       case 'Early check out':
//         return 'early-check-out';
//       case 'Leave Type':
//         return 'leave';
//       case 'Permission':
//         return 'permission';
//       case 'Over Time':
//         return 'overtime';
//       case 'Half Day Leave':
//         return 'halfday';
//       case 'Comp Off':
//         return 'compoff';
//       default:
//         return ui.trim();
//     }
//   }

//   static String? _normStatus(String? status) {
//     if (status == null) return null;
//     final s = status.trim().toLowerCase();
//     if (s.isEmpty || s == 'all' || s == 'status') return null;
//     if (s == 'pending') return 'Pending';
//     if (s == 'approved') return 'Approved';
//     if (s == 'rejected') return 'Rejected';
//     return status.trim();
//   }

//   /// Try to infer "attendance" vs "leaves" from item shape or a hint.
//   static String? _inferSource(Map<String, dynamic> item, {String? hintTabOrType}) {
//     // 1) explicit field from backend item
//     final fromItem = (item['source'] ?? item['collection'] ?? item['src'])?.toString().toLowerCase();
//     if (fromItem == 'attendance' || fromItem == 'leaves') return fromItem;

//     // 2) backend "type" or "category" style slugs
//     final t = (item['type'] ?? item['category'] ?? hintTabOrType ?? '').toString().toLowerCase();
//     if (t.contains('late') || t.contains('early') || t.contains('attend')) return 'attendance';
//     if (t.contains('leave') || t.contains('permission') || t.contains('overtime') ||
//         t.contains('halfday') || t.contains('comp')) return 'leaves';

//     // 3) heuristic by known fields
//     if (item.containsKey('checkIn') || item.containsKey('checkOut') || item.containsKey('requestTime')) {
//       return 'attendance';
//     }
//     if (item.containsKey('leaveType') || item.containsKey('reason') || item.containsKey('fromDate') || item.containsKey('toDate')) {
//       return 'leaves';
//     }

//     return null; // unknown
//   }

//   // ======================================================
//   //                      ADMIN
//   // ======================================================

//   /// Fetch approval cards for Admin dashboard.
//   static Future<List<Map<String, dynamic>>> fetchApprovals({
//     required String type,     // UI label
//     required String status,   // Pending | Approved | Rejected | All
//     String? start,            // YYYY-MM-DD
//     String? end,              // YYYY-MM-DD
//   }) async {
//     final qp = <String, String>{
//       if (_mapType(type).isNotEmpty) 'type': _mapType(type),
//       if (_normStatus(status) != null) 'status': _normStatus(status)!,
//       if (start != null && start.isNotEmpty) 'start': start,
//       if (end != null && end.isNotEmpty) 'end': end,
//     };

//     final uri = Uri.parse('$_origin$_approvalsPath').replace(queryParameters: qp);
//     final res = await http.get(uri, headers: await _authHeaders());

//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw Exception('Failed to fetch approvals (${res.statusCode}): ${res.body}');
//     }

//     final body = jsonDecode(res.body);
//     if (body is List) {
//       return List<Map<String, dynamic>>.from(
//         body.map((e) => Map<String, dynamic>.from(e)),
//       );
//     }
//     if (body is Map && body['items'] is List) {
//       return List<Map<String, dynamic>>.from(
//         (body['items'] as List).map((e) => Map<String, dynamic>.from(e)),
//       );
//     }
//     if (body is Map<String, dynamic>) return [body];
//     return <Map<String, dynamic>>[];
//   }

//   /// Approve/Reject by id returned from fetchApprovals().
//   static Future<void> decideApproval({
//     required Map<String, dynamic> item,
//     required String status, // "Approved" | "Rejected" (any case coming in)
//     String? remarks,
//     String? sourceHint,     // "attendance" | "leaves" (optional)
//   }) async {
//     // ---- Normalize to exact strings backend accepts ----
//     final s = status.trim().toLowerCase();
//     final normalizedStatus =
//         (s == 'approve' || s == 'approved') ? 'Approved'
//       : (s == 'reject'  || s == 'rejected') ? 'Rejected'
//       : (() => throw Exception('Decision failed: invalid status "$status"'))();

//     // ---- Determine source ----
//     String? src = sourceHint?.trim().toLowerCase();
//     src ??= _inferSource(item);
//     if (src != 'attendance' && src != 'leaves') {
//       throw Exception('Decision failed: could not determine source (attendance/leaves)');
//     }

//     // ---- Generic id (works for leaves; keep if your backend uses it) ----
//     final genericId = (item['id'] ?? item['docId'] ?? item['requestId'])?.toString();

//     // ---- Attendance identifiers (if needed) ----
//     String? attendanceId = (item['attendanceId'] ?? item['attId'])?.toString();
//     String? empid = (item['empid'] ?? item['empId'] ?? item['employeeId'])?.toString();
//     String? rawDate = (item['requestDate'] ?? item['date'] ?? item['onDate'])?.toString();
//     String? normDate;
//     if (rawDate != null && rawDate.isNotEmpty) {
//       normDate = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
//     }

//     // ---- Build payload ----
//     final payload = <String, dynamic>{
//       if (genericId != null && genericId.isNotEmpty) 'id': genericId,
//       'status': normalizedStatus,   // Title-Case
//       'source': src,
//       if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
//     };

//     // Backend requires attendanceId OR (empid & date) for attendance decisions
//     if (src == 'attendance') {
//       if (attendanceId != null && attendanceId.isNotEmpty) {
//         payload['attendanceId'] = attendanceId;
//       } else if ((empid != null && empid.isNotEmpty) &&
//                  (normDate != null && normDate.isNotEmpty)) {
//         payload['empid'] = empid;
//         payload['date']  = normDate; // YYYY-MM-DD
//       } else {
//         throw Exception('Decision failed: attendanceId or (empid & date) required');
//       }
//     }

//     final uri = Uri.parse('$_origin$_approvalsPath/decision');
//     final res = await http.post(
//       uri,
//       headers: await _authHeaders(),
//       body: jsonEncode(payload),
//     );

//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw Exception('Decision failed (${res.statusCode}): ${res.body}');
//     }
//   }

//   // ======================================================
//   //                      USER
//   // ======================================================

//   /// Logged-in user's own requests in a date window.
//   static Future<List<Map<String, dynamic>>> fetchMyRequests({
//     required DateTime from,
//     required DateTime to,
//     String status = 'All', required String start, required String end,
//   }) async {
//     final qp = <String, String>{
//       'start': _ymd(from),
//       'end': _ymd(to),
//       if (_normStatus(status) != null) 'status': _normStatus(status)!,
//     };

//     final uri = Uri.parse('$_origin$_myRequestsPath').replace(queryParameters: qp);
//     final res = await http.get(uri, headers: await _authHeaders());

//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw Exception('HTTP ${res.statusCode}: ${res.body}');
//     }

//     final body = jsonDecode(res.body);
//     if (body is List) {
//       return List<Map<String, dynamic>>.from(
//         body.map((e) => Map<String, dynamic>.from(e)),
//       );
//     }
//     if (body is Map && body['items'] is List) {
//       return List<Map<String, dynamic>>.from(
//         (body['items'] as List).map((e) => Map<String, dynamic>.from(e)),
//       );
//     }
//     return <Map<String, dynamic>>[];
//   }

//   // Optional legacy wrapper
//   static Future<void> decideAttendance({
//     required String requestId,
//     required String empid,
//     required String date,
//     required String status,
//     String? remarks,
//   }) async {
//     await decideApproval(
//       item: {'id': requestId, 'empid': empid, 'requestDate': date},
//       status: status,
//       remarks: remarks,
//       sourceHint: 'attendance',
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Token set at login
import 'package:serv_app/models/company_data.dart';

// Web only (localStorage)
import 'package:serv_app/html_stub.dart'
  if (dart.library.html) 'package:serv_app/html_web.dart' as html;

class ApiService {
  static const String _origin = 'http://localhost:3000';
  static const String _approvalsPath = '/api/attendance/approvals';
  static const String _myRequestsPath = '/api/attendance/my-requests';

  // -------------------- auth headers --------------------
  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    String? token = CompanyData.token;
    if ((token!.isEmpty) && kIsWeb) {
      try {
        final t = html.window.localStorage['token'];
        if (t != null && t.isNotEmpty) token = t;
      } catch (_) {}
    }
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // -------------------- helpers --------------------
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Map UI labels to API slugs; return '' to omit the param (e.g. "All")
  static String _mapType(String? ui) {
    if (ui == null || ui.trim().isEmpty) return '';
    switch (ui.trim()) {
      case 'All':
      case 'Type':
        return '';
      case 'Late check in':
        return 'late-check-in';
      case 'Early check out':
        return 'early-check-out';
      case 'Leave Type':
        return 'leave';
      case 'Permission':
        return 'permission';
      case 'Over Time':
        return 'overtime';
      case 'Half Day Leave':
        return 'halfday';
      case 'Comp Off':
        return 'compoff';
      default:
        return ui.trim();
    }
  }

  static String? _normStatus(String? status) {
    if (status == null) return null;
    final s = status.trim().toLowerCase();
    if (s.isEmpty || s == 'all' || s == 'status') return null;
    if (s == 'pending') return 'Pending';
    if (s == 'approved') return 'Approved';
    if (s == 'rejected') return 'Rejected';
    return status.trim();
  }

  /// Try to infer "attendance" vs "leaves" from item shape or a hint.
  static String? _inferSource(Map<String, dynamic> item, {String? hintTabOrType}) {
    // 1) explicit field from backend item
    final fromItem = (item['source'] ?? item['collection'] ?? item['src'])?.toString().toLowerCase();
    if (fromItem == 'attendance' || fromItem == 'leaves') return fromItem;

    // 2) backend "type" or "category" style slugs
    final t = (item['type'] ?? item['category'] ?? hintTabOrType ?? '').toString().toLowerCase();
    if (t.contains('late') || t.contains('early') || t.contains('attend')) return 'attendance';
    if (t.contains('leave') || t.contains('permission') || t.contains('overtime') ||
        t.contains('halfday') || t.contains('comp')) {
      return 'leaves';
    }

    // 3) heuristic by known fields
    if (item.containsKey('checkIn') || item.containsKey('checkOut') || item.containsKey('requestTime')) {
      return 'attendance';
    }
    if (item.containsKey('leaveType') || item.containsKey('reason') || item.containsKey('fromDate') || item.containsKey('toDate')) {
      return 'leaves';
    }

    return null; // unknown
  }

  // ======================================================
  //                      ADMIN
  // ======================================================

  /// Fetch approval cards for Admin dashboard.
  static Future<List<Map<String, dynamic>>> fetchApprovals({
    required String type,     // UI label
    required String status,   // Pending | Approved | Rejected | All
    String? start,            // YYYY-MM-DD
    String? end,              // YYYY-MM-DD
  }) async {
    final qp = <String, String>{
      if (_mapType(type).isNotEmpty) 'type': _mapType(type),
      if (_normStatus(status) != null) 'status': _normStatus(status)!,
      if (start != null && start.isNotEmpty) 'start': start,
      if (end != null && end.isNotEmpty) 'end': end,
    };

    final uri = Uri.parse('$_origin$_approvalsPath').replace(queryParameters: qp);
    final res = await http.get(uri, headers: await _authHeaders());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to fetch approvals (${res.statusCode}): ${res.body}');
    }

    final body = jsonDecode(res.body);
    if (body is List) {
      return List<Map<String, dynamic>>.from(body.map((e) => Map<String, dynamic>.from(e)));
    }
    if (body is Map && body['items'] is List) {
      return List<Map<String, dynamic>>.from((body['items'] as List).map((e) => Map<String, dynamic>.from(e)));
    }
    if (body is Map<String, dynamic>) return [body];
    return <Map<String, dynamic>>[];
  }

  /// Approve/Reject by id returned from fetchApprovals().
  static Future<void> decideApproval({
    required Map<String, dynamic> item,
    required String status, // "Approved" | "Rejected" (any case coming in)
    String? remarks,
    String? sourceHint,     // "attendance" | "leaves" (optional)
  }) async {
    // ---- Normalize to exact strings backend accepts ----
    final s = status.trim().toLowerCase();
    final normalizedStatus =
        (s == 'approve' || s == 'approved') ? 'Approved'
      : (s == 'reject'  || s == 'rejected') ? 'Rejected'
      : (() => throw Exception('Decision failed: invalid status "$status"'))();

    // ---- Determine source ----
    String? src = sourceHint?.trim().toLowerCase();
    src ??= _inferSource(item);
    if (src != 'attendance' && src != 'leaves') {
      throw Exception('Decision failed: could not determine source (attendance/leaves)');
    }

    // ---- Common & specific identifiers ----
    final genericId = (item['id'] ?? item['docId'] ?? item['requestId'])?.toString();

    // Attendance identifiers
    String? attendanceId = (item['attendanceId'] ?? item['attId'])?.toString();
    String? empid = (item['empid'] ?? item['empId'] ?? item['employeeId'])?.toString();
    String? rawDate = (item['requestDate'] ?? item['date'] ?? item['onDate'])?.toString();
    String? normDate;
    if (rawDate != null && rawDate.isNotEmpty) {
      normDate = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    }

    // Leaves identifiers
    String? leaveId = (item['leaveId'] ?? item['leave_id'] ?? item['requestId'] ?? item['id'])?.toString();

    // ---- Build payload ----
    final payload = <String, dynamic>{
      if (genericId != null && genericId.isNotEmpty) 'id': genericId, // harmless for most backends
      'status': normalizedStatus,
      'source': src,
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    };

    if (src == 'attendance') {
      // Backend requires attendanceId OR (empid & date)
      if (attendanceId != null && attendanceId.isNotEmpty) {
        payload['attendanceId'] = attendanceId;
      } else if ((empid != null && empid.isNotEmpty) &&
                 (normDate != null && normDate.isNotEmpty)) {
        payload['empid'] = empid;
        payload['date']  = normDate; // YYYY-MM-DD
      } else {
        throw Exception('Decision failed: attendanceId or (empid & date) required');
      }
    } else {
      // src == 'leaves' => Backend expects leaveId
      if (leaveId == null || leaveId.isEmpty) {
        throw Exception('Decision failed: leaveId required');
      }
      payload['leaveId'] = leaveId;
    }

    final uri = Uri.parse('$_origin$_approvalsPath/decision');
    final res = await http.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Decision failed (${res.statusCode}): ${res.body}');
    }
  }

  // ======================================================
  //                      USER
  // ======================================================

  /// Logged-in user's own requests in a date window.
  static Future<List<Map<String, dynamic>>> fetchMyRequests({
    required DateTime from,
    required DateTime to,
    String status = 'All', required String start, required String end,
  }) async {
    final qp = <String, String>{
      'start': _ymd(from),
      'end': _ymd(to),
      if (_normStatus(status) != null) 'status': _normStatus(status)!,
    };

    final uri = Uri.parse('$_origin$_myRequestsPath').replace(queryParameters: qp);
    final res = await http.get(uri, headers: await _authHeaders());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);
    if (body is List) {
      return List<Map<String, dynamic>>.from(body.map((e) => Map<String, dynamic>.from(e)));
    }
    if (body is Map && body['items'] is List) {
      return List<Map<String, dynamic>>.from((body['items'] as List).map((e) => Map<String, dynamic>.from(e)));
    }
    return <Map<String, dynamic>>[];
  }

  // Optional legacy wrapper
  static Future<void> decideAttendance({
    required String requestId,
    required String empid,
    required String date,
    required String status,
    String? remarks,
  }) async {
    await decideApproval(
      item: {'id': requestId, 'empid': empid, 'requestDate': date},
      status: status,
      remarks: remarks,
      sourceHint: 'attendance',
    );
  }
}
