// lib/features/admin/admin_notifications_page.dart
//
// Admin notification history. Every record was created server-side scoped
// to this admin's userId + companyId; tapping a row marks it read and
// navigates to the related screen (tracking events -> employee day detail,
// tasks -> task details). Notification payloads are never trusted for
// authorization - destination screens re-fetch from the backend.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serv_app/features/admin/employee_detail_page.dart';
import 'package:serv_app/features/users/task_details_page.dart';
import 'package:serv_app/services/notification_service.dart';
import 'package:serv_app/features/admin/admin_theme.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  bool _loading = true;
  List<AppNotification> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await NotificationService.fetchNotifications(limit: 100);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    final ok = await NotificationService.markAllRead();
    if (!mounted) return;
    if (ok) {
      setState(() {
        _items = _items
            .map((n) => AppNotification(
                  id: n.id,
                  type: n.type,
                  title: n.title,
                  body: n.body,
                  entityType: n.entityType,
                  entityId: n.entityId,
                  data: n.data,
                  isRead: true,
                  pushStatus: n.pushStatus,
                  createdAt: n.createdAt,
                  readAt: n.readAt,
                ))
            .toList();
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'All notifications marked as read' : 'Failed to update'),
      ),
    );
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      // Optimistic local flip; server write is fire-and-forget.
      setState(() {
        _items = _items
            .map((x) => x.id == n.id
                ? AppNotification(
                    id: x.id,
                    type: x.type,
                    title: x.title,
                    body: x.body,
                    entityType: x.entityType,
                    entityId: x.entityId,
                    data: x.data,
                    isRead: true,
                    pushStatus: x.pushStatus,
                    createdAt: x.createdAt,
                    readAt: x.readAt,
                  )
                : x)
            .toList();
      });
      NotificationService.markRead(n.id);
    }

    if (!mounted) return;

    // Navigate by entity type; the payload only carries ids, destination
    // screens re-fetch and re-authorize against the backend.
    if (n.isTrackingEvent && n.empid.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmployeeDetailPage(
            employee: {
              'id': n.empid,
              if (n.dateIso.isNotEmpty) 'date': n.dateIso,
            },
          ),
        ),
      ).then((_) => _load());
      return;
    }

    if (n.entityType == 'task' && n.entityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailsPage(taskId: n.entityId),
        ),
      ).then((_) => _load());
      return;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'ATTENDANCE_AUTO_INACTIVATED':
        return Icons.timer_off_outlined;
      case 'LOCATION_DISABLED':
        return Icons.location_off;
      case 'LOCATION_ENABLED':
        return Icons.location_on;
      case 'PERMISSION_REVOKED':
        return Icons.gps_off;
      case 'TRACKING_INTERRUPTED':
      case 'TRACKING_GPS_DELAYED':
        return Icons.gps_not_fixed;
      case 'TRACKING_RECOVERED':
      case 'TRACKING_GPS_RECOVERED':
        return Icons.gps_fixed;
      case 'SUSPICIOUS_LOCATION':
        return Icons.warning_amber_rounded;
      case 'TASK_ASSIGNED':
      case 'TASK_COMPLETED':
        return Icons.assignment;
      case 'REQUEST_APPROVED':
        return Icons.check_circle_outline;
      case 'REQUEST_REJECTED':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _iconColorFor(String type) {
    switch (type) {
      case 'LOCATION_DISABLED':
        return Colors.red.shade700;
      case 'LOCATION_ENABLED':
        return Colors.green.shade700;
      case 'PERMISSION_REVOKED':
      case 'TRACKING_INTERRUPTED':
        return Colors.red.shade700;
      case 'TRACKING_GPS_DELAYED':
        return Colors.orange.shade800;
      case 'TRACKING_RECOVERED':
      case 'TRACKING_GPS_RECOVERED':
        return Colors.green.shade700;
      case 'SUSPICIOUS_LOCATION':
        return Colors.orange.shade800;
      case 'REQUEST_REJECTED':
        return Colors.red.shade400;
      case 'REQUEST_APPROVED':
        return Colors.green.shade600;
      default:
        return const Color(0xFF6A1B9A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.isRead).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: kAdminAppBarColor,
        actions: [
          if (unread > 0)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all),
              onPressed: _markAllRead,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('No notifications yet')),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) => _row(_items[i]),
                    ),
            ),
    );
  }

  Widget _row(AppNotification n) {
    final ts = n.createdAtDate;
    final when = ts == null ? '' : DateFormat('dd MMM yyyy, hh:mm a').format(ts);
    return ListTile(
      onTap: () => _open(n),
      tileColor: n.isRead ? null : const Color(0x146A1B9A),
      leading: CircleAvatar(
        backgroundColor: _iconColorFor(n.type).withValues(alpha: 0.12),
        child: Icon(_iconFor(n.type), color: _iconColorFor(n.type), size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              n.title.isEmpty ? n.kindLabel : n.title,
              style: TextStyle(
                fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
          if (!n.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF6A1B9A),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n.body.isNotEmpty)
            Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            [n.kindLabel, when, n.isRead ? 'Read' : 'Unread']
                .where((s) => s.isNotEmpty)
                .join('  •  '),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      trailing: (n.isTrackingEvent || n.entityType == 'task')
          ? const Icon(Icons.chevron_right)
          : null,
      isThreeLine: true,
    );
  }
}
