// // // // // // // // // leave_approvals_screen.dart
// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:intl/intl.dart';
// // // // // // // // import 'leave_data.dart';
// // // // // // // // import 'leave_card.dart';

// // // // // // // // class LeaveApprovalsScreen extends StatefulWidget {
// // // // // // // //   const LeaveApprovalsScreen({super.key});

// // // // // // // //   @override
// // // // // // // //   State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
// // // // // // // // }

// // // // // // // // class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
// // // // // // // //   String selectedTab = 'All';
// // // // // // // //   String selectedStatusFilter = 'All';
// // // // // // // //   final TextEditingController searchController = TextEditingController();

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final today = DateFormat('dd MMM yyyy').format(DateTime.now());

// // // // // // // //     List<Map<String, dynamic>> filtered = allLeaveRequests
// // // // // // // //         .where((leave) => selectedTab == 'All' || leave['type'] == selectedTab)
// // // // // // // //         .where((leave) => selectedStatusFilter == 'All' || leave['status'] == selectedStatusFilter.toLowerCase())
// // // // // // // //         .where((leave) => leave.values.any((v) => v.toString().toLowerCase().contains(searchController.text.toLowerCase())))
// // // // // // // //         .toList();

// // // // // // // //     return Scaffold(
// // // // // // // //       appBar: AppBar(
// // // // // // // //         backgroundColor: const Color(0xFF8C6EAF),
// // // // // // // //         title: const Text("Leave Approvals"),
// // // // // // // //         actions: [
// // // // // // // //           Padding(
// // // // // // // //             padding: const EdgeInsets.all(12),
// // // // // // // //             child: Center(child: Text(today)),
// // // // // // // //           ),
// // // // // // // //         ],
// // // // // // // //       ),
// // // // // // // //       body: Container(
// // // // // // // //         padding: const EdgeInsets.all(10),
// // // // // // // //         decoration: const BoxDecoration(
// // // // // // // //           gradient: LinearGradient(
// // // // // // // //             colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
// // // // // // // //             begin: Alignment.topCenter,
// // // // // // // //             end: Alignment.bottomCenter,
// // // // // // // //           ),
// // // // // // // //         ),
// // // // // // // //         child: Column(
// // // // // // // //           children: [
// // // // // // // //             // 🔁 Scrollable Row with Dropdown + Buttons
// // // // // // // //             SingleChildScrollView(
// // // // // // // //               scrollDirection: Axis.horizontal,
// // // // // // // //               child: Row(
// // // // // // // //                 children: [
// // // // // // // //                   DropdownButton<String>(
// // // // // // // //                     value: selectedTab,
// // // // // // // //                     onChanged: (val) => setState(() => selectedTab = val!),
// // // // // // // //                     items: [
// // // // // // // //                       'All',
// // // // // // // //                       'Leave Type',
// // // // // // // //                       'Permission',
// // // // // // // //                       'Over Time',
// // // // // // // //                       'Half Day Leave',
// // // // // // // //                       'Comp Off'
// // // // // // // //                     ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
// // // // // // // //                   ),
// // // // // // // //                   const SizedBox(width: 10),
// // // // // // // //                   _buildStatusButton("Pending", Colors.pink[100]!),
// // // // // // // //                   const SizedBox(width: 6),
// // // // // // // //                   _buildStatusButton("Approved", Colors.greenAccent),
// // // // // // // //                   const SizedBox(width: 6),
// // // // // // // //                   _buildStatusButton("Rejected", Colors.red[200]!),
// // // // // // // //                 ],
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //             const SizedBox(height: 10),

// // // // // // // //             // 🔍 Search bar
// // // // // // // //             TextField(
// // // // // // // //               controller: searchController,
// // // // // // // //               onChanged: (_) => setState(() {}),
// // // // // // // //               decoration: InputDecoration(
// // // // // // // //                 hintText: 'Search...',
// // // // // // // //                 prefixIcon: const Icon(Icons.search),
// // // // // // // //                 filled: true,
// // // // // // // //                 fillColor: Colors.white,
// // // // // // // //                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //             const SizedBox(height: 10),

// // // // // // // //             // 📝 List of Leave Cards
// // // // // // // //             Expanded(
// // // // // // // //               child: ListView.builder(
// // // // // // // //                 itemCount: filtered.length,
// // // // // // // //                 itemBuilder: (context, index) {
// // // // // // // //                   final leave = filtered[index];
// // // // // // // //                   return LeaveCard(
// // // // // // // //                     item: leave,
// // // // // // // //                     onStatusChange: (status) {
// // // // // // // //                       setState(() {
// // // // // // // //                         leave['status'] = status;
// // // // // // // //                       });
// // // // // // // //                     },
// // // // // // // //                   );
// // // // // // // //                 },
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   // 🔘 Status Button Widget
// // // // // // // //   Widget _buildStatusButton(String label, Color color) {
// // // // // // // //     return GestureDetector(
// // // // // // // //       onTap: () => setState(() => selectedStatusFilter = label),
// // // // // // // //       child: Container(
// // // // // // // //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // // // // // //         decoration: BoxDecoration(
// // // // // // // //           color: color,
// // // // // // // //           borderRadius: BorderRadius.circular(14),
// // // // // // // //           border: Border.all(color: Colors.black),
// // // // // // // //         ),
// // // // // // // //         child: Text(
// // // // // // // //           "$label (${_getCount(label.toLowerCase())})",
// // // // // // // //           style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   // 🔢 Count logic
// // // // // // // //   int _getCount(String status) {
// // // // // // // //     return allLeaveRequests
// // // // // // // //         .where((e) => (selectedTab == 'All' || e['type'] == selectedTab) && e['status'] == status)
// // // // // // // //         .length;
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:intl/intl.dart';
// // // // // // // import 'leave_data.dart';
// // // // // // // import 'leave_card.dart';

// // // // // // // class LeaveApprovalsScreen extends StatefulWidget {
// // // // // // //   const LeaveApprovalsScreen({super.key});

// // // // // // //   @override
// // // // // // //   State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
// // // // // // // }

// // // // // // // class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
// // // // // // //   String selectedTab = 'All';
// // // // // // //   String selectedStatusFilter = 'All';
// // // // // // //   final TextEditingController searchController = TextEditingController();

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final today = DateFormat('dd MMM yyyy').format(DateTime.now());

// // // // // // //     List<Map<String, dynamic>> filtered = allLeaveRequests
// // // // // // //         .where((leave) => selectedTab == 'All' || leave['type'] == selectedTab)
// // // // // // //         .where((leave) =>
// // // // // // //             selectedStatusFilter == 'All' ||
// // // // // // //             leave['status'] == selectedStatusFilter.toLowerCase())
// // // // // // //         .where((leave) => leave.values.any((v) => v
// // // // // // //             .toString()
// // // // // // //             .toLowerCase()
// // // // // // //             .contains(searchController.text.toLowerCase())))
// // // // // // //         .toList();

