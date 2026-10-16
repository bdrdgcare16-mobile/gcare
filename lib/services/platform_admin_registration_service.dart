// lib/services/platform_admin_registration_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

/// API client for organization registration applications reviewed in the
/// Platform Admin portal (Milestone 3D pages under
/// lib/features/platform_admin/).
///
/// Talks to /api/platform/registrations* — all endpoints require an
/// authenticated platform_admin JWT (enforced by roleMiddleware
/// server-side; this client just forwards the portal session token).
class PlatformAdminRegistrationService {
  PlatformAdminRegistrationService._();

  static final PlatformAdminRegistrationService instance =
      PlatformAdminRegistrationService._();

  static String get _base => '${ApiConfig.baseUrl}/platform/registrations';

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

  /// GET /api/platform/registrations — paged list with optional filters.
  Future<Map<String, dynamic>> listRegistrations({
    String? status,
    String? search,
    String? sort,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );

    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load registrations');
    }

    final body = jsonDecode(res.body);
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    return <String, dynamic>{
      'registrations': body is List ? body : const [],
      'hasMore': false,
    };
  }

  /// GET /api/platform/registrations/:id — full application detail.
  Future<Map<String, dynamic>> getRegistration(String id) async {
    final res = await http
        .get(Uri.parse('$_base/$id'), headers: _headers())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to load registration');
    }

    final body = jsonDecode(res.body);
    if (body is Map && body['registration'] is Map) {
      return Map<String, dynamic>.from(body['registration'] as Map);
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    throw Exception('Invalid registration response');
  }

  /// Resolves a stored document to a viewable URL and opens it in a new
  /// browser tab. Returns false when the document could only be
  /// downloaded (non-web) rather than viewed inline.
  Future<bool> openDocument(
    String registrationId,
    String field,
    String filename,
  ) async {
    final uri = Uri.parse('$_base/$registrationId/documents/$field')
        .replace(queryParameters: {'filename': filename});

    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw _errorFrom(res, 'Failed to open document');
    }

    final body = jsonDecode(res.body);
    final url = body is Map
        ? (body['url'] ?? body['data']?['url'])?.toString()
        : null;

    if (url == null || url.isEmpty || !kIsWeb) return false;
    html.window.open(url, '_blank');
    return true;
  }

  /// POST /api/platform/registrations/:id/approve
  Future<void> approveRegistration(String id, {String? comment}) =>
      _review(id, 'approve', comment: comment);

  /// POST /api/platform/registrations/:id/reject
  Future<void> rejectRegistration(String id, String reason) =>
      _review(id, 'reject', comment: reason);

  /// POST /api/platform/registrations/:id/request-changes
  Future<void> requestChanges(String id, String comment) =>
      _review(id, 'request-changes', comment: comment);

  Future<void> _review(
    String id,
    String action, {
    String? comment,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/$id/$action'),
          headers: _headers(),
          body: jsonEncode({
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _errorFrom(res, 'Review action failed');
    }
  }
}
