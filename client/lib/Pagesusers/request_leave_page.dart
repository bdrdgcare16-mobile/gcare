// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:intl/intl.dart';
// // // // // // // import 'package:http/http.dart' as http;
// // // // // // // import 'dart:convert';

// // // // // // // // Theme Colors
// // // // // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // // // // const Color kButtonColor = Color(0xFF655193);
// // // // // // // const Color kTextColor = Colors.white;

// // // // // // // class RequestLeavePage extends StatefulWidget {
// // // // // // //   const RequestLeavePage({super.key});

// // // // // // //   @override
// // // // // // //   State<RequestLeavePage> createState() => _RequestLeavePageState();
// // // // // // // }

// // // // // // // class _RequestLeavePageState extends State<RequestLeavePage> {
// // // // // // //   final _formKey = GlobalKey<FormState>();

// // // // // // //   String? selectedLeaveType;
// // // // // // //   String? selectedShift;
// // // // // // //   String? selectedLeaveDuration;
// // // // // // //   DateTime? fromDate;
// // // // // // //   DateTime? toDate;
// // // // // // //   String? errorMessage;

// // // // // // //   final TextEditingController reasonController = TextEditingController();
// // // // // // //   final TextEditingController customLeaveController = TextEditingController();

// // // // // // //   final List<String> leaveTypes = [
// // // // // // //     'Sick Leave',
// // // // // // //     'Casual Leave',
// // // // // // //     'Planned Leave',
// // // // // // //     'Emergency Leave'
// // // // // // //   ];
// // // // // // //   final List<String> shifts = ['Shift 1', 'Shift 2', 'Shift 3'];

// // // // // // //   final Map<String, String> shiftTimes = {
// // // // // // //     'Shift 1': '6:00 AM - 2:00 PM',
// // // // // // //     'Shift 2': '8:30 AM - 4:30 PM',
// // // // // // //     'Shift 3': '9:00 AM - 5:00 PM',
// // // // // // //   };

// // // // // // //   final List<DateTime> appliedCasualLeaves = [
// // // // // // //     DateTime(2025, 7, 10),
// // // // // // //   ];

// // // // // // //   List<String> getLeaveDurationOptions(String? type) {
// // // // // // //     switch (type) {
// // // // // // //       case 'Sick Leave':
// // // // // // //       case 'Planned Leave':
// // // // // // //       case 'Emergency Leave':
// // // // // // //         return ['1 day', '2 days', '3 days', 'Others'];
// // // // // // //       case 'Casual Leave':
// // // // // // //         return ['1 day'];
// // // // // // //       default:
// // // // // // //         return [];
// // // // // // //     }
// // // // // // //   }

// // // // // // //   bool hasCasualLeaveInSameMonth() {
// // // // // // //     if (selectedLeaveType != 'Casual Leave' || fromDate == null) return false;
// // // // // // //     return appliedCasualLeaves.any(
// // // // // // //       (leave) => leave.month == fromDate!.month && leave.year == fromDate!.year,
// // // // // // //     );
// // // // // // //   }

// // // // // // //   Future<void> pickDate(BuildContext context, bool isFrom) async {
// // // // // // //     DateTime initialDate = isFrom ? DateTime.now() : (fromDate ?? DateTime.now());
// // // // // // //     DateTime firstDate = isFrom ? DateTime.now() : (fromDate ?? DateTime.now());

// // // // // // //     final DateTime? picked = await showDatePicker(
// // // // // // //       context: context,
// // // // // // //       initialDate: initialDate,
// // // // // // //       firstDate: firstDate,
// // // // // // //       lastDate: DateTime(2100),
// // // // // // //       builder: (context, child) {
// // // // // // //         return Theme(
// // // // // // //           data: Theme.of(context).copyWith(
// // // // // // //             colorScheme: const ColorScheme.light(
// // // // // // //               primary: kAppBarColor,
// // // // // // //               onPrimary: Colors.white,
// // // // // // //               onSurface: Colors.black,
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //           child: child!,
// // // // // // //         );
// // // // // // //       },
// // // // // // //     );

// // // // // // //     if (picked != null) {
// // // // // // //       setState(() {
// // // // // // //         if (isFrom) {
// // // // // // //           fromDate = picked;
// // // // // // //           if (toDate != null && toDate!.isBefore(fromDate!)) {
// // // // // // //             errorMessage = "To Date cannot be before From Date";
// // // // // // //             toDate = null;
// // // // // // //           } else {
// // // // // // //             errorMessage = null;
// // // // // // //           }
// // // // // // //         } else {
// // // // // // //           if (fromDate != null && picked.isBefore(fromDate!)) {
// // // // // // //             errorMessage = "To Date cannot be before From Date";
// // // // // // //           } else {
// // // // // // //             toDate = picked;
// // // // // // //             errorMessage = null;
// // // // // // //           }
// // // // // // //         }
// // // // // // //       });
// // // // // // //     }
// // // // // // //   }

// // // // // // //   String formatDate(DateTime? date) {
// // // // // // //     if (date == null) return '';
// // // // // // //     try {
// // // // // // //       return DateFormat('yyyy-MM-dd').format(date);
// // // // // // //     } catch (e) {
// // // // // // //       return 'Invalid Date';
// // // // // // //     }
// // // // // // //   }

// // // // // // //    Future<void> submitLeaveForm() async {
// // // // // // //    final url = Uri.parse("https://api-zmj7dqloiq-uc.a.run.app/api/apply-leave");

// // // // // // //     final response = await http.post(
// // // // // // //       url,
// // // // // // //       headers: {'Content-Type': 'application/json'},
// // // // // // //       body: jsonEncode({
// // // // // // //         'employeeName': "Padma",
// // // // // // //         'leaveType': selectedLeaveType ?? '',
// // // // // // //         'leaveDuration': selectedLeaveDuration == 'Others'
// // // // // // //             ? customLeaveController.text
// // // // // // //             : selectedLeaveDuration,
// // // // // // //         'numberOfDays': selectedLeaveDuration == 'Others'
// // // // // // //             ? int.tryParse(customLeaveController.text) ?? 1
// // // // // // //             : int.tryParse(selectedLeaveDuration?.split(" ").first ?? "1") ?? 1,
// // // // // // //         'shift': selectedShift ?? '',
// // // // // // //         'fromDate': fromDate?.toIso8601String() ?? '',
// // // // // // //         'toDate': toDate?.toIso8601String() ?? '',
// // // // // // //         'reason': reasonController.text,
// // // // // // //       }),
// // // // // // //     );

// // // // // // //     if (response.statusCode == 200) {
// // // // // // //       final data = jsonDecode(response.body);
// // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //         SnackBar(content: Text(" ${data['message']}")),
// // // // // // //       );
// // // // // // //       // Clear form after success
// // // // // // //       _formKey.currentState!.reset();
// // // // // // //       setState(() {
// // // // // // //         selectedLeaveType = null;
// // // // // // //         selectedShift = null;
// // // // // // //         selectedLeaveDuration = null;
// // // // // // //         fromDate = null;
// // // // // // //         toDate = null;
// // // // // // //         errorMessage = null;
// // // // // // //         reasonController.clear();
// // // // // // //         customLeaveController.clear();
// // // // // // //       });
// // // // // // //     } else {
// // // // // // //       print("❌ API Error: ${response.body}");
// // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //         SnackBar(content: Text("❌ Failed: ${response.body}")),
// // // // // // //       );
// // // // // // //     }
// // // // // // //   }

// // // // // // //   @override
// // // // // // // Widget build(BuildContext context) {
// // // // // // //   final durationOptions = getLeaveDurationOptions(selectedLeaveType);
// // // // // // //   final casualLeaveTaken = hasCasualLeaveInSameMonth();

// // // // // // //   return Scaffold(
// // // // // // //     body: Container(
// // // // // // //       decoration: const BoxDecoration(
// // // // // // //         gradient: LinearGradient(
// // // // // // //           colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // // // // // //           begin: Alignment.topCenter,
// // // // // // //           end: Alignment.bottomCenter,
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //       child: SafeArea(
// // // // // // //         child: SingleChildScrollView(
// // // // // // //           padding: const EdgeInsets.all(16),
// // // // // // //           child: Form(
// // // // // // //             key: _formKey,
// // // // // // //             child: Column(
// // // // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //               children: [
// // // // // // //                 // 🆕 Updated Header Bar
// // // // // // //                 Container(
// // // // // // //                   width: double.infinity,
// // // // // // //                   padding: const EdgeInsets.symmetric(vertical: 16),
// // // // // // //                   color: kAppBarColor,
// // // // // // //                   child: Row(
// // // // // // //                     children: [
// // // // // // //                       const SizedBox(width: 8),
// // // // // // //                       GestureDetector(
// // // // // // //                         onTap: () => Navigator.pop(context),
// // // // // // //                         child: const Icon(Icons.arrow_back, color: Colors.white),
// // // // // // //                       ),
// // // // // // //                       const SizedBox(width: 12),
// // // // // // //                       const Text(
// // // // // // //                         "Apply Leave",
// // // // // // //                         style: TextStyle(
// // // // // // //                           fontSize: 18,
// // // // // // //                           fontWeight: FontWeight.bold,
// // // // // // //                           color: Colors.white,
// // // // // // //                         ),
// // // // // // //                       ),
// // // // // // //                     ],
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 24),

// // // // // // //                   DropdownButtonFormField<String>(
// // // // // // //                     value: selectedLeaveType,
// // // // // // //                     decoration: _inputDecorationWithLabel("Leave Type"),
// // // // // // //                     items: leaveTypes.map((type) {
// // // // // // //                       return DropdownMenuItem(value: type, child: Text(type));
// // // // // // //                     }).toList(),
// // // // // // //                     onChanged: (val) {
// // // // // // //                       setState(() {
// // // // // // //                         selectedLeaveType = val;
// // // // // // //                         selectedLeaveDuration = null;
// // // // // // //                         customLeaveController.clear();
// // // // // // //                       });
// // // // // // //                     },
// // // // // // //                     validator: (val) => val == null ? "Please select leave type" : null,
// // // // // // //                   ),
// // // // // // //                   const SizedBox(height: 16),

// // // // // // //                   if (selectedLeaveType != null)
// // // // // // //                     DropdownButtonFormField<String>(
// // // // // // //                       value: selectedLeaveDuration,
// // // // // // //                       decoration: _inputDecorationWithLabel("Leave Duration"),
// // // // // // //                       items: durationOptions.map((d) {
// // // // // // //                         return DropdownMenuItem(value: d, child: Text(d));
// // // // // // //                       }).toList(),
// // // // // // //                       onChanged: (val) {
// // // // // // //                         setState(() {
// // // // // // //                           selectedLeaveDuration = val;
// // // // // // //                           if (val != 'Others') {
// // // // // // //                             customLeaveController.clear();
// // // // // // //                           }
// // // // // // //                         });
// // // // // // //                       },
// // // // // // //                       validator: (val) => val == null ? "Select duration" : null,
// // // // // // //                     ),

// // // // // // //                   if (selectedLeaveDuration == 'Others')
// // // // // // //                     Padding(
// // // // // // //                       padding: const EdgeInsets.only(top: 12),
// // // // // // //                       child: TextFormField(
// // // // // // //                         controller: customLeaveController,
// // // // // // //                         keyboardType: TextInputType.number,
// // // // // // //                         decoration: _inputDecorationWithLabel("Enter number of days"),
// // // // // // //                         validator: (val) =>
// // // // // // //                             val == null || val.isEmpty ? "Enter custom days" : null,
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                   const SizedBox(height: 16),

// // // // // // //                   DropdownButtonFormField<String>(
// // // // // // //                     value: selectedShift,
// // // // // // //                     decoration: _inputDecorationWithLabel("Shift"),
// // // // // // //                     items: shifts.map((shift) {
// // // // // // //                       return DropdownMenuItem(value: shift, child: Text(shift));
// // // // // // //                     }).toList(),
// // // // // // //                     onChanged: (val) => setState(() => selectedShift = val),
// // // // // // //                     validator: (val) => val == null ? "Select shift" : null,
// // // // // // //                   ),
// // // // // // //                   if (selectedShift != null)
// // // // // // //                     Padding(
// // // // // // //                       padding: const EdgeInsets.only(top: 8),
// // // // // // //                       child: Text(
// // // // // // //                         "Time: ${shiftTimes[selectedShift]!}",
// // // // // // //                         style: const TextStyle(fontSize: 14),
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                   const SizedBox(height: 16),

// // // // // // //                   GestureDetector(
// // // // // // //                     onTap: () => pickDate(context, true),
// // // // // // //                     child: AbsorbPointer(
// // // // // // //                       child: TextFormField(
// // // // // // //                         decoration: _inputDecorationWithLabel("From Date"),
// // // // // // //                         controller: TextEditingController(text: formatDate(fromDate)),
// // // // // // //                         validator: (val) =>
// // // // // // //                             val == null || val.isEmpty ? "Select From Date" : null,
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                   ),
// // // // // // //                   const SizedBox(height: 16),

// // // // // // //                   GestureDetector(
// // // // // // //                     onTap: () => pickDate(context, false),
// // // // // // //                     child: AbsorbPointer(
// // // // // // //                       child: TextFormField(
// // // // // // //                         decoration: _inputDecorationWithLabel("To Date"),
// // // // // // //                         controller: TextEditingController(text: formatDate(toDate)),
// // // // // // //                         validator: (val) {
// // // // // // //                           if (val == null || val.isEmpty) return "Select To Date";
// // // // // // //                           if (errorMessage != null) return errorMessage;
// // // // // // //                           return null;
// // // // // // //                         },
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                   ),
// // // // // // //                   if (errorMessage != null)
// // // // // // //                     Padding(
// // // // // // //                       padding: const EdgeInsets.only(top: 8),
// // // // // // //                       child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
// // // // // // //                     ),
// // // // // // //                   const SizedBox(height: 16),

// // // // // // //                   TextFormField(
// // // // // // //                     controller: reasonController,
// // // // // // //                     maxLines: 2,
// // // // // // //                     decoration: _inputDecorationWithLabel("Reason").copyWith(hintText: "Enter your reason"),
// // // // // // //                     validator: (val) => val == null || val.isEmpty ? "Enter reason" : null,
// // // // // // //                   ),
// // // // // // //                   const SizedBox(height: 24),

// // // // // // //                   if (casualLeaveTaken && selectedLeaveType == 'Casual Leave')
// // // // // // //                     Container(
// // // // // // //                       padding: const EdgeInsets.all(12),
// // // // // // //                       margin: const EdgeInsets.only(bottom: 16),
// // // // // // //                       decoration: BoxDecoration(
// // // // // // //                         color: Colors.red.shade50,
// // // // // // //                         borderRadius: BorderRadius.circular(12),
// // // // // // //                         border: Border.all(color: Colors.red),
// // // // // // //                       ),
// // // // // // //                       child: const Text(
// // // // // // //                         "You have already applied for Casual Leave this month.",
// // // // // // //                         style: TextStyle(color: Colors.red),
// // // // // // //                       ),
// // // // // // //                     ),