// // // // // // //     return Scaffold(
// // // // // // //       appBar: AppBar(
// // // // // // //         backgroundColor: const Color(0xFF8C6EAF),
// // // // // // //         title: const Text("Leave Approvals"),
// // // // // // //         actions: [
// // // // // // //           Padding(
// // // // // // //             padding: const EdgeInsets.all(12),
// // // // // // //             child: Center(child: Text(today)),
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //       body: Container(
// // // // // // //         padding: const EdgeInsets.all(10),
// // // // // // //         decoration: const BoxDecoration(
// // // // // // //           gradient: LinearGradient(
// // // // // // //             colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
// // // // // // //             begin: Alignment.topCenter,
// // // // // // //             end: Alignment.bottomCenter,
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         child: Column(
// // // // // // //           children: [
// // // // // // //             // 🔁 Horizontal scroll for filters (overflow fixed)
// // // // // // //             SingleChildScrollView(
// // // // // // //               scrollDirection: Axis.horizontal,
// // // // // // //               child: Row(
// // // // // // //                 children: [
// // // // // // //                   Container(
// // // // // // //                     height: 30,
// // // // // // //                     padding: const EdgeInsets.symmetric(horizontal: 6),
// // // // // // //                     margin: const EdgeInsets.only(right: 6),
// // // // // // //                     decoration: BoxDecoration(
// // // // // // //                       color: Colors.deepPurple[100],
// // // // // // //                       borderRadius: BorderRadius.circular(10),
// // // // // // //                       border: Border.all(color: Colors.black),
// // // // // // //                     ),
// // // // // // //                     child: DropdownButtonHideUnderline(
// // // // // // //                       child: DropdownButton<String>(
// // // // // // //                         value: selectedTab,
// // // // // // //                         onChanged: (val) => setState(() => selectedTab = val!),
// // // // // // //                         icon: const Icon(Icons.arrow_drop_down,
// // // // // // //                             size: 18, color: Colors.black),
// // // // // // //                         style: const TextStyle(
// // // // // // //                             color: Colors.black,
// // // // // // //                             fontSize: 12,
// // // // // // //                             fontWeight: FontWeight.w500),
// // // // // // //                         dropdownColor: Colors.white,
// // // // // // //                         isDense: true,
// // // // // // //                         isExpanded: false,
// // // // // // //                         items: [
// // // // // // //                           'All',
// // // // // // //                           'Late check in',
// // // // // // //                           'Late check out',
// // // // // // //                           'Leave Type',
// // // // // // //                           'Permission',
// // // // // // //                           'Over Time',
// // // // // // //                           'Half Day Leave',
// // // // // // //                           'Comp Off'
// // // // // // //                         ]
// // // // // // //                             .map((type) => DropdownMenuItem(
// // // // // // //                                   value: type,
// // // // // // //                                   child: Text(type),
// // // // // // //                                 ))
// // // // // // //                             .toList(),
// // // // // // //                       ),
// // // // // // //                     ),
// // // // // // //                   ),
// // // // // // //                   _buildStatusButton("Pending", Colors.pink[100]!),
// // // // // // //                   const SizedBox(width: 6),
// // // // // // //                   _buildStatusButton("Approved", Colors.greenAccent),
// // // // // // //                   const SizedBox(width: 6),
// // // // // // //                   _buildStatusButton("Rejected", Colors.red[200]!),
// // // // // // //                 ],
// // // // // // //               ),
// // // // // // //             ),

// // // // // // //             const SizedBox(height: 10),

// // // // // // //             // 🔍 Search bar
// // // // // // //             TextField(
// // // // // // //               controller: searchController,
// // // // // // //               onChanged: (_) => setState(() {}),
// // // // // // //               decoration: InputDecoration(
// // // // // // //                 hintText: 'Search...',
// // // // // // //                 prefixIcon: const Icon(Icons.search),
// // // // // // //                 filled: true,
// // // // // // //                 fillColor: Colors.white,
// // // // // // //                 border: OutlineInputBorder(
// // // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //             const SizedBox(height: 10),

// // // // // // //             // 📝 Leave card list
// // // // // // //             Expanded(
// // // // // // //               child: ListView.builder(
// // // // // // //                 itemCount: filtered.length,
// // // // // // //                 itemBuilder: (context, index) {
// // // // // // //                   final leave = filtered[index];
// // // // // // //                   return LeaveCard(
// // // // // // //                     item: leave,
// // // // // // //                     onStatusChange: (status) {
// // // // // // //                       setState(() {
// // // // // // //                         leave['status'] = status;
// // // // // // //                       });
// // // // // // //                     },
// // // // // // //                   );
// // // // // // //                 },
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ],
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }

// // // // // // //   // 🔘 Filter button with count
// // // // // // //   Widget _buildStatusButton(String label, Color color) {
// // // // // // //     return GestureDetector(
// // // // // // //       onTap: () => setState(() => selectedStatusFilter = label),
// // // // // // //       child: Container(
// // // // // // //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // // // // //         decoration: BoxDecoration(
// // // // // // //           color: color,
// // // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // // //           border: Border.all(color: Colors.black),
// // // // // // //         ),
// // // // // // //         child: Text(
// // // // // // //           "$label (${_getCount(label.toLowerCase())})",
// // // // // // //           style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }

// // // // // // //   // 🔢 Count for each filter button
// // // // // // //   int _getCount(String status) {
// // // // // // //     return allLeaveRequests
// // // // // // //         .where((e) =>
// // // // // // //             (selectedTab == 'All' || e['type'] == selectedTab) &&
// // // // // // //             e['status'] == status)
// // // // // // //         .length;
// // // // // // //   }
// // // // // // // }
// // // // // // // lib/Pagesadmin/leave_approval_screen.dart
// // // // // // // lib/Pagesadmin/leave_approval_screen.dart
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:intl/intl.dart';
// // // // // // import '../services/api_service.dart';
// // // // // // import '../models/leave_approval.dart'; // Update the path if your ApiService is not in ../services/

// // // // // // import 'leave_card.dart';

// // // // // // class LeaveApprovalsScreen extends StatefulWidget {
// // // // // //   const LeaveApprovalsScreen({super.key});

// // // // // //   @override
// // // // // //   State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
// // // // // // }

// // // // // // class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
// // // // // //   String selectedTab = 'All';
// // // // // //   String selectedStatusFilter = 'Pending';
// // // // // //   final TextEditingController searchController = TextEditingController();

// // // // // //   bool _loading = false;
// // // // // //   List<LeaveApproval> _items = [];

// // // // // //   // chip counts
// // // // // //   Map<String, int> _counts = {'Pending': 0, 'Approved': 0, 'Rejected': 0};

// // // // // //   final List<String> _types = const [
// // // // // //     'All',
// // // // // //     'Late check in',
// // // // // //     'Late check out',
// // // // // //     'Leave Type',
// // // // // //     'Permission',
// // // // // //     'Over Time',
// // // // // //     'Half Day Leave',
// // // // // //     'Comp Off',
// // // // // //   ];

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     _loadAll(); // initial
// // // // // //     searchController.addListener(() => setState(() {}));
// // // // // //   }

// // // // // //   Future<void> _loadAll() async {
// // // // // //     await Future.wait([_loadList(), _loadCounts()]);
// // // // // //   }

