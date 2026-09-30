// lib/services/organization_context_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/company_data.dart';
import '../models/organization_context.dart';

/// Loads the authenticated organization's runtime context from the
/// canonical companyProfile document. Server-authoritative: the backend
/// resolves the profile from the JWT email/companyId, not from request
/// parameters supplied by the client.
class OrganizationContextService {
  OrganizationContextService._();

  static Future<OrganizationContext?> load() async {
    final token = CompanyData.token;
    if (token.isEmpty) return null;
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/company/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      final data =
          (body is Map ? body['data'] : null) as Map<String, dynamic>?;
      if (data == null) return null;
      final ctx = OrganizationContext.fromProfileJson(data);
      OrganizationContext.current = ctx;
      return ctx;
    } catch (_) {
      return null;
    }
  }
}
