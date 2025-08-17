// // // import 'package:flutter/material.dart';
// // // import 'package:intl/intl.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';

// // // // 🎨 Your Color Constants
// // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // const Color kButtonColor = Color(0xFF655193);
// // // const Color kTextColor = Colors.white;

// // // class ApplyHalfDayForm extends StatefulWidget {
// // //   const ApplyHalfDayForm({super.key});

// // //   @override
// // //   State<ApplyHalfDayForm> createState() => _ApplyHalfDayFormState();
// // // }

// // // class _ApplyHalfDayFormState extends State<ApplyHalfDayForm> {
// // //   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

// // //   String? selectedShift;
// // //   DateTime? fromDate;
// // //   DateTime? replaceWorkDate;
// // //   final TextEditingController reasonController = TextEditingController();

// // //   final List<String> shifts = ['Shift 1', 'Shift 2', 'Shift 3'];

// // //   Future<void> _pickDate(bool isFromDate) async {
// // //     final picked = await showDatePicker(
// // //       context: context,
// // //       initialDate: DateTime.now(),
// // //       firstDate: DateTime.now(),
// // //       lastDate: DateTime(2101),
// // //     );
// // //     if (picked != null) {
// // //       setState(() {
// // //         if (isFromDate) {
// // //           fromDate = picked;
// // //         } else {
// // //           replaceWorkDate = picked;
// // //         }
// // //       });
// // //     }
// // //   }

// // //   Future<void> _submitForm() async {
// // //     if (_formKey.currentState?.validate() != true) return;

// // //     if (fromDate == null || replaceWorkDate == null) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('⚠️ Please select both dates')),
// // //       );
// // //       return;
// // //     }

// // //     final url = Uri.parse('http://localhost:3000/api/apply-compoff');

// // //     final response = await http.post(
// // //       url,
// // //       headers: {'Content-Type': 'application/json'},
// // //       body: jsonEncode({
// // //         'shift': selectedShift,
// // //         'workedDate': DateFormat('yyyy-MM-dd').format(fromDate!),
// // //         'alternateLeaveDate': DateFormat('yyyy-MM-dd').format(replaceWorkDate!),
// // //         'reason': reasonController.text.trim(),
// // //       }),
// // //     );

// // //     if (response.statusCode == 200) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('CompOff Request Submitted Successfully')),
// // //       );
// // //       setState(() {
// // //         selectedShift = null;
// // //         fromDate = null;
// // //         replaceWorkDate = null;
// // //         reasonController.clear();
// // //       });
// // //     } else {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('❌ Submission Failed: ${response.body}')),
// // //       );
// // //     }
// // //   }

// // //   InputDecoration buildInputDecoration(String label, {bool isRequired = false}) {
// // //     return InputDecoration(
// // //     filled: true,
// // //     fillColor: Colors.white, // 👈 This line sets white background
// // //       label: RichText(
// // //         text: TextSpan(
// // //           text: label,
// // //           style: const TextStyle(
// // //             color: Colors.black,
// // //             fontSize: 16,
// // //           ),
// // //           children: isRequired
// // //               ? const [
// // //                   TextSpan(
// // //                     text: ' *',
// // //                     style: TextStyle(color: Colors.red),
// // //                   )
// // //                 ]
// // //               : [],
// // //         ),
// // //       ),
// // //       floatingLabelBehavior: FloatingLabelBehavior.auto,
// // //       border: OutlineInputBorder(
// // //         borderRadius: BorderRadius.circular(8),
// // //       ),
// // //       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
// // //     );
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Apply CompOff"),
// // //         backgroundColor: kAppBarColor,
// // //       ),
// // //       body: Container(
// // //         decoration: const BoxDecoration(
// // //           gradient: LinearGradient(
// // //             begin: Alignment.topCenter,
// // //             end: Alignment.bottomCenter,
// // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // //           ),
// // //         ),
// // //         child: Form(
// // //           key: _formKey,
// // //           child: SingleChildScrollView(
// // //             padding: const EdgeInsets.all(16),
// // //             child: Column(
// // //               children: [
// // //                 /// 🔽 Shift Dropdown
// // //                 DropdownButtonFormField<String>(
// // //                   decoration: buildInputDecoration("Shift", isRequired: true),
// // //                   value: selectedShift,
// // //                   items: shifts.map((shift) {
// // //                     return DropdownMenuItem(value: shift, child: Text(shift));
// // //                   }).toList(),
// // //                   validator: (value) =>
// // //                       value == null ? 'Please select a shift' : null,
// // //                   onChanged: (value) => setState(() => selectedShift = value),
// // //                 ),
// // //                 const SizedBox(height: 16),

