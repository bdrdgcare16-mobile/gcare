import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';
import 'user_session.dart';

class SimpleAttendanceService {
  Future<Map<String, dynamic>> checkIn() async {
    try {
      // Always return success for testing
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      return {
        'success': true,
        'message': 'Check-in successful!',
        'checkInTime': DateTime.now().toIso8601String(),
        'status': 'Present',
        'userId': 1,
      };
    } catch (e) {
      print('❌ Simple check-in error: $e');
      return {
        'success': true,
        'message': 'Check-in successful (fallback)',
        'checkInTime': DateTime.now().toIso8601String(),
        'status': 'Present',
        'userId': 1,
      };
    }
  }

  Future<Map<String, dynamic>> checkOut() async {
    try {
      // Always return success for testing
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      return {
        'success': true,
        'message': 'Check-out successful!',
        'checkOutTime': DateTime.now().toIso8601String(),
        'status': 'Checked Out',
        'userId': 1,
      };
    } catch (e) {
      print('❌ Simple check-out error: $e');
      return {
        'success': true,
        'message': 'Check-out successful (fallback)',
        'checkOutTime': DateTime.now().toIso8601String(),
        'status': 'Checked Out',
        'userId': 1,
      };
    }
  }

  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      // Return mock today attendance
      return {
        'hasCheckedIn': false,
        'hasCheckedOut': false,
        'checkInTime': null,
        'checkOutTime': null,
        'status': 'Not Marked'
      };
    } catch (e) {
      print('❌ Simple today attendance error: $e');
      return {
        'hasCheckedIn': false,
        'hasCheckedOut': false,
        'checkInTime': null,
        'checkOutTime': null,
        'status': 'Not Marked'
      };
    }
  }
} 