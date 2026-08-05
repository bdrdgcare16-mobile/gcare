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

import 'forgot_password_page.dart';

// ===== THEME =====
const Color kPrimary = Color(0xFF8C6EAF);
const Color kPrimaryDark = Color(0xFF655193);
const Color kPrimaryLight = Color(0xFFD1C4E9);
const Color kAccent = Color(0xFFB39DDB);
const Color kTextColor = Colors.white;
const Color kFieldBg = Color(0xFFF7F4FC);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final idController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool _isEmpLoading = false;
  bool _isAdminLoading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;

  bool get _isAnyLoginLoading => _isEmpLoading || _isAdminLoading;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'sans-serif')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kPrimaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _persist(String key, String value) async {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, value);
  }

  Future<void> _showPermissionIntroThenRequest() async {
    await LocationPermissionDialog.showIfNeeded(context);
  }

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

    final u1 = Uri.parse('${ApiService.baseUrl}/company/profile/check');
    try {
      final r1 = await http.get(u1, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 15));
      debugPrint('[GET] $u1 -> ${r1.statusCode}');
      if (r1.statusCode == 200) return norm(jsonDecode(r1.body));
      if (r1.statusCode == 404) return treat404();
    } catch (e) {
      debugPrint('profile/check exception: $e');
    }

    final u2 = Uri.parse('${ApiService.baseUrl}/company/profile')
        .replace(queryParameters: {'email': adminEmail.trim().toLowerCase()});
    final r2 = await http.get(u2, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 15));

    debugPrint('[GET] $u2 -> ${r2.statusCode}');
    if (r2.statusCode == 200) return norm(jsonDecode(r2.body));
    if (r2.statusCode == 404) return treat404();

    dynamic err;
    try {
      err = jsonDecode(r2.body);
    } catch (_) {}
    throw Exception('HTTP ${r2.statusCode} ${r2.reasonPhrase} ${err ?? ''}');
  }

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
        final token =
            (data['token'] ?? data['data']?['token'] ?? '').toString();
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEF9),
      body: Stack(
        // FIX 1: clipBehavior.none allows blobs to render outside bounds
        clipBehavior: Clip.none,
        children: [
          // ── decorative blobs ──
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.18,
            child: _Blob(
              width: size.width * 0.72,
              height: size.height * 0.38,
              color: kPrimary.withOpacity(0.85),
            ),
          ),
          Positioned(
            top: size.height * 0.18,
            // FIX 2: reduced negative left offset so blob is visible, not clipped
            left: -size.width * 0.08,
            child: _Blob(
              // FIX 3: reduced width so blob doesn't overflow too far
              width: size.width * 0.45,
              height: size.height * 0.28,
              color: kPrimaryLight.withOpacity(0.7),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.06,
            right: -size.width * 0.1,
            child: _Blob(
              width: size.width * 0.65,
              height: size.height * 0.26,
              color: kAccent.withOpacity(0.5),
            ),
          ),

          // ── content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 18),

                        // Logo
                        Image.asset(
                          'assets/images/serv_new_logo-removebg.png',
                          height: 120,
                          width: 250,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 28),

                        // Welcome text
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D1B4E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: kPrimary.withOpacity(0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 32),

                        Column(
                          children: [
                              // Email field
                              _StyledField(
                                controller: idController,
                                label: 'Email address',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Email required';
                                  }
                                  final emailRegex = RegExp(
                                    r"^[\w._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$",
                                    caseSensitive: false,
                                  );
                                  if (!emailRegex.hasMatch(val.trim())) {
                                    return 'Enter valid email';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password field
                              _StyledField(
                                controller: passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: !isPasswordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: kPrimary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => isPasswordVisible =
                                        !isPasswordVisible,
                                  ),
                                ),
                                validator: (val) =>
                                    (val == null || val.isEmpty)
                                        ? 'Password required'
                                        : null,
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordPage(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 0),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Sign in as Employee
                              _GradientButton(
                                label: 'Sign in as Employee',
                                icon: Icons.person_rounded,
                                isLoading: _isEmpLoading,
                                disabled: _isAnyLoginLoading,
                                onTap: () => _login(isAdmin: false),
                              ),

                              const SizedBox(height: 12),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                        color: kPrimaryLight, thickness: 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: kPrimary.withOpacity(0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                        color: kPrimaryLight, thickness: 1),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Sign in as Admin
                              _OutlineButton(
                                label: 'Sign in as Admin',
                                icon: Icons.admin_panel_settings_rounded,
                                isLoading: _isAdminLoading,
                                disabled: _isAnyLoginLoading,
                                onTap: () => _login(isAdmin: true),
                              ),
                          ],
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Blob shape widget
// ──────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  const _Blob(
      {required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BlobClipper(),
      child: Container(width: width, height: height, color: color),
    );
  }
}

class _BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.05, size.height * 0.35);
    path.cubicTo(
      size.width * 0.0,
      size.height * 0.1,
      size.width * 0.3,
      size.height * -0.05,
      size.width * 0.55,
      size.height * 0.08,
    );
    path.cubicTo(
      size.width * 0.8,
      size.height * 0.2,
      size.width * 1.05,
      size.height * 0.1,
      size.width * 1.0,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.95,
      size.height * 0.8,
      size.width * 0.7,
      size.height * 1.05,
      size.width * 0.45,
      size.height * 0.98,
    );
    path.cubicTo(
      size.width * 0.2,
      size.height * 0.92,
      size.width * 0.1,
      size.height * 0.65,
      size.width * 0.05,
      size.height * 0.35,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_BlobClipper oldClipper) => false;
}

// ──────────────────────────────────────────
// Styled text field
// ──────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF2D1B4E),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: kPrimary.withOpacity(0.7),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: kPrimary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kFieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimaryLight.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

// ──────────────────────────────────────────
// Gradient (filled) button
// ──────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? LinearGradient(
                  colors: [kPrimary.withOpacity(0.4), kAccent.withOpacity(0.4)])
              : const LinearGradient(
                  colors: [kPrimaryDark, kPrimary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: disabled ? null : onTap,
          icon: isLoading
              ? const SizedBox.shrink()
              : Icon(icon, size: 18, color: Colors.white),
          label: isLoading
              ? const _ArcLoader(size: 22, color: Colors.white)
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Outline button (Admin)
// ──────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: disabled ? null : onTap,
        icon: isLoading
            ? const SizedBox.shrink()
            : Icon(icon, size: 18, color: kPrimaryDark),
        label: isLoading
            ? const _ArcLoader(size: 22, color: kPrimaryDark)
            : Text(
                label,
                style: const TextStyle(
                  color: kPrimaryDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Arc loader
// ──────────────────────────────────────────
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