// // //                 /// 📅 From Date
// // //                 TextFormField(
// // //                   readOnly: true,
// // //                   onTap: () => _pickDate(true),
// // //                   controller: TextEditingController(
// // //                     text: fromDate != null
// // //                         ? DateFormat('dd MMM yyyy').format(fromDate!)
// // //                         : '',
// // //                   ),
// // //                   validator: (_) =>
// // //                       fromDate == null ? 'Please select from date' : null,
// // //                   decoration:
// // //                       buildInputDecoration("From Date", isRequired: true),
// // //                 ),
// // //                 const SizedBox(height: 16),

// // //                 /// 🔁 Replace Work Date
// // //                 TextFormField(
// // //                   readOnly: true,
// // //                   onTap: () => _pickDate(false),
// // //                   controller: TextEditingController(
// // //                     text: replaceWorkDate != null
// // //                         ? DateFormat('dd MMM yyyy').format(replaceWorkDate!)
// // //                         : '',
// // //                   ),
// // //                   validator: (_) => replaceWorkDate == null
// // //                       ? 'Please select replace work date'
// // //                       : null,
// // //                   decoration:
// // //                       buildInputDecoration("Compensate Date", isRequired: true),
// // //                 ),
// // //                 const SizedBox(height: 16),

// // //                 /// 📝 Reason
// // //                 TextFormField(
// // //                   controller: reasonController,
// // //                   maxLines: 3,
// // //                   validator: (value) =>
// // //                       value == null || value.trim().isEmpty
// // //                           ? 'Please enter a reason'
// // //                           : null,
// // //                   decoration: buildInputDecoration("Reason", isRequired: true),
// // //                 ),
// // //                 const SizedBox(height: 32),

// // //                 /// ✅ Submit Button
// // //                 SizedBox(
// // //                   width: double.infinity,
// // //                   child: ElevatedButton(
// // //                     onPressed: _submitForm,
// // //                     style: ElevatedButton.styleFrom(
// // //                       backgroundColor: kButtonColor,
// // //                       padding: const EdgeInsets.symmetric(vertical: 14),
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(12),
// // //                       ),
// // //                     ),
// // //                     child: const Text("Submit",
// // //                         style: TextStyle(color: kTextColor)),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';

// // // ✅ Custom Colors
// // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // const Color kAppBarColor = Color(0xFF8c6eaf);
// // const Color kButtonColor = Color(0xFF655193);
// // const Color kTextColor = Colors.white;

// // class HalfDayTimePage extends StatefulWidget {
// //   final bool isPopup;
// //   final int totalHalfDays;
// //   final int takenHalfDays;
// //   final String status;

// //   const HalfDayTimePage({
// //     super.key,
// //     required this.isPopup,
// //     required this.totalHalfDays,
// //     required this.takenHalfDays,
// //     required this.status,
// //   });

// //   @override
// //   State<HalfDayTimePage> createState() => _HalfDayTimePageState();
// // }

// // class _HalfDayTimePageState extends State<HalfDayTimePage> {
// //   final _formKey = GlobalKey<FormState>();

// //   DateTime? selectedDate;
// //   String? selectedSession;
// //   final TextEditingController reasonController = TextEditingController();

// //   final List<String> sessions = ['Morning Half', 'Afternoon Half'];

