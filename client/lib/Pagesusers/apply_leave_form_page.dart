// // import 'package:flutter/material.dart';

// // // 🎨 Reuse your existing colors
// // const Color kAppBarColor = Color(0xFF8C6EAF);
// // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // const Color kButtonColor = Color(0xFF655193);
// // const Color kTextColor = Colors.white;

// // class PermissionPopup extends StatelessWidget {
// //   const PermissionPopup({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Dialog(
// //       backgroundColor: Colors.transparent,
// //       child: Container(
// //         height: 450,
// //         decoration: BoxDecoration(
// //           borderRadius: BorderRadius.circular(20),
// //           gradient: const LinearGradient(
// //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //         ),
// //         child: Column(
// //           children: [
// //             // 🔷 AppBar-like container with your desired color
// //             Container(
// //               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
// //               width: double.infinity,
// //               decoration: const BoxDecoration(
// //                 color: kAppBarColor,
// //                 borderRadius: BorderRadius.only(
// //                   topLeft: Radius.circular(20),
// //                   topRight: Radius.circular(20),
// //                 ),
// //               ),
// //               child: const Text(
// //                 "Permission Time",
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 18,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //             ),

// //             const SizedBox(height: 12),

// //             Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16),
// //               child: Column(
// //                 children: [
// //                   // 🔽 Dropdown Example
// //                   DropdownButtonFormField<String>(
// //                     decoration: InputDecoration(
// //                       labelText: "Shift",
// //                       labelStyle: const TextStyle(color: Colors.black),
// //                       filled: true,
// //                       fillColor: Colors.transparent,
// //                       enabledBorder: OutlineInputBorder(
// //                         borderSide: const BorderSide(color: Colors.black),
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       focusedBorder: OutlineInputBorder(
// //                         borderSide: const BorderSide(color: kAppBarColor),
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                     ),
// //                     items: ["Morning", "Evening"]
// //                         .map((shift) => DropdownMenuItem(
// //                               value: shift,
// //                               child: Text(shift),
// //                             ))
// //                         .toList(),
// //                     onChanged: (value) {},
// //                   ),

// //                   const SizedBox(height: 12),

// //                   // 📝 Reason Field
// //                   TextFormField(
// //                     decoration: InputDecoration(
// //                       labelText: "Reason",
// //                       labelStyle: const TextStyle(color: Colors.black),
// //                       filled: true,
// //                       fillColor: Colors.transparent,
// //                       enabledBorder: OutlineInputBorder(
// //                         borderSide: const BorderSide(color: Colors.black),
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       focusedBorder: OutlineInputBorder(
// //                         borderSide: const BorderSide(color: kAppBarColor),
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                     ),
// //                   ),

// //                   const SizedBox(height: 20),

