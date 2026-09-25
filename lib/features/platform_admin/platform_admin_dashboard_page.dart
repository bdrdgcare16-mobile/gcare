// lib/features/platform_admin/platform_admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/services/platform_admin_registration_service.dart';

import 'platform_admin_session.dart';

/// Portal landing page — a small operational overview of registration
/// applications. Read-only; review actions arrive with Milestone 3D-C.
class PlatformAdminDashboardPage extends StatefulWidget {
  const PlatformAdminDashboardPage({super.key});

  @override
  State<PlatformAdminDashboardPage> createState() =>
      _PlatformAdminDashboardPageState();
}

class _PlatformAdminDashboardPageState
    extends State<PlatformAdminDashboardPage> {
  int? _pendingCount;
  bool _pendingHasMore = false;
  int? _totalSampled;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Read-only counts from the list API — no dedicated stats endpoint
      // exists in 3D-B.
      final pending = await PlatformAdminRegistrationService.instance
          .listRegistrations(status: 'pending_approval', pageSize: 50);
      final all = await PlatformAdminRegistrationService.instance
          .listRegistrations(pageSize: 50);
      if (!mounted) return;
      setState(() {
        _pendingCount =
            (pending['registrations'] as List? ?? []).length;
        _pendingHasMore = pending['hasMore'] == true;
        _totalSampled = (all['registrations'] as List? ?? []).length;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Widget _statCard(String title, String value, IconData icon, Color color,
      VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E2450),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Signed in as ${PlatformAdminSession.email}',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFC62828)),
              ),
            ),
          Row(
            children: [
              _statCard(
                'Pending applications',
                _pendingCount == null
                    ? '—'
                    : '$_pendingCount${_pendingHasMore ? '+' : ''}',
                Icons.hourglass_top_outlined,
                Colors.orange,
                () => Navigator.of(context)
                    .pushReplacementNamed('/platform-admin/registrations'),
              ),
              const SizedBox(width: 16),
              _statCard(
                'Applications (first page)',
                _totalSampled == null ? '—' : '$_totalSampled',
                Icons.domain_verification_outlined,
                const Color(0xFF655193),
                () => Navigator.of(context)
                    .pushReplacementNamed('/platform-admin/registrations'),
              ),
              const SizedBox(width: 16),
              _statCard(
                'Review actions',
                'Read-only',
                Icons.lock_outline,
                Colors.blueGrey,
                null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'This portal reviews organization registration applications. '
              'Milestone 3D-B is read-only: approve, reject and request-changes '
              'actions will be introduced in Milestone 3D-C.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