// // // // // //   Future<void> _loadList() async {
// // // // // //     setState(() => _loading = true);
// // // // // //     try {
// // // // // //       final data = await ApiService.fetchApprovals(
// // // // // //         type: selectedTab == 'All' ? '' : selectedTab,
// // // // // //         status: selectedStatusFilter,
// // // // // //       );
// // // // // //       setState(() => _items = data.cast<LeaveApproval>());
// // // // // //     } catch (e) {
// // // // // //       _toast('Failed to fetch approvals: $e');
// // // // // //     } finally {
// // // // // //       if (mounted) setState(() => _loading = false);
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _loadCounts() async {
// // // // // //     try {
// // // // // //       final c = await ApiService.fetchCountsForType(selectedTab);
// // // // // //       setState(() => _counts = c);
// // // // // //     } catch (_) {
// // // // // //       // ignore count errors silently; the list still works
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _refreshAfterDecision() async {
// // // // // //     await Future.wait([_loadList(), _loadCounts()]);
// // // // // //   }

// // // // // //   void _toast(String msg) {
// // // // // //     if (!mounted) return;
// // // // // //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// // // // // //   }

// // // // // //   Future<void> _handleDecision(Map<String, dynamic> map, String decisionLower) async {
// // // // // //     // Map from card -> API
// // // // // //     final reqId = (map['_requestId'] ?? '').toString();
// // // // // //     final empid = (map['empid'] ?? map['id'] ?? '').toString();
// // // // // //     final dateIso = (map['_requestDateIso'] ?? '').toString();
// // // // // //     if (reqId.isEmpty || empid.isEmpty || dateIso.isEmpty) {
// // // // // //       _toast('Missing request details');
// // // // // //       return;
// // // // // //     }

// // // // // //     final decision = decisionLower.toLowerCase() == 'approved' ? 'Approved' : 'Rejected';
// // // // // //     setState(() => _loading = true);
// // // // // //     try {
// // // // // //       await ApiService.decideAttendance(
// // // // // //         requestId: reqId,
// // // // // //         empid: empid,
// // // // // //         date: dateIso,
// // // // // //         status: decision,
// // // // // //         reviewer: 'admin001',
// // // // // //         remarks: decision == 'Approved' ? 'OK' : 'Rejected by admin',
// // // // // //       );
// // // // // //       _toast('Attendance ${decision.toLowerCase()} successfully');
// // // // // //       await _refreshAfterDecision();
// // // // // //     } catch (e) {
// // // // // //       _toast('Decision failed: $e');
// // // // // //     } finally {
// // // // // //       if (mounted) setState(() => _loading = false);
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final today = DateFormat('dd MMM yyyy').format(DateTime.now());

// // // // // //     // local search filter (keeps UI behavior the same)
// // // // // //     final q = searchController.text.toLowerCase();
// // // // // //     final filtered = _items.where((a) {
// // // // // //       if (q.isEmpty) return true;
// // // // // //       final m = a.toMap();
// // // // // //       return m.values.any((v) => (v ?? '').toString().toLowerCase().contains(q));
// // // // // //     }).toList();

// // // // // //     return Scaffold(
// // // // // //       appBar: AppBar(
// // // // // //         backgroundColor: const Color(0xFF8C6EAF),
// // // // // //         title: const Text("Leave Approvals"),
// // // // // //         actions: [
// // // // // //           Padding(
// // // // // //             padding: const EdgeInsets.all(12),
// // // // // //             child: Center(child: Text(today)),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //       body: Stack(
// // // // // //         children: [
// // // // // //           Container(
// // // // // //             padding: const EdgeInsets.all(10),
// // // // // //             decoration: const BoxDecoration(
// // // // // //               gradient: LinearGradient(
// // // // // //                 colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
// // // // // //                 begin: Alignment.topCenter,
// // // // // //                 end: Alignment.bottomCenter,
// // // // // //               ),
// // // // // //             ),
// // // // // //             child: Column(
// // // // // //               children: [
// // // // // //                 // 🔁 Horizontal scroll for filters (UI unchanged)
// // // // // //                 SingleChildScrollView(
// // // // // //                   scrollDirection: Axis.horizontal,
// // // // // //                   child: Row(
// // // // // //                     children: [
// // // // // //                       Container(
// // // // // //                         height: 30,
// // // // // //                         padding: const EdgeInsets.symmetric(horizontal: 6),
// // // // // //                         margin: const EdgeInsets.only(right: 6),
// // // // // //                         decoration: BoxDecoration(
// // // // // //                           color: Colors.deepPurple[100],
// // // // // //                           borderRadius: BorderRadius.circular(10),
// // // // // //                           border: Border.all(color: Colors.black),
// // // // // //                         ),
// // // // // //                         child: DropdownButtonHideUnderline(
// // // // // //                           child: DropdownButton<String>(
// // // // // //                             value: selectedTab,
// // // // // //                             onChanged: (val) async {
// // // // // //                               if (val == null) return;
// // // // // //                               setState(() => selectedTab = val);
// // // // // //                               await _loadAll();
// // // // // //                             },
// // // // // //                             icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black),
// // // // // //                             style: const TextStyle(
// // // // // //                               color: Colors.black,
// // // // // //                               fontSize: 12,
// // // // // //                               fontWeight: FontWeight.w500,
// // // // // //                             ),
// // // // // //                             dropdownColor: Colors.white,
// // // // // //                             isDense: true,
// // // // // //                             isExpanded: false,
// // // // // //                             items: _types
// // // // // //                                 .map((type) => DropdownMenuItem(
// // // // // //                                       value: type,
// // // // // //                                       child: Text(type),
// // // // // //                                     ))
// // // // // //                                 .toList(),
// // // // // //                           ),
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                       _buildStatusButton("Pending", Colors.pink[100]!),
// // // // // //                       const SizedBox(width: 6),
// // // // // //                       _buildStatusButton("Approved", Colors.greenAccent),
// // // // // //                       const SizedBox(width: 6),
// // // // // //                       _buildStatusButton("Rejected", Colors.red[200]!),
// // // // // //                     ],
// // // // // //                   ),
// // // // // //                 ),

// // // // // //                 const SizedBox(height: 10),

// // // // // //                 // 🔍 Search bar
// // // // // //                 TextField(
// // // // // //                   controller: searchController,
// // // // // //                   decoration: InputDecoration(
// // // // // //                     hintText: 'Search...',
// // // // // //                     prefixIcon: const Icon(Icons.search),
// // // // // //                     filled: true,
// // // // // //                     fillColor: Colors.white,
// // // // // //                     border: OutlineInputBorder(
// // // // // //                       borderRadius: BorderRadius.circular(12),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 10),

// // // // // //                 // 📝 Leave card list
// // // // // //                 Expanded(
// // // // // //                   child: RefreshIndicator(
// // // // // //                     onRefresh: _loadAll,
// // // // // //                     child: ListView.builder(
// // // // // //                       itemCount: filtered.length,
// // // // // //                       itemBuilder: (context, index) {
// // // // // //                         final leave = filtered[index].toMap();
// // // // // //                         return LeaveCard(
// // // // // //                           item: leave,
// // // // // //                           onStatusChange: (status) {
// // // // // //                             // status is 'approved' or 'rejected' from the existing card/detail UI.
// // // // // //                             _handleDecision(leave, status);
// // // // // //                           },
// // // // // //                         );
// // // // // //                       },
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),

// // // // // //           // simple loading overlay (UI layout unchanged beneath)
// // // // // //           if (_loading)
// // // // // //             Container(
// // // // // //               color: Colors.black.withOpacity(0.15),
// // // // // //               child: const Center(child: CircularProgressIndicator()),
// // // // // //             ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   // 🔘 Filter button with count (kept same visuals)
// // // // // //   Widget _buildStatusButton(String label, Color color) {
// // // // // //     return GestureDetector(
// // // // // //       onTap: () async {
// // // // // //         setState(() => selectedStatusFilter = label);
// // // // // //         await _loadList();
// // // // // //       },
// // // // // //       child: Container(
// // // // // //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // // // //         decoration: BoxDecoration(
// // // // // //           color: color,
// // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // //           border: Border.all(color: Colors.black),
// // // // // //         ),
// // // // // //         child: Text(
// // // // // //           "$label (${_counts[label] ?? 0})",
// // // // // //           style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:intl/intl.dart';
// // // // // import '../services/api_service.dart';
// // // // // import 'leave_card.dart';

// // // // // class LeaveApprovalsScreen extends StatefulWidget {
// // // // //   const LeaveApprovalsScreen({super.key});

// // // // //   @override
// // // // //   State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
// // // // // }

// // // // // class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
// // // // //   String selectedTab = 'All';
// // // // //   String selectedStatusFilter = 'All';
// // // // //   final TextEditingController searchController = TextEditingController();

// // // // //   List<Map<String, dynamic>> _items = [];
// // // // //   bool _loading = false;

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _loadAll();
// // // // //   }

// // // // //   Future<void> _loadAll() async {
// // // // //     setState(() => _loading = true);
// // // // //     try {
// // // // //       final data = await ApiService.fetchApprovals(
// // // // //         type: selectedTab,
// // // // //         status: selectedStatusFilter == 'All'
// // // // //             ? 'Pending'
// // // // //             : selectedStatusFilter,
// // // // //       );
// // // // //       setState(() => _items = data);
// // // // //     } catch (e) {
// // // // //       _snack('Failed to fetch approvals: $e');
// // // // //       setState(() => _items = []);
// // // // //     } finally {
// // // // //       if (mounted) setState(() => _loading = false);
// // // // //     }
// // // // //   }

// // // // //   void _snack(String msg) =>
// // // // //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final today = DateFormat('dd MMM yyyy').format(DateTime.now());

// // // // //     // local filter for search box (server-side filtering already applied)
// // // // //     final filtered = _items
// // // // //         .where(
// // // // //           (leave) => leave.values.any(
// // // // //             (v) => (v ?? '').toString().toLowerCase().contains(
// // // // //               searchController.text.toLowerCase(),
// // // // //             ),
// // // // //           ),
// // // // //         )
// // // // //         .toList();

// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //         backgroundColor: const Color(0xFF8C6EAF),
// // // // //         title: const Text("Leave Approvals"),
// // // // //         actions: [
// // // // //           Padding(
// // // // //             padding: const EdgeInsets.all(12),
// // // // //             child: Center(child: Text(today)),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //       body: Container(
// // // // //         padding: const EdgeInsets.all(10),
// // // // //         decoration: const BoxDecoration(
// // // // //           gradient: LinearGradient(
// // // // //             colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
// // // // //             begin: Alignment.topCenter,
// // // // //             end: Alignment.bottomCenter,
// // // // //           ),
// // // // //         ),
// // // // //         child: Column(
// // // // //           children: [
// // // // //             SingleChildScrollView(
// // // // //               scrollDirection: Axis.horizontal,
// // // // //               child: Row(
// // // // //                 children: [
// // // // //                   Container(
// // // // //                     height: 30,
// // // // //                     padding: const EdgeInsets.symmetric(horizontal: 6),
// // // // //                     margin: const EdgeInsets.only(right: 6),
// // // // //                     decoration: BoxDecoration(
// // // // //                       color: Colors.deepPurple[100],
// // // // //                       borderRadius: BorderRadius.circular(10),
// // // // //                       border: Border.all(color: Colors.black),
// // // // //                     ),
// // // // //                     child: DropdownButtonHideUnderline(
// // // // //                       child: DropdownButton<String>(
// // // // //                         value: selectedTab,
// // // // //                         onChanged: (val) async {
// // // // //                           setState(() => selectedTab = val!);
// // // // //                           await _loadAll();
// // // // //                         },
// // // // //                         icon: const Icon(
// // // // //                           Icons.arrow_drop_down,
// // // // //                           size: 18,
// // // // //                           color: Colors.black,
// // // // //                         ),
// // // // //                         style: const TextStyle(
// // // // //                           color: Colors.black,
// // // // //                           fontSize: 12,
// // // // //                           fontWeight: FontWeight.w500,
// // // // //                         ),
// // // // //                         dropdownColor: Colors.white,
// // // // //                         isDense: true,
// // // // //                         isExpanded: false,
// // // // //                         items:
// // // // //                             const [
// // // // //                                   'All',
// // // // //                                   'Late check in',
// // // // //                                   'Early check out',
// // // // //                                   'Leave Type',
// // // // //                                   'Permission',
// // // // //                                   'Over Time',
// // // // //                                   'Half Day Leave',
// // // // //                                   'Comp Off',
// // // // //                                 ]
// // // // //                                 .map(
// // // // //                                   (type) => DropdownMenuItem(
// // // // //                                     value: type,
// // // // //                                     child: Text(type),
// // // // //                                   ),
// // // // //                                 )
// // // // //                                 .toList(),
// // // // //                       ),
// // // // //                     ),
// // // // //                   ),
// // // // //                   _buildStatusButton("Pending"),
// // // // //                   const SizedBox(width: 6),
// // // // //                   _buildStatusButton("Approved"),
// // // // //                   const SizedBox(width: 6),
// // // // //                   _buildStatusButton("Rejected"),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //             const SizedBox(height: 10),
// // // // //             TextField(
// // // // //               controller: searchController,
// // // // //               onChanged: (_) => setState(() {}),
// // // // //               decoration: InputDecoration(
// // // // //                 hintText: 'Search...',
// // // // //                 prefixIcon: const Icon(Icons.search),
// // // // //                 filled: true,
// // // // //                 fillColor: Colors.white,
// // // // //                 border: OutlineInputBorder(
// // // // //                   borderRadius: BorderRadius.circular(12),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //             const SizedBox(height: 10),
// // // // //             if (_loading)
// // // // //               const Expanded(child: Center(child: CircularProgressIndicator()))
// // // // //             else
// // // // //               Expanded(
// // // // //                 child: filtered.isEmpty
// // // // //                     ? const Center(child: Text('No requests'))
// // // // //                     : ListView.builder(
// // // // //                         itemCount: filtered.length,
// // // // //                         itemBuilder: (context, index) {
// // // // //                           final leave = filtered[index];
// // // // //                           return LeaveCard(
// // // // //                             item: leave,
// // // // //                             onStatusChange: (status) async {
// // // // //                               // Only attendance requests have decision API in current backend
// // // // //                               final type = (leave['type'] ?? '')
// // // // //                                   .toString()
// // // // //                                   .toLowerCase();
// // // // //                               if (type.startsWith('late check')) {
// // // // //                                 try {
// // // // //                                   await ApiService.decideApproval(
// // // // //                                     requestId:
// // // // //                                         leave['requestId']?.toString() ?? '',
// // // // //                                     status:
// // // // //                                         status[0].toUpperCase() +
// // // // //                                         status.substring(1).toLowerCase(),
// // // // //                                     empid: leave['empid']?.toString() ?? '',
// // // // //                                     date:
// // // // //                                         leave['requestDate']?.toString() ?? '',
// // // // //                                     item: {
// // // // //                                       'requestId':
// // // // //                                           leave['requestId']?.toString() ?? '',
// // // // //                                       'empid': leave['empid']?.toString() ?? '',
// // // // //                                       'date':
// // // // //                                           leave['requestDate']?.toString() ??
// // // // //                                           '',
// // // // //                                     },
// // // // //                                   );
// // // // //                                   _snack('Updated: $status');
// // // // //                                   await _loadAll();
// // // // //                                 } catch (e) {
// // // // //                                   _snack('Update failed: $e');
// // // // //                                 }
// // // // //                               }
// // // // //                             },
// // // // //                           );
// // // // //                         },
// // // // //                       ),
// // // // //               ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildStatusButton(String label) {
// // // // //     final color = label == 'Pending'
// // // // //         ? Colors.pink[100]!
// // // // //         : label == 'Approved'
// // // // //         ? Colors.greenAccent
// // // // //         : Colors.red[200]!;
// // // // //     return GestureDetector(
// // // // //       onTap: () async {
// // // // //         setState(() => selectedStatusFilter = label);
// // // // //         await _loadAll();
// // // // //       },
// // // // //       child: Container(
// // // // //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // // //         decoration: BoxDecoration(
// // // // //           color: color,
// // // // //           borderRadius: BorderRadius.circular(12),
// // // // //           border: Border.all(color: Colors.black),
// // // // //         ),
// // // // //         child: Text(
// // // // //           // counts could be added later with a separate endpoint
// // // // //           "$label (0)",
// // // // //           style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // // // lib/Pagesadmin/leave_approval_screen.dart
// // // // import 'package:flutter/material.dart';
// // // // import 'package:intl/intl.dart';
// // // // import '../services/api_service.dart';
// // // // import 'leave_card.dart';

// // // // class LeaveApprovalsScreen extends StatefulWidget {
// // // //   const LeaveApprovalsScreen({super.key});

// // // //   @override
// // // //   State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
// // // // }

// // // // class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
// // // //   String selectedTab = 'All'; // Type filter
// // // //   String selectedStatusFilter = 'All'; // Status filter
// // // //   final TextEditingController searchController = TextEditingController();

// // // //   List<Map<String, dynamic>> _items = [];
// // // //   bool _loading = false;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _loadAll();
// // // //   }

// // // //   Future<void> _loadAll() async {
// // // //     setState(() => _loading = true);
// // // //     try {
// // // //       final data = await ApiService.fetchApprovals(
// // // //         type: selectedTab,
// // // //         status: selectedStatusFilter,
// // // //       );
// // // //       setState(() => _items = data);
// // // //     } catch (e) {
// // // //       _snack('Failed to fetch approvals: $e');
// // // //       setState(() => _items = []);
// // // //     } finally {
// // // //       if (mounted) setState(() => _loading = false);
// // // //     }
// // // //   }

// // // //   void _snack(String msg) =>
// // // //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final today = DateFormat('dd MMM yyyy').format(DateTime.now());

// // // //     // local search filter
// // // //     final filtered = _items
// // // //         .where(
// // // //           (leave) => leave.values.any(
// // // //             (v) => (v ?? '').toString().toLowerCase().contains(
// // // //               searchController.text.toLowerCase(),
// // // //             ),
// // // //           ),
// // // //         )
// // // //         .toList();

// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         backgroundColor: const Color(0xFF8C6EAF),
// // // //         title: const Text("Leave Approvals"),
// // // //         actions: [
// // // //           Padding(
// // // //             padding: const EdgeInsets.all(12),
// // // //             child: Center(child: Text(today)),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       body: Container(
// // // //         padding: const EdgeInsets.all(10),
// // // //         decoration: const BoxDecoration(
// // // //           gradient: LinearGradient(
// // // //             colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
// // // //             begin: Alignment.topCenter,
// // // //             end: Alignment.bottomCenter,
// // // //           ),
// // // //         ),
// // // //         child: Column(
// // // //           children: [
// // // //             SingleChildScrollView(
// // // //               scrollDirection: Axis.horizontal,
// // // //               child: Row(
// // // //                 children: [
// // // //                   Container(
// // // //                     height: 30,
// // // //                     padding: const EdgeInsets.symmetric(horizontal: 6),
// // // //                     margin: const EdgeInsets.only(right: 6),
// // // //                     decoration: BoxDecoration(
// // // //                       color: Colors.deepPurple[100],
// // // //                       borderRadius: BorderRadius.circular(10),
// // // //                       border: Border.all(color: Colors.black),
// // // //                     ),
// // // //                     child: DropdownButtonHideUnderline(
// // // //                       child: DropdownButton<String>(
// // // //                         value: selectedTab,
// // // //                         onChanged: (val) async {
// // // //                           setState(() => selectedTab = val!);
// // // //                           await _loadAll();
// // // //                         },
// // // //                         icon: const Icon(
// // // //                           Icons.arrow_drop_down,
// // // //                           size: 18,
// // // //                           color: Colors.black,
// // // //                         ),
// // // //                         style: const TextStyle(
// // // //                           color: Colors.black,
// // // //                           fontSize: 12,
// // // //                           fontWeight: FontWeight.w500,
// // // //                         ),
// // // //                         dropdownColor: Colors.white,
// // // //                         isDense: true,
// // // //                         isExpanded: false,
// // // //                         items:
// // // //                             const [
// // // //                                   'All',
// // // //                                   'Late check in',
// // // //                                   'Late check out',
// // // //                                   'Leave Type',
// // // //                                   'Permission',
// // // //                                   'Over Time',
// // // //                                   'Half Day Leave',
// // // //                                   'Comp Off',
// // // //                                 ]
// // // //                                 .map(
// // // //                                   (type) => DropdownMenuItem(
// // // //                                     value: type,
// // // //                                     child: Text(type),
// // // //                                   ),
// // // //                                 )
// // // //                                 .toList(),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                   _buildStatusButton("Pending"),
// // // //                   const SizedBox(width: 6),
// // // //                   _buildStatusButton("Approved"),
// // // //                   const SizedBox(width: 6),
// // // //                   _buildStatusButton("Rejected"),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //             TextField(
// // // //               controller: searchController,
// // // //               onChanged: (_) => setState(() {}),
// // // //               decoration: InputDecoration(
// // // //                 hintText: 'Search...',
// // // //                 prefixIcon: const Icon(Icons.search),
// // // //                 filled: true,
// // // //                 fillColor: Colors.white,
// // // //                 border: OutlineInputBorder(
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //             if (_loading)
// // // //               const Expanded(child: Center(child: CircularProgressIndicator()))
// // // //             else
// // // //               Expanded(
// // // //                 child: filtered.isEmpty
// // // //                     ? const Center(child: Text('No requests'))
// // // //                     : ListView.builder(
// // // //                         itemCount: filtered.length,
// // // //                         itemBuilder: (context, index) {
// // // //                           final leave = filtered[index];
// // // //                           return LeaveCard(
// // // //                             item: leave,
// // // //                             onStatusChange: (status) async {
// // // //                               try {
// // // //                                 await ApiService.decideApproval(
// // // //                                   item: leave, // pass the full map
// // // //                                   status: status,
// // // //                                 );
// // // //                                 _snack('Updated: $status');
// // // //                                 await _loadAll();
// // // //                               } catch (e) {
// // // //                                 _snack('Update failed: $e');
// // // //                               }
// // // //                             },
// // // //                           );
// // // //                         },
// // // //                       ),
// // // //               ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildStatusButton(String label) {
// // // //     final color = label == 'Pending'
// // // //         ? Colors.pink[100]!
// // // //         : label == 'Approved'
// // // //         ? Colors.greenAccent
// // // //         : Colors.red[200]!;
// // // //     return GestureDetector(
// // // //       onTap: () async {
// // // //         setState(() => selectedStatusFilter = label);
// // // //         await _loadAll();
// // // //       },
// // // //       child: Container(
// // // //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // //         decoration: BoxDecoration(
// // // //           color: color,
// // // //           borderRadius: BorderRadius.circular(12),
// // // //           border: Border.all(color: Colors.black),
// // // //         ),
// // // //         child: Text(
// // // //           "$label (0)", // counts could be added later
// // // //           style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // // lib/Pagesadmin/leave_approval_screen.dart
// // // import 'package:flutter/material.dart';
// // // import 'package:intl/intl.dart';
// // // import '../services/api_service.dart';
// // // import 'leave_card.dart';

// // // class LeaveApprovalsScreen extends StatefulWidget {
// // //   const LeaveApprovalsScreen({super.key});

// // //   @override
// // //   State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
// // // }

// // // class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
// // //   String selectedTab = 'All';           // Type filter
// // //   String selectedStatusFilter = 'Pending';  // default to Pending
// // //   final TextEditingController searchController = TextEditingController();

// // //   // data & counts
// // //   List<Map<String, dynamic>> _items = [];
// // //   int _cPending = 0, _cApproved = 0, _cRejected = 0;

// // //   bool _loading = false;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadAll();
// // //   }

// // //   Future<void> _loadAll() async {
// // //     setState(() => _loading = true);
// // //     try {
// // //       // Fetch all three statuses for the selected TYPE so we can show counts
// // //       final results = await Future.wait<List<Map<String, dynamic>>>([
// // //         ApiService.fetchApprovals(type: selectedTab, status: 'Pending'),
// // //         ApiService.fetchApprovals(type: selectedTab, status: 'Approved'),
// // //         ApiService.fetchApprovals(type: selectedTab, status: 'Rejected'),
// // //       ]);

// // //       final pending = results[0];
// // //       final approved = results[1];
// // //       final rejected = results[2];

// // //       // update counts
// // //       _cPending = pending.length;
// // //       _cApproved = approved.length;
// // //       _cRejected = rejected.length;

// // //       // choose which list to display based on selected status chip
// // //       List<Map<String, dynamic>> current;
// // //       switch (selectedStatusFilter) {
// // //         case 'Approved':
// // //           current = approved;
// // //           break;
// // //         case 'Rejected':
// // //           current = rejected;
// // //           break;
// // //         case 'Pending':
// // //         default:
// // //           current = pending;
// // //       }

// // //       setState(() => _items = current);
// // //     } catch (e) {
// // //       _snack('Failed to fetch approvals: $e');
// // //       setState(() {
// // //         _items = [];
// // //         _cPending = _cApproved = _cRejected = 0;
// // //       });
// // //     } finally {
// // //       if (mounted) setState(() => _loading = false);
// // //     }
// // //   }

// // //   void _snack(String msg) =>
// // //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final today = DateFormat('dd MMM yyyy').format(DateTime.now());

// // //     // local search filter
// // //     final filtered = _items
// // //         .where((leave) => leave.values.any((v) =>
// // //             (v ?? '')
// // //                 .toString()
// // //                 .toLowerCase()
// // //                 .contains(searchController.text.toLowerCase())))
// // //         .toList();

// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         backgroundColor: const Color(0xFF8C6EAF),
// // //         title: const Text("Leave Approvals"),
// // //         actions: [
// // //           Padding(
// // //             padding: const EdgeInsets.all(12),
// // //             child: Center(child: Text(today)),
// // //           ),
// // //         ],
// // //       ),
// // //       body: Container(
// // //         padding: const EdgeInsets.all(10),
// // //         decoration: const BoxDecoration(
// // //           gradient: LinearGradient(
// // //             colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
// // //             begin: Alignment.topCenter,
// // //             end: Alignment.bottomCenter,
// // //           ),
// // //         ),
// // //         child: Column(
// // //           children: [
// // //             SingleChildScrollView(
// // //               scrollDirection: Axis.horizontal,
// // //               child: Row(
// // //                 children: [
// // //                   // Type selector
// // //                   Container(
// // //                     height: 30,
// // //                     padding: const EdgeInsets.symmetric(horizontal: 6),
// // //                     margin: const EdgeInsets.only(right: 6),
// // //                     decoration: BoxDecoration(
// // //                       color: Colors.deepPurple[100],
// // //                       borderRadius: BorderRadius.circular(10),
// // //                       border: Border.all(color: Colors.black),
// // //                     ),
// // //                     child: DropdownButtonHideUnderline(
// // //                       child: DropdownButton<String>(
// // //                         value: selectedTab,
// // //                         onChanged: (val) async {
// // //                           setState(() => selectedTab = val!);
// // //                           await _loadAll();
// // //                         },
// // //                         icon: const Icon(Icons.arrow_drop_down,
// // //                             size: 18, color: Colors.black),
// // //                         style: const TextStyle(
// // //                             color: Colors.black,
// // //                             fontSize: 12,
// // //                             fontWeight: FontWeight.w500),
// // //                         dropdownColor: Colors.white,
// // //                         isDense: true,
// // //                         isExpanded: false,
// // //                         items: const [
// // //                           'All',
// // //                           'Late check in',
// // //                           'Early check out',
// // //                           'Leave Type',
// // //                           'Permission',
// // //                           'Over Time',
// // //                           'Half Day Leave',
// // //                           'Comp Off'
// // //                         ]
// // //                             .map((type) =>
// // //                                 DropdownMenuItem(value: type, child: Text(type)))
// // //                             .toList(),
// // //                       ),
// // //                     ),
// // //                   ),

// // //                   // Status chips with live counts
// // //                   _buildStatusButton("Pending", _cPending),
// // //                   const SizedBox(width: 6),
// // //                   _buildStatusButton("Approved", _cApproved),
// // //                   const SizedBox(width: 6),
// // //                   _buildStatusButton("Rejected", _cRejected),
// // //                 ],
// // //               ),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextField(
// // //               controller: searchController,
// // //               onChanged: (_) => setState(() {}),
// // //               decoration: InputDecoration(
// // //                 hintText: 'Search...',
// // //                 prefixIcon: const Icon(Icons.search),
// // //                 filled: true,
// // //                 fillColor: Colors.white,
// // //                 border:
// // //                     OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// // //               ),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             if (_loading)
// // //               const Expanded(child: Center(child: CircularProgressIndicator()))
// // //             else
// // //               Expanded(
// // //                 child: filtered.isEmpty
// // //                     ? const Center(child: Text('No requests'))
// // //                     : ListView.builder(
// // //                         itemCount: filtered.length,
// // //                         itemBuilder: (context, index) {
// // //                           final leave = filtered[index];
// // //                           return LeaveCard(
// // //                             item: leave,
// // //                             onStatusChange: (status) async {
// // //                               try {
// // //                                 await ApiService.decideApproval(
// // //                                   item: leave,
// // //                                   status: status,
// // //                                 );
// // //                                 _snack('Updated: $status');
// // //                                 await _loadAll(); // refresh counts + list
// // //                               } catch (e) {
// // //                                 _snack('Update failed: $e');
// // //                               }
// // //                             },
// // //                           );
// // //                         },
// // //                       ),
// // //               ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildStatusButton(String label, int count) {
// // //     final color = label == 'Pending'
// // //         ? Colors.pink[100]!
// // //         : label == 'Approved'
// // //             ? Colors.greenAccent
// // //             : Colors.red[200]!;
// // //     final isSelected = selectedStatusFilter == label;

// // //     return GestureDetector(
// // //       onTap: () async {
// // //         setState(() => selectedStatusFilter = label);
// // //         await _loadAll(); // switch list to that status
// // //       },
// // //       child: Container(
// // //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //         decoration: BoxDecoration(
// // //           color: color.withOpacity(isSelected ? 1.0 : 0.7),
// // //           borderRadius: BorderRadius.circular(12),
// // //           border: Border.all(color: Colors.black),
// // //         ),
// // //         child: Text(
// // //           "$label ($count)",
// // //           style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// // import '../services/api_service.dart';
// // import 'leave_card.dart';

// // class LeaveApprovalsScreen extends StatefulWidget {
// //   const LeaveApprovalsScreen({super.key});

// //   @override
// //   State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
// // }

// // class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
// //   String selectedTab = 'All';                // Type filter
// //   String selectedStatusFilter = 'Pending';   // Status chip
// //   final TextEditingController searchController = TextEditingController();

// //   // data & counts
// //   List<Map<String, dynamic>> _items = [];
// //   int _cPending = 0, _cApproved = 0, _cRejected = 0;

// //   bool _loading = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadAll(adjustForType: true); // first load: pick a status that has data
// //   }

// //   /// Fetch all three statuses for current [selectedTab].
// //   /// If [adjustForType] is true, auto-switch the selected status to the
// //   /// first non-empty bucket (Pending → Approved → Rejected) when needed.
// //   Future<void> _loadAll({bool adjustForType = false}) async {
// //     setState(() => _loading = true);
// //     try {
// //       final results = await Future.wait<List<Map<String, dynamic>>>([
// //         ApiService.fetchApprovals(type: selectedTab, status: 'Pending'),
// //         ApiService.fetchApprovals(type: selectedTab, status: 'Approved'),
// //         ApiService.fetchApprovals(type: selectedTab, status: 'Rejected'),
// //       ]);

// //       final pending  = results[0];
// //       final approved = results[1];
// //       final rejected = results[2];

// //       final newPendingCount  = pending.length;
// //       final newApprovedCount = approved.length;
// //       final newRejectedCount = rejected.length;

// //       String nextStatus = selectedStatusFilter;

// //       if (adjustForType) {
// //         // If the current status has no items for this TYPE,
// //         // jump to the first non-empty bucket.
// //         bool currIsEmpty = (nextStatus == 'Pending'  && newPendingCount  == 0) ||
// //                            (nextStatus == 'Approved' && newApprovedCount == 0) ||
// //                            (nextStatus == 'Rejected' && newRejectedCount == 0);

// //         if (currIsEmpty) {
// //           if (newPendingCount > 0) {
// //             nextStatus = 'Pending';
// //           } else if (newApprovedCount > 0) {
// //             nextStatus = 'Approved';
// //           } else if (newRejectedCount > 0) {
// //             nextStatus = 'Rejected';
// //           }
// //           // else: all empty → keep whatever is selected so "No requests" shows
// //         }
// //       }

// //       // Pick list to display based on (possibly updated) status
// //       List<Map<String, dynamic>> current;
// //       switch (nextStatus) {
// //         case 'Approved':
// //           current = approved;
// //           break;
// //         case 'Rejected':
// //           current = rejected;
// //           break;
// //         case 'Pending':
// //         default:
// //           current = pending;
// //       }

// //       if (!mounted) return;
// //       setState(() {
// //         _cPending = newPendingCount;
// //         _cApproved = newApprovedCount;
// //         _cRejected = newRejectedCount;
// //         selectedStatusFilter = nextStatus;
// //         _items = current;
// //       });
// //     } catch (e) {
// //       _snack('Failed to fetch approvals: $e');
// //       if (!mounted) return;
// //       setState(() {
// //         _items = [];
// //         _cPending = _cApproved = _cRejected = 0;
// //       });
// //     } finally {
// //       if (mounted) setState(() => _loading = false);
// //     }
// //   }

// //   void _snack(String msg) =>
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// //   @override
// //   Widget build(BuildContext context) {
// //     final today = DateFormat('dd MMM yyyy').format(DateTime.now());

// //     // local search filter
// //     final filtered = _items
// //         .where((leave) => leave.values.any((v) =>
// //             (v ?? '')
// //                 .toString()
// //                 .toLowerCase()
// //                 .contains(searchController.text.toLowerCase())))
// //         .toList();

// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: const Color(0xFF8C6EAF),
// //         title: const Text("Leave Approvals"),
// //         actions: [
// //           Padding(
// //             padding: const EdgeInsets.all(12),
// //             child: Center(child: Text(today)),
// //           ),
// //         ],
// //       ),
// //       body: Container(
// //         padding: const EdgeInsets.all(10),
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //         ),
// //         child: Column(
// //           children: [
// //             SingleChildScrollView(
// //               scrollDirection: Axis.horizontal,
// //               child: Row(
// //                 children: [
// //                   // Type selector
// //                   Container(
// //                     height: 30,
// //                     padding: const EdgeInsets.symmetric(horizontal: 6),
// //                     margin: const EdgeInsets.only(right: 6),
// //                     decoration: BoxDecoration(
// //                       color: Colors.deepPurple[100],
// //                       borderRadius: BorderRadius.circular(10),
// //                       border: Border.all(color: Colors.black),
// //                     ),
// //                     child: DropdownButtonHideUnderline(
// //                       child: DropdownButton<String>(
// //                         value: selectedTab,
// //                         onChanged: (val) async {
// //                           setState(() => selectedTab = val!);
// //                           // IMPORTANT: adjustForType=true so Permission/others
// //                           // jump to a status that actually has data.
// //                           await _loadAll(adjustForType: true);
// //                         },
// //                         icon: const Icon(Icons.arrow_drop_down,
// //                             size: 18, color: Colors.black),
// //                         style: const TextStyle(
// //                             color: Colors.black,
// //                             fontSize: 12,
// //                             fontWeight: FontWeight.w500),
// //                         dropdownColor: Colors.white,
// //                         isDense: true,
// //                         isExpanded: false,
// //                         items: const [
// //                           'All',
// //                           'Late check in',
// //                           'Early check out',
// //                           'Leave Type',
// //                           'Permission',
// //                           'Over Time',
// //                           'Half Day Leave',
// //                           'Comp Off'
// //                         ]
// //                             .map((type) =>
// //                                 DropdownMenuItem(value: type, child: Text(type)))
// //                             .toList(),
// //                       ),
// //                     ),
// //                   ),

// //                   // Status chips with live counts
// //                   _buildStatusButton("Pending", _cPending),
// //                   const SizedBox(width: 6),
// //                   _buildStatusButton("Approved", _cApproved),
// //                   const SizedBox(width: 6),
// //                   _buildStatusButton("Rejected", _cRejected),
// //                 ],
// //               ),
// //             ),
// //             const SizedBox(height: 10),
// //             TextField(
// //               controller: searchController,
// //               onChanged: (_) => setState(() {}),
// //               decoration: InputDecoration(
// //                 hintText: 'Search...',
// //                 prefixIcon: const Icon(Icons.search),
// //                 filled: true,
// //                 fillColor: Colors.white,
// //                 border:
// //                     OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// //               ),
// //             ),
// //             const SizedBox(height: 10),
// //             if (_loading)
// //               const Expanded(child: Center(child: CircularProgressIndicator()))
// //             else
// //               Expanded(
// //                 child: filtered.isEmpty
// //                     ? const Center(child: Text('No requests'))
// //                     : ListView.builder(
// //                         itemCount: filtered.length,
// //                         itemBuilder: (context, index) {
// //                           final leave = filtered[index];
// //                           return LeaveCard(
// //                             item: leave,
// //                             onStatusChange: (status) async {
// //                               try {
// //                                 await ApiService.decideApproval(
// //                                   item: leave,
// //                                   status: status,
// //                                 );
// //                                 _snack('Updated: $status');
// //                                 await _loadAll(adjustForType: true);
// //                               } catch (e) {
// //                                 _snack('Update failed: $e');
// //                               }
// //                             },
// //                           );
// //                         },
// //                       ),
// //               ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildStatusButton(String label, int count) {
// //     final color = label == 'Pending'
// //         ? Colors.pink[100]!
// //         : label == 'Approved'
// //             ? Colors.greenAccent
// //             : Colors.red[200]!;
// //     final isSelected = selectedStatusFilter == label;

// //     return GestureDetector(
// //       onTap: () async {
// //         setState(() => selectedStatusFilter = label);
// //         await _loadAll(); // explicit status switch; no auto-adjust
// //       },
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //         decoration: BoxDecoration(
// //           color: color.withOpacity(isSelected ? 1.0 : 0.7),
// //           borderRadius: BorderRadius.circular(12),
// //           border: Border.all(color: Colors.black),
// //         ),
// //         child: Text(
// //           "$label ($count)",
// //           style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../services/api_service.dart';
// import 'leave_card.dart';

// class LeaveApprovalsScreen extends StatefulWidget {
//   const LeaveApprovalsScreen({super.key});

//   @override
//   State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
// }

// class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
//   String selectedTab = 'All';                // Type filter
//   String selectedStatusFilter = 'Pending';   // Status chip
//   final TextEditingController searchController = TextEditingController();

//   // data & counts
//   List<Map<String, dynamic>> _items = [];
//   int _cPending = 0, _cApproved = 0, _cRejected = 0;

//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadAll(adjustForType: true); // first load: pick a status that has data
//   }

//   // Normalize decision strings to API-accepted values.
//   String _normalizeDecision(String input) {
//     final v = (input).trim().toLowerCase();
//     if (v == 'approve' || v == 'approved') return 'Approved';
//     if (v == 'reject'  || v == 'rejected') return 'Rejected';
//     if (v == 'pending') return 'Pending';
//     return input.trim();
//   }

//   Future<void> _loadAll({bool adjustForType = false}) async {
//     setState(() => _loading = true);
//     try {
//       final results = await Future.wait<List<Map<String, dynamic>>>([
//         ApiService.fetchApprovals(type: selectedTab, status: 'Pending'),
//         ApiService.fetchApprovals(type: selectedTab, status: 'Approved'),
//         ApiService.fetchApprovals(type: selectedTab, status: 'Rejected'),
//       ]);

//       final pending  = results[0];
//       final approved = results[1];
//       final rejected = results[2];

//       final newPendingCount  = pending.length;
//       final newApprovedCount = approved.length;
//       final newRejectedCount = rejected.length;

//       String nextStatus = selectedStatusFilter;

//       if (adjustForType) {
//         final currIsEmpty = (nextStatus == 'Pending'  && newPendingCount  == 0) ||
//                             (nextStatus == 'Approved' && newApprovedCount == 0) ||
//                             (nextStatus == 'Rejected' && newRejectedCount == 0);
//         if (currIsEmpty) {
//           if (newPendingCount > 0) {
//             nextStatus = 'Pending';
//           } else if (newApprovedCount > 0) {
//             nextStatus = 'Approved';
//           } else if (newRejectedCount > 0) {
//             nextStatus = 'Rejected';
//           }
//         }
//       }

//       List<Map<String, dynamic>> current;
//       switch (nextStatus) {
//         case 'Approved':
//           current = approved;
//           break;
//         case 'Rejected':
//           current = rejected;
//           break;
//         case 'Pending':
//         default:
//           current = pending;
//       }

//       if (!mounted) return;
//       setState(() {
//         _cPending = newPendingCount;
//         _cApproved = newApprovedCount;
//         _cRejected = newRejectedCount;
//         selectedStatusFilter = nextStatus;
//         _items = current;
//       });
//     } catch (e) {
//       _snack('Failed to fetch approvals: $e');
//       if (!mounted) return;
//       setState(() {
//         _items = [];
//         _cPending = _cApproved = _cRejected = 0;
//       });
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   void _snack(String msg) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

//   @override
//   Widget build(BuildContext context) {
//     final today = DateFormat('dd MMM yyyy').format(DateTime.now());

//     final filtered = _items
//         .where((leave) => leave.values.any((v) =>
//             (v ?? '')
//                 .toString()
//                 .toLowerCase()
//                 .contains(searchController.text.toLowerCase())))
//         .toList();

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF8C6EAF),
//         title: const Text("Leave Approvals"),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Center(child: Text(today)),
//           ),
//         ],
//       ),
//       body: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           children: [
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   Container(
//                     height: 30,
//                     padding: const EdgeInsets.symmetric(horizontal: 6),
//                     margin: const EdgeInsets.only(right: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.deepPurple[100],
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: Colors.black),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: selectedTab,
//                         onChanged: (val) async {
//                           setState(() => selectedTab = val!);
//                           await _loadAll(adjustForType: true);
//                         },
//                         icon: const Icon(Icons.arrow_drop_down,
//                             size: 18, color: Colors.black),
//                         style: const TextStyle(
//                             color: Colors.black,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500),
//                         dropdownColor: Colors.white,
//                         isDense: true,
//                         isExpanded: false,
//                         items: const [
//                           'All',
//                           'Late check in',
//                           'Early check out',
//                           'Leave Type',
//                           'Permission',
//                           'Over Time',
//                           'Half Day Leave',
//                           'Comp Off'
//                         ]
//                             .map((type) =>
//                                 DropdownMenuItem(value: type, child: Text(type)))
//                             .toList(),
//                       ),
//                     ),
//                   ),
//                   _buildStatusButton("Pending", _cPending),
//                   const SizedBox(width: 6),
//                   _buildStatusButton("Approved", _cApproved),
//                   const SizedBox(width: 6),
//                   _buildStatusButton("Rejected", _cRejected),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: searchController,
//               onChanged: (_) => setState(() {}),
//               decoration: InputDecoration(
//                 hintText: 'Search...',
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border:
//                     OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//             const SizedBox(height: 10),
//             if (_loading)
//               const Expanded(child: Center(child: CircularProgressIndicator()))
//             else
//               Expanded(
//                 child: filtered.isEmpty
//                     ? const Center(child: Text('No requests'))
//                     : ListView.builder(
//                         itemCount: filtered.length,
//                         itemBuilder: (context, index) {
//                           final leave = filtered[index];
//                           return LeaveCard(
//                             item: leave,
//                             onStatusChange: (status) async {
//                               try {
//                                 final normalized = _normalizeDecision(status);

