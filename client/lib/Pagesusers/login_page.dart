// import 'dart:async'; // NEW: for Timer
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:serv_app/models/company_data.dart';
// import 'package:serv_app/Pagesusers/home_screen_page.dart';
// import 'package:serv_app/Pagesadmin/admin_dashboard_page.dart';
// import 'package:serv_app/Pagesadmin/company_details_page.dart';
// import 'package:serv_app/Pagesadmin/company_setup_page.dart';


// // ADD: shared_preferences for cross-page persistence
// import 'package:shared_preferences/shared_preferences.dart';

// // For Flutter Web localStorage
//  import 'package:serv_app/html_stub.dart'
//   if (dart.library.html) 'package:serv_app/html_web.dart' as html;
  
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// // Base URL used throughout this file
// const String _apiBase = 'http://localhost:3000/api';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final idController = TextEditingController();
//   final passwordController = TextEditingController();
//   bool isPasswordVisible = false;
//   bool _isEmpLoading = false;
//   bool _isAdminLoading = false;
//   final bool _isResetLoading = false;

//   @override
//   void dispose() {
//     idController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   Future<bool> isProfileFilled(String token) async {
//     final res = await http.get(
//       Uri.parse('$_apiBase/company/profile/check'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//     if (res.statusCode == 200) {
//       return json.decode(res.body)['filled'] ?? false;
//     }
//     throw Exception('Failed to check profile status');
//   }

//   Future<Map<String, dynamic>> fetchCompanyProfile(String token) async {
//     final res = await http.get(
//       Uri.parse('$_apiBase/company/profile'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//     if (res.statusCode == 200) {
//       return json.decode(res.body) as Map<String, dynamic>;
//     }
//     throw Exception('Failed to load company profile');
//   }

//   // ---------- FORGOT PASSWORD (Email -> OTP -> New Password) ----------
//   Future<void> _showForgotPasswordDialog(BuildContext context) async {
//     // Local controllers & keys for the 3 steps
//     final emailCtrl = TextEditingController();
//     final otpCtrl = TextEditingController();
//     final newPwdCtrl = TextEditingController();
//     final confirmPwdCtrl = TextEditingController();

//     final emailKey = GlobalKey<FormState>();
//     final otpKey = GlobalKey<FormState>();
//     final resetKey = GlobalKey<FormState>();

//     // Local state for the dialog
//     bool sending = false;
//     bool verifying = false;
//     bool resetting = false;

//     bool otpSent = false;
//     bool otpVerified = false;

//     const int otpValidSeconds = 10 * 60; // 10 minutes
//     int secondsLeft = 0;
//     Timer? countdown;

//     String fmt(int s) {
//       final m = (s ~/ 60).toString().padLeft(2, '0');
//       final r = (s % 60).toString().padLeft(2, '0');
//       return '$m:$r';
//     }

//     void startTimer(void Function(VoidCallback fn) setDlgState) {
//       secondsLeft = otpValidSeconds;
//       countdown?.cancel();
//       countdown = Timer.periodic(const Duration(seconds: 1), (t) {
//         if (secondsLeft > 0) {
//           secondsLeft--;
//           setDlgState(() {});
//         } else {
//           t.cancel();
//           setDlgState(() {}); // refresh "Expired" state
//         }
//       });
//     }

//     Future<void> sendOtp(void Function(VoidCallback fn) setDlgState) async {
//       if (!emailKey.currentState!.validate()) return;
//       setDlgState(() => sending = true);
//       try {
//         final res = await http.post(
//           Uri.parse('$_apiBase/auth/forgot-password/request-otp'),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode({'email': emailCtrl.text.trim().toLowerCase()}),
//         );
//         if (res.statusCode == 200) {
//           otpSent = true;
//           startTimer(setDlgState);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('OTP sent to your email.')),
//           );
//         } else {
//           final msg = (jsonDecode(res.body)['error'] ?? 'Failed to send OTP')
//               .toString();
//           ScaffoldMessenger.of(context)
//               .showSnackBar(SnackBar(content: Text(msg)));
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('Error: $e')));
//       } finally {
//         setDlgState(() => sending = false);
//       }
//     }

