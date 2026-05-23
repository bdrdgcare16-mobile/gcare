// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:serv_app/html_stub.dart'
//     if (dart.library.html) 'package:serv_app/html_web.dart'
//     as html; // for Flutter Web localStorage
// import 'package:serv_app/models/company_data.dart'; // <-- moved to top with other imports
// import 'package:serv_app/services/api_service.dart';

// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// /// Match your Node server port (using centralized config)
// final String apiBase = ApiService.baseUrl;

// class PermissionTimePage extends StatefulWidget {
//   const PermissionTimePage({super.key, required this.isPopup});
//   final bool isPopup;

//   @override
//   State<PermissionTimePage> createState() => _PermissionTimePageState();
// }

// class _PermissionTimePageState extends State<PermissionTimePage> {
//   final _formKey = GlobalKey<FormState>();
//   // Dynamic list of shifts that will be populated from the server
//   final List<String> shifts = [];
//   final List<String> reasons = ['Emergency', 'Personal Reason'];

//   String? selectedShift;
//   String? selectedReason;
//   DateTime? selectedDate;
//   TimeOfDay? startTime;
//   TimeOfDay? endTime;

//   final TextEditingController startTimeController = TextEditingController();
//   final TextEditingController endTimeController = TextEditingController();
//   final TextEditingController dateController = TextEditingController();

//   // Shift time ranges are now dynamic and not hardcoded

//   // ---------- JWT helpers ----------
//   bool _looksLikeJwt(String v) => RegExp(
//         r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$',
//       ).hasMatch(v);

//   Future<String?> _getJwt() async {
//     // 1) CompanyData (in-memory)
//     try {
//       final t = CompanyData.token;
//       if (t != null && t.isNotEmpty) {
//         html.window.localStorage.putIfAbsent('token', () => t);
//         debugPrint('[PermissionTime] token from CompanyData (${t.length})');
//         return t;
//       }
//     } catch (_) {}

//     // 2) common localStorage keys
//     for (final k in ['jwt', 'token', 'access_token', 'auth_token']) {
//       final v = html.window.localStorage[k];
//       if (v != null && v.isNotEmpty) {
//         debugPrint(
//           '[PermissionTime] token from localStorage "$k" (${v.length})',
//         );
//         return v;
//       }
//     }

//     // 3) scan any key that looks like a JWT
//     for (final k in html.window.localStorage.keys) {
//       final v = html.window.localStorage[k];
//       if (v != null && _looksLikeJwt(v)) {
//         debugPrint(
//           '[PermissionTime] token from localStorage "$k" (${v.length})',
//         );
//         return v;
//       }
//     }

//     debugPrint('[PermissionTime] No token found');
//     return null;
//   }

//   // ---------- NEW: load employee's default shift from /auth/me ----------
//   Future<void> _loadDefaultShiftFromProfile() async {
//     final token = CompanyData.token.isNotEmpty
//         ? CompanyData.token
//         : (await _getJwt()) ?? '';
//     if (token.isEmpty) return;

//     try {
//       final res = await http.get(
//         Uri.parse('${ApiService.baseUrl}/auth/me'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//       if (res.statusCode != 200) return;

//       final data = jsonDecode(res.body) as Map<String, dynamic>;
//       final profile = (data['employeeProfile'] is Map<String, dynamic>)
//           ? data['employeeProfile'] as Map<String, dynamic>
//           : const <String, dynamic>{};

//       final raw =
//           (profile['shiftGroup'] ?? data['shiftGroup'] ?? '').toString().trim();
//       if (raw.isEmpty) return;

//       if (!shifts.contains(raw)) {
//         // Insert the employee's actual shift if it's custom (e.g., "GCC Shift 1")
//         shifts.insert(0, raw);
//       }

//       if (!mounted) return;
//       setState(() => selectedShift = raw);
//     } catch (_) {
//       // Silent failure; keep manual selection
//     }
//   }
//   // ----------------------------------------------------------------------