//                                 // 🔑 Ensure the item we send already contains the final status.
//                                 // This protects us if the ApiService builds its payload from `item`.
//                                 final payloadItem = Map<String, dynamic>.from(leave)
//                                   ..['status'] = normalized;

//                                 if (normalized != 'Approved' &&
//                                     normalized != 'Rejected') {
//                                   throw 'Invalid status "$status"';
//                                 }

//                                 await ApiService.decideApproval(
//                                   item: payloadItem,
//                                   status: normalized,
//                                 );

//                                 _snack('Updated: $normalized');
//                                 await _loadAll(adjustForType: true);
//                               } catch (e) {
//                                 _snack('Update failed: $e');
//                               }
//                             },
//                           );
//                         },
//                       ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusButton(String label, int count) {
//     final color = label == 'Pending'
//         ? Colors.pink[100]!
//         : label == 'Approved'
//             ? Colors.greenAccent
//             : Colors.red[200]!;
//     final isSelected = selectedStatusFilter == label;

//     return GestureDetector(
//       onTap: () async {
//         setState(() => selectedStatusFilter = label);
//         await _loadAll();
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: color.withOpacity(isSelected ? 1.0 : 0.7),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.black),
//         ),
//         child: Text(
//           "$label ($count)",
//           style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'leave_card.dart';

