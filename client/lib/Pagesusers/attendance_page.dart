// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:serv_app/models/company_data.dart'; // where you kept the token

// // Color constants
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class AttendanceScreen extends StatefulWidget {
//   /// Pass the Firestore document ID of the logged-in employee here
//   final String employeeDocId;

//   const AttendanceScreen({super.key, required this.employeeDocId});

//   @override
//   _AttendanceScreenState createState() => _AttendanceScreenState();
// }

// class _AttendanceScreenState extends State<AttendanceScreen> {
//   // User states
//   bool isFaceRegistered = false;
//   bool isShiftSelected = false;
//   bool isCheckedIn = false;
//   bool isTimerRunning = false;

//   // Dynamic user info
//   String userName = "";
//   String userId = "";
//   String dept = "";
//   String location = "";

//   // Shift selection
//   String selectedShift = "Shift";
//   bool shiftClicked = false;

//   // Timer variables
//   Timer? _timer;
//   int totalSeconds = 0;
//   String hours = "00";
//   String minutes = "00";
//   String seconds = "00";

//   @override
//   void initState() {
//     super.initState();
//     _loadUserInfo();
//     _checkUserFaceRegistration();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   /// 1) Load the employee’s profile from your backend
//   Future<void> _loadUserInfo() async {
//     final token = CompanyData.token;
//     final url = Uri.parse('https://api-zmj7dqloiq-uc.a.run.app/api/auth/me');

//     if (kDebugMode) {
//       print('[AttendanceScreen] GET $url');
//       print('[AttendanceScreen] Authorization: Bearer $token');
//     }

//     try {
//       final res = await http.get(
//         url,
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       if (kDebugMode) {
//         print('[AttendanceScreen] statusCode: ${res.statusCode}');
//         print('[AttendanceScreen] response body: ${res.body}');
//       }

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body) as Map<String, dynamic>;

//         // 🔧 FIX: read nested fields from employeeProfile if present
//         final Map<String, dynamic> profile =
//             (data['employeeProfile'] is Map<String, dynamic>)
//                 ? (data['employeeProfile'] as Map<String, dynamic>)
//                 : <String, dynamic>{};

//         setState(() {
//           userName = (data['name'] ?? profile['name'] ?? "") as String;
//           userId = (data['empid'] ?? profile['empid'] ?? "") as String;

//           // dept & location typically live under employeeProfile
//           dept = (profile['dept'] ?? data['dept'] ?? "") as String;
//           location = (profile['location'] ?? data['location'] ?? "") as String;

//           // shiftGroup typically lives under employeeProfile
//           selectedShift = (profile['shiftGroup'] ??
//               data['shiftGroup'] ??
//               "Shift") as String;

//           // If we resolved a shift name, mark it selected so the button shows it
//           final hasShift = selectedShift.isNotEmpty && selectedShift != "Shift";
//           shiftClicked = hasShift;
//           isShiftSelected = hasShift;
//         });
//       } else {
//         setState(() {
//           userName = "(unknown)";
//           userId = widget.employeeDocId;
//           dept = "";
//           location = "";
//         });
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('[AttendanceScreen] _loadUserInfo error: $e');
//       }
//       setState(() {
//         userName = "(error)";
//         userId = widget.employeeDocId;
//         dept = "";
//         location = "";
//       });
//     }
//   }

//   // Check if user face is already registered
//   Future<void> _checkUserFaceRegistration() async {
//     setState(() {
//       isFaceRegistered = false;
//     });
//   }

//   // Common check-in logic: calls the API, then starts the timer
//   Future<void> _performCheckIn(String type) async {
//     final token = CompanyData.token;
//     final url = Uri.parse('https://api-zmj7dqloiq-uc.a.run.app/api/attendance/check-in');
//     final body = jsonEncode({
//       'empid': userId,
//       'name': userName,
//       'location': location,
//     });

//     if (kDebugMode) {
//       print('[AttendanceScreen] POST $url');
//       print('[AttendanceScreen] body: $body');
//     }

//     _showLoadingDialog('Checking in…');
//     try {
//       final res = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: body,
//       );
//       Navigator.pop(context); // dismiss loading

//       if (kDebugMode) {
//         print('[AttendanceScreen] check-in statusCode: ${res.statusCode}');
//         print('[AttendanceScreen] check-in response: ${res.body}');
//       }

//       if (res.statusCode == 200 || res.statusCode == 201) {
//         setState(() => isCheckedIn = true);
//         _startWorkTimer();
//         _showSuccessDialog('Check-in successful! Timer started.');
//       } else {
//         final msg =
//             (jsonDecode(res.body)['error'] ?? jsonDecode(res.body)['message'])
//                 .toString();
//         _showErrorDialog(msg);
//       }
//     } catch (e) {
//       Navigator.pop(context);
//       _showErrorDialog('Network error: $e');
//     }
//   }

//   // Common check-out logic: calls the API, then stops the timer
//   Future<void> _performCheckOut() async {
//     final token = CompanyData.token;
//     final url = Uri.parse('https://api-zmj7dqloiq-uc.a.run.app/api/attendance/check-out');
//     final body = jsonEncode({'empid': userId, 'location': location});

//     if (kDebugMode) {
//       print('[AttendanceScreen] POST $url');
//       print('[AttendanceScreen] body: $body');
//     }

//     _showLoadingDialog('Checking out…');
//     try {
//       final res = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: body,
//       );
//       Navigator.pop(context);

//       if (kDebugMode) {
//         print('[AttendanceScreen] check-out statusCode: ${res.statusCode}');
//         print('[AttendanceScreen] check-out response: ${res.body}');
//       }

//       if (res.statusCode == 200) {
//         _stopWorkTimer();
//       } else {
//         final msg =
//             (jsonDecode(res.body)['error'] ?? jsonDecode(res.body)['message'])
//                 .toString();
//         _showErrorDialog(msg);
//       }
//     } catch (e) {
//       Navigator.pop(context);
//       _showErrorDialog('Network error: $e');
//     }
//   }

//   // Start work timer after check-in (00:00:00)
//   void _startWorkTimer() {
//     setState(() {
//       isTimerRunning = true;
//       totalSeconds = 0;
//       hours = "00";
//       minutes = "00";
//       seconds = "00";
//     });

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) return;
//       setState(() {
//         totalSeconds++;
//         hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
//         minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
//         seconds = (totalSeconds % 60).toString().padLeft(2, '0');
//       });
//     });
//   }

