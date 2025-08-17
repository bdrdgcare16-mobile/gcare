



// // // // import 'package:flutter/material.dart';

// // // // // Colors
// // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // const Color kButtonColor = Color(0xFF655193);
// // // // const Color kTextColor = Colors.white;

// // // // void main() => runApp(MyApp());

// // // // class MyApp extends StatelessWidget {
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return MaterialApp(
// // // //       title: 'Report Scheduler',
// // // //       theme: ThemeData(primarySwatch: Colors.deepPurple),
// // // //       home: ReportSchedulerPage(),
// // // //       debugShowCheckedModeBanner: false,
// // // //     );
// // // //   }
// // // // }

// // // // class ScheduledReport {
// // // //   final String id;
// // // //   final String scheduleName;
// // // //   final String createdDate;
// // // //   final String schedulerTime;

// // // //   ScheduledReport({
// // // //     required this.id,
// // // //     required this.scheduleName,
// // // //     required this.createdDate,
// // // //     required this.schedulerTime,
// // // //   });
// // // // }

// // // // class ReportSchedulerPage extends StatefulWidget {
// // // //   @override
// // // //   _ReportSchedulerPageState createState() => _ReportSchedulerPageState();
// // // // }

// // // // class _ReportSchedulerPageState extends State<ReportSchedulerPage> {
// // // //   List<ScheduledReport> scheduledReports = [];

// // // //   void _deleteReport(String id) {
// // // //     setState(() {
// // // //       scheduledReports.removeWhere((report) => report.id == id);
// // // //     });
// // // //   }

// // // //   void _addReport(ScheduledReport report) {
// // // //     setState(() {
// // // //       scheduledReports.add(report);
// // // //     });
// // // //   }

// // // //   void _showCreateScheduleModal() {
// // // //     final isWeb = MediaQuery.of(context).size.width > 800;
// // // //     showDialog(
// // // //       context: context,
// // // //       barrierDismissible: false,
// // // //       builder: (BuildContext context) {
// // // //         return Dialog(
// // // //           backgroundColor: Colors.transparent,
// // // //           child: Container(
// // // //             width: isWeb ? 800 : MediaQuery.of(context).size.width * 0.95,
// // // //             height: isWeb ? MediaQuery.of(context).size.height * 0.85 : MediaQuery.of(context).size.height * 0.9,
// // // //             child: CreateScheduledReportModal(onReportCreated: _addReport),
// // // //           ),
// // // //         );
// // // //       },
// // // //     );
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final isWeb = MediaQuery.of(context).size.width > 800;
// // // //     return Scaffold(
// // // //       backgroundColor: kPrimaryBackgroundTop,
// // // //       body: SafeArea(
// // // //         child: SingleChildScrollView(
// // // //           padding: EdgeInsets.all(isWeb ? 24 : 16),
// // // //           child: Column(
// // // //             children: [
// // // //               Container(
// // // //                 width: double.infinity,
// // // //                 padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16, vertical: isWeb ? 20 : 16),
// // // //                 decoration: BoxDecoration(
// // // //                   color: kAppBarColor,
// // // //                   borderRadius: BorderRadius.circular(isWeb ? 30 : 25),
// // // //                 ),
// // // //                 child: Row(
// // // //                   children: [
// // // //                     IconButton(
// // // //                       icon: Icon(Icons.arrow_back, color: Colors.white),
// // // //                       onPressed: () => Navigator.of(context).maybePop(),
// // // //                     ),
// // // //                     SizedBox(width: 8),
// // // //                     Text(
// // // //                       'Report Scheduler',
// // // //                       style: TextStyle(
// // // //                         color: Colors.white,
// // // //                         fontSize: isWeb ? 20 : 18,
// // // //                         fontWeight: FontWeight.bold,
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //               SizedBox(height: isWeb ? 24 : 20),
// // // //               Wrap(
// // // //                 spacing: 12,
// // // //                 runSpacing: 12,
// // // //                 children: [
// // // //                   _buildActionButton('Create Schedule', Icons.add, isWeb: isWeb, isPrimary: true, onTap: _showCreateScheduleModal),
// // // //                 ],
// // // //               ),
// // // //               SizedBox(height: isWeb ? 24 : 20),
// // // //               Container(
// // // //                 width: double.infinity,
// // // //                 decoration: BoxDecoration(
// // // //                   color: Colors.white,
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                   border: Border.all(color: Colors.grey[300]!),
// // // //                 ),
// // // //                 child: Column(
// // // //                   children: [
// // // //                     Container(
// // // //                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // //                       decoration: BoxDecoration(
// // // //                         color: kPrimaryBackgroundBottom.withOpacity(0.4),
// // // //                         borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
// // // //                       ),
// // // //                       child: Row(
// // // //                         children: [
// // // //                           Expanded(flex: 3, child: Text('Schedule Name', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
// // // //                           Expanded(flex: 2, child: Text('Created Date', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
// // // //                           Expanded(flex: 2, child: Text('Scheduled Time', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
// // // //                           Expanded(flex: 1, child: Text('Delete', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
// // // //                         ],
// // // //                       ),
// // // //                     ),
// // // //                     if (scheduledReports.isEmpty)
// // // //                       Padding(
// // // //                         padding: const EdgeInsets.all(24.0),
// // // //                         child: Text('No scheduled reports yet', style: TextStyle(color: Colors.grey[600])),
// // // //                       )
// // // //                     else
// // // //                       ListView.builder(
// // // //                         shrinkWrap: true,
// // // //                         physics: NeverScrollableScrollPhysics(),
// // // //                         itemCount: scheduledReports.length,
// // // //                         itemBuilder: (_, i) {
// // // //                           final report = scheduledReports[i];
// // // //                           return Container(
// // // //                             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // //                             decoration: BoxDecoration(
// // // //                               border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
// // // //                             ),
// // // //                             child: Row(
// // // //                               children: [
// // // //                                 Expanded(flex: 3, child: Text(report.scheduleName, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
// // // //                                 Expanded(flex: 2, child: Text(report.createdDate, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
// // // //                                 Expanded(flex: 2, child: Text(report.schedulerTime, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
// // // //                                 Expanded(
// // // //                                   flex: 1,
// // // //                                   child: IconButton(
// // // //                                     icon: Icon(Icons.delete_outline, color: Colors.red[400]),
// // // //                                     onPressed: () => _deleteReport(report.id),
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ),
// // // //                           );
// // // //                         },
// // // //                       )
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildActionButton(String text, IconData icon,
// // // //       {bool isPrimary = false, bool isWeb = false, VoidCallback? onTap}) {
// // // //     return SizedBox(
// // // //       width: isWeb ? 180 : double.infinity,
// // // //       child: GestureDetector(
// // // //         onTap: onTap,
// // // //         child: Container(
// // // //           padding: EdgeInsets.symmetric(vertical: isWeb ? 14 : 12),
// // // //           decoration: BoxDecoration(
// // // //             color: isPrimary ? kButtonColor : Colors.white,
// // // //             borderRadius: BorderRadius.circular(8),
// // // //             border: Border.all(color: isPrimary ? kButtonColor : Colors.grey[300]!),
// // // //           ),
// // // //           child: Row(
// // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // //             children: [
// // // //               Icon(icon, size: isWeb ? 18 : 16, color: isPrimary ? Colors.white : Colors.grey[600]),
// // // //               SizedBox(width: 6),
// // // //               Flexible(
// // // //                 child: Text(
// // // //                   text,
// // // //                   style: TextStyle(
// // // //                     color: isPrimary ? Colors.white : Colors.grey[700],
// // // //                     fontSize: isWeb ? 14 : 12,
// // // //                     fontWeight: FontWeight.w500,
// // // //                   ),
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // // 🔽 CREATE SCHEDULE MODAL (WITH VALIDATION)

// // // // class CreateScheduledReportModal extends StatefulWidget {
// // // //   final Function(ScheduledReport) onReportCreated;

// // // //   const CreateScheduledReportModal({super.key, required this.onReportCreated});

// // // //   @override
// // // //   _CreateScheduledReportModalState createState() => _CreateScheduledReportModalState();
// // // // }

// // // // class _CreateScheduledReportModalState extends State<CreateScheduledReportModal> {
// // // //   final TextEditingController _nameController = TextEditingController();
// // // //   final TextEditingController _emailController = TextEditingController();
// // // //   final TextEditingController _mobileController = TextEditingController();

// // // //   String? selectedReportType;
// // // //   String? selectedTime;

// // // //   final _formKey = GlobalKey<FormState>();

// // // //   bool isValidEmail(String email) {
// // // //     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
// // // //     return emailRegex.hasMatch(email);
// // // //   }

// // // //   bool isValidMobile(String mobile) {
// // // //     final mobileRegex = RegExp(r'^[0-9]{10,}$');
// // // //     return mobileRegex.hasMatch(mobile);
// // // //   }

// // // //   void _createSchedule() {
// // // //     if (_formKey.currentState!.validate()) {
// // // //       if (selectedTime == null) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(content: Text("Please select schedule time")),
// // // //         );
// // // //         return;
// // // //       }

// // // //       final newReport = ScheduledReport(
// // // //         id: DateTime.now().millisecondsSinceEpoch.toString(),
// // // //         scheduleName: _nameController.text.trim(),
// // // //         createdDate: DateTime.now().toString().split(" ")[0],
// // // //         schedulerTime: selectedTime!,
// // // //       );

// // // //       widget.onReportCreated(newReport);
// // // //       Navigator.pop(context);
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: Colors.white,
// // // //       body: SafeArea(
// // // //         child: SingleChildScrollView(
// // // //           padding: const EdgeInsets.all(20.0),
// // // //           child: Form(
// // // //             key: _formKey,
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 Row(
// // // //                   children: [
// // // //                     IconButton(
// // // //                       icon: Icon(Icons.arrow_back),
// // // //                       onPressed: () => Navigator.pop(context),
// // // //                     ),
// // // //                     SizedBox(width: 8),
// // // //                     Text('Create Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))
// // // //                   ],
// // // //                 ),
// // // //                 SizedBox(height: 24),
// // // //                 TextFormField(
// // // //                   controller: _nameController,
// // // //                   decoration: InputDecoration(
// // // //                     labelText: 'Schedule Name',
// // // //                     border: OutlineInputBorder(),
// // // //                   ),
// // // //                   validator: (value) {
// // // //                     if (value == null || value.trim().isEmpty) {
// // // //                       return 'Please enter schedule name';
// // // //                     }
// // // //                     return null;
// // // //                   },
// // // //                 ),
// // // //                 SizedBox(height: 18),
// // // //                 DropdownButtonFormField<String>(
// // // //                   decoration: InputDecoration(
// // // //                     labelText: 'Choose Report List',
// // // //                     border: OutlineInputBorder(),
// // // //                   ),
// // // //                   items: ['Check-in', 'Check-out', 'Late check-in','On leave','Absent']
// // // //                       .map((e) => DropdownMenuItem(value: e, child: Text(e)))
// // // //                       .toList(),
// // // //                   onChanged: (val) => setState(() => selectedReportType = val),
// // // //                 ),
// // // //                 SizedBox(height: 18),
// // // //                 TextFormField(
// // // //                   controller: _emailController,
// // // //                   decoration: InputDecoration(
// // // //                     labelText: 'Email (Optional)',
// // // //                     border: OutlineInputBorder(),
// // // //                   ),
// // // //                   validator: (value) {
// // // //                     if (value != null && value.trim().isNotEmpty && !isValidEmail(value.trim())) {
// // // //                       return 'Enter a valid email';
// // // //                     }
// // // //                     return null;
// // // //                   },
// // // //                 ),
// // // //                 SizedBox(height: 18),
// // // //                 TextFormField(
// // // //                   controller: _mobileController,
// // // //                   decoration: InputDecoration(
// // // //                     labelText: 'Mobile (Optional)',
// // // //                     border: OutlineInputBorder(),
// // // //                   ),
// // // //                   keyboardType: TextInputType.phone,
// // // //                   validator: (value) {
// // // //                     if (value != null && value.trim().isNotEmpty && !isValidMobile(value.trim())) {
// // // //                       return 'Enter a valid 10 digit mobile number';
// // // //                     }
// // // //                     return null;
// // // //                   },
// // // //                 ),
// // // //                 SizedBox(height: 18),
// // // //                 DropdownButtonFormField<String>(
// // // //                   decoration: InputDecoration(
// // // //                     labelText: 'Schedule Time',
// // // //                     border: OutlineInputBorder(),
// // // //                   ),
// // // //                   items: ['07:00 PM', '08:00 PM', '09:00 PM','10:00 PM']
// // // //                       .map((e) => DropdownMenuItem(value: e, child: Text(e)))
// // // //                       .toList(),
// // // //                   onChanged: (val) => setState(() => selectedTime = val),
// // // //                 ),
// // // //                 SizedBox(height: 24),
// // // //                 Row(
// // // //                   children: [
// // // //                     Expanded(
// // // //                       child: OutlinedButton(
// // // //                         onPressed: () => Navigator.pop(context),
// // // //                         child: Text('Cancel', style: TextStyle(fontSize: 14)),
// // // //                       ),
// // // //                     ),
// // // //                     SizedBox(width: 12),
// // // //                     Expanded(
// // // //                       child: ElevatedButton(
// // // //                         style: ElevatedButton.styleFrom(backgroundColor: kButtonColor),
// // // //                         onPressed: _createSchedule,
// // // //                         child: Text('Create', style: TextStyle(color: Colors.white)),
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 )
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }


// // // import 'package:flutter/material.dart';

// // // // Gradient colors
// // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // const Color kButtonColor = Color(0xFF655193);
// // // const Color kTextColor = Colors.white;

// // // void main() => runApp(MyApp());

// // // class MyApp extends StatelessWidget {
// // //   const MyApp({super.key});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MaterialApp(
// // //       title: 'Report Scheduler',
// // //       debugShowCheckedModeBanner: false,
// // //       home: ReportSchedulerPage(),
// // //     );
// // //   }
// // // }

// // // class ScheduledReport {
// // //   final String id;
// // //   final String scheduleName;
// // //   final String createdDate;
// // //   final String schedulerTime;

// // //   ScheduledReport({
// // //     required this.id,
// // //     required this.scheduleName,
// // //     required this.createdDate,
// // //     required this.schedulerTime,
// // //   });
// // // }

// // // class ReportSchedulerPage extends StatefulWidget {
// // //   const ReportSchedulerPage({super.key});

// // //   @override
// // //   _ReportSchedulerPageState createState() => _ReportSchedulerPageState();
// // // }

// // // class _ReportSchedulerPageState extends State<ReportSchedulerPage> {
// // //   List<ScheduledReport> scheduledReports = [];

// // //   void _deleteReport(String id) {
// // //     setState(() {
// // //       scheduledReports.removeWhere((report) => report.id == id);
// // //     });
// // //   }

// // //   void _addReport(ScheduledReport report) {
// // //     setState(() {
// // //       scheduledReports.add(report);
// // //     });
// // //   }

