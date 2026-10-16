import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

/// API client for Platform Admin (platform_admin) tenant management.
/// All endpoints live under /api/platform and require a platform_admin JWT.
class PlatformAdminService {
  static String get _base => '${ApiService.baseUrl}/platform';

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

  /// GET /api/platform/features -> [{key, label, requires[]}]
  static Future<List<Map<String, dynamic>>> getFeatureCatalog() async {
    final res = await http.get(
      Uri.parse('$_base/features'),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load feature catalog');
    }

    final body = jsonDecode(res.body);
    final list = body is Map && body['features'] is List
        ? body['features'] as List
        : <dynamic>[];
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// GET /api/platform/companies
  static Future<List<Map<String, dynamic>>> listCompanies() async {
    final res = await http.get(
      Uri.parse('$_base/companies'),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load companies');
    }

    final body = jsonDecode(res.body);
    final list = body is Map && body['companies'] is List
        ? body['companies'] as List
        : <dynamic>[];
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// POST /api/platform/companies
  static Future<Map<String, dynamic>> createCompany({
    required String companyId,
    required String companyName,
    required String adminName,
    required String adminEmail,
    required String adminPhone,
    required String adminPassword,
    int? maxUsers,
    List<String>? enabledFeatures,
    String? status,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/companies'),
      headers: _headers(),
      body: jsonEncode({
        'companyId': companyId,
        'companyName': companyName,
        'adminName': adminName,
        'adminEmail': adminEmail,
        'adminPhone': adminPhone,
        'adminPassword': adminPassword,
        if (maxUsers != null) 'maxUsers': maxUsers,
        if (enabledFeatures != null) 'enabledFeatures': enabledFeatures,
        if (status != null && status.isNotEmpty) 'status': status,
      }),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode == 201 && body is Map && body['success'] == true) {
      return Map<String, dynamic>.from(body);
    }
    throw _errorFrom(res, 'Failed to create company');
  }

  /// PATCH /api/platform/companies/:companyId
  static Future<Map<String, dynamic>> updateCompany(
    String companyId,
    Map<String, dynamic> updates,
  ) async {
    final res = await http.patch(
      Uri.parse('$_base/companies/$companyId'),
      headers: _headers(),
      body: jsonEncode(updates),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['success'] == true) {
      return Map<String, dynamic>.from(body);
    }
    throw _errorFrom(res, 'Failed to update company');
  }
}
