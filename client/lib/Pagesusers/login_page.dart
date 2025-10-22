// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer' as dev;
// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // Web localStorage shim
// import 'package:serv_app/html_stub.dart'
//     if (dart.library.html) 'package:serv_app/html_web.dart' as html;

// import 'package:serv_app/models/company_data.dart';
// import 'package:serv_app/Pagesusers/home_screen_page.dart';
// import 'package:serv_app/Pagesadmin/admin_dashboard_page.dart';
// import 'package:serv_app/Pagesadmin/company_details_page.dart';
// import 'package:serv_app/Pagesadmin/company_setup_page.dart';

// // ===== THEME =====
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// // ===== API BASE =====
// const String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final idController = TextEditingController();
//   final passwordController = TextEditingController();

//   bool isPasswordVisible = false;
//   bool _isEmpLoading = false;
//   bool _isAdminLoading = false;

//   @override
//   void dispose() {
//     idController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   // ---------- UI helpers ----------
//   void _showSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   Future<void> _persist(String key, String value) async {
//     try {
//       html.window.localStorage[key] = value; // web
//     } catch (_) {}
//     final sp = await SharedPreferences.getInstance(); // mobile/desktop
//     await sp.setString(key, value);
//   }

//   // ---------- COMPANY PROFILE (Admin) ----------
//   /// Returns { exists: bool, data: Map, raw: Map }.
//   /// NOTE: 404 is treated as {exists:false} so we route to setup without error.
//   Future<Map<String, dynamic>> _checkCompanyProfile({
//     required String token,
//     required String adminEmail,
//   }) async {
//     Map<String, dynamic> norm(dynamic body) {
//       final m = (body is Map) ? body : <String, dynamic>{};
//       final exists = (m['exists'] == true) ||
//           (m['filled'] == true) ||
//           (m['hasProfile'] == true);
//       final data = (m['data'] is Map)
//           ? (m['data'] as Map).cast<String, dynamic>()
//           : <String, dynamic>{};
//       return {'exists': exists, 'data': data, 'raw': m};
//     }

//     Future<Map<String, dynamic>> treat404() async => {
//           'exists': false,
//           'data': <String, dynamic>{},
//           'raw': <String, dynamic>{}
//         };

//     // 1) Try /company/profile/check
//     final u1 = Uri.parse('$_apiBase/company/profile/check');
//     try {
//       final r1 = await http.get(u1, headers: {
//         'Authorization': 'Bearer $token',
//         'Accept': 'application/json'
//       }).timeout(const Duration(seconds: 15));
//       dev.log('[GET] $u1 -> ${r1.statusCode}');
//       if (r1.statusCode == 200) return norm(jsonDecode(r1.body));
//       if (r1.statusCode == 404) return treat404();
//       // fall through to fallback for non-200/404
//     } catch (e) {
//       dev.log('profile/check exception: $e');
//     }

//     // 2) Fallback /company/profile?email=...
//     final u2 = Uri.parse('$_apiBase/company/profile')
//         .replace(queryParameters: {'email': adminEmail.trim().toLowerCase()});
//     final r2 = await http.get(u2, headers: {
//       'Authorization': 'Bearer $token',
//       'Accept': 'application/json'
//     }).timeout(const Duration(seconds: 15));

//     dev.log('[GET] $u2 -> ${r2.statusCode}');
//     if (r2.statusCode == 200) return norm(jsonDecode(r2.body));
//     if (r2.statusCode == 404) return treat404();

//     // any other status is a real error
//     dynamic err;
//     try {
//       err = jsonDecode(r2.body);
//     } catch (_) {}
//     throw Exception('HTTP ${r2.statusCode} ${r2.reasonPhrase} ${err ?? ''}');
//   }

//   // ---------- FORGOT PASSWORD DIALOG ----------
//   Future<void> _showForgotPasswordDialog(BuildContext context) async {
//     final emailCtrl = TextEditingController(text: idController.text.trim());
//     final otpCtrl = TextEditingController();
//     final newPwdCtrl = TextEditingController();
//     final confirmPwdCtrl = TextEditingController();

