import 'dart:convert';

import 'package:serv_app/services/api_service.dart';

class EmployeeJobHistoryService {
  static Future<List<Map<String, dynamic>>> list(String employeeId) async {
    final response = await ApiService.get(
      '/employees/${Uri.encodeComponent(employeeId)}/job-history',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load job history (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
