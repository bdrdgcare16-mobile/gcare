// lib/features/onboarding/services/organization_policy_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:serv_app/services/api_service.dart';
import '../models/organization_policy_model.dart';

/// Thrown when the policy API cannot be used right now (network, 5xx).
/// Callers must NOT treat this as "all policies accepted".
class PolicyServiceException implements Exception {
  final String message;
  final int? statusCode;
  const PolicyServiceException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// The JWT is missing/expired or the account is not permitted (401/403).
class PolicyAuthException extends PolicyServiceException {
  const PolicyAuthException(super.message, {super.statusCode});
}

/// The policy version the employee viewed is no longer current (409).
class PolicyVersionConflictException extends PolicyServiceException {
  const PolicyVersionConflictException(super.message)
      : super(statusCode: 409);
}

/// Backend communication for organization HR policies.
///
/// The authenticated SERV JWT is attached by [ApiService]; this service never
/// sends userId/companyId — the backend derives them from the token.
class OrganizationPolicyService {
  OrganizationPolicyService._();

  static final OrganizationPolicyService instance =
      OrganizationPolicyService._();

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) return Map<String, dynamic>.from(body);
    } catch (_) {}
    throw const PolicyServiceException('Invalid server response');
  }

  static String _message(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        return (body['message'] ?? body['error'] ?? '').toString();
      }
    } catch (_) {}
    return '';
  }

  static Exception _errorFor(http.Response res) {
    final message = _message(res);
    switch (res.statusCode) {
      case 401:
      case 403:
        return PolicyAuthException(
          message.isEmpty ? 'Authentication failed' : message,
          statusCode: res.statusCode,
        );
      case 409:
        return PolicyVersionConflictException(
          message.isEmpty
              ? 'A newer version of this policy has been published'
              : message,
        );
      case 400:
      case 404:
        return PolicyServiceException(
          message.isEmpty ? 'Invalid policy or version' : message,
          statusCode: res.statusCode,
        );
      default:
        return PolicyServiceException(
          message.isEmpty
              ? 'Policy service unavailable (${res.statusCode})'
              : message,
          statusCode: res.statusCode,
        );
    }
  }

  /// GET /organization/policies — active policies for the employee's org.
  Future<List<OrganizationPolicy>> getCurrentPolicies() async {
    final res = await ApiService.get('/organization/policies');
    if (res.statusCode != 200) throw _errorFor(res);
    final body = _decode(res);
    final list = body['policies'];
    if (list is! List) {
      throw const PolicyServiceException('Invalid server response');
    }
    return list
        .whereType<Map>()
        .map((e) =>
            OrganizationPolicy.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /organization/policies/acceptance-status.
  Future<PolicyAcceptanceStatus> getAcceptanceStatus() async {
    final res =
        await ApiService.get('/organization/policies/acceptance-status');
    if (res.statusCode != 200) throw _errorFor(res);
    return PolicyAcceptanceStatus.fromJson(_decode(res));
  }

  /// POST /organization/policies/accept — records acceptance of the exact
  /// (policyId, policyVersion) the employee viewed.
  ///
  /// Returns normally on 200 (including the idempotent "already accepted"
  /// response). Throws [PolicyVersionConflictException] on 409.
  Future<void> acceptPolicy({
    required String policyId,
    required int policyVersion,
  }) async {
    final res = await ApiService.post(
      '/organization/policies/accept',
      body: jsonEncode({
        'policyId': policyId,
        'policyVersion': policyVersion,
      }),
    );
    if (res.statusCode != 200) throw _errorFor(res);
  }
}