// //                   // ✅ Submit Button
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton(
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: kButtonColor,
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                         ),
// //                       ),
// //                       onPressed: () {
// //                         Navigator.pop(context);
// //                       },
// //                       child: const Text(
// //                         "Submit",
// //                         style: TextStyle(color: Colors.white),
// //                       ),
// //                     ),
// //                   )
// //                 ],
// //               ),
// //             )
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// // 🎨 Color constants
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class ApplyLeaveFormPage extends StatefulWidget {
//   const ApplyLeaveFormPage({super.key});

//   @override
//   State<ApplyLeaveFormPage> createState() => _ApplyLeaveFormPageState();
// }

// class _ApplyLeaveFormPageState extends State<ApplyLeaveFormPage> {
//   String leaveType = 'Leave';
//   String? selectedLeaveType;
//   final TextEditingController causeController = TextEditingController();
//   final TextEditingController fromDateController = TextEditingController();
//   final TextEditingController toDateController = TextEditingController();
//   final TextEditingController leaveFormatController = TextEditingController();

//   DateTime? fromDate;
//   DateTime? toDate;

//   Future<void> _selectDate(TextEditingController controller, bool isFromDate) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       controller.text = "${picked.day}/${picked.month}/${picked.year}";
//       if (isFromDate) {
//         fromDate = picked;
//       } else {
//         toDate = picked;
//       }
//     }
//   }

//   Future<void> submitLeaveForm() async {
//     final url = Uri.parse("http://localhost:4000/api/requests/leave");

//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'employeeName': "Padma", // Or use a controller if name is input
//         'leaveType': selectedLeaveType ?? '',
//         'fromDate': fromDate?.toIso8601String() ?? '',
//         'toDate': toDate?.toIso8601String() ?? '',
//         'reason': causeController.text,
//         'leaveCount': leaveFormatController.text,
//         'category': leaveType, // "Leave" or "Comp off"
//       }),
//     );

//     if (response.statusCode == 200) {
//       print("Leave Request submitted successfully!");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Leave submitted!")),
//       );
//     } else {
//       print("❌ Error: ${response.body}");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${response.body}")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Apply Leave"),
//         backgroundColor: kAppBarColor,
//         centerTitle: true,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: ListView(
//             children: [
//               // Radio toggle
//               Row(
//                 children: [
//                   Radio(
//                     value: 'Leave',
//                     groupValue: leaveType,
//                     onChanged: (value) {
//                       setState(() => leaveType = value.toString());
//                     },
//                   ),
//                   const Text("Leave"),
//                   Radio(
//                     value: 'Comp off',
//                     groupValue: leaveType,
//                     onChanged: (value) {
//                       setState(() => leaveType = value.toString());
//                     },
//                   ),
//                   const Text("Comp off"),
//                 ],
//               ),
//               const SizedBox(height: 8),

//               // Leave Type Dropdown
//               DropdownButtonFormField<String>(
//                 value: selectedLeaveType,
//                 hint: const Text("Choose Leave Type"),
//                 items: ['Casual Leave', 'Sick Leave', 'Planned Leave']
//                     .map((type) => DropdownMenuItem(value: type, child: Text(type)))
//                     .toList(),
//                 onChanged: (value) {
//                   setState(() => selectedLeaveType = value);
//                 },
//                 decoration: const InputDecoration(
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               // Cause
//               TextFormField(
//                 controller: causeController,
//                 decoration: const InputDecoration(
//                   labelText: "Cause",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               // From Date
//               TextFormField(
//                 controller: fromDateController,
//                 readOnly: true,
//                 onTap: () => _selectDate(fromDateController, true),
//                 decoration: const InputDecoration(
//                   labelText: "From Date",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               // To Date
//               TextFormField(
//                 controller: toDateController,
//                 readOnly: true,
//                 onTap: () => _selectDate(toDateController, false),
//                 decoration: const InputDecoration(
//                   labelText: "To Date",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               // Leave count
//               TextFormField(
//                 controller: leaveFormatController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: "Apply leave count",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Capture image (optional feature)
//               const Text("Capture Image"),
//               const SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: () {
//                   // TODO: Add camera logic
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: kButtonColor,
//                 ),
//                 child: const Text("Capture", style: TextStyle(color: kTextColor)),
//               ),
//               const SizedBox(height: 20),

//               // Submit Button
//               ElevatedButton(
//                 onPressed: submitLeaveForm,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: kButtonColor,
//                 ),
//                 child: const Text("Submit", style: TextStyle(color: kTextColor)),
//               ),
//             ],
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
import 'package:serv_app/html_stub.dart'
  if (dart.library.html) 'package:serv_app/html_web.dart' as html;// for Flutter Web localStorage
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

  // ---- JWT helpers (same pattern as other pages) ----
  bool _looksLikeJwt(String v) => RegExp(
    r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$',
  ).hasMatch(v);

  Future<String?> _getJwt() async {
    // 1) In-memory token from your login flow
    try {
      final t = CompanyData.token;
      if (t != null && t.isNotEmpty) {
        html.window.localStorage.putIfAbsent('token', () => t);
        return t;
      }
    } catch (_) {}

    // 2) Common localStorage keys
    for (final k in ['jwt', 'token', 'access_token', 'auth_token']) {
      final v = html.window.localStorage[k];
      if (v != null && v.isNotEmpty) return v;
    }

    // 3) Any JWT-looking value in localStorage
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select both dates')),
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

    // Use /api/leaves with type "Comp Off" to match your controller.
    final url = Uri.parse('$apiBase/api/leaves');

    final body = {
      'type': 'Comp Off',
      'selectShift': selectedShift,
      // Map Work Date -> startDate, Compensate Date -> endDate
      'startDate': fromDate!.toIso8601String(),
      'endDate': replaceWorkDate!.toIso8601String(),
      'reason': reasonController.text.trim(),
      // Force a single-off credit even if dates differ
      'leaveCount': 1,
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
              '❌ Submission Failed: ${response.statusCode} ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Network error: $e')));
    }
  }

  InputDecoration buildInputDecoration(
    String label, {
    bool isRequired = false,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white, // 👈 keep white input backgrounds
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
      appBar: AppBar(
        title: const Text("Apply CompOff"),
        backgroundColor: kAppBarColor,
      ),
      body: Container(
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
                /// 🔽 Shift Dropdown
                DropdownButtonFormField<String>(
                  decoration: buildInputDecoration("Shift", isRequired: true),
                  initialValue: selectedShift,
                  items: shifts.map((shift) {
                    return DropdownMenuItem(value: shift, child: Text(shift));
                  }).toList(),
                  validator: (value) =>
                      value == null ? 'Please select a shift' : null,
                  onChanged: (value) => setState(() => selectedShift = value),
                ),
                const SizedBox(height: 16),

                /// 📅 Work Date
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

                /// 🔁 Compensate Date
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

                /// 📝 Reason
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a reason'
                      : null,
                  decoration: buildInputDecoration("Reason", isRequired: true),
                ),
                const SizedBox(height: 32),

                /// ✅ Submit Button
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