//   // Stop work timer after check-out
//   void _stopWorkTimer() {
//     _timer?.cancel();
//     setState(() {
//       isTimerRunning = false;
//       isCheckedIn = false;
//       totalSeconds = 0;
//       hours = "00";
//       minutes = "00";
//       seconds = "00";
//     });
//     _showSuccessDialog(
//       'Check-out successful!\nWork duration: ${hours}h ${minutes}m ${seconds}s',
//     );
//   }

//   // Get month name
//   String _getMonthName(int month) {
//     const months = [
//       '',
//       'JAN',
//       'FEB',
//       'MAR',
//       'APR',
//       'MAY',
//       'JUN',
//       'JUL',
//       'AUG',
//       'SEP',
//       'OCT',
//       'NOV',
//       'DEC',
//     ];
//     return months[month];
//   }

//   // Face registration demo logic (unchanged)
//   Future<void> _registerFace() async {
//     try {
//       bool? proceed = await showDialog<bool>(
//         context: context,
//         builder: (c) => AlertDialog(
//           title: const Text('Face Registration'),
//           content: const Text(
//             'This will open your camera to register your face.\n\nDemo mode.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(c, false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(c, true),
//               child: const Text('Proceed'),
//             ),
//           ],
//         ),
//       );
//       if (proceed != true) return;