// // //   void _showCreateScheduleModal() {
// // //     showDialog(
// // //       context: context,
// // //       barrierDismissible: false,
// // //       builder: (BuildContext context) {
// // //         return Dialog(
// // //           backgroundColor: Colors.transparent,
// // //           child: SizedBox(
// // //             width: MediaQuery.of(context).size.width * 0.95,
// // //             height: MediaQuery.of(context).size.height * 0.9,
// // //             child: CreateScheduledReportModal(onReportCreated: _addReport),
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       resizeToAvoidBottomInset: false,
// // //       body: SizedBox.expand(
// // //         child: Container(
// // //           decoration: const BoxDecoration(
// // //             gradient: LinearGradient(
// // //               colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // //               begin: Alignment.topCenter,
// // //               end: Alignment.bottomCenter,
// // //             ),
// // //           ),
// // //           child: SafeArea(
// // //             child: SingleChildScrollView(
// // //               padding: const EdgeInsets.all(16),
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   // AppBar style header
// // //                   Row(
// // //                     children: [
// // //                       IconButton(
// // //                         icon: const Icon(Icons.arrow_back, color: kAppBarColor),
// // //                         onPressed: () => Navigator.of(context).maybePop(),
// // //                       ),
// // //                       const SizedBox(width: 8),
// // //                       const Text(
// // //                         'Report Scheduler',
// // //                         style: TextStyle(
// // //                           color: kAppBarColor,
// // //                           fontSize: 20,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   const SizedBox(height: 20),

// // //                   // Create Schedule button
// // //                   SizedBox(
// // //                     width: double.infinity,
// // //                     child: ElevatedButton.icon(
// // //                       style: ElevatedButton.styleFrom(
// // //                         backgroundColor: kButtonColor,
// // //                         foregroundColor: kTextColor,
// // //                         padding: const EdgeInsets.symmetric(vertical: 14),
// // //                         shape: RoundedRectangleBorder(
// // //                           borderRadius: BorderRadius.circular(8),
// // //                         ),
// // //                       ),
// // //                       icon: const Icon(Icons.add),
// // //                       label: const Text("Create Schedule"),
// // //                       onPressed: _showCreateScheduleModal,
// // //                     ),
// // //                   ),

// // //                   const SizedBox(height: 30),

// // //                   // Table Header
// // //                   Row(
// // //                     children: const [
// // //                       Expanded(flex: 3, child: Text('Schedule Name', style: TextStyle(fontWeight: FontWeight.bold))),
// // //                       Expanded(flex: 2, child: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold))),
// // //                       Expanded(flex: 2, child: Text('Scheduled Time', style: TextStyle(fontWeight: FontWeight.bold))),
// // //                       Expanded(flex: 1, child: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold))),
// // //                     ],
// // //                   ),
// // //                   const SizedBox(height: 10),

// // //                   // Report list
// // //                   if (scheduledReports.isEmpty)
// // //                     const Padding(
// // //                       padding: EdgeInsets.symmetric(vertical: 24.0),
// // //                       child: Center(
// // //                         child: Text('No scheduled reports yet', style: TextStyle(color: Colors.black54)),
// // //                       ),
// // //                     )
// // //                   else
// // //                     ListView.builder(
// // //                       shrinkWrap: true,
// // //                       physics: const NeverScrollableScrollPhysics(),
// // //                       itemCount: scheduledReports.length,
// // //                       itemBuilder: (context, index) {
// // //                         final report = scheduledReports[index];
// // //                         return Padding(
// // //                           padding: const EdgeInsets.symmetric(vertical: 8.0),
// // //                           child: Row(
// // //                             children: [
// // //                               Expanded(flex: 3, child: Text(report.scheduleName)),
// // //                               Expanded(flex: 2, child: Text(report.createdDate)),
// // //                               Expanded(flex: 2, child: Text(report.schedulerTime)),
// // //                               Expanded(
// // //                                 flex: 1,
// // //                                 child: IconButton(
// // //                                   icon: Icon(Icons.delete_outline, color: Colors.red[400]),
// // //                                   onPressed: () => _deleteReport(report.id),
// // //                                 ),
// // //                               ),
// // //                             ],
// // //                           ),
// // //                         );
// // //                       },
// // //                     ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class CreateScheduledReportModal extends StatefulWidget {
// // //   final Function(ScheduledReport) onReportCreated;

// // //   const CreateScheduledReportModal({super.key, required this.onReportCreated});

// // //   @override
// // //   _CreateScheduledReportModalState createState() => _CreateScheduledReportModalState();
// // // }

// // // class _CreateScheduledReportModalState extends State<CreateScheduledReportModal> {
// // //   final _formKey = GlobalKey<FormState>();
// // //   final TextEditingController _nameController = TextEditingController();
// // //   final TextEditingController _emailController = TextEditingController();
// // //   final TextEditingController _mobileController = TextEditingController();

// // //   String? selectedReportType;
// // //   String? selectedTime;

// // //   bool isValidEmail(String email) {
// // //     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
// // //     return emailRegex.hasMatch(email);
// // //   }

// // //   bool isValidMobile(String mobile) {
// // //     final mobileRegex = RegExp(r'^[0-9]{10,}$');
// // //     return mobileRegex.hasMatch(mobile);
// // //   }

// // //   void _createSchedule() {
// // //     if (_formKey.currentState!.validate()) {
// // //       if (selectedTime == null) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text("Please select schedule time")),
// // //         );
// // //         return;
// // //       }

// // //       final newReport = ScheduledReport(
// // //         id: DateTime.now().millisecondsSinceEpoch.toString(),
// // //         scheduleName: _nameController.text.trim(),
// // //         createdDate: DateTime.now().toString().split(" ")[0],
// // //         schedulerTime: selectedTime!,
// // //       );

