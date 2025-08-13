import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class AnnouncementService {
  static const String baseUrl = 'http://localhost:8080';

  // Get all announcements
  static Future<List<dynamic>> getAllAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/announcements'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch announcements');
      }
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  // Get latest announcements for employee dashboard
  static Future<List<dynamic>> getLatestAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/announcements/latest'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch latest announcements');
      }
    } catch (e) {
      print('Error fetching latest announcements: $e');
      return [];
    }
  }

  // Create announcement
  static Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String content,
    String priority = 'medium',
    bool isPinned = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/announcements'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'priority': priority,
          'pinned': isPinned,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create announcement');
      }
    } catch (e) {
      print('Error creating announcement: $e');
      rethrow;
    }
  }

  // Update announcement
  static Future<Map<String, dynamic>> updateAnnouncement({
    required int id,
    required String title,
    required String content,
    String priority = 'medium',
    bool isPinned = false,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'priority': priority,
          'pinned': isPinned,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update announcement');
      }
    } catch (e) {
      print('Error updating announcement: $e');
      rethrow;
    }
  }

  // Delete announcement
  static Future<bool> deleteAnnouncement(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting announcement: $e');
      return false;
    }
  }

  // Get announcement by ID
  static Future<Map<String, dynamic>?> getAnnouncementById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching announcement by ID: $e');
      return null;
    }
  }
} 