//   // ---------- UI logic ----------
//   Future<void> _selectDate(BuildContext context) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null) {
//       setState(() {
//         selectedDate = picked;
//         dateController.text = DateFormat('yyyy-MM-dd').format(picked);
//       });
//     }
//   }

//   Future<void> _selectTime(BuildContext context, bool isStart) async {
//   final picked = await showTimePicker(
//     context: context,
//     initialTime: TimeOfDay.now(),
//     builder: (context, child) {
//       return MediaQuery(
//         data: MediaQuery.of(context).copyWith(
//           alwaysUse24HourFormat: false,
//         ),
//         child: Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: kAppBarColor,
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         ),
//       );
//     },
//   );

//   if (picked != null) {
//     setState(() {
//       final formatted = formatTimeOfDay(picked);

//       if (isStart) {
//         startTime = picked;
//         startTimeController.text = formatted;
//         endTimeController.clear();
//         endTime = null;
//       } else {
//         endTime = picked;
//         endTimeController.text = formatted;
//       }
//     });

//     if (isStart) {
//       await Future.delayed(const Duration(milliseconds: 200));
//       _selectEndTimeAfterStart(context);
//     }
//   }
// }

//   Future<void> _selectEndTimeAfterStart(BuildContext context) async {
//   if (startTime == null || selectedShift == null) return;

//   final picked = await showTimePicker(
//     context: context,
//     initialTime: startTime!,
//     builder: (context, child) {
//       return MediaQuery(
//         data: MediaQuery.of(context).copyWith(
//           alwaysUse24HourFormat: false,
//         ),
//         child: Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: kAppBarColor,
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         ),
//       );
//     },
//   );

//   if (picked != null) {
//     if (!_isAfterStartTime(picked)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('End time must be after start time'),
//         ),
//       );
//       return;
//     }

//     setState(() {
//       endTime = picked;
//       endTimeController.text = formatTimeOfDay(picked);
//     });
//   }
// }

//   bool _isAfterStartTime(TimeOfDay checkTime) {
//     final startMinutes = startTime!.hour * 60 + startTime!.minute;
//     final checkMinutes = checkTime.hour * 60 + checkTime.minute;
//     return checkMinutes > startMinutes;
//   }

//   String formatTimeOfDay(TimeOfDay? time) {
//     if (time == null) return '';

//     final now = DateTime.now();
//     final dt = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       time.hour,
//       time.minute,
//     );

//    return DateFormat('hh:mm a').format(dt);
//   }  

//   String _to24h(TimeOfDay t) {
//     final h = t.hour.toString().padLeft(2, '0');
//     final m = t.minute.toString().padLeft(2, '0');
//     return '$h:$m'; // send as "HH:mm" to backend
//   }

//   Future<void> _handleSubmit() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (selectedShift == null ||
//         selectedReason == null ||
//         selectedDate == null ||
//         startTime == null ||
//         endTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please complete all required fields')),
//       );
//       return;
//     }
//     if (!_isAfterStartTime(endTime!)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('End time must be after start time')),
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

//     // Build payload expected by backend for Permission Time
//     final payload = {
//       'type': 'Permission Time',
//       'selectDate': DateFormat('yyyy-MM-dd').format(selectedDate!),
//       'startTime': _to24h(startTime!),
//       'endTime': _to24h(endTime!),
//       'selectShift': selectedShift,
//       'reason': selectedReason,
//     };

//     final uri = Uri.parse('${ApiService.baseUrl}/leaves');
//     debugPrint('[PermissionTime] POST $uri');
//     debugPrint('[PermissionTime] payload: $payload');

//     try {
//       final resp = await http.post(
//         uri,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(payload),
//       );

//       debugPrint('[PermissionTime] status=${resp.statusCode}');
//       debugPrint('[PermissionTime] body=${resp.body}');

