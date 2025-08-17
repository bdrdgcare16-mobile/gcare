
// // import 'package:flutter/material.dart';
// // import 'create_shift_page.dart';
// // import 'shift_permission_page.dart';

// // // Theme Colors
// // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // const Color kAppBarColor = Color(0xFF8C6EAF);
// // const Color kButtonColor = Color(0xFF655193);
// // const Color kTextColor = Colors.white;

// // class WorkdaysShiftPage extends StatefulWidget {
// //   const WorkdaysShiftPage({super.key});

// //   @override
// //   State<WorkdaysShiftPage> createState() => _WorkdaysShiftPageState();
// // }

// // class _WorkdaysShiftPageState extends State<WorkdaysShiftPage> {
// //   bool _isShiftPermissionClicked = false;
// //   bool _isCreateShiftClicked = false;

// //   List<Map<String, String>> _createdShifts = [];

// //   void _navigateToShiftPermission(BuildContext context) {
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(builder: (context) => const ShiftPermissionPage()),
// //     );
// //   }

// //   void _navigateToCreateShift(BuildContext context) async {
// //     final result = await Navigator.push<Map<String, String>>(
// //       context,
// //       MaterialPageRoute(builder: (context) => const CreateShiftPage()),
// //     );

// //     if (result != null) {
// //       setState(() {
// //         _createdShifts.add(result);
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: kPrimaryBackgroundTop,
// //       appBar: AppBar(
// //         title: const Text("Workdays & Shifts"),
// //         backgroundColor: kAppBarColor,
// //         foregroundColor: kTextColor,
// //       ),
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// //           ),
// //         ),
// //         child: SingleChildScrollView(
// //           padding: const EdgeInsets.all(16),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               const Text(
// //                 "Shift Configuration",
// //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //               ),
// //               const SizedBox(height: 8),
// //               const Text(
// //                 "Choose your shift",
// //                 style: TextStyle(fontSize: 14, color: Colors.black54),
// //               ),
// //               const SizedBox(height: 16),

// //               const _ShiftTemplateCard(
// //                 title: "Template 1",
// //                 time: "09:30 AM - 06:30 PM",
// //               ),
// //               const SizedBox(height: 10),
// //               const _ShiftTemplateCard(
// //                 title: "Template 2",
// //                 time: "07:30 AM - 04:30 PM",
// //               ),
// //               const SizedBox(height: 10),
// //               const _ShiftTemplateCard(
// //                 title: "Template 3",
// //                 time: "12:30 AM - 11:59 PM",
// //               ),
// //               const SizedBox(height: 10),

// //               for (int i = 0; i < _createdShifts.length; i++) ...[
// //                 _ShiftTemplateCard(
// //                   title: "Template ${i + 4}: ${_createdShifts[i]["shiftName"] ?? "Shift"}",
// //                   time: "${_createdShifts[i]["startTime"]} - ${_createdShifts[i]["endTime"]}",
// //                 ),
// //                 const SizedBox(height: 10),
// //               ],

// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                 children: [
// //                   OutlinedButton(
// //                     style: OutlinedButton.styleFrom(
// //                       backgroundColor: _isShiftPermissionClicked ? kButtonColor : Colors.transparent,
// //                       foregroundColor: _isShiftPermissionClicked ? kTextColor : Colors.black,
// //                       side: const BorderSide(color: kButtonColor),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(20),
// //                       ),
// //                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
// //                     ),
// //                     onPressed: () {
// //                       setState(() {
// //                         _isShiftPermissionClicked = true;
// //                         _isCreateShiftClicked = false;
// //                       });
// //                       _navigateToShiftPermission(context);
// //                     },
// //                     child: const Text("Shift Permissions"),
// //                   ),
// //                   OutlinedButton(
// //                     style: OutlinedButton.styleFrom(
// //                       backgroundColor: _isCreateShiftClicked ? kButtonColor : Colors.transparent,
// //                       foregroundColor: _isCreateShiftClicked ? kTextColor : Colors.black,
// //                       side: const BorderSide(color: kButtonColor),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(20),
// //                       ),
// //                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
// //                     ),
// //                     onPressed: () {
// //                       setState(() {
// //                         _isCreateShiftClicked = true;
// //                         _isShiftPermissionClicked = false;
// //                       });
// //                       _navigateToCreateShift(context);
// //                     },
// //                     child: const Text("Create Shift"),
// //                   ),
// //                 ],
// //               ),

