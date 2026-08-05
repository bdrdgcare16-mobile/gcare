import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;
import 'change_password_page.dart';
import 'multi_language_page.dart';
import 'permissions_page.dart';
import 'feedback_page.dart';
import 'log_out_page.dart';

// ── Original Theme Colors ──────────────────────────────────
const Color kPrimaryBackgroundTop    = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor             = Color(0xFF8C6EAF);
const Color kButtonColor             = Color(0xFF655193);
const Color kTextColor               = Colors.white;
const Color kIconColor               = Color(0xFF3D0066);

// ── Neumorphic tokens ─────────────────────────────────────
const Color kBg          = Color(0xFFF5F0FC);
const Color kShadowDark  = Color(0xFFCFC5E0);
const Color kShadowLight = Color(0xFFFFFFFF);
const Color kTextDark    = Color(0xFF2D1B4E);
const Color kTextSub     = Color(0xFF9B86B8);
const Color kPurplePale  = Color(0xFFEDE6F7);

final String _host = ApiService.baseUrl.replaceFirst('/api', '');
Uri _u(String path) => Uri.parse('$_host$path');

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userData,
    this.preloadedProfile,
  });

  final Map userData;
  final Map<String, dynamic>? preloadedProfile;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = false;
  String? _error;

  Map<String, String> _userData = const {
    "name": "-",
    "id": "-",
    "role": "-",
    "email": "-",
    "phone": "-",
  };

  final List<Map<String, dynamic>> settings = const [
    {"icon": Icons.lock_outline_rounded,       "label": "Change Password"},
    {"icon": Icons.language_rounded,           "label": "Language"},
    {"icon": Icons.privacy_tip_outlined,       "label": "Privacy Policy"},
    {"icon": Icons.article_outlined,           "label": "Terms & Conditions"},
    {"icon": Icons.tune_rounded,               "label": "Permissions"},
    {"icon": Icons.feedback_outlined,          "label": "Feedback"},
    {"icon": Icons.logout_rounded,             "label": "Log Out", "isLogout": true},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preloadedProfile != null) {
      _applyPreloadedProfile(widget.preloadedProfile!);
    } else {
      _loadProfile();
    }
  }

  Future<String?> _getToken() async {
    try {
      final t = html.window.localStorage['token'];
      if (t != null && t.isNotEmpty) return t;
    } catch (_) {}
    final sp = await SharedPreferences.getInstance();
    final t2 = sp.getString('token');
    return (t2 != null && t2.isNotEmpty) ? t2 : null;
  }

  String _extractEmployeeId(Map<String, dynamic> data) {
    return (data['empid'] as String?) ??
        (data['empId'] as String?) ??
        (data['employeeId'] as String?) ??
        (data['employeeProfile']?['empid'] as String?) ??
        '-';
  }

  String _extractPhone(Map<String, dynamic> data) {
    final mainPhone = (data['phone'] as String?) ?? (data['mobile'] as String?);
    if (mainPhone?.isNotEmpty == true) return mainPhone!;
    final empProfile = data['employeeProfile'] as Map<String, dynamic>?;
    if (empProfile != null) {
      final empPhone =
          (empProfile['phone'] as String?) ?? (empProfile['mobile'] as String?);
      if (empPhone?.isNotEmpty == true) return empPhone!;
    }
    return '-';
  }

  void _applyPreloadedProfile(Map<String, dynamic> profileData) {
    try {
      setState(() {
        _loading = true;
        _error = null;
        _userData = {
          "name": (profileData['name'] ?? "-") as String,
          "id": _extractEmployeeId(profileData),
          "role": (profileData['role'] ?? "-") as String,
          "email": (profileData['email'] ?? "-") as String,
          "phone": _extractPhone(profileData),
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load profile';
      });
    }
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        setState(() { _loading = false; _error = 'No token found. Please log in.'; });
        return;
      }
      final res = await http.get(_u('/api/auth/me'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (res.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = res.statusCode == 401 || res.statusCode == 403
              ? 'Unauthorized. Please log in again.'
              : 'Could not load profile (status ${res.statusCode}).';
        });
        return;
      }
      final payload = jsonDecode(res.body) as Map<String, dynamic>;
      String name  = (payload['name'] ?? payload['fullName'] ?? '').toString();
      String empid = _extractEmployeeId(payload);
      String role  = (payload['role'] ?? '').toString();
      String email = (payload['email'] ?? '').toString();
      String phone = (payload['phone'] ?? payload['mobile'] ?? '').toString();
      if ((name.isEmpty || email.isEmpty) && payload.containsKey('employeeProfile')) {
        final u = (payload['employeeProfile'] as Map).cast<String, dynamic>();
        name  = (u['name'] ?? u['fullName'] ?? name).toString();
        empid = _extractEmployeeId(u);
        role  = (payload['role'] ?? role).toString();
        email = (u['email'] ?? email).toString();
        phone = (u['phone'] ?? u['mobile'] ?? phone).toString();
      }
      final sp = await SharedPreferences.getInstance();
      if (email.isNotEmpty) await sp.setString('email', email.toLowerCase());
      setState(() {
        _userData = {
          "name":  name.isNotEmpty  ? name  : '-',
          "id":    empid.isNotEmpty ? empid : '-',
          "role":  role.isNotEmpty  ? role  : '-',
          "email": email.isNotEmpty ? email : '-',
          "phone": phone.isNotEmpty ? phone : '-',
        };
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'Network error: $e'; });
    }
  }

  Future<void> _openSetting(String label) async {
    if (label == "Change Password") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
    } else if (label == "Language") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiLanguagePage()));
    } else if (label == "Privacy Policy") {
      final uri = Uri.parse('https://servappbackend.web.app/privacy-policy.html');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (label == "Terms & Conditions") {
      final uri = Uri.parse('https://servappbackend.web.app/terms.html');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (label == "Permissions") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsPage()));
    } else if (label == "Feedback") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackPage()));
    } else if (label == "Log Out") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LogOutPage()));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label tapped')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = (_userData['name'] != null &&
            _userData['name']!.isNotEmpty &&
            _userData['name'] != '-')
        ? _userData['name']![0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  _NeuButton(
                    size: 42,
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: kAppBarColor),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: kTextDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Removed extra three-dot button to simplify header
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Profile hero card ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kButtonColor, kAppBarColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kAppBarColor.withOpacity(0.38),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar circle
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kTextColor.withOpacity(0.18),
                        border: Border.all(color: kTextColor, width: 2),
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(kTextColor)),
                              )
                            : Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: kTextColor,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData['name'] ?? '-',
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _InfoChip(
                                  label: _userData['id'] ?? '-'),
                              const SizedBox(width: 6),
                              _InfoChip(
                                  label: _userData['role'] ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.mail_outline_rounded,
                                  size: 12,
                                  color: Color(0xCCFFFFFF)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _userData['email'] ?? '-',
                                  style: const TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 11.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (_userData['phone'] != '-') ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 12,
                                    color: Color(0xAAFFFFFF)),
                                const SizedBox(width: 4),
                                Text(
                                  _userData['phone'] ?? '-',
                                  style: const TextStyle(
                                    color: Color(0xAAFFFFFF),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 4),
                            Text(_error!,
                                style: const TextStyle(
                                    color: Color(0xFFFFB3BA), fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── Section label ─────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Settings list ─────────────────────────────────
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: settings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = settings[index];
                  final bool isLogout = item['isLogout'] == true;
                  return _SettingsRow(
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    isLogout: isLogout,
                    index: index,
                    onTap: () => _openSetting(item['label'] as String),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small chip inside hero card ────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kTextColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kTextColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Neumorphic settings row ────────────────────────────────
class _SettingsRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isLogout;
  final int index;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.isLogout,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color iconBg   = widget.isLogout ? const Color(0xFFFFE5E5) : kPurplePale;
    final Color iconClr  = widget.isLogout ? const Color(0xFFD32F2F) : kIconColor;
    final Color labelClr = widget.isLogout ? const Color(0xFFD32F2F) : kTextDark;
    final Color arrowClr = widget.isLogout
        ? const Color(0xFFD32F2F).withOpacity(0.6)
        : kAppBarColor.withOpacity(0.6);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(18),
              border: widget.isLogout
                  ? Border.all(color: const Color(0xFFFFE5E5), width: 1)
                  : null,
              boxShadow: _pressed
                  ? [
                      BoxShadow(
                        color: kShadowDark.withOpacity(0.7),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: kShadowDark,
                        blurRadius: 14,
                        offset: const Offset(5, 5),
                      ),
                      const BoxShadow(
                        color: kShadowLight,
                        blurRadius: 14,
                        offset: Offset(-5, -5),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Icon bubble
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: widget.isLogout
                        ? []
                        : [
                            BoxShadow(
                              color: kShadowDark,
                              blurRadius: 6,
                              offset: const Offset(2, 2),
                            ),
                            const BoxShadow(
                              color: kShadowLight,
                              blurRadius: 6,
                              offset: Offset(-2, -2),
                            ),
                          ],
                  ),
                  child: Icon(widget.icon, color: iconClr, size: 20),
                ),

                const SizedBox(width: 16),

                // Label
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: widget.isLogout
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: labelClr,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),

                // Arrow
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: widget.isLogout
                        ? const Color(0xFFFFE5E5)
                        : kPurplePale,
                    shape: BoxShape.circle,
                    boxShadow: widget.isLogout
                        ? []
                        : [
                            BoxShadow(
                              color: kAppBarColor.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(1, 2),
                            ),
                          ],
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: arrowClr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Neumorphic circle button ───────────────────────────────
class _NeuButton extends StatelessWidget {
  final double size;
  final Widget child;
  final VoidCallback onTap;
  const _NeuButton(
      {required this.size, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: kBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: kShadowDark, blurRadius: 10, offset: Offset(4, 4)),
            BoxShadow(
                color: kShadowLight, blurRadius: 10, offset: Offset(-4, -4)),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}