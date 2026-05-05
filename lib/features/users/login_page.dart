import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/models/company_profile.dart';
import 'package:serv_app/utils/location_permission_dialog.dart';

// Web localStorage shim
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/features/users/home_screen_page.dart';
import 'package:serv_app/features/admin/admin_dashboard_page.dart';
import 'package:serv_app/features/admin/company_details_page.dart';
import 'package:serv_app/services/api_service.dart';

// 👉 Keep the new, dedicated page-based Forgot Password flow.
import 'forgot_password_page.dart';

// ===== THEME =====
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final idController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool _isEmpLoading = false;
  bool _isAdminLoading = false;

  bool get _isAnyLoginLoading => _isEmpLoading || _isAdminLoading;

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------- UI helpers ----------
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _persist(String key, String value) async {
    try {
      html.window.localStorage[key] = value; // web
    } catch (_) {}
    final sp = await SharedPreferences.getInstance(); // mobile/desktop
    await sp.setString(key, value);
  }

  // ---------- PERMISSION FLOW (using unified dialog) ----------
  Future<void> _showPermissionIntroThenRequest() async {
    await LocationPermissionDialog.showIfNeeded(context);
  }

  // ---------- COMPANY PROFILE CHECK (from your old page) ----------
  /// Returns { exists: bool, data: Map, raw: Map }.
  /// NOTE: 404 is treated as {exists:false} so we route to setup without error.
  Future<Map<String, dynamic>> _checkCompanyProfile({
    required String token,
    required String adminEmail,
  }) async {
    Map<String, dynamic> norm(dynamic body) {
      final m = (body is Map) ? body : <String, dynamic>{};
      final exists = (m['exists'] == true) ||
          (m['filled'] == true) ||
          (m['hasProfile'] == true);
      final data = (m['data'] is Map)
          ? (m['data'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      return {'exists': exists, 'data': data, 'raw': m};
    }

    Future<Map<String, dynamic>> treat404() async => {
          'exists': false,
          'data': <String, dynamic>{},
          'raw': <String, dynamic>{}
        };

    // 1) Try /company/profile/check
    final u1 = Uri.parse('${ApiService.baseUrl}/company/profile/check');
    try {
      final r1 = await http.get(u1, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 15));
      debugPrint('[GET] $u1 -> ${r1.statusCode}');
      if (r1.statusCode == 200) return norm(jsonDecode(r1.body));
      if (r1.statusCode == 404) return treat404();
      // fall through to fallback for non-200/404
    } catch (e) {
      debugPrint('profile/check exception: $e');
    }

    // 2) Fallback /company/profile?email=...
    final u2 = Uri.parse('${ApiService.baseUrl}/company/profile')
    .replace(queryParameters: {'email': adminEmail.trim().toLowerCase()});
    final r2 = await http.get(u2, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 15));

    debugPrint('[GET] $u2 -> ${r2.statusCode}');
    if (r2.statusCode == 200) return norm(jsonDecode(r2.body));
    if (r2.statusCode == 404) return treat404();

    // any other status is a real error
    dynamic err;
    try {
      err = jsonDecode(r2.body);
    } catch (_) {}
    throw Exception('HTTP ${r2.statusCode} ${r2.reasonPhrase} ${err ?? ''}');
  }

  // ---------- LOGIN (merged: old flow + new permission + new forgot) ----------
