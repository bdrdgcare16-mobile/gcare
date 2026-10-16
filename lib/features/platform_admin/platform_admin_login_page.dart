// lib/features/platform_admin/platform_admin_login_page.dart

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/config/api_config.dart';

import 'pa_ui.dart';
import 'platform_admin_session.dart';

/// Browser login for the Platform Admin portal.
///
/// Uses the shared Firebase Authentication infrastructure — no parallel
/// password store. After Firebase sign-in, the ID token is exchanged for
/// a SERV JWT via /auth/firebase-login exactly like the main app, but the
/// account is admitted ONLY when the backend reports role
/// 'platform_admin'. Server-side roleMiddleware provides the real
/// enforcement; this gate only controls portal UX.
class PlatformAdminLoginPage extends StatefulWidget {
  const PlatformAdminLoginPage({super.key});

  @override
  State<PlatformAdminLoginPage> createState() => _PlatformAdminLoginPageState();
}

class _PlatformAdminLoginPageState extends State<PlatformAdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      // Clear any stale Firebase session (web persists users in indexedDB).
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final idToken = await cred.user?.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to obtain Firebase token');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/firebase-login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw Exception(
          data['message']?.toString() ??
              data['error']?.toString() ??
              'Sign-in failed (${response.statusCode})',
        );
      }

      final token = (data['token'] ?? data['data']?['token'] ?? '').toString();
      final role = (data['role'] ?? data['data']?['role'] ?? '').toString();

      if (token.isEmpty || role.isEmpty) {
        throw Exception('Invalid server response. Token or role missing.');
      }

      // Portal admits platform_admin only — every other role is signed out.
      if (role != PlatformAdminSession.requiredRole) {
        await PlatformAdminSession.signOut();
        setState(() {
          _error =
              'This account is not authorized for the Platform Admin portal.';
        });
        return;
      }

      PlatformAdminSession.save(token: token, email: email);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/platform-admin/dashboard',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[PlatformAdmin] Firebase sign-in failed: ${e.code}');
      setState(() {
        _error = switch (e.code) {
          'user-not-found' ||
          'wrong-password' ||
          'invalid-credential' =>
            'Invalid email or password.',
          'too-many-requests' => 'Too many attempts. Try again later.',
          'user-disabled' => 'This account is disabled.',
          _ => 'Sign-in failed (${e.code}).',
        };
      });
    } catch (e) {
      debugPrint('[PlatformAdmin] login error: $e');
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: PaCard(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [PaColors.primary, PaColors.deep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SERV Platform Admin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PaColors.text,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tenant & organization administration portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: PaColors.muted),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: paInputDecoration('',
                          label: 'Email', prefixIcon: Icons.mail_outline),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty || !value.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: paInputDecoration('',
                              label: 'Password', prefixIcon: Icons.lock_outline)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: PaColors.muted,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Enter your password' : null,
                      onFieldSubmitted: (_) => _busy ? null : _signIn(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFEF9A9A),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: _busy ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PaColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Access is restricted to SERV platform\n'
                      'administrators (platform_admin accounts).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: PaColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
