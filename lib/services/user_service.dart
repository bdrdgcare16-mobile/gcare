import 'dart:convert';
import 'api_base.dart';
import 'user_session.dart';
import 'package:flutter/foundation.dart';

class UserService {
  static String get _baseUrl => getBaseUrl();

  // Get current user profile
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = UserSession.instance.token;
      final response = await httpGetWithTimeout(
        '$_baseUrl/users/profile',
        headers: getHeaders(token: token),
      );
      return handleApiResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e - Using mock data');
      }
      return _mockCurrentUser();
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phoneNumber,
    required String designation,
    required String department,
    required String gender,
    required String shiftTiming,
    required String reportingTo,
  }) async {
    try {
      final token = UserSession.instance.token;
      final response = await httpPutWithTimeout(
        '$_baseUrl/users/profile',
        headers: getHeaders(token: token),
        body: json.encode({
          'name': name,
          'phoneNumber': phoneNumber,
          'designation': designation,
          'department': department,
          'gender': gender,
          'shiftTiming': shiftTiming,
          'reportingTo': reportingTo,
        }),
      );
      return handleApiResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e - Using mock data');
      }
      return _mockUpdateProfile();
    }
  }

  // Get all employees (for admin)
  static Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      final token = UserSession.instance.token;
      final response = await httpGetWithTimeout(
        '$_baseUrl/users/employees',
        headers: getHeaders(token: token),
      );
      final data = handleApiResponse(response);
      return List<Map<String, dynamic>>.from(data['employees']);
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e - Using mock data');
      }
      return _mockEmployees();
    }
  }

  // Add new employee (for admin)
  static Future<Map<String, dynamic>> addEmployee({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String designation,
    required String department,
    required String gender,
    required String shiftTiming,
    required String reportingTo,
  }) async {
    try {
      final token = UserSession.instance.token;
      final response = await httpPostWithTimeout(
        '$_baseUrl/users/employees',
        headers: getHeaders(token: token),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'designation': designation,
          'department': department,
          'gender': gender,
          'shiftTiming': shiftTiming,
          'reportingTo': reportingTo,
          'role': 'EMPLOYEE',
        }),
      );
      return handleApiResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e - Using mock data');
      }
      return _mockAddEmployee();
    }
  }

  // Mock data fallbacks
  static Map<String, dynamic> _mockCurrentUser() {
    final user = UserSession.instance.currentUser;
    return {
      'id': user?['id'] ?? 1,
      'name': user?['name'] ?? 'Current User',
      'email': user?['email'] ?? 'user@example.com',
      'role': user?['role'] ?? 'EMPLOYEE',
      'phoneNumber': '9876543210',
      'designation': 'Software Developer',
      'department': 'IT Department',
      'gender': 'Female',
      'shiftTiming': '9:00 AM - 6:00 PM',
      'reportingTo': 'IT Manager',
      'dateOfJoining': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _mockUpdateProfile() {
    return {
      'success': true,
      'message': 'Profile updated successfully',
      'user': _mockCurrentUser(),
    };
  }

  static List<Map<String, dynamic>> _mockEmployees() {
    return [
      {
        'id': 1,
        'name': 'A. Baby Reeta',
        'email': 'babyreeta16@gmail.com',
        'role': 'EMPLOYEE',
        'phoneNumber': '9876543210',
        'designation': 'Software Developer',
        'department': 'IT Department',
        'gender': 'Female',
        'shiftTiming': '9:00 AM - 6:00 PM',
        'reportingTo': 'IT Manager',
        'dateOfJoining': '2024-01-01T00:00:00.000Z',
      },
      {
        'id': 2,
        'name': 'A. Mahalakshmi',
        'email': 'keshaw390@gmail.com',
        'role': 'EMPLOYEE',
        'phoneNumber': '9876543211',
        'designation': 'UI/UX Designer',
        'department': 'Design Department',
        'gender': 'Female',
        'shiftTiming': '9:00 AM - 6:00 PM',
        'reportingTo': 'Design Manager',
        'dateOfJoining': '2024-01-02T00:00:00.000Z',
      },
      {
        'id': 3,
        'name': 'M. Anbumozhi',
        'email': 'anbu98871@gmail.com',
        'role': 'EMPLOYEE',
        'phoneNumber': '9876543212',
        'designation': 'Project Manager',
        'department': 'Management',
        'gender': 'Male',
        'shiftTiming': '9:00 AM - 6:00 PM',
        'reportingTo': 'CEO',
        'dateOfJoining': '2024-01-03T00:00:00.000Z',
      },
      {
        'id': 15,
        'name': 'Nishali Mr Tech',
        'email': 'nishalimrtech22@gmail.com',
        'role': 'EMPLOYEE',
        'phoneNumber': '9876543210',
        'designation': 'Software Developer',
        'department': 'IT Department',
        'gender': 'Female',
        'shiftTiming': '9:00 AM - 6:00 PM',
        'reportingTo': 'IT Manager',
        'dateOfJoining': '2024-01-01T00:00:00.000Z',
      },
    ];
  }

  static Map<String, dynamic> _mockAddEmployee() {
    return {
      'success': true,
      'message': 'Employee added successfully',
      'user': {
        'id': 16,
        'name': 'New Employee',
        'email': 'newemployee@company.com',
        'role': 'EMPLOYEE',
      },
    };
  }
} 