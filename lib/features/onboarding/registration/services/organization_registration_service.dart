// lib/features/onboarding/registration/services/organization_registration_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:serv_app/config/api_config.dart';
import '../models/organization_registration_draft.dart';

/// Thrown when the registration API cannot be used right now (network, 5xx).
/// Callers must keep the local draft — a transient failure is not data loss.
class RegistrationApiException implements Exception {
  final String message;
  final int? statusCode;
  const RegistrationApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// The resume credential was rejected — expired, revoked or wrong (401/403/410).
/// The caller should clear the stored credential and create a new draft on the
/// next save, WITHOUT discarding the applicant's local data.
class RegistrationCredentialException extends RegistrationApiException {
  const RegistrationCredentialException(super.message, {super.statusCode});
}

/// Client for the public organization-registration draft API.
///
/// These endpoints are unauthenticated (the applicant has no SERV account);
/// access is controlled by the `x-registration-resume-token` header issued
/// once at draft creation. The token is stored in flutter_secure_storage —
/// never in SharedPreferences.
class OrganizationRegistrationService {
  OrganizationRegistrationService._();

  static final OrganizationRegistrationService instance =
      OrganizationRegistrationService._();

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'serv_org_reg_resume_token';
  static const _timeout = Duration(seconds: 15);

  // ── Credential storage ──────────────────────────────────────────────────