// // // // // // //                   SizedBox(
// // // // // // //                     width: double.infinity,
// // // // // // //                     height: 44,
// // // // // // //                     child: ElevatedButton(
// // // // // // //                       onPressed: () {
// // // // // // //                         if (_formKey.currentState!.validate()) {
// // // // // // //                           if (selectedLeaveType == 'Casual Leave' && casualLeaveTaken) {
// // // // // // //                             ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //                               const SnackBar(
// // // // // // //                                 content: Text("You already applied Casual Leave this month."),
// // // // // // //                                 backgroundColor: Colors.red,
// // // // // // //                               ),
// // // // // // //                             );
// // // // // // //                             return;
// // // // // // //                           }
// // // // // // //                           submitLeaveForm();
// // // // // // //                         }
// // // // // // //                       },
// // // // // // //                       style: ElevatedButton.styleFrom(
// // // // // // //                         backgroundColor: kButtonColor,
// // // // // // //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // // // //                       ),
// // // // // // //                       child: const Text("Submit", style: TextStyle(color: kTextColor)),
// // // // // // //                     ),
// // // // // // //                   ),
// // // // // // //                 ],
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }

// // // // // // //   InputDecoration _inputDecorationWithLabel(String labelText) {
// // // // // // //     return InputDecoration(
// // // // // // //       floatingLabelBehavior: FloatingLabelBehavior.auto,
// // // // // // //       label: RichText(
// // // // // // //         text: TextSpan(
// // // // // // //           text: labelText,
// // // // // // //           style: const TextStyle(color: Colors.black87, fontSize: 14),
// // // // // // //           children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //       filled: true,
// // // // // // //       fillColor: Colors.white,
// // // // // // //       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
// // // // // // //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// // // // // // //       enabledBorder: OutlineInputBorder(
// // // // // // //         borderRadius: BorderRadius.circular(12),
// // // // // // //         borderSide: const BorderSide(color: kButtonColor,
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //       focusedBorder: OutlineInputBorder(
// // // // // // //         borderRadius: BorderRadius.circular(12),
// // // // // // //         borderSide: const BorderSide(color: kAppBarColor, width: 2),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // frontend
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:intl/intl.dart';

// // // // // // // Theme Colors
// // // // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // // // const Color kButtonColor = Color(0xFF655193);
// // // // // // const Color kTextColor = Colors.white;

// // // // // // class RequestLeavePage extends StatefulWidget {
// // // // // //   const RequestLeavePage({super.key});

// // // // // //   @override
// // // // // //   State<RequestLeavePage> createState() => _RequestLeavePageState();
// // // // // // }

// // // // // // class _RequestLeavePageState extends State<RequestLeavePage> {
// // // // // //   final _formKey = GlobalKey<FormState>();

// // // // // //   String? selectedLeaveType;
// // // // // //   String? selectedShift;
// // // // // //   String? selectedLeaveDuration;
// // // // // //   DateTime? fromDate;
// // // // // //   DateTime? toDate;
// // // // // //   String? errorMessage;

// // // // // //   final TextEditingController reasonController = TextEditingController();
// // // // // //   final TextEditingController customLeaveController = TextEditingController();

// // // // // //   final List<String> leaveTypes = [
// // // // // //     'Sick Leave',
// // // // // //     'Casual Leave',
// // // // // //     'Planned Leave',
// // // // // //     'Emergency Leave'
// // // // // //   ];
// // // // // //   final List<String> shifts = ['Shift 1', 'Shift 2', 'Shift 3'];

// // // // // //   final Map<String, String> shiftTimes = {
// // // // // //     'Shift 1': '6:00 AM - 2:00 PM',
// // // // // //     'Shift 2': '8:30 AM - 4:30 PM',
// // // // // //     'Shift 3': '9:00 AM - 5:00 PM',
// // // // // //   };

// // // // // //   final List<DateTime> appliedCasualLeaves = [
// // // // // //     DateTime(2025, 7, 10),
// // // // // //   ];

// // // // // //   List<String> getLeaveDurationOptions(String? type) {
// // // // // //     switch (type) {
// // // // // //       case 'Sick Leave':
// // // // // //       case 'Planned Leave':
// // // // // //       case 'Emergency Leave':
// // // // // //         return ['1 day', '2 days', '3 days', 'Others'];
// // // // // //       case 'Casual Leave':
// // // // // //         return ['1 day'];
// // // // // //       default:
// // // // // //         return [];
// // // // // //     }
// // // // // //   }

// // // // // //   bool hasCasualLeaveInSameMonth() {
// // // // // //     if (selectedLeaveType != 'Casual Leave' || fromDate == null) return false;
// // // // // //     return appliedCasualLeaves.any(
// // // // // //       (leave) => leave.month == fromDate!.month && leave.year == fromDate!.year,
// // // // // //     );
// // // // // //   }

// // // // // //   int? _getAllowedDays() {
// // // // // //     if (selectedLeaveDuration == null) return null;
// // // // // //     if (selectedLeaveDuration == 'Others') {
// // // // // //       if (customLeaveController.text.isEmpty) return null;
// // // // // //       return int.tryParse(customLeaveController.text);
// // // // // //     }
// // // // // //     return int.tryParse(selectedLeaveDuration!.split(' ')[0]);
// // // // // //   }

// // // // // //   Future<void> pickDate(BuildContext context, bool isFrom) async {
// // // // // //     int? allowedDays = _getAllowedDays();

// // // // // //     DateTime initialDate = isFrom ? DateTime.now() : (fromDate ?? DateTime.now());
// // // // // //     DateTime firstDate = isFrom ? DateTime.now() : (fromDate ?? DateTime.now());
// // // // // //     DateTime lastDate;

// // // // // //     if (isFrom) {
// // // // // //       // If picking from date, allow any date up to far future
// // // // // //       lastDate = DateTime(2100);
// // // // // //     } else {
// // // // // //       // If picking to date, restrict according to allowedDays
// // // // // //       if (fromDate != null && allowedDays != null && allowedDays > 0) {
// // // // // //         lastDate = fromDate!.add(Duration(days: allowedDays - 1));
// // // // // //       } else {
// // // // // //         lastDate = DateTime(2100);
// // // // // //       }
// // // // // //     }

// // // // // //     final DateTime? picked = await showDatePicker(
// // // // // //       context: context,
// // // // // //       initialDate: initialDate,
// // // // // //       firstDate: firstDate,
// // // // // //       lastDate: lastDate,
// // // // // //       builder: (context, child) {
// // // // // //         return Theme(
// // // // // //           data: Theme.of(context).copyWith(
// // // // // //             colorScheme: const ColorScheme.light(
// // // // // //               primary: kAppBarColor,
// // // // // //               onPrimary: Colors.white,
// // // // // //               onSurface: Colors.black,
// // // // // //             ),
// // // // // //           ),
// // // // // //           child: child!,
// // // // // //         );
// // // // // //       },
// // // // // //     );

// // // // // //     if (picked != null) {
// // // // // //       setState(() {
// // // // // //         if (isFrom) {
// // // // // //           fromDate = picked;
// // // // // //           // Auto adjust toDate if allowedDays selected
// // // // // //           if (allowedDays != null && allowedDays > 0) {
// // // // // //             toDate = fromDate!.add(Duration(days: allowedDays - 1));
// // // // // //           }
// // // // // //           errorMessage = null;
// // // // // //         } else {
// // // // // //           if (fromDate != null && picked.isBefore(fromDate!)) {
// // // // // //             errorMessage = "To Date cannot be before From Date";
// // // // // //           } else {
// // // // // //             toDate = picked;
// // // // // //             errorMessage = null;
// // // // // //           }
// // // // // //         }
// // // // // //       });
// // // // // //     }
// // // // // //   }

// // // // // //   String formatDate(DateTime? date) {
// // // // // //     if (date == null) return '';
// // // // // //     try {
// // // // // //       return DateFormat('yyyy-MM-dd').format(date);
// // // // // //     } catch (e) {
// // // // // //       return 'Invalid Date';
// // // // // //     }
// // // // // //   }

// // // // // //   void onSubmit() {
// // // // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // // // //       const SnackBar(
// // // // // //         content: Text("Leave request submitted "),
// // // // // //         backgroundColor: Color.fromARGB(255, 15, 15, 15),
// // // // // //       ),
// // // // // //     );

// // // // // //     // Reset form
// // // // // //     _formKey.currentState!.reset();
// // // // // //     setState(() {
// // // // // //       selectedLeaveType = null;
// // // // // //       selectedShift = null;
// // // // // //       selectedLeaveDuration = null;
// // // // // //       fromDate = null;
// // // // // //       toDate = null;
// // // // // //       errorMessage = null;
// // // // // //       reasonController.clear();
// // // // // //       customLeaveController.clear();
// // // // // //     });
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final durationOptions = getLeaveDurationOptions(selectedLeaveType);
// // // // // //     final casualLeaveTaken = hasCasualLeaveInSameMonth();

// // // // // //     return Scaffold(
// // // // // //       body: Container(
// // // // // //         decoration: const BoxDecoration(
// // // // // //           gradient: LinearGradient(
// // // // // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // // // // //             begin: Alignment.topCenter,
// // // // // //             end: Alignment.bottomCenter,
// // // // // //           ),
// // // // // //         ),
// // // // // //         child: SafeArea(
// // // // // //           child: SingleChildScrollView(
// // // // // //             padding: const EdgeInsets.all(16),
// // // // // //             child: Form(
// // // // // //               key: _formKey,
// // // // // //               child: Column(
// // // // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //                 children: [
// // // // // //                   Container(
// // // // // //                     width: double.infinity,
// // // // // //                     padding: const EdgeInsets.symmetric(vertical: 16),
// // // // // //                     color: kAppBarColor,
// // // // // //                     child: Row(
// // // // // //                       children: [
// // // // // //                         const SizedBox(width: 8),
// // // // // //                         GestureDetector(
// // // // // //                           onTap: () => Navigator.pop(context),
// // // // // //                           child: const Icon(Icons.arrow_back, color: Colors.white),
// // // // // //                         ),
// // // // // //                         const SizedBox(width: 12),
// // // // // //                         const Text(
// // // // // //                           "Apply Leave",
// // // // // //                           style: TextStyle(
// // // // // //                             fontSize: 18,
// // // // // //                             fontWeight: FontWeight.bold,
// // // // // //                             color: Colors.white,
// // // // // //                           ),
// // // // // //                         ),
// // // // // //                       ],
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   const SizedBox(height: 24),

// // // // // //                   DropdownButtonFormField<String>(
// // // // // //                     value: selectedLeaveType,
// // // // // //                     decoration: _inputDecorationWithLabel("Leave Type"),
// // // // // //                     items: leaveTypes.map((type) {
// // // // // //                       return DropdownMenuItem(value: type, child: Text(type));
// // // // // //                     }).toList(),
// // // // // //                     onChanged: (val) {
// // // // // //                       setState(() {
// // // // // //                         selectedLeaveType = val;
// // // // // //                         selectedLeaveDuration = null;
// // // // // //                         customLeaveController.clear();
// // // // // //                       });
// // // // // //                     },
// // // // // //                     validator: (val) => val == null ? "Please select leave type" : null,
// // // // // //                   ),
// // // // // //                   const SizedBox(height: 16),

// // // // // //                   if (selectedLeaveType != null)
// // // // // //                     DropdownButtonFormField<String>(
// // // // // //                       value: selectedLeaveDuration,
// // // // // //                       decoration: _inputDecorationWithLabel("Leave Duration"),
// // // // // //                       items: durationOptions.map((d) {
// // // // // //                         return DropdownMenuItem(value: d, child: Text(d));
// // // // // //                       }).toList(),
// // // // // //                       onChanged: (val) {
// // // // // //                         setState(() {
// // // // // //                           selectedLeaveDuration = val;
// // // // // //                           if (val != 'Others') {
// // // // // //                             customLeaveController.clear();
// // // // // //                           }
// // // // // //                         });
// // // // // //                       },
// // // // // //                       validator: (val) => val == null ? "Select duration" : null,
// // // // // //                     ),

// // // // // //                   if (selectedLeaveDuration == 'Others')
// // // // // //                     Padding(
// // // // // //                       padding: const EdgeInsets.only(top: 12),
// // // // // //                       child: TextFormField(
// // // // // //                         controller: customLeaveController,
// // // // // //                         keyboardType: TextInputType.number,
// // // // // //                         decoration: _inputDecorationWithLabel("Enter number of days"),
// // // // // //                         onChanged: (_) {
// // // // // //                           // Reset dates if days changed
// // // // // //                           setState(() {
// // // // // //                             fromDate = null;
// // // // // //                             toDate = null;
// // // // // //                           });
// // // // // //                         },
// // // // // //                         validator: (val) =>
// // // // // //                             val == null || val.isEmpty ? "Enter custom days" : null,
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   const SizedBox(height: 16),

// // // // // //                   DropdownButtonFormField<String>(
// // // // // //                     value: selectedShift,
// // // // // //                     decoration: _inputDecorationWithLabel("Shift"),
// // // // // //                     items: shifts.map((shift) {
// // // // // //                       return DropdownMenuItem(value: shift, child: Text(shift));
// // // // // //                     }).toList(),
// // // // // //                     onChanged: (val) => setState(() => selectedShift = val),
// // // // // //                     validator: (val) => val == null ? "Select shift" : null,
// // // // // //                   ),
// // // // // //                   if (selectedShift != null)
// // // // // //                     Padding(
// // // // // //                       padding: const EdgeInsets.only(top: 8),
// // // // // //                       child: Text(
// // // // // //                         "Time: ${shiftTimes[selectedShift]!}",
// // // // // //                         style: const TextStyle(fontSize: 14),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   const SizedBox(height: 16),

// // // // // //                   GestureDetector(
// // // // // //                     onTap: () => pickDate(context, true),
// // // // // //                     child: AbsorbPointer(
// // // // // //                       child: TextFormField(
// // // // // //                         decoration: _inputDecorationWithLabel("From Date"),
// // // // // //                         controller: TextEditingController(text: formatDate(fromDate)),
// // // // // //                         validator: (val) =>
// // // // // //                             val == null || val.isEmpty ? "Select From Date" : null,
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   const SizedBox(height: 16),

// // // // // //                   GestureDetector(
// // // // // //                     onTap: () => pickDate(context, false),
// // // // // //                     child: AbsorbPointer(
// // // // // //                       child: TextFormField(
// // // // // //                         decoration: _inputDecorationWithLabel("To Date"),
// // // // // //                         controller: TextEditingController(text: formatDate(toDate)),
// // // // // //                         validator: (val) {
// // // // // //                           if (val == null || val.isEmpty) return "Select To Date";
// // // // // //                           if (errorMessage != null) return errorMessage;
// // // // // //                           return null;
// // // // // //                         },
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   if (errorMessage != null)
// // // // // //                     Padding(
// // // // // //                       padding: const EdgeInsets.only(top: 8),
// // // // // //                       child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
// // // // // //                     ),
// // // // // //                   const SizedBox(height: 16),

