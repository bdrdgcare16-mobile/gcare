// lib/services/fcm_test_service.dart
//
// FCM handling for SERV: permission + token, device registration with the
// backend, a visible foreground notification banner, and secure
// notification-tap navigation (TASK_ASSIGNED only, for now).
//
// This intentionally does NOT touch Firestore directly, nor does it trust
// the notification payload as authorization — tapping a notification only
// navigates to a screen that re-fetches the entity from the authenticated
// backend API (see TaskDetailsPage).
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:serv_app/core/app_navigator.dart';
import 'package:serv_app/features/users/background_tasks.dart' as bg;
import 'package:serv_app/features/users/task_details_page.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

class FcmTestService {
  FcmTestService._();

  static final FcmTestService instance = FcmTestService._();

  bool _initialized = false;
  String? _fcmToken;

  /// Requests notification permission, logs the FCM token, registers the
  /// device with the backend, and wires up listeners for token refresh,
  /// foreground messages, and notification taps.
  ///
  /// Safe to call multiple times; the actual setup only runs once.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Local notifications shown for foreground FCM messages are tapped
    // through the shared plugin instance (see background_tasks.dart) — hook
    // our handler in before that plugin is initialized.
    bg.notificationTapHandler = (NotificationResponse details) {
      final payload = details.payload;
      if (payload == null || payload.isEmpty) return;
      try {
        final data = Map<String, dynamic>.from(
          jsonDecode(payload) as Map,
        ).map((k, v) => MapEntry(k, v?.toString() ?? ''));
        _handleNotificationTap(data);
      } catch (e) {
        debugPrint('[FCM] Failed to parse local notification payload');
      }
    };

    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    _fcmToken = await messaging.getToken();

    await registerDeviceIfReady();

    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      registerDeviceIfReady();
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _logReceived(message, source: 'onMessageOpenedApp');
      _handleNotificationTap(
        message.data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );
    });

    // App was launched by tapping a notification from a terminated state.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _logReceived(initialMessage, source: 'getInitialMessage');
      _handleNotificationTap(
        initialMessage.data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );
    }
  }

  void _logReceived(RemoteMessage message, {required String source}) {
    debugPrint('[FCM] Notification received ($source)');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logReceived(message, source: 'onMessage');

    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title == null && body == null) {
      return; // data-only message, nothing visible to show
    }

    try {
      await bg.ensureNotificationChannelsReady();

      const androidDetails = AndroidNotificationDetails(
        bg.kUpdatesChannelId,
        'SERV Updates',
        channelDescription: 'Task and general notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      await bg.sharedLocalNotificationsPlugin.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: jsonEncode(
          message.data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        ),
      );
    } catch (e) {
      debugPrint('[FCM] Failed to show foreground notification: $e');
    }
  }

  void _handleNotificationTap(Map<String, String> data) {
    final type = data['type'] ?? '';
    final entityType = data['entityType'] ?? '';
    final entityId = data['entityId'] ?? '';

    debugPrint(
      '[FCM] Notification tapped -> type=$type entityType=$entityType entityId=$entityId',
    );

    // Type-based routing only; the destination screen re-fetches the
    // entity from the backend and re-checks authorization there.
    if (type == 'TASK_ASSIGNED' &&
        entityType == 'task' &&
        entityId.isNotEmpty) {
      final nav = AppNavigator.state;
      if (nav == null) return;
      nav.push(
        MaterialPageRoute(builder: (_) => TaskDetailsPage(taskId: entityId)),
      );
    }
  }

  /// Sends the current FCM token to the backend for the authenticated user.
  /// No-op until we have both a JWT and a token (backend derives
  /// userId/companyId from the JWT — never trusts client-supplied values).
  Future<void> registerDeviceIfReady() async {
    final token = _fcmToken;
    final jwt = CompanyData.token;
    if (token == null || token.isEmpty || jwt.isEmpty) return;

    try {
      final resp = await ApiService.post(
        '/notifications/register-device',
        body: jsonEncode({
          'fcmToken': token,
          'platform': 'android',
          'deviceName': 'android-device',
        }),
      );
      debugPrint('[FCM] Device registration status: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Device registration failed: $e');
    }
  }

  /// Marks the current device inactive on the backend. Call this before
  /// clearing the JWT/session on logout.
  Future<void> unregisterDevice() async {
    final token = _fcmToken;
    final jwt = CompanyData.token;
    if (token == null || token.isEmpty || jwt.isEmpty) return;

    try {
      final resp = await ApiService.post(
        '/notifications/unregister-device',
        body: jsonEncode({'fcmToken': token}),
      );
      debugPrint('[FCM] Device unregistration status: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Device unregistration failed: $e');
    }
  }
}