// //   String get sessionTime {
// //     if (selectedSession == 'Morning Half') {
// //       return '9:00 AM - 1:00 PM';
// //     } else if (selectedSession == 'Afternoon Half') {
// //       return '2:00 PM - 6:00 PM';
// //     }
// //     return '';
// //   }

// //   Future<void> _selectDate(BuildContext context) async {
// //     final DateTime? pickedDate = await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now(),
// //       firstDate: DateTime.now(),
// //       lastDate: DateTime.now().add(const Duration(days: 365)),
// //     );

// //     if (pickedDate != null) {
// //       setState(() {
// //         selectedDate = pickedDate;
// //       });
// //     }
// //   }

// //   InputDecoration buildInputDecoration(String label) {
// //     return InputDecoration(
// //       floatingLabelBehavior: FloatingLabelBehavior.auto,
// //       filled: true,
// //       fillColor: Colors.white, // 👈 This line sets white background
// //       label: RichText(
// //         text: TextSpan(
// //           text: label,
// //           style: const TextStyle(color: Colors.black, fontSize: 16),
// //           children: const [
// //             TextSpan(
// //               text: ' *',
// //               style: TextStyle(color: Colors.red),
// //             ),
// //           ],
// //         ),
// //       ),
// //       border: const OutlineInputBorder(),
// //       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
// //     );
// //   }

// //   Future<void> _submitForm() async {
// //     if (_formKey.currentState!.validate()) {
// //       final url = Uri.parse("http://localhost:3000/api/apply-halfday");

// //       final body = {
// //         "date": DateFormat("yyyy-MM-dd").format(selectedDate!),
// //         "session": selectedSession,
// //         "reason": reasonController.text.trim(),
// //       };

// //       try {
// //         final response = await http.post(
// //           url,
// //           headers: {"Content-Type": "application/json"},
// //           body: jsonEncode(body),
// //         );

// //         if (response.statusCode == 200) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(
// //               content: Text("HalfDay Request Submitted Successfully"),
// //               backgroundColor: Color.fromARGB(255, 22, 24, 22),
// //             ),
// //           );
// //           if (widget.isPopup) Navigator.pop(context);
// //         } else {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text("❌ Failed: ${response.body}"),
// //               backgroundColor: Colors.red,
// //             ),
// //           );
// //         }
// //       } catch (e) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text("❌ Error: $e"),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final pageContent = SingleChildScrollView(
// //       padding: const EdgeInsets.all(16.0),
// //       child: Form(
// //         key: _formKey,
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             // 📅 Leave Date
// //            GestureDetector(
// //               onTap: () => _selectDate(context),
// //               child: AbsorbPointer(
// //                 child: TextFormField(
// //                   decoration: buildInputDecoration("Leave Date"),
// //                   controller: TextEditingController(
// //                     text: selectedDate == null
// //                         ? ''
// //                         : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
// //                   ),
// //                   validator: (_) =>
// //                       selectedDate == null ? 'Please select a leave date' : null,
// //                 ),
// //               ),
// //             ),
// //             const SizedBox(height: 16),

// //             // 🕒 Session Dropdown
// //             DropdownButtonFormField<String>(
// //               decoration: buildInputDecoration("Select Session"),
// //               value: selectedSession,
// //               items: sessions.map((String session) {
// //                 return DropdownMenuItem<String>(
// //                   value: session,
// //                   child: Text(session),
// //                 );
// //               }).toList(),
// //               onChanged: (value) {
// //                 setState(() {
// //                   selectedSession = value;
// //                 });
// //               },
// //               validator: (value) =>
// //                   value == null ? 'Please select a session' : null,
// //             ),
// //             const SizedBox(height: 10),

// //             // ⏰ Session Time Info
// //             if (selectedSession != null)
// //               Padding(
// //                 padding: const EdgeInsets.only(bottom: 12),
// //                 child: Text(
// //                   sessionTime,
// //                   style: const TextStyle(
// //                     fontSize: 14,
// //                     fontWeight: FontWeight.w500,
// //                     color: Colors.blueGrey,
// //                   ),
// //                 ),
// //               ),