// // // // // //                   TextFormField(
// // // // // //                     controller: reasonController,
// // // // // //                     maxLines: 2,
// // // // // //                     decoration: _inputDecorationWithLabel("Reason")
// // // // // //                         .copyWith(hintText: "Enter your reason"),
// // // // // //                     validator: (val) => val == null || val.isEmpty ? "Enter reason" : null,
// // // // // //                   ),
// // // // // //                   const SizedBox(height: 24),

// // // // // //                   if (casualLeaveTaken && selectedLeaveType == 'Casual Leave')
// // // // // //                     Container(
// // // // // //                       padding: const EdgeInsets.all(12),
// // // // // //                       margin: const EdgeInsets.only(bottom: 16),
// // // // // //                       decoration: BoxDecoration(
// // // // // //                         color: Colors.red.shade50,
// // // // // //                         borderRadius: BorderRadius.circular(12),
// // // // // //                         border: Border.all(color: Colors.red),
// // // // // //                       ),
// // // // // //                       child: const Text(
// // // // // //                         "You have already applied for Casual Leave this month.",
// // // // // //                         style: TextStyle(color: Colors.red),
// // // // // //                       ),
// // // // // //                     ),

// // // // // //                   SizedBox(
// // // // // //                     width: double.infinity,
// // // // // //                     height: 44,
// // // // // //                     child: ElevatedButton(
// // // // // //                       onPressed: () {
// // // // // //                         if (_formKey.currentState!.validate()) {
// // // // // //                           if (selectedLeaveType == 'Casual Leave' && casualLeaveTaken) {
// // // // // //                             ScaffoldMessenger.of(context).showSnackBar(
// // // // // //                               const SnackBar(
// // // // // //                                 content: Text("You already applied Casual Leave this month."),
// // // // // //                                 backgroundColor: Colors.red,
// // // // // //                               ),
// // // // // //                             );
// // // // // //                             return;
// // // // // //                           }
// // // // // //                           onSubmit();
// // // // // //                         }
// // // // // //                       },
// // // // // //                       style: ElevatedButton.styleFrom(
// // // // // //                         backgroundColor: kButtonColor,
// // // // // //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // // // //                       ),
// // // // // //                       child: const Text("Submit", style: TextStyle(color: kTextColor)),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   InputDecoration _inputDecorationWithLabel(String labelText) {
// // // // // //     return InputDecoration(
// // // // // //       floatingLabelBehavior: FloatingLabelBehavior.auto,
// // // // // //       label: RichText(
// // // // // //         text: TextSpan(
// // // // // //           text: labelText,
// // // // // //           style: const TextStyle(color: Colors.black87, fontSize: 14),
// // // // // //           children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
// // // // // //         ),
// // // // // //       ),
// // // // // //       filled: true,
// // // // // //       fillColor: Colors.white,
// // // // // //       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
// // // // // //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// // // // // //       enabledBorder: OutlineInputBorder(
// // // // // //         borderRadius: BorderRadius.circular(12),
// // // // // //         borderSide: const BorderSide(color: kButtonColor),
// // // // // //       ),
// // // // // //       focusedBorder: OutlineInputBorder(
// // // // // //         borderRadius: BorderRadius.circular(12),
// // // // // //         borderSide: const BorderSide(color: kAppBarColor, width: 2),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // // }
// // // // import 'package:flutter/material.dart';
// // // // import 'package:intl/intl.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'dart:convert';
// // // // import 'dart:html' as html; // for Flutter Web localStorage

// // // // // If you already use a central model to hold the JWT (from your login flow)
// // // // import 'package:serv_app/models/company_data.dart'; // <-- adjust path if needed

// // // // // Theme Colors
// // // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // // const Color kButtonColor = Color(0xFF655193);
// // // // const Color kTextColor = Colors.white;

// // // // /// Match your Node server port
// // // // const String apiBase = 'http://localhost:3000';

// // // // class RequestLeavePage extends StatefulWidget {
// // // //   /// Allow passing a token directly when navigating, if you prefer.
// // // //   final String? token;
// // // //   const RequestLeavePage({super.key, this.token});

// // // //   @override
// // // //   State<RequestLeavePage> createState() => _RequestLeavePageState();
// // // // }

// // // // class _RequestLeavePageState extends State<RequestLeavePage> {
// // // //   final _formKey = GlobalKey<FormState>();

// // // //   String? selectedLeaveType;
// // // //   String? selectedShift;
// // // //   String? selectedLeaveDuration;
// // // //   DateTime? fromDate;
// // // //   DateTime? toDate;
// // // //   String? errorMessage;

// // // //   final TextEditingController reasonController = TextEditingController();
// // // //   final TextEditingController customLeaveController = TextEditingController();

// // // //   final List<String> leaveTypes = [
// // // //     'Sick Leave',
// // // //     'Casual Leave',
// // // //     'Planned Leave',
// // // //     'Emergency Leave', // will be mapped to a valid backend type
// // // //   ];
// // // //   final List<String> shifts = ['Shift 1', 'Shift 2', 'Shift 3'];

// // // //   final Map<String, String> shiftTimes = {
// // // //     'Shift 1': '6:00 AM - 2:00 PM',
// // // //     'Shift 2': '8:30 AM - 4:30 PM',
// // // //     'Shift 3': '9:00 AM - 5:00 PM',
// // // //   };

// // // //   // Example: casual taken once in a month rule
// // // //   final List<DateTime> appliedCasualLeaves = [DateTime(2025, 7, 10)];

// // // //   // ---------- helpers: jwt + mapping ----------
// // // //   bool _looksLikeJwt(String v) => RegExp(
// // // //     r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$',
// // // //   ).hasMatch(v);

// // // //   Future<String?> _getJwt() async {
// // // //     // 1) From constructor param
// // // //     if (widget.token != null && widget.token!.isNotEmpty) {
// // // //       debugPrint('[RequestLeave] token from widget (${widget.token!.length})');
// // // //       return widget.token;
// // // //     }

// // // //     // 2) From CompanyData (in-memory, set at login)
// // // //     try {
// // // //       final t = CompanyData.token; // adjust if your field name differs
// // // //       if (t != null && t.isNotEmpty) {
// // // //         debugPrint('[RequestLeave] token from CompanyData (${t.length})');
// // // //         // Persist to localStorage for web pages that open later
// // // //         final exists = html.window.localStorage['token'];
// // // //         if (exists == null || exists.isEmpty) {
// // // //           html.window.localStorage['token'] = t;
// // // //         }
// // // //         return t;
// // // //       }
// // // //     } catch (_) {
// // // //       // ignore if CompanyData is unavailable in this target
// // // //     }

// // // //     // 3) Common localStorage keys
// // // //     final keysToTry = ['jwt', 'token', 'access_token', 'auth_token'];
// // // //     for (final k in keysToTry) {
// // // //       final v = html.window.localStorage[k];
// // // //       if (v != null && v.isNotEmpty) {
// // // //         debugPrint('[RequestLeave] token from localStorage "$k" (${v.length})');
// // // //         return v;
// // // //       }
// // // //     }

// // // //     // 4) Fallback: scan all localStorage values; pick first JWT-looking string
// // // //     for (int i = 0; i < html.window.localStorage.length; i++) {
// // // //       final key = html.window.localStorage.keys.elementAt(i);
// // // //       final val = html.window.localStorage[key];
// // // //       if (val != null && _looksLikeJwt(val)) {
// // // //         debugPrint(
// // // //           '[RequestLeave] token from localStorage "$key" (${val.length})',
// // // //         );
// // // //         return val;
// // // //       }
// // // //     }

// // // //     debugPrint(
// // // //       '[RequestLeave] No token found (CompanyData/widget/localStorage)',
// // // //     );
// // // //     return null;
// // // //   }

// // // //   // Backend only accepts: Casual Leave | Planned Leave | Sick Leave (+ others you use elsewhere)
// // // //   String _canonicalType(String? t) {
// // // //     if (t == null) return '';
// // // //     if (t == 'Emergency Leave') return 'Planned Leave';
// // // //     return t;
// // // //   }

// // // //   List<String> getLeaveDurationOptions(String? type) {
// // // //     switch (type) {
// // // //       case 'Sick Leave':
// // // //       case 'Planned Leave':
// // // //       case 'Emergency Leave':
// // // //         return ['1 day', '2 days', '3 days', 'Others'];
// // // //       case 'Casual Leave':
// // // //         return ['1 day'];
// // // //       default:
// // // //         return [];
// // // //     }
// // // //   }

// // // //   bool hasCasualLeaveInSameMonth() {
// // // //     if (selectedLeaveType != 'Casual Leave' || fromDate == null) return false;
// // // //     return appliedCasualLeaves.any(
// // // //       (leave) => leave.month == fromDate!.month && leave.year == fromDate!.year,
// // // //     );
// // // //   }

// // // //   int? _getAllowedDays() {
// // // //     if (selectedLeaveDuration == null) return null;
// // // //     if (selectedLeaveDuration == 'Others') {
// // // //       if (customLeaveController.text.isEmpty) return null;
// // // //       return int.tryParse(customLeaveController.text);
// // // //     }
// // // //     return int.tryParse(selectedLeaveDuration!.split(' ')[0]);
// // // //   }

// // // //   Future<void> pickDate(BuildContext context, bool isFrom) async {
// // // //     int? allowedDays = _getAllowedDays();

// // // //     DateTime initialDate = isFrom
// // // //         ? DateTime.now()
// // // //         : (fromDate ?? DateTime.now());
// // // //     DateTime firstDate = isFrom ? DateTime.now() : (fromDate ?? DateTime.now());
// // // //     DateTime lastDate;

// // // //     if (isFrom) {
// // // //       lastDate = DateTime(2100);
// // // //     } else {
// // // //       if (fromDate != null && allowedDays != null && allowedDays > 0) {
// // // //         lastDate = fromDate!.add(Duration(days: allowedDays - 1));
// // // //       } else {
// // // //         lastDate = DateTime(2100);
// // // //       }
// // // //     }

// // // //     final DateTime? picked = await showDatePicker(
// // // //       context: context,
// // // //       initialDate: initialDate,
// // // //       firstDate: firstDate,
// // // //       lastDate: lastDate,
// // // //       builder: (context, child) {
// // // //         return Theme(
// // // //           data: Theme.of(context).copyWith(
// // // //             colorScheme: const ColorScheme.light(
// // // //               primary: kAppBarColor,
// // // //               onPrimary: Colors.white,
// // // //               onSurface: Colors.black,
// // // //             ),
// // // //           ),
// // // //           child: child!,
// // // //         );
// // // //       },
// // // //     );

// // // //     if (picked != null) {
// // // //       setState(() {
// // // //         if (isFrom) {
// // // //           fromDate = picked;
// // // //           if (allowedDays != null && allowedDays > 0) {
// // // //             toDate = fromDate!.add(Duration(days: allowedDays - 1));
// // // //           }
// // // //           errorMessage = null;
// // // //         } else {
// // // //           if (fromDate != null && picked.isBefore(fromDate!)) {
// // // //             errorMessage = "To Date cannot be before From Date";
// // // //           } else {
// // // //             toDate = picked;
// // // //             errorMessage = null;
// // // //           }
// // // //         }
// // // //       });
// // // //     }
// // // //   }

// // // //   String formatDate(DateTime? date) {
// // // //     if (date == null) return '';
// // // //     try {
// // // //       return DateFormat('yyyy-MM-dd').format(date);
// // // //     } catch (e) {
// // // //       return 'Invalid Date';
// // // //     }
// // // //   }

// // // //   // ------------- SUBMIT -> API -------------
// // // //   Future<void> _submit() async {
// // // //     debugPrint('### RequestLeave SUBMIT CLICKED ###');

// // // //     // Validate form
// // // //     if (!(_formKey.currentState?.validate() ?? false)) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text('Please fix the highlighted fields')),
// // // //       );
// // // //       return;
// // // //     }

// // // //     if (fromDate == null || toDate == null) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text('Please pick both From Date and To Date')),
// // // //       );
// // // //       return;
// // // //     }
// // // //     if (toDate!.isBefore(fromDate!)) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text('To Date cannot be before From Date')),
// // // //       );
// // // //       return;
// // // //     }

// // // //     final token = await _getJwt();
// // // //     if (token == null) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(content: Text('Not logged in: missing token')),
// // // //       );
// // // //       return;
// // // //     }

// // // //     final type = _canonicalType(selectedLeaveType);
// // // //     if (type.isEmpty) {
// // // //       ScaffoldMessenger.of(
// // // //         context,
// // // //       ).showSnackBar(const SnackBar(content: Text('Invalid leave type')));
// // // //       return;
// // // //     }

// // // //     // Build payload for backend
// // // //     final startIso = fromDate!.toIso8601String();
// // // //     final endIso = toDate!.toIso8601String();
// // // //     final days = (toDate!.difference(fromDate!).inMilliseconds ~/ 86400000) + 1;

// // // //     final payload = {
// // // //       'type': type,
// // // //       'startDate': startIso,
// // // //       'endDate': endIso,
// // // //       'reason': reasonController.text.trim(),
// // // //       'selectShift': selectedShift,
// // // //       'leaveCount': days, // optional; backend will compute if omitted
// // // //     };

// // // //     final uri = Uri.parse('$apiBase/api/leaves');
// // // //     debugPrint('[RequestLeave] POST $uri');
// // // //     debugPrint('[RequestLeave] payload: $payload');
// // // //     debugPrint('[RequestLeave] token length: ${token.length}');

// // // //     try {
// // // //       final resp = await http.post(
// // // //         uri,
// // // //         headers: {
// // // //           'Content-Type': 'application/json',
// // // //           'Authorization': 'Bearer $token',
// // // //         },
// // // //         body: jsonEncode(payload),
// // // //       );

// // // //       debugPrint('[RequestLeave] status=${resp.statusCode}');
// // // //       debugPrint('[RequestLeave] body=${resp.body}');

// // // //       if (resp.statusCode == 201) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text("Leave request submitted")),
// // // //         );
// // // //         // Reset form
// // // //         _formKey.currentState!.reset();
// // // //         setState(() {
// // // //           selectedLeaveType = null;
// // // //           selectedShift = null;
// // // //           selectedLeaveDuration = null;
// // // //           fromDate = null;
// // // //           toDate = null;
// // // //           errorMessage = null;
// // // //           reasonController.clear();
// // // //           customLeaveController.clear();
// // // //         });
// // // //       } else {
// // // //         final msg = resp.body.isNotEmpty ? resp.body : 'Unexpected error';
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(content: Text('Failed: ${resp.statusCode} $msg')),
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint('[RequestLeave] error: $e');
// // // //       ScaffoldMessenger.of(
// // // //         context,
// // // //       ).showSnackBar(SnackBar(content: Text('Network error: $e')));
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final durationOptions = getLeaveDurationOptions(selectedLeaveType);
// // // //     final casualLeaveTaken = hasCasualLeaveInSameMonth();