// // //       widget.onReportCreated(newReport);
// // //       Navigator.pop(context);
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Colors.transparent,
// // //       body: SizedBox.expand(
// // //         child: Container(
// // //           decoration: const BoxDecoration(
// // //             gradient: LinearGradient(
// // //               colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // //               begin: Alignment.topCenter,
// // //               end: Alignment.bottomCenter,
// // //             ),
// // //           ),
// // //           child: SafeArea(
// // //             child: SingleChildScrollView(
// // //               padding: const EdgeInsets.all(20.0),
// // //               child: Form(
// // //                 key: _formKey,
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Row(
// // //                       children: [
// // //                         IconButton(
// // //                           icon: const Icon(Icons.arrow_back, color: kAppBarColor),
// // //                           onPressed: () => Navigator.pop(context),
// // //                         ),
// // //                         const SizedBox(width: 8),
// // //                         const Text('Create Schedule',
// // //                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kAppBarColor)),
// // //                       ],
// // //                     ),
// // //                     const SizedBox(height: 24),
// // //                     TextFormField(
// // //                       controller: _nameController,
// // //                       decoration: const InputDecoration(
// // //                         labelText: 'Schedule Name',
// // //                         border: OutlineInputBorder(),
// // //                       ),
// // //                       validator: (value) =>
// // //                           value == null || value.trim().isEmpty ? 'Please enter schedule name' : null,
// // //                     ),
// // //                     const SizedBox(height: 18),
// // //                     DropdownButtonFormField<String>(
// // //                       decoration: const InputDecoration(
// // //                         labelText: 'Choose Report List',
// // //                         border: OutlineInputBorder(),
// // //                       ),
// // //                       items: ['Check-in', 'Check-out', 'Late check-in', 'On leave', 'Absent']
// // //                           .map((e) => DropdownMenuItem(value: e, child: Text(e)))
// // //                           .toList(),
// // //                       onChanged: (val) => setState(() => selectedReportType = val),
// // //                     ),
// // //                     const SizedBox(height: 18),
// // //                     TextFormField(
// // //                       controller: _emailController,
// // //                       decoration: const InputDecoration(
// // //                         labelText: 'Email (Optional)',
// // //                         border: OutlineInputBorder(),
// // //                       ),
// // //                       validator: (value) {
// // //                         if (value != null &&
// // //                             value.trim().isNotEmpty &&
// // //                             !isValidEmail(value.trim())) {
// // //                           return 'Enter a valid email';
// // //                         }
// // //                         return null;
// // //                       },
// // //                     ),
// // //                     const SizedBox(height: 18),
// // //                     TextFormField(
// // //                       controller: _mobileController,
// // //                       decoration: const InputDecoration(
// // //                         labelText: 'Mobile (Optional)',
// // //                         border: OutlineInputBorder(),
// // //                       ),
// // //                       keyboardType: TextInputType.phone,
// // //                       validator: (value) {
// // //                         if (value != null &&
// // //                             value.trim().isNotEmpty &&
// // //                             !isValidMobile(value.trim())) {
// // //                           return 'Enter a valid 10 digit mobile number';
// // //                         }
// // //                         return null;
// // //                       },
// // //                     ),
// // //                     const SizedBox(height: 18),
// // //                     DropdownButtonFormField<String>(
// // //                       decoration: const InputDecoration(
// // //                         labelText: 'Schedule Time',
// // //                         border: OutlineInputBorder(),
// // //                       ),
// // //                       items: ['07:00 PM', '08:00 PM', '09:00 PM', '10:00 PM']
// // //                           .map((e) => DropdownMenuItem(value: e, child: Text(e)))
// // //                           .toList(),
// // //                       onChanged: (val) => setState(() => selectedTime = val),
// // //                     ),
// // //                     const SizedBox(height: 24),
// // //                     Row(
// // //                       children: [
// // //                         Expanded(
// // //                           child: OutlinedButton(
// // //                             onPressed: () => Navigator.pop(context),
// // //                             child: const Text('Cancel'),
// // //                           ),
// // //                         ),
// // //                         const SizedBox(width: 12),
// // //                         Expanded(
// // //                           child: ElevatedButton(
// // //                             style: ElevatedButton.styleFrom(backgroundColor: kButtonColor),
// // //                             onPressed: _createSchedule,
// // //                             child: const Text('Create', style: TextStyle(color: Colors.white)),
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     )
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';

// // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // const Color kAppBarColor = Color(0xFF8C6EAF);
// // const Color kButtonColor = Color(0xFF655193);
// // const Color kTextColor = Colors.white;

// // void main() => runApp(MyApp());

// // class MyApp extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Report Scheduler',
// //       debugShowCheckedModeBanner: false,
// //       home: ReportSchedulerPage(),
// //     );
// //   }
// // }

// // class ScheduledReport {
// //   final String id;
// //   final String scheduleName;
// //   final String createdDate;
// //   final String schedulerTime;

// //   ScheduledReport({
// //     required this.id,
// //     required this.scheduleName,
// //     required this.createdDate,
// //     required this.schedulerTime,
// //   });
// // }

// // class ReportSchedulerPage extends StatefulWidget {
// //   @override
// //   _ReportSchedulerPageState createState() => _ReportSchedulerPageState();
// // }

// // class _ReportSchedulerPageState extends State<ReportSchedulerPage> {
// //   List<ScheduledReport> scheduledReports = [];

// //   void _deleteReport(String id) {
// //     setState(() {
// //       scheduledReports.removeWhere((report) => report.id == id);
// //     });
// //   }

// //   void _addReport(ScheduledReport report) {
// //     setState(() {
// //       scheduledReports.add(report);
// //     });
// //   }

// //   void _showCreateScheduleModal() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (BuildContext context) {
// //         return Dialog(
// //           backgroundColor: Colors.transparent,
// //           child: FractionallySizedBox(
// //             alignment: Alignment.center,
// //             widthFactor: 0.85,
// //             heightFactor: 0.8,
// //             child: CreateScheduledReportModal(onReportCreated: _addReport),
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: kAppBarColor,
// //         title: const Text('Report Scheduler', style: TextStyle(color: kTextColor)),
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: kTextColor),
// //           onPressed: () => Navigator.of(context).maybePop(),
// //         ),
// //       ),
// //       resizeToAvoidBottomInset: false,
// //       body: SizedBox.expand(
// //         child: Container(
// //           decoration: const BoxDecoration(
// //             gradient: LinearGradient(
// //               colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// //               begin: Alignment.topCenter,
// //               end: Alignment.bottomCenter,
// //             ),
// //           ),
// //           child: SafeArea(
// //             child: SingleChildScrollView(
// //               padding: const EdgeInsets.all(16),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton.icon(
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: kButtonColor,
// //                         foregroundColor: kTextColor,
// //                         padding: const EdgeInsets.symmetric(vertical: 14),
// //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// //                       ),
// //                       icon: const Icon(Icons.add),
// //                       label: const Text("Create Report Scheduler"),
// //                       onPressed: _showCreateScheduleModal,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 30),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: const [
// //                       Expanded(flex: 3, child: Text('Report Schedule Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
// //                       Expanded(flex: 2, child: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
// //                       Expanded(flex: 2, child: Text('Scheduled Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
// //                       Expanded(flex: 1, child: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 10),
// //                   if (scheduledReports.isEmpty)
// //                     const Padding(
// //                       padding: EdgeInsets.symmetric(vertical: 24.0),
// //                       child: Center(child: Text('No scheduled reports yet', style: TextStyle(color: Colors.black54))),
// //                     )
// //                   else
// //                     ListView.builder(
// //                       shrinkWrap: true,
// //                       physics: const NeverScrollableScrollPhysics(),
// //                       itemCount: scheduledReports.length,
// //                       itemBuilder: (context, index) {
// //                         final report = scheduledReports[index];
// //                         return Padding(
// //                           padding: const EdgeInsets.symmetric(vertical: 8.0),
// //                           child: Row(
// //                             children: [
// //                               Expanded(flex: 3, child: Text(report.scheduleName, style: TextStyle(fontSize: 12))),
// //                               Expanded(flex: 2, child: Text(report.createdDate, style: TextStyle(fontSize: 12))),
// //                               Expanded(flex: 2, child: Text(report.schedulerTime, style: TextStyle(fontSize: 12))),
// //                               Expanded(
// //                                 flex: 1,
// //                                 child: IconButton(
// //                                   icon: Icon(Icons.delete_outline, color: Colors.red[400]),
// //                                   onPressed: () => _deleteReport(report.id),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class CreateScheduledReportModal extends StatefulWidget {
// //   final Function(ScheduledReport) onReportCreated;

// //   const CreateScheduledReportModal({super.key, required this.onReportCreated});

// //   @override
// //   _CreateScheduledReportModalState createState() => _CreateScheduledReportModalState();
// // }

// // class _CreateScheduledReportModalState extends State<CreateScheduledReportModal> {
// //   final _formKey = GlobalKey<FormState>();
// //   final TextEditingController _nameController = TextEditingController();
// //   final TextEditingController _emailController = TextEditingController();
// //   final TextEditingController _mobileController = TextEditingController();

// //   String? selectedReportType;
// //   String? selectedTime;

// //   bool isValidEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email);
// //   bool isValidMobile(String mobile) => RegExp(r'^[0-9]{10}$').hasMatch(mobile);