// //             // 📝 Reason
// //             TextFormField(
// //               controller: reasonController,
// //               maxLines: 3,
// //               decoration: buildInputDecoration("Reason"),
// //               validator: (value) =>
// //                   value == null || value.trim().isEmpty
// //                       ? 'Please enter a reason'
// //                       : null,
// //             ),
// //             const SizedBox(height: 24),

// //             // ✅ Submit Button
// //             SizedBox(
// //               width: double.infinity,
// //               child: ElevatedButton(
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: kButtonColor,
// //                   foregroundColor: kTextColor,
// //                   padding: const EdgeInsets.symmetric(vertical: 14),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                 ),
// //                 onPressed: _submitForm,
// //                 child: const Text("Submit"),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );

// //     final gradientBackground = Container(
// //       decoration: const BoxDecoration(
// //         gradient: LinearGradient(
// //           colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// //           begin: Alignment.topCenter,
// //           end: Alignment.bottomCenter,
// //         ),
// //       ),
// //       child: SafeArea(
// //         child: widget.isPopup
// //             ? SizedBox(width: 350, child: pageContent)
// //             : Column(
// //                 children: [
// //                   Expanded(child: pageContent),
// //                 ],
// //               ),
// //       ),
// //     );

// //     return Scaffold(
// //       backgroundColor: Colors.transparent,
// //       appBar: widget.isPopup
// //           ? null
// //           : AppBar(
// //               title: const Text('Apply Half Day'),
// //               backgroundColor: kAppBarColor,
// //               foregroundColor: kTextColor,
// //             ),
// //       body: gradientBackground,
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// // 🎨 Your Color Constants
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class ApplyHalfDayForm extends StatefulWidget {
//   const ApplyHalfDayForm({super.key});

//   @override
//   State<ApplyHalfDayForm> createState() => _ApplyHalfDayFormState();
// }

// class _ApplyHalfDayFormState extends State<ApplyHalfDayForm> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   String? selectedShift;
//   DateTime? fromDate;
//   DateTime? replaceWorkDate;
//   final TextEditingController reasonController = TextEditingController();

//   final List<String> shifts = ['Shift 1', 'Shift 2', 'Shift 3'];

//   Future<void> _pickDate(bool isFromDate) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isFromDate) {
//           fromDate = picked;
//         } else {
//           replaceWorkDate = picked;
//         }
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState?.validate() != true) return;

//     if (fromDate == null || replaceWorkDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('⚠️ Please select both dates')),
//       );
//       return;
//     }

//     final url = Uri.parse('http://localhost:3000/api/apply-compoff');

//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'shift': selectedShift,
//         'workedDate': DateFormat('yyyy-MM-dd').format(fromDate!),
//         'alternateLeaveDate': DateFormat('yyyy-MM-dd').format(replaceWorkDate!),
//         'reason': reasonController.text.trim(),
//       }),
//     );

//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('CompOff Request Submitted Successfully')),
//       );
//       setState(() {
//         selectedShift = null;
//         fromDate = null;
//         replaceWorkDate = null;
//         reasonController.clear();
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('❌ Submission Failed: ${response.body}')),
//       );
//     }
//   }

//   InputDecoration buildInputDecoration(String label, {bool isRequired = false}) {
//     return InputDecoration(
//     filled: true,
//     fillColor: Colors.white, // 👈 This line sets white background
//       label: RichText(
//         text: TextSpan(
//           text: label,
//           style: const TextStyle(
//             color: Colors.black,
//             fontSize: 16,
//           ),
//           children: isRequired
//               ? const [
//                   TextSpan(
//                     text: ' *',
//                     style: TextStyle(color: Colors.red),
//                   )
//                 ]
//               : [],
//         ),
//       ),
//       floatingLabelBehavior: FloatingLabelBehavior.auto,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Apply CompOff"),
//         backgroundColor: kAppBarColor,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//           ),
//         ),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 /// 🔽 Shift Dropdown
//                 DropdownButtonFormField<String>(
//                   decoration: buildInputDecoration("Shift", isRequired: true),
//                   value: selectedShift,
//                   items: shifts.map((shift) {
//                     return DropdownMenuItem(value: shift, child: Text(shift));
//                   }).toList(),
//                   validator: (value) =>
//                       value == null ? 'Please select a shift' : null,
//                   onChanged: (value) => setState(() => selectedShift = value),
//                 ),
//                 const SizedBox(height: 16),

