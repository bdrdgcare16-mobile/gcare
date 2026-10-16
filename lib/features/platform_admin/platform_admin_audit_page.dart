// lib/features/platform_admin/platform_admin_audit_page.dart

import 'package:flutter/material.dart';

/// Audit / Review History tab for the Platform Admin portal.
///
/// Milestone 3D-B is read-only: no review decisions exist yet, so there is
/// no cross-application review feed to display. Per-application audit
/// trails (draft creation, verification, document uploads, submission)
/// are visible on each application's detail page. Once Milestone 3D-C
/// introduces review actions, this page will list review decisions with
/// reviewer identity, comments and timestamps.
class PlatformAdminAuditPage extends StatelessWidget {
  const PlatformAdminAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audit / Review History',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E2450),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Review decisions and their audit events will appear here.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 40,
                  color: Color(0xFF9C8FC4),
                ),
                SizedBox(height: 12),
                Text(
                  'No review history yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'This milestone is read-only — applications have not been '
                  'approved, rejected or sent back for changes. Applicant-side '
                  'audit events (verification, uploads, submission) are shown '
                  'on each application\'s detail page.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