//     final emailKey = GlobalKey<FormState>();
//     final otpKey = GlobalKey<FormState>();
//     final resetKey = GlobalKey<FormState>();

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
//           setDlgState(() {});
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
//           _showSnack('OTP sent to your email.');
//         } else {
//           final msg = (jsonDecode(res.body)['error'] ?? 'Failed to send OTP')
//               .toString();
//           _showSnack(msg);
//         }
//       } catch (e) {
//         _showSnack('Error: $e');
//       } finally {
//         setDlgState(() => sending = false);
//       }
//     }

//     Future<void> verifyOtp(void Function(VoidCallback fn) setDlgState) async {
//       if (!otpKey.currentState!.validate()) return;
//       if (secondsLeft <= 0) {
//         _showSnack('OTP expired. Please resend.');
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
//           _showSnack('OTP verified. Please set new password.');
//         } else {
//           final msg =
//               (jsonDecode(res.body)['error'] ?? 'Invalid OTP').toString();
//           _showSnack(msg);
//         }
//       } catch (e) {
//         _showSnack('Error: $e');
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
//           _showSnack('Password reset successful. Please log in.');
//           countdown?.cancel();
//           if (mounted) Navigator.of(context).pop();
//         } else {
//           final msg =
//               (jsonDecode(res.body)['error'] ?? 'Reset failed').toString();
//           _showSnack(msg);
//         }
//       } catch (e) {
//         _showSnack('Error: $e');
//       } finally {
//         setDlgState(() => resetting = false);
//       }
//     }

//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => StatefulBuilder(
//         builder: (ctx, setDlgState) {
//           Widget content;
//           List<Widget> actions = [];

//           if (!otpSent) {
//             content = Form(
//               key: emailKey,
//               child: TextFormField(
//                 controller: emailCtrl,
//                 decoration: InputDecoration(
//                   hintText: "Enter your registered email",
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) return "Email required";
//                   final re = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
//                   if (!re.hasMatch(v.trim())) return "Enter valid email";
//                   return null;
//                 },
//               ),
//             );
//             actions = [
//               TextButton(
//                   onPressed: () => Navigator.pop(ctx),
//                   child: const Text("Cancel")),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
//                 onPressed: sending ? null : () => sendOtp(setDlgState),
//                 child: sending
//                     ? const _ArcLoader(size: 20, color: Colors.white, strokeWidth: 2)
//                     : const Text("Send OTP",
//                         style: TextStyle(color: kTextColor)),
//               ),
//             ];
//           } else if (!otpVerified) {
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
//                           borderRadius: BorderRadius.circular(8)),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.trim().isEmpty) return "OTP required";
//                       if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
//                         return "Enter 6-digit OTP";
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//               ],
//             );
//             actions = [
//               TextButton(
//                   onPressed: () => Navigator.pop(ctx),
//                   child: const Text("Cancel")),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
//                 onPressed: verifying ? null : () => verifyOtp(setDlgState),
//                 child: verifying
//                     ? const _ArcLoader(size: 20, color: Colors.white, strokeWidth: 2)
//                     : const Text("Verify OTP",
//                         style: TextStyle(color: kTextColor)),
//               ),
//             ];
//           } else {
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
//                           borderRadius: BorderRadius.circular(8)),
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
//                           borderRadius: BorderRadius.circular(8)),
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
//                   onPressed: () => Navigator.pop(ctx),
//                   child: const Text("Cancel")),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
//                 onPressed: resetting ? null : () => resetPassword(setDlgState),
//                 child: resetting
//                     ? const _ArcLoader(size: 20, color: Colors.white, strokeWidth: 2)
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

//   // ---------- LOGIN ----------
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
//       final email = idController.text.trim().toLowerCase();
//       final pwd = passwordController.text;

//       final response = await http
//           .post(
//             Uri.parse('$_apiBase/auth/login'),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({'email': email, 'password': pwd}),
//           )
//           .timeout(const Duration(seconds: 15));

//       final data = jsonDecode(response.body) as Map<String, dynamic>;

//       if (response.statusCode == 200) {
//         final tok = (data['token'] ?? '').toString();
//         final role = (data['role'] ?? '').toString();

