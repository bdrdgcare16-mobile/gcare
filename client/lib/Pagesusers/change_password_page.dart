
// import 'package:flutter/material.dart';

// // Theme Colors
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class ChangePasswordPage extends StatefulWidget {
//   const ChangePasswordPage({super.key});

//   @override
//   State<ChangePasswordPage> createState() => _ChangePasswordPageState();
// }

// class _ChangePasswordPageState extends State<ChangePasswordPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _oldPassController = TextEditingController();
//   final TextEditingController _newPassController = TextEditingController();
//   final TextEditingController _confirmPassController = TextEditingController();

//   bool _isOldObscure = true;
//   bool _isNewObscure = true;
//   bool _isConfirmObscure = true;

//   void _changePassword() {
//     if (_formKey.currentState!.validate()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Password changed successfully")),
//       );
//       _oldPassController.clear();
//       _newPassController.clear();
//       _confirmPassController.clear();
//     }
//   }

//   String? validateStrongPassword(String? value) {
//     if (value == null || value.isEmpty) return 'Enter new password';
//     if (value.length < 8) return 'Minimum 8 characters required';
//     if (!RegExp(r'[a-z]').hasMatch(value)) return 'Include at least one lowercase letter';
//     if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
//     if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
//     if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
//       return 'Include at least one special character';
//     }
//     return null;
//   }

//   Widget buildFloatingPasswordField({
//     required String labelText,
//     required TextEditingController controller,
//     required bool obscureText,
//     required VoidCallback toggleObscure,
//     required String? Function(String?) validator,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: TextFormField(
//         controller: controller,
//         obscureText: obscureText,
//         decoration: InputDecoration(
//           label: RichText(
//             text: TextSpan(
//               text: labelText,
//               style: const TextStyle(color: Colors.black, fontSize: 16),
//               children: const [
//                 TextSpan(
//                   text: ' *',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ],
//             ),
//           ),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//           suffixIcon: IconButton(
//             icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
//             onPressed: toggleObscure,
//           ),
//         ),
//         validator: validator,
//       ),
//     );
//   }

//   Widget buildPasswordRules() {
//     return Container(
//       margin: const EdgeInsets.only(top: 10, bottom: 30),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.blue[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blueAccent),
//       ),
//       child: const Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Password must contain:', style: TextStyle(fontWeight: FontWeight.bold)),
//           SizedBox(height: 8),
//           Text('• Minimum of 8 characters'),
//           Text('• At least one lowercase letter (a-z)'),
//           Text('• At least one uppercase letter (A-Z)'),
//           Text('• At least one number (0-9)'),
//           Text('• At least one special character (!@#...)'),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _oldPassController.dispose();
//     _newPassController.dispose();
//     _confirmPassController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Change Password'),
//         centerTitle: true,
//         backgroundColor: kAppBarColor,
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Form(
//             key: _formKey,
//             child: ListView(
//               children: [
//                 const SizedBox(height: 10),
//                 buildFloatingPasswordField(
//                   labelText: 'Old Password',
//                   controller: _oldPassController,
//                   obscureText: _isOldObscure,
//                   toggleObscure: () => setState(() => _isOldObscure = !_isOldObscure),
//                   validator: (value) =>
//                       value == null || value.isEmpty ? 'Enter old password' : null,
//                 ),
//                 buildFloatingPasswordField(
//                   labelText: 'New Password',
//                   controller: _newPassController,
//                   obscureText: _isNewObscure,
//                   toggleObscure: () => setState(() => _isNewObscure = !_isNewObscure),
//                   validator: validateStrongPassword,
//                 ),
//                 buildFloatingPasswordField(
//                   labelText: 'Confirm New Password',
//                   controller: _confirmPassController,
//                   obscureText: _isConfirmObscure,
//                   toggleObscure: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Confirm your password';
//                     }
//                     if (value != _newPassController.text) {
//                       return 'Passwords do not match';
//                     }
//                     return null;
//                   },
//                 ),
//                 buildPasswordRules(),
//                 ElevatedButton(
//                   onPressed: _changePassword,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kButtonColor,
//                     foregroundColor: kTextColor,
//                   ),
//                   child: const Text('Change Password'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// If you already declare this elsewhere, you can remove this line.
const String _apiBase = 'https://us-central1-servappbackend.cloudfunctions.net/api';

// Theme Colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isOldObscure = true;
  bool _isNewObscure = true;
  bool _isConfirmObscure = true;
  bool _submitting = false;

  // -------- password rules ----------
  String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter new password';
    if (value.length < 8) return 'Minimum 8 characters required';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Include at least one lowercase letter';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Include at least one special character';
    }
    return null;
  }

  // ---------- API: change password (no old password needed) ----------
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final newPwd = _confirmPassController.text.trim();

    setState(() => _submitting = true);
    try {
      // 1) get token saved during login
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('token');

      // 2) fetch the user profile to get email (backend reads token)
      String? emailLower;
      if (token != null && token.isNotEmpty) {
        final meRes = await http.get(
          Uri.parse('$_apiBase/auth/me'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (meRes.statusCode == 200) {
          final me = jsonDecode(meRes.body) as Map<String, dynamic>;
          // prefer me['email'] then fallback to employeeProfile.email
          final fromMe = (me['email'] ?? '').toString();
          final fromProfile = (me['employeeProfile'] is Map
                  ? (me['employeeProfile']['email'] ?? '')
                  : '')
              .toString();
          final chosen = (fromMe.isNotEmpty ? fromMe : fromProfile).trim();
          if (chosen.isNotEmpty) {
            emailLower = chosen.toLowerCase();
          }
        }
      }

      if (emailLower == null || emailLower.isEmpty) {
        // As a fallback, try what you stored earlier (optional)
        final cached = sp.getString('email');
        if (cached != null && cached.isNotEmpty) {
          emailLower = cached.toLowerCase();
        }
      }

      if (emailLower == null || emailLower.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found (no email). Please login again.')),
        );
        setState(() => _submitting = false);
        return;
      }

      // 3) call backend to change password (only email + newPassword)
      final res = await http.post(
        Uri.parse('$_apiBase/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailLower, 'newPassword': newPwd}),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
        _oldPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
      } else {
        final msg = (data['error'] ?? data['message'] ?? 'Change password failed').toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // -------- UI helpers ----------
  Widget buildFloatingPasswordField({
    required String labelText,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
    bool requiredMark = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: labelText,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              children: requiredMark
                  ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                  : const [],
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: toggleObscure,
          ),
        ),
        validator: validator, // may be null (optional field)
      ),
    );
  }

  Widget buildPasswordRules() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 30),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Password must contain:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('• Minimum of 8 characters'),
          Text('• At least one lowercase letter (a-z)'),
          Text('• At least one uppercase letter (A-Z)'),
          Text('• At least one number (0-9)'),
          Text('• At least one special character (!@#...)'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        centerTitle: true,
        backgroundColor: kAppBarColor,
      ),
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 10),

                // OLD PASSWORD — OPTIONAL (no validator + no red star)
                buildFloatingPasswordField(
                  labelText: 'Old Password',
                  controller: _oldPassController,
                  obscureText: _isOldObscure,
                  toggleObscure: () => setState(() => _isOldObscure = !_isOldObscure),
                  validator: null,           // <- optional
                  requiredMark: false,       // <- remove red *
                ),

                // NEW PASSWORD — STRONG VALIDATION
                buildFloatingPasswordField(
                  labelText: 'New Password',
                  controller: _newPassController,
                  obscureText: _isNewObscure,
                  toggleObscure: () => setState(() => _isNewObscure = !_isNewObscure),
                  validator: validateStrongPassword,
                ),

                // CONFIRM — must match new
                buildFloatingPasswordField(
                  labelText: 'Confirm New Password',
                  controller: _confirmPassController,
                  obscureText: _isConfirmObscure,
                  toggleObscure: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirm your password';
                    if (value != _newPassController.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                buildPasswordRules(),

                ElevatedButton(
                  onPressed: _submitting ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    foregroundColor: kTextColor,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Change Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