// //   void _createSchedule() {
// //     if (_formKey.currentState!.validate()) {
// //       if (selectedTime == null) {
// //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select schedule time")));
// //         return;
// //       }

// //       final newReport = ScheduledReport(
// //         id: DateTime.now().millisecondsSinceEpoch.toString(),
// //         scheduleName: _nameController.text.trim(),
// //         createdDate: DateTime.now().toString().split(" ")[0],
// //         schedulerTime: selectedTime!,
// //       );

// //       widget.onReportCreated(newReport);
// //       Navigator.pop(context);
// //     }
// //   }

// //   InputDecoration denseInputDecoration(String label) {
// //     return InputDecoration(
// //       labelText: label,
// //       labelStyle: const TextStyle(fontSize: 12),
// //       isDense: true,
// //       contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 9),
// //       border: const OutlineInputBorder(),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Dialog(
// //       insetPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
// //       backgroundColor: Colors.transparent,
// //       child: Container(
// //         constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //           borderRadius: BorderRadius.all(Radius.circular(12)),
// //         ),
// //         child: Column(
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
// //               decoration: const BoxDecoration(
// //                 color: kAppBarColor,
// //                 borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
// //               ),
// //               child: Row(
// //                 children: [
// //                   IconButton(
// //                     icon: const Icon(Icons.arrow_back, color: kTextColor),
// //                     onPressed: () => Navigator.pop(context),
// //                   ),
// //                   const SizedBox(width: 8),
// //                   Expanded(
// //                     child: Text(
// //                       'Report Scheduler',
// //                       style: TextStyle(color: kTextColor, fontSize: 15, fontWeight: FontWeight.bold),
// //                       overflow: TextOverflow.ellipsis,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             Expanded(
// //               child: SingleChildScrollView(
// //                 padding: const EdgeInsets.all(20),
// //                 child: Form(
// //                   key: _formKey,
// //                   child: Column(
// //                     children: [
// //                       TextFormField(
// //                         controller: _nameController,
// //                         style: const TextStyle(fontSize: 12),
// //                         decoration: denseInputDecoration('Schedule Name'),
// //                         validator: (value) => value == null || value.trim().isEmpty ? 'Please enter schedule name' : null,
// //                       ),
// //                       const SizedBox(height: 12),
// //                       DropdownButtonFormField<String>(
// //                         decoration: denseInputDecoration('Choose Report List'),
// //                         style: const TextStyle(fontSize: 12),
// //                         items: ['Check-in', 'Check-out', 'Late check-in', 'On leave', 'Absent']
// //                             .map((e) => DropdownMenuItem(value: e, child: Text(e)))
// //                             .toList(),
// //                         onChanged: (val) => setState(() => selectedReportType = val),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       TextFormField(
// //                         controller: _emailController,
// //                         style: const TextStyle(fontSize: 12),
// //                         decoration: denseInputDecoration('Email (Optional)'),
// //                         validator: (value) {
// //                           if (value != null && value.trim().isNotEmpty && !isValidEmail(value.trim())) {
// //                             return 'Enter a valid email';
// //                           }
// //                           return null;
// //                         },
// //                       ),
// //                       const SizedBox(height: 12),
// //                       TextFormField(
// //                         controller: _mobileController,
// //                         style: const TextStyle(fontSize: 12),
// //                         decoration: denseInputDecoration('Mobile (Optional)'),
// //                         keyboardType: TextInputType.phone,
// //                         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
// //                         validator: (value) {
// //                           if (value != null && value.trim().isNotEmpty && !isValidMobile(value.trim())) {
// //                             return 'Please enter a valid 10 digit mobile number';
// //                           }
// //                           return null;
// //                         },
// //                       ),
// //                       const SizedBox(height: 12),
// //                       DropdownButtonFormField<String>(
// //                         decoration: denseInputDecoration('Schedule Time'),
// //                         style: const TextStyle(fontSize: 12),
// //                         items: ['07:00 PM', '08:00 PM', '09:00 PM', '10:00 PM']
// //                             .map((e) => DropdownMenuItem(value: e, child: Text(e)))
// //                             .toList(),
// //                         onChanged: (val) => setState(() => selectedTime = val),
// //                       ),
// //                       const SizedBox(height: 20),
// //                       Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                         children: [
// //                           SizedBox(
// //                             width: 70,
// //                             child: OutlinedButton(
// //                               style: OutlinedButton.styleFrom(
// //                                 padding: const EdgeInsets.symmetric(vertical: 14),
// //                                 textStyle: const TextStyle(fontSize: 12),
// //                               ),
// //                               onPressed: () => Navigator.pop(context),
// //                               child: const Text('Cancel'),
// //                             ),
// //                           ),
// //                           SizedBox(
// //                             width: 70,
// //                             child: ElevatedButton(
// //                               style: ElevatedButton.styleFrom(
// //                                 padding: const EdgeInsets.symmetric(vertical: 14),
// //                                 backgroundColor: kButtonColor,
// //                                 textStyle: const TextStyle(fontSize: 12),
// //                               ),
// //                               onPressed: _createSchedule,
// //                               child: const Text('Create', style: TextStyle(color: Colors.white)),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// // ADDED: http + json + localStorage for API calls
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// // ==== API base (same as the rest of your app) ====
// const String apiBase = 'http://localhost:3000';

// // ==== Small helpers (token + headers) ====
// String? _readToken() {
//   final t1 = html.window.localStorage['token'];
//   if (t1 != null && t1.isNotEmpty) return t1;
//   final t2 = html.window.localStorage['jwt'];
//   if (t2 != null && t2.isNotEmpty) return t2;
//   final t3 = html.window.localStorage['authToken'];
//   if (t3 != null && t3.isNotEmpty) return t3;
//   return null;
// }

// Map<String, String> _headers() {
//   final token = _readToken();
//   final h = <String, String>{'Content-Type': 'application/json'};
//   if (token != null && token.isNotEmpty) {
//     h['Authorization'] = 'Bearer $token';
//     h['x-auth-token'] = token;
//   }
//   return h;
// }

// // Time format helpers (UI shows 07:00 PM; API gets "19:00")
// String _to24h(String ui) {
//   try {
//     final dt = TimeOfDay.fromDateTime(
//       DateTime.parse('1970-01-01 ${ui.replaceAll(' ', '')}'),
//     );
//     // If parse above fails for strings like "07:00PM", fall back:
//   } catch (_) {}
//   // Robust parse:
//   final parts = ui.split(' ');
//   if (parts.length != 2) return ui;
//   final time = parts[0]; // "07:00"
//   final ampm = parts[1].toUpperCase(); // "PM"
//   final hhmm = time.split(':');
//   int hh = int.tryParse(hhmm[0]) ?? 0;
//   final mm = hhmm.length > 1 ? int.tryParse(hhmm[1]) ?? 0 : 0;
//   if (ampm == 'PM' && hh != 12) hh += 12;
//   if (ampm == 'AM' && hh == 12) hh = 0;
//   return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
// }

// String _toDisplay(String hhmm24) {
//   try {
//     final parts = hhmm24.split(':');
//     int hh = int.parse(parts[0]);
//     final mm = int.parse(parts[1]);
//     final ampm = hh >= 12 ? 'PM' : 'AM';
//     if (hh == 0) hh = 12;
//     if (hh > 12) hh -= 12;
//     return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')} $ampm';
//   } catch (_) {
//     return hhmm24;
//   }
// }

