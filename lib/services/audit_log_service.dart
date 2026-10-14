import 'dart:convert';

import 'package:serv_app/services/api_service.dart';

class AuditLogService {
  static Future<List<Map<String, dynamic>>> getAuditLogs({
    String? action,
    String? module,
    String? employeeId,
    String? resourceType,
    String? resourceId,
    int limit = 200,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (action != null && action.isNotEmpty) query['action'] = action;
    if (module != null && module.isNotEmpty) query['module'] = module;
    if (employeeId != null && employeeId.isNotEmpty) {
      query['employeeId'] = employeeId;
    }
    if (resourceType != null && resourceType.isNotEmpty) {
      query['resourceType'] = resourceType;
    }
    if (resourceId != null && resourceId.isNotEmpty) {
      query['resourceId'] = resourceId;
    }

    final path = '/audit-logs?${Uri(queryParameters: query).query}';
    final response = await ApiService.get(path);
    if (response.statusCode != 200) {
      throw Exception('Failed to load audit logs (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    final logs = decoded is Map ? decoded['logs'] : decoded;
    if (logs is! List) return [];
    return logs
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