//         if (tok.isEmpty || role.isEmpty) {
//           _showSnack('Invalid server response');
//           return;
//         }

//         // Store token/role ASAP
//         CompanyData.token = tok;
//         await _persist('token', tok);
//         await _persist('role', role);

//         // role checks vs button pressed
//         if (isAdmin && role != 'admin') {
//           _showSnack("Not authorized as admin.");
//           return;
//         }
//         if (!isAdmin && role != 'employee') {
//           _showSnack("Not authorized as employee.");
//           return;
//         }

//         if (isAdmin) {
//           // ADMIN FLOW
//           try {
//             final result =
//                 await _checkCompanyProfile(token: tok, adminEmail: email);
//             final exists = result['exists'] == true;
//             final companyData =
//                 result['data'] as Map<String, dynamic>? ?? const {};

//             if (exists) {
//               if (!mounted) return;
// Navigator.of(context).pushAndRemoveUntil(
//   MaterialPageRoute(builder: (_) => AdminDashboard(
//     companyProfile: CompanyProfile(
//       name: (companyData['companyName'] ?? '').toString(),
//       adminName: (companyData['adminName'] ?? '').toString(),
//       logoUrl: companyData['logoUrl']?.toString(),
//     ),
//   )),
//   (route) => false,
// );


//             } else {
//               if (!mounted) return;
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                     builder: (_) => const CompanyDetailsFormPage()),
//               );
//             }
//           } catch (e) {
//             dev.log('Company profile check failed: $e');
//             _showSnack('Company profile check failed: $e');
//           }
//         } else {
//           // EMPLOYEE FLOW
//           // 1) Seed from login response immediately
//           String empIdSeed = (data['empId'] ??
//                   data['empid'] ??
//                   data['user']?['empId'] ??
//                   data['user']?['empid'] ??
//                   '')
//               .toString()
//               .trim();

//           String nameSeed =
//               (data['name'] ?? data['user']?['name'] ?? '').toString().trim();

//           if (nameSeed.isEmpty) {
//             try {
//               final decoded = JwtDecoder.decode(tok);
//               nameSeed = (decoded['name'] ?? '').toString().trim();
//             } catch (_) {}
//           }

//           if (empIdSeed.isNotEmpty) {
//             await _persist('empId', empIdSeed);
//             await _persist('empid', empIdSeed); // legacy
//           }
//           if (nameSeed.isNotEmpty) {
//             await _persist('name', nameSeed);
//           }

//           // 2) Decode token for docId (optional)
//           String docId = '';
//           try {
//             final decoded = JwtDecoder.decode(tok);
//             docId = (decoded['userId'] ?? decoded['uid'] ?? '').toString();
//           } catch (_) {}

//           // 3) Normalize with /auth/me
//           try {
//             final meRes = await http.get(
//               Uri.parse('$_apiBase/auth/me'),
//               headers: {'Authorization': 'Bearer $tok'},
//             );
//             if (meRes.statusCode == 200) {
//               final meData = jsonDecode(meRes.body) as Map<String, dynamic>;
//               final profile = (meData['employeeProfile'] is Map)
//                   ? Map<String, dynamic>.from(meData['employeeProfile'])
//                   : <String, dynamic>{};

//               final realName = (meData['name'] ??
//                       profile['name'] ??
//                       meData['fullName'] ??
//                       nameSeed)
//                   .toString()
//                   .trim();

//               final empId = (meData['empId'] ??
//                       profile['empId'] ??
//                       meData['empid'] ??
//                       profile['empid'] ??
//                       meData['employeeId'] ??
//                       profile['employeeId'] ??
//                       empIdSeed)
//                   .toString()
//                   .trim();

//               await _persist(
//                 'employeeProfile',
//                 jsonEncode({
//                   ...profile,
//                   if (realName.isNotEmpty) 'name': realName,
//                   if (empId.isNotEmpty) 'empId': empId,
//                 }),
//               );

//               if (realName.isNotEmpty) await _persist('name', realName);
//               if (empId.isNotEmpty) {
//                 await _persist('empId', empId);
//                 await _persist('empid', empId);
//               }
//             }
//           } catch (_) {
//             // ignore
//           }

