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
//   String selectedTab = 'All';              // Type filter (UI label)
//   String selectedStatusFilter = 'Pending'; // Status chip
//   final TextEditingController searchController = TextEditingController();

//   List<Map<String, dynamic>> _items = [];
//   int _cPending = 0, _cApproved = 0, _cRejected = 0;

//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadAll(adjustForType: true);
//   }

//   // ---- Helpers -------------------------------------------------------------

//   bool _isOtherLocationTab(String label) {
//     final t = label.trim().toLowerCase();
//     return t == 'other location' || t == 'other_location';
//   }

//   // Map UI label -> API “type” (used for non other-location tabs)
//   String _apiTypeForTab(String ui) {
//     switch (ui.toLowerCase()) {
//       case 'late check in':
//         return 'attendance:late_check_in';
//       case 'early check out':
//         return 'attendance:early_check_out';
//       case 'permission':
//         return 'leave:permission';
//       case 'over time':
//         return 'leave:overtime';
//       case 'half day leave':
//         return 'leave:halfday';
//       case 'comp off':
//         return 'leave:compoff';
//       case 'leave type':
//         return 'leave:any';
//       case 'all':
//       default:
//         return 'all';
//     }
//   }

//   String _normalizeDecision(String input) {
//     final v = input.trim().toLowerCase();
//     if (v == 'approve' || v == 'approved') return 'Approved';
//     if (v == 'reject' || v == 'rejected') return 'Rejected';
//     if (v == 'pending') return 'Pending';
//     return input.trim();
//   }

//   /// Decide the backend source.
//   String _sourceFromItemOrTab(Map<String, dynamic> item) {
//     final s = (item['source'] ?? '').toString().toLowerCase();
//     if (s == 'attendance' || s == 'leaves' || s == 'other_location') return s;
//     if (_isOtherLocationTab(selectedTab)) return 'other_location';

//     final typeStr = (item['type'] ?? item['category'] ?? '')
//         .toString()
//         .toLowerCase();
//     if (typeStr.contains('late') || typeStr.contains('early')) return 'attendance';
//     if (typeStr.contains('leave') ||
//         typeStr.contains('permission') ||
//         typeStr.contains('overtime') ||
//         typeStr.contains('half')) return 'leaves';
//     return 'attendance';
//   }

//   Future<void> _loadAll({bool adjustForType = false}) async {
//     setState(() => _loading = true);
//     try {
//       List<Map<String, dynamic>> pending = [];
//       List<Map<String, dynamic>> approved = [];
//       List<Map<String, dynamic>> rejected = [];

//       if (_isOtherLocationTab(selectedTab)) {
//         // ---- READ DIRECTLY FROM otherLocation collection ----
//         pending  = await ApiService.fetchOtherLocationApprovals(status: 'Pending');
//         approved = await ApiService.fetchOtherLocationApprovals(status: 'Approved');
//         rejected = await ApiService.fetchOtherLocationApprovals(status: 'Rejected');
//       } else {
//         // ---- All other tabs through approvals aggregator ----
//         final apiType = _apiTypeForTab(selectedTab);
//         pending  = await ApiService.fetchApprovals(type: apiType, status: 'Pending');
//         approved = await ApiService.fetchApprovals(type: apiType, status: 'Approved');
//         rejected = await ApiService.fetchApprovals(type: apiType, status: 'Rejected');
//       }

//       // Counts
//       final newPendingCount  = pending.length;
//       final newApprovedCount = approved.length;
//       final newRejectedCount = rejected.length;

//       String nextStatus = selectedStatusFilter;
//       if (adjustForType) {
//         final currIsEmpty = (nextStatus == 'Pending'  && newPendingCount  == 0) ||
//                             (nextStatus == 'Approved' && newApprovedCount == 0) ||
//                             (nextStatus == 'Rejected' && newRejectedCount == 0);
//         if (currIsEmpty) {
//           if (newPendingCount > 0) nextStatus = 'Pending';
//           else if (newApprovedCount > 0) nextStatus = 'Approved';
//           else if (newRejectedCount > 0) nextStatus = 'Rejected';
//         }
//       }

