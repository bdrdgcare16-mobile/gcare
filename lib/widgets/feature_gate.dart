import 'package:flutter/material.dart';
import 'package:serv_app/services/feature_service.dart';

/// Route-level guard: wraps a page and shows an Access Denied screen when the
/// tenant's feature entitlement does not include [feature]. Used for named
/// routes and any page that could be opened without going through a
/// gated menu entry.
class FeatureGate extends StatelessWidget {
  final String feature;
  final Widget child;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (FeatureAccess.has(feature)) return child;
    return const FeatureAccessDenied();
  }
}

class FeatureAccessDenied extends StatelessWidget {
  const FeatureAccessDenied({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: const Color(0xFF8C6EAF),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Color(0xFF8C6EAF)),
            const SizedBox(height: 16),
            const Text(
              'This feature is not enabled for your company.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact your platform administrator to enable it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
