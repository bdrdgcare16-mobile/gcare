// import 'package:flutter/material.dart';
// import 'change_password_page.dart';
// import 'multi_language_page.dart';
// import 'privacy_policy_page.dart';
// import 'terms_and_conditions_page.dart';
// import 'feedback_page.dart';
// import 'permissions_page.dart';
// import 'log_out_page.dart';

// class ProfilePage extends StatelessWidget {
//   const ProfilePage({super.key, required Map userData});

//   // Dummy user data added inside the widget
//   final Map<String, String> userData = const {
//     "name": "Divya D V",
//     "id": "AI2025",
//     "role": "Student",
//     "email": "divya.ai@gmail.com",
//     "phone": "9876543210",
//   };

//   final List<Map<String, dynamic>> settings = const [
//     {"icon": Icons.lock, "label": "Change Password"},
//     {"icon": Icons.language, "label": "Multi Language"},
//     {"icon": Icons.privacy_tip, "label": "Privacy Policy"},
//     {"icon": Icons.article, "label": "Terms & Conditions"},
//     {"icon": Icons.settings, "label": "Permissions"},
//     {"icon": Icons.feedback, "label": "Feedback"},
//     {"icon": Icons.logout, "label": "Log Out", "color": Colors.red},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // 🔙 Back Button
//             Align(
//               alignment: Alignment.topLeft,
//               child: IconButton(
//                 icon: const Icon(Icons.arrow_back),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),

