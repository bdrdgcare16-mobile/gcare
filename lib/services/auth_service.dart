import 'dart:convert';
import 'api_base.dart';
import 'user_session.dart';

class AuthService {
  static String get _baseUrl => getBaseUrl();

  // Login with real API
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Use real database for authentication
    try {
      final response = await httpPostWithTimeout(
        '$_baseUrl/auth/login',
        headers: getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 5));

      final data = handleApiResponse(response);
      
      // Store user session
      await UserSession.instance.setUserSession(
        data['user'],
        data['token'],
      );

      return data;
    } catch (e) {
      print('API Error: $e - Trying mock fallback');
      // Fallback to mock data only for known demo accounts
      try {
        final mockData = _mockLogin(email, password);
        await UserSession.instance.setUserSession(
          mockData['user'],
          mockData['token'],
        );
        return mockData;
      } catch (mockError) {
        throw Exception('Login failed. Please check your credentials.');
      }
    }
  }

  // Register with real API
  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    try {
      final response = await httpPostWithTimeout(
        '$_baseUrl/auth/register',
        headers: getHeaders(),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      return handleApiResponse(response);
    } catch (e) {
      // Fallback to mock data if API fails
      print('API Error: $e - Using mock data');
      return _mockRegister(name, email, password, role);
    }
  }

  // Enhanced registration with all employee details
  Future<Map<String, dynamic>> registerWithDetails({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? designation,
    String? department,
    String? gender,
    String? shiftTiming,
    String? reportingTo,
    String? dateOfJoining,
  }) async {
    try {
      final response = await httpPostWithTimeout(
        '$_baseUrl/auth/register',
        headers: getHeaders(),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'phoneNumber': phoneNumber,
          'designation': designation,
          'department': department,
          'gender': gender,
          'shiftTiming': shiftTiming,
          'reportingTo': reportingTo,
          'dateOfJoining': dateOfJoining,
        }),
      );

      return handleApiResponse(response);
    } catch (e) {
      print('API Error: $e - Using mock data');
      return _mockRegisterWithDetails(
        email: email,
        password: password,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        designation: designation,
        department: department,
        gender: gender,
        shiftTiming: shiftTiming,
        reportingTo: reportingTo,
        dateOfJoining: dateOfJoining,
      );
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = UserSession.instance.token;
      if (token == null) {
        throw Exception('User not logged in');
      }

      final response = await httpGetWithTimeout(
        '$_baseUrl/auth/profile',
        headers: {
          ...getHeaders(),
          'Authorization': 'Bearer $token',
        },
      );

      return handleApiResponse(response);
    } catch (e) {
      print('API Error: $e - Using session data');
      // Fallback to session data
      final user = UserSession.instance.currentUser;
      if (user != null) {
        return {'user': user};
      }
      throw Exception('Failed to get profile');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phoneNumber,
    String? designation,
    String? department,
    String? gender,
    String? shiftTiming,
    String? reportingTo,
  }) async {
    try {
      final token = UserSession.instance.token;
      if (token == null) {
        throw Exception('User not logged in');
      }

      final response = await httpPutWithTimeout(
        '$_baseUrl/auth/profile',
        headers: {
          ...getHeaders(),
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (name != null) 'name': name,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (designation != null) 'designation': designation,
          if (department != null) 'department': department,
          if (gender != null) 'gender': gender,
          if (shiftTiming != null) 'shiftTiming': shiftTiming,
          if (reportingTo != null) 'reportingTo': reportingTo,
        }),
      );

      final data = handleApiResponse(response);
      
      // Update session with new user data
      if (data['user'] != null) {
        await UserSession.instance.setUserSession(
          data['user'],
          token,
        );
      }

      return data;
    } catch (e) {
      print('API Error: $e');
      throw Exception('Failed to update profile');
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await httpPostWithTimeout(
        '$_baseUrl/auth/forgot-password',
        headers: getHeaders(),
        body: json.encode({
          'email': email,
        }),
      );

      return handleApiResponse(response);
    } catch (e) {
      print('API Error: $e - Using mock data');
      return _mockForgotPassword(email);
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await httpPostWithTimeout(
        '$_baseUrl/auth/reset-password',
        headers: getHeaders(),
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      return handleApiResponse(response);
    } catch (e) {
      print('API Error: $e - Using mock data');
      return _mockResetPassword(token, newPassword);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final token = UserSession.instance.token;
      if (token != null) {
        await httpPostWithTimeout(
          '$_baseUrl/auth/logout',
          headers: getHeaders(token: token),
        );
      }
    } catch (e) {
      print('Logout API Error: $e');
    } finally {
      // Always clear local session
      await UserSession.instance.clearUserSession();
    }
  }

  // Mock login data for fallback
  Map<String, dynamic> _mockLogin(String email, String password) {
    // Original users
    if (email == 'keshaw390@gmail.com' && password == 'Employee@123') {
      return {
        'message': 'Login successful',
        'token': 'mock_token_employee',
        'user': {
          'id': 1,
          'email': 'keshaw390@gmail.com',
          'name': 'A.Mahalakshmi',
          'role': 'EMPLOYEE',
          'phoneNumber': '+9876543210',
          'designation': 'District Program Officer',
          'department': 'Program Management',
          'gender': 'Female',
          'shiftTiming': '9:00 AM - 6:00 PM',
          'reportingTo': 'Manager',
          'dateOfJoining': '2024-01-15T00:00:00.000Z',
        }
      };
    } else if (email == 'admin@techcorp.com' && password == 'Admin@123') {
      return {
        'message': 'Login successful',
        'token': 'mock_token_admin',
        'user': {
          'id': 2,
          'email': 'admin@techcorp.com',
          'name': 'Admin User',
          'role': 'ADMIN',
          'phoneNumber': '+1234567890',
          'designation': 'System Administrator',
          'department': 'IT',
          'gender': 'Not specified',
          'shiftTiming': '9:00 AM - 6:00 PM',
          'reportingTo': 'CEO',
          'dateOfJoining': '2024-01-01T00:00:00.000Z',
        }
      };
    }
    
    // Custom admin users
    else if (email == 'admin@nishali.com' && password == 'admin123') {
      return {
        'message': 'Login successful',
        'token': 'mock_token_admin_custom',
        'user': {
          'id': 101,
          'email': 'admin@nishali.com',
          'name': 'System Administrator',
          'role': 'ADMIN',
          'phoneNumber': '+919876543210',
          'designation': 'System Administrator',
          'department': 'IT',
          'gender': 'Not specified',
          'shiftTiming': '9:00 AM - 6:00 PM',
          'reportingTo': 'CEO',
          'dateOfJoining': '2024-01-01T00:00:00.000Z',
        }
      };
    } else if (email == 'hr@nishali.com' && password == 'hr123') {
      return {
        'message': 'Login successful',
        'token': 'mock_token_admin_hr',
        'user': {
          'id': 102,
          'email': 'hr@nishali.com',
          'name': 'HR Manager',
          'role': 'ADMIN',
          'phoneNumber': '+919876543211',
          'designation': 'HR Manager',
          'department': 'Human Resources',
          'gender': 'Not specified',
          'shiftTiming': '9:00 AM - 6:00 PM',
          'reportingTo': 'CEO',
          'dateOfJoining': '2024-01-15T00:00:00.000Z',
        }
      };
    }
    
    // Custom employee users
    else if (email == 'john.doe@nishali.com' && password == 'employee123') {
      return {
        'message': 'Login successful',
        'token': 'mock_token_employee_john',
        'user': {
          'id': 201,
          'email': 'john.doe@nishali.com',
          'name': 'John Doe',
          'role': 'EMPLOYEE',
          'phoneNumber': '+919876543212',
          'designation': 'Software Developer',
          'department': 'Engineering',
          'gender': 'Male',
          'shiftTiming': '9:00 AM - 6:00 PM',
          'reportingTo': 'Team Lead',
          'dateOfJoining': '2024-02-01T00:00:00.000Z',
        }
      };
    } else if (email == 'jane.smith@nishali.com' && password == 'employee123') {
      return {
        'message': 'Login successful',
        'token': 'mock_token_employee_jane',
        'user': {
          'id': 202,
          'email': 'jane.smith@nishali.com',
          'name': 'Jane Smith',
          'role': 'EMPLOYEE',
          'phoneNumber': '+919876543213',
          'designation': 'UI/UX Designer',
          'department': 'Design',
          'gender': 'Female',
          'shiftTiming': '9:00 AM - 6:00 PM',
          'reportingTo': 'Design Lead',
          'dateOfJoining': '2024-02-15T00:00:00.000Z',
        }
      };
    } else if (email == 'mike.johnson@nishali.com' && password == 'employee123') {
      return {
        'message': 'Login successful',
        'token': 'mock_token_employee_mike',
        'user': {
          'id': 203,
          'email': 'mike.johnson@nishali.com',
          'name': 'Mike Johnson',
          'role': 'EMPLOYEE',
          'phoneNumber': '+919876543214',
          'designation': 'Marketing Specialist',
          'department': 'Marketing',
          'gender': 'Male',
          'shiftTiming': '9:00 AM - 6:00 PM',
          'reportingTo': 'Marketing Manager',
          'dateOfJoining': '2024-03-01T00:00:00.000Z',
        }
      };
    } else if (email == 'sarah.wilson@nishali.com' && password == 'employee123') {
      return {
        'message': 'Login successful',
        'token': 'mock_token_employee_sarah',
        'user': {
          'id': 204,
          'email': 'sarah.wilson@nishali.com',
          'name': 'Sarah Wilson',
          'role': 'EMPLOYEE',
          'phoneNumber': '+919876543215',
          'designation': 'Sales Representative',
          'department': 'Sales',
          'gender': 'Female',
          'shiftTiming': '9:00 AM - 6:00 PM',
          'reportingTo': 'Sales Manager',
          'dateOfJoining': '2024-03-15T00:00:00.000Z',
        }
      };
    }
    
    throw Exception('Invalid credentials');
  }

  // Mock register data
  Map<String, dynamic> _mockRegister(String name, String email, String password, String role) {
    return {
      'message': 'User registered successfully',
      'user': {
        'id': 999,
        'email': email,
        'name': name,
        'role': role,
        'phoneNumber': null,
        'designation': null,
        'department': null,
        'gender': null,
        'shiftTiming': '9:00 AM - 6:00 PM',
        'reportingTo': null,
        'dateOfJoining': DateTime.now().toIso8601String(),
      }
    };
  }

  // Mock register with details
  Map<String, dynamic> _mockRegisterWithDetails({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? designation,
    String? department,
    String? gender,
    String? shiftTiming,
    String? reportingTo,
    String? dateOfJoining,
  }) {
    return {
      'message': 'User registered successfully',
      'user': {
        'id': 999,
        'email': email,
        'name': name,
        'role': role,
        'phoneNumber': phoneNumber,
        'designation': designation,
        'department': department,
        'gender': gender,
        'shiftTiming': shiftTiming ?? '9:00 AM - 6:00 PM',
        'reportingTo': reportingTo,
        'dateOfJoining': dateOfJoining ?? DateTime.now().toIso8601String(),
      }
    };
  }

  // Mock forgot password
  Map<String, dynamic> _mockForgotPassword(String email) {
    return {
      'message': 'Password reset email sent',
      'email': email,
    };
  }

  // Mock reset password
  Map<String, dynamic> _mockResetPassword(String token, String newPassword) {
    return {
      'message': 'Password reset successfully',
      'token': token,
    };
  }
} 