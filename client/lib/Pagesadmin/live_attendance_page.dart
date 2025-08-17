// // // // import 'package:flutter/material.dart';
// // // // import 'package:intl/intl.dart';
// // // // import 'employee_list_page.dart';
// // // // import 'company_setup_page.dart';

// // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // const Color kButtonColor = Color(0xFF655193);
// // // // const Color kTextColor = Colors.white;
// // // // const Color kPopupColor = Color(0xFFEDE7F6);

// // // // class LiveAttendancePage extends StatelessWidget {
// // // //   final CompanyProfile companyProfile;

// // // //   LiveAttendancePage({super.key, required this.companyProfile});

// // // //   // Dummy employees
// // // //   final List<String> checkInEmployees = [
// // // //     "John Smith - 9:00 AM",
// // // //     "Priya R - 9:10 AM",
// // // //     "David R - 8:55 AM",
// // // //   ];

// // // //   final List<String> checkOutEmployees = [
// // // //     "Sarah J - 6:00 PM",
// // // //     "Kumar P - 5:45 PM",
// // // //   ];

// // // //   final List<String> presentEmployees = [
// // // //     "John Smith",
// // // //     "Sarah J",
// // // //     "Kumar P",
// // // //   ];

// // // //   final List<String> absentEmployees = ["Ravi K", "Deepa M"];

// // // //   final List<String> onLeaveEmployees = ["Meena S"];

// // // //   final List<String> halfDayEmployees = ["Lakshmi V"];
// // // //   final List<String> lateCheckInEmployees = ["Naveen B"];
// // // //   final List<String> earlyCheckoutEmployees = ["Ramya R"];
// // // //   final List<String> waitingApprovalEmployees = ["Suresh M"];
// // // //   final List<String> fieldAttendanceEmployees = ["Gopi A"];

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     String currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
// // // //     String currentTime = DateFormat('hh:mm a').format(DateTime.now());

