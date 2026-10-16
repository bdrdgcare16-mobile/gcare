import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

/// API client for the HR-owned company policy endpoints.
/// Routes live under /api/hr/company-policy and require an authenticated
/// JWT with role 'hr'. companyId is derived server-side from the token —
/// the client never sends it.
///
/// Policy state is the source of truth for the "policy published" gate in
/// the HR flow (backend, not local storage — works across devices).
class HrCompanyPolicyService {
  static String get _base => '${ApiService.baseUrl}/hr/company-policy';

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

  /// GET /api/hr/company-policy
  /// Returns { 'policy': Map|null, 'hasPublished': bool,
  ///           'latestPublishedVersion': int? }.
  /// `policy` is the working copy — the draft when one exists, else the
  /// latest published version.
  static Future<Map<String, dynamic>> getCompanyPolicy() async {
    final res = await http.get(Uri.parse(_base), headers: _headers());
    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load company policy');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) {
      return {'policy': null, 'hasPublished': false};
    }
    return {
      'policy': body['policy'] is Map
          ? Map<String, dynamic>.from(body['policy'] as Map)
          : null,
      'hasPublished': body['hasPublished'] == true,
      'latestPublishedVersion': body['latestPublishedVersion'],
    };
  }

  /// POST /api/hr/company-policy — save draft (creates v1, updates an
  /// existing draft in place, or opens v(n+1) draft over a published
  /// version). Returns the saved version map.
  static Future<Map<String, dynamic>> saveCompanyPolicy({
    required String title,
    required String content,
  }) async {
    final res = await http.post(
      Uri.parse(_base),
      headers: _headers(),
      body: jsonEncode({'title': title, 'content': content}),
    );
    final body = jsonDecode(res.body);
    if ((res.statusCode == 200 || res.statusCode == 201) &&
        body is Map &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body);
    }
    throw _errorFrom(res, 'Failed to save policy');
  }

  /// POST /api/hr/company-policy/publish — publishes the current draft.
  /// Returns the published version map.
  static Future<Map<String, dynamic>> publishCompanyPolicy() async {
    final res = await http.post(
      Uri.parse('$_base/publish'),
      headers: _headers(),
    );
    final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['success'] == true) {
      return Map<String, dynamic>.from(body);
    }
    throw _errorFrom(res, 'Failed to publish policy');
  }
}