// // // //     return Scaffold(
// // // //       body: Container(
// // // //         decoration: const BoxDecoration(
// // // //           gradient: LinearGradient(
// // // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // // //             begin: Alignment.topCenter,
// // // //             end: Alignment.bottomCenter,
// // // //           ),
// // // //         ),
// // // //         child: SafeArea(
// // // //           child: SingleChildScrollView(
// // // //             padding: const EdgeInsets.all(16),
// // // //             child: Form(
// // // //               key: _formKey,
// // // //               child: Column(
// // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // //                 children: [
// // // //                   Container(
// // // //                     width: double.infinity,
// // // //                     padding: const EdgeInsets.symmetric(vertical: 16),
// // // //                     color: kAppBarColor,
// // // //                     child: Row(
// // // //                       children: [
// // // //                         const SizedBox(width: 8),
// // // //                         GestureDetector(
// // // //                           onTap: () => Navigator.pop(context),
// // // //                           child: const Icon(
// // // //                             Icons.arrow_back,
// // // //                             color: Colors.white,
// // // //                           ),
// // // //                         ),
// // // //                         const SizedBox(width: 12),
// // // //                         const Text(
// // // //                           "Apply Leave",
// // // //                           style: TextStyle(
// // // //                             fontSize: 18,
// // // //                             fontWeight: FontWeight.bold,
// // // //                             color: Colors.white,
// // // //                           ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                   const SizedBox(height: 24),

// // // //                   DropdownButtonFormField<String>(
// // // //                     value: selectedLeaveType,
// // // //                     decoration: _inputDecorationWithLabel("Leave Type"),
// // // //                     items: leaveTypes.map((type) {
// // // //                       return DropdownMenuItem(value: type, child: Text(type));
// // // //                     }).toList(),
// // // //                     onChanged: (val) {
// // // //                       setState(() {
// // // //                         selectedLeaveType = val;
// // // //                         selectedLeaveDuration = null;
// // // //                         customLeaveController.clear();
// // // //                       });
// // // //                     },
// // // //                     validator: (val) =>
// // // //                         val == null ? "Please select leave type" : null,
// // // //                   ),
// // // //                   const SizedBox(height: 16),

// // // //                   if (selectedLeaveType != null)
// // // //                     DropdownButtonFormField<String>(
// // // //                       value: selectedLeaveDuration,
// // // //                       decoration: _inputDecorationWithLabel("Leave Duration"),
// // // //                       items: durationOptions.map((d) {
// // // //                         return DropdownMenuItem(value: d, child: Text(d));
// // // //                       }).toList(),
// // // //                       onChanged: (val) {
// // // //                         setState(() {
// // // //                           selectedLeaveDuration = val;
// // // //                           if (val != 'Others') {
// // // //                             customLeaveController.clear();
// // // //                           }
// // // //                         });
// // // //                       },
// // // //                       validator: (val) =>
// // // //                           val == null ? "Select duration" : null,
// // // //                     ),

// // // //                   if (selectedLeaveDuration == 'Others')
// // // //                     Padding(
// // // //                       padding: const EdgeInsets.only(top: 12),
// // // //                       child: TextFormField(
// // // //                         controller: customLeaveController,
// // // //                         keyboardType: TextInputType.number,
// // // //                         decoration: _inputDecorationWithLabel(
// // // //                           "Enter number of days",
// // // //                         ),
// // // //                         onChanged: (_) {
// // // //                           setState(() {
// // // //                             fromDate = null;
// // // //                             toDate = null;
// // // //                           });
// // // //                         },
// // // //                         validator: (val) => val == null || val.isEmpty
// // // //                             ? "Enter custom days"
// // // //                             : null,
// // // //                       ),
// // // //                     ),
// // // //                   const SizedBox(height: 16),

// // // //                   DropdownButtonFormField<String>(
// // // //                     value: selectedShift,
// // // //                     decoration: _inputDecorationWithLabel("Shift"),
// // // //                     items: shifts.map((shift) {
// // // //                       return DropdownMenuItem(value: shift, child: Text(shift));
// // // //                     }).toList(),
// // // //                     onChanged: (val) => setState(() => selectedShift = val),
// // // //                     validator: (val) => val == null ? "Select shift" : null,
// // // //                   ),
// // // //                   if (selectedShift != null)
// // // //                     Padding(
// // // //                       padding: const EdgeInsets.only(top: 8),
// // // //                       child: Text(
// // // //                         "Time: ${shiftTimes[selectedShift]!}",
// // // //                         style: const TextStyle(fontSize: 14),
// // // //                       ),
// // // //                     ),
// // // //                   const SizedBox(height: 16),

// // // //                   GestureDetector(
// // // //                     onTap: () => pickDate(context, true),
// // // //                     child: AbsorbPointer(
// // // //                       child: TextFormField(
// // // //                         decoration: _inputDecorationWithLabel("From Date"),
// // // //                         controller: TextEditingController(
// // // //                           text: formatDate(fromDate),
// // // //                         ),
// // // //                         validator: (val) => val == null || val.isEmpty
// // // //                             ? "Select From Date"
// // // //                             : null,
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                   const SizedBox(height: 16),

// // // //                   GestureDetector(
// // // //                     onTap: () => pickDate(context, false),
// // // //                     child: AbsorbPointer(
// // // //                       child: TextFormField(
// // // //                         decoration: _inputDecorationWithLabel("To Date"),
// // // //                         controller: TextEditingController(
// // // //                           text: formatDate(toDate),
// // // //                         ),
// // // //                         validator: (val) {
// // // //                           if (val == null || val.isEmpty)
// // // //                             return "Select To Date";
// // // //                           if (errorMessage != null) return errorMessage;
// // // //                           return null;
// // // //                         },
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                   if (errorMessage != null)
// // // //                     Padding(
// // // //                       padding: const EdgeInsets.only(top: 8),
// // // //                       child: Text(
// // // //                         errorMessage!,
// // // //                         style: const TextStyle(color: Colors.red),
// // // //                       ),
// // // //                     ),
// // // //                   const SizedBox(height: 16),

// // // //                   TextFormField(
// // // //                     controller: reasonController,
// // // //                     maxLines: 2,
// // // //                     decoration: _inputDecorationWithLabel(
// // // //                       "Reason",
// // // //                     ).copyWith(hintText: "Enter your reason"),
// // // //                     validator: (val) =>
// // // //                         val == null || val.isEmpty ? "Enter reason" : null,
// // // //                   ),
// // // //                   const SizedBox(height: 24),

// // // //                   if (hasCasualLeaveInSameMonth() &&
// // // //                       selectedLeaveType == 'Casual Leave')
// // // //                     Container(
// // // //                       padding: const EdgeInsets.all(12),
// // // //                       margin: const EdgeInsets.only(bottom: 16),
// // // //                       decoration: BoxDecoration(
// // // //                         color: Colors.red.shade50,
// // // //                         borderRadius: BorderRadius.circular(12),
// // // //                         border: Border.all(color: Colors.red),
// // // //                       ),
// // // //                       child: const Text(
// // // //                         "You have already applied for Casual Leave this month.",
// // // //                         style: TextStyle(color: Colors.red),
// // // //                       ),
// // // //                     ),

// // // //                   SizedBox(
// // // //                     width: double.infinity,
// // // //                     height: 44,
// // // //                     child: ElevatedButton(
// // // //                       onPressed: _submit, // ✅ call API-integrated submit
// // // //                       style: ElevatedButton.styleFrom(
// // // //                         backgroundColor: kButtonColor,
// // // //                         shape: RoundedRectangleBorder(
// // // //                           borderRadius: BorderRadius.circular(12),
// // // //                         ),
// // // //                       ),
// // // //                       child: const Text(
// // // //                         "Submit",
// // // //                         style: TextStyle(color: kTextColor),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   InputDecoration _inputDecorationWithLabel(String labelText) {
// // // //     return InputDecoration(
// // // //       floatingLabelBehavior: FloatingLabelBehavior.auto,
// // // //       label: RichText(
// // // //         text: TextSpan(
// // // //           text: labelText,
// // // //           style: const TextStyle(color: Colors.black87, fontSize: 14),
// // // //           children: const [
// // // //             TextSpan(
// // // //               text: ' *',
// // // //               style: TextStyle(color: Colors.red),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //       filled: true,
// // // //       fillColor: Colors.white,
// // // //       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
// // // //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// // // //       enabledBorder: OutlineInputBorder(
// // // //         borderRadius: BorderRadius.circular(12),
// // // //         borderSide: const BorderSide(color: kButtonColor),
// // // //       ),
// // // //       focusedBorder: OutlineInputBorder(
// // // //         borderRadius: BorderRadius.circular(12),
// // // //         borderSide: const BorderSide(color: kAppBarColor, width: 2),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // import 'package:flutter/material.dart';
// // // import 'package:intl/intl.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // // import 'dart:html' as html; // for Flutter Web localStorage

// // // // If you already use a central model to hold the JWT (from your login flow)
// // // import 'package:serv_app/models/company_data.dart'; // <-- adjust path if needed

// // // // Theme Colors
// // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // const Color kButtonColor = Color(0xFF655193);
// // // const Color kTextColor = Colors.white;

// // // /// Match your Node server port
// // // const String apiBase = 'http://localhost:3000';

// // // class RequestLeavePage extends StatefulWidget {
// // //   /// Allow passing a token directly when navigating, if you prefer.
// // //   final String? token;
// // //   const RequestLeavePage({super.key, this.token});

// // //   @override
// // //   State<RequestLeavePage> createState() => _RequestLeavePageState();
// // // }

// // // class _RequestLeavePageState extends State<RequestLeavePage> {
// // //   final _formKey = GlobalKey<FormState>();

// // //   String? selectedLeaveType;
// // //   String? selectedShift;
// // //   String? selectedLeaveDuration;
// // //   DateTime? fromDate;
// // //   DateTime? toDate;
// // //   String? errorMessage;

// // //   final TextEditingController reasonController = TextEditingController();
// // //   final TextEditingController customLeaveController = TextEditingController();

// // //   final List<String> leaveTypes = [
// // //     'Sick Leave',
// // //     'Casual Leave',
// // //     'Planned Leave',
// // //     'Emergency Leave', // will be mapped to a valid backend type
// // //   ];
// // //   final List<String> shifts = ['Shift 1', 'Shift 2', 'Shift 3'];

// // //   final Map<String, String> shiftTimes = {
// // //     'Shift 1': '6:00 AM - 2:00 PM',
// // //     'Shift 2': '8:30 AM - 4:30 PM',
// // //     'Shift 3': '9:00 AM - 5:00 PM',
// // //   };

// // //   // Example: casual taken once in a month rule
// // //   final List<DateTime> appliedCasualLeaves = [DateTime(2025, 7, 10)];

// // //   // ---------- helpers: jwt + mapping ----------
// // //   bool _looksLikeJwt(String v) => RegExp(
// // //     r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$',
// // //   ).hasMatch(v);

// // //   Future<String?> _getJwt() async {
// // //     // 1) From constructor param
// // //     if (widget.token != null && widget.token!.isNotEmpty) {
// // //       debugPrint('[RequestLeave] token from widget (${widget.token!.length})');
// // //       return widget.token;
// // //     }

// // //     // 2) From CompanyData (in-memory, set at login)
// // //     try {
// // //       final t = CompanyData.token; // adjust if your field name differs
// // //       if (t != null && t.isNotEmpty) {
// // //         debugPrint('[RequestLeave] token from CompanyData (${t.length})');
// // //         // Persist to localStorage for web pages that open later
// // //         final exists = html.window.localStorage['token'];
// // //         if (exists == null || exists.isEmpty) {
// // //           html.window.localStorage['token'] = t;
// // //         }
// // //         return t;
// // //       }
// // //     } catch (_) {
// // //       // ignore if CompanyData is unavailable in this target
// // //     }

// // //     // 3) Common localStorage keys
// // //     final keysToTry = ['jwt', 'token', 'access_token', 'auth_token'];
// // //     for (final k in keysToTry) {
// // //       final v = html.window.localStorage[k];
// // //       if (v != null && v.isNotEmpty) {
// // //         debugPrint('[RequestLeave] token from localStorage "$k" (${v.length})');
// // //         return v;
// // //       }
// // //     }

// // //     // 4) Fallback: scan all localStorage values; pick first JWT-looking string
// // //     for (int i = 0; i < html.window.localStorage.length; i++) {
// // //       final key = html.window.localStorage.keys.elementAt(i);
// // //       final val = html.window.localStorage[key];
// // //       if (val != null && _looksLikeJwt(val)) {
// // //         debugPrint(
// // //           '[RequestLeave] token from localStorage "$key" (${val.length})',
// // //         );
// // //         return val;
// // //       }
// // //     }

// // //     debugPrint(
// // //       '[RequestLeave] No token found (CompanyData/widget/localStorage)',
// // //     );
// // //     return null;
// // //   }

// // //   // Backend only accepts: Casual Leave | Planned Leave | Sick Leave (+ others you use elsewhere)
// // //   String _canonicalType(String? t) {
// // //     if (t == null) return '';
// // //     if (t == 'Emergency Leave') return 'Planned Leave';
// // //     return t;
// // //   }

// // //   List<String> getLeaveDurationOptions(String? type) {
// // //     switch (type) {
// // //       case 'Sick Leave':
// // //       case 'Planned Leave':
// // //       case 'Emergency Leave':
// // //         return ['1 day', '2 days', '3 days', 'Others'];
// // //       case 'Casual Leave':
// // //         return ['1 day'];
// // //       default:
// // //         return [];
// // //     }
// // //   }

// // //   bool hasCasualLeaveInSameMonth() {
// // //     if (selectedLeaveType != 'Casual Leave' || fromDate == null) return false;
// // //     return appliedCasualLeaves.any(
// // //       (leave) => leave.month == fromDate!.month && leave.year == fromDate!.year,
// // //     );
// // //   }

// // //   int? _getAllowedDays() {
// // //     if (selectedLeaveDuration == null) return null;
// // //     if (selectedLeaveDuration == 'Others') {
// // //       if (customLeaveController.text.isEmpty) return null;
// // //       return int.tryParse(customLeaveController.text);
// // //     }
// // //     return int.tryParse(selectedLeaveDuration!.split(' ')[0]);
// // //   }

// // //   Future<void> pickDate(BuildContext context, bool isFrom) async {
// // //     int? allowedDays = _getAllowedDays();

// // //     DateTime initialDate = isFrom
// // //         ? DateTime.now()
// // //         : (fromDate ?? DateTime.now());
// // //     DateTime firstDate = isFrom ? DateTime.now() : (fromDate ?? DateTime.now());
// // //     DateTime lastDate;

