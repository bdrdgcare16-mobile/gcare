import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static const List<String> _approvalsPaths = [
    '/attendance/approvals',
  ];

  static const String _otherLocPath = '/attendance/other-location';
  static const String _otherLocDecisionPath =
      '/attendance/other-location/decision';
  static const String _myRequestsPath = '/attendance/my-requests';

  static String? _cachedToken;

  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    String? token = CompanyData.token ?? _cachedToken;

    if ((token == null || token.isEmpty) && kIsWeb) {
      try {
        final t1 = html.window.localStorage['token'];
        final t2 = html.window.sessionStorage['token'];
        token = (t1 != null && t1.isNotEmpty) ? t1 : (t2 ?? token);
      } catch (_) {}
    }

    _cachedToken = token;

    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Exception _friendlyNetworkError(Object e) {
    const msg =
        'Network unavailable. Please check your connection and try again.';

    if (e is TimeoutException ||
        e is SocketException ||
        e is HandshakeException) {
      return Exception(msg);
    }

    if (e is http.ClientException &&
        (e.message.contains('Failed host lookup') ||
            e.message.contains('No address associated with hostname'))) {
      return Exception(msg);
    }

    return Exception(msg);
  }

  static Future<http.Response> _safeGet(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      return await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 500));
      return await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    }
  }

  static Future<http.Response> _safePost(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      return await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw _friendlyNetworkError(e);
    }
  }

  static Future<http.Response> _safePatch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      return await http
          .patch(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw _friendlyNetworkError(e);
    }
  }

  static Future<http.Response> _safePut(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      return await http
          .put(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw _friendlyNetworkError(e);
    }
  }

  static Future<http.Response> _safeDelete(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      return await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw _friendlyNetworkError(e);
    }
  }

  static String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _mapTypeForServer(String? uiOrCode) {
    if (uiOrCode == null) return '';
    final raw = uiOrCode.trim();
    if (raw.isEmpty) return '';

    final lower = raw.toLowerCase();

    if (lower == 'other location' ||
        lower == 'other_location' ||
        lower == 'other-location' ||
        lower.contains('attendance:other_location')) {
      return '';
    }

    switch (lower) {
      case 'all':
      case 'type':
        return '';
      case 'late check in':
        return 'late check in';
      case 'early check out':
        return 'early check out';
      case 'leave type':
        return 'leave type';
      case 'permission':
        return 'permission';
      case 'over time':
        return 'over time';
      case 'half day leave':
        return 'half day leave';
      case 'comp off':
        return 'comp off';
      default:
        return raw;
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

  static List<Map<String, dynamic>> _listFromBody(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (body is Map) {
      final data = body['data'];
      final items = body['items'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  static String? _inferSource(Map<String, dynamic> item, {String? hint}) {
    final fromItem = (item['source'] ?? item['collection'] ?? item['src'])
        ?.toString()
        .toLowerCase();

    if (fromItem == 'attendance' || fromItem == 'leaves') return fromItem;

    final t = (item['type'] ?? item['category'] ?? hint ?? '')
        .toString()
        .toLowerCase();

    if (t.contains('late') ||
        t.contains('early') ||
        t.contains('attend') ||
        t.contains('other location')) {
      return 'attendance';
    }

    if (t.contains('leave') ||
        t.contains('permission') ||
        t.contains('over time') ||
        t.contains('half') ||
        t.contains('comp')) {
      return 'leaves';
    }

    if (item.containsKey('checkIn') ||
        item.containsKey('checkOut') ||
        item.containsKey('requestTime')) {
      return 'attendance';
    }

    if (item.containsKey('leaveType') ||
        item.containsKey('fromDate') ||
        item.containsKey('toDate')) {
      return 'leaves';
    }

    return null;
  }

  static bool _ok(http.Response r) => r.statusCode >= 200 && r.statusCode < 300;
  static bool _is404(http.Response r) => r.statusCode == 404;

  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? query,
    Map<String, String>? queryParameters,
    bool authRequired = true,
  }) async {
    final headers = authRequired
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};
    final queryParams = query ?? queryParameters;
    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    return _safeGet(uri, headers: headers);
  }

  static Future<http.Response> post(
    String endpoint, {
    Map<String, String>? query,
    Object? body,
    bool authRequired = true,
  }) async {
    final headers = authRequired
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: query);
    return _safePost(uri, headers: headers, body: body);
  }

  static Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? query,
    Object? body,
    bool authRequired = true,
  }) async {
    final headers = authRequired
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: query);
    return _safePatch(uri, headers: headers, body: body);
  }

  static Future<http.Response> put(
    String endpoint, {
    Map<String, String>? query,
    Object? body,
    bool authRequired = true,
  }) async {
    final headers = authRequired
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: query);
    return _safePut(uri, headers: headers, body: body);
  }

  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? query,
    bool authRequired = true,
  }) async {
    final headers = authRequired
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: query);
    return _safeDelete(uri, headers: headers);
  }

  static Future<http.Response> _getWithFallback(
    List<String> paths, {
    Map<String, String>? query,
  }) async {
    http.Response? last;

    for (final path in paths) {
      final response = await get(path, query: query);
      last = response;
      if (_ok(response)) return response;
    }

    return last!;
  }

  static Future<http.Response> _postWithFallback(
    List<String> paths, {
    Map<String, String>? query,
    Object? body,
  }) async {
    http.Response? last;

    for (final path in paths) {
      final response = await post(path, query: query, body: body);
      last = response;
      if (_ok(response)) return response;
    }

    return last!;
  }

  static Future<List<Map<String, dynamic>>> fetchApprovals({
    required String type,
    required String status,
    String? start,
    String? end,
    int limit = 50,
  }) async {
    final page = await fetchApprovalsPaginated(
      type: type,
      status: status,
      start: start,
      end: end,
      page: 1,
      limit: limit,
    );
    return page.data;
  }

  static Future<ApprovalsPage> fetchApprovalsPaginated({
    required String type,
    required String status,
    String? start,
    String? end,
    String? search,
    String? branch,
    int page = 1,
    int limit = 20,
  }) async {
    final mappedType = _mapTypeForServer(type);

    final qp = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (mappedType.isNotEmpty) 'type': mappedType,
      'status': _normStatus(status) ?? 'All',
      if (start != null && start.isNotEmpty) 'start': start,
      if (end != null && end.isNotEmpty) 'end': end,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (branch != null && branch.trim().isNotEmpty) 'branch': branch.trim(),
    };

    final res = await _getWithFallback(_approvalsPaths, query: qp);

    if (!_ok(res)) {
      throw Exception('Failed to fetch approvals (${res.statusCode})');
    }

    final body = json.decode(res.body);
    final data = _listFromBody(body);

    final pagination = body is Map && body['pagination'] is Map
        ? Map<String, dynamic>.from(body['pagination'])
        : <String, dynamic>{
            'page': page,
            'limit': limit,
            'total': data.length,
            'hasMore': false,
          };

    final totals = body is Map && body['totals'] is Map
        ? Map<String, int>.from(
            (body['totals'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
            ),
          )
        : <String, int>{};

    return ApprovalsPage(data: data, pagination: pagination, totals: totals);
  }

  static Future<List<Map<String, dynamic>>> fetchOtherLocation({
    required String status,
    String? start,
    String? end,
  }) async {
    final qp = <String, String>{
      'limit': '50',
      'status': (_normStatus(status) ?? 'All'),
      if (start != null && start.isNotEmpty) 'start': start,
      if (end != null && end.isNotEmpty) 'end': end,
    };

    final first = await get(_otherLocPath, query: qp);

    if (_ok(first)) {
      final body = jsonDecode(first.body);
      return _listFromBody(body);
    }

    if (_is404(first)) {
      final aggQp = <String, String>{
        'type': 'attendance:other_location',
        if (_normStatus(status) != null) 'status': _normStatus(status)!,
        if (start != null && start.isNotEmpty) 'start': start,
        if (end != null && end.isNotEmpty) 'end': end,
      };

      final res = await _getWithFallback(_approvalsPaths, query: aggQp);

      if (!_ok(res)) {
        throw Exception(
          'Failed to fetch other-location via fallback (${res.statusCode}): ${res.body}',
        );
      }

      final body = json.decode(res.body);
      return _listFromBody(body);
    }

    throw Exception(
      'Failed to fetch other-location (${first.statusCode}): ${first.body}',
    );
  }

  static Future<void> decideApproval({
    required Map<String, dynamic> item,
    required String status,
    String? remarks,
    String? sourceHint,
    String? leavePayType,
  }) async {
    final s = status.trim().toLowerCase();

    final normalizedStatus = (s == 'approve' || s == 'approved')
        ? 'Approved'
        : (s == 'reject' || s == 'rejected')
            ? 'Rejected'
            : (throw Exception('Decision failed: invalid status "$status"'));

    String? src = sourceHint?.trim().toLowerCase();
    src ??= _inferSource(item);

    if (src != 'attendance' && src != 'leaves') {
      throw Exception(
        'Decision failed: could not determine source (attendance/leaves)',
      );
    }

    final payload = <String, dynamic>{
      'status': normalizedStatus,
      'source': src,
      if (remarks != null && remarks.trim().isNotEmpty)
        'remarks': remarks.trim(),
    };

    // Add leavePayType for leave requests
    if (src == 'leaves') {
      if (normalizedStatus == 'Approved' && leavePayType != null) {
        final normalizedLeavePayType = leavePayType.trim().toLowerCase();
        if (normalizedLeavePayType == 'paid' ||
            normalizedLeavePayType == 'unpaid') {
          payload['leavePayType'] = normalizedLeavePayType;
        }
      } else if (normalizedStatus == 'Rejected') {
        // Clear leavePayType for rejected leaves
        payload['leavePayType'] = null;
      }
    }

    final genericId =
        (item['id'] ?? item['docId'] ?? item['requestId'])?.toString();

    if (genericId != null && genericId.isNotEmpty) {
      payload['id'] = genericId;
    }

    if (src == 'attendance') {
      final attendanceId = (item['attendanceId'] ?? item['attId'])?.toString();
      final empid =
          (item['empid'] ?? item['empId'] ?? item['employeeId'])?.toString();
      final rawDate =
          (item['requestDate'] ?? item['date'] ?? item['onDate'])?.toString();

      String? normDate;
      if (rawDate != null && rawDate.isNotEmpty) {
        normDate = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
      }

      if (attendanceId != null && attendanceId.isNotEmpty) {
        payload['attendanceId'] = attendanceId;
      } else if ((empid != null && empid.isNotEmpty) &&
          (normDate != null && normDate.isNotEmpty)) {
        payload['empid'] = empid;
        payload['date'] = normDate;
      }
    } else {
      final leaveId = (item['leaveId'] ??
              item['leave_id'] ??
              item['requestId'] ??
              item['id'])
          ?.toString();

      if (leaveId == null || leaveId.isEmpty) {
        throw Exception('Decision failed: leaveId required');
      }

      payload['leaveId'] = leaveId;
    }

    final res = await _postWithFallback(
      _approvalsPaths.map((p) => '$p/decision').toList(),
      body: jsonEncode(payload),
    );

    if (!_ok(res)) {
      throw Exception('Decision failed (${res.statusCode}): ${res.body}');
    }
  }

  static Future<void> decideOtherLocation({
    required String id,
    required String status,
    String? remarks,
  }) async {
    final s = status.trim().toLowerCase();

    final normalizedStatus = (s == 'approve' || s == 'approved')
        ? 'Approved'
        : (s == 'reject' || s == 'rejected')
            ? 'Rejected'
            : (throw Exception('Decision failed: invalid status "$status"'));

    final first = await post(
      _otherLocDecisionPath,
      body: jsonEncode({
        'id': id,
        'status': normalizedStatus,
        if (remarks != null && remarks.trim().isNotEmpty)
          'remarks': remarks.trim(),
      }),
    );

    if (_ok(first)) return;

    if (_is404(first)) {
      await decideApproval(
        item: {'id': id, 'source': 'attendance'},
        status: normalizedStatus,
        remarks: remarks,
        sourceHint: 'attendance',
      );
      return;
    }

    throw Exception('Decision failed (${first.statusCode}): ${first.body}');
  }

  static Future<List<Map<String, dynamic>>> fetchMyRequests({
    required DateTime from,
    required DateTime to,
    String status = 'All',
    int? limit,
  }) async {
    final qp = <String, String>{
      'start': _ymd(from),
      'end': _ymd(to),
      if (_normStatus(status) != null) 'status': _normStatus(status)!,
      if (limit != null) 'limit': limit.toString(),
    };

    final res = await get(_myRequestsPath, query: qp);

    if (!_ok(res)) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = json.decode(res.body);

    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (body is Map && body['items'] is List) {
      return (body['items'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  static Future<Map<String, dynamic>> fetchRequestDetails({
    String? id,
    String? src,
    String? empid,
    String? date,
  }) async {
    final qp = <String, String>{
      if (id != null && id.isNotEmpty) 'id': id,
      if (src != null && src.isNotEmpty) 'src': src,
      if (empid != null && empid.isNotEmpty) 'empid': empid,
      if (date != null && date.isNotEmpty) 'date': date,
    };

    final res = await get('/attendance/request-details', query: qp);

    if (res.statusCode == 404) {
      return <String, dynamic>{};
    }

    if (_ok(res)) {
      final body = json.decode(res.body);
      return (body is Map)
          ? Map<String, dynamic>.from(body)
          : <String, dynamic>{};
    }

    throw Exception('details ${res.statusCode}: ${res.body}');
  }

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

  static Future<Map<String, dynamic>> fetchLiveEmployeeDetails({
    required String empid,
    required String dateIso,
  }) async {
    final res = await get(
      '/liveEmployeeDetails/$empid',
      query: {'dateIso': dateIso},
    );

    if (!_ok(res)) {
      throw Exception('liveEmployeeDetails ${res.statusCode}: ${res.body}');
    }

    final body = json.decode(res.body);

    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data']);
    }

    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> fetchTrackingDay({
    required String empid,
    required String dateIso,
  }) async {
    final headers = await _authHeaders();

    final uri = Uri.parse('$baseUrl/tracking/day')
        .replace(queryParameters: {'dateIso': dateIso});

    final res = await _safeGet(uri, headers: headers);

    if (!_ok(res)) {
      throw Exception('tracking/day ${res.statusCode}: ${res.body}');
    }

    final body = json.decode(res.body);

    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data']);
    }

    return <String, dynamic>{};
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}

    return response.body.isNotEmpty
        ? response.body
        : 'Request failed. Please try again.';
  }

  static Future<List<Map<String, dynamic>>> fetchAttendanceApprovals({
    String? status,
  }) async {
    return fetchApprovals(type: 'All', status: status ?? 'All');
  }

  static Future<List<Map<String, dynamic>>> fetchLeaveApprovals({
    String? status,
  }) async {
    return fetchApprovals(type: 'All', status: status ?? 'All');
  }

  static Future<List<Map<String, dynamic>>> fetchOtherLocationApprovals({
    String? status,
  }) async {
    final page = await fetchOtherLocationApprovalsPaginated(
      status: status ?? 'All',
      page: 1,
      limit: 50,
    );
    return page.data;
  }

  static Future<ApprovalsPage> fetchOtherLocationApprovalsPaginated({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'status': _normStatus(status) ?? 'All',
    };

    final response = await get(_otherLocPath, query: qp);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = _listFromBody(body);
      final pagination = body is Map && body['pagination'] is Map
          ? Map<String, dynamic>.from(body['pagination'])
          : <String, dynamic>{
              'page': page,
              'limit': limit,
              'total': data.length,
              'hasMore': false,
            };
      return ApprovalsPage(data: data, pagination: pagination);
    }

    throw Exception(
      'Other location approvals ${response.statusCode}: ${_extractErrorMessage(response)}',
    );
  }

  static Future<Map<String, dynamic>> updatePayroll({
    required String payrollId,
    required int workedDays,
    required int lopDays,
    required List<Map<String, dynamic>> allowances,
  }) async {
    final response = await patch(
      '/payroll/$payrollId',
      body: jsonEncode({
        'workedDays': workedDays,
        'lopDays': lopDays,
        'allowances': allowances,
      }),
    );

    final body = jsonDecode(response.body);
    if (!_ok(response)) {
      throw Exception(
        body is Map && body['message'] != null
            ? body['message'].toString()
            : 'Failed to update payroll (${response.statusCode})',
      );
    }

    return body is Map<String, dynamic>
        ? body
        : <String, dynamic>{'success': true, 'data': body};
  }

  static Future<Map<String, dynamic>?> fetchOnboardingByEmpId(
    String empid,
  ) async {
    final res = await get('/onboarding/by-empid/$empid');

    if (res.statusCode == 404) return null;

    if (!_ok(res)) {
      throw Exception(
        'Failed to fetch onboarding (${res.statusCode})',
      );
    }

    final body = jsonDecode(res.body);
    if (body is Map && body['success'] == true && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }

    return null;
  }

  // legacy payroll helper removed; use `decideApproval` and `leavePayType`.
}

class ApprovalsPage {
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic> pagination;
  final Map<String, int> totals;

  const ApprovalsPage({
    required this.data,
    required this.pagination,
    this.totals = const <String, int>{},
  });

  int get total => (pagination['total'] as num?)?.toInt() ?? data.length;
  bool get hasMore => pagination['hasMore'] == true;
}