// // // //     return Scaffold(
// // // //       backgroundColor: kPrimaryBackgroundTop,
// // // //       resizeToAvoidBottomInset: false,
// // // //       body: SafeArea(
// // // //         child: SingleChildScrollView(
// // // //           padding: const EdgeInsets.only(bottom: 20),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               _buildHeader(context),
// // // //               const SizedBox(height: 16),
// // // //               Padding(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // //                 child: Row(
// // // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                   children: [
// // // //                     Text("Today - $currentDate", style: const TextStyle(fontWeight: FontWeight.w500)),
// // // //                     Text(currentTime, style: const TextStyle(color: Colors.grey)),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(height: 12),
// // // //               Padding(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 16),
// // // //                 child: Row(
// // // //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // //                   children: [
// // // //                     _popupButton(context, "Check-in", checkInEmployees),
// // // //                     _popupButton(context, "Check-out", checkOutEmployees),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(height: 12),
// // // //               Padding(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // //                 child: Row(
// // // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                   children: [
// // // //                     _statusBox(context, "Present", presentEmployees, Colors.green),
// // // //                     _statusBox(context, "Absent", absentEmployees, Colors.red),
// // // //                     _statusBox(context, "On Leave", onLeaveEmployees, Colors.orange),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(height: 20),
// // // //               const Center(
// // // //                 child: Text("Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // // //               ),
// // // //               const SizedBox(height: 10),
// // // //               Padding(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 16),
// // // //                 child: GridView.count(
// // // //                   crossAxisCount: 3,
// // // //                   shrinkWrap: true,
// // // //                   physics: const NeverScrollableScrollPhysics(),
// // // //                   crossAxisSpacing: 10,
// // // //                   mainAxisSpacing: 10,
// // // //                   childAspectRatio: 1,
// // // //                   children: [
// // // //                     _activityCard(context, "Half Day", halfDayEmployees),
// // // //                     _activityCard(context, "Late Check-in", lateCheckInEmployees),
// // // //                     _activityCard(context, "Early Check-out", earlyCheckoutEmployees),
// // // //                     _activityCard(context, "Waiting for Approvals", waitingApprovalEmployees, fontSize: 10),
// // // //                     _activityCard(context, "Field Attendance", fieldAttendanceEmployees),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildHeader(BuildContext context) {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
// // // //       decoration: const BoxDecoration(
// // // //         color: kAppBarColor,
// // // //         borderRadius: BorderRadius.only(
// // // //           bottomLeft: Radius.circular(40),
// // // //           bottomRight: Radius.circular(40),
// // // //         ),
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           const Text("Live Attendance",
// // // //               style: TextStyle(color: kTextColor, fontSize: 22, fontWeight: FontWeight.bold)),
// // // //           const SizedBox(height: 8),
// // // //           Text(companyProfile.name, style: const TextStyle(color: kTextColor)),
// // // //           Text("ID | ${companyProfile.adminName}", style: const TextStyle(color: Colors.white70)),
// // // //           const SizedBox(height: 16),
// // // //           Row(
// // // //             mainAxisAlignment: MainAxisAlignment.end,
// // // //             children: [
// // // //               const CircleAvatar(
// // // //                 backgroundColor: Colors.white,
// // // //                 child: Icon(Icons.map, color: Colors.green),
// // // //               ),
// // // //               const SizedBox(width: 16),
// // // //               GestureDetector(
// // // //                 onTap: () {
// // // //                   Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(builder: (_) => EmployeeListPage()),
// // // //                   );
// // // //                 },
// // // //                 child: const CircleAvatar(
// // // //                   backgroundColor: Colors.white,
// // // //                   child: Icon(Icons.people, color: Colors.blue),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _popupButton(BuildContext context, String title, List<String> employees) {
// // // //     return ElevatedButton(
// // // //       onPressed: () => _showPopup(context, title, employees),
// // // //       style: ElevatedButton.styleFrom(
// // // //         backgroundColor: kButtonColor,
// // // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// // // //       ),
// // // //       child: Text(title, style: const TextStyle(color: kTextColor)),
// // // //     );
// // // //   }

// // // //   Widget _statusBox(BuildContext context, String title, List<String> employees, Color color) {
// // // //     return Expanded(
// // // //       child: GestureDetector(
// // // //         onTap: () => _showPopup(context, title, employees),
// // // //         child: Container(
// // // //           margin: const EdgeInsets.symmetric(horizontal: 4),
// // // //           padding: const EdgeInsets.all(10),
// // // //           decoration: BoxDecoration(
// // // //             color: color.withOpacity(0.1),
// // // //             border: Border.all(color: color),
// // // //             borderRadius: BorderRadius.circular(10),
// // // //           ),
// // // //           child: Column(
// // // //             children: [
// // // //               Text("${employees.length}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
// // // //               const SizedBox(height: 4),
// // // //               Text(title, style: TextStyle(color: color)),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _activityCard(BuildContext context, String title, List<String> employees, {double fontSize = 12}) {
// // // //     return GestureDetector(
// // // //       onTap: () => _showPopup(context, title, employees),
// // // //       child: Container(
// // // //         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
// // // //         decoration: BoxDecoration(
// // // //           color: kPrimaryBackgroundBottom.withOpacity(0.1),
// // // //           border: Border.all(color: kAppBarColor.withOpacity(0.3)),
// // // //           borderRadius: BorderRadius.circular(12),
// // // //         ),
// // // //         child: Column(
// // // //           mainAxisAlignment: MainAxisAlignment.center,
// // // //           children: [
// // // //             Text("${employees.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // // //             const SizedBox(height: 4),
// // // //             Text(title, style: TextStyle(fontSize: fontSize), textAlign: TextAlign.center),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   void _showPopup(BuildContext context, String title, List<String> employees) {
// // // //     showDialog(
// // // //       context: context,
// // // //       builder: (_) => AlertDialog(
// // // //         backgroundColor: kPopupColor,
// // // //         title: Text(
// // // //           "$title - ${employees.length} Employees",
// // // //           style: const TextStyle(fontWeight: FontWeight.bold, color: kAppBarColor),
// // // //         ),
// // // //         content: SizedBox(
// // // //           width: double.maxFinite,
// // // //           height: 300,
// // // //           child: ListView.builder(
// // // //             itemCount: employees.length,
// // // //             itemBuilder: (_, index) => Padding(
// // // //               padding: const EdgeInsets.symmetric(vertical: 6),
// // // //               child: Text(
// // // //                 employees[index],
// // // //                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //         actions: [
// // // //           TextButton(
// // // //             onPressed: () => Navigator.pop(context),
// // // //             child: const Text("Close", style: TextStyle(color: kAppBarColor)),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // // import 'package:flutter/material.dart';
// // // // import 'package:intl/intl.dart';
// // // // import 'company_setup_page.dart';
// // // // import 'employee_list_page.dart';

// // // // class LiveAttendancePage extends StatelessWidget {
// // // //   final CompanyProfile companyProfile;

// // // //   const LiveAttendancePage({super.key, required this.companyProfile});

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     String currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

// // // //     final presentCount = 46;
// // // //     final absentCount = 8;
// // // //     final onLeaveCount = 2;

// // // //     final checkInCount = 32;
// // // //     final checkOutCount = 18;

// // // //     final halfDay = 2;
// // // //     final lateCheckIn = 0;
// // // //     final earlyCheckOut = 0;
// // // //     final waitingForApprovals = 1;
// // // //     final fieldAttendance = 3;

// // // //     return Scaffold(
// // // //       backgroundColor: Colors.white,
// // // //       resizeToAvoidBottomInset: false,
// // // //       body: SafeArea(
// // // //         child: SingleChildScrollView(
// // // //           padding: const EdgeInsets.only(bottom: 20),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               Container(
// // // //                 width: double.infinity,
// // // //                 padding: const EdgeInsets.only(
// // // //                   top: 40,
// // // //                   bottom: 16,
// // // //                   left: 16,
// // // //                   right: 16,
// // // //                 ),
// // // //                 decoration: const BoxDecoration(
// // // //                   color: Color(0xFF8C6EAF),
// // // //                   borderRadius: BorderRadius.only(
// // // //                     bottomLeft: Radius.circular(40),
// // // //                     bottomRight: Radius.circular(40),
// // // //                   ),
// // // //                 ),
// // // //                 child: Column(
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   children: [
// // // //                     const Text(
// // // //                       "Live Attendance",
// // // //                       style: TextStyle(
// // // //                         color: Colors.white,
// // // //                         fontSize: 22,
// // // //                         fontWeight: FontWeight.bold,
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(height: 8),
// // // //                     Text(
// // // //                       companyProfile.name,
// // // //                       style: const TextStyle(color: Colors.white),
// // // //                     ),
// // // //                     Text(
// // // //                       "ID | ${companyProfile.adminName}",
// // // //                       style: const TextStyle(color: Colors.white70),
// // // //                     ),
// // // //                     const SizedBox(height: 16),
// // // //                     Row(
// // // //                       mainAxisAlignment: MainAxisAlignment.end,
// // // //                       children: [
// // // //                         Column(
// // // //                           children: const [
// // // //                             CircleAvatar(
// // // //                               backgroundColor: Colors.white,
// // // //                               child: Icon(Icons.map, color: Colors.green),
// // // //                             ),
// // // //                             SizedBox(height: 4),
// // // //                             Text("Map", style: TextStyle(color: Colors.white, fontSize: 12)),
// // // //                           ],
// // // //                         ),
// // // //                         const SizedBox(width: 16),
// // // //                         GestureDetector(
// // // //                           onTap: () {
// // // //                             Navigator.push(
// // // //                               context,
// // // //                               MaterialPageRoute(
// // // //                                 builder: (_) => const EmployeeListPage(),
// // // //                               ),
// // // //                             );
// // // //                           },
// // // //                           child: Column(
// // // //                             children: const [
// // // //                               CircleAvatar(
// // // //                                 backgroundColor: Colors.white,
// // // //                                 child: Icon(Icons.people, color: Colors.blue),
// // // //                               ),
// // // //                               SizedBox(height: 4),
// // // //                               Text("Employee List", style: TextStyle(color: Colors.white, fontSize: 12)),
// // // //                             ],
// // // //                           ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),

// // // //               const SizedBox(height: 16),

// // // //               Padding(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // //                 child: Row(
// // // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                   children: [
// // // //                     Text("Today - $currentDate", style: const TextStyle(fontWeight: FontWeight.w500)),

// // // //                   ],
// // // //                 ),
// // // //               ),

// // // //               const SizedBox(height: 12),

// // // //               Padding(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 16),
// // // //                 child: Row(
// // // //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // //                   children: [
// // // //                     ElevatedButton(
// // // //                       onPressed: () {
// // // //                         _showEmployeePopup(context, "Checked-in Employees", checkInCount);
// // // //                       },
// // // //                       style: ElevatedButton.styleFrom(
// // // //                         backgroundColor: const Color(0xFF655193),
// // // //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// // // //                       ),
// // // //                       child: Text("Check-in $checkInCount", style: const TextStyle(color: Colors.white)),
// // // //                     ),
// // // //                     ElevatedButton(
// // // //                       onPressed: () {
// // // //                         _showEmployeePopup(context, "Checked-out Employees", checkOutCount);
// // // //                       },
// // // //                       style: ElevatedButton.styleFrom(
// // // //                         backgroundColor: const Color(0xFF655193),
// // // //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// // // //                       ),
// // // //                       child: Text("Check-out $checkOutCount", style: const TextStyle(color: Colors.white)),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),

// // // //               const SizedBox(height: 12),

// // // //               Padding(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // //                 child: Row(
// // // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                   children: [
// // // //                     _statusBox(context, "Present", presentCount, Colors.green),
// // // //                     _statusBox(context, "Absent", absentCount, Colors.red),
// // // //                     _statusBox(context, "On Leave", onLeaveCount, Colors.orange),
// // // //                   ],
// // // //                 ),
// // // //               ),

// // // //               const SizedBox(height: 20),
// // // //               const Center(
// // // //                 child: Text("Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // // //               ),

// // // //               const SizedBox(height: 10),

// // // //               Padding(
// // // //                 padding: const EdgeInsets.symmetric(horizontal: 16),
// // // //                 child: GridView.count(
// // // //                   crossAxisCount: 3,
// // // //                   shrinkWrap: true,
// // // //                   physics: const NeverScrollableScrollPhysics(),
// // // //                   crossAxisSpacing: 10,
// // // //                   mainAxisSpacing: 10,
// // // //                   childAspectRatio: 1,
// // // //                   children: [
// // // //                     GestureDetector(
// // // //                       onTap: () => _showEmployeePopup(context, "Half Day", halfDay),
// // // //                       child: _activityCard("Half Day", halfDay),
// // // //                     ),
// // // //                     GestureDetector(
// // // //                       onTap: () => _showEmployeePopup(context, "Late Check-in", lateCheckIn),
// // // //                       child: _activityCard("Late Check-in", lateCheckIn),
// // // //                     ),
// // // //                     GestureDetector(
// // // //                       onTap: () => _showEmployeePopup(context, "Early Check-out", earlyCheckOut),
// // // //                       child: _activityCard("Early Check-out", earlyCheckOut),
// // // //                     ),
// // // //                     GestureDetector(
// // // //                       onTap: () => _showEmployeePopup(context, "Waiting for Approvals", waitingForApprovals),
// // // //                       child: _activityCard("Waiting for Approvals", waitingForApprovals, fontSize: 10),
// // // //                     ),
// // // //                     GestureDetector(
// // // //                       onTap: () => _showEmployeePopup(context, "Field Attendance", fieldAttendance),
// // // //                       child: _activityCard("Field Attendance", fieldAttendance),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   void _showEmployeePopup(BuildContext context, String title, int count) {
// // // //     showDialog(
// // // //       context: context,
// // // //       builder: (ctx) => AlertDialog(
// // // //         backgroundColor: const Color(0xFFF3E5F5),
// // // //         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
// // // //         content: SizedBox(
// // // //           width: double.maxFinite,
// // // //           height: 300,
// // // //           child: ListView.builder(
// // // //             itemCount: count,
// // // //             itemBuilder: (ctx, index) {
// // // //               return ListTile(
// // // //                 leading: const CircleAvatar(
// // // //                   backgroundColor: Color(0xFFCE93D8),
// // // //                   child: Icon(Icons.person, color: Colors.white),
// // // //                 ),
// // // //                 title: Text("Employee ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
// // // //                 subtitle: Text("ID: EMP00${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
// // // //               );
// // // //             },
// // // //           ),
// // // //         ),
// // // //         actions: [
// // // //           TextButton(
// // // //             onPressed: () => Navigator.pop(ctx),
// // // //             child: const Text("Close", style: TextStyle(color: Color(0xFF6A1B9A))),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _statusBox(BuildContext context, String title, int count, Color color) {
// // // //     return Expanded(
// // // //       child: GestureDetector(
// // // //         onTap: () => _showEmployeePopup(context, "$title Employees", count),
// // // //         child: Container(
// // // //           margin: const EdgeInsets.symmetric(horizontal: 4),
// // // //           padding: const EdgeInsets.all(10),
// // // //           decoration: BoxDecoration(
// // // //             color: color.withOpacity(0.1),
// // // //             border: Border.all(color: color),
// // // //             borderRadius: BorderRadius.circular(10),
// // // //           ),
// // // //           child: Column(
// // // //             children: [
// // // //               Text(
// // // //                 "$count",
// // // //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
// // // //               ),
// // // //               const SizedBox(height: 4),
// // // //               Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _activityCard(String title, int value, {double fontSize = 12}) {
// // // //     return Container(
// // // //       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
// // // //       decoration: BoxDecoration(
// // // //         color: const Color(0xFFD1C4E9).withOpacity(0.1),
// // // //         border: Border.all(color: const Color(0xFF8C6EAF).withOpacity(0.3)),
// // // //         borderRadius: BorderRadius.circular(12),
// // // //       ),
// // // //       child: Column(
// // // //         mainAxisAlignment: MainAxisAlignment.center,
// // // //         children: [
// // // //           Text("$value", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // // //           const SizedBox(height: 4),
// // // //           Text(title, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // // lib/Pagesadmin/live_attendance_page.dart

// // // // lib/Pagesadmin/live_attendance_page.dart

// // // // lib/Pagesadmin/live_attendance_page.dart

// // // import 'dart:convert';
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:intl/intl.dart';

// // // import 'company_setup_page.dart';
// // // import 'employee_list_page.dart';
// // // import 'package:serv_app/models/company_data.dart'; // for CompanyData.token

// // // // Model for each attendance record returned by /api/attendance/live
// // // class AttendanceRecord {
// // //   final String empid;
// // //   final String name;
// // //   final String status;
// // //   final String? checkIn;
// // //   final String? checkOut;
// // //   final bool late;
// // //   final bool early;
// // //   final int permissionCount;

// // //   AttendanceRecord({
// // //     required this.empid,
// // //     required this.name,
// // //     required this.status,
// // //     this.checkIn,
// // //     this.checkOut,
// // //     required this.late,
// // //     required this.early,
// // //     required this.permissionCount,
// // //   });

// // //   factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
// // //     return AttendanceRecord(
// // //       empid: json['empid'] as String,
// // //       name: json['name'] as String,
// // //       status: json['status'] as String,
// // //       checkIn: json['checkIn'] as String?,
// // //       checkOut: json['checkOut'] as String?,
// // //       late: (json['late'] as bool?) ?? false,
// // //       early: (json['early'] as bool?) ?? false,
// // //       permissionCount: json['permissionCount'] as int,
// // //     );
// // //   }
// // // }

// // // class LiveAttendancePage extends StatefulWidget {
// // //   final CompanyProfile companyProfile;

// // //   const LiveAttendancePage({super.key, required this.companyProfile});

// // //   @override
// // //   _LiveAttendancePageState createState() => _LiveAttendancePageState();
// // // }

// // // class _LiveAttendancePageState extends State<LiveAttendancePage> {
// // //   bool _isLoading = true;
// // //   String? _error;
// // //   List<AttendanceRecord> _records = [];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchLiveAttendance();
// // //   }

// // //   Future<void> _fetchLiveAttendance() async {
// // //     final url = Uri.parse('http://localhost:3000/api/attendance/live');
// // //     try {
// // //       final resp = await http.get(
// // //         url,
// // //         headers: {
// // //           'Content-Type': 'application/json',
// // //           'Authorization': 'Bearer ${CompanyData.token}',
// // //         },
// // //       );
// // //       if (resp.statusCode != 200) {
// // //         setState(() {
// // //           _error = 'Error ${resp.statusCode}: ${resp.body}';
// // //           _isLoading = false;
// // //         });
// // //         return;
// // //       }

// // //       final List<dynamic> jsonList = jsonDecode(resp.body);
// // //       final records = jsonList
// // //           .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
// // //           .toList();

// // //       setState(() {
// // //         _records = records;
// // //         _isLoading = false;
// // //       });
// // //     } catch (e) {
// // //       setState(() {
// // //         _error = 'Failed to load: $e';
// // //         _isLoading = false;
// // //       });
// // //     }
// // //   }

// // //   // Helpers to compute counts, using case-insensitive matching:
// // //   bool _isStatus(AttendanceRecord r, String s) =>
// // //       r.status.toLowerCase() == s.toLowerCase();

// // //   int get presentCount => _records.where((r) => _isStatus(r, 'present')).length;
// // //   int get absentCount => _records.where((r) => _isStatus(r, 'absent')).length;
// // //   int get onLeaveCount => _records.where((r) => _isStatus(r, 'leave')).length;
// // //   int get checkInCount => _records.where((r) => r.checkIn != null).length;
// // //   int get checkOutCount => _records.where((r) => r.checkOut != null).length;
// // //   int get halfDayCount =>
// // //       _records.where((r) => r.checkIn != null && r.checkOut == null).length;
// // //   int get lateCheckInCount => _records.where((r) => r.late).length;
// // //   int get earlyCheckOutCount => _records.where((r) => r.early).length;
// // //   int get waitingApprovalCount =>
// // //       _records.fold(0, (sum, r) => sum + r.permissionCount);
// // //   int get fieldAttendanceCount =>
// // //       _records.where((r) => _isStatus(r, 'fieldattendance')).length;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     String currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

// // //     return Scaffold(
// // //       backgroundColor: Colors.white,
// // //       body: SafeArea(
// // //         child: _isLoading
// // //             ? const Center(child: CircularProgressIndicator())
// // //             : _error != null
// // //             ? Center(child: Text(_error!))
// // //             : SingleChildScrollView(
// // //                 padding: const EdgeInsets.only(bottom: 20),
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     _buildHeader(),
// // //                     const SizedBox(height: 16),
// // //                     _buildDateRow(currentDate),
// // //                     const SizedBox(height: 12),
// // //                     _buildCheckButtons(),
// // //                     const SizedBox(height: 12),
// // //                     _buildStatusBoxes(),
// // //                     const SizedBox(height: 20),
// // //                     const Center(
// // //                       child: Text(
// // //                         "Activity",
// // //                         style: TextStyle(
// // //                           fontSize: 18,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 10),
// // //                     _buildActivityGrid(),
// // //                   ],
// // //                 ),
// // //               ),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildHeader() {
// // //     return Container(
// // //       width: double.infinity,
// // //       padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
// // //       decoration: const BoxDecoration(
// // //         color: Color(0xFF8C6EAF),
// // //         borderRadius: BorderRadius.only(
// // //           bottomLeft: Radius.circular(40),
// // //           bottomRight: Radius.circular(40),
// // //         ),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           const Text(
// // //             "Live Attendance",
// // //             style: TextStyle(
// // //               color: Colors.white,
// // //               fontSize: 22,
// // //               fontWeight: FontWeight.bold,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 8),
// // //           Text(
// // //             widget.companyProfile.name,
// // //             style: const TextStyle(color: Colors.white),
// // //           ),
// // //           Text(
// // //             "ID | ${widget.companyProfile.adminName}",
// // //             style: const TextStyle(color: Colors.white70),
// // //           ),
// // //           const SizedBox(height: 16),
// // //           Row(
// // //             mainAxisAlignment: MainAxisAlignment.end,
// // //             children: [
// // //               Column(
// // //                 children: const [
// // //                   CircleAvatar(
// // //                     backgroundColor: Colors.white,
// // //                     child: Icon(Icons.map, color: Colors.green),
// // //                   ),
// // //                   SizedBox(height: 4),
// // //                   Text(
// // //                     "Map",
// // //                     style: TextStyle(color: Colors.white, fontSize: 12),
// // //                   ),
// // //                 ],
// // //               ),
// // //               const SizedBox(width: 16),
// // //               GestureDetector(
// // //                 onTap: () => Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (_) => const EmployeeListPage()),
// // //                 ),
// // //                 child: Column(
// // //                   children: const [
// // //                     CircleAvatar(
// // //                       backgroundColor: Colors.white,
// // //                       child: Icon(Icons.people, color: Colors.blue),
// // //                     ),
// // //                     SizedBox(height: 4),
// // //                     Text(
// // //                       "Employee List",
// // //                       style: TextStyle(color: Colors.white, fontSize: 12),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildDateRow(String currentDate) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // //       child: Text(
// // //         "Today - $currentDate",
// // //         style: const TextStyle(fontWeight: FontWeight.w500),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildCheckButtons() {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // //         children: [
// // //           ElevatedButton(
// // //             onPressed: () => _showEmployeePopup(
// // //               "Checked-in Employees",
// // //               _records.where((r) => r.checkIn != null).toList(),
// // //             ),
// // //             style: ElevatedButton.styleFrom(
// // //               backgroundColor: const Color(0xFF655193),
// // //               shape: RoundedRectangleBorder(
// // //                 borderRadius: BorderRadius.circular(20),
// // //               ),
// // //             ),
// // //             child: Text(
// // //               "Check-in $checkInCount",
// // //               style: const TextStyle(color: Colors.white),
// // //             ),
// // //           ),
// // //           ElevatedButton(
// // //             onPressed: () => _showEmployeePopup(
// // //               "Checked-out Employees",
// // //               _records.where((r) => r.checkOut != null).toList(),
// // //             ),
// // //             style: ElevatedButton.styleFrom(
// // //               backgroundColor: const Color(0xFF655193),
// // //               shape: RoundedRectangleBorder(
// // //                 borderRadius: BorderRadius.circular(20),
// // //               ),
// // //             ),
// // //             child: Text(
// // //               "Check-out $checkOutCount",
// // //               style: const TextStyle(color: Colors.white),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildStatusBoxes() {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //         children: [
// // //           _statusBox(
// // //             "Present",
// // //             presentCount,
// // //             Colors.green,
// // //             _records.where((r) => _isStatus(r, 'present')).toList(),
// // //           ),
// // //           _statusBox(
// // //             "Absent",
// // //             absentCount,
// // //             Colors.red,
// // //             _records.where((r) => _isStatus(r, 'absent')).toList(),
// // //           ),
// // //           _statusBox(
// // //             "On Leave",
// // //             onLeaveCount,
// // //             Colors.orange,
// // //             _records.where((r) => _isStatus(r, 'leave')).toList(),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildActivityGrid() {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // //       child: GridView.count(
// // //         crossAxisCount: 3,
// // //         shrinkWrap: true,
// // //         physics: const NeverScrollableScrollPhysics(),
// // //         crossAxisSpacing: 10,
// // //         mainAxisSpacing: 10,
// // //         children: [
// // //           _activityCard(
// // //             "Half Day",
// // //             halfDayCount,
// // //             _records
// // //                 .where((r) => r.checkIn != null && r.checkOut == null)
// // //                 .toList(),
// // //           ),
// // //           _activityCard(
// // //             "Late Check-in",
// // //             lateCheckInCount,
// // //             _records.where((r) => r.late).toList(),
// // //           ),
// // //           _activityCard(
// // //             "Early Check-out",
// // //             earlyCheckOutCount,
// // //             _records.where((r) => r.early).toList(),
// // //           ),
// // //           _activityCard(
// // //             "Waiting for Approvals",
// // //             waitingApprovalCount,
// // //             _records.where((r) => r.permissionCount > 0).toList(),
// // //             fontSize: 10,
// // //           ),
// // //           _activityCard(
// // //             "Field Attendance",
// // //             fieldAttendanceCount,
// // //             _records.where((r) => _isStatus(r, 'fieldattendance')).toList(),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   void _showEmployeePopup(String title, List<AttendanceRecord> list) {
// // //     showDialog(
// // //       context: context,
// // //       builder: (ctx) => AlertDialog(
// // //         backgroundColor: const Color(0xFFF3E5F5),
// // //         title: Text(
// // //           title,
// // //           style: const TextStyle(
// // //             fontWeight: FontWeight.bold,
// // //             color: Color(0xFF6A1B9A),
// // //           ),
// // //         ),
// // //         content: SizedBox(
// // //           width: double.maxFinite,
// // //           height: 300,
// // //           child: ListView.builder(
// // //             itemCount: list.length,
// // //             itemBuilder: (ctx, i) {
// // //               final r = list[i];
// // //               return ListTile(
// // //                 leading: const CircleAvatar(
// // //                   backgroundColor: Color(0xFFCE93D8),
// // //                   child: Icon(Icons.person, color: Colors.white),
// // //                 ),
// // //                 title: Text(
// // //                   r.name,
// // //                   style: const TextStyle(fontWeight: FontWeight.bold),
// // //                 ),
// // //                 subtitle: Text(
// // //                   "ID: ${r.empid}",
// // //                   style: const TextStyle(fontWeight: FontWeight.bold),
// // //                 ),
// // //               );
// // //             },
// // //           ),
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(ctx),
// // //             child: const Text(
// // //               "Close",
// // //               style: TextStyle(color: Color(0xFF6A1B9A)),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _statusBox(
// // //     String title,
// // //     int count,
// // //     Color color,
// // //     List<AttendanceRecord> list,
// // //   ) => Expanded(
// // //     child: GestureDetector(
// // //       onTap: () => _showEmployeePopup("$title Employees", list),
// // //       child: Container(
// // //         margin: const EdgeInsets.symmetric(horizontal: 4),
// // //         padding: const EdgeInsets.all(10),
// // //         decoration: BoxDecoration(
// // //           color: color.withOpacity(0.1),
// // //           border: Border.all(color: color),
// // //           borderRadius: BorderRadius.circular(10),
// // //         ),
// // //         child: Column(
// // //           children: [
// // //             Text(
// // //               "$count",
// // //               style: TextStyle(
// // //                 fontSize: 20,
// // //                 fontWeight: FontWeight.bold,
// // //                 color: color,
// // //               ),
// // //             ),
// // //             const SizedBox(height: 4),
// // //             Text(
// // //               title,
// // //               style: TextStyle(color: color, fontWeight: FontWeight.bold),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     ),
// // //   );

// // //   Widget _activityCard(
// // //     String title,
// // //     int value,
// // //     List<AttendanceRecord> list, {
// // //     double fontSize = 12,
// // //   }) => GestureDetector(
// // //     onTap: () => _showEmployeePopup(title, list),
// // //     child: Container(
// // //       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFFD1C4E9).withOpacity(0.1),
// // //         border: Border.all(color: const Color(0xFF8C6EAF).withOpacity(0.3)),
// // //         borderRadius: BorderRadius.circular(12),
// // //       ),
// // //       child: Column(
// // //         mainAxisAlignment: MainAxisAlignment.center,
// // //         children: [
// // //           Text(
// // //             "$value",
// // //             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //           ),
// // //           const SizedBox(height: 4),
// // //           Text(
// // //             title,
// // //             style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
// // //             textAlign: TextAlign.center,
// // //           ),
// // //         ],
// // //       ),
// // //     ),
// // //   );
// // // }
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:intl/intl.dart';

// // import 'company_setup_page.dart';
// // import 'employee_list_page.dart';
// // import 'package:serv_app/models/company_data.dart';

// // // ✅ pull the same service used by the approvals screen
// // import '../services/api_service.dart';

// // // Model for each attendance record returned by /api/attendance/live
// // class AttendanceRecord {
// //   final String empid;
// //   final String name;
// //   final String status;
// //   final String? checkIn;
// //   final String? checkOut;
// //   final bool late;
// //   final bool early;
// //   final int permissionCount;

// //   AttendanceRecord({
// //     required this.empid,
// //     required this.name,
// //     required this.status,
// //     this.checkIn,
// //     this.checkOut,
// //     required this.late,
// //     required this.early,
// //     required this.permissionCount,
// //   });

// //   factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
// //     return AttendanceRecord(
// //       empid: json['empid'] as String,
// //       name: json['name'] as String,
// //       status: json['status'] as String,
// //       checkIn: json['checkIn'] as String?,
// //       checkOut: json['checkOut'] as String?,
// //       late: (json['late'] as bool?) ?? false,
// //       early: (json['early'] as bool?) ?? false,
// //       permissionCount: (json['permissionCount'] as num?)?.toInt() ?? 0,
// //     );
// //   }
// // }

// // class LiveAttendancePage extends StatefulWidget {
// //   final CompanyProfile companyProfile;

// //   const LiveAttendancePage({super.key, required this.companyProfile});

// //   @override
// //   _LiveAttendancePageState createState() => _LiveAttendancePageState();
// // }

// // class _LiveAttendancePageState extends State<LiveAttendancePage> {
// //   bool _isLoading = true;
// //   String? _error;
// //   List<AttendanceRecord> _records = [];

// //   // 🔹 new: hold the real pending-count from Approvals
// //   int _pendingApprovalsCount = 0;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchAll();
// //   }

// //   Future<void> _fetchAll() async {
// //     setState(() {
// //       _isLoading = true;
// //       _error = null;
// //     });
// //     try {
// //       await Future.wait([
// //         _fetchLiveAttendance(),
// //         _fetchPendingApprovalsCount(), // <- pull pending count for dashboard
// //       ]);
// //     } finally {
// //       if (mounted) {
// //         setState(() => _isLoading = false);
// //       }
// //     }
// //   }

// //   Future<void> _fetchLiveAttendance() async {
// //     final url = Uri.parse('http://localhost:3000/api/attendance/live');
// //     try {
// //       final resp = await http.get(
// //         url,
// //         headers: {
// //           'Content-Type': 'application/json',
// //           'Authorization': 'Bearer ${CompanyData.token}',
// //         },
// //       );
// //       if (resp.statusCode != 200) {
// //         setState(() {
// //           _error = 'Error ${resp.statusCode}: ${resp.body}';
// //         });
// //         return;
// //       }

// //       final List<dynamic> jsonList = jsonDecode(resp.body);
// //       final records = jsonList
// //           .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
// //           .toList();

// //       setState(() {
// //         _records = records;
// //       });
// //     } catch (e) {
// //       setState(() {
// //         _error = 'Failed to load: $e';
// //       });
// //     }
// //   }

// //   // 🔹 new: fetch total Pending approvals (same source as approvals screen)
// //   Future<void> _fetchPendingApprovalsCount() async {
// //     try {
// //       final list =
// //           await ApiService.fetchApprovals(type: 'All', status: 'Pending');
// //       if (!mounted) return;
// //       setState(() {
// //         _pendingApprovalsCount = list.length;
// //       });
// //     } catch (e) {
// //       // if it fails, show 0 instead of breaking the UI
// //       if (!mounted) return;
// //       setState(() {
// //         _pendingApprovalsCount = 0;
// //       });
// //     }
// //   }

// //   // Helpers to compute counts, using case-insensitive matching:
// //   bool _isStatus(AttendanceRecord r, String s) =>
// //       r.status.toLowerCase() == s.toLowerCase();

// //   int get presentCount => _records.where((r) => _isStatus(r, 'present')).length;
// //   int get absentCount => _records.where((r) => _isStatus(r, 'absent')).length;
// //   int get onLeaveCount => _records.where((r) => _isStatus(r, 'leave')).length;
// //   int get checkInCount => _records.where((r) => r.checkIn != null).length;
// //   int get checkOutCount => _records.where((r) => r.checkOut != null).length;
// //   int get halfDayCount =>
// //       _records.where((r) => r.checkIn != null && r.checkOut == null).length;
// //   int get lateCheckInCount => _records.where((r) => r.late).length;
// //   int get earlyCheckOutCount => _records.where((r) => r.early).length;

// //   // 🔹 changed: use the real pending count from approvals
// //   int get waitingApprovalCount => _pendingApprovalsCount;

// //   int get fieldAttendanceCount =>
// //       _records.where((r) => _isStatus(r, 'fieldattendance')).length;

// //   @override
// //   Widget build(BuildContext context) {
// //     String currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: SafeArea(
// //         child: _isLoading
// //             ? const Center(child: CircularProgressIndicator())
// //             : _error != null
// //                 ? Center(child: Text(_error!))
// //                 : SingleChildScrollView(
// //                     padding: const EdgeInsets.only(bottom: 20),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         _buildHeader(),
// //                         const SizedBox(height: 16),
// //                         _buildDateRow(currentDate),
// //                         const SizedBox(height: 12),
// //                         _buildCheckButtons(),
// //                         const SizedBox(height: 12),
// //                         _buildStatusBoxes(),
// //                         const SizedBox(height: 20),
// //                         const Center(
// //                           child: Text(
// //                             "Activity",
// //                             style: TextStyle(
// //                               fontSize: 18,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 10),
// //                         _buildActivityGrid(),
// //                       ],
// //                     ),
// //                   ),
// //       ),
// //     );
// //   }

// //   Widget _buildHeader() {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
// //       decoration: const BoxDecoration(
// //         color: Color(0xFF8C6EAF),
// //         borderRadius: BorderRadius.only(
// //           bottomLeft: Radius.circular(40),
// //           bottomRight: Radius.circular(40),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Text(
// //             "Live Attendance",
// //             style: TextStyle(
// //               color: Colors.white,
// //               fontSize: 22,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           Text(
// //             widget.companyProfile.name,
// //             style: const TextStyle(color: Colors.white),
// //           ),
// //           Text(
// //             "ID | ${widget.companyProfile.adminName}",
// //             style: const TextStyle(color: Colors.white70),
// //           ),
// //           const SizedBox(height: 16),
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.end,
// //             children: [
// //               Column(
// //                 children: const [
// //                   CircleAvatar(
// //                     backgroundColor: Colors.white,
// //                     child: Icon(Icons.map, color: Colors.green),
// //                   ),
// //                   SizedBox(height: 4),
// //                   Text(
// //                     "Map",
// //                     style: TextStyle(color: Colors.white, fontSize: 12),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(width: 16),
// //               GestureDetector(
// //                 onTap: () => Navigator.push(
// //                   context,
// //                   MaterialPageRoute(builder: (_) => const EmployeeListPage()),
// //                 ),
// //                 child: Column(
// //                   children: const [
// //                     CircleAvatar(
// //                       backgroundColor: Colors.white,
// //                       child: Icon(Icons.people, color: Colors.blue),
// //                     ),
// //                     SizedBox(height: 4),
// //                     Text(
// //                       "Employee List",
// //                       style: TextStyle(color: Colors.white, fontSize: 12),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildDateRow(String currentDate) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //       child: Text(
// //         "Today - $currentDate",
// //         style: const TextStyle(fontWeight: FontWeight.w500),
// //       ),
// //     );
// //   }

// //   Widget _buildCheckButtons() {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //         children: [
// //           ElevatedButton(
// //             onPressed: () => _showEmployeePopup(
// //               "Checked-in Employees",
// //               _records.where((r) => r.checkIn != null).toList(),
// //             ),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: const Color(0xFF655193),
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(20),
// //               ),
// //             ),
// //             child: Text(
// //               "Check-in $checkInCount",
// //               style: const TextStyle(color: Colors.white),
// //             ),
// //           ),
// //           ElevatedButton(
// //             onPressed: () => _showEmployeePopup(
// //               "Checked-out Employees",
// //               _records.where((r) => r.checkOut != null).toList(),
// //             ),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: const Color(0xFF655193),
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(20),
// //               ),
// //             ),
// //             child: Text(
// //               "Check-out $checkOutCount",
// //               style: const TextStyle(color: Colors.white),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildStatusBoxes() {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           _statusBox(
// //             "Present",
// //             presentCount,
// //             Colors.green,
// //             _records.where((r) => _isStatus(r, 'present')).toList(),
// //           ),
// //           _statusBox(
// //             "Absent",
// //             absentCount,
// //             Colors.red,
// //             _records.where((r) => _isStatus(r, 'absent')).toList(),
// //           ),
// //           _statusBox(
// //             "On Leave",
// //             onLeaveCount,
// //             Colors.orange,
// //             _records.where((r) => _isStatus(r, 'leave')).toList(),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildActivityGrid() {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16),
// //       child: GridView.count(
// //         crossAxisCount: 3,
// //         shrinkWrap: true,
// //         physics: const NeverScrollableScrollPhysics(),
// //         crossAxisSpacing: 10,
// //         mainAxisSpacing: 10,
// //         children: [
// //           _activityCard(
// //             "Half Day",
// //             halfDayCount,
// //             _records
// //                 .where((r) => r.checkIn != null && r.checkOut == null)
// //                 .toList(),
// //           ),
// //           _activityCard(
// //             "Late Check-in",
// //             lateCheckInCount,
// //             _records.where((r) => r.late).toList(),
// //           ),
// //           _activityCard(
// //             "Early Check-out",
// //             earlyCheckOutCount,
// //             _records.where((r) => r.early).toList(),
// //           ),
// //           _activityCard(
// //             "Waiting for Approvals",
// //             waitingApprovalCount,
// //             _records.where((r) => r.permissionCount > 0).toList(),
// //             fontSize: 10,
// //           ),
// //           _activityCard(
// //             "Field Attendance",
// //             fieldAttendanceCount,
// //             _records.where((r) => _isStatus(r, 'fieldattendance')).toList(),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showEmployeePopup(String title, List<AttendanceRecord> list) {
// //     showDialog(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         backgroundColor: const Color(0xFFF3E5F5),
// //         title: Text(
// //           title,
// //           style: const TextStyle(
// //             fontWeight: FontWeight.bold,
// //             color: Color(0xFF6A1B9A),
// //           ),
// //         ),
// //         content: SizedBox(
// //           width: double.maxFinite,
// //           height: 300,
// //           child: ListView.builder(
// //             itemCount: list.length,
// //             itemBuilder: (ctx, i) {
// //               final r = list[i];
// //               return ListTile(
// //                 leading: const CircleAvatar(
// //                   backgroundColor: Color(0xFFCE93D8),
// //                   child: Icon(Icons.person, color: Colors.white),
// //                 ),
// //                 title: Text(
// //                   r.name,
// //                   style: const TextStyle(fontWeight: FontWeight.bold),
// //                 ),
// //                 subtitle: Text(
// //                   "ID: ${r.empid}",
// //                   style: const TextStyle(fontWeight: FontWeight.bold),
// //                 ),
// //               );
// //             },
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx),
// //             child: const Text(
// //               "Close",
// //               style: TextStyle(color: Color(0xFF6A1B9A)),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _statusBox(
// //     String title,
// //     int count,
// //     Color color,
// //     List<AttendanceRecord> list,
// //   ) =>
// //       Expanded(
// //         child: GestureDetector(
// //           onTap: () => _showEmployeePopup("$title Employees", list),
// //           child: Container(
// //             margin: const EdgeInsets.symmetric(horizontal: 4),
// //             padding: const EdgeInsets.all(10),
// //             decoration: BoxDecoration(
// //               color: color.withOpacity(0.1),
// //               border: Border.all(color: color),
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //             child: Column(
// //               children: [
// //                 Text(
// //                   "$count",
// //                   style: TextStyle(
// //                     fontSize: 20,
// //                     fontWeight: FontWeight.bold,
// //                     color: color,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   title,
// //                   style: TextStyle(color: color, fontWeight: FontWeight.bold),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       );

// //   Widget _activityCard(
// //     String title,
// //     int value,
// //     List<AttendanceRecord> list, {
// //     double fontSize = 12,
// //   }) =>
// //       GestureDetector(
// //         onTap: () => _showEmployeePopup(title, list),
// //         child: Container(
// //           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
// //           decoration: BoxDecoration(
// //             color: const Color(0xFFD1C4E9).withOpacity(0.1),
// //             border: Border.all(color: const Color(0xFF8C6EAF).withOpacity(0.3)),
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Text(
// //                 "$value",
// //                 style:
// //                     const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //               ),
// //               const SizedBox(height: 4),
// //               Text(
// //                 title,
// //                 style:
// //                     TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
// //                 textAlign: TextAlign.center,
// //               ),
// //             ],
// //           ),
// //         ),
// //       );
// // }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

// import 'company_setup_page.dart';
// // kept import
// import 'package:serv_app/models/company_data.dart';

// // 🔹 use the same API helper as approvals screen
// import '../services/api_service.dart';

// const String _apiBase = 'http://localhost:3000';

// /// Record returned by /api/attendance/live
// class AttendanceRecord {
//   final String empid;
//   final String name;
//   final String status;
//   final String? checkIn;
//   final String? checkOut;
//   final bool late;
//   final bool early;
//   final int permissionCount;

//   AttendanceRecord({
//     required this.empid,
//     required this.name,
//     required this.status,
//     this.checkIn,
//     this.checkOut,
//     required this.late,
//     required this.early,
//     required this.permissionCount,
//   });

//   factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
//     return AttendanceRecord(
//       empid: json['empid'] as String,
//       name: json['name'] as String,
//       status: json['status'] as String,
//       checkIn: json['checkIn'] as String?,
//       checkOut: json['checkOut'] as String?,
//       late: (json['late'] as bool?) ?? false,
//       early: (json['early'] as bool?) ?? false,
//       permissionCount: (json['permissionCount'] as num?)?.toInt() ?? 0,
//     );
//   }
// }

// /// Minimal employee info (from employees DB) used to enrich the list
// class _EmployeeMeta {
//   final String empid;
//   final String? dept;
//   final String? shiftGroup;

//   _EmployeeMeta({required this.empid, this.dept, this.shiftGroup});

//   factory _EmployeeMeta.fromJson(Map<String, dynamic> j) {
//     return _EmployeeMeta(
//       empid: (j['empid'] ?? '').toString(),
//       dept: j['dept']?.toString(),
//       shiftGroup: j['shiftGroup']?.toString(),
//     );
//   }
// }

// /// Row shown in the Employee List popup (attendance + employee meta joined)
// class _CheckedInRow {
//   final String empid;
//   final String name;
//   final String date;    // yyyy-MM-dd
//   final String checkIn; // as returned by attendance
//   final String? dept;
//   final String? shiftGroup;

//   _CheckedInRow({
//     required this.empid,
//     required this.name,
//     required this.date,
//     required this.checkIn,
//     this.dept,
//     this.shiftGroup,
//   });
// }

// class LiveAttendancePage extends StatefulWidget {
//   final CompanyProfile companyProfile;

//   const LiveAttendancePage({super.key, required this.companyProfile});

//   @override
//   _LiveAttendancePageState createState() => _LiveAttendancePageState();
// }

// class _LiveAttendancePageState extends State<LiveAttendancePage> {
//   bool _isLoading = true;
//   String? _error;
//   List<AttendanceRecord> _records = [];

//   // pending approvals count shown in "Waiting for Approvals"
//   int _pendingApprovalsCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _fetchAll();
//   }

//   Future<void> _fetchAll() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//     try {
//       await Future.wait([
//         _fetchLiveAttendance(),
//         _fetchPendingApprovalsCount(), // ← fixed to match approvals page
//       ]);
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _fetchLiveAttendance() async {
//     final url = Uri.parse('$_apiBase/api/attendance/live');
//     try {
//       final resp = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${CompanyData.token}',
//         },
//       );
//       if (resp.statusCode != 200) {
//         setState(() => _error = 'Error ${resp.statusCode}: ${resp.body}');
//         return;
//       }
//       final List<dynamic> jsonList = jsonDecode(resp.body);
//       final records = jsonList
//           .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
//           .toList();
//       setState(() => _records = records);
//     } catch (e) {
//       setState(() => _error = 'Failed to load: $e');
//     }
//   }

//   /// ✅ Use the SAME service as LeaveApprovalsScreen so counts match exactly
//   Future<void> _fetchPendingApprovalsCount() async {
//     try {
//       final list = await ApiService.fetchApprovals(
//         type: 'All',
//         status: 'Pending',
//       );
//       if (!mounted) return;
//       setState(() => _pendingApprovalsCount = list.length);
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => _pendingApprovalsCount = 0);
//     }
//   }

//   // counts for tiles
//   bool _isStatus(AttendanceRecord r, String s) =>
//       r.status.toLowerCase() == s.toLowerCase();

//   int get presentCount => _records.where((r) => _isStatus(r, 'present')).length;
//   int get absentCount => _records.where((r) => _isStatus(r, 'absent')).length;
//   int get onLeaveCount => _records.where((r) => _isStatus(r, 'leave')).length;
//   int get checkInCount => _records.where((r) => r.checkIn != null).length;
//   int get checkOutCount => _records.where((r) => r.checkOut != null).length;
//   int get halfDayCount =>
//       _records.where((r) => r.checkIn != null && r.checkOut == null).length;
//   int get lateCheckInCount => _records.where((r) => r.late).length;
//   int get earlyCheckOutCount => _records.where((r) => r.early).length;
//   int get waitingApprovalCount => _pendingApprovalsCount;
//   int get fieldAttendanceCount =>
//       _records.where((r) => _isStatus(r, 'fieldattendance')).length;

//   // ——— employee list popup (today’s check-ins with dept/shift) ———

//   Future<void> _showCheckedInEmployeesPopup() async {
//     final todayYmd = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     final checkedIn = _records.where((r) => r.checkIn != null).toList();

//     if (checkedIn.isEmpty) {
//       _showSimpleInfo('No one has checked-in today.');
//       return;
//     }

//     Map<String, _EmployeeMeta> metaById = {};
//     try {
//       final uri = Uri.parse('$_apiBase/api/employees');
//       final resp = await http.get(
//         uri,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${CompanyData.token}',
//         },
//       );
//       if (resp.statusCode == 200) {
//         final List data = jsonDecode(resp.body) as List;
//         for (final e in data) {
//           if (e is Map<String, dynamic>) {
//             final m = _EmployeeMeta.fromJson(e);
//             if (m.empid.isNotEmpty) metaById[m.empid] = m;
//           }
//         }
//       }
//     } catch (_) {
//       // ignore; dept/shift will be shown as '-'
//     }

//     final rows = <_CheckedInRow>[];
//     for (final r in checkedIn) {
//       final m = metaById[r.empid];
//       rows.add(_CheckedInRow(
//         empid: r.empid,
//         name: r.name,
//         date: todayYmd,
//         checkIn: r.checkIn!,
//         dept: m?.dept,
//         shiftGroup: m?.shiftGroup,
//       ));
//     }

//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: const Color(0xFFF3E5F5),
//         title: const Text(
//           'Employee List',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF6A1B9A),
//           ),
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           height: 420,
//           child: ListView.builder(
//             itemCount: rows.length,
//             itemBuilder: (ctx, i) {
//               final e = rows[i];
//               return Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(15),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.purpleAccent.withOpacity(0.15),
//                       spreadRadius: 1.5,
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                   border: Border.all(color: Colors.deepPurple.shade100),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       e.name,
//                       style: const TextStyle(
//                         color: Colors.deepPurple,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       "ID: ${e.empid} | Date: ${e.date}",
//                       style: const TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                     const Divider(),
//                     Text("Check-in: ${e.checkIn}",
//                         style: const TextStyle(color: Colors.black87)),
//                     const SizedBox(height: 4),
//                     Text("Department: ${e.dept ?? '-'}",
//                         style: const TextStyle(color: Colors.black87)),
//                     const SizedBox(height: 4),
//                     Text("Shift: ${e.shiftGroup ?? '-'}",
//                         style: const TextStyle(color: Colors.black87)),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Close", style: TextStyle(color: Color(0xFF6A1B9A))),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSimpleInfo(String msg) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Info'),
//         content: Text(msg),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : _error != null
//                 ? Center(child: Text(_error!))
//                 : SingleChildScrollView(
//                     padding: const EdgeInsets.only(bottom: 20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildHeader(),
//                         const SizedBox(height: 16),
//                         _buildDateRow(currentDate),
//                         const SizedBox(height: 12),
//                         _buildCheckButtons(),
//                         const SizedBox(height: 12),
//                         _buildStatusBoxes(),
//                         const SizedBox(height: 20),
//                         const Center(
//                           child: Text(
//                             "Activity",
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _buildActivityGrid(),
//                       ],
//                     ),
//                   ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
//       decoration: const BoxDecoration(
//         color: Color(0xFF8C6EAF),
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(40),
//           bottomRight: Radius.circular(40),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Live Attendance",
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(widget.companyProfile.name, style: const TextStyle(color: Colors.white)),
//           Text("ID | ${widget.companyProfile.adminName}",
//               style: const TextStyle(color: Colors.white70)),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Column(
//                 children: const [
//                   CircleAvatar(
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.map, color: Colors.green),
//                   ),
//                   SizedBox(height: 4),
//                   Text("Map", style: TextStyle(color: Colors.white, fontSize: 12)),
//                 ],
//               ),
//               const SizedBox(width: 16),
//               GestureDetector(
//                 onTap: _showCheckedInEmployeesPopup,
//                 child: Column(
//                   children: const [
//                     CircleAvatar(
//                       backgroundColor: Colors.white,
//                       child: Icon(Icons.people, color: Colors.blue),
//                     ),
//                     SizedBox(height: 4),
//                     Text("Employee List",
//                         style: TextStyle(color: Colors.white, fontSize: 12)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDateRow(String currentDate) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       child: Text("Today - $currentDate",
//           style: const TextStyle(fontWeight: FontWeight.w500)),
//     );
//   }

//   Widget _buildCheckButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           ElevatedButton(
//             onPressed: () => _showEmployeePopup(
//               "Checked-in Employees",
//               _records.where((r) => r.checkIn != null).toList(),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF655193),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             child:
//                 Text("Check-in $checkInCount", style: const TextStyle(color: Colors.white)),
//           ),
//           ElevatedButton(
//             onPressed: () => _showEmployeePopup(
//               "Checked-out Employees",
//               _records.where((r) => r.checkOut != null).toList(),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF655193),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             child: Text("Check-out $checkOutCount",
//                 style: const TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusBoxes() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _statusBox(
//             "Present",
//             presentCount,
//             Colors.green,
//             _records.where((r) => _isStatus(r, 'present')).toList(),
//           ),
//           _statusBox(
//             "Absent",
//             absentCount,
//             Colors.red,
//             _records.where((r) => _isStatus(r, 'absent')).toList(),
//           ),
//           _statusBox(
//             "On Leave",
//             onLeaveCount,
//             Colors.orange,
//             _records.where((r) => _isStatus(r, 'leave')).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActivityGrid() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: GridView.count(
//         crossAxisCount: 3,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 10,
//         children: [
//           _activityCard(
//             "Half Day",
//             halfDayCount,
//             _records.where((r) => r.checkIn != null && r.checkOut == null).toList(),
//           ),
//           _activityCard(
//             "Late Check-in",
//             lateCheckInCount,
//             _records.where((r) => r.late).toList(),
//           ),
//           _activityCard(
//             "Early Check-out",
//             earlyCheckOutCount,
//             _records.where((r) => r.early).toList(),
//           ),
//           _activityCard(
//             "Waiting for Approvals",
//             waitingApprovalCount,
//             _records.where((r) => r.permissionCount > 0).toList(),
//             fontSize: 10,
//           ),
//           _activityCard(
//             "Field Attendance",
//             fieldAttendanceCount,
//             _records.where((r) => _isStatus(r, 'fieldattendance')).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showEmployeePopup(String title, List<AttendanceRecord> list) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: const Color(0xFFF3E5F5),
//         title: Text(
//           title,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF6A1B9A),
//           ),
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           height: 300,
//           child: ListView.builder(
//             itemCount: list.length,
//             itemBuilder: (ctx, i) {
//               final r = list[i];
//               return ListTile(
//                 leading: const CircleAvatar(
//                   backgroundColor: Color(0xFFCE93D8),
//                   child: Icon(Icons.person, color: Colors.white),
//                 ),
//                 title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle:
//                     Text("ID: ${r.empid}", style: const TextStyle(fontWeight: FontWeight.bold)),
//               );
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Close", style: TextStyle(color: Color(0xFF6A1B9A))),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _statusBox(
//     String title,
//     int count,
//     Color color,
//     List<AttendanceRecord> list,
//   ) =>
//       Expanded(
//         child: GestureDetector(
//           onTap: () => _showEmployeePopup("$title Employees", list),
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 4),
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               border: Border.all(color: color),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   "$count",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ),
//         ),
//       );