//                 /// 📅 From Date
//                 TextFormField(
//                   readOnly: true,
//                   onTap: () => _pickDate(true),
//                   controller: TextEditingController(
//                     text: fromDate != null
//                         ? DateFormat('dd MMM yyyy').format(fromDate!)
//                         : '',
//                   ),
//                   validator: (_) =>
//                       fromDate == null ? 'Please select from date' : null,
//                   decoration:
//                       buildInputDecoration("From Date", isRequired: true),
//                 ),
//                 const SizedBox(height: 16),

//                 /// 🔁 Replace Work Date
//                 TextFormField(
//                   readOnly: true,
//                   onTap: () => _pickDate(false),
//                   controller: TextEditingController(
//                     text: replaceWorkDate != null
//                         ? DateFormat('dd MMM yyyy').format(replaceWorkDate!)
//                         : '',
//                   ),
//                   validator: (_) => replaceWorkDate == null
//                       ? 'Please select replace work date'
//                       : null,
//                   decoration:
//                       buildInputDecoration("Compensate Date", isRequired: true),
//                 ),
//                 const SizedBox(height: 16),

//                 /// 📝 Reason
//                 TextFormField(
//                   controller: reasonController,
//                   maxLines: 3,
//                   validator: (value) =>
//                       value == null || value.trim().isEmpty
//                           ? 'Please enter a reason'
//                           : null,
//                   decoration: buildInputDecoration("Reason", isRequired: true),
//                 ),
//                 const SizedBox(height: 32),

//                 /// ✅ Submit Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _submitForm,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: kButtonColor,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text("Submit",
//                         style: TextStyle(color: kTextColor)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:html' as html; // for Flutter Web localStorage
// import 'package:serv_app/models/company_data.dart';

// // 🎨 Your Color Constants
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// /// Match your Node server port
// const String apiBase = 'http://localhost:3000';

// class ApplyHalfDayForm extends StatefulWidget {
//   const ApplyHalfDayForm({super.key});

//   @override
//   State<ApplyHalfDayForm> createState() => _ApplyHalfDayFormState();
// }

// class _ApplyHalfDayFormState extends State<ApplyHalfDayForm> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   String? selectedShift;
//   DateTime? fromDate; // Work Date
//   DateTime? replaceWorkDate; // Compensate Date
//   final TextEditingController reasonController = TextEditingController();

//   final List<String> shifts = ['Shift 1', 'Shift 2', 'Shift 3'];

//   // ---- JWT helpers ----
//   bool _looksLikeJwt(String v) => RegExp(
//     r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$',
//   ).hasMatch(v);

//   Future<String?> _getJwt() async {
//     try {
//       final t = CompanyData.token;
//       if (t != null && t.isNotEmpty) {
//         html.window.localStorage.putIfAbsent('token', () => t);
//         return t;
//       }
//     } catch (_) {}

//     for (final k in ['jwt', 'token', 'access_token', 'auth_token']) {
//       final v = html.window.localStorage[k];
//       if (v != null && v.isNotEmpty) return v;
//     }

//     for (final k in html.window.localStorage.keys) {
//       final v = html.window.localStorage[k];
//       if (v != null && _looksLikeJwt(v)) return v;
//     }
//     return null;
//   }

//   Future<void> _pickDate(bool isFromDate) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isFromDate) {
//           fromDate = picked;
//         } else {
//           replaceWorkDate = picked;
//         }
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState?.validate() != true) return;

//     if (fromDate == null || replaceWorkDate == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please select both dates')));
//       return;
//     }