// String _formatDate(DateTime d) =>
//     '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// DateTime _parseCreatedAt(dynamic v) {
//   if (v == null) return DateTime.now();
//   if (v is String) {
//     // ISO string from server
//     final t = DateTime.tryParse(v);
//     if (t != null) return t;
//   }
//   // If server ever returns Firestore Timestamp-like map, you can extend here.
//   return DateTime.now();
// }

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Report Scheduler',
//       debugShowCheckedModeBanner: false,
//       home: ReportSchedulerPage(),
//     );
//   }
// }

// class ScheduledReport {
//   final String id;
//   final String scheduleName;
//   final String createdDate;
//   final String schedulerTime;

//   ScheduledReport({
//     required this.id,
//     required this.scheduleName,
//     required this.createdDate,
//     required this.schedulerTime,
//   });

//   // Build from backend JSON
//   factory ScheduledReport.fromServer(Map<String, dynamic> j) {
//     final created = _parseCreatedAt(j['createdAt']);
//     // API scheduleTime preferred as "HH:mm"; display as "hh:mm a"
//     final rawTime = (j['scheduleTime'] ?? '').toString();
//     return ScheduledReport(
//       id: (j['id'] ?? j['_id'] ?? '').toString(),
//       scheduleName: (j['name'] ?? j['scheduleName'] ?? '').toString(),
//       createdDate: _formatDate(created),
//       schedulerTime: rawTime.isEmpty ? '' : _toDisplay(rawTime),
//     );
//   }

//   // Body for POST
//   static Map<String, dynamic> toCreateBody({
//     required String name,
//     required String reportType,
//     required String uiTime, // "07:00 PM"
//     String? email,
//     String? mobile,
//   }) {
//     final hhmm24 = _to24h(uiTime);
//     return {
//       'name': name,
//       'reportType': reportType,
//       'scheduleTime': hhmm24, // server gets 24h "HH:mm"
//       // The backend Swagger shows "recipient" — we’ll include both commonly used keys
//       if (email != null && email.trim().isNotEmpty) 'recipient': email.trim(),
//       if (email != null && email.trim().isNotEmpty) 'recipientEmail': email.trim(),
//       if (mobile != null && mobile.trim().isNotEmpty) 'recipientMobile': mobile.trim(),
//       // templateId can be optional; send null if you don’t use it
//       'templateId': null,
//     };
//   }
// }

// class ReportSchedulerPage extends StatefulWidget {
//   @override
//   _ReportSchedulerPageState createState() => _ReportSchedulerPageState();
// }

// class _ReportSchedulerPageState extends State<ReportSchedulerPage> {
//   List<ScheduledReport> scheduledReports = [];

//   // === API: load, create, delete ===
//   Future<void> _fetchSchedules() async {
//     try {
//       final res = await http.get(Uri.parse('$apiBase/api/reports'), headers: _headers());
//       if (res.statusCode == 200) {
//         final list = (jsonDecode(res.body) as List)
//             .map((e) => ScheduledReport.fromServer(e as Map<String, dynamic>))
//             .toList();
//         setState(() => scheduledReports = list);
//       } else {
//         // Show nothing, but you can surface an error if needed
//       }
//     } catch (_) {
//       // ignore – keep UI unchanged
//     }
//   }

//   Future<bool> _createOnServer({
//     required String name,
//     required String reportType,
//     required String uiTime,
//     String? email,
//     String? mobile,
//   }) async {
//     try {
//       final body = jsonEncode(
//         ScheduledReport.toCreateBody(
//           name: name,
//           reportType: reportType,
//           uiTime: uiTime,
//           email: email,
//           mobile: mobile,
//         ),
//       );
//       final res = await http.post(
//         Uri.parse('$apiBase/api/reports'),
//         headers: _headers(),
//         body: body,
//       );
//       if (res.statusCode == 201) {
//         return true;
//       }
//       // You can inspect res.body for error details
//       return false;
//     } catch (_) {
//       return false;
//     }
//   }

//   Future<bool> _deleteOnServer(String id) async {
//     try {
//       final res = await http.delete(
//         Uri.parse('$apiBase/api/reports/$id'),
//         headers: _headers(),
//       );
//       return res.statusCode == 200;
//     } catch (_) {
//       return false;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fetchSchedules();
//   }

//   void _deleteReport(String id) async {
//     final ok = await _deleteOnServer(id);
//     if (ok) {
//       setState(() {
//         scheduledReports.removeWhere((report) => report.id == id);
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Schedule deleted')),
//         );
//       }
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Delete failed')),
//         );
//       }
//     }
//   }

//   Future<void> _addReportAndRefresh(ScheduledReport report) async {
//     // Refresh from server to ensure data is authoritative
//     await _fetchSchedules();
//   }

//   void _showCreateScheduleModal() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           child: FractionallySizedBox(
//             alignment: Alignment.center,
//             widthFactor: 0.85,
//             heightFactor: 0.8,
//             child: CreateScheduledReportModal(onReportCreated: _addReportAndRefresh),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: kAppBarColor,
//         title: const Text('Report Scheduler', style: TextStyle(color: kTextColor)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: kTextColor),
//           onPressed: () => Navigator.of(context).maybePop(),
//         ),
//       ),
//       resizeToAvoidBottomInset: false,
//       body: SizedBox.expand(
//         child: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           child: SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: kButtonColor,
//                         foregroundColor: kTextColor,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                       icon: const Icon(Icons.add),
//                       label: const Text("Create Report Scheduler"),
//                       onPressed: _showCreateScheduleModal,
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: const [
//                       Expanded(flex: 3, child: Text('Report Schedule Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
//                       Expanded(flex: 2, child: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
//                       Expanded(flex: 2, child: Text('Scheduled Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
//                       Expanded(flex: 1, child: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   if (scheduledReports.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 24.0),
//                       child: Center(child: Text('No scheduled reports yet', style: TextStyle(color: Colors.black54))),
//                     )
//                   else
//                     ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: scheduledReports.length,
//                       itemBuilder: (context, index) {
//                         final report = scheduledReports[index];
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 8.0),
//                           child: Row(
//                             children: [
//                               Expanded(flex: 3, child: Text(report.scheduleName, style: TextStyle(fontSize: 12))),
//                               Expanded(flex: 2, child: Text(report.createdDate, style: TextStyle(fontSize: 12))),
//                               Expanded(flex: 2, child: Text(report.schedulerTime, style: TextStyle(fontSize: 12))),
//                               Expanded(
//                                 flex: 1,
//                                 child: IconButton(
//                                   icon: Icon(Icons.delete_outline, color: Colors.red[400]),
//                                   onPressed: () => _deleteReport(report.id),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class CreateScheduledReportModal extends StatefulWidget {
//   final Future<void> Function(ScheduledReport) onReportCreated;

//   const CreateScheduledReportModal({super.key, required this.onReportCreated});

//   @override
//   _CreateScheduledReportModalState createState() => _CreateScheduledReportModalState();
// }

// class _CreateScheduledReportModalState extends State<CreateScheduledReportModal> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();

//   String? selectedReportType;
//   String? selectedTime;

//   bool isValidEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email);
//   bool isValidMobile(String mobile) => RegExp(r'^[0-9]{10}$').hasMatch(mobile);

//   // ADDED: create via API and report back to parent (keeps UI unchanged)
//   Future<void> _createSchedule() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (selectedTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select schedule time")));
//       return;
//     }
//     if (selectedReportType == null || selectedReportType!.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select report type")));
//       return;
//     }

//     final ok = await _createOnServer(
//       name: _nameController.text.trim(),
//       reportType: selectedReportType!,
//       uiTime: selectedTime!,
//       email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
//       mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
//     );