//       // Pick list by status chip
//       List<Map<String, dynamic>> current;
//       switch (nextStatus) {
//         case 'Approved': current = approved; break;
//         case 'Rejected': current = rejected; break;
//         case 'Pending':
//         default: current = pending; break;
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

//   // ---- UI ------------------------------------------------------------------

//   @override
//   Widget build(BuildContext context) {
//     const kAppBarColor = Color(0xFF8C6EAF);
//     const kBgTop = Color(0xFFFFFFFF);
//     const kBgBottom = Color(0xFFD1C4E9);

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
//         backgroundColor: kAppBarColor,
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
//             colors: [kBgTop, kBgBottom],
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
//                           'Comp Off',
//                           'Other Location', // loads from otherLocation
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
//                           final item = filtered[index];
//                           return LeaveCard(
//                             item: item,
//                             onStatusChange: (status) async {
//                               try {
//                                 final normalized = _normalizeDecision(status);
//                                 if (normalized != 'Approved' &&
//                                     normalized != 'Rejected') {
//                                   throw 'Invalid status "$status"';
//                                 }

//                                 final src = _sourceFromItemOrTab(item);

//                                 if (src == 'other_location') {
//                                   final id = (item['requestId'] ?? item['id'] ?? '').toString();
//                                   if (id.isEmpty) throw 'Missing id for other-location';
//                                   await ApiService.decideOtherLocation(
//                                     id: id,
//                                     status: normalized,
//                                     remarks: item['decisionRemarks'],
//                                   );
//                                 } else {
//                                   final payloadItem = Map<String, dynamic>.from(item)
//                                     ..['status'] = normalized;
//                                   await ApiService.decideApproval(
//                                     item: payloadItem,
//                                     status: normalized,
//                                     sourceHint: src, // "attendance" | "leaves"
//                                   );
//                                 }

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
import 'leave_detail_screen.dart' show RequestDetailsCard;

class LeaveApprovalsScreen extends StatefulWidget {
  const LeaveApprovalsScreen({super.key});

  @override
  State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
  String selectedTab = 'All'; // Type filter (UI label)
  String selectedStatusFilter = 'Pending'; // Status chip
  final TextEditingController searchController = TextEditingController();

  // backend rows (full objects)
  List<Map<String, dynamic>> _rows = [];

  // chip counts
  int _cPending = 0, _cApproved = 0, _cRejected = 0;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAll(adjustForType: true);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  bool _isOtherLocationTab(String label) {
    final t = label.trim().toLowerCase();
    return t == 'other location' || t == 'other_location';
  }

  String _apiTypeForTab(String ui) {
    switch (ui.toLowerCase()) {
      case 'late check in':
        return 'attendance:late_check_in';
      case 'early check out':
        return 'attendance:early_check_out';
      case 'permission':
        return 'leave:permission';
      case 'over time':
        return 'leave:overtime';
      case 'half day leave':
        return 'leave:halfday';
      case 'comp off':
        return 'leave:compoff';
      case 'leave type':
        return 'leave:any';
      case 'all':
      default:
        return 'all';
    }
  }

  String _normalizeDecision(String input) {
    final v = input.trim().toLowerCase();
    if (v == 'approve' || v == 'approved') return 'Approved';
    if (v == 'reject' || v == 'rejected') return 'Rejected';
    if (v == 'pending') return 'Pending';
    return input.trim();
  }

