import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminDashboardService {
  static const String baseUrl = 'http://localhost:8080';

  // Fetch real dashboard statistics from database
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard-stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'totalEmployees': data['totalEmployees'] ?? 0,
          'activeEmployees': data['activeEmployees'] ?? 0,
          'pendingLeaves': data['pendingLeaves'] ?? 0,
          'todayAttendance': data['todayAttendance'] ?? 0,
          'totalPayroll': data['totalPayroll'] ?? 0,
          'announcements': data['announcements'] ?? 0,
          'success': true,
        };
      } else {
        print('Error fetching dashboard stats: ${response.statusCode}');
        return _getDefaultStats();
      }
    } catch (e) {
      print('Exception fetching dashboard stats: $e');
      return _getDefaultStats();
    }
  }

  // Get user count statistics
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/user-stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'totalUsers': data['totalUsers'] ?? 0,
          'employees': data['employees'] ?? 0,
          'admins': data['admins'] ?? 0,
          'success': true,
        };
      } else {
        print('Error fetching user stats: ${response.statusCode}');
        return {
          'totalUsers': 23,
          'employees': 20,
          'admins': 3,
          'success': false,
        };
      }
    } catch (e) {
      print('Exception fetching user stats: $e');
      return {
        'totalUsers': 23,
        'employees': 20,
        'admins': 3,
        'success': false,
      };
    }
  }

  // Get attendance statistics
  static Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/attendance-stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'todayAttendance': data['todayAttendance'] ?? 0,
          'present': data['present'] ?? 0,
          'absent': data['absent'] ?? 0,
          'late': data['late'] ?? 0,
          'success': true,
        };
      } else {
        print('Error fetching attendance stats: ${response.statusCode}');
        return {
          'todayAttendance': 20,
          'present': 18,
          'absent': 2,
          'late': 0,
          'success': false,
        };
      }
    } catch (e) {
      print('Exception fetching attendance stats: $e');
      return {
        'todayAttendance': 20,
        'present': 18,
        'absent': 2,
        'late': 0,
        'success': false,
      };
    }
  }

  // Get leave request statistics
  static Future<Map<String, dynamic>> getLeaveStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/leave-stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'pendingLeaves': data['pendingLeaves'] ?? 0,
          'approvedLeaves': data['approvedLeaves'] ?? 0,
          'rejectedLeaves': data['rejectedLeaves'] ?? 0,
          'totalRequests': data['totalRequests'] ?? 0,
          'success': true,
        };
      } else {
        print('Error fetching leave stats: ${response.statusCode}');
        return {
          'pendingLeaves': 5,
          'approvedLeaves': 12,
          'rejectedLeaves': 2,
          'totalRequests': 19,
          'success': false,
        };
      }
    } catch (e) {
      print('Exception fetching leave stats: $e');
      return {
        'pendingLeaves': 5,
        'approvedLeaves': 12,
        'rejectedLeaves': 2,
        'totalRequests': 19,
        'success': false,
      };
    }
  }

  // Default stats fallback
  static Map<String, dynamic> _getDefaultStats() {
    return {
      'totalEmployees': 23,
      'activeEmployees': 20,
      'pendingLeaves': 5,
      'todayAttendance': 20,
      'totalPayroll': 1200000,
      'announcements': 3,
      'success': false,
    };
  }
} 