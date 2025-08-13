import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  static const String baseUrl = 'http://localhost:8080';

  // Get employee dashboard data
  static Future<Map<String, dynamic>> getEmployeeDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/employee-stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'userName': data['userName'] ?? 'Employee',
          'shiftTiming': data['shiftTiming'] ?? '9:00 AM - 6:00 PM',
          'location': data['location'] ?? 'Office Location',
          'todayTasks': data['todayTasks'] ?? [],
          'attendanceStatus': data['attendanceStatus'] ?? 'Not Checked In',
          'checkInTime': data['checkInTime'],
          'checkOutTime': data['checkOutTime'],
          'workDuration': data['workDuration'] ?? 0,
          'totalTasks': data['totalTasks'] ?? 0,
          'completedTasks': data['completedTasks'] ?? 0,
          'pendingTasks': data['pendingTasks'] ?? 0,
          'success': true,
        };
      } else {
        print('Error fetching employee dashboard data: ${response.statusCode}');
        return _getDefaultEmployeeData();
      }
    } catch (e) {
      print('Exception fetching employee dashboard data: $e');
      return _getDefaultEmployeeData();
    }
  }

  // Get admin dashboard data
  static Future<Map<String, dynamic>> getAdminDashboardData() async {
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
        print('Error fetching admin dashboard data: ${response.statusCode}');
        return _getDefaultAdminData();
      }
    } catch (e) {
      print('Exception fetching admin dashboard data: $e');
      return _getDefaultAdminData();
    }
  }

  // Get user profile data
  static Future<Map<String, dynamic>> getUserProfileData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'name': data['name'] ?? 'User',
          'email': data['email'] ?? 'user@example.com',
          'phoneNumber': data['phoneNumber'] ?? 'Not specified',
          'designation': data['designation'] ?? 'Employee',
          'department': data['department'] ?? 'General',
          'gender': data['gender'] ?? 'Not specified',
          'shiftTiming': data['shiftTiming'] ?? '9:00 AM - 6:00 PM',
          'reportingTo': data['reportingTo'] ?? 'Manager',
          'dateOfJoining': data['dateOfJoining'],
          'employeeId': data['employeeId'] ?? 'EMP000',
          'success': true,
        };
      } else {
        print('Error fetching user profile data: ${response.statusCode}');
        return _getDefaultProfileData();
      }
    } catch (e) {
      print('Exception fetching user profile data: $e');
      return _getDefaultProfileData();
    }
  }

  // Get attendance statistics
  static Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/stats'),
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
          'checkInTime': data['checkInTime'],
          'checkOutTime': data['checkOutTime'],
          'workDuration': data['workDuration'] ?? 0,
          'success': true,
        };
      } else {
        print('Error fetching attendance stats: ${response.statusCode}');
        return _getDefaultAttendanceData();
      }
    } catch (e) {
      print('Exception fetching attendance stats: $e');
      return _getDefaultAttendanceData();
    }
  }

  // Get task statistics
  static Future<Map<String, dynamic>> getTaskStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'totalTasks': data['totalTasks'] ?? 0,
          'completedTasks': data['completedTasks'] ?? 0,
          'pendingTasks': data['pendingTasks'] ?? 0,
          'inProgressTasks': data['inProgressTasks'] ?? 0,
          'todayTasks': data['todayTasks'] ?? [],
          'success': true,
        };
      } else {
        print('Error fetching task stats: ${response.statusCode}');
        return _getDefaultTaskData();
      }
    } catch (e) {
      print('Exception fetching task stats: $e');
      return _getDefaultTaskData();
    }
  }

  // Default data fallbacks
  static Map<String, dynamic> _getDefaultEmployeeData() {
    return {
      'userName': 'Employee',
      'shiftTiming': '9:00 AM - 6:00 PM',
      'location': 'Office Location',
      'todayTasks': [
        {'title': 'District Program Review', 'status': 'Pending'},
        {'title': 'Community Outreach Meeting', 'status': 'In Progress'},
        {'title': 'Monthly Report Submission', 'status': 'Completed'},
      ],
      'attendanceStatus': 'Not Checked In',
      'workDuration': 0,
      'totalTasks': 3,
      'completedTasks': 1,
      'pendingTasks': 2,
      'success': false,
    };
  }

  static Map<String, dynamic> _getDefaultAdminData() {
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

  static Map<String, dynamic> _getDefaultProfileData() {
    return {
      'name': 'User',
      'email': 'user@example.com',
      'phoneNumber': 'Not specified',
      'designation': 'Employee',
      'department': 'General',
      'gender': 'Not specified',
      'shiftTiming': '9:00 AM - 6:00 PM',
      'reportingTo': 'Manager',
      'employeeId': 'EMP000',
      'success': false,
    };
  }

  static Map<String, dynamic> _getDefaultAttendanceData() {
    return {
      'todayAttendance': 0,
      'present': 0,
      'absent': 0,
      'late': 0,
      'workDuration': 0,
      'success': false,
    };
  }

  static Map<String, dynamic> _getDefaultTaskData() {
    return {
      'totalTasks': 3,
      'completedTasks': 1,
      'pendingTasks': 2,
      'inProgressTasks': 0,
      'todayTasks': [
        {'title': 'District Program Review', 'status': 'Pending'},
        {'title': 'Community Outreach Meeting', 'status': 'In Progress'},
        {'title': 'Monthly Report Submission', 'status': 'Completed'},
      ],
      'success': false,
    };
  }
} 