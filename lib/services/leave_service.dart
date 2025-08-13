import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class LeaveService {
  Future<List<dynamic>> getLeaveTypes(String token) async {
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/leave/types'),
      headers: getHeaders(token: token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      return body['data'] ?? body;
    } else {
      throw Exception('Failed to fetch leave types');
    }
  }

  Future<List<dynamic>> getLeaveRequests(String token) async {
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/leave/requests'),
      headers: getHeaders(token: token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      return body['data'] ?? body;
    } else {
      throw Exception('Failed to fetch leave requests');
    }
  }

  Future<void> createLeaveRequest({
    required int userId,
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String status,
    String? reason,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/leave/requests'),
      headers: getHeaders(token: token),
      body: jsonEncode({
        'userId': userId,
        'leaveTypeId': leaveTypeId,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'reason': reason,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create leave request');
    }
  }
} 