//             // 🧑‍🎓 Profile Header
//             Container(
//               color: Colors.cyanAccent[100],
//               padding: const EdgeInsets.all(20),
//               child: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.pink[100],
//                     child: Text(
//                       userData['name']?.isNotEmpty == true
//                           ? userData['name']![0]
//                           : '?',
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(userData['name'] ?? 'Name',
//                             style: const TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold)),
//                         Text(
//                           '${userData['id'] ?? '-'} | ${userData['role'] ?? '-'}',
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                         Text(userData['email'] ?? 'No email',
//                             style: const TextStyle(fontSize: 14)),
//                         Text(userData['phone'] ?? 'No phone',
//                             style: const TextStyle(fontSize: 14)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const Divider(height: 1),

//             // ⚙️ Settings List
//             Expanded(
//               child: ListView.builder(
//                 itemCount: settings.length,
//                 itemBuilder: (context, index) {
//                   final item = settings[index];
//                   final String label = item['label'];
//                   return Padding(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 4,
//                             offset: const Offset(0, 2),
//                           )
//                         ],
//                       ),
//                       child: ListTile(
//                         contentPadding: EdgeInsets.zero,
//                         leading: Icon(item['icon'],
//                             color: item['color'] ?? Colors.black),
//                         title: Text(
//                           label,
//                           style: TextStyle(
//                             color: item['color'] ?? Colors.black,
//                             fontWeight: label == "Log Out"
//                                 ? FontWeight.bold
//                                 : FontWeight.normal,
//                           ),
//                         ),
//                         trailing:
//                             const Icon(Icons.arrow_forward_ios, size: 14),
//                         onTap: () {
//                           if (label == "Change Password") {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) =>
//                                       const ChangePasswordPage()),
//                             );
//                           } else if (label == "Multi Language") {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) =>
//                                       const MultiLanguagePage()),
//                             );
//                           } else if (label == "Privacy Policy") {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) =>
//                                       const PrivacyPolicyPage()),
//                             );
//                           } else if (label == "Terms & Conditions") {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) =>
//                                       const TermsAndConditionsPage()),
//                             );
//                           } else if (label == "Permissions") {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) =>
//                                       const PermissionsPage()),
//                             );
//                           } else if (label == "Feedback") {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => const FeedbackPage()),
//                             );
//                           } else if (label == "Log Out") {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => const LogOutPage()),
//                             );
//                           } else {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text('$label tapped')),
//                             );
//                           }
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Web localStorage (ignored on mobile/desktop)
import 'dart:html' as html show window;

import 'change_password_page.dart';
import 'multi_language_page.dart';
import 'privacy_policy_page.dart';
import 'terms_and_conditions_page.dart';
import 'feedback_page.dart';
import 'permissions_page.dart';
import 'log_out_page.dart';

/// ===== API base; adjust if needed =====
const String _apiBase = 'http://localhost:3000/api';

/// Order of endpoints to try for the current user's profile.
/// Keep the path only (we'll prefix with _apiBase).
const List<String> _profilePaths = [
  '/me',
  '/profile',
  '/auth/me',
  // add another if you expose attendance's getCurrentUser:
  '/attendance/me',
];

class ProfilePage extends StatefulWidget {
  /// Keep the old signature so existing navigation code does not break.
  const ProfilePage({super.key, required Map userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = false;
  String? _error;

  /// What we render in the header (defaults shown initially).
  Map<String, String> _userData = {
    "name": "Divya D V",
    "id": "AI2025",
    "role": "Student",
    "email": "divya.ai@gmail.com",
    "phone": "9876543210",
  };

  final List<Map<String, dynamic>> settings = const [
    {"icon": Icons.lock, "label": "Change Password"},
    {"icon": Icons.language, "label": "Multi Language"},
    {"icon": Icons.privacy_tip, "label": "Privacy Policy"},
    {"icon": Icons.article, "label": "Terms & Conditions"},
    {"icon": Icons.settings, "label": "Permissions"},
    {"icon": Icons.feedback, "label": "Feedback"},
    {"icon": Icons.logout, "label": "Log Out", "color": Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      Map<String, dynamic>? payload;

      // Try the list of likely endpoints until one returns 200
      for (final path in _profilePaths) {
        final uri = Uri.parse('$_apiBase$path');
        final res = await http.get(uri, headers: headers);
        if (res.statusCode == 200) {
          payload = jsonDecode(res.body) as Map<String, dynamic>;
          break;
        }
      }

      if (payload == null) {
        setState(() {
          _loading = false;
          _error = 'Could not load profile (no endpoint returned 200).';
        });
        return;
      }

      // Normalize keys coming from different backends
      String name = (payload['name'] ?? payload['fullName'] ?? '').toString();
      String empid =
          (payload['empid'] ?? payload['employeeId'] ?? payload['id'] ?? '')
              .toString();
      String role = (payload['role'] ?? '').toString();
      String email = (payload['email'] ?? '').toString();
      String phone = (payload['phone'] ?? payload['mobile'] ?? '').toString();

      if (name.isEmpty && payload.containsKey('user')) {
        final u = payload['user'] as Map<String, dynamic>;
        name = (u['name'] ?? '').toString();
        empid = (u['empid'] ?? '').toString();
        role = (u['role'] ?? '').toString();
        email = (u['email'] ?? '').toString();
        phone = (u['phone'] ?? '').toString();
      }

      // Fall back to dashes if missing
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔙 Back Button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 🧑‍🎓 Profile Header (UI unchanged)
            Container(
              color: Color.fromARGB(255, 140, 110, 175),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.pink[100],
                    child: Text(
                      _userData['name']?.isNotEmpty == true
                          ? _userData['name']![0]
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _userData['name'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_loading)
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        // ID | Role
                        Text(
                          '${_userData['id'] ?? '-'} | ${_userData['role'] ?? '-'}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Email
                        Text(
                          _userData['email'] ?? '-',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Phone
                        Text(
                          _userData['phone'] ?? '-',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ⚙️ Settings List (UI unchanged)
            Expanded(
              child: ListView.builder(
                itemCount: settings.length,
                itemBuilder: (context, index) {
                  final item = settings[index];
                  final String label = item['label'];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(item['icon'],
                            color: item['color'] ?? Colors.black),
                        title: Text(
                          label,
                          style: TextStyle(
                            color: item['color'] ?? Colors.black,
                            fontWeight: label == "Log Out"
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          if (label == "Change Password") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChangePasswordPage()),
                            );
                          } else if (label == "Multi Language") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MultiLanguagePage()),
                            );
                          } else if (label == "Privacy Policy") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyPage()),
                            );
                          } else if (label == "Terms & Conditions") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const TermsAndConditionsPage()),
                            );
                          } else if (label == "Permissions") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PermissionsPage()),
                            );
                          } else if (label == "Feedback") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FeedbackPage()),
                            );
                          } else if (label == "Log Out") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LogOutPage()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$label tapped')),
                            );
                          }
                        },
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
