// lib/features/admin/admin_feature_gate.dart

import 'package:flutter/material.dart';

import '../../models/organization_context.dart';

/// Reusable route/page guard for organization features.
///
/// Wraps a module page: renders [child] when the loaded
/// [OrganizationContext] shows the feature enabled, otherwise a plain
/// "Feature Not Enabled" surface. When no context has been loaded at all
/// (legacy session / still loading), the child is allowed through — the
/// backend requireFeature middleware remains the real enforcement.
class FeatureGate extends StatelessWidget {
  final String feature;
  final List<String> anyOf;
  final Widget child;

  const FeatureGate({super.key, required this.feature, required this.child})
      : anyOf = const [];

  /// Any-of variant: renders [child] when at least one of [features] is
  /// enabled — mirrors backend requireAnyFeature (e.g. Live Attendance is
  /// reachable with `attendance` OR `location_tracking`).
  const FeatureGate.anyOf({
    super.key,
    required List<String> features,
    required this.child,
  })  : feature = '',
        anyOf = features;

  @override
  Widget build(BuildContext context) {
    final org = OrganizationContext.current;
    if (org == null ||
        org.isFeatureEnabled(feature) ||
        anyOf.any(org.isFeatureEnabled)) {
      return child;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Not Enabled'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'This module is not enabled for your organization.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Contact your platform administrator to enable it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
