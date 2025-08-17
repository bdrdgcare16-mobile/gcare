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
//     final url = Uri.parse('http://localhost:3000/api/auth/me');

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
//         setState(() {
//           userName = data['name'] ?? "";
//           userId = data['empid'] ?? "";
//           dept = data['dept'] ?? "";
//           location = data['location'] ?? "";
//           // Pre-select the employee’s shiftGroup
//           selectedShift = data['shiftGroup'] ?? "Shift";
//           shiftClicked = true;
//           isShiftSelected = true;
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
//     final url = Uri.parse('http://localhost:3000/api/attendance/check-in');
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
//     final url = Uri.parse('http://localhost:3000/api/attendance/check-out');
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
//                 Container(
//                   width: 65,
//                   height: 65,
//                   decoration: BoxDecoration(
//                     color: kButtonColor.withOpacity(0.2),
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: kButtonColor.withOpacity(0.3),
//                       width: 2,
//                     ),
//                   ),
//                   child: Icon(
//                     isTimerRunning ? Icons.timer : Icons.access_time,
//                     size: 32,
//                     color: kButtonColor,
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

//                 // SHIFT BUTTON
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
import 'package:serv_app/models/company_data.dart'; // where you kept the token

// Color constants
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class AttendanceScreen extends StatefulWidget {
  /// Pass the Firestore document ID of the logged-in employee here
  final String employeeDocId;

  const AttendanceScreen({super.key, required this.employeeDocId});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
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
    _loadUserInfo();
    _checkUserFaceRegistration();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 1) Load the employee’s profile from your backend
  Future<void> _loadUserInfo() async {
    final token = CompanyData.token;
    final url = Uri.parse('http://localhost:3000/api/auth/me');

    if (kDebugMode) {
      print('[AttendanceScreen] GET $url');
      print('[AttendanceScreen] Authorization: Bearer $token');
    }

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        print('[AttendanceScreen] statusCode: ${res.statusCode}');
        print('[AttendanceScreen] response body: ${res.body}');
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        // 🔧 FIX: read nested fields from employeeProfile if present
        final Map<String, dynamic> profile =
            (data['employeeProfile'] is Map<String, dynamic>)
                ? (data['employeeProfile'] as Map<String, dynamic>)
                : <String, dynamic>{};

        setState(() {
          userName = (data['name'] ?? profile['name'] ?? "") as String;
          userId   = (data['empid'] ?? profile['empid'] ?? "") as String;

          // dept & location typically live under employeeProfile
          dept     = (profile['dept'] ?? data['dept'] ?? "") as String;
          location = (profile['location'] ?? data['location'] ?? "") as String;

          // shiftGroup typically lives under employeeProfile
          selectedShift =
              (profile['shiftGroup'] ?? data['shiftGroup'] ?? "Shift") as String;

          // If we resolved a shift name, mark it selected so the button shows it
          final hasShift = selectedShift.isNotEmpty && selectedShift != "Shift";
          shiftClicked = hasShift;
          isShiftSelected = hasShift;
        });
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

  // Check if user face is already registered
  Future<void> _checkUserFaceRegistration() async {
    setState(() {
      isFaceRegistered = false;
    });
  }

  // Common check-in logic: calls the API, then starts the timer
  Future<void> _performCheckIn(String type) async {
    final token = CompanyData.token;
    final url = Uri.parse('http://localhost:3000/api/attendance/check-in');
    final body = jsonEncode({
      'empid': userId,
      'name': userName,
      'location': location,
    });

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
        setState(() => isCheckedIn = true);
        _startWorkTimer();
        _showSuccessDialog('Check-in successful! Timer started.');
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
    final url = Uri.parse('http://localhost:3000/api/attendance/check-out');
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

  // Start work timer after check-in (00:00:00)
  void _startWorkTimer() {
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
    _timer?.cancel();
    setState(() {
      isTimerRunning = false;
      isCheckedIn = false;
      totalSeconds = 0;
      hours = "00";
      minutes = "00";
      seconds = "00";
    });
    _showSuccessDialog(
      'Check-out successful!\nWork duration: ${hours}h ${minutes}m ${seconds}s',
    );
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
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: kButtonColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kButtonColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isTimerRunning ? Icons.timer : Icons.access_time,
                    size: 32,
                    color: kButtonColor,
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

                // SHIFT BUTTON (read-only, shows employee's shiftGroup)
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

                // CHECK-IN / CHECK-OUT FLOW
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