//   Widget _activityCard(
//     String title,
//     int value,
//     List<AttendanceRecord> list, {
//     double fontSize = 12,
//   }) =>
//       GestureDetector(
//         onTap: () => _showEmployeePopup(title, list),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
//           decoration: BoxDecoration(
//             color: const Color(0xFFD1C4E9).withOpacity(0.1),
//             border: Border.all(color: const Color(0xFF8C6EAF).withOpacity(0.3)),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text("$value",
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 4),
//               Text(
//                 title,
//                 style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       );
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'company_setup_page.dart';
import 'package:serv_app/models/company_data.dart';

// 🔹 use the same API helper as approvals screen
import '../services/api_service.dart';

const String _apiBase = 'http://localhost:3000';

/// Record returned by /api/attendance/live
class AttendanceRecord {
  final String empid;
  final String name;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final bool late;
  final bool early;
  final int permissionCount;

  AttendanceRecord({
    required this.empid,
    required this.name,
    required this.status,
    this.checkIn,
    this.checkOut,
    required this.late,
    required this.early,
    required this.permissionCount,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      empid: json['empid'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
      late: (json['late'] as bool?) ?? false,
      early: (json['early'] as bool?) ?? false,
      permissionCount: (json['permissionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Minimal employee info (from employees DB) used to enrich the list
class _EmployeeMeta {
  final String empid;
  final String? dept;
  final String? shiftGroup;

  _EmployeeMeta({required this.empid, this.dept, this.shiftGroup});

  factory _EmployeeMeta.fromJson(Map<String, dynamic> j) {
    return _EmployeeMeta(
      empid: (j['empid'] ?? '').toString(),
      dept: j['dept']?.toString(),
      shiftGroup: j['shiftGroup']?.toString(),
    );
  }
}

/// Row shown in the Employee List popup (attendance + employee meta joined)
class _CheckedInRow {
  final String empid;
  final String name;
  final String date;    // yyyy-MM-dd
  final String checkIn; // as returned by attendance
  final String? dept;
  final String? shiftGroup;

  _CheckedInRow({
    required this.empid,
    required this.name,
    required this.date,
    required this.checkIn,
    this.dept,
    this.shiftGroup,
  });
}

class LiveAttendancePage extends StatefulWidget {
  final CompanyProfile companyProfile;

  const LiveAttendancePage({super.key, required this.companyProfile});

  @override
  _LiveAttendancePageState createState() => _LiveAttendancePageState();
}

class _LiveAttendancePageState extends State<LiveAttendancePage> {
  bool _isLoading = true;
  String? _error;
  List<AttendanceRecord> _records = [];

  // pending approvals count shown in "Waiting for Approvals"
  int _pendingApprovalsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _fetchLiveAttendance(),
        _fetchPendingApprovalsCount(), // ← same source as approvals screen
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLiveAttendance() async {
    final url = Uri.parse('$_apiBase/api/attendance/live');
    try {
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${CompanyData.token}',
        },
      );
      if (resp.statusCode != 200) {
        setState(() => _error = 'Error ${resp.statusCode}: ${resp.body}');
        return;
      }
      final List<dynamic> jsonList = jsonDecode(resp.body);
      final records = jsonList
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _records = records);
    } catch (e) {
      setState(() => _error = 'Failed to load: $e');
    }
  }

  /// ✅ Use the SAME service as LeaveApprovalsScreen so counts match exactly
  Future<void> _fetchPendingApprovalsCount() async {
    try {
      final list = await ApiService.fetchApprovals(
        type: 'All',
        status: 'Pending',
      );
      if (!mounted) return;
      setState(() => _pendingApprovalsCount = list.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingApprovalsCount = 0);
    }
  }

  // counts for tiles
  bool _isStatus(AttendanceRecord r, String s) =>
      r.status.toLowerCase() == s.toLowerCase();

  int get presentCount => _records.where((r) => _isStatus(r, 'present')).length;
  int get absentCount => _records.where((r) => _isStatus(r, 'absent')).length;
  int get onLeaveCount => _records.where((r) => _isStatus(r, 'leave')).length;
  int get checkInCount => _records.where((r) => r.checkIn != null).length;
  int get checkOutCount => _records.where((r) => r.checkOut != null).length;
  int get halfDayCount =>
      _records.where((r) => r.checkIn != null && r.checkOut == null).length;
  int get lateCheckInCount => _records.where((r) => r.late).length;
  int get earlyCheckOutCount => _records.where((r) => r.early).length;
  int get waitingApprovalCount => _pendingApprovalsCount;
  int get fieldAttendanceCount =>
      _records.where((r) => _isStatus(r, 'fieldattendance')).length;

  // ——— employee list popup (today’s check-ins with dept/shift) ———

  Future<void> _showCheckedInEmployeesPopup() async {
    final todayYmd = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final checkedIn = _records.where((r) => r.checkIn != null).toList();

    if (checkedIn.isEmpty) {
      _showSimpleInfo('No one has checked-in today.');
      return;
    }

    Map<String, _EmployeeMeta> metaById = {};
    try {
      final uri = Uri.parse('$_apiBase/api/employees');
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${CompanyData.token}',
        },
      );
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body) as List;
        for (final e in data) {
          if (e is Map<String, dynamic>) {
            final m = _EmployeeMeta.fromJson(e);
            if (m.empid.isNotEmpty) metaById[m.empid] = m;
          }
        }
      }
    } catch (_) {
      // ignore; dept/shift will be shown as '-'
    }