//       if (resp.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Permission Request Submitted')),
//         );
//         _formKey.currentState?.reset();
//         setState(() {
//           selectedShift = null;
//           selectedReason = null;
//           startTime = null;
//           endTime = null;
//           selectedDate = null;
//           startTimeController.clear();
//           endTimeController.clear();
//           dateController.clear();
//         });
//       } else if (resp.statusCode == 403) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Forbidden: Employees only')),
//         );
//       } else {
//         final msg = resp.body.isNotEmpty ? resp.body : 'Unexpected error';
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed: ${resp.statusCode} $msg')),
//         );
//       }
//     } catch (e) {
//       debugPrint('[PermissionTime] error: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Network error: $e')));
//     }
//   }

//   InputDecoration inputBoxDecoration(String label, {bool isRequired = true}) {
//     return InputDecoration(
//       label: RichText(
//         text: TextSpan(
//           text: label,
//           style: const TextStyle(color: Colors.black87, fontSize: 14),
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
//       filled: true,
//       fillColor: Colors.white,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: kAppBarColor, width: 1.5),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: kButtonColor, width: 2),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: const BorderSide(color: Colors.red),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: const BorderSide(color: Colors.red, width: 2),
//       ),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadDefaultShiftFromProfile(); // NEW: auto-fill shift from employee profile
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.dark,
//         systemNavigationBarColor: kAppBarColor,
//         systemNavigationBarIconBrightness: Brightness.light,
//       ),
//       child: Scaffold(
//         extendBodyBehindAppBar: false,
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(90),
//           child: AppBar(
//             automaticallyImplyLeading: false,
//             backgroundColor: kAppBarColor,
//             elevation: 0,
//             flexibleSpace: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   height: 90,
//                   child: Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.arrow_back, color: Colors.white),
//                           onPressed: () => Navigator.pop(context),
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           "Apply Permission Time",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           child: Column(
//             children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       DropdownButtonFormField<String>(
//                         initialValue: selectedShift,
//                         decoration: inputBoxDecoration('Shift'),
//                         items: shifts.map((shift) {
//                           return DropdownMenuItem(
//                             value: shift,
//                             child: Text(shift),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             selectedShift = value;
//                             startTime = null;
//                             endTime = null;
//                             startTimeController.clear();
//                             endTimeController.clear();
//                           });
//                         },
//                         validator: (value) =>
//                             value == null ? 'Please select a shift' : null,
//                       ),

//                       // Show selected shift name
//                       if (selectedShift != null) ...[
//                         const SizedBox(height: 8),
//                         Text(
//                           selectedShift!,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],

//                       const SizedBox(height: 16),
//                       GestureDetector(
//                         onTap: () => _selectTime(context, true),
//                         child: AbsorbPointer(
//                           child: TextFormField(
//                             controller: startTimeController,
//                             decoration: inputBoxDecoration('Start Time'),
//                             validator: (value) => value == null || value.isEmpty
//                                 ? 'Please select start time'
//                                 : null,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       GestureDetector(
//                         onTap: () => _selectTime(context, false),
//                         child: AbsorbPointer(
//                           child: TextFormField(
//                             controller: endTimeController,
//                             decoration: inputBoxDecoration('End Time'),
//                             validator: (value) => value == null || value.isEmpty
//                                 ? 'Please select end time'
//                                 : null,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       DropdownButtonFormField<String>(
//                         initialValue: selectedReason,
//                         decoration: inputBoxDecoration('Reason'),
//                         items: reasons.map((reason) {
//                           return DropdownMenuItem(
//                             value: reason,
//                             child: Text(reason),
//                           );
//                         }).toList(),
//                         onChanged: (value) =>
//                             setState(() => selectedReason = value),
//                         validator: (value) =>
//                             value == null ? 'Please select a reason' : null,
//                       ),
//                       const SizedBox(height: 16),
//                       GestureDetector(
//                         onTap: () => _selectDate(context),
//                         child: AbsorbPointer(
//                           child: TextFormField(
//                             controller: dateController,
//                             decoration: inputBoxDecoration('Date'),
//                             validator: (value) => value == null || value.isEmpty
//                                 ? 'Please select a date'
//                                 : null,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: _handleSubmit,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: kButtonColor,
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: const Text(
//                             'Submit',
//                             style: TextStyle(color: kTextColor, fontSize: 16),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       ),
//     );
//   }
// }

// class TimeRange {
//   final TimeOfDay start;
//   final TimeOfDay end;

//   TimeRange({required this.start, required this.end});

//   bool contains(TimeOfDay time) {
//     final startMinutes = start.hour * 60 + start.minute;
//     final endMinutes = end.hour * 60 + end.minute;
//     final checkMinutes = time.hour * 60 + time.minute;
//     return checkMinutes >= startMinutes && checkMinutes <= endMinutes;
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

/// Match your Node server port using centralized config.
final String apiBase = ApiService.baseUrl;

class PermissionTimePage extends StatefulWidget {
  const PermissionTimePage({super.key, required this.isPopup});
  final bool isPopup;

  @override
  State<PermissionTimePage> createState() => _PermissionTimePageState();
}

class _PermissionTimePageState extends State<PermissionTimePage> {
  final _formKey = GlobalKey<FormState>();

  final List<String> shifts = [];
  final List<String> reasons = ['Emergency', 'Personal Reason'];

  String? selectedShift;
  String? selectedReason;
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  TimeOfDay? shiftStartTime;
  TimeOfDay? shiftEndTime;

  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  // ---------- JWT helpers ----------
  bool _looksLikeJwt(String v) => RegExp(
        r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$',
      ).hasMatch(v);

  Future<String?> _getJwt() async {
    try {
      final t = CompanyData.token;
      if (t != null && t.isNotEmpty) {
        html.window.localStorage.putIfAbsent('token', () => t);
        debugPrint('[PermissionTime] token from CompanyData (${t.length})');
        return t;
      }
    } catch (_) {}

    for (final k in ['jwt', 'token', 'access_token', 'auth_token']) {
      final v = html.window.localStorage[k];
      if (v != null && v.isNotEmpty) {
        debugPrint('[PermissionTime] token from localStorage "$k" (${v.length})');
        return v;
      }
    }

    for (final k in html.window.localStorage.keys) {
      final v = html.window.localStorage[k];
      if (v != null && _looksLikeJwt(v)) {
        debugPrint('[PermissionTime] token from localStorage "$k" (${v.length})');
        return v;
      }
    }

    debugPrint('[PermissionTime] No token found');
    return null;
  }

  // ---------- Time helpers ----------
  TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    try {
      // Supports "09:30" or "17:30"
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(text)) {
        final parts = text.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      // Supports "09:30 AM" or "05:30 PM"
      final parsed = DateFormat.jm().parse(text);
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      return null;
    }
  }

  int _toMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  bool _isWithinShift(TimeOfDay time) {
    if (shiftStartTime == null || shiftEndTime == null) return false;

    final selected = _toMinutes(time);
    final shiftStart = _toMinutes(shiftStartTime!);
    final shiftEnd = _toMinutes(shiftEndTime!);

    return selected >= shiftStart && selected <= shiftEnd;
  }

  bool _isAfterStartTime(TimeOfDay checkTime) {
    if (startTime == null) return false;

    final startMinutes = _toMinutes(startTime!);
    final checkMinutes = _toMinutes(checkTime);

    return checkMinutes > startMinutes;
  }

  String _formatShiftTime(TimeOfDay? time) {
    if (time == null) return '-';

    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    return DateFormat('hh:mm a').format(dt);
  }

  String formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Always display AM/PM format.
    return DateFormat('hh:mm a').format(dt);
  }

  String _to24h(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ---------- Load logged-in employee shift ----------
  Future<void> _loadDefaultShiftFromProfile() async {
    final token = CompanyData.token.isNotEmpty
        ? CompanyData.token
        : (await _getJwt()) ?? '';

    if (token.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      final profile = (data['employeeProfile'] is Map<String, dynamic>)
          ? data['employeeProfile'] as Map<String, dynamic>
          : const <String, dynamic>{};

      final raw =
          (profile['shiftGroup'] ?? data['shiftGroup'] ?? '').toString().trim();

      if (raw.isEmpty) return;

      if (!shifts.contains(raw)) {
        shifts.insert(0, raw);
      }

      if (!mounted) return;

      setState(() {
        selectedShift = raw;
      });

      await _loadShiftTimingByShiftName(raw);
    } catch (e) {
      debugPrint('[PermissionTime] Failed to load default shift: $e');
    }
  }

  // ---------- Load shift timing from /shifts ----------
  Future<void> _loadShiftTimingByShiftName(String shiftName) async {
    final token = CompanyData.token.isNotEmpty
        ? CompanyData.token
        : (await _getJwt()) ?? '';

    if (token.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/shifts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) {
        debugPrint('[PermissionTime] Failed to fetch shifts: ${res.statusCode}');
        return;
      }

      final decoded = jsonDecode(res.body);

      final List<dynamic> data = decoded is List
          ? decoded
          : decoded is Map<String, dynamic> && decoded['data'] is List
              ? decoded['data'] as List<dynamic>
              : <dynamic>[];

      for (final item in data) {
        final map = Map<String, dynamic>.from(item as Map);

        final name = (map['shiftname'] ??
                map['shiftName'] ??
                map['name'] ??
                map['title'] ??
                '')
            .toString()
            .trim();

        if (name.toLowerCase() == shiftName.toLowerCase()) {
          final startRaw = map['startTime'] ??
              map['shiftStartTime'] ??
              map['start_time'] ??
              map['fromTime'];

          final endRaw = map['endTime'] ??
              map['shiftEndTime'] ??
              map['end_time'] ??
              map['toTime'];

          final parsedStart = _parseTimeOfDay(startRaw);
          final parsedEnd = _parseTimeOfDay(endRaw);

          if (!mounted) return;

          setState(() {
            shiftStartTime = parsedStart;
            shiftEndTime = parsedEnd;
          });

          debugPrint(
            '[PermissionTime] Shift matched: $name, start=$startRaw, end=$endRaw',
          );

          return;
        }
      }

      debugPrint('[PermissionTime] No matching shift found for: $shiftName');
    } catch (e) {
      debugPrint('[PermissionTime] Shift timing fetch error: $e');
    }
  }

  // ---------- Date picker ----------
  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime.now();
    final firstAllowedDate = DateTime(today.year, today.month, today.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate != null &&
              !selectedDate!.isBefore(firstAllowedDate)
          ? selectedDate!
          : firstAllowedDate,
      firstDate: firstAllowedDate,
      lastDate: DateTime(2101),
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
        selectedDate = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ---------- Start / End time picker ----------
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    if (selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shift first')),
      );
      return;
    }

    if (shiftStartTime == null || shiftEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift start and end time are not available'),
        ),
      );
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? shiftStartTime! : (startTime ?? shiftStartTime!),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: kAppBarColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked == null) return;

    if (!_isWithinShift(picked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permission time must be within shift time '
            '(${_formatShiftTime(shiftStartTime)} - ${_formatShiftTime(shiftEndTime)})',
          ),
        ),
      );
      return;
    }

    if (isStart) {
      setState(() {
        startTime = picked;
        startTimeController.text = formatTimeOfDay(picked);
        endTimeController.clear();
        endTime = null;
      });

      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _selectEndTimeAfterStart(context);
    } else {
      if (startTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start time first')),
        );
        return;
      }

      if (!_isAfterStartTime(picked)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      setState(() {
        endTime = picked;
        endTimeController.text = formatTimeOfDay(picked);
      });
    }
  }

  Future<void> _selectEndTimeAfterStart(BuildContext context) async {
    if (startTime == null || selectedShift == null) return;

    if (shiftStartTime == null || shiftEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift start and end time are not available'),
        ),
      );
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: startTime!,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: kAppBarColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked == null) return;

    if (!_isWithinShift(picked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permission end time must be within shift time '
            '(${_formatShiftTime(shiftStartTime)} - ${_formatShiftTime(shiftEndTime)})',
          ),
        ),
      );
      return;
    }

    if (!_isAfterStartTime(picked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
        ),
      );
      return;
    }

    setState(() {
      endTime = picked;
      endTimeController.text = formatTimeOfDay(picked);
    });
  }

  // ---------- Submit ----------
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedShift == null ||
        selectedReason == null ||
        selectedDate == null ||
        startTime == null ||
        endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    if (shiftStartTime == null || shiftEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift start and end time are not available'),
        ),
      );
      return;
    }

    if (!_isWithinShift(startTime!) || !_isWithinShift(endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permission time must be within shift time '
            '(${_formatShiftTime(shiftStartTime)} - ${_formatShiftTime(shiftEndTime)})',
          ),
        ),
      );
      return;
    }

    if (!_isAfterStartTime(endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
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

    final payload = {
      'type': 'Permission Time',
      'selectDate': DateFormat('yyyy-MM-dd').format(selectedDate!),
      'startTime': _to24h(startTime!),
      'endTime': _to24h(endTime!),
      'selectShift': selectedShift,
      'reason': selectedReason,
    };

    final uri = Uri.parse('${ApiService.baseUrl}/leaves');

    debugPrint('[PermissionTime] POST $uri');
    debugPrint('[PermissionTime] payload: $payload');

    try {
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('[PermissionTime] status=${resp.statusCode}');
      debugPrint('[PermissionTime] body=${resp.body}');

      if (resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission Request Submitted')),
        );

        _formKey.currentState?.reset();

        setState(() {
          selectedReason = null;
          startTime = null;
          endTime = null;
          selectedDate = null;
          startTimeController.clear();
          endTimeController.clear();
          dateController.clear();

          // Keep selectedShift and shift timing because it belongs to logged-in employee.
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
      debugPrint('[PermissionTime] error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  InputDecoration inputBoxDecoration(String label, {bool isRequired = true}) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
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
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kAppBarColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kButtonColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultShiftFromProfile();
  }

  @override
  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: kAppBarColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: kAppBarColor,
            elevation: 0,
            flexibleSpace: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 90,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Apply Permission Time",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedShift,
                          decoration: inputBoxDecoration('Shift'),
                          items: shifts.map((shift) {
                            return DropdownMenuItem<String>(
                              value: shift,
                              child: Text(shift),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            setState(() {
                              selectedShift = value;
                              startTime = null;
                              endTime = null;
                              shiftStartTime = null;
                              shiftEndTime = null;
                              startTimeController.clear();
                              endTimeController.clear();
                            });

                            if (value != null) {
                              await _loadShiftTimingByShiftName(value);
                            }
                          },
                          validator: (value) =>
                              value == null ? 'Please select a shift' : null,
                        ),

                        if (selectedShift != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            selectedShift!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],

                        if (shiftStartTime != null && shiftEndTime != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Shift Time: ${_formatShiftTime(shiftStartTime)} - ${_formatShiftTime(shiftEndTime)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: () => _selectTime(context, true),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: startTimeController,
                              decoration: inputBoxDecoration('Start Time'),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please select start time'
                                      : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: () => _selectTime(context, false),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: endTimeController,
                              decoration: inputBoxDecoration('End Time'),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please select end time'
                                      : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: selectedReason,
                          decoration: inputBoxDecoration('Reason'),
                          items: reasons.map((reason) {
                            return DropdownMenuItem<String>(
                              value: reason,
                              child: Text(reason),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => selectedReason = value),
                          validator: (value) =>
                              value == null ? 'Please select a reason' : null,
                        ),

                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: dateController,
                              decoration: inputBoxDecoration('Date'),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please select a date'
                                      : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kButtonColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: kTextColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeRange({required this.start, required this.end});

  bool contains(TimeOfDay time) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final checkMinutes = time.hour * 60 + time.minute;

    return checkMinutes >= startMinutes && checkMinutes <= endMinutes;
  }
}