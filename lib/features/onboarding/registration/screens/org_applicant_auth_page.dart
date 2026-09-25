// lib/features/onboarding/registration/screens/org_applicant_auth_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/models/company_data.dart';
import '../guards/registration_resume_guard.dart';
import '../services/organization_registration_service.dart';

/// Account gate for organization registration (3D-C follow-up).
///
/// The applicant must sign in — or create — a Firebase Auth account BEFORE
/// any registration data is collected. The account is exchanged for a
/// restricted `org_applicant` SERV session via POST /auth/register-applicant;
/// organization/admin roles are only granted later at activation.
class OrgApplicantAuthPage extends StatefulWidget {
  const OrgApplicantAuthPage({super.key});

  @override
  State<OrgApplicantAuthPage> createState() => _OrgApplicantAuthPageState();
}

class _OrgApplicantAuthPageState extends State<OrgApplicantAuthPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _createMode = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _persist(String key, String value) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(key, value);
    } catch (_) {}
  }

  String _friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists for this email — sign in instead.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'network-request-failed':
          return 'Network unavailable. Please check your connection.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    }
    if (e is RegistrationApiException) return e.message;
    return 'Something went wrong. Please try again.';
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      final cred = _createMode
          ? await auth.createUserWithEmailAndPassword(
              email: email, password: password)
          : await auth.signInWithEmailAndPassword(
              email: email, password: password);
      final idToken = await cred.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw const RegistrationApiException(
            'Could not verify the signed-in account.');
      }

      final session =
          await OrganizationRegistrationService.instance.registerApplicant(
        idToken,
      );

      final token = (session['token'] ?? '').toString();
      final role = (session['role'] ?? '').toString();
      if (token.isEmpty || role != 'org_applicant') {
        throw const RegistrationApiException(
            'This account is not an organization applicant.');
      }

      CompanyData.token = token;
      CompanyData.role = role;
      CompanyData.companyId = (session['companyId'] ?? '').toString();
      CompanyData.email = email;

      await _persist('token', token);
      await _persist('role', role);
      await _persist('companyId', CompanyData.companyId);
      await _persist('email', email);
      await _persist('status', 'active');
      final name = (session['name'] ?? '').toString();
      if (name.isNotEmpty) await _persist('name', name);
      await _persist('userDocId', (session['uid'] ?? '').toString());

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegistrationResumeGuard()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Organization Registration'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign in to continue',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F3D3E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your organization application is saved to this account — '
                  'you can return on any device to continue or check its '
                  'status.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF555555),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Sign in')),
                    ButtonSegment(value: true, label: Text('Create account')),
                  ],
                  selected: {_createMode},
                  onSelectionChanged: _busy
                      ? null
                      : (s) => setState(() => _createMode = s.first),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF655193),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(_createMode ? 'Create account' : 'Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
