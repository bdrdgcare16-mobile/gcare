import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/models/onboarding_model.dart';

class SuperAdminOnboardingService {
  static const String _baseUrl =
      'https://api-zmj7dqloiq-uc.a.run.app/api/onboarding';

  static Future<List<OnboardingModel>> getAllOnboardings({
    String? search,
    String? status,
    String? department,
    String? branch,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};

      // Only add status filter if it's not "All"
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (department != null && department.isNotEmpty)
        queryParams['department'] = department;
      if (branch != null && branch.isNotEmpty) queryParams['branch'] = branch;

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      debugPrint('[Onboarding] Fetching onboardings');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (CompanyData.token.isNotEmpty)
            'Authorization': 'Bearer ${CompanyData.token}',
        },
      );

      debugPrint('[Onboarding] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded['success'] == true && decoded['data'] != null) {
          final List<dynamic> data = decoded['data'];
          return data.map((item) => OnboardingModel.fromJson(item)).toList();
        } else {
          throw Exception(decoded['message'] ?? 'Failed to fetch onboardings');
        }
      } else {
        throw Exception('Failed to load onboardings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Onboarding] Error fetching onboardings');
      throw Exception('Failed to fetch onboardings: $e');
    }
  }

  static Future<OnboardingModel> getOnboardingById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (CompanyData.token.isNotEmpty)
            'Authorization': 'Bearer ${CompanyData.token}',
        },
      );

      debugPrint('[Onboarding] Get by ID status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return OnboardingModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Onboarding not found');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Onboarding not found');
      } else {
        throw Exception('Failed to load onboarding: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Onboarding] Error fetching onboarding by ID');
      throw Exception('Failed to fetch onboarding: $e');
    }
  }

  static Future<Map<String, dynamic>> updateOnboardingStatus(
    String id,
    String status,
  ) async {
    try {
      debugPrint('[Onboarding] Updating status');

      final response = await http.patch(
        Uri.parse('$_baseUrl/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          if (CompanyData.token.isNotEmpty)
            'Authorization': 'Bearer ${CompanyData.token}',
        },
        body: json.encode({
          'status': status,
        }),
      );

      debugPrint('[Onboarding] Update status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Status updated successfully',
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      debugPrint('[Onboarding] Error updating onboarding status');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Resolves a Firebase Storage object path (e.g.
  /// "onboarding-dev/EMP001/offerLetter-....png") to a short-lived signed
  /// download URL via the backend. Old records that already store a full
  /// http(s) URL should not be passed here.
  static Future<String> resolveDocumentUrl(String storagePath) async {
    final uri = Uri.parse('$_baseUrl/documents/resolve-url')
        .replace(queryParameters: {'path': storagePath});

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (CompanyData.token.isNotEmpty)
          'Authorization': 'Bearer ${CompanyData.token}',
      },
    );

    debugPrint(
        '[Onboarding] Resolve document URL status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['success'] == true && decoded['url'] != null) {
        return decoded['url'] as String;
      }
      throw Exception(decoded['message'] ?? 'Failed to resolve document URL');
    }

    final decoded = json.decode(response.body);
    throw Exception(decoded['message'] ??
        'Failed to resolve document URL: ${response.statusCode}');
  }

  static Future<List<String>> getDepartments() async {
    // This could be a separate API call or hardcoded list
    return [
      'Engineering',
      'Sales',
      'Marketing',
      'HR',
      'Finance',
      'Operations',
      'IT',
      'Customer Support',
      'Admin',
    ];
  }

  static Future<List<String>> getBranches() async {
    // This could be a separate API call or hardcoded list
    return [
      'Bangalore',
      'Mumbai',
      'Delhi',
      'Hyderabad',
      'Chennai',
      'Pune',
      'Kolkata',
      'Ahmedabad',
    ];
  }
}