//     final token = await _getJwt();
//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Not logged in: missing token')),
//       );
//       return;
//     }

//     final url = Uri.parse('$apiBase/api/leaves');
//     final body = {
//       'type': 'Comp Off',
//       'selectShift': selectedShift,
//       'startDate': fromDate!.toIso8601String(), // Work Date
//       'endDate': replaceWorkDate!.toIso8601String(), // Compensate Date
//       'reason': reasonController.text.trim(),
//       'leaveCount': 1, // treat as single comp-off unit
//     };

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('CompOff Request Submitted Successfully'),
//           ),
//         );
//         setState(() {
//           selectedShift = null;
//           fromDate = null;
//           replaceWorkDate = null;
//           reasonController.clear();
//         });
//       } else if (response.statusCode == 403) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Forbidden: Employees only')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Submission Failed: ${response.statusCode} ${response.body}',
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Network error: $e')));
//     }
//   }

//   InputDecoration buildInputDecoration(
//     String label, {
//     bool isRequired = false,
//   }) {
//     return InputDecoration(
//       filled: true,
//       fillColor: Colors.white,
//       label: RichText(
//         text: TextSpan(
//           text: label,
//           style: const TextStyle(color: Colors.black, fontSize: 16),
//           children: isRequired
//               ? const [
//                   TextSpan(
//                     text: ' *',
//                     style: TextStyle(color: Colors.red),
//                   ),
//                 ]
//               : [],
//         ),
//       ),
//       floatingLabelBehavior: FloatingLabelBehavior.auto,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Apply CompOff"),
//         backgroundColor: kAppBarColor,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//           ),
//         ),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 // Shift
//                 DropdownButtonFormField<String>(
//                   decoration: buildInputDecoration("Shift", isRequired: true),
//                   value: selectedShift,
//                   items: shifts
//                       .map(
//                         (shift) =>
//                             DropdownMenuItem(value: shift, child: Text(shift)),
//                       )
//                       .toList(),
//                   validator: (value) =>
//                       value == null ? 'Please select a shift' : null,
//                   onChanged: (value) => setState(() => selectedShift = value),
//                 ),
//                 const SizedBox(height: 16),

//                 // Work Date
//                 TextFormField(
//                   readOnly: true,
//                   onTap: () => _pickDate(true),
//                   controller: TextEditingController(
//                     text: fromDate != null
//                         ? DateFormat('dd MMM yyyy').format(fromDate!)
//                         : '',
//                   ),
//                   validator: (_) =>
//                       fromDate == null ? 'Please select work date' : null,
//                   decoration: buildInputDecoration(
//                     "Work Date",
//                     isRequired: true,
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Compensate Date
//                 TextFormField(
//                   readOnly: true,
//                   onTap: () => _pickDate(false),
//                   controller: TextEditingController(
//                     text: replaceWorkDate != null
//                         ? DateFormat('dd MMM yyyy').format(replaceWorkDate!)
//                         : '',
//                   ),
//                   validator: (_) => replaceWorkDate == null
//                       ? 'Please select compensate date'
//                       : null,
//                   decoration: buildInputDecoration(
//                     "Compensate Date",
//                     isRequired: true,
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Reason
//                 TextFormField(
//                   controller: reasonController,
//                   maxLines: 3,
//                   validator: (value) => value == null || value.trim().isEmpty
//                       ? 'Please enter a reason'
//                       : null,
//                   decoration: buildInputDecoration("Reason", isRequired: true),
//                 ),
//                 const SizedBox(height: 32),

//                 // Submit
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _submitForm,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: kButtonColor,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       "Submit",
//                       style: TextStyle(color: kTextColor),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html; // for Flutter Web localStorage
import 'package:serv_app/models/company_data.dart';

// 🎨 Your Color Constants
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

/// Match your Node server port
const String apiBase = 'http://localhost:3000';

class ApplyHalfDayForm extends StatefulWidget {
  const ApplyHalfDayForm({super.key});

