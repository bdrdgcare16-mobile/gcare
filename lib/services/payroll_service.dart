import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class PayrollService {
  Future<List<dynamic>> getAllPayrolls(String token) async {
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/payroll'),
      headers: getHeaders(token: token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      return body['data'] ?? body;
    } else {
      throw Exception('Failed to fetch payrolls');
    }
  }

  Future<List<dynamic>> getPayrollsByUser(int userId, String token) async {
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/payroll/user/$userId'),
      headers: getHeaders(token: token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      return body['data'] ?? body;
    } else {
      throw Exception('Failed to fetch payrolls');
    }
  }

  Future<void> createPayroll({
    required int userId,
    required int month,
    required int year,
    required double amount,
    String? details,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/payroll'),
      headers: getHeaders(token: token),
      body: jsonEncode({
        'userId': userId,
        'month': month,
        'year': year,
        'amount': amount,
        'details': details,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create payroll');
    }
  }
} 