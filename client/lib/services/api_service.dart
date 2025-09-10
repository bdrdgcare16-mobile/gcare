import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Token set at login
import 'package:serv_app/models/company_data.dart';

// Web only (localStorage)
import 'package:serv_app/html_stub.dart'
  if (dart.library.html) 'package:serv_app/html_web.dart' as html;

/// Single source of truth for API base.
/// Override in dev with:
/// flutter run --dart-define=API_BASE=http://localhost:3000/api
const String _defaultApiBase = 'https://api-zmj7dqloiq-uc.a.run.app/api';
const String apiBase =
    String.fromEnvironment('API_BASE', defaultValue: _defaultApiBase);

class ApiService {
  /// Prefer top-level approvals route. If the server doesn't have it,
  /// we transparently fall back to the legacy attendance-scoped route.
  static const List<String> _approvalsPaths = [
    '/approvals',
    '/attendance/approvals',
  ];

  static const String _myRequestsPath = '/attendance/my-requests';

  // -------------------- auth headers --------------------
  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    String? token = CompanyData.token;

    // For web, try localStorage fallback if the in-memory token is missing
    if ((token == null || token.isEmpty) && kIsWeb) {
      try {
        final t = html.window.localStorage['token'];
        if (t != null && t.isNotEmpty) token = t;
      } catch (_) {
        // ignore
      }
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
    final fromItem =
        (item['source'] ?? item['collection'] ?? item['src'])?.toString().toLowerCase();
    if (fromItem == 'attendance' || fromItem == 'leaves') return fromItem;

    // 2) backend "type" or "category" style slugs
    final t = (item['type'] ?? item['category'] ?? hintTabOrType ?? '')
        .toString()
        .toLowerCase();
    if (t.contains('late') || t.contains('early') || t.contains('attend')) {
      return 'attendance';
    }
    if (t.contains('leave') ||
        t.contains('permission') ||
        t.contains('overtime') ||
        t.contains('halfday') ||
        t.contains('comp')) {
      return 'leaves';
    }

    // 3) heuristic by known fields
    if (item.containsKey('checkIn') ||
        item.containsKey('checkOut') ||
        item.containsKey('requestTime')) {
      return 'attendance';
    }
    if (item.containsKey('leaveType') ||
        item.containsKey('reason') ||
        item.containsKey('fromDate') ||
        item.containsKey('toDate')) {
      return 'leaves';
    }

    return null; // unknown
  }

  // -------------------- internal HTTP helpers with fallback --------------------

  static Future<http.Response> _getWithFallback(
    List<String> paths, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    headers ??= await _authHeaders();
    for (final p in paths) {
      final uri = Uri.parse('$apiBase$p').replace(queryParameters: query);
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode != 404) return resp; // success or other error -> stop
    }
    // If all were 404, return the last attempt’s response
    final uri = Uri.parse('$apiBase${paths.last}').replace(queryParameters: query);
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> _postWithFallback(
    List<String> paths, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Object? body,
  }) async {
    headers ??= await _authHeaders();
    for (final p in paths) {
      final uri = Uri.parse('$apiBase$p').replace(queryParameters: query);
      final resp = await http.post(uri, headers: headers, body: body);
      if (resp.statusCode != 404) return resp;
    }
    final uri = Uri.parse('$apiBase${paths.last}').replace(queryParameters: query);
    return http.post(uri, headers: headers, body: body);
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

    final res = await _getWithFallback(_approvalsPaths, query: qp);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to fetch approvals (${res.statusCode}): ${res.body}');
    }

    final body = jsonDecode(res.body);
    if (body is List) {
      return List<Map<String, dynamic>>.from(
          body.map((e) => Map<String, dynamic>.from(e)));
    }
    if (body is Map && body['items'] is List) {
      return List<Map<String, dynamic>>.from(
          (body['items'] as List).map((e) => Map<String, dynamic>.from(e)));
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
        (s == 'approve' || s == 'approved')
            ? 'Approved'
            : (s == 'reject' || s == 'rejected')
                ? 'Rejected'
                : (throw Exception('Decision failed: invalid status "$status"'));

    // ---- Determine source ----
    String? src = sourceHint?.trim().toLowerCase();
    src ??= _inferSource(item);
    if (src != 'attendance' && src != 'leaves') {
      throw Exception('Decision failed: could not determine source (attendance/leaves)');
    }

    // ---- Common & specific identifiers ----
    final genericId =
        (item['id'] ?? item['docId'] ?? item['requestId'])?.toString();

    // Attendance identifiers
    String? attendanceId =
        (item['attendanceId'] ?? item['attId'])?.toString();
    String? empid =
        (item['empid'] ?? item['empId'] ?? item['employeeId'])?.toString();
    String? rawDate =
        (item['requestDate'] ?? item['date'] ?? item['onDate'])?.toString();
    String? normDate;
    if (rawDate != null && rawDate.isNotEmpty) {
      normDate = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    }

    // Leaves identifiers
    String? leaveId =
        (item['leaveId'] ?? item['leave_id'] ?? item['requestId'] ?? item['id'])
            ?.toString();

    // ---- Build payload ----
    final payload = <String, dynamic>{
      if (genericId != null && genericId.isNotEmpty) 'id': genericId,
      'status': normalizedStatus,
      'source': src,
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    };

    if (src == 'attendance') {
      if (attendanceId != null && attendanceId.isNotEmpty) {
        payload['attendanceId'] = attendanceId;
      } else if ((empid != null && empid.isNotEmpty) &&
          (normDate != null && normDate.isNotEmpty)) {
        payload['empid'] = empid;
        payload['date'] = normDate; // YYYY-MM-DD
      } else {
        throw Exception('Decision failed: attendanceId or (empid & date) required');
      }
    } else {
      if (leaveId == null || leaveId.isEmpty) {
        throw Exception('Decision failed: leaveId required');
      }
      payload['leaveId'] = leaveId;
    }

    final res = await _postWithFallback(
      _approvalsPaths.map((p) => '$p/decision').toList(),
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
    String status = 'All',
  }) async {
    final qp = <String, String>{
      'start': _ymd(from),
      'end': _ymd(to),
      if (_normStatus(status) != null) 'status': _normStatus(status)!,
    };

    final uri = Uri.parse('$apiBase$_myRequestsPath').replace(queryParameters: qp);
    final res = await http.get(uri, headers: await _authHeaders());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);
    if (body is List) {
      return List<Map<String, dynamic>>.from(
          body.map((e) => Map<String, dynamic>.from(e)));
    }
    if (body is Map && body['items'] is List) {
      return List<Map<String, dynamic>>.from(
          (body['items'] as List).map((e) => Map<String, dynamic>.from(e)));
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

  // Generic GET helper (kept for convenience)
  static Future<T> getJson<T>(
    String path, {
    Map<String, String>? query,
    T Function(dynamic json)? parse,
  }) async {
    final uri = Uri.parse('$apiBase$path').replace(queryParameters: query);
    final resp = await http.get(uri, headers: await _authHeaders());
    if (resp.statusCode != 200) {
      throw Exception('GET $path -> ${resp.statusCode}: ${resp.body}');
    }
    final decoded = jsonDecode(resp.body);
    return parse != null ? parse(decoded) : decoded as T;
  }
}
