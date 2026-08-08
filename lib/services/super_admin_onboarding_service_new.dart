import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/onboarding_model.dart';

class SuperAdminOnboardingService {
  static const String _baseUrl = 'http://127.0.0.1:3000/api/onboarding';

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
      if (department != null && department.isNotEmpty) queryParams['department'] = department;
      if (branch != null && branch.isNotEmpty) queryParams['branch'] = branch;
      
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      
      debugPrint('Fetching onboardings from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

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
      debugPrint('Error fetching onboardings: $e');
      throw Exception('Failed to fetch onboardings: $e');
    }
  }

  static Future<OnboardingModel> getOnboardingById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Get onboarding by ID response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

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
      debugPrint('Error fetching onboarding by ID: $e');
      throw Exception('Failed to fetch onboarding: $e');
    }
  }

  static Future<Map<String, dynamic>> updateOnboardingStatus(
    String id,
    String status,
  ) async {
    try {
      debugPrint('Updating onboarding status: $id to $status');

      final response = await http.patch(
        Uri.parse('$_baseUrl/$id/status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'status': status,
        }),
      );

      debugPrint('Update status response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

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
      debugPrint('Error updating onboarding status: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
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
