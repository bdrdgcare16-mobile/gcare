// import 'package:flutter/material.dart';

// class HalfDayTimePage extends StatefulWidget {
//   final bool isPopup;
//   final int totalHalfDays;
//   final int takenHalfDays;
//   final String status;

//   const HalfDayTimePage({
//     super.key,
//     required this.isPopup,
//     required this.totalHalfDays,
//     required this.takenHalfDays,
//     required this.status,
//   });

//   @override
//   State<HalfDayTimePage> createState() => _HalfDayTimePageState();
// }

// class _HalfDayTimePageState extends State<HalfDayTimePage> {
//   DateTime? selectedDate;
//   String? selectedSession;
//   final TextEditingController reasonController = TextEditingController();

//   final List<String> sessions = ['Morning Half', 'Afternoon Half'];

//   String get sessionTime {
//     if (selectedSession == 'Morning Half') {
//       return '9:00 AM - 1:00 PM';
//     } else if (selectedSession == 'Afternoon Half') {
//       return '2:00 PM - 6:00 PM';
//     }
//     return '';
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now().subtract(const Duration(days: 0)),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );

//     if (pickedDate != null) {
//       setState(() {
//         selectedDate = pickedDate;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: widget.isPopup
//           ? null
//           : AppBar(
//               title: const Text('Apply Half Day'),
//               backgroundColor: Colors.deepPurple,
//               foregroundColor: Colors.white,
//             ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Apply Half Day Leave",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),

//             // Leave Date Picker
//             Row(
//               children: [
//                 const Icon(Icons.calendar_today),
//                 const SizedBox(width: 8),
//                 const Text("Leave Date: "),
//                 const SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: () => _selectDate(context),
//                   child: Text(selectedDate == null
//                       ? 'Choose Date'
//                       : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}"),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // Session Dropdown
//             DropdownButtonFormField<String>(
//               decoration: const InputDecoration(
//                 labelText: "Select Session",
//                 border: OutlineInputBorder(),
//               ),
//               value: selectedSession,
//               items: sessions.map((String session) {
//                 return DropdownMenuItem<String>(
//                   value: session,
//                   child: Text(session),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedSession = value;
//                 });
//               },
//             ),
//             const SizedBox(height: 8),

//             // Show session time
//             if (selectedSession != null)
//               Text(
//                 sessionTime,
//                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blueGrey),
//               ),

//             const SizedBox(height: 16),

//             // Reason field
//             TextField(
//               controller: reasonController,
//               maxLines: 3,
//               decoration: const InputDecoration(
//                 labelText: "Reason",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Submit Button
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepPurple,
//                 foregroundColor: Colors.white,
//               ),
//               onPressed: () {
//                 if (selectedDate != null &&
//                     selectedSession != null &&
//                     reasonController.text.isNotEmpty) {
//                   // You can send this data to backend or Firebase
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Submitted Successfully")),
//                   );
//                   if (widget.isPopup) Navigator.pop(context);
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Please fill all fields")),
//                   );
//                 }
//               },
//               child: const Text("Submit"),
//             ),
//           ],
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
  if (dart.library.html) 'package:serv_app/html_web.dart' as html; // for Flutter Web localStorage
import 'package:serv_app/models/company_data.dart';

// Colors (unchanged)
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8c6eaf);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

/// Match your Node server port
const String apiBase = 'https://api-zmj7dqloiq-uc.a.run.app/api';

class HalfDayTimePage extends StatefulWidget {
  final bool isPopup;
  final int totalHalfDays;
  final int takenHalfDays;
  final String status;

  const HalfDayTimePage({
    super.key,
    required this.isPopup,
    required this.totalHalfDays,
    required this.takenHalfDays,
    required this.status,
  });

  @override
  State<HalfDayTimePage> createState() => _HalfDayTimePageState();
}

class _HalfDayTimePageState extends State<HalfDayTimePage> {
  final _formKey = GlobalKey<FormState>();

  DateTime? selectedDate;
  String? selectedSession;
  final TextEditingController reasonController = TextEditingController();

  final List<String> sessions = ['Morning Half', 'Afternoon Half'];

  String get sessionTime {
    if (selectedSession == 'Morning Half') {
      return '9:00 AM - 1:00 PM';
    } else if (selectedSession == 'Afternoon Half') {
      return '2:00 PM - 6:00 PM';
    }
    return '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  InputDecoration buildInputDecoration(String label) {
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.white,
      label: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
    );
  }

  // ---------- JWT helpers ----------
  bool _looksLikeJwt(String v) => RegExp(
    r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$',
  ).hasMatch(v);

  Future<String?> _getJwt() async {
    // 1) From your in-memory model (set at login)
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

    // 3) Any JWT-looking value
    for (final k in html.window.localStorage.keys) {
      final v = html.window.localStorage[k];
      if (v != null && _looksLikeJwt(v)) return v;
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null || selectedSession == null) return;

    final token = await _getJwt();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in: missing token')),
      );
      return;
    }

    final uri = Uri.parse('$apiBase/api/leaves');

    // Backend Half-Day branch expects: type, selectDate, (optional) selectShift, reason.
    final payload = {
      'type': 'Half-Day',
      'selectDate': DateFormat('yyyy-MM-dd').format(selectedDate!),
      'selectShift': selectedSession, // contains 'Morning' or 'Afternoon'
      'reason': reasonController.text.trim(),
    };

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
          const SnackBar(content: Text('Half-day request submitted')),
        );
        if (widget.isPopup) Navigator.pop(context);
        // Reset form
        setState(() {
          selectedDate = null;
          selectedSession = null;
          reasonController.clear();
        });
      } else if (resp.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Forbidden: Employees only')),
        );
      } else {
        final msg = resp.body.isNotEmpty ? resp.body : 'Unexpected error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${resp.statusCode} $msg')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Leave Date
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: buildInputDecoration("Leave Date"),
                  controller: TextEditingController(
                    text: selectedDate == null
                        ? ''
                        : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                  ),
                  validator: (_) => selectedDate == null
                      ? 'Please select a leave date'
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Session
            DropdownButtonFormField<String>(
              decoration: buildInputDecoration("Select Session"),
              initialValue: selectedSession,
              items: sessions
                  .map(
                    (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedSession = value),
              validator: (value) =>
                  value == null ? 'Please select a session' : null,
            ),
            const SizedBox(height: 10),

            // Session time hint
            if (selectedSession != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  sessionTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
              ),

            // Reason
            TextFormField(
              controller: reasonController,
              maxLines: 3,
              decoration: buildInputDecoration("Reason"),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter a reason'
                  : null,
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonColor,
                  foregroundColor: kTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _submitForm,
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );

    final gradientBackground = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: widget.isPopup
            ? SizedBox(width: 350, child: pageContent)
            : Column(children: [Expanded(child: pageContent)]),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.isPopup
          ? null
          : AppBar(
              title: const Text('Apply Half Day'),
              backgroundColor: kAppBarColor,
              foregroundColor: kTextColor,
            ),
      body: gradientBackground,
    );
  }
}