// // //     if (isFrom) {
// // //       lastDate = DateTime(2100);
// // //     } else {
// // //       if (fromDate != null && allowedDays != null && allowedDays > 0) {
// // //         lastDate = fromDate!.add(Duration(days: allowedDays - 1));
// // //       } else {
// // //         lastDate = DateTime(2100);
// // //       }
// // //     }

// // //     final DateTime? picked = await showDatePicker(
// // //       context: context,
// // //       initialDate: initialDate,
// // //       firstDate: firstDate,
// // //       lastDate: lastDate,
// // //       builder: (context, child) {
// // //         return Theme(
// // //           data: Theme.of(context).copyWith(
// // //             colorScheme: const ColorScheme.light(
// // //               primary: kAppBarColor,
// // //               onPrimary: Colors.white,
// // //               onSurface: Colors.black,
// // //             ),
// // //           ),
// // //           child: child!,
// // //         );
// // //       },
// // //     );

// // //     if (picked != null) {
// // //       setState(() {
// // //         if (isFrom) {
// // //           fromDate = picked;
// // //           if (allowedDays != null && allowedDays > 0) {
// // //             toDate = fromDate!.add(Duration(days: allowedDays - 1));
// // //           }
// // //           errorMessage = null;
// // //         } else {
// // //           if (fromDate != null && picked.isBefore(fromDate!)) {
// // //             errorMessage = "To Date cannot be before From Date";
// // //           } else {
// // //             toDate = picked;
// // //             errorMessage = null;
// // //           }
// // //         }
// // //       });
// // //     }
// // //   }

// // //   String formatDate(DateTime? date) {
// // //     if (date == null) return '';
// // //     try {
// // //       return DateFormat('yyyy-MM-dd').format(date);
// // //     } catch (e) {
// // //       return 'Invalid Date';
// // //     }
// // //   }

// // //   // ------------- SUBMIT -> API -------------
// // //   Future<void> _submit() async {
// // //     debugPrint('### RequestLeave SUBMIT CLICKED ###');

// // //     // Validate form
// // //     if (!(_formKey.currentState?.validate() ?? false)) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Please fix the highlighted fields')),
// // //       );
// // //       return;
// // //     }

// // //     if (fromDate == null || toDate == null) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Please pick both From Date and To Date')),
// // //       );
// // //       return;
// // //     }
// // //     if (toDate!.isBefore(fromDate!)) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('To Date cannot be before From Date')),
// // //       );
// // //       return;
// // //     }

// // //     final token = await _getJwt();
// // //     if (token == null) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Not logged in: missing token')),
// // //       );
// // //       return;
// // //     }

// // //     final type = _canonicalType(selectedLeaveType);
// // //     if (type.isEmpty) {
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(const SnackBar(content: Text('Invalid leave type')));
// // //       return;
// // //     }

// // //     // Build payload for backend
// // //     final startIso = fromDate!.toIso8601String();
// // //     final endIso = toDate!.toIso8601String();
// // //     final days = (toDate!.difference(fromDate!).inMilliseconds ~/ 86400000) + 1;

// // //     final payload = {
// // //       'type': type,
// // //       'startDate': startIso,
// // //       'endDate': endIso,
// // //       'reason': reasonController.text.trim(),
// // //       'selectShift': selectedShift,
// // //       'leaveCount': days, // optional; backend will compute if omitted
// // //     };

// // //     final uri = Uri.parse('$apiBase/api/leaves');
// // //     debugPrint('[RequestLeave] POST $uri');
// // //     debugPrint('[RequestLeave] payload: $payload');
// // //     debugPrint('[RequestLeave] token length: ${token.length}');

// // //     try {
// // //       final resp = await http.post(
// // //         uri,
// // //         headers: {
// // //           'Content-Type': 'application/json',
// // //           'Authorization': 'Bearer $token',
// // //         },
// // //         body: jsonEncode(payload),
// // //       );

// // //       debugPrint('[RequestLeave] status=${resp.statusCode}');
// // //       debugPrint('[RequestLeave] body=${resp.body}');

// // //       if (resp.statusCode == 201) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text("Leave request submitted")),
// // //         );
// // //         // Reset form
// // //         _formKey.currentState!.reset();
// // //         setState(() {
// // //           selectedLeaveType = null;
// // //           selectedShift = null;
// // //           selectedLeaveDuration = null;
// // //           fromDate = null;
// // //           toDate = null;
// // //           errorMessage = null;
// // //           reasonController.clear();
// // //           customLeaveController.clear();
// // //         });
// // //       } else {
// // //         final msg = resp.body.isNotEmpty ? resp.body : 'Unexpected error';
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(content: Text('Failed: ${resp.statusCode} $msg')),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       debugPrint('[RequestLeave] error: $e');
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(SnackBar(content: Text('Network error: $e')));
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final durationOptions = getLeaveDurationOptions(selectedLeaveType);
// // //     final casualLeaveTaken = hasCasualLeaveInSameMonth();

// // //     return Scaffold(
// // //       // ✅ ADDED: ensure no white shows through
// // //       backgroundColor: kPrimaryBackgroundBottom,
// // //       body: Container(
// // //         // ✅ ADDED: force gradient to fill the viewport (removes bottom white space)
// // //         constraints: const BoxConstraints.expand(),
// // //         decoration: const BoxDecoration(
// // //           gradient: LinearGradient(
// // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // //             begin: Alignment.topCenter,
// // //             end: Alignment.bottomCenter,
// // //           ),
// // //         ),
// // //         child: SafeArea(
// // //           child: SingleChildScrollView(
// // //             padding: const EdgeInsets.all(16),
// // //             child: Form(
// // //               key: _formKey,
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Container(
// // //                     width: double.infinity,
// // //                     padding: const EdgeInsets.symmetric(vertical: 16),
// // //                     color: kAppBarColor,
// // //                     child: Row(
// // //                       children: [
// // //                         const SizedBox(width: 8),
// // //                         GestureDetector(
// // //                           onTap: () => Navigator.pop(context),
// // //                           child: const Icon(
// // //                             Icons.arrow_back,
// // //                             color: Colors.white,
// // //                           ),
// // //                         ),
// // //                         const SizedBox(width: 12),
// // //                         const Text(
// // //                           "Apply Leave",
// // //                           style: TextStyle(
// // //                             fontSize: 18,
// // //                             fontWeight: FontWeight.bold,
// // //                             color: Colors.white,
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 24),

// // //                   DropdownButtonFormField<String>(
// // //                     value: selectedLeaveType,
// // //                     decoration: _inputDecorationWithLabel("Leave Type"),
// // //                     items: leaveTypes.map((type) {
// // //                       return DropdownMenuItem(value: type, child: Text(type));
// // //                     }).toList(),
// // //                     onChanged: (val) {
// // //                       setState(() {
// // //                         selectedLeaveType = val;
// // //                         selectedLeaveDuration = null;
// // //                         customLeaveController.clear();
// // //                       });
// // //                     },
// // //                     validator: (val) =>
// // //                         val == null ? "Please select leave type" : null,
// // //                   ),
// // //                   const SizedBox(height: 16),

// // //                   if (selectedLeaveType != null)
// // //                     DropdownButtonFormField<String>(
// // //                       value: selectedLeaveDuration,
// // //                       decoration: _inputDecorationWithLabel("Leave Duration"),
// // //                       items: durationOptions.map((d) {
// // //                         return DropdownMenuItem(value: d, child: Text(d));
// // //                       }).toList(),
// // //                       onChanged: (val) {
// // //                         setState(() {
// // //                           selectedLeaveDuration = val;
// // //                           if (val != 'Others') {
// // //                             customLeaveController.clear();
// // //                           }
// // //                         });
// // //                       },
// // //                       validator: (val) =>
// // //                           val == null ? "Select duration" : null,
// // //                     ),

// // //                   if (selectedLeaveDuration == 'Others')
// // //                     Padding(
// // //                       padding: const EdgeInsets.only(top: 12),
// // //                       child: TextFormField(
// // //                         controller: customLeaveController,
// // //                         keyboardType: TextInputType.number,
// // //                         decoration: _inputDecorationWithLabel(
// // //                           "Enter number of days",
// // //                         ),
// // //                         onChanged: (_) {
// // //                           setState(() {
// // //                             fromDate = null;
// // //                             toDate = null;
// // //                           });
// // //                         },
// // //                         validator: (val) => val == null || val.isEmpty
// // //                             ? "Enter custom days"
// // //                             : null,
// // //                       ),
// // //                     ),
// // //                   const SizedBox(height: 16),

// // //                   DropdownButtonFormField<String>(
// // //                     value: selectedShift,
// // //                     decoration: _inputDecorationWithLabel("Shift"),
// // //                     items: shifts.map((shift) {
// // //                       return DropdownMenuItem(value: shift, child: Text(shift));
// // //                     }).toList(),
// // //                     onChanged: (val) => setState(() => selectedShift = val),
// // //                     validator: (val) => val == null ? "Select shift" : null,
// // //                   ),
// // //                   if (selectedShift != null)
// // //                     Padding(
// // //                       padding: const EdgeInsets.only(top: 8),
// // //                       child: Text(
// // //                         "Time: ${shiftTimes[selectedShift]!}",
// // //                         style: const TextStyle(fontSize: 14),
// // //                       ),
// // //                     ),
// // //                   const SizedBox(height: 16),

// // //                   GestureDetector(
// // //                     onTap: () => pickDate(context, true),
// // //                     child: AbsorbPointer(
// // //                       child: TextFormField(
// // //                         decoration: _inputDecorationWithLabel("From Date"),
// // //                         controller: TextEditingController(
// // //                           text: formatDate(fromDate),
// // //                         ),
// // //                         validator: (val) => val == null || val.isEmpty
// // //                             ? "Select From Date"
// // //                             : null,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 16),

// // //                   GestureDetector(
// // //                     onTap: () => pickDate(context, false),
// // //                     child: AbsorbPointer(
// // //                       child: TextFormField(
// // //                         decoration: _inputDecorationWithLabel("To Date"),
// // //                         controller: TextEditingController(
// // //                           text: formatDate(toDate),
// // //                         ),
// // //                         validator: (val) {
// // //                           if (val == null || val.isEmpty) {
// // //                             return "Select To Date";
// // //                           }
// // //                           if (errorMessage != null) return errorMessage;
// // //                           return null;
// // //                         },
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   if (errorMessage != null)
// // //                     Padding(
// // //                       padding: const EdgeInsets.only(top: 8),
// // //                       child: Text(
// // //                         errorMessage!,
// // //                         style: const TextStyle(color: Colors.red),
// // //                       ),
// // //                     ),
// // //                   const SizedBox(height: 16),

// // //                   TextFormField(
// // //                     controller: reasonController,
// // //                     maxLines: 2,
// // //                     decoration: _inputDecorationWithLabel(
// // //                       "Reason",
// // //                     ).copyWith(hintText: "Enter your reason"),
// // //                     validator: (val) =>
// // //                         val == null || val.isEmpty ? "Enter reason" : null,
// // //                   ),
// // //                   const SizedBox(height: 24),

// // //                   if (hasCasualLeaveInSameMonth() &&
// // //                       selectedLeaveType == 'Casual Leave')
// // //                     Container(
// // //                       padding: const EdgeInsets.all(12),
// // //                       margin: const EdgeInsets.only(bottom: 16),
// // //                       decoration: BoxDecoration(
// // //                         color: Colors.red.shade50,
// // //                         borderRadius: BorderRadius.circular(12),
// // //                         border: Border.all(color: Colors.red),
// // //                       ),
// // //                       child: const Text(
// // //                         "You have already applied for Casual Leave this month.",
// // //                         style: TextStyle(color: Colors.red),
// // //                       ),
// // //                     ),

