import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/realtime_provider.dart';
import '../widgets/notification_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          Consumer<RealtimeProvider>(
            builder: (context, realtimeProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'clear') {
                    realtimeProvider.clearNotifications();
                  } else if (value == 'mark_all_read') {
                    for (int i = 0; i < realtimeProvider.notifications.length; i++) {
                      realtimeProvider.markNotificationAsRead(i);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read),
                        SizedBox(width: 8),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear all'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          Consumer<RealtimeProvider>(
            builder: (context, realtimeProvider, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                color: realtimeProvider.isConnected ? Colors.green[50] : Colors.red[50],
                child: Row(
                  children: [
                    Icon(
                      realtimeProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                      color: realtimeProvider.isConnected ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      realtimeProvider.isConnected 
                        ? 'Connected to real-time updates' 
                        : 'Disconnected from real-time updates',
                      style: TextStyle(
                        color: realtimeProvider.isConnected ? Colors.green[700] : Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Notification count
          Consumer<RealtimeProvider>(
            builder: (context, realtimeProvider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${realtimeProvider.notifications.length} notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (realtimeProvider.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${realtimeProvider.unreadCount} unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          
          // Notifications list
          Expanded(
            child: const NotificationList(),
          ),
        ],
      ),
    );
  }
} 