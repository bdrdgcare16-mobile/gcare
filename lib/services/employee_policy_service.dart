import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

/// Thrown when the employee tries to acknowledge a version that is no
/// longer the latest published one (HTTP 409). The caller should reload
/// the policy and prompt the employee to acknowledge the current version.
class PolicyVersionStaleException implements Exception {
  final String message;
  final int? latestPublishedVersion;
  const PolicyVersionStaleException(this.message, {this.latestPublishedVersion});

  @override
  String toString() => message;
}

/// API client for the employee company-policy endpoints.
/// Routes live under /api/employee/company-policy and require an
/// authenticated JWT with role 'employee'. companyId and employee
/// identity are derived server-side from the token — the client never
/// sends them.
///
/// The backend acknowledgement record (policyAcknowledgements) is the
/// source of truth — no local flags are used for authorization.
class EmployeePolicyService {
  static String get _base => '${ApiService.baseUrl}/employee/company-policy';

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

  /// GET /api/employee/company-policy
  /// Returns {
  ///   'hasPublishedPolicy': bool,
  ///   'policy': {version, title, content, publishedAt}|null,
  ///   'acknowledged': bool,
  /// }
  static Future<Map<String, dynamic>> getCurrentPolicy() async {
    final res = await http.get(Uri.parse(_base), headers: _headers());
    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load company policy');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) {
      return {
        'hasPublishedPolicy': false,
        'policy': null,
        'acknowledged': true,
      };
    }
    return {
      'hasPublishedPolicy': body['hasPublishedPolicy'] == true,
      'policy': body['policy'] is Map
          ? Map<String, dynamic>.from(body['policy'] as Map)
          : null,
      'acknowledged': body['acknowledged'] == true,
    };
  }

  /// Convenience for routing gates: true when the employee must see the
  /// policy page before reaching the dashboard (a published policy exists
  /// that this employee has not acknowledged).
  static Future<bool> needsAcknowledgement() async {
    final data = await getCurrentPolicy();
    return data['hasPublishedPolicy'] == true &&
        data['acknowledged'] != true;
  }

  /// POST /api/employee/company-policy/acknowledge
  /// body: { policyVersion } — must equal the server-side latest published
  /// version. Throws [PolicyVersionStaleException] on HTTP 409.
  static Future<Map<String, dynamic>> acknowledgePolicy(
      int policyVersion) async {
    final res = await http.post(
      Uri.parse('$_base/acknowledge'),
      headers: _headers(),
      body: jsonEncode({'policyVersion': policyVersion}),
    );
    if (res.statusCode == 409) {
      int? latest;
      String msg = 'This policy version is no longer current. '
          'Please reload the latest policy.';
      try {
        final body = jsonDecode(res.body);
        if (body is Map) {
          latest = (body['latestPublishedVersion'] as num?)?.toInt();
          if (body['error'] != null) msg = body['error'].toString();
        }
      } catch (_) {}
      throw PolicyVersionStaleException(msg,
          latestPublishedVersion: latest);
    }
    final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    if ((res.statusCode == 200 || res.statusCode == 201) &&
        body is Map &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body);
    }
    throw _errorFrom(res, 'Failed to acknowledge policy');
  }
}
