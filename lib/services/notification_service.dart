// lib/services/notification_service.dart
//
// Client for the authenticated notification history API:
//   GET  /notifications?unreadOnly=&limit=
//   GET  /notifications/unread-count
//   POST /notifications/:id/read | /:id/unread | /read-all
//
// Every call goes through ApiService so the JWT is attached automatically;
// the backend derives companyId + recipientUserId from the token, so the
// client never supplies them.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serv_app/services/api_service.dart';

/// One notification history record (see notificationController.serialize).
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? pushStatus;
  final String? createdAt;
  final String? readAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.isRead,
    this.pushStatus,
    this.createdAt,
    this.readAt,
  });

  /// `createdAt`/`readAt` arrive as ISO strings (server-side serialized).
  DateTime? get createdAtDate {
    final v = createdAt;
    if (v == null || v.isEmpty) return null;
    return DateTime.tryParse(v)?.toLocal();
  }

  /// Convenience accessors for tracking_event navigation metadata.
  String get empid => (data['empid'] ?? '').toString();
  String get eventType => (data['eventType'] ?? '').toString();
  String get dateIso => (data['dateIso'] ?? '').toString();

  /// Rows whose `data` carries empid+dateIso and can deep-link to
  /// EmployeeDetailPage: per-event notifications (tracking_event) and
  /// heartbeat alerts (tracking_heartbeat) share that payload shape.
  bool get isTrackingEvent =>
      entityType == 'tracking_event' || entityType == 'tracking_heartbeat';

  /// Short label for the notification kind shown in the history list.
  String get kindLabel {
    switch (type) {
      case 'LOCATION_DISABLED':
        return 'GPS Disabled';
      case 'LOCATION_ENABLED':
        return 'GPS Enabled';
      case 'PERMISSION_REVOKED':
        return 'Permission Revoked';
      case 'TRACKING_INTERRUPTED':
        return 'Tracking Interrupted';
      case 'TRACKING_RECOVERED':
        return 'Tracking Resumed';
      case 'TRACKING_GPS_DELAYED':
        return 'GPS Delayed';
      case 'TRACKING_GPS_RECOVERED':
        return 'GPS Recovered';
      case 'SUSPICIOUS_LOCATION':
        return 'Suspicious Location';
      case 'TASK_ASSIGNED':
        return 'Task Assigned';
      case 'TASK_COMPLETED':
        return 'Task Completed';
      case 'LEAVE_REQUEST':
        return 'Leave Request';
      case 'PERMISSION_REQUEST':
        return 'Permission Request';
      case 'OVERTIME_REQUEST':
        return 'Overtime Request';
      case 'HALF_DAY_REQUEST':
        return 'Half-Day Request';
      case 'COMP_OFF_REQUEST':
        return 'Comp-Off Request';
      case 'REQUEST_APPROVED':
        return 'Request Approved';
      case 'REQUEST_REJECTED':
        return 'Request Rejected';
      default:
        return type.isEmpty ? 'Notification' : type;
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    return AppNotification(
      id: (j['id'] ?? '').toString(),
      type: (j['type'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      entityType: (j['entityType'] ?? '').toString(),
      entityId: (j['entityId'] ?? '').toString(),
      data: j['data'] is Map
          ? Map<String, dynamic>.from(j['data'] as Map)
          : const {},
      isRead: j['isRead'] == true,
      pushStatus: j['pushStatus']?.toString(),
      createdAt: j['createdAt']?.toString(),
      readAt: j['readAt']?.toString(),
    );
  }
}

class NotificationService {
  NotificationService._();

  /// Latest notifications for the signed-in user (server-scoped to their
  /// company + user id). Returns an empty list on any failure - the bell
  /// badge must never crash the dashboard.
  static Future<List<AppNotification>> fetchNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final resp = await ApiService.get('/notifications', query: {
        if (unreadOnly) 'unreadOnly': 'true',
        'limit': '$limit',
      });
      if (resp.statusCode != 200) return const [];
      final body = jsonDecode(resp.body);
      final list = body is Map && body['notifications'] is List
          ? body['notifications'] as List
          : const [];
      return list
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Unread count for the bell badge. 0 on any failure.
  static Future<int> fetchUnreadCount() async {
    try {
      final resp = await ApiService.get('/notifications/unread-count');
      if (resp.statusCode != 200) return 0;
      final body = jsonDecode(resp.body);
      return body is Map ? (body['count'] as num? ?? 0).toInt() : 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> markRead(String id) => _postOk('/notifications/$id/read');

  static Future<bool> markUnread(String id) =>
      _postOk('/notifications/$id/unread');

  static Future<bool> markAllRead() => _postOk('/notifications/read-all');

  static Future<bool> _postOk(String path) async {
    try {
      final http.Response resp = await ApiService.post(path, body: '{}');
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