  String _sourceFromItemOrTab(Map<String, dynamic> item) {
    final s = (item['source'] ?? '').toString().toLowerCase();
    if (s == 'attendance' || s == 'leaves' || s == 'other_location') return s;
    if (_isOtherLocationTab(selectedTab)) return 'other_location';

    final typeStr =
        (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
    if (typeStr.contains('late') || typeStr.contains('early')) return 'attendance';
    if (typeStr.contains('other') && typeStr.contains('location')) return 'other_location';
    if (typeStr.contains('leave') ||
        typeStr.contains('permission') ||
        typeStr.contains('overtime') ||
        typeStr.contains('half')) {
      return 'leaves';
    }
    // heuristic by fields
    if (item.containsKey('withinRadius') ||
        item.containsKey('expectedLatitude') ||
        item.containsKey('otherLocation')) {
      return 'other_location';
    }
    return 'attendance';
  }

  // ✅ Only allow navigation for: Other Location, Late Check-In, Early Check-Out
  bool _isRowTappable(Map<String, dynamic> item) {
    // If user is on the Other Location tab, all rows there are tappable
    if (_isOtherLocationTab(selectedTab)) return true;

    final src = _sourceFromItemOrTab(item);
    if (src == 'other_location') return true; // Other Location always navigates

    // Only allow attendance rows that are explicitly Late Check-In / Early Check-Out
    if (src != 'attendance') return false;

    final type =
        (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
    final isLateIn =
        type.contains('late') && type.contains('check') && type.contains('in');
    final isEarlyOut =
        type.contains('early') && type.contains('check') && type.contains('out');

    return isLateIn || isEarlyOut;
  }

  Map<String, dynamic> _toDisplay(Map<String, dynamic> item) {
    String pickStr(List keys, {String fallback = '-'}) {
      for (final k in keys) {
        final v = item[k]?.toString();
        if (v != null && v.trim().isNotEmpty) return v;
      }
      return fallback;
    }

    final requestTime = pickStr(['requestTime', 'time', 'checkIn', 'checkOut']);
    final requestDate =
        pickStr(['requestDate', 'date', 'startDate', 'selectDate'], fallback: '');

    // Only the selected fields get shown (UNCHANGED)
    return <String, dynamic>{
      'type': pickStr(['type', 'category'], fallback: '-'),
      'empid': pickStr(['empid', 'empId', 'employeeId'], fallback: '-'),
      'department': pickStr(['department', 'dept'], fallback: '-'),
      'name': pickStr(['name', 'employeeName'], fallback: '-'),
      'shift': pickStr(['shift', 'shiftGroup'], fallback: '-'),
      'requestTime': requestTime,
      'requestDate': requestDate,
      'reason': pickStr(['reason', 'otherLocation'], fallback: '-'),
      'location': pickStr(['location'], fallback: '-'),
      'branchName': pickStr(['branchName', 'branchLocation'], fallback: '-'),
      'status': pickStr(['status', 'approvalStatus'], fallback: 'Pending'),
    };
  }

  String _pickAnyId(Map<String, dynamic> item) {
    for (final k in [
      'requestId',
      'id',
      'docId',
      'attendanceId',
      'leaveId',
      'otherLocId',
    ]) {
      final v = item[k]?.toString();
      if (v != null && v.trim().isNotEmpty) return v;
    }
    return '';
  }

  Future<void> _loadAll({bool adjustForType = false}) async {
    setState(() => _loading = true);
    try {
      List<Map<String, dynamic>> pending = [];
      List<Map<String, dynamic>> approved = [];
      List<Map<String, dynamic>> rejected = [];

      if (_isOtherLocationTab(selectedTab)) {
        // uses the dedicated other-location endpoint
        pending = await ApiService.fetchOtherLocation(status: 'Pending');
        approved = await ApiService.fetchOtherLocation(status: 'Approved');
        rejected = await ApiService.fetchOtherLocation(status: 'Rejected');
      } else {
        final apiType = _apiTypeForTab(selectedTab);
        pending = await ApiService.fetchApprovals(type: apiType, status: 'Pending');
        approved = await ApiService.fetchApprovals(type: apiType, status: 'Approved');
        rejected = await ApiService.fetchApprovals(type: apiType, status: 'Rejected');
      }

      final newPendingCount = pending.length;
      final newApprovedCount = approved.length;
      final newRejectedCount = rejected.length;

      String nextStatus = selectedStatusFilter;
      if (adjustForType) {
        final emptyNow = (nextStatus == 'Pending' && newPendingCount == 0) ||
            (nextStatus == 'Approved' && newApprovedCount == 0) ||
            (nextStatus == 'Rejected' && newRejectedCount == 0);
        if (emptyNow) {
          if (newPendingCount > 0) {
            nextStatus = 'Pending';
          } else if (newApprovedCount > 0) nextStatus = 'Approved';
          else if (newRejectedCount > 0) nextStatus = 'Rejected';
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
          break;
      }

      if (!mounted) return;
      setState(() {
        _cPending = newPendingCount;
        _cApproved = newApprovedCount;
        _cRejected = newRejectedCount;
        selectedStatusFilter = nextStatus;
        _rows = current;
      });
    } catch (e) {
      _snack('Failed to fetch approvals: $e');
      if (!mounted) return;
      setState(() {
        _rows = [];
        _cPending = _cApproved = _cRejected = 0;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const kAppBarColor = Color(0xFF8C6EAF);
    const kBgTop = Color(0xFFFFFFFF);
    const kBgBottom = Color(0xFFD1C4E9);

    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    // Build display list with only selected fields; support search
    final displayList = _rows.map(_toDisplay).toList();
    final q = searchController.text.toLowerCase();

    final filteredIndices = <int>[];
    final filteredDisplay = <Map<String, dynamic>>[];
    for (int i = 0; i < displayList.length; i++) {
      final disp = displayList[i];
      final hit =
          disp.values.any((v) => (v ?? '').toString().toLowerCase().contains(q));
      if (hit) {
        filteredIndices.add(i);
        filteredDisplay.add(disp);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarColor,
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
            colors: [kBgTop, kBgBottom],
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
                          'Comp Off',
                          'Other Location',
                        ].map((t) =>
                            DropdownMenuItem(value: t, child: Text(t))).toList(),
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
                child: filteredDisplay.isEmpty
                    ? const Center(child: Text('No requests'))
                    : ListView.builder(
                        itemCount: filteredDisplay.length,
                        itemBuilder: (context, viewIdx) {
                          final backendIdx = filteredIndices[viewIdx];
                          final backendItem = _rows[backendIdx];
                          final viewItem = filteredDisplay[viewIdx];

                          final tappable = _isRowTappable(backendItem);

                          final card = LeaveCard(
                            item: viewItem, // only selected fields shown (UNCHANGED)
                            onStatusChange: (status) async {
                              try {
                                final normalized = _normalizeDecision(status);
                                if (normalized != 'Approved' &&
                                    normalized != 'Rejected') {
                                  throw 'Invalid status "$status"';
                                }
                                final src = _sourceFromItemOrTab(backendItem);

                                if (src == 'other_location') {
                                  final id = _pickAnyId(backendItem);
                                  if (id.isEmpty) throw 'Missing id for other-location';
                                  await ApiService.decideOtherLocation(
                                    id: id,
                                    status: normalized,
                                    remarks: backendItem['decisionRemarks'],
                                  );
                                } else {
                                  final payloadItem =
                                      Map<String, dynamic>.from(backendItem)
                                        ..['status'] = normalized;
                                  await ApiService.decideApproval(
                                    item: payloadItem,
                                    status: normalized,
                                    sourceHint: src,
                                  );
                                }

                                _snack('Updated: $normalized');
                                await _loadAll(adjustForType: true);
                              } catch (e) {
                                _snack('Update failed: $e');
                              }
                            },
                          );

                          // Only wrap with tap if it is tappable (so only your 3 cases navigate)
                          if (!tappable) return card;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final merged = {...backendItem, ...viewItem};
                              final decision = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RequestDetailsCard(data: merged),
                                ),
                              );

                              if (decision is String &&
                                  (decision.toLowerCase() == 'approved' ||
                                      decision.toLowerCase() == 'rejected')) {
                                final normalized = _normalizeDecision(decision);
                                try {
                                  final src = _sourceFromItemOrTab(backendItem);
                                  if (src == 'other_location') {
                                    final id = _pickAnyId(backendItem);
                                    if (id.isEmpty) throw 'Missing id for other-location';
                                    await ApiService.decideOtherLocation(
                                      id: id,
                                      status: normalized,
                                      remarks: backendItem['decisionRemarks'],
                                    );
                                  } else {
                                    final payload =
                                        Map<String, dynamic>.from(backendItem)
                                          ..['status'] = normalized;
                                    await ApiService.decideApproval(
                                      item: payload,
                                      status: normalized,
                                      sourceHint: src,
                                    );
                                  }
                                  _snack('Updated: $normalized');
                                  await _loadAll(adjustForType: true);
                                } catch (e) {
                                  _snack('Update failed: $e');
                                }
                              }
                            },
                            child: card,
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
