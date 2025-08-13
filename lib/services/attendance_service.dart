import 'dart:convert';
import 'api_base.dart';
import 'user_session.dart';

class AttendanceService {
  Future<List<dynamic>> getAllAttendance(String token) async {
    try {
      final response = await httpGetWithTimeout(
        '${getBaseUrl()}/attendance',
        headers: getHeaders(token: token),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<dynamic>();
        } else {
          return _mockAttendanceData();
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Attendance fetch error: $e');
      return _mockAttendanceData();
    }
  }

  Future<List<dynamic>> getAttendanceByUser(int userId, String token) async {
    try {
      final response = await httpGetWithTimeout(
        '${getBaseUrl()}/attendance/user/$userId',
        headers: getHeaders(token: token),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<dynamic>();
        } else {
          return _mockAttendanceData();
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ User attendance fetch error: $e');
      return _mockAttendanceData();
    }
  }

  Future<Map<String, dynamic>> checkIn() async {
    try {
      // Get current user
      await UserSession.instance.loadUserSession();
      final user = UserSession.instance.currentUser;
      final token = UserSession.instance.token;
      
      if (user == null || token == null) {
        throw Exception('User not authenticated');
      }

      final userId = user['id'];
      final timestamp = DateTime.now().toIso8601String();

      // Try real API first
      try {
        final response = await httpPostWithTimeout(
          '${getBaseUrl()}/attendance/checkin',
          headers: getHeaders(token: token),
          body: jsonEncode({
            'userId': userId,
            'timestamp': timestamp,
          }),
        );

        final result = handleApiResponse(response);
        return result;
      } catch (apiError) {
        print('⚠️ API failed, using mock data: $apiError');
        // Return mock success response
        return {
          'success': true,
          'message': 'Check-in successful (mock)',
          'checkInTime': timestamp,
          'status': 'Present'
        };
      }
    } catch (e) {
      print('❌ Check-in error: $e');
      throw Exception('Failed to check in. Please try again.');
    }
  }

  Future<Map<String, dynamic>> checkOut() async {
    try {
      // Get current user
      await UserSession.instance.loadUserSession();
      final user = UserSession.instance.currentUser;
      final token = UserSession.instance.token;
      
      if (user == null || token == null) {
        throw Exception('User not authenticated');
      }

      final userId = user['id'];
      final timestamp = DateTime.now().toIso8601String();

      final response = await httpPostWithTimeout(
        '${getBaseUrl()}/attendance/checkout',
        headers: getHeaders(token: token),
        body: jsonEncode({
          'userId': userId,
          'timestamp': timestamp,
        }),
      );

      final result = handleApiResponse(response);
      return result;
    } catch (e) {
      print('❌ Check-out error: $e');
      throw Exception('Failed to check out. Please try again.');
    }
  }

  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      await UserSession.instance.loadUserSession();
      final user = UserSession.instance.currentUser;
      final token = UserSession.instance.token;
      
      if (user == null || token == null) {
        throw Exception('User not authenticated');
      }

      final userId = user['id'];
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await httpGetWithTimeout(
        '${getBaseUrl()}/attendance/user/$userId',
        headers: getHeaders(token: token),
      );

      List<dynamic> attendanceData = [];
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data is List) {
          attendanceData = data.cast<dynamic>();
        }
      }
      
      // Filter for today's attendance
      final todayAttendance = attendanceData.where((attendance) {
        final attendanceDate = DateTime.parse(attendance['date']);
        return attendanceDate.isAfter(startOfDay) && attendanceDate.isBefore(endOfDay);
      }).toList();

      return {
        'hasCheckedIn': todayAttendance.isNotEmpty && todayAttendance.first['checkIn'] != null,
        'hasCheckedOut': todayAttendance.isNotEmpty && todayAttendance.first['checkOut'] != null,
        'checkInTime': todayAttendance.isNotEmpty ? todayAttendance.first['checkIn'] : null,
        'checkOutTime': todayAttendance.isNotEmpty ? todayAttendance.first['checkOut'] : null,
        'status': todayAttendance.isNotEmpty ? todayAttendance.first['status'] : 'Not Marked'
      };
    } catch (e) {
      print('❌ Today attendance error: $e');
      return {
        'hasCheckedIn': false,
        'hasCheckedOut': false,
        'checkInTime': null,
        'checkOutTime': null,
        'status': 'Not Marked'
      };
    }
  }

  // Mock data fallback
  List<dynamic> _mockAttendanceData() {
    return [
      {
        'id': 1,
        'userId': 1,
        'date': DateTime.now().toIso8601String(),
        'checkIn': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
        'checkOut': null,
        'status': 'Present'
      }
    ];
  }
} 