    final rows = <_CheckedInRow>[];
    for (final r in checkedIn) {
      final m = metaById[r.empid];
      rows.add(_CheckedInRow(
        empid: r.empid,
        name: r.name,
        date: todayYmd,
        checkIn: r.checkIn!,
        dept: m?.dept,
        shiftGroup: m?.shiftGroup,
      ));
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF3E5F5),
        title: const Text(
          'Employee List',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (ctx, i) {
              final e = rows[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.15),
                      spreadRadius: 1.5,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "ID: ${e.empid} | Date: ${e.date}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Divider(),
                    Text("Check-in: ${e.checkIn}",
                        style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text("Department: ${e.dept ?? '-'}",
                        style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text("Shift: ${e.shiftGroup ?? '-'}",
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Color(0xFF6A1B9A))),
          ),
        ],
      ),
    );
  }

  /// NEW: exact popup for “Waiting for Approvals”
  /// Pulls the **pending list** from the same service the count uses,
  /// so names/IDs match the number shown on the tile.
  Future<void> _showPendingApprovalsPopup() async {
    try {
      final pendings = await ApiService.fetchApprovals(
        type: 'All',
        status: 'Pending',
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFF3E5F5),
          title: const Text(
            'Waiting for Approvals',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A1B9A),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 360,
            child: pendings.isEmpty
                ? const Center(child: Text('No pending requests'))
                : ListView.builder(
                    itemCount: pendings.length,
                    itemBuilder: (_, i) {
                      final item = pendings[i];
                      final name = (item['name'] ?? '').toString();
                      final empid = (item['empid'] ?? '').toString();
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFCE93D8),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          name.isEmpty ? '-' : name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'ID: ${empid.isEmpty ? '-' : empid}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Color(0xFF6A1B9A))),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSimpleInfo('Failed to load pending approvals: $e');
    }
  }

  void _showSimpleInfo(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Info'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildDateRow(currentDate),
                        const SizedBox(height: 12),
                        _buildCheckButtons(),
                        const SizedBox(height: 12),
                        _buildStatusBoxes(),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            "Activity",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildActivityGrid(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF8C6EAF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Live Attendance",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.companyProfile.name, style: const TextStyle(color: Colors.white)),
          Text("ID | ${widget.companyProfile.adminName}",
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const _HeaderIcon(label: 'Map', icon: Icons.map, color: Colors.green),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _showCheckedInEmployeesPopup,
                child: const _HeaderIcon(
                  label: 'Employee List',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String currentDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text("Today - $currentDate",
          style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCheckButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => _showEmployeePopup(
              "Checked-in Employees",
              _records.where((r) => r.checkIn != null).toList(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF655193),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child:
                Text("Check-in $checkInCount", style: const TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => _showEmployeePopup(
              "Checked-out Employees",
              _records.where((r) => r.checkOut != null).toList(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF655193),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text("Check-out $checkOutCount",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBoxes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statusBox(
            "Present",
            presentCount,
            Colors.green,
            _records.where((r) => _isStatus(r, 'present')).toList(),
          ),
          _statusBox(
            "Absent",
            absentCount,
            Colors.red,
            _records.where((r) => _isStatus(r, 'absent')).toList(),
          ),
          _statusBox(
            "On Leave",
            onLeaveCount,
            Colors.orange,
            _records.where((r) => _isStatus(r, 'leave')).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _activityCard(
            "Half Day",
            halfDayCount,
            _records.where((r) => r.checkIn != null && r.checkOut == null).toList(),
          ),
          _activityCard(
            "Late Check-in",
            lateCheckInCount,
            _records.where((r) => r.late).toList(),
          ),
          _activityCard(
            "Early Check-out",
            earlyCheckOutCount,
            _records.where((r) => r.early).toList(),
          ),
          // 🔧 SPECIAL CASE: Waiting for Approvals should show the approvals list,
          // not attendance-derived list. So we override onTap here.
          _activityCard(
            "Waiting for Approvals",
            waitingApprovalCount,
            const <AttendanceRecord>[], // unused for this card
            fontSize: 10,
            onTap: _showPendingApprovalsPopup,
          ),
          _activityCard(
            "Field Attendance",
            fieldAttendanceCount,
            _records.where((r) => _isStatus(r, 'fieldattendance')).toList(),
          ),
        ],
      ),
    );
  }

  void _showEmployeePopup(String title, List<AttendanceRecord> list) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF3E5F5),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final r = list[i];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFCE93D8),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text("ID: ${r.empid}", style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Color(0xFF6A1B9A))),
          ),
        ],
      ),
    );
  }

  Widget _statusBox(
    String title,
    int count,
    Color color,
    List<AttendanceRecord> list,
  ) =>
      Expanded(
        child: GestureDetector(
          onTap: () => _showEmployeePopup("$title Employees", list),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );

  /// ⬇️ Same UI as before, but with an optional [onTap] override.
  Widget _activityCard(
    String title,
    int value,
    List<AttendanceRecord> list, {
    double fontSize = 12,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap ?? () => _showEmployeePopup(title, list),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD1C4E9).withOpacity(0.1),
            border: Border.all(color: const Color(0xFF8C6EAF).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("$value",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _HeaderIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _HeaderIcon({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