  @override
  State<ApplyHalfDayForm> createState() => _ApplyHalfDayFormState();
}

class _ApplyHalfDayFormState extends State<ApplyHalfDayForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedShift;
  DateTime? fromDate; // Work Date
  DateTime? replaceWorkDate; // Compensate Date
  final TextEditingController reasonController = TextEditingController();

  final List<String> shifts = ['Shift 1', 'Shift 2', 'Shift 3'];

  // ---- JWT helpers ----
  bool _looksLikeJwt(String v) => RegExp(
        r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$',
      ).hasMatch(v);

  Future<String?> _getJwt() async {
    try {
      final t = CompanyData.token;
      if (t != null && t.isNotEmpty) {
        html.window.localStorage.putIfAbsent('token', () => t);
        return t;
      }
    } catch (_) {}

    for (final k in ['jwt', 'token', 'access_token', 'auth_token']) {
      final v = html.window.localStorage[k];
      if (v != null && v.isNotEmpty) return v;
    }

    for (final k in html.window.localStorage.keys) {
      final v = html.window.localStorage[k];
      if (v != null && _looksLikeJwt(v)) return v;
    }
    return null;
  }

  Future<void> _pickDate(bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          replaceWorkDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    if (fromDate == null || replaceWorkDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select both dates')));
      return;
    }

    final token = await _getJwt();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in: missing token')),
      );
      return;
    }

    final url = Uri.parse('$apiBase/api/leaves');
    final body = {
      'type': 'Comp Off',
      'selectShift': selectedShift,
      'startDate': fromDate!.toIso8601String(), // Work Date
      'endDate': replaceWorkDate!.toIso8601String(), // Compensate Date
      'reason': reasonController.text.trim(),
      'leaveCount': 1, // treat as single comp-off unit
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CompOff Request Submitted Successfully'),
          ),
        );
        setState(() {
          selectedShift = null;
          fromDate = null;
          replaceWorkDate = null;
          reasonController.clear();
        });
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Forbidden: Employees only')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Submission Failed: ${response.statusCode} ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  InputDecoration buildInputDecoration(
    String label, {
    bool isRequired = false,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      label: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          children: isRequired
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ]
              : [],
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ✅ let the gradient be visible edge-to-edge
      extendBody: true,                    // ✅ extend body under bottom area
      appBar: AppBar(
        title: const Text("Apply CompOff"),
        backgroundColor: kAppBarColor,
      ),
      body: Container(
        constraints: const BoxConstraints.expand(), // ✅ fill entire viewport
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Shift
                DropdownButtonFormField<String>(
                  decoration: buildInputDecoration("Shift", isRequired: true),
                  value: selectedShift,
                  items: shifts
                      .map(
                        (shift) =>
                            DropdownMenuItem(value: shift, child: Text(shift)),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null ? 'Please select a shift' : null,
                  onChanged: (value) => setState(() => selectedShift = value),
                ),
                const SizedBox(height: 16),

                // Work Date
                TextFormField(
                  readOnly: true,
                  onTap: () => _pickDate(true),
                  controller: TextEditingController(
                    text: fromDate != null
                        ? DateFormat('dd MMM yyyy').format(fromDate!)
                        : '',
                  ),
                  validator: (_) =>
                      fromDate == null ? 'Please select work date' : null,
                  decoration: buildInputDecoration(
                    "Work Date",
                    isRequired: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Compensate Date
                TextFormField(
                  readOnly: true,
                  onTap: () => _pickDate(false),
                  controller: TextEditingController(
                    text: replaceWorkDate != null
                        ? DateFormat('dd MMM yyyy').format(replaceWorkDate!)
                        : '',
                  ),
                  validator: (_) => replaceWorkDate == null
                      ? 'Please select compensate date'
                      : null,
                  decoration: buildInputDecoration(
                    "Compensate Date",
                    isRequired: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Reason
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a reason'
                      : null,
                  decoration: buildInputDecoration("Reason", isRequired: true),
                ),
                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(color: kTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
