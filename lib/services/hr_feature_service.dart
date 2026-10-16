import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

/// API client for the HR self-service feature-request endpoints.
/// Routes live under /api/hr and require an authenticated JWT with
/// role 'hr' — enforced server-side by roleMiddleware(['hr']).
///
/// Data separation:
///  - companies.enabledFeatures   = company-level list chosen by the
///    Platform Admin; this is what /features/available returns.
///  - hrFeatureRequests.requestedFeatures = this HR's pending request.
///  - hrFeatureRequests.approvedFeatures  = approved set; the only source
///    of HR module visibility once approved.
class HrFeatureService {
  static String get _base => '${ApiService.baseUrl}/hr';

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

  /// GET /api/hr/features/available
  /// Company-level features the Platform Admin enabled; features not
  /// enabled are omitted entirely (hidden, not disabled).
  /// Returns [{key, label, requires: []}].
  static Future<List<Map<String, dynamic>>> getAvailableFeatures() async {
    final res = await http.get(
      Uri.parse('$_base/features/available'),
      headers: _headers(),
    );
    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load available features');
    }
    final body = jsonDecode(res.body);
    final list = body is Map && body['features'] is List
        ? body['features'] as List
        : <dynamic>[];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// GET /api/hr/feature-request
  /// Returns { 'request': Map|null, 'hr': {name,email,branch,department} }.
  static Future<Map<String, dynamic>> getMyRequest() async {
    final res = await http.get(
      Uri.parse('$_base/feature-request'),
      headers: _headers(),
    );
    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load feature request');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) return {'request': null, 'hr': <String, dynamic>{}};
    return {
      'request': body['request'] is Map
          ? Map<String, dynamic>.from(body['request'] as Map)
          : null,
      'hr': body['hr'] is Map
          ? Map<String, dynamic>.from(body['hr'] as Map)
          : <String, dynamic>{},
    };
  }

  /// POST /api/hr/feature-request — submit or resubmit (after a
  /// changes_requested review). Returns the stored request map.
  static Future<Map<String, dynamic>> submitRequest({
    required List<String> requestedFeatures,
    required String branch,
    required String department,
    String? branchId,
    String? departmentId,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/feature-request'),
      headers: _headers(),
      body: jsonEncode({
        'requestedFeatures': requestedFeatures,
        'branch': branch,
        'department': department,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (departmentId != null && departmentId.isNotEmpty)
          'departmentId': departmentId,
      }),
    );

    final body = jsonDecode(res.body);
    if ((res.statusCode == 200 || res.statusCode == 201) &&
        body is Map &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body);
    }
    throw _errorFrom(res, 'Failed to submit feature request');
  }

  /// GET /api/hr/features/approved — the authorization source of truth.
  /// Returns {
  ///   'approvedFeatures':   [...]  stored approved set (admin-granted)
  ///   'accessibleFeatures': [...]  approved + dependency closure; this is
  ///                               what the backend allows and what the
  ///                               dashboard must render.
  /// }
  static Future<Map<String, dynamic>> getApprovedFeatures() async {
    final res = await http.get(
      Uri.parse('$_base/features/approved'),
      headers: _headers(),
    );
    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load approved features');
    }
    final body = jsonDecode(res.body);
    List<String> listOf(String k) => body is Map && body[k] is List
        ? (body[k] as List).map((e) => e.toString()).toList()
        : <String>[];
    return {
      'approvedFeatures': listOf('approvedFeatures'),
      'accessibleFeatures': listOf('accessibleFeatures'),
    };
  }

  /// GET /api/hr/modules/:feature — feature-gated module endpoint.
  /// The backend returns 403 unless the feature is in this HR user's
  /// approvedFeatures (checked server-side — UI visibility is not access).
  static Future<Map<String, dynamic>> getModule(String featureKey) async {
    final res = await http.get(
      Uri.parse('$_base/modules/$featureKey'),
      headers: _headers(),
    );
    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Module not accessible');
    }
    final body = jsonDecode(res.body);
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }
}
