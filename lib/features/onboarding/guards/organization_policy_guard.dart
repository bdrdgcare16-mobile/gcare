// lib/features/onboarding/guards/organization_policy_guard.dart

import 'package:flutter/material.dart';

import 'package:serv_app/features/users/home_screen_page.dart';
import 'package:serv_app/features/users/login_page.dart';
import '../screens/organization_policies_page.dart';
import '../services/organization_policy_service.dart';

/// Shared checkpoint between employee authentication and the dashboard.
///
/// Reached from:
///  - EmployeeLoginPage after a successful login
///  - AuthGuard when restoring a valid employee session
///
/// Flow:
///   load /organization/policies/acceptance-status
///     - allAccepted == true  -> HomeScreen
///     - allAccepted == false -> OrganizationPoliciesPage
///     - 401/403              -> LoginPage (session expired handling)
///     - any other failure    -> error + retry (never bypasses the check)
class OrganizationPolicyGuard extends StatefulWidget {
  final String userName;
  final String employeeDocId;

  const OrganizationPolicyGuard({
    super.key,
    required this.userName,
    required this.employeeDocId,
  });

  @override
  State<OrganizationPolicyGuard> createState() =>
      _OrganizationPolicyGuardState();
}

class _OrganizationPolicyGuardState extends State<OrganizationPolicyGuard> {
  bool _checking = true;
  bool _navigated = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _go(Widget destination) {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Future<void> _check() async {
    if (_navigated) return;
    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final status =
          await OrganizationPolicyService.instance.getAcceptanceStatus();
      if (!mounted) return;

      if (status.allAccepted) {
        _go(HomeScreen(
          userName: widget.userName,
          employeeDocId: widget.employeeDocId,
        ));
      } else {
        _go(OrganizationPoliciesPage(
          userName: widget.userName,
          employeeDocId: widget.employeeDocId,
        ));
      }
    } on PolicyAuthException {
      // Expired/invalid session or non-employee — reuse existing login flow.
      _go(const LoginPage());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEF9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 56,
                color: Color(0xFF655193),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to verify policy status',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF655193),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error?.toString() ??
                    'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _check,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