// // //                   SizedBox(
// // //                     width: double.infinity,
// // //                     height: 44,
// // //                     child: ElevatedButton(
// // //                       onPressed: _submit, // ✅ call API-integrated submit
// // //                       style: ElevatedButton.styleFrom(
// // //                         backgroundColor: kButtonColor,
// // //                         shape: RoundedRectangleBorder(
// // //                           borderRadius: BorderRadius.circular(12),
// // //                         ),
// // //                       ),
// // //                       child: const Text(
// // //                         "Submit",
// // //                         style: TextStyle(color: kTextColor),
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   InputDecoration _inputDecorationWithLabel(String labelText) {
// // //     return InputDecoration(
// // //       floatingLabelBehavior: FloatingLabelBehavior.auto,
// // //       label: RichText(
// // //         text: TextSpan(
// // //           text: labelText,
// // //           style: const TextStyle(color: Colors.black87, fontSize: 14),
// // //           children: const [
// // //             TextSpan(
// // //               text: ' *',
// // //               style: TextStyle(color: Colors.red),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //       filled: true,
// // //       fillColor: Colors.white,
// // //       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
// // //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// // //       enabledBorder: OutlineInputBorder(
// // //         borderRadius: BorderRadius.circular(12),
// // //         borderSide: const BorderSide(color: kButtonColor),
// // //       ),
// // //       focusedBorder: OutlineInputBorder(
// // //         borderRadius: BorderRadius.circular(12),
// // //         borderSide: const BorderSide(color: kAppBarColor, width: 2),
// // //       ),
// // //     );
// // //   }
// // // }
// // // lib/Pagesusers/request_leave_page.dart
// // import 'dart:convert';
// // import 'dart:html' as html; // for Flutter Web localStorage
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:intl/intl.dart';

// // // If you already use a central model to hold the JWT (from your login flow)
// // import 'package:serv_app/models/company_data.dart'; // <-- adjust path if needed

// // // Theme Colors
// // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // const Color kAppBarColor = Color(0xFF8C6EAF);
// // const Color kButtonColor = Color(0xFF655193);
// // const Color kTextColor = Colors.white;

// // /// Match your Node server port
// // const String apiBase = 'http://localhost:3000';

// // /// ---------- Helpers (top-level) ----------
// // bool _looksLikeJwt(String v) =>
// //     RegExp(r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$').hasMatch(v);

// // /// Accepts ISO string or Firestore {_seconds,_nanoseconds}
// // DateTime? _ts(dynamic v) {
// //   try {
// //     if (v == null) return null;
// //     if (v is String) return DateTime.parse(v);
// //     if (v is Map) {
// //       final s = (v['_seconds'] ?? v['seconds']);
// //       final ns = (v['_nanoseconds'] ?? v['nanoseconds']) ?? 0;
// //       if (s is int) {
// //         final ms = s * 1000 + (ns is int ? ns ~/ 1000000 : 0);
// //         return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
// //       }
// //     }
// //   } catch (_) {}
// //   return null;
// // }

// // /// ---------- Model (top-level) ----------
// // class LeaveTypeRule {
// //   final String id;
// //   final String type;        // e.g. "CASUAL LEAVE"
// //   final int allowedDays;    // e.g. 1
// //   final DateTime? fromDate; // clamp start
// //   final DateTime? toDate;   // clamp end
// //   final DateTime? createdAt;
// //   final bool active;
// //   final String? shift;      // present but NOT used to filter

// //   LeaveTypeRule({
// //     required this.id,
// //     required this.type,
// //     required this.allowedDays,
// //     required this.fromDate,
// //     required this.toDate,
// //     required this.createdAt,
// //     required this.active,
// //     required this.shift,
// //   });

// //   factory LeaveTypeRule.fromJson(Map<String, dynamic> j) {
// //     return LeaveTypeRule(
// //       id: (j['id'] ?? '').toString(),
// //       type: (j['type'] ?? '').toString(),
// //       allowedDays: (j['allowedDays'] is num)
// //           ? (j['allowedDays'] as num).toInt()
// //           : int.tryParse('${j['allowedDays'] ?? 0}') ?? 0,
// //       fromDate: _ts(j['fromDate']),
// //       toDate: _ts(j['toDate']),
// //       createdAt: _ts(j['createdAt']),
// //       active: j['active'] != false,
// //       shift: j['shift']?.toString(),
// //     );
// //   }
// // }

// // class RequestLeavePage extends StatefulWidget {
// //   /// Allow passing a token directly when navigating, if you prefer.
// //   final String? token;
// //   const RequestLeavePage({super.key, this.token});

// //   @override
// //   State<RequestLeavePage> createState() => _RequestLeavePageState();
// // }

// // class _RequestLeavePageState extends State<RequestLeavePage> {
// //   final _formKey = GlobalKey<FormState>();

// //   String? selectedLeaveType;
// //   String? selectedShift;
// //   String? selectedLeaveDuration;
// //   DateTime? fromDate;
// //   DateTime? toDate;
// //   String? errorMessage;

// //   final TextEditingController reasonController = TextEditingController();

// //   // Shifts (just view/select; NOT used to filter)
// //   final List<String> shifts = const ['Shift 1', 'Shift 2', 'Shift 3'];
// //   final Map<String, String> shiftTimes = const {
// //     'Shift 1': '6:00 AM - 2:00 PM',
// //     'Shift 2': '8:30 AM - 4:30 PM',
// //     'Shift 3': '9:00 AM - 5:00 PM',
// //   };

// //   // Loaded from API
// //   List<LeaveTypeRule> _rules = [];
// //   List<String> _typeNames = []; // unique type strings for dropdown
// //   LeaveTypeRule? _currentRule;
// //   bool _loadingTypes = false;

// //   /// Pick the most recent active rule for a type
// //   LeaveTypeRule? _latestRuleForType(String type) {
// //     final list = _rules.where((r) => r.active && r.type == type).toList();
// //     if (list.isEmpty) return null;
// //     list.sort((a, b) {
// //       final ca = a.createdAt ?? a.fromDate ?? DateTime.fromMillisecondsSinceEpoch(0);
// //       final cb = b.createdAt ?? b.fromDate ?? DateTime.fromMillisecondsSinceEpoch(0);
// //       return cb.compareTo(ca);
// //     });
// //     return list.first;
// //   }

// //   Future<String?> _getJwt() async {
// //     // 1) From constructor param
// //     if (widget.token != null && widget.token!.isNotEmpty) {
// //       return widget.token;
// //     }

// //     // 2) From CompanyData (in-memory, set at login)
// //     try {
// //       final t = CompanyData.token; // adjust if your field name differs
// //       if (t != null && t.isNotEmpty) {
// //         final exists = html.window.localStorage['token'];
// //         if (exists == null || exists.isEmpty) {
// //           html.window.localStorage['token'] = t;
// //         }
// //         return t;
// //       }
// //     } catch (_) {}

// //     // 3) Common localStorage keys
// //     for (final k in ['jwt', 'token', 'access_token', 'auth_token']) {
// //       final v = html.window.localStorage[k];
// //       if (v != null && v.isNotEmpty) return v;
// //     }

// //     // 4) Fallback: scan all storage values for a JWT-looking string
// //     for (int i = 0; i < html.window.localStorage.length; i++) {
// //       final key = html.window.localStorage.keys.elementAt(i);
// //       final val = html.window.localStorage[key];
// //       if (val != null && _looksLikeJwt(val)) return val;
// //     }
// //     return null;
// //   }

// //   Future<void> _fetchLeaveTypes() async {
// //     setState(() => _loadingTypes = true);
// //     final token = await _getJwt();
// //     if (token == null) {
// //       setState(() => _loadingTypes = false);
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Not logged in: missing token')),
// //       );
// //       return;
// //     }

// //     final uri = Uri.parse('$apiBase/api/leave-types'); // NO shift filter
// //     try {
// //       final resp = await http.get(uri, headers: {
// //         'Authorization': 'Bearer $token',
// //         'Content-Type': 'application/json',
// //       });

// //       if (resp.statusCode == 200) {
// //         final List data = jsonDecode(resp.body) as List;
// //         final rules = data.map((e) => LeaveTypeRule.fromJson(e)).toList();
// //         final names = rules
// //             .where((r) => r.active)
// //             .map((r) => r.type)
// //             .toSet()
// //             .toList();

// //         setState(() {
// //           _rules = rules;
// //           _typeNames = names;
// //           selectedLeaveType = null;
// //           selectedLeaveDuration = null;
// //           fromDate = null;
// //           toDate = null;
// //           errorMessage = null;
// //           _currentRule = null;
// //           _loadingTypes = false;
// //         });
// //       } else {
// //         setState(() => _loadingTypes = false);
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               'No leave types available (status: ${resp.statusCode})',
// //             ),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       setState(() => _loadingTypes = false);
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Network error: $e')),
// //       );
// //     }
// //   }

// //   // Build duration options from the selected rule
// //   List<String> _durationOptionsFromRule() {
// //     if (_currentRule == null) return const [];
// //     final n = _currentRule!.allowedDays;
// //     if (n <= 0) return const [];
// //     return List.generate(n, (i) => '${i + 1} day${i == 0 ? '' : 's'}');
// //   }

// //   int? _getAllowedDaysFromSelection() {
// //     if (selectedLeaveDuration == null) return null;
// //     final n = int.tryParse(selectedLeaveDuration!.split(' ').first);
// //     return n;
// //   }

// //   Future<void> pickDate(BuildContext context, bool isFrom) async {
// //     if (_currentRule == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Select leave type first')),
// //       );
// //       return;
// //     }
// //     final rule = _currentRule!;
// //     final int? allowed = _getAllowedDaysFromSelection();

// //     final DateTime startClamp = rule.fromDate ?? DateTime.now();
// //     final DateTime endClamp = rule.toDate ?? DateTime(2100);

// //     DateTime firstDate = isFrom ? startClamp : (fromDate ?? startClamp);
// //     DateTime lastDate;
// //     if (isFrom) {
// //       lastDate = endClamp;
// //     } else {
// //       final start = fromDate ?? startClamp;
// //       lastDate = endClamp;
// //       if (allowed != null && allowed > 0) {
// //         final maxByAllowed = start.add(Duration(days: allowed - 1));
// //         if (maxByAllowed.isBefore(lastDate)) {
// //           lastDate = maxByAllowed;
// //         }
// //       }
// //     }

// //     final DateTime initialDate =
// //         isFrom ? (fromDate ?? firstDate) : (toDate ?? fromDate ?? firstDate);

// //     final picked = await showDatePicker(
// //       context: context,
// //       initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
// //       firstDate: firstDate,
// //       lastDate: lastDate,
// //       builder: (context, child) {
// //         return Theme(
// //           data: Theme.of(context).copyWith(
// //             colorScheme: const ColorScheme.light(
// //               primary: kAppBarColor,
// //               onPrimary: Colors.white,
// //               onSurface: Colors.black,
// //             ),
// //           ),
// //           child: child!,
// //         );
// //       },
// //     );

// //     if (picked != null) {
// //       setState(() {
// //         if (isFrom) {
// //           fromDate = picked;
// //           if (allowed != null && allowed > 0) {
// //             toDate = fromDate!.add(Duration(days: allowed - 1));
// //             if (rule.toDate != null && toDate!.isAfter(rule.toDate!)) {
// //               toDate = rule.toDate;
// //             }
// //           } else {
// //             toDate = null;
// //           }
// //           errorMessage = null;
// //         } else {
// //           if (fromDate != null && picked.isBefore(fromDate!)) {
// //             errorMessage = "To Date cannot be before From Date";
// //           } else {
// //             toDate = picked;
// //             errorMessage = null;
// //           }
// //         }
// //       });
// //     }
// //   }

// //   String _fmt(DateTime? date) =>
// //       (date == null) ? '' : DateFormat('yyyy-MM-dd').format(date);

// //   // ------------- SUBMIT -> API -------------
// //   Future<void> _submit() async {
// //     if (!(_formKey.currentState?.validate() ?? false)) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Please fix the highlighted fields')),
// //       );
// //       return;
// //     }

// //     if (fromDate == null || toDate == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Please pick both From Date and To Date')),
// //       );
// //       return;
// //     }
// //     if (toDate!.isBefore(fromDate!)) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('To Date cannot be before From Date')),
// //       );
// //       return;
// //     }

// //     final token = await _getJwt();
// //     if (token == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Not logged in: missing token')),
// //       );
// //       return;
// //     }

// //     final days =
// //         (toDate!.difference(fromDate!).inMilliseconds ~/ 86400000) + 1;

// //     final payload = {
// //       'type': selectedLeaveType, // backend expects this
// //       'startDate': fromDate!.toIso8601String(),
// //       'endDate': toDate!.toIso8601String(),
// //       'reason': reasonController.text.trim(),
// //       'selectShift': selectedShift, // just pass through if you want
// //       'leaveCount': days,
// //     };

// //     final uri = Uri.parse('$apiBase/api/leaves');
// //     try {
// //       final resp = await http.post(
// //         uri,
// //         headers: {
// //           'Content-Type': 'application/json',
// //           'Authorization': 'Bearer $token',
// //         },
// //         body: jsonEncode(payload),
// //       );

// //       if (resp.statusCode == 201) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Leave request submitted")),
// //         );
// //         // Reset form
// //         _formKey.currentState!.reset();
// //         setState(() {
// //           selectedLeaveType = null;
// //           selectedShift = null;
// //           selectedLeaveDuration = null;
// //           fromDate = null;
// //           toDate = null;
// //           errorMessage = null;
// //           reasonController.clear();
// //           _currentRule = null;
// //         });
// //       } else {
// //         final msg = resp.body.isNotEmpty ? resp.body : 'Unexpected error';
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Failed: ${resp.statusCode} $msg')),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Network error: $e')),
// //       );
// //     }
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchLeaveTypes(); // load list for the dropdown
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final durationOptions = _durationOptionsFromRule();

// //     return Scaffold(
// //       // keep gradient and UI
// //       backgroundColor: kPrimaryBackgroundBottom,
// //       body: Container(
// //         constraints: const BoxConstraints.expand(),
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //         ),
// //         child: SafeArea(
// //           child: SingleChildScrollView(
// //             padding: const EdgeInsets.all(16),
// //             child: Form(
// //               key: _formKey,
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Container(
// //                     width: double.infinity,
// //                     padding: const EdgeInsets.symmetric(vertical: 16),
// //                     color: kAppBarColor,
// //                     child: Row(
// //                       children: const [
// //                         SizedBox(width: 12),
// //                         Icon(Icons.arrow_back, color: Colors.white),
// //                         SizedBox(width: 12),
// //                         Text(
// //                           "Apply Leave",
// //                           style: TextStyle(
// //                             fontSize: 18,
// //                             fontWeight: FontWeight.bold,
// //                             color: Colors.white,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   const SizedBox(height: 24),

// //                   // Leave Type (from API)
// //                   DropdownButtonFormField<String>(
// //                     value: selectedLeaveType,
// //                     decoration: _inputDecorationWithLabel("Leave Type"),
// //                     items: _typeNames
// //                         .map((t) => DropdownMenuItem(value: t, child: Text(t)))
// //                         .toList(),
// //                     onChanged: (val) {
// //                       setState(() {
// //                         selectedLeaveType = val;
// //                         _currentRule =
// //                             (val == null) ? null : _latestRuleForType(val);
// //                         selectedLeaveDuration = null;
// //                         fromDate = null;
// //                         toDate = null;
// //                         errorMessage = null;
// //                       });
// //                     },
// //                     validator: (val) =>
// //                         val == null ? "Please select leave type" : null,
// //                   ),
// //                   if (_loadingTypes)
// //                     const Padding(
// //                       padding: EdgeInsets.only(top: 8),
// //                       child: Text('Loading leave types...'),
// //                     ),
// //                   const SizedBox(height: 16),

// //                   // Duration (1..allowedDays)
// //                   if (selectedLeaveType != null && _currentRule != null)
// //                     DropdownButtonFormField<String>(
// //                       value: selectedLeaveDuration,
// //                       decoration: _inputDecorationWithLabel("Leave Duration"),
// //                       items: durationOptions
// //                           .map((d) =>
// //                               DropdownMenuItem(value: d, child: Text(d)))
// //                           .toList(),
// //                       onChanged: (val) {
// //                         setState(() {
// //                           selectedLeaveDuration = val;
// //                           fromDate = null;
// //                           toDate = null;
// //                           errorMessage = null;
// //                         });
// //                       },
// //                       validator: (val) => val == null ? "Select duration" : null,
// //                     ),
// //                   const SizedBox(height: 16),

// //                   // Shift (independent)
// //                   DropdownButtonFormField<String>(
// //                     value: selectedShift,
// //                     decoration: _inputDecorationWithLabel("Shift"),
// //                     items: shifts
// //                         .map((shift) =>
// //                             DropdownMenuItem(value: shift, child: Text(shift)))
// //                         .toList(),
// //                     onChanged: (val) => setState(() => selectedShift = val),
// //                     validator: (val) => val == null ? "Select shift" : null,
// //                   ),
// //                   if (selectedShift != null)
// //                     Padding(
// //                       padding: const EdgeInsets.only(top: 8),
// //                       child: Text(
// //                         "Time: ${shiftTimes[selectedShift]!}",
// //                         style: const TextStyle(fontSize: 14),
// //                       ),
// //                     ),
// //                   const SizedBox(height: 16),

// //                   GestureDetector(
// //                     onTap: () => pickDate(context, true),
// //                     child: AbsorbPointer(
// //                       child: TextFormField(
// //                         decoration: _inputDecorationWithLabel("From Date"),
// //                         controller: TextEditingController(text: _fmt(fromDate)),
// //                         validator: (val) =>
// //                             val == null || val.isEmpty ? "Select From Date" : null,
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 16),

