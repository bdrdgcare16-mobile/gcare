import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
// Web localStorage (ignored on mobile/desktop)
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;
// ---------- import your destination pages (so taps push correctly) ----------
import 'change_password_page.dart';
import 'multi_language_page.dart';
import 'permissions_page.dart';
import 'feedback_page.dart';
import 'log_out_page.dart';

/// ===== Service root (using centralized config) =====
final String _host = ApiService.baseUrl.replaceFirst('/api', '');
Uri _u(String path) => Uri.parse('$_host$path'); // use like /api/auth/me



class ProfilePage extends StatefulWidget {
  /// Kept for backward compatibility; not used.
  /// Do not remove unless you have updated all callers.
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

  /// Render data for the header; starts with placeholders only (no hard-coded user).
  Map<String, String> _userData = const {
    "name": "-",
    "id": "-",
    "role": "-",
    "email": "-",
    "phone": "-",
  };

  final List<Map<String, dynamic>> settings = const [
    {"icon": Icons.lock, "label": "Change Password"},
    {"icon": Icons.language, "label": "Language"},
    {"icon": Icons.privacy_tip, "label": "Privacy Policy"},
    {"icon": Icons.article, "label": "Terms & Conditions"},
    {"icon": Icons.settings, "label": "Permissions"},
    {"icon": Icons.feedback, "label": "Feedback"},
    {"icon": Icons.logout, "label": "Log Out", "color": Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    
    // ✅ SAFETY: Use preloaded profile data when available, otherwise load normally
    if (widget.preloadedProfile != null) {
      debugPrint('[Profile] Using preloaded profile data from home page');
      _applyPreloadedProfile(widget.preloadedProfile!);
    } else {
      debugPrint('[Profile] No preloaded profile data, loading auth/me API');
      _loadProfile();
    }
  }

  Future<String?> _getToken() async {
    // Web localStorage first
    try {
      final t = html.window.localStorage['token'];
      if (t != null && t.isNotEmpty) return t;
    } catch (_) {}
    // Mobile/desktop
    final sp = await SharedPreferences.getInstance();
    final t2 = sp.getString('token');
    return (t2 != null && t2.isNotEmpty) ? t2 : null;
  }

  // Extract employee ID with proper priority order
  String _extractEmployeeId(Map<String, dynamic> data) {
    return (data['empid'] as String?) ??
           (data['empId'] as String?) ??
           (data['employeeId'] as String?) ??
           (data['employeeProfile']?['empid'] as String?) ??
           '-';
  }

  // Extract phone number with proper priority order
  String _extractPhone(Map<String, dynamic> data) {
    // Check main fields first
    final mainPhone = (data['phone'] as String?) ?? (data['mobile'] as String?);
    if (mainPhone?.isNotEmpty == true) return mainPhone!;
    
    // Check employeeProfile fields
    final empProfile = data['employeeProfile'] as Map<String, dynamic>?;
    if (empProfile != null) {
      final empPhone = (empProfile['phone'] as String?) ?? (empProfile['mobile'] as String?);
      if (empPhone?.isNotEmpty == true) return empPhone!;
    }
    
    return '-';
  }

  // ✅ SAFETY: Apply preloaded profile data without API calls
void _applyPreloadedProfile(Map<String, dynamic> profileData) {
  try {
    setState(() {
      _loading = true;
      _error = null;
      
      // Apply preloaded data directly
      _userData = {
        "name": (profileData['name'] ?? "-") as String,
        "id": _extractEmployeeId(profileData),
        "role": (profileData['role'] ?? "-") as String,
        "email": (profileData['email'] ?? "-") as String,
        "phone": _extractPhone(profileData),
      };
      
      _loading = false;
    });
    
    debugPrint('[Profile] Applied preloaded profile data: ${_userData['name']}');
  } catch (e) {
    debugPrint('[Profile] Error applying preloaded profile: $e');
    setState(() {
      _loading = false;
      _error = 'Failed to load profile';
    });
  }
}

Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No token found. Please log in.';
        });
        return;
      }

      final res = await http.get(
        _u('/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

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

      // Normalize keys coming from different backends
      String name = (payload['name'] ?? payload['fullName'] ?? '').toString();
      String empid = _extractEmployeeId(payload);
      String role = (payload['role'] ?? '').toString();
      String email = (payload['email'] ?? '').toString();
      String phone = (payload['phone'] ?? payload['mobile'] ?? '').toString();

      if ((name.isEmpty || email.isEmpty) && payload.containsKey('employeeProfile')) {
        final u = (payload['employeeProfile'] as Map).cast<String, dynamic>();
        name = (u['name'] ?? u['fullName'] ?? name).toString();
        empid = _extractEmployeeId(u);
        role = (payload['role'] ?? role).toString();
        email = (u['email'] ?? email).toString();
        phone = (u['phone'] ?? u['mobile'] ?? phone).toString();
      }

      // Cache email for Change Password page
      final sp = await SharedPreferences.getInstance();
      if (email.isNotEmpty) {
        await sp.setString('email', email.toLowerCase());
      }

      final normalized = <String, String>{
        "name": name.isNotEmpty ? name : '-',
        "id": empid.isNotEmpty ? empid : '-',
        "role": role.isNotEmpty ? role : '-',
        "email": email.isNotEmpty ? email : '-',
        "phone": phone.isNotEmpty ? phone : '-',
      };

      setState(() {
        _userData = normalized;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Network error: $e';
      });
    }
  }

  Future<void> _openSetting(String label) async {
    if (label == "Change Password") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
      );
    } else if (label == "Language") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MultiLanguagePage()),
      );
    } else if (label == "Privacy Policy") {
      // final Uri privacyUri = Uri.parse('https://serv-dev-f2557.web.app/privacy-policy.html');
      final Uri privacyUri2 = Uri.parse('https://servappbackend.web.app/privacy-policy.html');
      if (await canLaunchUrl(privacyUri2)) {
        await launchUrl(privacyUri2, mode: LaunchMode.externalApplication);
      }
    } else if (label == "Terms & Conditions") {
      // final Uri termsUri = Uri.parse('https://serv-dev-f2557.web.app/terms.html');
      final Uri termsUri2 = Uri.parse('https://servappbackend.web.app/terms.html');
      if (await canLaunchUrl(termsUri2)) {
        await launchUrl(termsUri2, mode: LaunchMode.externalApplication);
      }
    } else if (label == "Permissions") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PermissionsPage()),
      );
    } else if (label == "Feedback") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FeedbackPage()),
      );
    } else if (label == "Log Out") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LogOutPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label tapped')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F8),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with Back Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8C6EAF),
                    Color(0xFF655193),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Back Button and Title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Compact Profile Info
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _userData['name'] != null &&
                                    _userData['name']!.isNotEmpty &&
                                    _userData['name'] != '-'
                                ? _userData['name']![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userData['name'] ?? '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_userData['id'] ?? '-'} | ${_userData['role'] ?? '-'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _userData['email'] ?? '-',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFFFB3BA),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (_loading)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Settings List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: settings.length,
                itemBuilder: (context, index) {
                  final item = settings[index];
                  final String label = item['label'];
                  final bool isLogout = label == "Log Out";
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openSetting(label),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isLogout 
                                ? Colors.white 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isLogout
                                ? Border.all(color: const Color(0xFFFFE5E5), width: 1)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isLogout
                                      ? const Color(0xFFFFE5E5)
                                      : const Color(0xFFF5F3F8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item['icon'],
                                  color: isLogout
                                      ? const Color(0xFFD32F2F)
                                      : const Color(0xFF8C6EAF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Label
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: isLogout
                                        ? const Color(0xFFD32F2F)
                                        : const Color(0xFF2D2D2D),
                                    fontSize: 15,
                                    fontWeight: isLogout
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              
                              // Arrow
                              Icon(
                                Icons.arrow_forward_ios,
                                color: isLogout
                                    ? const Color(0xFFD32F2F).withOpacity(0.6)
                                    : const Color(0xFF8C6EAF).withOpacity(0.6),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