//           if (docId.isNotEmpty) await _persist('userDocId', docId);

//           if (!mounted) return;
// Navigator.of(context).pushAndRemoveUntil(
//   MaterialPageRoute(
//     builder: (_) => HomeScreen(
//       userName: nameSeed.isNotEmpty ? nameSeed : email.split('@').first,
//       employeeDocId: docId,
//     ),
//   ),
//   (route) => false,
// );

//         }
//       } else {
//         final msg =
//             (data['message'] ?? data['error'] ?? 'Login failed').toString();
//         _showSnack(msg);
//       }
//     } catch (e) {
//       _showSnack('Error: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isEmpLoading = false;
//           _isAdminLoading = false;
//         });
//       }
//     }
//   }

//   // ---------- UI ----------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
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
//         child: SafeArea(
//           child: LayoutBuilder(
//             builder: (ctx, constraints) {
//               return SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 child: ConstrainedBox(
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
//                               color: kPrimaryBackgroundBottom,
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             clipBehavior: Clip.antiAlias,
//                             child: Image.asset('assets/images/loginlogo.png',
//                                 fit: BoxFit.cover),
//                           ),
//                           const SizedBox(height: 10),
//                           const Text('Sign In',
//                               style: TextStyle(
//                                   fontSize: 22, fontWeight: FontWeight.bold)),
//                           const SizedBox(height: 30),

//                           // Email
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
//                                     color: kButtonColor, width: 1.5),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 borderSide: const BorderSide(
//                                     color: kButtonColor, width: 2),
//                               ),
//                             ),
//                             validator: (val) {
//                               if (val == null || val.trim().isEmpty) {
//                                 return "Email required";
//                               }
//                               final emailRegex = RegExp(
//                                 r"^[\w._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$",
//                                 caseSensitive: false,
//                               );
//                               if (!emailRegex.hasMatch(val.trim())) {
//                                 return "Enter valid email";
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 16),

//                           // Password
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
//                                     color: kButtonColor, width: 1.5),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 borderSide: const BorderSide(
//                                     color: kButtonColor, width: 2),
//                               ),
//                             ),
//                             validator: (val) => (val == null || val.isEmpty)
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

//                           // Employee Sign In
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
//                                     borderRadius: BorderRadius.circular(8)),
//                               ),
//                               child: _isEmpLoading
//                                   ? const _ArcLoader(size: 22, color: Colors.white)
//                                   : const Text("Sign in as employee",
//                                       style: TextStyle(color: kTextColor)),
//                             ),
//                           ),
//                           const SizedBox(height: 10),

//                           // Admin Sign In
//                           SizedBox(
//                             width: double.infinity,
//                             height: 44,
//                             child: ElevatedButton(
//                               onPressed: _isAdminLoading
//                                   ? null
//                                   : () => _login(isAdmin: true),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: kButtonColor,
//                                 shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8)),
//                               ),
//                               child: _isAdminLoading
//                                   ? const _ArcLoader(size: 22, color: Colors.white)
//                                   : const Text("Sign in as admin",
//                                       style: TextStyle(color: kTextColor)),
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

// /// ─────────────────────────────────────────────────────────────────────────
// /// Two-arc loader (matches your ref: row 2, column 4)
// /// ─────────────────────────────────────────────────────────────────────────
// class _ArcLoader extends StatefulWidget {
//   final double size;
//   final Color color;
//   final double strokeWidth;
//   const _ArcLoader({
//     required this.size,
//     required this.color,
//     this.strokeWidth = 3,
//   });

//   @override
//   State<_ArcLoader> createState() => _ArcLoaderState();
// }

// class _ArcLoaderState extends State<_ArcLoader>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _c;

//   @override
//   void initState() {
//     super.initState();
    