// //                   GestureDetector(
// //                     onTap: () => pickDate(context, false),
// //                     child: AbsorbPointer(
// //                       child: TextFormField(
// //                         decoration: _inputDecorationWithLabel("To Date"),
// //                         controller: TextEditingController(text: _fmt(toDate)),
// //                         validator: (val) {
// //                           if (val == null || val.isEmpty) {
// //                             return "Select To Date";
// //                           }
// //                           if (errorMessage != null) return errorMessage;
// //                           return null;
// //                         },
// //                       ),
// //                     ),
// //                   ),
// //                   if (errorMessage != null)
// //                     Padding(
// //                       padding: const EdgeInsets.only(top: 8),
// //                       child: Text(
// //                         errorMessage!,
// //                         style: const TextStyle(color: Colors.red),
// //                       ),
// //                     ),
// //                   const SizedBox(height: 16),

// //                   TextFormField(
// //                     controller: reasonController,
// //                     maxLines: 2,
// //                     decoration: _inputDecorationWithLabel(
// //                       "Reason",
// //                     ).copyWith(hintText: "Enter your reason"),
// //                     validator: (val) =>
// //                         val == null || val.isEmpty ? "Enter reason" : null,
// //                   ),
// //                   const SizedBox(height: 24),

// //                   SizedBox(
// //                     width: double.infinity,
// //                     height: 44,
// //                     child: ElevatedButton(
// //                       onPressed: _submit,
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: kButtonColor,
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                         ),
// //                       ),
// //                       child: const Text(
// //                         "Submit",
// //                         style: TextStyle(color: kTextColor),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   InputDecoration _inputDecorationWithLabel(String labelText) {
// //     return InputDecoration(
// //       floatingLabelBehavior: FloatingLabelBehavior.auto,
// //       label: RichText(
// //         text: TextSpan(
// //           text: labelText,
// //           style: const TextStyle(color: Colors.black87, fontSize: 14),
// //           children: const [
// //             TextSpan(
// //               text: ' *',
// //               style: TextStyle(color: Colors.red),
// //             ),
// //           ],
// //         ),
// //       ),
// //       filled: true,
// //       fillColor: Colors.white,
// //       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
// //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// //       enabledBorder: const OutlineInputBorder(
// //         borderSide: BorderSide(color: kButtonColor),
// //       ),
// //       focusedBorder: const OutlineInputBorder(
// //         borderSide: BorderSide(color: kAppBarColor, width: 2),
// //       ),
// //     );
// //   }
// // }
// // lib/Pagesusers/request_leave_page.dart
// import 'dart:convert';
// import 'dart:html' as html; // for Flutter Web localStorage
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

// import 'package:serv_app/models/company_data.dart'; // adjust if needed

// // Theme Colors
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// // Backend base
// const String apiBase = 'http://localhost:3000';

// bool _looksLikeJwt(String v) =>
//     RegExp(r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$').hasMatch(v);

// // Accepts ISO or Firestore {_seconds,_nanoseconds}
// DateTime? _ts(dynamic v) {
//   try {
//     if (v == null) return null;
//     if (v is String) return DateTime.parse(v);
//     if (v is Map) {
//       final s = (v['_seconds'] ?? v['seconds']);
//       final ns = (v['_nanoseconds'] ?? v['nanoseconds']) ?? 0;
//       if (s is int) {
//         final ms = s * 1000 + (ns is int ? ns ~/ 1000000 : 0);
//         return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
//       }
//     }
//   } catch (_) {}
//   return null;
// }

// // ---------- Model ----------
// class LeaveTypeRule {
//   final String id;
//   final String type;        // e.g. "CASUAL LEAVE"
//   final int allowedDays;    // e.g. 1
//   final DateTime? fromDate; // clamp start
//   final DateTime? toDate;   // clamp end
//   final DateTime? createdAt;
//   final bool active;
//   final String? shift;

//   LeaveTypeRule({
//     required this.id,
//     required this.type,
//     required this.allowedDays,
//     required this.fromDate,
//     required this.toDate,
//     required this.createdAt,
//     required this.active,
//     required this.shift,
//   });

//   factory LeaveTypeRule.fromJson(Map<String, dynamic> j) {
//     return LeaveTypeRule(
//       id: (j['id'] ?? '').toString(),
//       type: (j['type'] ?? '').toString(),
//       allowedDays: (j['allowedDays'] is num)
//           ? (j['allowedDays'] as num).toInt()
//           : int.tryParse('${j['allowedDays'] ?? 0}') ?? 0,
//       fromDate: _ts(j['fromDate']),
//       toDate: _ts(j['toDate']),
//       createdAt: _ts(j['createdAt']),
//       active: j['active'] != false,
//       shift: j['shift']?.toString(),
//     );
//   }
// }

// class RequestLeavePage extends StatefulWidget {
//   final String? token;
//   const RequestLeavePage({super.key, this.token});

//   @override
//   State<RequestLeavePage> createState() => _RequestLeavePageState();
// }

// class _RequestLeavePageState extends State<RequestLeavePage> {
//   final _formKey = GlobalKey<FormState>();

//   String? selectedLeaveType;
//   String? selectedShift;
//   String? selectedLeaveDuration;
//   DateTime? fromDate;
//   DateTime? toDate;
//   String? errorMessage;

//   final TextEditingController reasonController = TextEditingController();

//   // Shifts (display only; NOT used to filter)
//   final List<String> shifts = const ['Shift 1', 'Shift 2', 'Shift 3'];
//   final Map<String, String> shiftTimes = const {
//     'Shift 1': '6:00 AM - 2:00 PM',
//     'Shift 2': '8:30 AM - 4:30 PM',
//     'Shift 3': '9:00 AM - 5:00 PM',
//   };

//   // Loaded from API
//   List<LeaveTypeRule> _rules = [];
//   List<String> _typeNames = []; // unique type strings from DB
//   LeaveTypeRule? _currentRule;
//   bool _loadingTypes = false;

//   LeaveTypeRule? _latestRuleForType(String type) {
//     final list = _rules.where((r) => r.active && r.type == type).toList();
//     if (list.isEmpty) return null;
//     list.sort((a, b) {
//       final ca = a.createdAt ?? a.fromDate ?? DateTime.fromMillisecondsSinceEpoch(0);
//       final cb = b.createdAt ?? b.fromDate ?? DateTime.fromMillisecondsSinceEpoch(0);
//       return cb.compareTo(ca);
//     });
//     return list.first;
//   }

//   Future<String?> _getJwt() async {
//     if (widget.token != null && widget.token!.isNotEmpty) return widget.token;

//     try {
//       final t = CompanyData.token;
//       if (t != null && t.isNotEmpty) {
//         final exists = html.window.localStorage['token'];
//         if (exists == null || exists.isEmpty) {
//           html.window.localStorage['token'] = t;
//         }
//         return t;
//       }
//     } catch (_) {}

//     for (final k in ['jwt', 'token', 'access_token', 'auth_token']) {
//       final v = html.window.localStorage[k];
//       if (v != null && v.isNotEmpty) return v;
//     }
//     for (int i = 0; i < html.window.localStorage.length; i++) {
//       final key = html.window.localStorage.keys.elementAt(i);
//       final val = html.window.localStorage[key];
//       if (val != null && _looksLikeJwt(val)) return val;
//     }
//     return null;
//   }

//   Future<void> _fetchLeaveTypes() async {
//     setState(() => _loadingTypes = true);
//     final token = await _getJwt();
//     if (token == null) {
//       setState(() => _loadingTypes = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Not logged in: missing token')),
//       );
//       return;
//     }

//     final uri = Uri.parse('$apiBase/api/leave-types'); // no shift filter
//     try {
//       final resp = await http.get(uri, headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       });

//       if (resp.statusCode == 200) {
//         final List data = jsonDecode(resp.body) as List;
//         final rules = data.map((e) => LeaveTypeRule.fromJson(e)).toList();
//         final names = rules.where((r) => r.active).map((r) => r.type).toSet().toList();

//         setState(() {
//           _rules = rules;
//           _typeNames = names;
//           selectedLeaveType = null;
//           selectedLeaveDuration = null;
//           fromDate = null;
//           toDate = null;
//           errorMessage = null;
//           _currentRule = null;
//           _loadingTypes = false;
//         });
//       } else {
//         setState(() => _loadingTypes = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('No leave types available (status: ${resp.statusCode})')),
//         );
//       }
//     } catch (e) {
//       setState(() => _loadingTypes = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Network error: $e')),
//       );
//     }
//   }

//   List<String> _durationOptionsFromRule() {
//     if (_currentRule == null) return const [];
//     final n = _currentRule!.allowedDays;
//     if (n <= 0) return const [];
//     return List.generate(n, (i) => '${i + 1} day${i == 0 ? '' : 's'}');
//   }

//   int? _getAllowedDaysFromSelection() {
//     if (selectedLeaveDuration == null) return null;
//     return int.tryParse(selectedLeaveDuration!.split(' ').first);
//   }

//   Future<void> pickDate(BuildContext context, bool isFrom) async {
//     if (_currentRule == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Select leave type first')),
//       );
//       return;
//     }
//     final rule = _currentRule!;
//     final int? allowed = _getAllowedDaysFromSelection();

//     final DateTime startClamp = rule.fromDate ?? DateTime.now();
//     final DateTime endClamp = rule.toDate ?? DateTime(2100);

//     DateTime firstDate = isFrom ? startClamp : (fromDate ?? startClamp);
//     DateTime lastDate;
//     if (isFrom) {
//       lastDate = endClamp;
//     } else {
//       final start = fromDate ?? startClamp;
//       lastDate = endClamp;
//       if (allowed != null && allowed > 0) {
//         final maxByAllowed = start.add(Duration(days: allowed - 1));
//         if (maxByAllowed.isBefore(lastDate)) {
//           lastDate = maxByAllowed;
//         }
//       }
//     }

//     final DateTime initialDate =
//         isFrom ? (fromDate ?? firstDate) : (toDate ?? fromDate ?? firstDate);

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
//       firstDate: firstDate,
//       lastDate: lastDate,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: kAppBarColor,
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         if (isFrom) {
//           fromDate = picked;
//           if (allowed != null && allowed > 0) {
//             toDate = fromDate!.add(Duration(days: allowed - 1));
//             if (rule.toDate != null && toDate!.isAfter(rule.toDate!)) {
//               toDate = rule.toDate;
//             }
//           } else {
//             toDate = null;
//           }
//           errorMessage = null;
//         } else {
//           if (fromDate != null && picked.isBefore(fromDate!)) {
//             errorMessage = "To Date cannot be before From Date";
//           } else {
//             toDate = picked;
//             errorMessage = null;
//           }
//         }
//       });
//     }
//   }

//   String _fmt(DateTime? date) =>
//       (date == null) ? '' : DateFormat('yyyy-MM-dd').format(date);

//   // --------- NEW: canonicalize type for backend ---------
//   String _toTitleCase(String s) {
//     return s
//         .trim()
//         .split(RegExp(r'\s+'))
//         .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
//         .join(' ');
//   }

//   String _canonicalTypeForSubmit(String? t) {
//     if (t == null || t.trim().isEmpty) return '';
//     final base = _toTitleCase(t); // e.g. "CASUAL LEAVE" -> "Casual Leave"
//     // If you also treat "Emergency Leave" as "Planned Leave", keep this:
//     if (base == 'Emergency Leave') return 'Planned Leave';
//     return base;
//   }
//   // ------------------------------------------------------

//   Future<void> _submit() async {
//     if (!(_formKey.currentState?.validate() ?? false)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fix the highlighted fields')),
//       );
//       return;
//     }
//     if (fromDate == null || toDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please pick both From Date and To Date')),
//       );
//       return;
//     }
//     if (toDate!.isBefore(fromDate!)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('To Date cannot be before From Date')),
//       );
//       return;
//     }

//     final token = await _getJwt();
//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Not logged in: missing token')),
//       );
//       return;
//     }

//     final typeForSubmit = _canonicalTypeForSubmit(selectedLeaveType);
//     if (typeForSubmit.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Invalid leave type')),
//       );
//       return;
//     }

//     final days =
//         (toDate!.difference(fromDate!).inMilliseconds ~/ 86400000) + 1;

//     final payload = {
//       'type': typeForSubmit, // <— canonicalized for backend
//       'startDate': fromDate!.toIso8601String(),
//       'endDate': toDate!.toIso8601String(),
//       'reason': reasonController.text.trim(),
//       'selectShift': selectedShift,
//       'leaveCount': days,
//     };

//     final uri = Uri.parse('$apiBase/api/leaves');
//     try {
//       final resp = await http.post(
//         uri,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(payload),
//       );

//       if (resp.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Leave request submitted")),
//         );
//         _formKey.currentState!.reset();
//         setState(() {
//           selectedLeaveType = null;
//           selectedShift = null;
//           selectedLeaveDuration = null;
//           fromDate = null;
//           toDate = null;
//           errorMessage = null;
//           reasonController.clear();
//           _currentRule = null;
//         });
//       } else {
//         final msg = resp.body.isNotEmpty ? resp.body : 'Unexpected error';
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed: ${resp.statusCode} $msg')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Network error: $e')),
//       );
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fetchLeaveTypes();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final durationOptions = _durationOptionsFromRule();

//     return Scaffold(
//       backgroundColor: kPrimaryBackgroundBottom,
//       body: Container(
//         constraints: const BoxConstraints.expand(),
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     color: kAppBarColor,
//                     child: Row(
//                       children: const [
//                         SizedBox(width: 12),
//                         Icon(Icons.arrow_back, color: Colors.white),
//                         SizedBox(width: 12),
//                         Text(
//                           "Apply Leave",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Leave Type (from API)
//                   DropdownButtonFormField<String>(
//                     value: selectedLeaveType,
//                     decoration: _inputDecorationWithLabel("Leave Type"),
//                     items: _typeNames
//                         .map((t) => DropdownMenuItem(value: t, child: Text(t)))
//                         .toList(),
//                     onChanged: (val) {
//                       setState(() {
//                         selectedLeaveType = val;
//                         _currentRule = (val == null) ? null : _latestRuleForType(val);
//                         selectedLeaveDuration = null;
//                         fromDate = null;
//                         toDate = null;
//                         errorMessage = null;
//                       });
//                     },
//                     validator: (val) =>
//                         val == null ? "Please select leave type" : null,
//                   ),
//                   if (_loadingTypes)
//                     const Padding(
//                       padding: EdgeInsets.only(top: 8),
//                       child: Text('Loading leave types...'),
//                     ),
//                   const SizedBox(height: 16),

//                   if (selectedLeaveType != null && _currentRule != null)
//                     DropdownButtonFormField<String>(
//                       value: selectedLeaveDuration,
//                       decoration: _inputDecorationWithLabel("Leave Duration"),
//                       items: durationOptions
//                           .map((d) =>
//                               DropdownMenuItem(value: d, child: Text(d)))
//                           .toList(),
//                       onChanged: (val) {
//                         setState(() {
//                           selectedLeaveDuration = val;
//                           fromDate = null;
//                           toDate = null;
//                           errorMessage = null;
//                         });
//                       },
//                       validator: (val) => val == null ? "Select duration" : null,
//                     ),
//                   const SizedBox(height: 16),