//       _showLoadingDialog('Opening camera...');
//       await Future.delayed(const Duration(seconds: 2));
//       Navigator.pop(context);

//       _showLoadingDialog('Processing face...');
//       await Future.delayed(const Duration(seconds: 2));
//       Navigator.pop(context);

//       setState(() => isFaceRegistered = true);
//       _showSuccessDialog('Face registered!');
//     } catch (e) {
//       Navigator.pop(context);
//       _showErrorDialog('Registration failed.');
//     }
//   }

//   // Face detection demo logic (unchanged)
//   Future<void> _faceDetectionCheckIn() async {
//     try {
//       bool? proceed = await showDialog<bool>(
//         context: context,
//         builder: (c) => AlertDialog(
//           title: const Text('Face Detection'),
//           content: const Text(
//             'This will open your camera for detection.\n\nDemo mode.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(c, false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(c, true),
//               child: const Text('Proceed'),
//             ),
//           ],
//         ),
//       );
//       if (proceed != true) return;

//       _showLoadingDialog('Opening camera...');
//       await Future.delayed(const Duration(seconds: 2));
//       Navigator.pop(context);

//       _showLoadingDialog('Detecting face...');
//       await Future.delayed(const Duration(seconds: 2));
//       Navigator.pop(context);

//       await _performCheckIn('face_detection');
//     } catch (e) {
//       Navigator.pop(context);
//       _showErrorDialog('Detection failed.');
//     }
//   }

//   // Check-out confirmation dialog
//   void _confirmCheckOut() {
//     showDialog(
//       context: context,
//       builder: (c) => AlertDialog(
//         title: const Text('Check Out'),
//         content: Text(
//           'Are you sure you want to check out?\n'
//           'Work duration: ${hours}h ${minutes}m ${seconds}s',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(c);
//               _performCheckOut();
//             },
//             child: const Text('Check Out'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Dialog helpers (unchanged)
//   void _showLoadingDialog(String message) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         content: Row(
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(width: 16),
//             Expanded(child: Text(message)),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSuccessDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Success'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: kAppBarColor,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: kTextColor),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Attendance',
//           style: TextStyle(
//             color: kTextColor,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: EdgeInsets.only(
//               left: 16,
//               top: 16,
//               right: 16,
//               bottom: 16 + MediaQuery.of(context).padding.bottom,
//             ),
//             child: Column(
//               children: [
//                 // HEADER
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.1),
//                         spreadRadius: 1,
//                         blurRadius: 5,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         userName,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '$userId | $dept',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.grey,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.calendar_today,
//                             size: 14,
//                             color: Colors.grey[600],
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             '${DateTime.now().day.toString().padLeft(2, '0')} '
//                             '${_getMonthName(DateTime.now().month)} '
//                             '${DateTime.now().year}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // CLOCK ICON
//                 SizedBox(
//                   width: 65,
//                   height: 65,
//                   child: Image.asset(
//                     'assets/images/timer1.png',
//                     fit: BoxFit.contain,
//                   ),
//                 ),

//                 const SizedBox(height: 15),

//                 // TIMER
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _buildTimeBox(hours),
//                     const SizedBox(width: 6),
//                     Text(
//                       ':',
//                       style: TextStyle(
//                         fontSize: 20,
//                         color: kButtonColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     _buildTimeBox(minutes),
//                     const SizedBox(width: 6),
//                     Text(
//                       ':',
//                       style: TextStyle(
//                         fontSize: 20,
//                         color: kButtonColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     _buildTimeBox(seconds),
//                     const SizedBox(width: 12),
//                     Text(
//                       isTimerRunning ? 'Work' : 'Hrs',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: kButtonColor,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 20),

//                 // SHIFT BUTTON (read-only, shows employee's shiftGroup)
//                 GestureDetector(
//                   onTap: null,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: kButtonColor,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       selectedShift,
//                       style: const TextStyle(
//                         color: kTextColor,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 15),