//     _c = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _c.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: widget.size,
//       height: widget.size,
//       child: AnimatedBuilder(
//         animation: _c,
//         builder: (context, _) {
//           return Transform.rotate(
//             angle: _c.value * 2 * math.pi,
//             child: CustomPaint(
//               painter: _ArcPainter(
//                 color: widget.color,
//                 strokeWidth: widget.strokeWidth,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class _ArcPainter extends CustomPainter {
//   final Color color;
//   final double strokeWidth;
//   _ArcPainter({required this.color, required this.strokeWidth});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = strokeWidth
//       ..color = color;

//     final rect = Offset.zero & size;
//     const sweep = math.pi * 0.8; // ~144°
//     const gap = math.pi; // opposite side

//     // first arc
//     canvas.drawArc(rect.deflate(strokeWidth / 2), 0, sweep, false, paint);
//     // second arc (opposite side)
//     canvas.drawArc(rect.deflate(strokeWidth / 2), gap, sweep, false, paint);
//   }

//   @override
//   bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
//       oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
// }
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ⬇️ NEW: permission + biometric + intents + gps
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

// Web localStorage shim
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/Pagesusers/home_screen_page.dart';
import 'package:serv_app/Pagesadmin/admin_dashboard_page.dart';
import 'package:serv_app/Pagesadmin/company_details_page.dart';
import 'package:serv_app/Pagesadmin/company_setup_page.dart';