//     if (!ok) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create failed')));
//       }
//       return;
//     }

//     // Build a local display item (the list will refresh from server too)
//     final display = ScheduledReport(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       scheduleName: _nameController.text.trim(),
//       createdDate: _formatDate(DateTime.now()),
//       schedulerTime: selectedTime!,
//     );

//     await widget.onReportCreated(display);
//     if (mounted) Navigator.pop(context);
//   }

//   // Use same POST helper as page-level for consistency
//   Future<bool> _createOnServer({
//     required String name,
//     required String reportType,
//     required String uiTime,
//     String? email,
//     String? mobile,
//   }) async {
//     try {
//       final body = jsonEncode(
//         ScheduledReport.toCreateBody(
//           name: name,
//           reportType: reportType,
//           uiTime: uiTime,
//           email: email,
//           mobile: mobile,
//         ),
//       );
//       final res = await http.post(
//         Uri.parse('$apiBase/api/reports'),
//         headers: _headers(),
//         body: body,
//       );
//       return res.statusCode == 201;
//     } catch (_) {
//       return false;
//     }
//   }

//   InputDecoration denseInputDecoration(String label) {
//     return InputDecoration(
//       labelText: label,
//       labelStyle: const TextStyle(fontSize: 12),
//       isDense: true,
//       contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 9),
//       border: const OutlineInputBorder(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
//       backgroundColor: Colors.transparent,
//       child: Container(
//         constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//           borderRadius: BorderRadius.all(Radius.circular(12)),
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
//               decoration: const BoxDecoration(
//                 color: kAppBarColor,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: kTextColor),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       'Report Scheduler',
//                       style: TextStyle(color: kTextColor, fontSize: 15, fontWeight: FontWeight.bold),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       TextFormField(
//                         controller: _nameController,
//                         style: const TextStyle(fontSize: 12),
//                         decoration: denseInputDecoration('Schedule Name'),
//                         validator: (value) => value == null || value.trim().isEmpty ? 'Please enter schedule name' : null,
//                       ),
//                       const SizedBox(height: 12),
//                       DropdownButtonFormField<String>(
//                         decoration: denseInputDecoration('Choose Report List'),
//                         style: const TextStyle(fontSize: 12),
//                         items: ['Check-in', 'Check-out', 'Late check-in', 'On leave', 'Absent']
//                             .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                             .toList(),
//                         onChanged: (val) => setState(() => selectedReportType = val),
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _emailController,
//                         style: const TextStyle(fontSize: 12),
//                         decoration: denseInputDecoration('Email (Optional)'),
//                         validator: (value) {
//                           if (value != null && value.trim().isNotEmpty) {
//                             final ok = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(value.trim());
//                             if (!ok) return 'Enter a valid email';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _mobileController,
//                         style: const TextStyle(fontSize: 12),
//                         decoration: denseInputDecoration('Mobile (Optional)'),
//                         keyboardType: TextInputType.phone,
//                         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                         validator: (value) {
//                           if (value != null && value.trim().isNotEmpty) {
//                             final ok = RegExp(r'^[0-9]{10}$').hasMatch(value.trim());
//                             if (!ok) return 'Please enter a valid 10 digit mobile number';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 12),
//                       DropdownButtonFormField<String>(
//                         decoration: denseInputDecoration('Schedule Time'),
//                         style: const TextStyle(fontSize: 12),
//                         items: ['07:00 PM', '08:00 PM', '09:00 PM', '10:00 PM']
//                             .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                             .toList(),
//                         onChanged: (val) => setState(() => selectedTime = val),
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           SizedBox(
//                             width: 70,
//                             child: OutlinedButton(
//                               style: OutlinedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(vertical: 14),
//                                 textStyle: const TextStyle(fontSize: 12),
//                               ),
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('Cancel'),
//                             ),
//                           ),
//                           SizedBox(
//                             width: 70,
//                             child: ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(vertical: 14),
//                                 backgroundColor: kButtonColor,
//                                 textStyle: const TextStyle(fontSize: 12),
//                               ),
//                               onPressed: _createSchedule,
//                               child: const Text('Create', style: TextStyle(color: Colors.white)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ADDED: http + json + localStorage for API calls
import 'package:http/http.dart' as http;
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ==== API base (same as the rest of your app) ====
const String apiBase = 'http://localhost:3000';

// ==== Small helpers (token + headers) ====
String? _readToken() {
  final t1 = html.window.localStorage['token'];
  if (t1 != null && t1.isNotEmpty) return t1;
  final t2 = html.window.localStorage['jwt'];
  if (t2 != null && t2.isNotEmpty) return t2;
  final t3 = html.window.localStorage['authToken'];
  if (t3 != null && t3.isNotEmpty) return t3;
  return null;
}

Map<String, String> _headers() {
  final token = _readToken();
  final h = <String, String>{'Content-Type': 'application/json'};
  if (token != null && token.isNotEmpty) {
    h['Authorization'] = 'Bearer $token';
    h['x-auth-token'] = token;
  }
  return h;
}

// Time format helpers (UI shows 07:00 PM; API gets "19:00")
String _to24h(String ui) {
  try {
    final dt = TimeOfDay.fromDateTime(
      DateTime.parse('1970-01-01 ${ui.replaceAll(' ', '')}'),
    );
    // If parse above fails for strings like "07:00PM", fall back:
  } catch (_) {}
  // Robust parse:
  final parts = ui.split(' ');
  if (parts.length != 2) return ui;
  final time = parts[0]; // "07:00"
  final ampm = parts[1].toUpperCase(); // "PM"
  final hhmm = time.split(':');
  int hh = int.tryParse(hhmm[0]) ?? 0;
  final mm = hhmm.length > 1 ? int.tryParse(hhmm[1]) ?? 0 : 0;
  if (ampm == 'PM' && hh != 12) hh += 12;
  if (ampm == 'AM' && hh == 12) hh = 0;
  return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
}

String _toDisplay(String hhmm24) {
  try {
    final parts = hhmm24.split(':');
    int hh = int.parse(parts[0]);
    final mm = int.parse(parts[1]);
    final ampm = hh >= 12 ? 'PM' : 'AM';
    if (hh == 0) hh = 12;
    if (hh > 12) hh -= 12;
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')} $ampm';
  } catch (_) {
    return hhmm24;
  }
}

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseCreatedAt(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is String) {
    // ISO string from server
    final t = DateTime.tryParse(v);
    if (t != null) return t;
  }
  // If server ever returns Firestore Timestamp-like map, you can extend here.
  return DateTime.now();
}

// Map UI report names to API enum: [Check-In, Check-Out, Present, Absent, Late Check-In]
String _mapReportTypeToApi(String uiValue) {
  final v = uiValue.trim().toLowerCase();
  if (v == 'check-in' || v == 'checkin') return 'Check-In';
  if (v == 'check-out' || v == 'checkout') return 'Check-Out';
  if (v == 'late check-in' || v == 'late checkin') return 'Late Check-In';
  if (v == 'absent') return 'Absent';
  if (v == 'on leave' || v == 'leave') {
    // The Swagger doesn't include "On leave". If your backend supports it, change here.
    // Fallback to a valid value to avoid 400:
    return 'Absent';
  }
  // Fallback (avoid 400)
  return 'Check-In';
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Scheduler',
      debugShowCheckedModeBanner: false,
      home: ReportSchedulerPage(),
    );
  }
}

class ScheduledReport {
  final String id;
  final String scheduleName;
  final String createdDate;
  final String schedulerTime;