//                 // CHECK-IN / CHECK-OUT FLOW
//                 if (!isCheckedIn) ...[
//                   if (!isFaceRegistered) ...[
//                     Row(
//                       children: [
//                         Expanded(
//                           child: SizedBox(
//                             height: 50,
//                             child: ElevatedButton(
//                               onPressed: _registerFace,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: kButtonColor,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 elevation: 2,
//                               ),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: const [
//                                   Icon(Icons.face, color: kTextColor, size: 14),
//                                   SizedBox(height: 2),
//                                   Text(
//                                     'Register',
//                                     style: TextStyle(
//                                       color: kTextColor,
//                                       fontSize: 9,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: SizedBox(
//                             height: 50,
//                             child: ElevatedButton(
//                               onPressed: () => _performCheckIn('manual'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: kButtonColor,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 elevation: 2,
//                               ),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: const [
//                                   Icon(
//                                     Icons.touch_app,
//                                     color: kTextColor,
//                                     size: 14,
//                                   ),
//                                   SizedBox(height: 2),
//                                   Text(
//                                     'Check in',
//                                     style: TextStyle(
//                                       color: kTextColor,
//                                       fontSize: 9,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ] else ...[
//                     Row(
//                       children: [
//                         Expanded(
//                           child: SizedBox(
//                             height: 35,
//                             child: ElevatedButton(
//                               onPressed: _faceDetectionCheckIn,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: kButtonColor,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 elevation: 2,
//                               ),
//                               child: const Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.face_retouching_natural,
//                                     color: kTextColor,
//                                     size: 14,
//                                   ),
//                                   SizedBox(height: 0),
//                                   Text(
//                                     'Face detect',
//                                     style: TextStyle(
//                                       color: kTextColor,
//                                       fontSize: 9,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: SizedBox(
//                             height: 35,
//                             child: ElevatedButton(
//                               onPressed: () => _performCheckIn('manual'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: kButtonColor,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 elevation: 2,
//                               ),
//                               child: const Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.touch_app,
//                                     color: kTextColor,
//                                     size: 14,
//                                   ),
//                                   SizedBox(height: 0),
//                                   Text(
//                                     'Check in',
//                                     style: TextStyle(
//                                       color: kTextColor,
//                                       fontSize: 9,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ] else ...[
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       onPressed: _confirmCheckOut,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFFF6B6B),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         elevation: 2,
//                       ),
//                       child: const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.logout, color: kTextColor, size: 13),
//                           SizedBox(width: 8),
//                           Text(
//                             'Check Out',
//                             style: TextStyle(
//                               color: kTextColor,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],

//                 const Spacer(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper to build each 2-digit time box
//   Widget _buildTimeBox(String time) {
//     return Container(
//       width: 42,
//       height: 32,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(6),
//         border: isTimerRunning
//             ? Border.all(color: Colors.green, width: 2)
//             : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Center(
//         child: Text(
//           time,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: isTimerRunning ? Colors.green : kButtonColor,
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/models/company_data.dart';

