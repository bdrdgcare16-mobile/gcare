import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

/// Read-only Platform Admin client for organization-registration review
/// (Milestone 3D-B). All endpoints require the platform_admin SERV JWT in
/// CompanyData.token (set by PlatformAdminSession). Documents stream
/// through the authenticated backend — no public or signed URLs.
class PlatformAdminRegistrationService {
  PlatformAdminRegistrationService._();

  static final PlatformAdminRegistrationService instance =
      PlatformAdminRegistrationService._();

  static const _timeout = Duration(seconds: 15);

  static String get _base => '${ApiConfig.baseUrl}/platform-admin/registrations';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (CompanyData.token.isNotEmpty)
          'Authorization': 'Bearer ${CompanyData.token}',
      };

  /// Lists applications. Returns `{registrations, page, pageSize, hasMore}`.
  /// [search] is a case-insensitive organization-name prefix; [sort] is
  /// 'createdAt' (default) or 'submittedAt'.
  Future<Map<String, dynamic>> listRegistrations({
    String? status,
    String? search,
    String sort = 'createdAt',
    int page = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (sort != 'createdAt') 'sort': sort,
    };
    final uri = Uri.parse(_base).replace(queryParameters: params);
    final response = await http
        .get(uri, headers: _headers)
        .timeout(_timeout);
    debugPrint('[AdminReg] list status=${response.statusCode}');
    final decoded = json.decode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    throw Exception(
      decoded is Map && decoded['error'] != null
          ? decoded['error']
          : 'Failed to load applications (${response.statusCode})',
    );
  }

  /// Shared POST for the 3D-C review decisions. The request body carries
  /// only free-text input — reviewer identity and role are derived
  /// server-side from the JWT and are never sent.
  Future<Map<String, dynamic>> _decide(
    String registrationId,
    String action,
    Map<String, String> fields,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_base/$registrationId/$action'),
          headers: _headers,
          body: json.encode(fields),
        )
        .timeout(_timeout);
    debugPrint('[AdminReg] $action status=${response.statusCode}');
    final decoded = json.decode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    throw Exception(
      decoded is Map && decoded['error'] != null
          ? decoded['error']
          : 'Review action failed (${response.statusCode})',
    );
  }

  /// Approve a pending_approval application — REVIEW APPROVED ONLY.
  /// No organization, org code, account, or feature is created by this.
  /// [comment] is optional.
  Future<Map<String, dynamic>> approveRegistration(
    String registrationId, {
    String? comment,
  }) =>
      _decide(registrationId, 'approve', {
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      });

  /// Reject a pending_approval application. [reason] is required.
  Future<Map<String, dynamic>> rejectRegistration(
    String registrationId,
    String reason,
  ) =>
      _decide(registrationId, 'reject', {'reason': reason.trim()});

  /// Request changes on a pending_approval application. [message] is
  /// required — it is shown to the applicant.
  Future<Map<String, dynamic>> requestChanges(
    String registrationId,
    String message,
  ) =>
      _decide(registrationId, 'request-changes', {'message': message.trim()});

  /// Fetches one full application for review.
  Future<Map<String, dynamic>> getRegistration(String registrationId) async {
    final response = await http
        .get(Uri.parse('$_base/$registrationId'), headers: _headers)
        .timeout(_timeout);
    debugPrint('[AdminReg] detail status=${response.statusCode}');
    final decoded = json.decode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        (decoded as Map)['registration'] as Map,
      );
    }
    throw Exception(
      decoded is Map && decoded['error'] != null
          ? decoded['error']
          : 'Failed to load application (${response.statusCode})',
    );
  }

  /// Downloads a private document through the authenticated backend and opens
  /// it in a new browser tab (web). On non-web targets the bytes are fetched
  /// successfully but cannot be opened inline — returns false.
  Future<bool> openDocument(
    String registrationId,
    String field,
    String filename,
  ) async {
    final response = await http
        .get(
          Uri.parse('$_base/$registrationId/documents/$field'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 30));
    debugPrint('[AdminReg] document status=${response.statusCode}');
    if (response.statusCode != 200) {
      String msg = 'Unable to open document (${response.statusCode})';
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          msg = decoded['error'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
    if (!kIsWeb) return false;

    final bytes = Uint8List.fromList(response.bodyBytes);
    final contentType =
        response.headers['content-type'] ?? 'application/octet-stream';
    final blob = html.Blob([bytes], contentType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    // Revoke later — the new tab needs the URL to stay alive briefly.
    Future.delayed(const Duration(seconds: 60), () {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
    });
    return true;
  }
}