// ===== THEME =====
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ===== API BASE =====
const String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

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

  // ---------- COMPANY PROFILE (Admin) ----------
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
    final u1 = Uri.parse('$_apiBase/company/profile/check');
    try {
      final r1 = await http.get(u1, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 15));
      dev.log('[GET] $u1 -> ${r1.statusCode}');
      if (r1.statusCode == 200) return norm(jsonDecode(r1.body));
      if (r1.statusCode == 404) return treat404();
      // fall through to fallback for non-200/404
    } catch (e) {
      dev.log('profile/check exception: $e');
    }

    // 2) Fallback /company/profile?email=...
    final u2 = Uri.parse('$_apiBase/company/profile')
        .replace(queryParameters: {'email': adminEmail.trim().toLowerCase()});
    final r2 = await http.get(u2, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 15));

    dev.log('[GET] $u2 -> ${r2.statusCode}');
    if (r2.statusCode == 200) return norm(jsonDecode(r2.body));
    if (r2.statusCode == 404) return treat404();

    // any other status is a real error
    dynamic err;
    try {
      err = jsonDecode(r2.body);
    } catch (_) {}
    throw Exception('HTTP ${r2.statusCode} ${r2.reasonPhrase} ${err ?? ''}');
  }

  // ---------- FORGOT PASSWORD DIALOG ----------
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
          setDlgState(() {});
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
          _showSnack('OTP sent to your email.');
        } else {
          final msg = (jsonDecode(res.body)['error'] ?? 'Failed to send OTP')
              .toString();
          _showSnack(msg);
        }
      } catch (e) {
        _showSnack('Error: $e');
      } finally {
        setDlgState(() => sending = false);
      }
    }

    Future<void> verifyOtp(void Function(VoidCallback fn) setDlgState) async {
      if (!otpKey.currentState!.validate()) return;
      if (secondsLeft <= 0) {
        _showSnack('OTP expired. Please resend.');
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
          _showSnack('OTP verified. Please set new password.');
        } else {
          final msg =
              (jsonDecode(res.body)['error'] ?? 'Invalid OTP').toString();
          _showSnack(msg);
        }
      } catch (e) {
        _showSnack('Error: $e');
      } finally {
        setDlgState(() => verifying = false);
      }
    }

    Future<void> resetPassword(
        void Function(VoidCallback fn) setDlgState) async {
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
          _showSnack('Password reset successful. Please log in.');
          countdown?.cancel();
          if (mounted) Navigator.of(context).pop();
        } else {
          final msg =
              (jsonDecode(res.body)['error'] ?? 'Reset failed').toString();
          _showSnack(msg);
        }
      } catch (e) {
        _showSnack('Error: $e');
      } finally {
        setDlgState(() => resetting = false);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          Widget content;
          List<Widget> actions = [];

          if (!otpSent) {
            content = Form(
              key: emailKey,
              child: TextFormField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  hintText: "Enter your registered email",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
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
                  child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
                onPressed: sending ? null : () => sendOtp(setDlgState),
                child: sending
                    ? const _ArcLoader(size: 20, color: Colors.white, strokeWidth: 2)
                    : const Text("Send OTP",
                        style: TextStyle(color: kTextColor)),
              ),
            ];
          } else if (!otpVerified) {
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
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "OTP required";
                      if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                        return "Enter 6-digit OTP";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
            actions = [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
                onPressed: verifying ? null : () => verifyOtp(setDlgState),
                child: verifying
                    ? const _ArcLoader(size: 20, color: Colors.white, strokeWidth: 2)
                    : const Text("Verify OTP",
                        style: TextStyle(color: kTextColor)),
              ),
            ];
          } else {
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
                          borderRadius: BorderRadius.circular(8)),
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
                          borderRadius: BorderRadius.circular(8)),
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
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
                onPressed: resetting ? null : () => resetPassword(setDlgState),
                child: resetting
                    ? const _ArcLoader(size: 20, color: Colors.white, strokeWidth: 2)
                    : const Text("Submit", style: TextStyle(color: kTextColor)),
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

  // ---------- PERMISSION FLOW (NEW) ----------
  Future<void> _showPermissionIntroThenRequest() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We need location access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'To track your attendance and location during work hours, we need the following permissions:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Location Permission
              _buildPermissionItem(
                icon: Icons.location_on_outlined,
                title: 'Device Location',
                description: 'To track your location for attendance and work hours',
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 16),
              // Location Accuracy
              _buildPermissionItem(
                icon: Icons.gps_fixed_outlined,
                title: 'Location Accuracy',
                description: 'For precise tracking of your work location',
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text(
                      'Not Now',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _requestAllPermissions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Allow All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    // Request location permissions
    var locationStatus = await Permission.locationWhenInUse.status;
    if (!locationStatus.isGranted) {
      locationStatus = await Permission.locationWhenInUse.request();
    }

    // Request precise location (Android 12+)
    if (locationStatus.isGranted) {
      await Permission.location.request();
    }

    // Ensure GPS is ON
    final gpsOn = await Geolocator.isLocationServiceEnabled();
    if (!gpsOn && mounted) {
      _showSnack('Please enable Location Services for accurate check-in.');
      // Open location settings if GPS is off
      try {
        await Geolocator.openLocationSettings();
      } catch (e) {
        dev.log('Error opening location settings: $e');
      }
    }
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
      final pwd = passwordController.text;

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
          _showSnack('Invalid server response');
          return;
        }

        // Store token/role ASAP
        CompanyData.token = tok;
        await _persist('token', tok);
        await _persist('role', role);

        // role checks vs button pressed
        if (isAdmin && role != 'admin') {
          _showSnack("Not authorized as admin.");
          return;
        }
        if (!isAdmin && role != 'employee') {
          _showSnack("Not authorized as employee.");
          return;
        }

        if (isAdmin) {
          // ADMIN FLOW
          try {
            final result =
                await _checkCompanyProfile(token: tok, adminEmail: email);
            final exists = result['exists'] == true;
            final companyData =
                result['data'] as Map<String, dynamic>? ?? const {};

            if (exists) {
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => AdminDashboard(
                  companyProfile: CompanyProfile(
                    name: (companyData['companyName'] ?? '').toString(),
                    adminName: (companyData['adminName'] ?? '').toString(),
                    logoUrl: companyData['logoUrl']?.toString(),
                  ),
                )),
                (route) => false,
              );
            } else {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const CompanyDetailsFormPage()),
              );
            }
          } catch (e) {
            dev.log('Company profile check failed: $e');
            _showSnack('Company profile check failed: $e');
          }
        } else {
          // EMPLOYEE FLOW
          // 1) Seed from login response immediately
          String empIdSeed = (data['empId'] ??
                  data['empid'] ??
                  data['user']?['empId'] ??
                  data['user']?['empid'] ??
                  '')
              .toString()
              .trim();

          String nameSeed =
              (data['name'] ?? data['user']?['name'] ?? '').toString().trim();

          if (nameSeed.isEmpty) {
            try {
              final decoded = JwtDecoder.decode(tok);
              nameSeed = (decoded['name'] ?? '').toString().trim();
            } catch (_) {}
          }

          if (empIdSeed.isNotEmpty) {
            await _persist('empId', empIdSeed);
            await _persist('empid', empIdSeed); // legacy
          }
          if (nameSeed.isNotEmpty) {
            await _persist('name', nameSeed);
          }

          // 2) Decode token for docId (optional)
          String docId = '';
          try {
            final decoded = JwtDecoder.decode(tok);
            docId = (decoded['userId'] ?? decoded['uid'] ?? '').toString();
          } catch (_) {}

          // 3) Normalize with /auth/me
          try {
            final meRes = await http.get(
              Uri.parse('$_apiBase/auth/me'),
              headers: {'Authorization': 'Bearer $tok'},
            );
            if (meRes.statusCode == 200) {
              final meData = jsonDecode(meRes.body) as Map<String, dynamic>;
              final profile = (meData['employeeProfile'] is Map)
                  ? Map<String, dynamic>.from(meData['employeeProfile'])
                  : <String, dynamic>{};

              final realName = (meData['name'] ??
                      profile['name'] ??
                      meData['fullName'] ??
                      nameSeed)
                  .toString()
                  .trim();

              final empId = (meData['empId'] ??
                      profile['empId'] ??
                      meData['empid'] ??
                      profile['empid'] ??
                      meData['employeeId'] ??
                      profile['employeeId'] ??
                      empIdSeed)
                  .toString()
                  .trim();

              await _persist(
                'employeeProfile',
                jsonEncode({
                  ...profile,
                  if (realName.isNotEmpty) 'name': realName,
                  if (empId.isNotEmpty) 'empId': empId,
                }),
              );

              if (realName.isNotEmpty) await _persist('name', realName);
              if (empId.isNotEmpty) {
                await _persist('empId', empId);
                await _persist('empid', empId);
              }
            }
          } catch (_) {
            // ignore
          }

          if (docId.isNotEmpty) await _persist('userDocId', docId);

          // ⬇️ NEW: Immediately show permission intro + system prompts (employee)
          if (mounted) {
            await _showPermissionIntroThenRequest();
          }

          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                userName: nameSeed.isNotEmpty ? nameSeed : email.split('@').first,
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 96), // ~1 inch (96 logical pixels)
                          Container(
                            height: 110, // Increased by 96px (1 inch) from 70px
                            width: 110,  // Increased proportionally
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color.fromARGB(255, 255, 255, 255), // Light lavender color
                                width: 2.0,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset('assets/images/splash_logo.png',
                                fit: BoxFit.cover),
                          ),
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
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: kButtonColor, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: kButtonColor, width: 2),
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
                                onPressed: () => setState(() =>
                                    isPasswordVisible = !isPasswordVisible),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: kButtonColor, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: kButtonColor, width: 2),
                              ),
                            ),
                            validator: (val) => (val == null || val.isEmpty)
                                ? "Password required"
                                : null,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  _showForgotPasswordDialog(context),
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
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isEmpLoading
                                  ? const _ArcLoader(size: 22, color: Colors.white)
                                  : const Text("Sign in as employee",
                                      style: TextStyle(color: kTextColor)),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Admin Sign In
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isAdminLoading
                                  ? null
                                  : () => _login(isAdmin: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isAdminLoading
                                  ? const _ArcLoader(size: 22, color: Colors.white)
                                  : const Text("Sign in as admin",
                                      style: TextStyle(color: kTextColor)),
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

/// ─────────────────────────────────────────────────────────────────────────
/// Two-arc loader (matches your ref: row 2, column 4)
/// ─────────────────────────────────────────────────────────────────────────
class _ArcLoader extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  const _ArcLoader({
    required this.size,
    required this.color,
    this.strokeWidth = 3,
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
    const sweep = math.pi * 0.8; // ~144°
    const gap = math.pi; // opposite side

    // first arc
    canvas.drawArc(rect.deflate(strokeWidth / 2), 0, sweep, false, paint);
    // second arc (opposite side)
    canvas.drawArc(rect.deflate(strokeWidth / 2), gap, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