  Future<String?> loadResumeToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveResumeToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> clearResumeToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}
  }

  // ── HTTP plumbing ────────────────────────────────────────────────────────

  static String get _base => ApiConfig.baseUrl;

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'x-registration-resume-token': token,
      };

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) return Map<String, dynamic>.from(body);
    } catch (_) {}
    throw const RegistrationApiException('Invalid server response');
  }

  static void _throwFor(http.Response res) {
    String message = '';
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        message = (body['error'] ?? body['message'] ?? '').toString();
      }
    } catch (_) {}
    if (res.statusCode == 401 ||
        res.statusCode == 403 ||
        res.statusCode == 410) {
      throw RegistrationCredentialException(
        message.isEmpty ? 'Registration credential is no longer valid' : message,
        statusCode: res.statusCode,
      );
    }
    throw RegistrationApiException(
      message.isEmpty ? 'Request failed (${res.statusCode})' : message,
      statusCode: res.statusCode,
    );
  }

  static Future<http.Response> _send(
    Future<http.Response> Function() call,
  ) async {
    try {
      return await call().timeout(_timeout);
    } on TimeoutException {
      throw const RegistrationApiException(
          'Network unavailable. Please check your connection.');
    } on http.ClientException {
      throw const RegistrationApiException(
          'Network unavailable. Please check your connection.');
    }
  }

  // ── Payload mapping ──────────────────────────────────────────────────────

  static Map<String, dynamic> _draftBody(
      OrganizationRegistrationDraft d) {
    int parseCount(String v) => int.tryParse(v.trim()) ?? 0;
    return {
      'organization': {
        'name': d.organizationName,
        'type': d.organizationType,
        'industry': d.industry,
        'employeeCount': parseCount(d.employeeCount),
        'branchCount': parseCount(d.branchCount),
        'registeredAddress': d.registeredAddress,
        'officialEmail': d.officialEmail,
        'contactNumber': d.contactNumber,
        'website': d.website,
        'gstNumber': d.gstNumber,
        'cinNumber': d.cinNumber,
      },
      'adminContact': {
        'fullName': d.adminFullName,
        'designation': d.adminDesignation,
        'email': d.adminEmail,
        'mobile': d.adminMobile,
      },
      'requestedFeatures': d.requestedFeatures.toList(),
      'currentStep': d.currentStep,
      'maxCompletedStep': d.maxCompletedStep,
    };
  }

  /// Applies a server draft onto the local draft model.
  static void applyServerDraft(
    OrganizationRegistrationDraft draft,
    Map<String, dynamic> body,
  ) {
    final org = (body['organization'] is Map)
        ? Map<String, dynamic>.from(body['organization'])
        : <String, dynamic>{};
    final admin = (body['adminContact'] is Map)
        ? Map<String, dynamic>.from(body['adminContact'])
        : <String, dynamic>{};

    draft.organizationName = (org['name'] ?? '').toString();
    draft.organizationType = (org['type'] ?? '').toString();
    draft.industry = (org['industry'] ?? '').toString();
    draft.employeeCount = (org['employeeCount'] ?? '').toString() == '0'
        ? ''
        : (org['employeeCount'] ?? '').toString();
    draft.branchCount = (org['branchCount'] ?? '').toString() == '0'
        ? ''
        : (org['branchCount'] ?? '').toString();
    draft.registeredAddress = (org['registeredAddress'] ?? '').toString();
    draft.officialEmail = (org['officialEmail'] ?? '').toString();
    draft.contactNumber = (org['contactNumber'] ?? '').toString();
    draft.website = (org['website'] ?? '').toString();
    draft.gstNumber = (org['gstNumber'] ?? '').toString();
    draft.cinNumber = (org['cinNumber'] ?? '').toString();

    draft.requestedFeatures
      ..clear()
      ..addAll(
        (body['requestedFeatures'] is List)
            ? (body['requestedFeatures'] as List).map((e) => e.toString())
            : const <String>[],
      );

    draft.adminFullName = (admin['fullName'] ?? '').toString();
    draft.adminDesignation = (admin['designation'] ?? '').toString();
    draft.adminEmail = (admin['email'] ?? '').toString();
    draft.adminMobile = (admin['mobile'] ?? '').toString();

    if (body['currentStep'] is num) {
      draft.currentStep = (body['currentStep'] as num).toInt();
    }
    if (body['maxCompletedStep'] is num) {
      draft.maxCompletedStep = (body['maxCompletedStep'] as num).toInt();
    }
  }

  // ── API calls ────────────────────────────────────────────────────────────

  /// Creates a server draft. Returns `{registrationId, resumeToken}`.
  /// The resume token is returned ONCE — the caller must persist it via
  /// [saveResumeToken].
  Future<({String registrationId, String resumeToken})> createDraft(
    OrganizationRegistrationDraft draft,
  ) async {
    final res = await _send(() => http.post(
          Uri.parse('$_base/org-registration/draft'),
          headers: _headers(null),
          body: jsonEncode(_draftBody(draft)),
        ));
    if (res.statusCode != 201 && res.statusCode != 200) _throwFor(res);
    final body = _decode(res);
    final id = (body['registrationId'] ?? '').toString();
    final token = (body['resumeToken'] ?? '').toString();
    if (id.isEmpty || token.isEmpty) {
      throw const RegistrationApiException('Invalid server response');
    }
    return (registrationId: id, resumeToken: token);
  }

  /// Fetches the server draft. Throws [RegistrationCredentialException] on
  /// an invalid/expired credential.
  Future<Map<String, dynamic>> getDraft(
    String registrationId,
    String resumeToken,
  ) async {
    final res = await _send(() => http.get(
          Uri.parse('$_base/org-registration/draft/$registrationId'),
          headers: _headers(resumeToken),
        ));
    if (res.statusCode != 200) _throwFor(res);
    return _decode(res);
  }

  /// Updates the server draft (partial update of editable fields).
  Future<void> updateDraft(
    String registrationId,
    String resumeToken,
    OrganizationRegistrationDraft draft,
  ) async {
    final res = await _send(() => http.patch(
          Uri.parse('$_base/org-registration/draft/$registrationId'),
          headers: _headers(resumeToken),
          body: jsonEncode(_draftBody(draft)),
        ));
    if (res.statusCode != 200) _throwFor(res);
  }

  /// Reads application status (for the future pending-approval screen).
  Future<Map<String, dynamic>> getStatus(
    String registrationId,
    String resumeToken,
  ) async {
    final res = await _send(() => http.get(
          Uri.parse('$_base/org-registration/status/$registrationId'),
          headers: _headers(resumeToken),
        ));
    if (res.statusCode != 200) _throwFor(res);
    return _decode(res);
  }

  // ── Contact verification (OTP) ───────────────────────────────────────────

  /// Requests a verification code for [channel]
  /// ('orgEmail' | 'adminEmail' | 'adminMobile').
  ///
  /// Returns the decoded body. In DEV emulator mode it may contain `devCode`
  /// for local testing; production responses never include the code.
  Future<Map<String, dynamic>> requestOtp(
    String registrationId,
    String resumeToken,
    String channel,
  ) async {
    final res = await _send(() => http.post(
          Uri.parse('$_base/org-registration/verify/request'),
          headers: _headers(resumeToken),
          body: jsonEncode({
            'registrationId': registrationId,
            'channel': channel,
          }),
        ));
    if (res.statusCode != 200) _throwFor(res);
    return _decode(res);
  }

  /// Confirms a 6-digit [code] for [channel].
  Future<void> confirmOtp(
    String registrationId,
    String resumeToken,
    String channel,
    String code,
  ) async {
    final res = await _send(() => http.post(
          Uri.parse('$_base/org-registration/verify/confirm'),
          headers: _headers(resumeToken),
          body: jsonEncode({
            'registrationId': registrationId,
            'channel': channel,
            'code': code,
          }),
        ));
    if (res.statusCode != 200) _throwFor(res);
  }

  // ── Organization documents ───────────────────────────────────────────────

  /// Uploads one document [field] with the given file bytes. The backend
  /// validates actual content type — the filename is cosmetic only.
  Future<void> uploadDocument(
    String registrationId,
    String resumeToken,
    String field,
    String filename,
    List<int> bytes,
  ) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/org-registration/documents'),
    );
    req.headers.addAll({'x-registration-resume-token': resumeToken});
    req.fields['registrationId'] = registrationId;
    req.files.add(
      http.MultipartFile.fromBytes(field, bytes, filename: filename),
    );
    http.Response res;
    try {
      res = await http.Response.fromStream(await req.send())
          .timeout(_timeout);
    } on TimeoutException {
      throw const RegistrationApiException(
          'Network unavailable. Please check your connection.');
    }
    if (res.statusCode != 200) _throwFor(res);
  }

  /// Returns document metadata for the registration.
  Future<Map<String, dynamic>> listDocuments(
    String registrationId,
    String resumeToken,
  ) async {
    final res = await _send(() => http.get(
          Uri.parse('$_base/org-registration/documents/$registrationId'),
          headers: _headers(resumeToken),
        ));
    if (res.statusCode != 200) _throwFor(res);
    return _decode(res);
  }
}
