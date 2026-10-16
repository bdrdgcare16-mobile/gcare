import 'package:flutter/material.dart';

import 'platform_admin_shell.dart';

/// Placeholder: the audit/review-history backend is not mounted in this
/// build, so the menu item is preserved but reports its status honestly.
class PlatformAdminAuditPage extends StatelessWidget {
  const PlatformAdminAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformAdminShell(
      selected: PlatformAdminSection.audit,
      title: 'Audit / Review History',
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Audit history is not available in this build.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