//     Future<void> verifyOtp(void Function(VoidCallback fn) setDlgState) async {
//       if (!otpKey.currentState!.validate()) return;
//       if (secondsLeft <= 0) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('OTP expired. Please resend.')),
//         );
//         return;
//       }
//       setDlgState(() => verifying = true);
//       try {
//         final res = await http.post(
//           Uri.parse('$_apiBase/auth/forgot-password/verify-otp'),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode({
//             'email': emailCtrl.text.trim().toLowerCase(),
//             'otp': otpCtrl.text.trim(),
//           }),
//         );
//         if (res.statusCode == 200) {
//           otpVerified = true;
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content: Text('OTP verified. Please set new password.')),
//           );
//         } else {
//           final msg =
//               (jsonDecode(res.body)['error'] ?? 'Invalid OTP').toString();
//           ScaffoldMessenger.of(context)
//               .showSnackBar(SnackBar(content: Text(msg)));
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('Error: $e')));
//       } finally {
//         setDlgState(() => verifying = false);
//       }
//     }

//     Future<void> resetPassword(
//         void Function(VoidCallback fn) setDlgState) async {
//       if (!resetKey.currentState!.validate()) return;
//       setDlgState(() => resetting = true);
//       try {
//         final res = await http.post(
//           Uri.parse('$_apiBase/auth/forgot-password/reset'),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode({
//             'email': emailCtrl.text.trim().toLowerCase(),
//             'otp': otpCtrl.text.trim(),
//             'newPassword': newPwdCtrl.text,
//           }),
//         );
//         if (res.statusCode == 200) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content: Text('Password reset successful. Please log in.')),
//           );
//           countdown?.cancel();
//           Navigator.of(context).pop(); // close the dialog
//         } else {
//           final msg =
//               (jsonDecode(res.body)['error'] ?? 'Reset failed').toString();
//           ScaffoldMessenger.of(context)
//               .showSnackBar(SnackBar(content: Text(msg)));
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('Error: $e')));
//       } finally {
//         setDlgState(() => resetting = false);
//       }
//     }

//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => StatefulBuilder(
//         builder: (ctx, setDlgState) {
//           // Decide which "step" view to render
//           Widget content;
//           List<Widget> actions = [];

