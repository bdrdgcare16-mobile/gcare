// lib/features/onboarding/screens/employee_login_page.dart

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/features/users/forgot_password_page.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/features/onboarding/guards/organization_policy_guard.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/services/fcm_test_service.dart';

// Web localStorage shim
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

const Color _kPrimary = Color(0xFF8C6EAF);
const Color _kPrimaryDark = Color(0xFF655193);
const Color _kPrimaryLight = Color(0xFFD1C4E9);
const Color _kFieldBg = Color(0xFFF7F4FC);

/// Dedicated login page for employees.
///
/// Validates organization code + email before invoking Firebase Authentication,
/// then finalizes authentication through the existing `/auth/firebase-login`
/// endpoint with an employee organization context.
class EmployeeLoginPage extends StatefulWidget {
  const EmployeeLoginPage({super.key});

  @override
  State<EmployeeLoginPage> createState() => _EmployeeLoginPageState();
}

class _EmployeeLoginPageState extends State<EmployeeLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _orgCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _orgCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _persist(String key, String value) async {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, value);
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _kPrimaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final organizationCode = _orgCodeController.text.trim().toUpperCase();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      // Step 1: Pre-validate organization + employee (no password sent).
      final preValid = await _preValidate(organizationCode: organizationCode, email: email);
      if (!preValid) {
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Firebase Authentication with email/password.
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        // ignore – best-effort cleanup of stale sessions
      }

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final idToken = await credential.user?.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to obtain Firebase ID token');
      }

      // Step 3: Backend authorization with organization context.
      final success = await _backendAuthorize(
        idToken: idToken,
        organizationCode: organizationCode,
      );

      if (!success) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      // Step 4: Navigate to employee dashboard.
      String employeeDocId = '';
      try {
        final decoded = JwtDecoder.decode(CompanyData.token);
        employeeDocId =
            (decoded['userId'] ?? decoded['uid'] ?? '').toString().trim();
      } catch (_) {}
      if (employeeDocId.isEmpty) employeeDocId = CompanyData.empid;

      // Step 4: Navigate through the organization policy gate before the
      // dashboard. The guard verifies required-policy acceptance server-side.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrganizationPolicyGuard(
            userName: CompanyData.name.isNotEmpty ? CompanyData.name : email.split('@').first,
            employeeDocId: employeeDocId,
          ),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(_firebaseErrorMessage(e));
      setState(() => _isLoading = false);
    } catch (e) {
      _showSnack('Login failed: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _preValidate({
    required String organizationCode,
    required String email,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/employee-login/validate'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'organizationCode': organizationCode,
              'email': email,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return true;
      }

      final data = _tryDecode(res.body);
      final message = (data?['message'] ?? data?['error'] ?? 'Invalid organization or email')
          .toString();
      _showSnack(message);
      return false;
    } on TimeoutException {
      _showSnack('Request timed out. Please try again.');
      return false;
    } catch (e) {
      _showSnack('Unable to verify organization. Please try again.');
      return false;
    }
  }

  Future<bool> _backendAuthorize({
    required String idToken,
    required String organizationCode,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/firebase-login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'organizationCode': organizationCode,
              'loginContext': 'employee',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        final data = _tryDecode(res.body);
        final message = (data?['message'] ?? data?['error'] ?? 'Login failed')
            .toString();
        _showSnack(message);
        return false;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final payload = data['data'] is Map ? data['data'] as Map<String, dynamic> : data;

      final token = (payload['token'] ?? payload['data']?['token'] ?? '').toString();
      final role = (payload['role'] ?? payload['data']?['role'] ?? '').toString();
      final empid = (payload['empid'] ??
              payload['empId'] ??
              payload['data']?['empid'] ??
              payload['data']?['empId'] ??
              '')
          .toString()
          .trim();
      final companyId = (payload['companyId'] ?? payload['data']?['companyId'] ?? '')
          .toString()
          .trim();
      final status = (payload['status'] ?? payload['data']?['status'] ?? 'active')
          .toString()
          .trim()
          .toLowerCase();
      final name = (payload['name'] ?? payload['data']?['name'] ?? '')
          .toString()
          .trim();

      if (token.isEmpty || role.isEmpty) {
        _showSnack('Invalid server response. Please contact support.');
        return false;
      }

      if (role != 'employee') {
        _showSnack('This login is only for employees.');
        return false;
      }

      if (status != 'active') {
        _showSnack('Account is not active. Please contact HR.');
        return false;
      }

      CompanyData.token = token;
      CompanyData.role = role;
      CompanyData.empid = empid;
      CompanyData.companyId = companyId;
      CompanyData.name = name;

      await _persist('token', token);
      await _persist('role', role);
      await _persist('companyId', companyId);
      await _persist('status', status);
      if (empid.isNotEmpty) {
        await _persist('empid', empid);
        await _persist('empId', empid);
      }
      if (name.isNotEmpty) await _persist('name', name);

      // Try to extract userDocId from JWT for consistency with existing login.
      String userDocId = '';
      try {
        final decoded = JwtDecoder.decode(token);
        userDocId = (decoded['userId'] ?? decoded['uid'] ?? '').toString();
        if (userDocId.isNotEmpty) await _persist('userDocId', userDocId);
      } catch (_) {
        // JWT decoding is optional for dashboard access
      }

      unawaited(FcmTestService.instance.registerDeviceIfReady());
      return true;
    } on TimeoutException {
      _showSnack('Authorization timed out. Please try again.');
      return false;
    } catch (e) {
      _showSnack('Authorization failed: $e');
      return false;
    }
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'invalid-email':
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled. Contact HR.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Login failed (${e.code}). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEF9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - 48),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Image.asset(
                      'assets/images/serv_new_logo-removebg.png',
                      height: 100,
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Employee Sign In',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D1B4E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your organization code and registered email',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 36),
                    _StyledField(
                      controller: _orgCodeController,
                      label: 'Organization Code',
                      hint: 'e.g. SERV001',
                      icon: Icons.business_outlined,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Organization code required' : null,
                    ),
                    const SizedBox(height: 16),
                    _StyledField(
                      controller: _emailController,
                      label: 'Registered Email',
                      hint: 'employee@company.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email required';
                        final regex = RegExp(
                          r"^[\w._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$",
                          caseSensitive: false,
                        );
                        if (!regex.hasMatch(v.trim())) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _StyledField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: _kPrimary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password required' : null,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _goToForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: _kPrimary,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryDark,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _kPrimaryDark.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: _contactHr,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimaryDark,
                        side: const BorderSide(color: _kPrimaryLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Contact HR'),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  void _contactHr() {
    _showSnack(
      'Please contact your HR team for account assistance.',
      isError: false,
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _kPrimary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _kFieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