  ScheduledReport({
    required this.id,
    required this.scheduleName,
    required this.createdDate,
    required this.schedulerTime,
  });

  // Build from backend JSON
  factory ScheduledReport.fromServer(Map<String, dynamic> j) {
    final created = _parseCreatedAt(j['createdAt']);
    // API scheduleTime preferred as "HH:mm"; display as "hh:mm a"
    final rawTime = (j['scheduleTime'] ?? '').toString();
    return ScheduledReport(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      scheduleName: (j['name'] ?? j['scheduleName'] ?? '').toString(),
      createdDate: _formatDate(created),
      schedulerTime: rawTime.isEmpty ? '' : _toDisplay(rawTime),
    );
  }

  // Body for POST (email required by API as "recipient")
  static Map<String, dynamic> toCreateBody({
    required String name,
    required String reportType, // must be mapped
    required String uiTime,     // "07:00 PM"
    required String email,      // required -> recipient
    String? mobile,
  }) {
    final hhmm24 = _to24h(uiTime);
    return {
      'name': name,
      'reportType': reportType,
      'scheduleTime': hhmm24,          // server gets 24h "HH:mm"
      'recipient': email,              // REQUIRED by Swagger (email format)
      'recipientEmail': email,         // extra, if controller reads this
      if (mobile != null && mobile.trim().isNotEmpty) 'recipientMobile': mobile.trim(),
      // templateId is required by Swagger; send a non-null default
      'templateId': 'default-template',
    };
  }
}

class ReportSchedulerPage extends StatefulWidget {
  const ReportSchedulerPage({super.key});

  @override
  _ReportSchedulerPageState createState() => _ReportSchedulerPageState();
}

class _ReportSchedulerPageState extends State<ReportSchedulerPage> {
  List<ScheduledReport> scheduledReports = [];

  // === API: load, create, delete ===
  Future<void> _fetchSchedules() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/api/reports'), headers: _headers());
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .map((e) => ScheduledReport.fromServer(e as Map<String, dynamic>))
            .toList();
        setState(() => scheduledReports = list);
      } else {
        // Show nothing, but you can surface an error if needed
      }
    } catch (_) {
      // ignore – keep UI unchanged
    }
  }

  Future<bool> _createOnServer({
    required String name,
    required String reportType,
    required String uiTime,
    required String email,   // now required
    String? mobile,
  }) async {
    try {
      final body = jsonEncode(
        ScheduledReport.toCreateBody(
          name: name,
          reportType: reportType,
          uiTime: uiTime,
          email: email,
          mobile: mobile,
        ),
      );
      final res = await http.post(
        Uri.parse('$apiBase/api/reports'),
        headers: _headers(),
        body: body,
      );
      if (res.statusCode == 201) {
        return true;
      }
      // You can inspect res.body for error details
      // debugPrint('Create schedule failed: ${res.statusCode} -> ${res.body}');
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteOnServer(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$apiBase/api/reports/$id'),
        headers: _headers(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  void _deleteReport(String id) async {
    final ok = await _deleteOnServer(id);
    if (ok) {
      setState(() {
        scheduledReports.removeWhere((report) => report.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule deleted')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete failed')),
        );
      }
    }
  }

  Future<void> _addReportAndRefresh(ScheduledReport report) async {
    // Refresh from server to ensure data is authoritative
    await _fetchSchedules();
  }

  void _showCreateScheduleModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: FractionallySizedBox(
            alignment: Alignment.center,
            widthFactor: 0.85,
            heightFactor: 0.8,
            child: CreateScheduledReportModal(onReportCreated: _addReportAndRefresh),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        title: const Text('Report Scheduler', style: TextStyle(color: kTextColor)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        foregroundColor: kTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text("Create Report Scheduler"),
                      onPressed: _showCreateScheduleModal,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(flex: 3, child: Text('Report Schedule Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Scheduled Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 1, child: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (scheduledReports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: Text('No scheduled reports yet', style: TextStyle(color: Colors.black54))),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: scheduledReports.length,
                      itemBuilder: (context, index) {
                        final report = scheduledReports[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(report.scheduleName, style: TextStyle(fontSize: 12))),
                              Expanded(flex: 2, child: Text(report.createdDate, style: TextStyle(fontSize: 12))),
                              Expanded(flex: 2, child: Text(report.schedulerTime, style: TextStyle(fontSize: 12))),
                              Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                                  onPressed: () => _deleteReport(report.id),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateScheduledReportModal extends StatefulWidget {
  final Future<void> Function(ScheduledReport) onReportCreated;

  const CreateScheduledReportModal({super.key, required this.onReportCreated});

  @override
  _CreateScheduledReportModalState createState() => _CreateScheduledReportModalState();
}

class _CreateScheduledReportModalState extends State<CreateScheduledReportModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  String? selectedReportType;
  String? selectedTime;

  bool isValidEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email);
  bool isValidMobile(String mobile) => RegExp(r'^[0-9]{10}$').hasMatch(mobile);

  // ADDED: create via API and report back to parent (keeps UI unchanged)
  Future<void> _createSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select schedule time")));
      return;
    }
    if (selectedReportType == null || selectedReportType!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select report type")));
      return;
    }
    // Email is required by backend as "recipient"
    final email = _emailController.text.trim();
    if (email.isEmpty || !isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid recipient email")));
      return;
    }

    final ok = await _createOnServer(
      name: _nameController.text.trim(),
      reportType: _mapReportTypeToApi(selectedReportType!),
      uiTime: selectedTime!,
      email: email,
      mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
    );

    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create failed')));
      }
      return;
    }

    // Build a local display item (the list will refresh from server too)
    final display = ScheduledReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      scheduleName: _nameController.text.trim(),
      createdDate: _formatDate(DateTime.now()),
      schedulerTime: selectedTime!,
    );

    await widget.onReportCreated(display);
    if (mounted) Navigator.pop(context);
  }

  // Use same POST helper as page-level for consistency
  Future<bool> _createOnServer({
    required String name,
    required String reportType,
    required String uiTime,
    required String email,
    String? mobile,
  }) async {
    try {
      final body = jsonEncode(
        ScheduledReport.toCreateBody(
          name: name,
          reportType: reportType,
          uiTime: uiTime,
          email: email,
          mobile: mobile,
        ),
      );
      final res = await http.post(
        Uri.parse('$apiBase/api/reports'),
        headers: _headers(),
        body: body,
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  InputDecoration denseInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 9),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
              decoration: const BoxDecoration(
                color: kAppBarColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Report Scheduler',
                      style: TextStyle(color: kTextColor, fontSize: 15, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 12),
                        decoration: denseInputDecoration('Schedule Name'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter schedule name' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: denseInputDecoration('Choose Report List'),
                        style: const TextStyle(fontSize: 12),
                        items: ['Check-in', 'Check-out', 'Late check-in', 'On leave', 'Absent']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedReportType = val),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 12),
                        decoration: denseInputDecoration('Email (Optional)'),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final ok = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(value.trim());
                            if (!ok) return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mobileController,
                        style: const TextStyle(fontSize: 12),
                        decoration: denseInputDecoration('Mobile (Optional)'),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final ok = RegExp(r'^[0-9]{10}$').hasMatch(value.trim());
                            if (!ok) return 'Please enter a valid 10 digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: denseInputDecoration('Schedule Time'),
                        style: const TextStyle(fontSize: 12),
                        items: ['07:00 PM', '08:00 PM', '09:00 PM', '10:00 PM']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedTime = val),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: 70,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: kButtonColor,
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: _createSchedule,
                              child: const Text('Create', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
