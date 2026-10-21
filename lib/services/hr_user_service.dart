import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

/// API client for Company Admin HR-user management.
/// Endpoints live under /api/admin/hr-users and require an authenticated
/// company admin (role 'company_admin') or tenant admin (role 'admin')
/// JWT — enforced server-side by roleMiddleware(['admin', 'company_admin']).
/// companyId is derived from the token; the client never sends it.
/// Accounts created through this API are stored with role 'admin' and a
/// non-authoritative displayRole 'hr' marker; the "HR" naming here is a
/// UI/management classification only.
class HrUserService {
  static String get _base => '${ApiService.baseUrl}/admin/hr-users';

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

  /// GET /api/admin/hr-users — HR users of the caller's company.
  static Future<List<Map<String, dynamic>>> listHrUsers() async {
    final res = await http.get(Uri.parse(_base), headers: _headers());

    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load HR users');
    }

    final body = jsonDecode(res.body);
    final list = body is Map && body['hrUsers'] is List
        ? body['hrUsers'] as List
        : <dynamic>[];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// POST /api/admin/hr-users — create an HR user for the caller's company.
  /// Returns the server response (includes `tempPassword` when no password
  /// was supplied).
  static Future<Map<String, dynamic>> createHrUser({
    required String name,
    required String email,
    required String branch,
    required String department,
    String? branchId,
    String? departmentId,
    String? phone,
    String? password,
  }) async {
    final res = await http.post(
      Uri.parse(_base),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'branch': branch,
        'department': department,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (departmentId != null && departmentId.isNotEmpty)
          'departmentId': departmentId,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (password != null && password.isNotEmpty) 'password': password,
      }),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode == 201 && body is Map && body['success'] == true) {
      return Map<String, dynamic>.from(body);
    }
    throw _errorFrom(res, 'Failed to create HR user');
  }
}
