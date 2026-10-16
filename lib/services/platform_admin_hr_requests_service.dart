// lib/services/platform_admin_hr_requests_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/models/company_data.dart';

/// API client for the Platform Admin HR feature-request review endpoints.
/// All calls hit /api/platform/hr-feature-requests*, which requires an
/// authenticated platform_admin JWT (roleMiddleware, server-side).
class PlatformAdminHrRequestsService {
  PlatformAdminHrRequestsService._();

  static final PlatformAdminHrRequestsService instance =
      PlatformAdminHrRequestsService._();

  static String get _base => '${ApiConfig.baseUrl}/platform/hr-feature-requests';

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (CompanyData.token.isNotEmpty)
          'Authorization': 'Bearer ${CompanyData.token}',
      };

  static Exception _errorFrom(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      final msg = body is Map
          ? (body['error'] ?? body['message'] ?? fallback)
          : fallback;
      return Exception(msg.toString());
    } catch (_) {
      return Exception('$fallback (${res.statusCode})');
    }
  }

  /// GET /api/platform/hr-feature-requests?status=&companyId=
  Future<List<Map<String, dynamic>>> listRequests({
    String? status,
    String? companyId,
  }) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
      },
    );
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load HR feature requests');
    }
    final body = jsonDecode(res.body);
    final list = body is Map && body['requests'] is List
        ? body['requests'] as List
        : <dynamic>[];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// GET /api/platform/hr-feature-requests/:requestId
  /// Returns {request, company, hrUser}.
  Future<Map<String, dynamic>> getRequest(String requestId) async {
    final res = await http
        .get(Uri.parse('$_base/$requestId'), headers: _headers())
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load feature request');
    }
    final body = jsonDecode(res.body);
    if (body is Map) return Map<String, dynamic>.from(body);
    throw Exception('Invalid feature request response');
  }

  /// POST .../approve — grants the requested features to the HR user only.
  Future<Map<String, dynamic>> approve(String requestId) =>
      _review(requestId, 'approve');

  /// POST .../request-changes — requires a review comment.
  Future<Map<String, dynamic>> requestChanges(
    String requestId,
    String reviewComment,
  ) =>
      _review(requestId, 'request-changes', reviewComment: reviewComment);

  /// POST .../reject — requires a review comment.
  Future<Map<String, dynamic>> reject(
    String requestId,
    String reviewComment,
  ) =>
      _review(requestId, 'reject', reviewComment: reviewComment);

  Future<Map<String, dynamic>> _review(
    String requestId,
    String action, {
    String? reviewComment,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/$requestId/$action'),
          headers: _headers(),
          body: jsonEncode({
            if (reviewComment != null) 'reviewComment': reviewComment,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && body is Map) {
      return Map<String, dynamic>.from(body);
    }
    throw _errorFrom(res, 'Review action failed');
  }
}