// //               const SizedBox(height: 30),
// //               _buildTableHeader(),
// //               const Divider(),
// //               _buildTableFooter(),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildTableHeader() {
// //     return const SingleChildScrollView(
// //       scrollDirection: Axis.horizontal,
// //       child: Row(
// //         children: [
// //           _HeaderCell("Shift Name"),
// //           _HeaderCell("Start Time"),
// //           _HeaderCell("End Time"),
// //           _HeaderCell("No. of hours"),
// //           _HeaderCell("OT(mins)"),
// //           _HeaderCell("Half Day Time"),
// //           _HeaderCell("Min PT"),
// //           _HeaderCell("Max PT"),
// //           _HeaderCell("Max OT"),
// //           _HeaderCell("Min OT"),
// //           _HeaderCell("Group Name"),
// //           _HeaderCell("Random count"),
// //           _HeaderCell("End BufferName"),
// //           _HeaderCell("Staff BufferName"),
// //           _HeaderCell("Group Name"),
// //           _HeaderCell("Break Count"),
// //           _HeaderCell("Delete"),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildTableFooter() {
// //     return SingleChildScrollView(
// //       scrollDirection: Axis.horizontal,
// //       child: Column(
// //         children: _createdShifts.map((shift) {
// //           return Row(
// //             children: [
// //               _CustomDataCell(shift["shiftName"] ?? ""),
// //               _CustomDataCell(shift["startTime"] ?? ""),
// //               _CustomDataCell(shift["endTime"] ?? ""),
// //               _CustomDataCell("8 hrs"),
// //               _CustomDataCell("30"),
// //               _CustomDataCell("4 hrs"),
// //               _CustomDataCell("2 hrs"),
// //               _CustomDataCell("6 hrs"),
// //               _CustomDataCell("2 hrs"),
// //               _CustomDataCell("1 hr"),
// //               _CustomDataCell(shift["groupName"] ?? ""),
// //               _CustomDataCell("5"),
// //               _CustomDataCell("10 min"),
// //               _CustomDataCell("15 min"),
// //               _CustomDataCell(shift["groupName"] ?? ""),
// //               _CustomDataCell(shift["breakConfig"] ?? ""),
// //               IconButton(
// //                 icon: const Icon(Icons.delete, color: Colors.red),
// //                 onPressed: () {
// //                   setState(() {
// //                     _createdShifts.remove(shift);
// //                   });
// //                 },
// //               ),
// //             ],
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// // }

// // class _ShiftTemplateCard extends StatelessWidget {
// //   final String title;
// //   final String time;