class LeaveApprovalsScreen extends StatefulWidget {
  const LeaveApprovalsScreen({super.key});

  @override
  State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
  String selectedTab = 'All';                // Type filter
  String selectedStatusFilter = 'Pending';   // Status chip
  final TextEditingController searchController = TextEditingController();

  // data & counts
  List<Map<String, dynamic>> _items = [];
  int _cPending = 0, _cApproved = 0, _cRejected = 0;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAll(adjustForType: true); // first load: pick a status that has data
  }

  // Normalize decision strings to API-accepted values.
  String _normalizeDecision(String input) {
    final v = (input).trim().toLowerCase();
    if (v == 'approve' || v == 'approved') return 'Approved';
    if (v == 'reject'  || v == 'rejected') return 'Rejected';
    if (v == 'pending') return 'Pending';
    return input.trim();
  }

  /// Map current tab/item to "attendance" | "leaves" for the decision API.
  String _sourceFromTabAndItem(Map<String, dynamic> item) {
    // If backend already sent a source, honor it.
    final s = (item['source'] ?? '').toString().toLowerCase();
    if (s == 'attendance' || s == 'leaves') return s;

    // Decide by selected tab
    final t = selectedTab.toLowerCase();
    if (t == 'late check in' || t == 'early check out') return 'attendance';
    if (t == 'leave type' || t == 'permission' || t == 'over time' ||
        t == 'half day leave' || t == 'comp off') return 'leaves';

    // If "All", infer by item fields/type
    final typeStr = (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
    if (typeStr.contains('late') || typeStr.contains('early') || typeStr.contains('attend')) return 'attendance';
    if (typeStr.contains('leave') || typeStr.contains('permission') || typeStr.contains('overtime') ||
        typeStr.contains('halfday') || typeStr.contains('comp')) return 'leaves';

    if (item.containsKey('checkIn') || item.containsKey('checkOut') || item.containsKey('requestTime')) {
      return 'attendance';
    }
    return 'leaves'; // safe default for leave approval cards
  }

  Future<void> _loadAll({bool adjustForType = false}) async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        ApiService.fetchApprovals(type: selectedTab, status: 'Pending'),
        ApiService.fetchApprovals(type: selectedTab, status: 'Approved'),
        ApiService.fetchApprovals(type: selectedTab, status: 'Rejected'),
      ]);

      final pending  = results[0];
      final approved = results[1];
      final rejected = results[2];

      final newPendingCount  = pending.length;
      final newApprovedCount = approved.length;
      final newRejectedCount = rejected.length;

      String nextStatus = selectedStatusFilter;

      if (adjustForType) {
        final currIsEmpty = (nextStatus == 'Pending'  && newPendingCount  == 0) ||
                            (nextStatus == 'Approved' && newApprovedCount == 0) ||
                            (nextStatus == 'Rejected' && newRejectedCount == 0);
        if (currIsEmpty) {
          if (newPendingCount > 0) {
            nextStatus = 'Pending';
          } else if (newApprovedCount > 0) {
            nextStatus = 'Approved';
          } else if (newRejectedCount > 0) {
            nextStatus = 'Rejected';
          }
        }
      }

      List<Map<String, dynamic>> current;
      switch (nextStatus) {
        case 'Approved':
          current = approved;
          break;
        case 'Rejected':
          current = rejected;
          break;
        case 'Pending':
        default:
          current = pending;
      }

      if (!mounted) return;
      setState(() {
        _cPending = newPendingCount;
        _cApproved = newApprovedCount;
        _cRejected = newRejectedCount;
        selectedStatusFilter = nextStatus;
        _items = current;
      });
    } catch (e) {
      _snack('Failed to fetch approvals: $e');
      if (!mounted) return;
      setState(() {
        _items = [];
        _cPending = _cApproved = _cRejected = 0;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    final filtered = _items
        .where((leave) => leave.values.any((v) =>
            (v ?? '')
                .toString()
                .toLowerCase()
                .contains(searchController.text.toLowerCase())))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8C6EAF),
        title: const Text("Leave Approvals"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(child: Text(today)),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFD1C4E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedTab,
                        onChanged: (val) async {
                          setState(() => selectedTab = val!);
                          await _loadAll(adjustForType: true);
                        },
                        icon: const Icon(Icons.arrow_drop_down,
                            size: 18, color: Colors.black),
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                        dropdownColor: Colors.white,
                        isDense: true,
                        isExpanded: false,
                        items: const [
                          'All',
                          'Late check in',
                          'Early check out',
                          'Leave Type',
                          'Permission',
                          'Over Time',
                          'Half Day Leave',
                          'Comp Off'
                        ]
                            .map((type) =>
                                DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                      ),
                    ),
                  ),
                  _buildStatusButton("Pending", _cPending),
                  const SizedBox(width: 6),
                  _buildStatusButton("Approved", _cApproved),
                  const SizedBox(width: 6),
                  _buildStatusButton("Rejected", _cRejected),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No requests'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final leave = filtered[index];
                          return LeaveCard(
                            item: leave,
                            onStatusChange: (status) async {
                              try {
                                final normalized = _normalizeDecision(status);

                                // copy & patch
                                final payloadItem = Map<String, dynamic>.from(leave)
                                  ..['status'] = normalized;

                                // determine source for the decision API
                                final src = _sourceFromTabAndItem(leave);

                                if (normalized != 'Approved' &&
                                    normalized != 'Rejected') {
                                  throw 'Invalid status "$status"';
                                }

                                await ApiService.decideApproval(
                                  item: payloadItem,
                                  status: normalized,
                                  sourceHint: src, // <-- pass "attendance" | "leaves"
                                );

                                _snack('Updated: $normalized');
                                await _loadAll(adjustForType: true);
                              } catch (e) {
                                _snack('Update failed: $e');
                              }
                            },
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, int count) {
    final color = label == 'Pending'
        ? Colors.pink[100]!
        : label == 'Approved'
            ? Colors.greenAccent
            : Colors.red[200]!;
    final isSelected = selectedStatusFilter == label;

    return GestureDetector(
      onTap: () async {
        setState(() => selectedStatusFilter = label);
        await _loadAll();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 1.0 : 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          "$label ($count)",
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        ),
      ),
    );
  }
}