// Color constants
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class AttendanceScreen extends StatefulWidget {
  final String employeeDocId;
  const AttendanceScreen({super.key, required this.employeeDocId});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  // User states
  bool isFaceRegistered = false;
  bool isShiftSelected = false;
  bool isCheckedIn = false;
  bool isTimerRunning = false;

  // Dynamic user info
  String userName = "";
  String userId = "";
  String dept = "";
  String location = "";

  // Shift selection
  String selectedShift = "Shift";
  bool shiftClicked = false;

  // Timer variables
  Timer? _timer;
  int totalSeconds = 0;
  String hours = "00";
  String minutes = "00";
  String seconds = "00";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo(); // also triggers _loadTodayStatus once userId is known
    _checkUserFaceRegistration();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTodayStatus(); // refresh when returning to this page
    }
  }

  /// 1) Load employee profile, then load today's attendance status
  Future<void> _loadUserInfo() async {
    final token = CompanyData.token;
    final url = Uri.parse('https://api-zmj7dqloiq-uc.a.run.app/api/auth/me');

    if (kDebugMode) {
      print('[AttendanceScreen] GET $url');
      print('[AttendanceScreen] Authorization: Bearer $token');
    }

    try {
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (kDebugMode) {
        print('[AttendanceScreen] statusCode: ${res.statusCode}');
        print('[AttendanceScreen] response body: ${res.body}');
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final Map<String, dynamic> profile =
            (data['employeeProfile'] is Map<String, dynamic>)
                ? (data['employeeProfile'] as Map<String, dynamic>)
                : <String, dynamic>{};

        setState(() {
          userName = (data['name'] ?? profile['name'] ?? "") as String;
          userId = (data['empid'] ?? profile['empid'] ?? "") as String;

          // dept & location typically live under employeeProfile
          dept = (profile['dept'] ?? data['dept'] ?? "") as String;
          location = (profile['location'] ?? data['location'] ?? "") as String;

          // shiftGroup typically lives under employeeProfile
          selectedShift =
              (profile['shiftGroup'] ?? data['shiftGroup'] ?? "Shift") as String;

          final hasShift = selectedShift.isNotEmpty && selectedShift != "Shift";
          shiftClicked = hasShift;
          isShiftSelected = hasShift;
        });

        // Once we know empid, fetch today's status
        if (userId.isNotEmpty) {
          await _loadTodayStatus();
        }
      } else {
        setState(() {
          userName = "(unknown)";
          userId = widget.employeeDocId;
          dept = "";
          location = "";
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AttendanceScreen] _loadUserInfo error: $e');
      }
      setState(() {
        userName = "(error)";
        userId = widget.employeeDocId;
        dept = "";
        location = "";
      });
    }
  }

  // Pull today's attendance from server and reflect UI state
  Future<void> _loadTodayStatus() async {
    final token = CompanyData.token;
    if (userId.isEmpty || token.isEmpty) return;

    final url = Uri.parse('https://api-zmj7dqloiq-uc.a.run.app/api/attendance/live');

    try {
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (kDebugMode) {
        print('[AttendanceScreen] /attendance/live status: ${res.statusCode}');
        if (res.statusCode == 200) print('[AttendanceScreen] live body: ${res.body}');
      }

      if (res.statusCode != 200) return;

      final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      final me = list.firstWhere(
        (e) => (e['empid']?.toString() ?? '') == userId,
        orElse: () => const {},
      );

      final checkIn = (me['checkIn']) as String?;
      final checkOut = (me['checkOut']) as String?;

      if (checkIn != null && (checkOut == null || checkOut.isEmpty)) {
        // Already checked-in and not checked-out -> show Checkout
        _applyCheckedInFromServer(checkIn);
      } else {
        // Not currently checked-in
        _resetTimerAndState();
      }
    } catch (e) {
      if (kDebugMode) print('[AttendanceScreen] _loadTodayStatus error: $e');
    }
  }

  // Parse HH:mm:ss and start timer from elapsed time today
  void _applyCheckedInFromServer(String hhmmss) {
    try {
      final now = DateTime.now();
      final parts = hhmmss.split(':').map((s) => int.tryParse(s) ?? 0).toList();
      final inDT = DateTime(now.year, now.month, now.day,
          parts.elementAt(0), parts.elementAt(1), parts.elementAt(2));
      final diff = now.difference(inDT).inSeconds;
      final startSeconds = diff > 0 ? diff : 0;

      _timer?.cancel();
      setState(() {
        isCheckedIn = true;
        isTimerRunning = true;
        totalSeconds = startSeconds;
        hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
        minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
        seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          totalSeconds++;
          hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
          minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
          seconds = (totalSeconds % 60).toString().padLeft(2, '0');
        });
      });
    } catch (_) {
      // Fallback: just mark as checked-in and start fresh timer
      _startWorkTimer();
      setState(() => isCheckedIn = true);
    }
  }

  void _resetTimerAndState() {
    _timer?.cancel();
    setState(() {
      isCheckedIn = false;
      isTimerRunning = false;
      totalSeconds = 0;
      hours = "00";
      minutes = "00";
      seconds = "00";
    });
  }

  // Check if user face is already registered
  Future<void> _checkUserFaceRegistration() async {
    setState(() {
      isFaceRegistered = false;
    });
  }

  // Common check-in logic: calls the API, then starts the timer
  Future<void> _performCheckIn(String type) async {
    final token = CompanyData.token;
    final url = Uri.parse('https://api-zmj7dqloiq-uc.a.run.app/api/attendance/check-in');
    final body = jsonEncode({'empid': userId, 'name': userName, 'location': location});

    if (kDebugMode) {
      print('[AttendanceScreen] POST $url');
      print('[AttendanceScreen] body: $body');
    }

    _showLoadingDialog('Checking in…');
    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
      Navigator.pop(context); // dismiss loading

      if (kDebugMode) {
        print('[AttendanceScreen] check-in statusCode: ${res.statusCode}');
        print('[AttendanceScreen] check-in response: ${res.body}');
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Treat both fresh and "ALREADY_CHECKED_IN" as success -> show Checkout
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          if ((data['code'] ?? '') == 'ALREADY_CHECKED_IN') {
            final rec = (data['record'] ?? {}) as Map<String, dynamic>;
            final ci = (rec['checkIn'] ?? '') as String;
            if (ci.isNotEmpty) {
              _applyCheckedInFromServer(ci);
            } else {
              setState(() => isCheckedIn = true);
              _startWorkTimer();
            }
          } else {
            setState(() => isCheckedIn = true);
            _startWorkTimer();
          }
        } catch (_) {
          setState(() => isCheckedIn = true);
          _startWorkTimer();
        }
        _showSuccessDialog('Check-in successful!');
      } else {
        final msg =
            (jsonDecode(res.body)['error'] ?? jsonDecode(res.body)['message'])
                .toString();
        _showErrorDialog(msg);
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Network error: $e');
    }
  }

  // Common check-out logic: calls the API, then stops the timer
  Future<void> _performCheckOut() async {
    final token = CompanyData.token;
    final url = Uri.parse('https://api-zmj7dqloiq-uc.a.run.app/api/attendance/check-out');
    final body = jsonEncode({'empid': userId, 'location': location});

    if (kDebugMode) {
      print('[AttendanceScreen] POST $url');
      print('[AttendanceScreen] body: $body');
    }

    _showLoadingDialog('Checking out…');
    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
      Navigator.pop(context);

      if (kDebugMode) {
        print('[AttendanceScreen] check-out statusCode: ${res.statusCode}');
        print('[AttendanceScreen] check-out response: ${res.body}');
      }

      if (res.statusCode == 200) {
        _stopWorkTimer();
      } else {
        final msg =
            (jsonDecode(res.body)['error'] ?? jsonDecode(res.body)['message'])
                .toString();
        _showErrorDialog(msg);
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Network error: $e');
    }
  }

  // Start work timer from zero (fresh check-in)
  void _startWorkTimer() {
    _timer?.cancel();
    setState(() {
      isTimerRunning = true;
      totalSeconds = 0;
      hours = "00";
      minutes = "00";
      seconds = "00";
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        totalSeconds++;
        hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
        minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
        seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      });
    });
  }

  // Stop work timer after check-out
  void _stopWorkTimer() {
    final h = hours, m = minutes, s = seconds;
    _resetTimerAndState();
    _showSuccessDialog('Check-out successful!\nWork duration: ${h}h ${m}m ${s}s');
  }

  // Get month name
  String _getMonthName(int month) {
    const months = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month];
  }

  // Face registration demo logic (unchanged)
  Future<void> _registerFace() async {
    try {
      bool? proceed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Face Registration'),
          content: const Text(
            'This will open your camera to register your face.\n\nDemo mode.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      if (proceed != true) return;

      _showLoadingDialog('Opening camera...');
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);

      _showLoadingDialog('Processing face...');
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);

      setState(() => isFaceRegistered = true);
      _showSuccessDialog('Face registered!');
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Registration failed.');
    }
  }

  // Face detection demo logic (unchanged)
  Future<void> _faceDetectionCheckIn() async {
    try {
      bool? proceed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Face Detection'),
          content: const Text(
            'This will open your camera for detection.\n\nDemo mode.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      if (proceed != true) return;

      _showLoadingDialog('Opening camera...');
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);

      _showLoadingDialog('Detecting face...');
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);

      await _performCheckIn('face_detection');
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Detection failed.');
    }
  }

  // Check-out confirmation dialog
  void _confirmCheckOut() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Check Out'),
        content: Text(
          'Are you sure you want to check out?\n'
          'Work duration: ${hours}h ${minutes}m ${seconds}s',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _performCheckOut();
            },
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
  }

  // Dialog helpers (unchanged)
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: kTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              top: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$userId | $dept',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${DateTime.now().day.toString().padLeft(2, '0')} '
                            '${_getMonthName(DateTime.now().month)} '
                            '${DateTime.now().year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CLOCK ICON
                SizedBox(
                  width: 65,
                  height: 65,
                  child: Image.asset(
                    'assets/images/timer1.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 15),

                // TIMER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeBox(hours),
                    const SizedBox(width: 6),
                    Text(
                      ':',
                      style: TextStyle(
                        fontSize: 20,
                        color: kButtonColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildTimeBox(minutes),
                    const SizedBox(width: 6),
                    Text(
                      ':',
                      style: TextStyle(
                        fontSize: 20,
                        color: kButtonColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildTimeBox(seconds),
                    const SizedBox(width: 12),
                    Text(
                      isTimerRunning ? 'Work' : 'Hrs',
                      style: TextStyle(
                        fontSize: 14,
                        color: kButtonColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // SHIFT BUTTON (read-only)
                GestureDetector(
                  onTap: null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kButtonColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedShift,
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // CHECK-IN / CHECK-OUT FLOW (UI untouched)
                if (!isCheckedIn) ...[
                  if (!isFaceRegistered) ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _registerFace,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.face, color: kTextColor, size: 14),
                                  SizedBox(height: 2),
                                  Text(
                                    'Register',
                                    style: TextStyle(
                                      color: kTextColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _performCheckIn('manual'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.touch_app,
                                    color: kTextColor,
                                    size: 14,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Check in',
                                    style: TextStyle(
                                      color: kTextColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 35,
                            child: ElevatedButton(
                              onPressed: _faceDetectionCheckIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.face_retouching_natural,
                                    color: kTextColor,
                                    size: 14,
                                  ),
                                  SizedBox(height: 0),
                                  Text(
                                    'Face detect',
                                    style: TextStyle(
                                      color: kTextColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 35,
                            child: ElevatedButton(
                              onPressed: () => _performCheckIn('manual'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    color: kTextColor,
                                    size: 14,
                                  ),
                                  SizedBox(height: 0),
                                  Text(
                                    'Check in',
                                    style: TextStyle(
                                      color: kTextColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmCheckOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: kTextColor, size: 13),
                          SizedBox(width: 8),
                          Text(
                            'Check Out',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build each 2-digit time box
  Widget _buildTimeBox(String time) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: isTimerRunning
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isTimerRunning ? Colors.green : kButtonColor,
          ),
        ),
      ),
    );
  }
}