Future<void> _login({required bool isAdmin}) async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    if (isAdmin) {
      _isAdminLoading = true;
    } else {
      _isEmpLoading = true;
    }
  });

  try {
    final email = idController.text.trim().toLowerCase();
    final pwd = passwordController.text;

    debugPrint('Current API Base URL: ${ApiService.baseUrl}');

    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': pwd,
          }),
        )
        .timeout(const Duration(seconds: 15));

    debugPrint('LOGIN STATUS: ${response.statusCode}');
    debugPrint('LOGIN BODY: ${response.body}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final token = (data['token'] ?? data['data']?['token'] ?? '').toString();
      final role = (data['role'] ?? data['data']?['role'] ?? '').toString();

      final empId = (data['empId'] ??
              data['empid'] ??
              data['data']?['empId'] ??
              data['data']?['empid'] ??
              data['user']?['empId'] ??
              data['user']?['empid'] ??
              '')
          .toString()
          .trim();

      final companyId = (data['companyId'] ??
              data['data']?['companyId'] ??
              data['user']?['companyId'] ??
              '')
          .toString()
          .trim();

      final name = (data['name'] ??
              data['data']?['name'] ??
              data['user']?['name'] ??
              '')
          .toString()
          .trim();

      if (token.isEmpty || role.isEmpty) {
        _showSnack('Invalid server response. Token or role missing.');
        return;
      }

      if (isAdmin && role != 'admin') {
        _showSnack("Not authorized as admin.");
        return;
      }

      if (!isAdmin && role != 'employee') {
        _showSnack("Not authorized as employee.");
        return;
      }

      CompanyData.token = token;
      CompanyData.role = role;
      CompanyData.empid = empId;
      CompanyData.companyId = companyId;

      // Extract empid from JWT token as fallback
      final decoded = JwtDecoder.decode(token);

      final empIdFromToken = (decoded['empid'] ??
              decoded['empId'] ??
              decoded['employeeId'] ??
              '')
          .toString()
          .trim();

      final finalEmpId = empId.isNotEmpty ? empId : empIdFromToken;

      CompanyData.empid = finalEmpId;

      if (finalEmpId.isNotEmpty) {
        await _persist('empid', finalEmpId);
        await _persist('empId', finalEmpId);
      }

      await _persist('token', token);
      await _persist('role', role);

      if (companyId.isNotEmpty) {
        await _persist('companyId', companyId);
      }

      if (name.isNotEmpty) {
        await _persist('name', name);
      }

      debugPrint('User authentication completed - role: ${CompanyData.role}');
      debugPrint('Employee ID exists: ${CompanyData.empid.isNotEmpty}');
      debugPrint('Company ID exists: ${CompanyData.companyId.isNotEmpty}');

      if (isAdmin) {
        final result = await _checkCompanyProfile(
          token: token,
          adminEmail: email,
        );

        final exists = result['exists'] == true;
        final companyData =
            result['data'] as Map<String, dynamic>? ?? const {};

        if (!mounted) return;

        if (exists) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AdminDashboard(
                companyProfile: CompanyProfile(
                  name: (companyData['companyName'] ?? '').toString(),
                  adminName: (companyData['adminName'] ?? '').toString(),
                  logoUrl: companyData['logoUrl']?.toString(),
                ),
              ),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const CompanyDetailsFormPage(),
            ),
          );
        }
      } else {
        String docId = '';

        try {
          final decoded = JwtDecoder.decode(token);
          docId = (decoded['userId'] ?? decoded['uid'] ?? '').toString();

          final jwtEmpId =
              (decoded['empId'] ?? decoded['empid'] ?? '').toString().trim();

          final jwtCompanyId =
              (decoded['companyId'] ?? '').toString().trim();

          if (CompanyData.empid.isEmpty && jwtEmpId.isNotEmpty) {
            CompanyData.empid = jwtEmpId;
            await _persist('empId', jwtEmpId);
            await _persist('empid', jwtEmpId);
          }

          if (CompanyData.companyId.isEmpty && jwtCompanyId.isNotEmpty) {
            CompanyData.companyId = jwtCompanyId;
            await _persist('companyId', jwtCompanyId);
          }
        } catch (_) {}

        if (docId.isNotEmpty) {
          await _persist('userDocId', docId);
        }

        if (mounted) {
          await _showPermissionIntroThenRequest();
        }

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: name.isNotEmpty ? name : email.split('@').first,
              employeeDocId: docId,
            ),
          ),
          (route) => false,
        );
      }
    } else {
      final msg =
          (data['message'] ?? data['error'] ?? 'Login failed').toString();
      _showSnack(msg);
    }
  } catch (e) {
    _showSnack('Error: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isEmpLoading = false;
        _isAdminLoading = false;
      });
    }
  }
}

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 96),
                        Image.asset('assets/images/splash_logo.png',
                        // Image.asset('test/apple.JPEG',
                            height: 110, width: 110, fit: BoxFit.cover),
                        const SizedBox(height: 10),
                        const Text('Sign In',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 30),

                        // Email
                        TextFormField(
                          controller: idController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Enter email",
                            prefixIcon:
                                const Icon(Icons.email, color: kButtonColor),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Email required";
                            }
                            final emailRegex = RegExp(
                              r"^[\w._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$",
                              caseSensitive: false,
                            );
                            if (!emailRegex.hasMatch(val.trim())) {
                              return "Enter valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "Enter password",
                            prefixIcon:
                                const Icon(Icons.lock, color: kButtonColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: kButtonColor,
                              ),
                              onPressed: () => setState(
                                () => isPasswordVisible = !isPasswordVisible,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) =>
                              (val == null || val.isEmpty)
                                  ? "Password required"
                                  : null,
                        ),

                        // 👉 Keep the new navigation to a dedicated page
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: kAppBarColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Employee
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isAnyLoginLoading
                                ? null
     : () => _login(isAdmin: false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kButtonColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isEmpLoading
                                ? const _ArcLoader(
                                    size: 22, color: Colors.white)
                                : const Text("Sign in as employee",
                                    style: TextStyle(color: kTextColor)),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Admin
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isAnyLoginLoading
                                ? null
                                : () => _login(isAdmin: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kButtonColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isAdminLoading
                                ? const _ArcLoader(
                                    size: 22, color: Colors.white)
                                : const Text("Sign in as admin",
                                    style: TextStyle(color: kTextColor)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Loader (kept)
class _ArcLoader extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  const _ArcLoader({
    required this.size,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  State<_ArcLoader> createState() => _ArcLoaderState();
}

class _ArcLoaderState extends State<_ArcLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Transform.rotate(
            angle: _c.value * 2 * math.pi,
            child: CustomPaint(
              painter: _ArcPainter(
                color: widget.color,
                strokeWidth: widget.strokeWidth,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _ArcPainter({required this.color, required this.strokeWidth});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = color;
    final rect = Offset.zero & size;
    const sweep = math.pi * 0.8;
    const gap = math.pi;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 0, sweep, false, paint);
    canvas.drawArc(rect.deflate(strokeWidth / 2), gap, sweep, false, paint);
  }
  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