//           if (!otpSent) {
//             // ------------ STEP 1: Email ------------
//             content = Form(
//               key: emailKey,
//               child: TextFormField(
//                 controller: emailCtrl,
//                 decoration: InputDecoration(
//                   hintText: "Enter your registered email",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) return "Email required";
//                   final re = RegExp(r"^[\w\.\-]+@[\w\-]+\.\w{2,}$");
//                   if (!re.hasMatch(v.trim())) return "Enter valid email";
//                   return null;
//                 },
//               ),
//             );
//             actions = [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(ctx);
//                 },
//                 child: const Text("Cancel"),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
//                 onPressed: sending ? null : () => sendOtp(setDlgState),
//                 child: sending
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                     : const Text("Send OTP",
//                         style: TextStyle(color: kTextColor)),
//               ),
//             ];
//           } else if (!otpVerified) {
//             // ------------ STEP 2: OTP ------------
//             content = Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Form(
//                   key: otpKey,
//                   child: TextFormField(
//                     controller: otpCtrl,
//                     keyboardType: TextInputType.number,
//                     maxLength: 6,
//                     decoration: InputDecoration(
//                       hintText: "Enter 6-digit OTP",
//                       counterText: "",
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.trim().isEmpty) {
//                         return "OTP required";
//                       }
//                       if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
//                         return "Enter 6-digit OTP";
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       secondsLeft > 0
//                           ? "Expires in ${fmt(secondsLeft)}"
//                           : "OTP expired",
//                       style: TextStyle(
//                         color: secondsLeft > 0 ? Colors.black54 : Colors.red,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: sending
//                           ? null
//                           : () async {
//                               await sendOtp(setDlgState);
//                             },
//                       child: const Text("Resend OTP"),
//                     ),
//                   ],
//                 ),
//               ],
//             );
//             actions = [
//               TextButton(
//                 onPressed: () {
//                   countdown?.cancel();
//                   Navigator.pop(ctx);
//                 },
//                 child: const Text("Cancel"),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
//                 onPressed: verifying ? null : () => verifyOtp(setDlgState),
//                 child: verifying
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                     : const Text("Verify OTP",
//                         style: TextStyle(color: kTextColor)),
//               ),
//             ];
//           } else {
//             // ------------ STEP 3: New Password ------------
//             content = Form(
//               key: resetKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextFormField(
//                     controller: newPwdCtrl,
//                     obscureText: true,
//                     decoration: InputDecoration(
//                       hintText: "Enter new password",
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return "Password required";
//                       if (v.length < 6) return "Min 6 characters";
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: confirmPwdCtrl,
//                     obscureText: true,
//                     decoration: InputDecoration(
//                       hintText: "Confirm new password",
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return "Confirm password";
//                       if (v != newPwdCtrl.text) return "Passwords do not match";
//                       return null;
//                     },
//                   ),
//                 ],
//               ),
//             );
//             actions = [
//               TextButton(
//                 onPressed: () {
//                   countdown?.cancel();
//                   Navigator.pop(ctx);
//                 },
//                 child: const Text("Cancel"),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
//                 onPressed: resetting ? null : () => resetPassword(setDlgState),
//                 child: resetting
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                     : const Text("Submit", style: TextStyle(color: kTextColor)),
//               ),
//             ];
//           }

//           return AlertDialog(
//             title: const Text("Forgot Password"),
//             content: content,
//             actions: actions,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           );
//         },
//       ),
//     ).whenComplete(() {
//       countdown?.cancel();
//     });
//   }
//   // ---------- END FORGOT PASSWORD FLOW ----------

//   /// Helper: persist to both storages so every page can read them
//   Future<void> _persist(String key, String value) async {
//     // Web localStorage
//     html.window.localStorage[key] = value;
//     // SharedPreferences (feedback page reads from here)
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(key, value);
//   }

//   Future<void> _login({required bool isAdmin}) async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() {
//       if (isAdmin) {
//         _isAdminLoading = true;
//       } else {
//         _isEmpLoading = true;
//       }
//     });

//     try {
//       // Normalize email: trim + lowercase. Keep password EXACT (case/space sensitive).
//       final email = idController.text.trim().toLowerCase();
//       final pwd = passwordController.text;

//       final response = await http
//           .post(
//             Uri.parse('$_apiBase/auth/login'),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({'email': email, 'password': pwd}),
//           )
//           .timeout(const Duration(seconds: 10));

//       final data = jsonDecode(response.body) as Map<String, dynamic>;

//       if (response.statusCode == 200) {
//         final tok = data['token'] as String;
//         final role = data['role'] as String? ?? '';
//         CompanyData.token = tok;

//         // Save JWT + role to both storages
//         await _persist('token', tok);
//         await _persist('role', role);

//         if (isAdmin && role != 'admin') {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Not authorized as admin.")),
//           );
//           return;
//         }
//         if (!isAdmin && role != 'employee') {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Not authorized as employee.")),
//           );
//           return;
//         }

//         if (isAdmin) {
//           final filled = await isProfileFilled(tok);
//           if (filled) {
//             final jsonProfile = await fetchCompanyProfile(tok);
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => AdminDashboard(
//                   companyProfile: CompanyProfile(
//                     name: jsonProfile['companyName'] ?? '',
//                     adminName: jsonProfile['adminName'] ?? '',
//                     logoUrl:
//                         (jsonProfile['logo'] as String?)?.isNotEmpty == true
//                             ? '$_apiBase${jsonProfile['logo']}'
//                                 .replaceFirst('/api', '')
//                             : null,
//                   ),
//                 ),
//               ),
//             );
//           } else {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const CompanyDetailsFormPage()),
//             );
//           }
//         } else {
//           // ——— EMPLOYEE FLOW ———
//           String realName = '';
//           String docId = '';
//           String empId = '';

//           // Decode the JWT to extract a user id if present
//           try {
//             final decoded = JwtDecoder.decode(tok);
//             docId = (decoded['userId'] ?? decoded['uid'] ?? '').toString();
//           } catch (_) {
//             docId = '';
//           }

//           try {
//             final meRes = await http.get(
//               Uri.parse('$_apiBase/auth/me'),
//               headers: {'Authorization': 'Bearer $tok'},
//             );
//             final meData = jsonDecode(meRes.body) as Map<String, dynamic>;
//             if (kDebugMode) print('[Login] /auth/me returned: $meData');

//             // Prefer employeeProfile values if available
//             final profile = (meData['employeeProfile'] is Map)
//                 ? (meData['employeeProfile'] as Map)
//                 : <String, dynamic>{};

//             realName =
//                 (meData['name'] ?? profile['name'] ?? meData['fullName'] ?? '')
//                     .toString()
//                     .trim();

//             empId = (meData['empid'] ??
//                     profile['empid'] ??
//                     meData['employeeId'] ??
//                     profile['employeeId'] ??
//                     '')
//                 .toString()
//                 .trim();

//             // Cache profile JSON for later reads
//             await _persist(
//                 'employeeProfile',
//                 jsonEncode({
//                   ...profile,
//                   if (meData['empid'] != null) 'empid': meData['empid'],
//                   if (meData['name'] != null) 'name': meData['name'],
//                 }));
//           } catch (_) {
//             // Fallback to something sensible
//             realName = idController.text.trim().split('@').first;
//           }

//           // Persist identity for other pages (e.g., Feedback)
//           if (docId.isNotEmpty) await _persist('userDocId', docId);
//           if (realName.isNotEmpty) await _persist('name', realName);
//           if (empId.isNotEmpty) await _persist('empid', empId);

//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) =>
//                   HomeScreen(userName: realName, employeeDocId: docId),
//             ),
//           );
//         }
//       } else {
//         final msg =
//             (data['message'] ?? data['error'] ?? 'Login failed').toString();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(msg)),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       setState(() {
//         _isEmpLoading = false;
//         _isAdminLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // keep Scaffold, but ensure the gradient draws behind everything
//       backgroundColor: Colors.transparent,
//       body: Container(
//         // ⬇️ Gradient fills entire screen
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: LayoutBuilder(
//             builder: (ctx, constraints) {
//               return SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 child: ConstrainedBox(
//                   // ⬇️ Ensures no white band at the bottom
//                   constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 24, vertical: 10),
//                     child: Form(
//                       key: _formKey,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const SizedBox(height: 10),
//                           Container(
//                             height: 70,
//                             width: 70,
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFFFCC00),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             clipBehavior: Clip.antiAlias,
//                             child: Image.asset(
//                               'assets/images/loginlogo.png',
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           const Text(
//                             'Sign In',
//                             style: TextStyle(
//                                 fontSize: 22, fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 30),

//                           // Email Input
//                           TextFormField(
//                             controller: idController,
//                             keyboardType: TextInputType.emailAddress,
//                             decoration: InputDecoration(
//                               labelText: "Enter email",
//                               prefixIcon:
//                                   const Icon(Icons.email, color: kButtonColor),
//                               filled: true,
//                               fillColor: Colors.white,
//                               enabledBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 borderSide: const BorderSide(
//                                   color: kButtonColor,
//                                   width: 1.5,
//                                 ),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 borderSide: const BorderSide(
//                                   color: kButtonColor,
//                                   width: 2,
//                                 ),
//                               ),
//                             ),
//                             validator: (val) {
//                               if (val == null || val.trim().isEmpty) {
//                                 return "Email required";
//                               }
//                               final emailRegex =
//                                   RegExp(r"^[\w._%+-]+@[a-z0-9]+\.[a-z]{2,}$");
//                               if (!emailRegex
//                                   .hasMatch(val.trim().toLowerCase())) {
//                                 return "Enter valid email";
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 16),

//                           // Password Input
//                           TextFormField(
//                             controller: passwordController,
//                             obscureText: !isPasswordVisible,
//                             decoration: InputDecoration(
//                               labelText: "Enter password",
//                               prefixIcon:
//                                   const Icon(Icons.lock, color: kButtonColor),
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                   isPasswordVisible
//                                       ? Icons.visibility
//                                       : Icons.visibility_off,
//                                   color: kButtonColor,
//                                 ),
//                                 onPressed: () => setState(() =>
//                                     isPasswordVisible = !isPasswordVisible),
//                               ),
//                               filled: true,
//                               fillColor: Colors.white,
//                               enabledBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 borderSide: const BorderSide(
//                                   color: kButtonColor,
//                                   width: 1.5,
//                                 ),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 borderSide: const BorderSide(
//                                   color: kButtonColor,
//                                   width: 2,
//                                 ),
//                               ),
//                             ),
//                             validator: (val) => val == null || val.isEmpty
//                                 ? "Password required"
//                                 : null,
//                           ),

//                           Align(
//                             alignment: Alignment.centerRight,
//                             child: TextButton(
//                               onPressed: () =>
//                                   _showForgotPasswordDialog(context),
//                               child: const Text(
//                                 "Forgot password?",
//                                 style: TextStyle(
//                                   decoration: TextDecoration.underline,
//                                   color: kAppBarColor,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 10),

//                           // Employee Sign In Button
//                           SizedBox(
//                             width: double.infinity,
//                             height: 44,
//                             child: ElevatedButton(
//                               onPressed: _isEmpLoading
//                                   ? null
//                                   : () => _login(isAdmin: false),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: kButtonColor,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               child: _isEmpLoading
//                                   ? const CircularProgressIndicator(
//                                       color: Colors.white)
//                                   : const Text(
//                                       "Sign in as employee",
//                                       style: TextStyle(color: kTextColor),
//                                     ),
//                             ),
//                           ),
//                           const SizedBox(height: 10),

//                           // Admin Sign In Button
//                           SizedBox(
//                             width: fullWidth,
//                             height: 44,
//                             child: ElevatedButton(
//                               onPressed: _isAdminLoading
//                                   ? null
//                                   : () => _login(isAdmin: true),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: kButtonColor,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               child: _isAdminLoading
//                                   ? const CircularProgressIndicator(
//                                       color: Colors.white)
//                                   : const Text(
//                                       "Sign in as admin",
//                                       style: TextStyle(color: kTextColor),
//                                     ),
//                             ),
//                           ),

//                           const SizedBox(height: 12),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Small helper for width without changing UI/logic
// double get fullWidth => double.infinity;
// lib/Pagesusers/login_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional web localStorage (html_web.dart should define a `window` shim)
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/Pagesusers/home_screen_page.dart';
import 'package:serv_app/Pagesadmin/admin_dashboard_page.dart';
import 'package:serv_app/Pagesadmin/company_details_page.dart';
// If you actually use it elsewhere keep this, otherwise you can remove
import 'package:serv_app/Pagesadmin/company_setup_page.dart';
// ===== THEME =====
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ===== API BASE =====
const String _apiBase = 'http://localhost:3000/api';

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

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------- COMPANY PROFILE HELPERS (Admin flow) ----------
  Future<bool> isProfileFilled(String token) async {
    final res = await http.get(
      Uri.parse('$_apiBase/company/profile/check'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return (body['filled'] ?? false) == true;
    }
    throw Exception('Failed to check profile status (${res.statusCode})');
  }

  Future<Map<String, dynamic>> fetchCompanyProfile(String token) async {
    final res = await http.get(
      Uri.parse('$_apiBase/company/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load company profile (${res.statusCode})');
  }

  // ---------- FORGOT PASSWORD (Email -> OTP -> New Password) ----------
  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailCtrl = TextEditingController(text: idController.text.trim());
    final otpCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();

    final emailKey = GlobalKey<FormState>();
    final otpKey = GlobalKey<FormState>();
    final resetKey = GlobalKey<FormState>();

    bool sending = false;
    bool verifying = false;
    bool resetting = false;

    bool otpSent = false;
    bool otpVerified = false;

    const int otpValidSeconds = 10 * 60; // 10 minutes
    int secondsLeft = 0;
    Timer? countdown;

    String fmt(int s) {
      final m = (s ~/ 60).toString().padLeft(2, '0');
      final r = (s % 60).toString().padLeft(2, '0');
      return '$m:$r';
    }

    void startTimer(void Function(VoidCallback fn) setDlgState) {
      secondsLeft = otpValidSeconds;
      countdown?.cancel();
      countdown = Timer.periodic(const Duration(seconds: 1), (t) {
        if (secondsLeft > 0) {
          secondsLeft--;
          setDlgState(() {});
        } else {
          t.cancel();
          setDlgState(() {}); // refresh "Expired" state
        }
      });
    }

    Future<void> sendOtp(void Function(VoidCallback fn) setDlgState) async {
      if (!emailKey.currentState!.validate()) return;
      setDlgState(() => sending = true);
      try {
        final res = await http.post(
          Uri.parse('$_apiBase/auth/forgot-password/request-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': emailCtrl.text.trim().toLowerCase()}),
        );
        if (res.statusCode == 200) {
          otpSent = true;
          startTimer(setDlgState);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP sent to your email.')),
            );
          }
        } else {
          final msg =
              (jsonDecode(res.body)['error'] ?? 'Failed to send OTP').toString();
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        setDlgState(() => sending = false);
      }
    }

    Future<void> verifyOtp(void Function(VoidCallback fn) setDlgState) async {
      if (!otpKey.currentState!.validate()) return;
      if (secondsLeft <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP expired. Please resend.')),
          );
        }
        return;
      }
      setDlgState(() => verifying = true);
      try {
        final res = await http.post(
          Uri.parse('$_apiBase/auth/forgot-password/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': emailCtrl.text.trim().toLowerCase(),
            'otp': otpCtrl.text.trim(),
          }),
        );
        if (res.statusCode == 200) {
          otpVerified = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('OTP verified. Please set new password.')),
            );
          }
        } else {
          final msg =
              (jsonDecode(res.body)['error'] ?? 'Invalid OTP').toString();
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        setDlgState(() => verifying = false);
      }
    }

    Future<void> resetPassword(
      void Function(VoidCallback fn) setDlgState,
    ) async {
      if (!resetKey.currentState!.validate()) return;
      setDlgState(() => resetting = true);
      try {
        final res = await http.post(
          Uri.parse('$_apiBase/auth/forgot-password/reset'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': emailCtrl.text.trim().toLowerCase(),
            'otp': otpCtrl.text.trim(),
            'newPassword': newPwdCtrl.text,
          }),
        );
        if (res.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Password reset successful. Please log in.')),
            );
          }
          countdown?.cancel();
          if (mounted) Navigator.of(context).pop(); // Close dialog
        } else {
          final msg =
              (jsonDecode(res.body)['error'] ?? 'Reset failed').toString();
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        setDlgState(() => resetting = false);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          // Decide which step to render
          Widget content;
          List<Widget> actions = [];

          if (!otpSent) {
            // Step 1: Email
            content = Form(
              key: emailKey,
              child: TextFormField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  hintText: "Enter your registered email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Email required";
                  final re = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
                  if (!re.hasMatch(v.trim())) return "Enter valid email";
                  return null;
                },
              ),
            );
            actions = [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
                onPressed: sending ? null : () => sendOtp(setDlgState),
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Send OTP",
                        style: TextStyle(color: kTextColor)),
              ),
            ];
          } else if (!otpVerified) {
            // Step 2: OTP
            content = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Form(
                  key: otpKey,
                  child: TextFormField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: "Enter 6-digit OTP",
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "OTP required";
                      }
                      if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                        return "Enter 6-digit OTP";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      secondsLeft > 0
                          ? "Expires in ${fmt(secondsLeft)}"
                          : "OTP expired",
                      style: TextStyle(
                        color:
                            secondsLeft > 0 ? Colors.black54 : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: sending ? null : () => sendOtp(setDlgState),
                      child: const Text("Resend OTP"),
                    ),
                  ],
                ),
              ],
            );
            actions = [
              TextButton(
                onPressed: () {
                  countdown?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
                onPressed: verifying ? null : () => verifyOtp(setDlgState),
                child: verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Verify OTP",
                        style: TextStyle(color: kTextColor)),
              ),
            ];
          } else {
            // Step 3: New Password
            content = Form(
              key: resetKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: newPwdCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Enter new password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Password required";
                      if (v.length < 6) return "Min 6 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: confirmPwdCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Confirm new password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Confirm password";
                      if (v != newPwdCtrl.text) return "Passwords do not match";
                      return null;
                    },
                  ),
                ],
              ),
            );
            actions = [
              TextButton(
                onPressed: () {
                  countdown?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
                onPressed: resetting ? null : () => resetPassword(setDlgState),
                child: resetting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Submit",
                        style: TextStyle(color: kTextColor)),
              ),
            ];
          }

          return AlertDialog(
            title: const Text("Forgot Password"),
            content: content,
            actions: actions,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        },
      ),
    ).whenComplete(() {
      countdown?.cancel();
    });
  }

  // ---------- PERSIST HELPERS ----------
  Future<void> _persist(String key, String value) async {
    // Web localStorage
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
    // SharedPreferences (mobile/desktop)
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, value);
  }

  // ---------- LOGIN ----------
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
      final pwd = passwordController.text; // keep exact

      final response = await http
          .post(
            Uri.parse('$_apiBase/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': pwd}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final tok = (data['token'] ?? '').toString();
        final role = (data['role'] ?? '').toString();

        if (tok.isEmpty || role.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid server response')),
          );
          return;
        }

        CompanyData.token = tok;
        await _persist('token', tok);
        await _persist('role', role);

        // role checks vs button pressed
        if (isAdmin && role != 'admin') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Not authorized as admin.")),
          );
          return;
        }
        if (!isAdmin && role != 'employee') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Not authorized as employee.")),
          );
          return;
        }

        if (isAdmin) {
          // ADMIN FLOW
          final filled = await isProfileFilled(tok);
          if (filled) {
            final jsonProfile = await fetchCompanyProfile(tok);
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AdminDashboard(
                  companyProfile: CompanyProfile(
                    name: (jsonProfile['companyName'] ?? '').toString(),
                    adminName: (jsonProfile['adminName'] ?? '').toString(),
                    logoUrl: ((jsonProfile['logo'] as String?)?.isNotEmpty ??
                            false)
                        ? '$_apiBase${jsonProfile['logo']}'.replaceFirst('/api', '')
                        : null,
                  ),
                ),
              ),
            );
          } else {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const CompanyDetailsFormPage()),
            );
          }
        } else {
          // EMPLOYEE FLOW
          String realName = '';
          String docId = '';
          String empId = '';

          // Decode token -> user id (if present)
          try {
            final decoded = JwtDecoder.decode(tok);
            docId = (decoded['userId'] ?? decoded['uid'] ?? '').toString();
          } catch (_) {
            docId = '';
          }

          // call /auth/me for richer info
          try {
            final meRes = await http.get(
              Uri.parse('$_apiBase/auth/me'),
              headers: {'Authorization': 'Bearer $tok'},
            );
            if (meRes.statusCode == 200) {
              final meData = jsonDecode(meRes.body) as Map<String, dynamic>;

              final profile = (meData['employeeProfile'] is Map)
                  ? (meData['employeeProfile'] as Map)
                  : <String, dynamic>{};

              realName = (meData['name'] ??
                      profile['name'] ??
                      meData['fullName'] ??
                      '')
                  .toString()
                  .trim();

              empId = (meData['empid'] ??
                      profile['empid'] ??
                      meData['employeeId'] ??
                      profile['employeeId'] ??
                      '')
                  .toString()
                  .trim();

              // cache for other pages
              await _persist(
                'employeeProfile',
                jsonEncode({
                  ...profile,
                  if (meData['empid'] != null) 'empid': meData['empid'],
                  if (meData['name'] != null) 'name': meData['name'],
                }),
              );
            } else {
              realName = email.split('@').first;
            }
          } catch (_) {
            realName = email.split('@').first;
          }

          if (docId.isNotEmpty) await _persist('userDocId', docId);
          if (realName.isNotEmpty) await _persist('name', realName);
          if (empId.isNotEmpty) await _persist('empid', empId);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  HomeScreen(userName: realName, employeeDocId: docId),
            ),
          );
        }
      } else {
        final msg =
            (data['message'] ?? data['error'] ?? 'Login failed').toString();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCC00),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/loginlogo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Sign In',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
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
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: kButtonColor,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: kButtonColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Email required";
                              }
                              final emailRegex = RegExp(
                                  r"^[\w._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$",
                                  caseSensitive: false);
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
                                    () => isPasswordVisible = !isPasswordVisible),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: kButtonColor,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: kButtonColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty
                                    ? "Password required"
                                    : null,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showForgotPasswordDialog(context),
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

                          // Employee Sign In
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isEmpLoading
                                  ? null
                                  : () => _login(isAdmin: false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isEmpLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Sign in as employee",
                                      style: TextStyle(color: kTextColor),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Admin Sign In
                          SizedBox(
                            width: fullWidth,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isAdminLoading
                                  ? null
                                  : () => _login(isAdmin: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isAdminLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Sign in as admin",
                                      style: TextStyle(color: kTextColor),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
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

// Small helper for width without changing UI/logic
double get fullWidth => double.infinity;