//                   DropdownButtonFormField<String>(
//                     value: selectedShift,
//                     decoration: _inputDecorationWithLabel("Shift"),
//                     items: shifts
//                         .map((shift) =>
//                             DropdownMenuItem(value: shift, child: Text(shift)))
//                         .toList(),
//                     onChanged: (val) => setState(() => selectedShift = val),
//                     validator: (val) => val == null ? "Select shift" : null,
//                   ),
//                   if (selectedShift != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8),
//                       child: Text(
//                         "Time: ${shiftTimes[selectedShift]!}",
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   const SizedBox(height: 16),

//                   GestureDetector(
//                     onTap: () => pickDate(context, true),
//                     child: AbsorbPointer(
//                       child: TextFormField(
//                         decoration: _inputDecorationWithLabel("From Date"),
//                         controller: TextEditingController(text: _fmt(fromDate)),
//                         validator: (val) =>
//                             val == null || val.isEmpty ? "Select From Date" : null,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   GestureDetector(
//                     onTap: () => pickDate(context, false),
//                     child: AbsorbPointer(
//                       child: TextFormField(
//                         decoration: _inputDecorationWithLabel("To Date"),
//                         controller: TextEditingController(text: _fmt(toDate)),
//                         validator: (val) {
//                           if (val == null || val.isEmpty) return "Select To Date";
//                           if (errorMessage != null) return errorMessage;
//                           return null;
//                         },
//                       ),
//                     ),
//                   ),
//                   if (errorMessage != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8),
//                       child: Text(
//                         errorMessage!,
//                         style: const TextStyle(color: Colors.red),
//                       ),
//                     ),
//                   const SizedBox(height: 16),

//                   TextFormField(
//                     controller: reasonController,
//                     maxLines: 2,
//                     decoration: _inputDecorationWithLabel("Reason")
//                         .copyWith(hintText: "Enter your reason"),
//                     validator: (val) =>
//                         val == null || val.isEmpty ? "Enter reason" : null,
//                   ),
//                   const SizedBox(height: 24),

//                   SizedBox(
//                     width: double.infinity,
//                     height: 44,
//                     child: ElevatedButton(
//                       onPressed: _submit,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: kButtonColor,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text("Submit", style: TextStyle(color: kTextColor)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   InputDecoration _inputDecorationWithLabel(String labelText) {
//     return InputDecoration(
//       floatingLabelBehavior: FloatingLabelBehavior.auto,
//       label: RichText(
//         text: TextSpan(
//           text: labelText,
//           style: const TextStyle(color: Colors.black87, fontSize: 14),
//           children: const [
//             TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
//           ],
//         ),
//       ),
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       enabledBorder: const OutlineInputBorder(
//         borderSide: BorderSide(color: kButtonColor),
//       ),
//       focusedBorder: const OutlineInputBorder(
//         borderSide: BorderSide(color: kAppBarColor, width: 2),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:serv_app/html_stub.dart'
  if (dart.library.html) 'package:serv_app/html_web.dart' as html;// for Flutter Web localStorage
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:serv_app/models/company_data.dart'; // adjust if needed

// Theme Colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// Backend base
const String apiBase = 'http://localhost:3000';

bool _looksLikeJwt(String v) =>
    RegExp(r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$').hasMatch(v);

// Accepts ISO or Firestore {_seconds,_nanoseconds}
DateTime? _ts(dynamic v) {
  try {
    if (v == null) return null;
    if (v is String) return DateTime.parse(v);
    if (v is Map) {
      final s = (v['_seconds'] ?? v['seconds']);
      final ns = (v['_nanoseconds'] ?? v['nanoseconds']) ?? 0;
      if (s is int) {
        final ms = s * 1000 + (ns is int ? ns ~/ 1000000 : 0);
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      }
    }
  } catch (_) {}
  return null;
}

// ---------- Model ----------
class LeaveTypeRule {
  final String id;
  final String type;        // e.g. "CASUAL LEAVE" or "sickleave"
  final int allowedDays;    // e.g. 1
  final DateTime? fromDate; // clamp start
  final DateTime? toDate;   // clamp end
  final DateTime? createdAt;
  final bool active;
  final String? shift;

  LeaveTypeRule({
    required this.id,
    required this.type,
    required this.allowedDays,
    required this.fromDate,
    required this.toDate,
    required this.createdAt,
    required this.active,
    required this.shift,
  });

  factory LeaveTypeRule.fromJson(Map<String, dynamic> j) {
    return LeaveTypeRule(
      id: (j['id'] ?? '').toString(),
      type: (j['type'] ?? '').toString(),
      allowedDays: (j['allowedDays'] is num)
          ? (j['allowedDays'] as num).toInt()
          : int.tryParse('${j['allowedDays'] ?? 0}') ?? 0,
      fromDate: _ts(j['fromDate']),
      toDate: _ts(j['toDate']),
      createdAt: _ts(j['createdAt']),
      active: j['active'] != false,
      shift: j['shift']?.toString(),
    );
  }
}

class RequestLeavePage extends StatefulWidget {
  final String? token;
  const RequestLeavePage({super.key, this.token});

  @override
  State<RequestLeavePage> createState() => _RequestLeavePageState();
}

class _RequestLeavePageState extends State<RequestLeavePage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedLeaveType;
  String? selectedShift;
  String? selectedLeaveDuration;
  DateTime? fromDate;
  DateTime? toDate;
  String? errorMessage;

  final TextEditingController reasonController = TextEditingController();

  // Shifts (display only; NOT used to filter)
  final List<String> shifts = const ['Shift 1', 'Shift 2', 'Shift 3'];
  final Map<String, String> shiftTimes = const {
    'Shift 1': '6:00 AM - 2:00 PM',
    'Shift 2': '8:30 AM - 4:30 PM',
    'Shift 3': '9:00 AM - 5:00 PM',
  };

  // Loaded from API
  List<LeaveTypeRule> _rules = [];
  List<String> _typeNames = []; // unique type strings from DB
  LeaveTypeRule? _currentRule;
  bool _loadingTypes = false;

  LeaveTypeRule? _latestRuleForType(String type) {
    final list = _rules.where((r) => r.active && r.type == type).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) {
      final ca = a.createdAt ?? a.fromDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cb = b.createdAt ?? b.fromDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return cb.compareTo(ca);
    });
    return list.first;
  }

  Future<String?> _getJwt() async {
    if (widget.token != null && widget.token!.isNotEmpty) return widget.token;

    try {
      final t = CompanyData.token;
      if (t != null && t.isNotEmpty) {
        final exists = html.window.localStorage['token'];
        if (exists == null || exists.isEmpty) {
          html.window.localStorage['token'] = t;
        }
        return t;
      }
    } catch (_) {}

    for (final k in ['jwt', 'token', 'access_token', 'auth_token']) {
      final v = html.window.localStorage[k];
      if (v != null && v.isNotEmpty) return v;
    }
    for (int i = 0; i < html.window.localStorage.length; i++) {
      final key = html.window.localStorage.keys.elementAt(i);
      final val = html.window.localStorage[key];
      if (val != null && _looksLikeJwt(val)) return val;
    }
    return null;
  }

  Future<void> _fetchLeaveTypes() async {
    setState(() => _loadingTypes = true);
    final token = await _getJwt();
    if (token == null) {
      setState(() => _loadingTypes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in: missing token')),
      );
      return;
    }

    final uri = Uri.parse('$apiBase/api/leave-types'); // no shift filter
    try {
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body) as List;
        final rules = data.map((e) => LeaveTypeRule.fromJson(e)).toList();
        final names = rules.where((r) => r.active).map((r) => r.type).toSet().toList();

        setState(() {
          _rules = rules;
          _typeNames = names;
          selectedLeaveType = null;
          selectedLeaveDuration = null;
          fromDate = null;
          toDate = null;
          errorMessage = null;
          _currentRule = null;
          _loadingTypes = false;
        });
      } else {
        setState(() => _loadingTypes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No leave types available (status: ${resp.statusCode})')),
        );
      }
    } catch (e) {
      setState(() => _loadingTypes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  List<String> _durationOptionsFromRule() {
    if (_currentRule == null) return const [];
    final n = _currentRule!.allowedDays;
    if (n <= 0) return const [];
    return List.generate(n, (i) => '${i + 1} day${i == 0 ? '' : 's'}');
  }

  int? _getAllowedDaysFromSelection() {
    if (selectedLeaveDuration == null) return null;
    return int.tryParse(selectedLeaveDuration!.split(' ').first);
  }

  Future<void> pickDate(BuildContext context, bool isFrom) async {
    if (_currentRule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select leave type first')),
      );
      return;
    }
    final rule = _currentRule!;
    final int? allowed = _getAllowedDaysFromSelection();

    final DateTime startClamp = rule.fromDate ?? DateTime.now();
    final DateTime endClamp = rule.toDate ?? DateTime(2100);

    DateTime firstDate = isFrom ? startClamp : (fromDate ?? startClamp);
    DateTime lastDate;
    if (isFrom) {
      lastDate = endClamp;
    } else {
      final start = fromDate ?? startClamp;
      lastDate = endClamp;
      if (allowed != null && allowed > 0) {
        final maxByAllowed = start.add(Duration(days: allowed - 1));
        if (maxByAllowed.isBefore(lastDate)) {
          lastDate = maxByAllowed;
        }
      }
    }

    final DateTime initialDate =
        isFrom ? (fromDate ?? firstDate) : (toDate ?? fromDate ?? firstDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kAppBarColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
          if (allowed != null && allowed > 0) {
            toDate = fromDate!.add(Duration(days: allowed - 1));
            if (rule.toDate != null && toDate!.isAfter(rule.toDate!)) {
              toDate = rule.toDate;
            }
          } else {
            toDate = null;
          }
          errorMessage = null;
        } else {
          if (fromDate != null && picked.isBefore(fromDate!)) {
            errorMessage = "To Date cannot be before From Date";
          } else {
            toDate = picked;
            errorMessage = null;
          }
        }
      });
    }
  }

  String _fmt(DateTime? date) =>
      (date == null) ? '' : DateFormat('yyyy-MM-dd').format(date);

  // ---------- canonicalize type for backend ----------
  String _toTitleCase(String s) {
    return s
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  // Normalizes whatever admin stored to the backend's accepted values.
  String _canonicalTypeForSubmit(String? t) {
    if (t == null || t.trim().isEmpty) return '';
    final norm = t.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''); // remove spaces/_ etc.

    switch (norm) {
      case 'casualleave':
      case 'casual':
        return 'Casual Leave';
      case 'sickleave':
      case 'sick':
        return 'Sick Leave';
      case 'plannedleave':
      case 'planned':
        return 'Planned Leave';
      case 'emergencyleave':
      case 'emergency':
        // your earlier rule maps Emergency -> Planned
        return 'Planned Leave';
      default:
        // fallback: title-case whatever is shown (works for "CASUAL LEAVE")
        return _toTitleCase(t);
    }
  }
  // ---------------------------------------------------

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields')),
      );
      return;
    }
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick both From Date and To Date')),
      );
      return;
    }
    if (toDate!.isBefore(fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To Date cannot be before From Date')),
      );
      return;
    }

    final token = await _getJwt();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in: missing token')),
      );
      return;
    }

    final typeForSubmit = _canonicalTypeForSubmit(selectedLeaveType);
    if (typeForSubmit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid leave type')),
      );
      return;
    }

    final days =
        (toDate!.difference(fromDate!).inMilliseconds ~/ 86400000) + 1;

    final payload = {
      'type': typeForSubmit,
      'startDate': fromDate!.toIso8601String(),
      'endDate': toDate!.toIso8601String(),
      'reason': reasonController.text.trim(),
      'selectShift': selectedShift,
      'leaveCount': days,
    };

    final uri = Uri.parse('$apiBase/api/leaves');
    try {
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Leave request submitted")),
        );
        _formKey.currentState!.reset();
        setState(() {
          selectedLeaveType = null;
          selectedShift = null;
          selectedLeaveDuration = null;
          fromDate = null;
          toDate = null;
          errorMessage = null;
          reasonController.clear();
          _currentRule = null;
        });
      } else {
        final msg = resp.body.isNotEmpty ? resp.body : 'Unexpected error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${resp.statusCode} $msg')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLeaveTypes();
  }

  @override
  Widget build(BuildContext context) {
    final durationOptions = _durationOptionsFromRule();

    return Scaffold(
      backgroundColor: kPrimaryBackgroundBottom,
      body: Container(
        constraints: const BoxConstraints.expand(),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: kAppBarColor,
                    child: Row(
                      children: const [
                        SizedBox(width: 12),
                        Icon(Icons.arrow_back, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          "Apply Leave",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Leave Type (from API)
                  DropdownButtonFormField<String>(
                    initialValue: selectedLeaveType,
                    decoration: _inputDecorationWithLabel("Leave Type"),
                    items: _typeNames
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedLeaveType = val;
                        _currentRule = (val == null) ? null : _latestRuleForType(val);
                        selectedLeaveDuration = null;
                        fromDate = null;
                        toDate = null;
                        errorMessage = null;
                      });
                    },
                    validator: (val) =>
                        val == null ? "Please select leave type" : null,
                  ),
                  if (_loadingTypes)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Loading leave types...'),
                    ),
                  const SizedBox(height: 16),

                  if (selectedLeaveType != null && _currentRule != null)
                    DropdownButtonFormField<String>(
                      initialValue: selectedLeaveDuration,
                      decoration: _inputDecorationWithLabel("Leave Duration"),
                      items: durationOptions
                          .map((d) =>
                              DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedLeaveDuration = val;
                          fromDate = null;
                          toDate = null;
                          errorMessage = null;
                        });
                      },
                      validator: (val) => val == null ? "Select duration" : null,
                    ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: selectedShift,
                    decoration: _inputDecorationWithLabel("Shift"),
                    items: shifts
                        .map((shift) =>
                            DropdownMenuItem(value: shift, child: Text(shift)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedShift = val),
                    validator: (val) => val == null ? "Select shift" : null,
                  ),
                  if (selectedShift != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Time: ${shiftTimes[selectedShift]!}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => pickDate(context, true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _inputDecorationWithLabel("From Date"),
                        controller: TextEditingController(text: _fmt(fromDate)),
                        validator: (val) =>
                            val == null || val.isEmpty ? "Select From Date" : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => pickDate(context, false),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _inputDecorationWithLabel("To Date"),
                        controller: TextEditingController(text: _fmt(toDate)),
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Select To Date";
                          if (errorMessage != null) return errorMessage!;
                          return null;
                        },
                      ),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: _inputDecorationWithLabel("Reason")
                        .copyWith(hintText: "Enter your reason"),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter reason" : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Submit", style: TextStyle(color: kTextColor)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecorationWithLabel(String labelText) {
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      label: RichText(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: const [
            TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: kButtonColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: kAppBarColor, width: 2),
      ),
    );
  }
}