// //   const _ShiftTemplateCard({required this.title, required this.time});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Card(
// //       color: kAppBarColor.withOpacity(0.2),
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// //       child: SizedBox(
// //         width: double.infinity,
// //         height: 70,
// //         child: Padding(
// //           padding: const EdgeInsets.symmetric(horizontal: 16),
// //           child: Row(
// //             children: [
// //               Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
// //               const Spacer(),
// //               Text(
// //                 time,
// //                 style: const TextStyle(fontSize: 12),
// //                 textAlign: TextAlign.right,
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _HeaderCell extends StatelessWidget {
// //   final String label;

// //   const _HeaderCell(this.label);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: 100,
// //       padding: const EdgeInsets.all(8),
// //       alignment: Alignment.center,
// //       child: Text(
// //         label,
// //         textAlign: TextAlign.center,
// //         style: const TextStyle(
// //           fontWeight: FontWeight.w600,
// //           fontSize: 12,
// //           color: kButtonColor,
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _CustomDataCell extends StatelessWidget {
// //   final String value;

// //   const _CustomDataCell(this.value);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: 100,
// //       padding: const EdgeInsets.all(8),
// //       alignment: Alignment.center,
// //       child: Text(
// //         value,
// //         textAlign: TextAlign.center,
// //         style: const TextStyle(fontSize: 12),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'create_shift_page.dart'; // ✅ make sure this path is correct
// import 'shift_permission_page.dart';

// // Theme Colors
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class WorkdaysShiftPage extends StatefulWidget {
//   const WorkdaysShiftPage({super.key});

//   @override
//   State<WorkdaysShiftPage> createState() => _WorkdaysShiftPageState();
// }

// class _WorkdaysShiftPageState extends State<WorkdaysShiftPage> {
//   bool _isShiftPermissionClicked = false;
//   bool _isCreateShiftClicked = false;

//   final List<Map<String, String>> _createdShifts = [];

//   void _navigateToShiftPermission(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const ShiftPermissionPage()),
//     );
//   }

//   /// Open the CreateShiftPage form and collect the result
//   Future<void> _handleCreateShift() async {
//     debugPrint('Create Shift tapped'); // sanity log

//     setState(() {
//       _isCreateShiftClicked = true;
//       _isShiftPermissionClicked = false;
//     });

//     final result = await Navigator.of(context).push<Map<String, String>>(
//       MaterialPageRoute(builder: (_) => const CreateShiftPage()),
//     );

//     if (result != null) {
//       setState(() {
//         _createdShifts.add(result);
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Shift "${result["shiftName"] ?? ""}" added'),
//             backgroundColor: kButtonColor,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kPrimaryBackgroundTop,
//       appBar: AppBar(
//         title: const Text("Workdays & Shifts"),
//         backgroundColor: kAppBarColor,
//         foregroundColor: kTextColor,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Shift Configuration",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 "Choose your shift",
//                 style: TextStyle(fontSize: 14, color: Colors.black54),
//               ),
//               const SizedBox(height: 16),

//               const _ShiftTemplateCard(
//                 title: "Template 1",
//                 time: "09:30 AM - 06:30 PM",
//               ),
//               const SizedBox(height: 10),
//               const _ShiftTemplateCard(
//                 title: "Template 2",
//                 time: "07:30 AM - 04:30 PM",
//               ),
//               const SizedBox(height: 10),
//               const _ShiftTemplateCard(
//                 title: "Template 3",
//                 time: "12:30 AM - 11:59 PM",
//               ),
//               const SizedBox(height: 10),

//               // Dynamically created shifts (from the CreateShiftPage form)
//               for (int i = 0; i < _createdShifts.length; i++) ...[
//                 _ShiftTemplateCard(
//                   title:
//                       "Template ${i + 4}: ${_createdShifts[i]["shiftName"] ?? "Shift"}",
//                   time:
//                       "${_createdShifts[i]["startTime"]} - ${_createdShifts[i]["endTime"]}",
//                 ),
//                 const SizedBox(height: 10),
//               ],

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   OutlinedButton(
//                     style: OutlinedButton.styleFrom(
//                       backgroundColor: _isShiftPermissionClicked
//                           ? kButtonColor
//                           : Colors.transparent,
//                       foregroundColor: _isShiftPermissionClicked
//                           ? kTextColor
//                           : Colors.black,
//                       side: const BorderSide(color: kButtonColor),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 24, vertical: 14),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _isShiftPermissionClicked = true;
//                         _isCreateShiftClicked = false;
//                       });
//                       _navigateToShiftPermission(context);
//                     },
//                     child: const Text("Shift Permissions"),
//                   ),
//                   OutlinedButton(
//                     style: OutlinedButton.styleFrom(
//                       backgroundColor: _isCreateShiftClicked
//                           ? kButtonColor
//                           : Colors.transparent,
//                       foregroundColor: _isCreateShiftClicked
//                           ? kTextColor
//                           : Colors.black,
//                       side: const BorderSide(color: kButtonColor),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 24, vertical: 14),
//                     ),
//                     onPressed: _handleCreateShift, // ✅ open the form
//                     child: const Text("Create Shift"),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 30),
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildTableHeader(),
//                     const Divider(),
//                     _buildTableFooter(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTableHeader() {
//     return Row(
//       children: const [
//         _HeaderCell("Shift Name"),
//         _HeaderCell("Start Time"),
//         _HeaderCell("End Time"),
//         _HeaderCell("No. of hours"),
//         _HeaderCell("OT(mins)"),
//         _HeaderCell("Half Day Time"),
//         _HeaderCell("Min PT"),
//         _HeaderCell("Max PT"),
//         _HeaderCell("Max OT"),
//         _HeaderCell("Min OT"),
//         _HeaderCell("Group Name"),
//         _HeaderCell("Random count"),
//         _HeaderCell("End BufferName"),
//         _HeaderCell("Staff BufferName"),
//         _HeaderCell("Group Name"),
//         _HeaderCell("Break Count"),
//         _HeaderCell("Delete"),
//       ],
//     );
//   }

//   Widget _buildTableFooter() {
//     return Column(
//       children: _createdShifts.map((shift) {
//         return Row(
//           children: [
//             _CustomDataCell(shift["shiftName"] ?? ""),
//             _CustomDataCell(shift["startTime"] ?? ""),
//             _CustomDataCell(shift["endTime"] ?? ""),
//             _CustomDataCell("8 hrs"),
//             _CustomDataCell("30"),
//             _CustomDataCell("4 hrs"),
//             _CustomDataCell("2 hrs"),
//             _CustomDataCell("6 hrs"),
//             _CustomDataCell("2 hrs"),
//             _CustomDataCell("1 hr"),
//             _CustomDataCell(shift["groupName"] ?? ""),
//             _CustomDataCell("5"),
//             _CustomDataCell("10 min"),
//             _CustomDataCell("15 min"),
//             _CustomDataCell(shift["groupName"] ?? ""),
//             _CustomDataCell(shift["breakConfig"] ?? ""),
//             IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red),
//               onPressed: () {
//                 setState(() {
//                   _createdShifts.remove(shift);
//                 });
//               },
//             ),
//           ],
//         );
//       }).toList(),
//     );
//   }
// }

// class _ShiftTemplateCard extends StatelessWidget {
//   final String title;
//   final String time;

//   const _ShiftTemplateCard({required this.title, required this.time});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: kAppBarColor.withOpacity(0.2),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       child: SizedBox(
//         width: double.infinity,
//         height: 70,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             children: [
//               Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//               const Spacer(),
//               Text(
//                 time,
//                 style: const TextStyle(fontSize: 12),
//                 textAlign: TextAlign.right,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _HeaderCell extends StatelessWidget {
//   final String label;

//   const _HeaderCell(this.label);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 100,
//       padding: const EdgeInsets.all(8),
//       alignment: Alignment.center,
//       child: Text(
//         label,
//         textAlign: TextAlign.center,
//         style: const TextStyle(
//           fontWeight: FontWeight.w600,
//           fontSize: 12,
//           color: kButtonColor,
//         ),
//       ),
//     );
//   }
// }

// class _CustomDataCell extends StatelessWidget {
//   final String value;

//   const _CustomDataCell(this.value);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 100,
//       padding: const EdgeInsets.all(8),
//       alignment: Alignment.center,
//       child: Text(
//         value,
//         textAlign: TextAlign.center,
//         style: const TextStyle(fontSize: 12),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Web localStorage (ignored on mobile/desktop builds)
import 'dart:html' as html show window;

import 'create_shift_page.dart';
import 'shift_permission_page.dart';

// Theme Colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ==== API ====
const String _apiBase = 'http://localhost:3000';

class WorkdaysShiftPage extends StatefulWidget {
  const WorkdaysShiftPage({super.key});

  @override
  State<WorkdaysShiftPage> createState() => _WorkdaysShiftPageState();
}

class _WorkdaysShiftPageState extends State<WorkdaysShiftPage> {
  bool _isShiftPermissionClicked = false;
  bool _isCreateShiftClicked = false;

  bool _loading = false;
  String? _error;

  /// Shifts from DB
  List<Map<String, dynamic>> _shifts = [];

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  Future<String?> _getToken() async {
    try {
      final t = html.window.localStorage['token'];
      if (t != null && t.isNotEmpty) return t;
    } catch (_) {}
    final sp = await SharedPreferences.getInstance();
    final t2 = sp.getString('token');
    return (t2 != null && t2.isNotEmpty) ? t2 : null;
  }

  Future<void> _fetchShifts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final res = await http.get(Uri.parse('$_apiBase/shifts'), headers: headers);
      if (res.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = 'Failed to load shifts (${res.statusCode})';
        });
        return;
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      _shifts = list.cast<Map<String, dynamic>>();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Network error: $e';
      });
    }
  }

  void _navigateToShiftPermission(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShiftPermissionPage()),
    );
  }

  Future<void> _handleCreateShift() async {
    setState(() {
      _isCreateShiftClicked = true;
      _isShiftPermissionClicked = false;
    });

    // Opens the real form page which POSTS to the API and pops with created shift
    final created = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const CreateShiftPage()),
    );

    if (created != null) {
      // Optimistic add (also still freshen from server)
      setState(() => _shifts.insert(0, created));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shift "${created["name"] ?? created["shiftname"] ?? ""}" created'), backgroundColor: kButtonColor),
      );
      // Make sure we’re in sync with DB
      await _fetchShifts();
    }
  }

  // Helpers
  String _hm12(String hhmm) {
    try {
      final parts = hhmm.split(':');
      int h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final am = h < 12;
      if (h == 0) h = 12;
      if (h > 12) h -= 12;
      final mm = m.toString().padLeft(2, '0');
      return '$h:$mm ${am ? "AM" : "PM"}';
    } catch (_) {
      return hhmm;
    }
  }

  String _hoursBetween(String startHHMM, String endHHMM) {
    try {
      final s = startHHMM.split(':').map(int.parse).toList();
      final e = endHHMM.split(':').map(int.parse).toList();
      int sm = s[0] * 60 + s[1];
      int em = e[0] * 60 + e[1];
      int diff = em - sm;
      if (diff < 0) diff += 24 * 60; // crosses midnight
      final h = (diff / 60).floor();
      final m = diff % 60;
      return m == 0 ? '$h hrs' : '$h hrs $m mins';
    } catch (_) {
      return '-';
    }
  }

  Future<void> _deleteShift(String id) async {
    final token = await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final res = await http.delete(Uri.parse('$_apiBase/shifts/$id'), headers: headers);
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() => _shifts.removeWhere((s) => s['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift deleted'), backgroundColor: kButtonColor),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${res.statusCode}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryBackgroundTop,
      appBar: AppBar(
        title: const Text("Workdays & Shifts"),
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchShifts,
            tooltip: 'Refresh',
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Shift Configuration", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text("Choose your shift", style: TextStyle(fontSize: 14, color: Colors.black54)),
                        const SizedBox(height: 16),

                     
                        // Live from DB
                        for (int i = 0; i < _shifts.length; i++) ...[
                          _ShiftTemplateCard(
                            title: " ${_shifts[i]["name"] ?? _shifts[i]["shiftname"] ?? "Shift"}",
                            time: "${_hm12(_shifts[i]["startTime"] ?? '-') } - ${_hm12(_shifts[i]["endTime"] ?? '-')}",
                          ),
                          const SizedBox(height: 10),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _isShiftPermissionClicked ? kButtonColor : Colors.transparent,
                                foregroundColor: _isShiftPermissionClicked ? kTextColor : Colors.black,
                                side: const BorderSide(color: kButtonColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isShiftPermissionClicked = true;
                                  _isCreateShiftClicked = false;
                                });
                                _navigateToShiftPermission(context);
                              },
                              child: const Text("Shift Permissions"),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _isCreateShiftClicked ? kButtonColor : Colors.transparent,
                                foregroundColor: _isCreateShiftClicked ? kTextColor : Colors.black,
                                side: const BorderSide(color: kButtonColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              onPressed: _handleCreateShift,
                              child: const Text("Create Shift"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Table with live DB rows
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTableHeader(),
                              const Divider(),
                              Column(
                                children: _shifts.map((s) {
                                  final id = (s['id'] ?? '').toString();
                                  final name = (s['name'] ?? '').toString();
                                  final group = (s['shiftname'] ?? '').toString(); // using shiftname as "Group Name"
                                  final st = (s['startTime'] ?? '').toString();
                                  final et = (s['endTime'] ?? '').toString();

                                  return Row(
                                    children: [
                                      _CustomDataCell(name),
                                      _CustomDataCell(_hm12(st)),
                                      _CustomDataCell(_hm12(et)),
                                      _CustomDataCell(_hoursBetween(st, et)),
                                      _CustomDataCell('0'), // OT (mins) — no rule yet
                                      _CustomDataCell('4 hrs'), // Half Day Time (example)
                                      _CustomDataCell('15 mins'), // Min PT
                                      _CustomDataCell('60 mins'), // Max PT
                                      _CustomDataCell('—'), // Max OT
                                      _CustomDataCell('—'), // Min OT
                                      _CustomDataCell(group),
                                      _CustomDataCell('—'), // Random count
                                      _CustomDataCell('—'), // End BufferName
                                      _CustomDataCell('—'), // Staff BufferName
                                      _CustomDataCell(group),
                                      _CustomDataCell('—'), // Break Count
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: id.isEmpty ? null : () => _deleteShift(id),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: const [
        _HeaderCell("Shift Name"),
        _HeaderCell("Start Time"),
        _HeaderCell("End Time"),
        _HeaderCell("No. of hours"),
        _HeaderCell("OT(mins)"),
        _HeaderCell("Half Day Time"),
        _HeaderCell("Min PT"),
        _HeaderCell("Max PT"),
        _HeaderCell("Max OT"),
        _HeaderCell("Min OT"),
        _HeaderCell("Group Name"),
        _HeaderCell("Random count"),
        _HeaderCell("End BufferName"),
        _HeaderCell("Staff BufferName"),
        _HeaderCell("Group Name"),
        _HeaderCell("Break Count"),
        _HeaderCell("Delete"),
      ],
    );
  }
}

class _ShiftTemplateCard extends StatelessWidget {
  final String title;
  final String time;

  const _ShiftTemplateCard({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kAppBarColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: double.infinity,
        height: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(time, style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: kButtonColor),
      ),
    );
  }
}

class _CustomDataCell extends StatelessWidget {
  final String value;

  const _CustomDataCell(this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
    );
  }
}
