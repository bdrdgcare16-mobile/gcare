// lib/services/disciplinary_actions_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/models/disciplinary_action_model.dart';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

class DisciplinaryActionsService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/disciplinary-actions';

  static String? _readToken() {
    final token = CompanyData.token;
    if (token.isNotEmpty) return token;

    try {
      final local = html.window.localStorage['token'];
      if (local != null && local.isNotEmpty) return local;
      final session = html.window.sessionStorage['token'];
      if (session != null && session.isNotEmpty) return session;
    } catch (_) {}

    return null;
  }

  static Map<String, String> _jsonHeaders() {
    final token = _readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  static Future<List<DisciplinaryActionModel>> _parseList(
    String label,
    String uri,
    http.Response response,
  ) async {
    debugPrint('[DisciplinaryActions][$label]');
    debugPrint('[DisciplinaryActions][$label] Endpoint: $uri');
    debugPrint('[DisciplinaryActions][$label] Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final raw = decoded is Map<String, dynamic>
          ? (decoded['data'] as List<dynamic>? ?? [])
          : decoded is List
              ? decoded
              : <dynamic>[];
      final result = raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => DisciplinaryActionModel.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
      debugPrint('[DisciplinaryActions][$label] Items: ${result.length}');
      return result;
    }

    debugPrint('[DisciplinaryActions][$label] Response: ${response.body}');
    String message = 'Failed to fetch disciplinary actions (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        message = decoded['message'].toString();
      } else if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  static Future<List<DisciplinaryActionModel>> getAdminList({
    String? status,
  }) async {
    final query = <String, String>{
      if (status != null && status.isNotEmpty && status != 'All')
        'status': status.toLowerCase(),
    };
    final uri = Uri.parse('$_baseUrl/admin').replace(queryParameters: query);
    final response = await http.get(uri, headers: _jsonHeaders());
    return _parseList('Admin', uri.toString(), response);
  }

  static Future<List<DisciplinaryActionModel>> getSuperAdminList({
    String? status,
  }) async {
    final query = <String, String>{
      if (status != null && status.isNotEmpty && status != 'All')
        'status': status.toLowerCase(),
    };
    final uri = Uri.parse('$_baseUrl/super-admin').replace(queryParameters: query);
    final response = await http.get(uri, headers: _jsonHeaders());
    return _parseList('SuperAdmin', uri.toString(), response);
  }

  static Future<List<DisciplinaryActionModel>> getMyActions() async {
    final uri = Uri.parse('$_baseUrl/my');
    final response = await http.get(uri, headers: _jsonHeaders());
    return _parseList('Employee', uri.toString(), response);
  }

  static Future<DisciplinaryActionModel> getById(String id) async {
    final uri = Uri.parse('$_baseUrl/$id');
    final response = await http.get(uri, headers: _jsonHeaders());

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('No data returned');
      return DisciplinaryActionModel.fromJson(data);
    }
    throw Exception('Failed to load disciplinary action (${response.statusCode})');
  }

  static Future<void> _submitJson({
    required String method,
    required String endpoint,
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('[DisciplinaryActions] $method $endpoint');

    final response = method == 'PUT'
        ? await http.put(
            uri,
            headers: _jsonHeaders(),
            body: jsonEncode(fields),
          )
        : await http.post(
            uri,
            headers: _jsonHeaders(),
            body: jsonEncode(fields),
          );

    debugPrint('[DisciplinaryActions] Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    debugPrint('[DisciplinaryActions] Response: ${response.body}');
    String message = 'Failed to submit disciplinary action (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final m = decoded['message'];
      if (m != null) message = m.toString();
    } catch (_) {}

    throw Exception(message);
  }

  static Future<void> create({
    required Map<String, String> fields,
  }) async {
    return _submitJson(
      method: 'POST',
      endpoint: '',
      fields: fields,
    );
  }

  static Future<void> update({
    required String id,
    required Map<String, String> fields,
  }) async {
    return _submitJson(
      method: 'PUT',
      endpoint: '/$id',
      fields: fields,
    );
  }

  static Future<void> resubmit({
    required String id,
    required Map<String, String> fields,
  }) async {
    return _submitJson(
      method: 'POST',
      endpoint: '/$id/resubmit',
      fields: fields,
    );
  }

  static Future<void> approve(String id) async {
    final uri = Uri.parse('$_baseUrl/$id/approve');
    final response = await http.post(uri, headers: _jsonHeaders());
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Failed to approve (${response.statusCode})');
  }

  static Future<void> reject(String id, String rejectionReason) async {
    final uri = Uri.parse('$_baseUrl/$id/reject');
    final response = await http.post(
      uri,
      headers: _jsonHeaders(),
      body: jsonEncode({'rejectionReason': rejectionReason}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Failed to reject (${response.statusCode})');
  }
}
