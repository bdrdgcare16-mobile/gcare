// lib/features/platform_admin/platform_admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/services/platform_admin_registration_service.dart';

import 'platform_admin_session.dart';
import 'platform_admin_theme.dart';

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

  Widget _statCard(String title, String value, IconData icon, Color bg,
      Color fg, VoidCallback? onTap) {
    return Expanded(
      child: PlatformAdminCard(
        hoverable: onTap != null,
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: fg),
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
                      color: PlatformAdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PlatformAdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          const PlatformAdminSectionHeader(
            title: 'Dashboard',
            titleSize: 26,
          ),
          const SizedBox(height: 4),
          Text(
            'Signed in as ${PlatformAdminSession.email}',
            style: const TextStyle(
              fontSize: 13,
              color: PlatformAdminColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: PlatformAdminColors.redBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: PlatformAdminColors.redFg),
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
                PlatformAdminColors.amberBg,
                PlatformAdminColors.amberFg,
                () => Navigator.of(context)
                    .pushReplacementNamed('/platform-admin/registrations'),
              ),
              const SizedBox(width: 16),
              _statCard(
                'Applications (first page)',
                _totalSampled == null ? '—' : '$_totalSampled',
                Icons.domain_verification_outlined,
                PlatformAdminColors.primarySoft,
                PlatformAdminColors.primary,
                () => Navigator.of(context)
                    .pushReplacementNamed('/platform-admin/registrations'),
              ),
              const SizedBox(width: 16),
              _statCard(
                'Review actions',
                'Read-only',
                Icons.lock_outline,
                PlatformAdminColors.grayBg,
                PlatformAdminColors.grayFg,
                null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PlatformAdminCard(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'This portal reviews organization registration applications. '
                'Milestone 3D-B is read-only: approve, reject and request-changes '
                'actions will be introduced in Milestone 3D-C.',
                style: TextStyle(
                  fontSize: 13,
                  color: PlatformAdminColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
