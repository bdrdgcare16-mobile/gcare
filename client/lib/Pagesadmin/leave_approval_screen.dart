// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// import '../services/api_service.dart';
// import 'leave_card.dart';
// import 'leave_detail_screen.dart' show RequestDetailsCard;

// class LeaveApprovalsScreen extends StatefulWidget {
//   const LeaveApprovalsScreen({super.key});

//   @override
//   State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
// }

// class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
//   String selectedTab = 'All'; // Type filter (UI label)
//   String selectedStatusFilter = 'Pending'; // Status chip
//   final TextEditingController searchController = TextEditingController();

//   List<Map<String, dynamic>> _rows = [];
//   int _cPending = 0, _cApproved = 0, _cRejected = 0;
//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadAll(adjustForType: true);
//   }

//   // ── helpers ────────────────────────────────────────────────────────────────

//   bool _isOtherLocationTab(String label) {
//     final t = label.trim().toLowerCase();
//     return t == 'other location' || t == 'other_location';
//   }

//   /// Map UI tab → API `type` query value (what your backend expects)
//   String _apiTypeForTab(String ui) {
//     final t = ui.trim().toLowerCase();
//     if (t == 'other location' || t == 'other_location') {
//       // We won’t pass this to fetchApprovals(); other-location uses its own API.
//       return 'Other Location';
//     }
//     switch (t) {
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

//   /// Heuristic to decide if a row is attendance, leaves, or other_location.
//   String _sourceFromItemOrTab(Map<String, dynamic> item) {
//     // Explicit source wins.
//     final s = (item['source'] ?? '').toString().toLowerCase();
//     if (s == 'attendance' || s == 'leaves' || s == 'other_location') return s;

//     // The tab can force it.
//     if (_isOtherLocationTab(selectedTab)) return 'other_location';

//     // Type/category hints.
//     final typeStr =
//         (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
//     if (typeStr.contains('other') && typeStr.contains('location')) {
//       return 'other_location';
//     }
//     if (typeStr.contains('late') || typeStr.contains('early')) {
//       return 'attendance';
//     }
//     if (typeStr.contains('leave') ||
//         typeStr.contains('permission') ||
//         typeStr.contains('overtime') ||
//         typeStr.contains('half')) {
//       return 'leaves';
//     }

//     // Field-based hints (covers All tab where type looks like check-in/out):
//     // Any of these are strong signals of otherLocation docs.
//     if (item.containsKey('withinRadius') ||
//         item.containsKey('expectedLatitude') ||
//         item.containsKey('expectedLongitude') ||
//         item.containsKey('distanceFromBranch') ||
//         item.containsKey('requestLocation') ||
//         item.containsKey('otherLocation') ||
//         (item.containsKey('latitude') && item.containsKey('longitude'))) {
//       return 'other_location';
//     }

//     // Attendance fall-back.
//     return 'attendance';
//   }

//   // ✅ Only allow navigation for: Other Location, Late Check-In, Early Check-Out
//   bool _isRowTappable(Map<String, dynamic> item) {
//     if (_isOtherLocationTab(selectedTab)) return true;

//     final src = _sourceFromItemOrTab(item);
//     if (src == 'other_location') return true;

//     if (src != 'attendance') return false;

//     final type =
//         (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
//     final isLateIn =
//         type.contains('late') && type.contains('check') && type.contains('in');
//     final isEarlyOut =
//         type.contains('early') && type.contains('check') && type.contains('out');

//     return isLateIn || isEarlyOut;
//   }

//   Map<String, dynamic> _toDisplay(Map<String, dynamic> item) {
//     String pickStr(List keys, {String fallback = '-'}) {
//       for (final k in keys) {
//         final v = item[k]?.toString();
//         if (v != null && v.trim().isNotEmpty) return v;
//       }
//       return fallback;
//     }

//     final requestTime = pickStr(['requestTime', 'time', 'checkIn', 'checkOut']);
//     final requestDate =
//         pickStr(['requestDate', 'date', 'startDate', 'selectDate'], fallback: '');

//     // Only the selected fields get shown
//     return <String, dynamic>{
//       'type': pickStr(['type', 'category'], fallback: '-'),
//       'empid': pickStr(['empid', 'empId', 'employeeId'], fallback: '-'),
//       'department': pickStr(['department', 'dept'], fallback: '-'),
//       'name': pickStr(['name', 'employeeName'], fallback: '-'),
//       'shift': pickStr(['shift', 'shiftGroup'], fallback: '-'),
//       'requestTime': requestTime,
//       'requestDate': requestDate,
//       'reason': pickStr(['reason', 'otherLocation'], fallback: '-'),
//       'location': pickStr(['location', 'requestLocation'], fallback: '-'),
//       'branchName': pickStr(['branchName', 'branchLocation'], fallback: '-'),
//       'status': pickStr(['status', 'approvalStatus'], fallback: 'Pending'),
//     };
//   }

//   // 🔧 Prefer otherLocId first to avoid mixing ids between sources
//   String _pickAnyId(Map<String, dynamic> item) {
//     for (final k in [
//       'otherLocId',      // moved to the front
//       'requestId',
//       'id',
//       'docId',
//       'attendanceId',
//       'leaveId',
//     ]) {
//       final v = item[k]?.toString();
//       if (v != null && v.trim().isNotEmpty) return v;
//     }
//     return '';
//   }

//   Future<void> _openDetails(
//     Map<String, dynamic> backendItem,
//     Map<String, dynamic> viewItem,
//   ) async {
//     Map<String, dynamic> details = {};
//     try {
//       // Decide source; if user is on Other Location tab, force that source.
//       String src = _sourceFromItemOrTab(backendItem);
//       if (_isOtherLocationTab(selectedTab)) {
//         src = 'other_location';
//       }

//       if (src == 'attendance' || src == 'other_location') {
//         final id = _pickAnyId(backendItem);
//         String empid =
//             (backendItem['empid'] ?? backendItem['empId'] ?? backendItem['employeeId'])?.toString() ?? '';
//         String date  =
//             (backendItem['requestDate'] ?? backendItem['date'] ?? backendItem['onDate'])?.toString() ?? '';
//         if (date.length > 10) date = date.substring(0, 10);

//         if (id.isNotEmpty) {
//           details = await ApiService.fetchRequestDetails(
//             id: id,
//             src: src, // <- correct source now
//           );
//         } else if (empid.isNotEmpty && date.isNotEmpty) {
//           details = await ApiService.fetchRequestDetails(empid: empid, date: date);
//         }
//       }
//     } catch (e) {
//       debugPrint('fetchRequestDetails failed: $e');
//     }

//     final merged = {...backendItem, ...viewItem, ...details};

//     final decision = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => RequestDetailsCard(data: merged)),
//     );

//     if (decision is String &&
//         (decision.toLowerCase() == 'approved' ||
//             decision.toLowerCase() == 'rejected')) {
//       final normalized = _normalizeDecision(decision);
//       try {
//         final src = _sourceFromItemOrTab(backendItem);
//         if (src == 'other_location') {
//           final id = _pickAnyId(backendItem);
//           if (id.isEmpty) throw 'Missing id for other-location';
//           await ApiService.decideOtherLocation(
//             id: id,
//             status: normalized,
//             remarks: backendItem['decisionRemarks'],
//           );
//         } else {
//           final payload =
//               Map<String, dynamic>.from(backendItem)..['status'] = normalized;
//           await ApiService.decideApproval(
//             item: payload,
//             status: normalized,
//             sourceHint: src,
//           );
//         }

//         _snack('Updated: $normalized');
//         await _loadAll(adjustForType: true);
//       } catch (e) {
//         _snack('Update failed: $e');
//       }
//     }
//   }

//   /// Fetch rows for a given tab+status.
//   Future<List<Map<String, dynamic>>> _fetchByTabAndStatus(
//       String tab, String status) async {
//     // For OTHER LOCATION: use the dedicated endpoint so only otherLocation docs are returned.
//     if (_isOtherLocationTab(tab)) {
//       debugPrint('[Approvals] OTHER-LOCATION  STATUS="$status"');
//       return ApiService.fetchOtherLocation(status: status);
//     }

//     // All other tabs go through the aggregator with mapped type.
//     final apiType = _apiTypeForTab(tab);
//     debugPrint('[Approvals] TAB="$tab"  STATUS="$status"  type="$apiType"');
//     return ApiService.fetchApprovals(type: apiType, status: status);
//   }

//   Future<void> _loadAll({bool adjustForType = false}) async {
//     setState(() => _loading = true);
//     try {
//       // Pull counts & rows per status for the current tab.
//       final pending  = await _fetchByTabAndStatus(selectedTab, 'Pending');
//       final approved = await _fetchByTabAndStatus(selectedTab, 'Approved');
//       final rejected = await _fetchByTabAndStatus(selectedTab, 'Rejected');

//       final newPendingCount = pending.length;
//       final newApprovedCount = approved.length;
//       final newRejectedCount = rejected.length;

//       String nextStatus = selectedStatusFilter;
//       if (adjustForType) {
//         final emptyNow = (nextStatus == 'Pending' && newPendingCount == 0) ||
//             (nextStatus == 'Approved' && newApprovedCount == 0) ||
//             (nextStatus == 'Rejected' && newRejectedCount == 0);
//         if (emptyNow) {
//           if (newPendingCount > 0) {
//             nextStatus = 'Pending';
//           } else if (newApprovedCount > 0) nextStatus = 'Approved';
//           else if (newRejectedCount > 0) nextStatus = 'Rejected';
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
//           break;
//       }

//       if (!mounted) return;
//       setState(() {
//         _cPending = newPendingCount;
//         _cApproved = newApprovedCount;
//         _cRejected = newRejectedCount;
//         selectedStatusFilter = nextStatus;
//         _rows = current;
//       });
//     } catch (e) {
//       _snack('Failed to fetch approvals: $e');
//       if (!mounted) return;
//       setState(() {
//         _rows = [];
//         _cPending = _cApproved = _cRejected = 0;
//       });
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   void _snack(String msg) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

//   // ── UI ─────────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     const kAppBarColor = Color(0xFF8C6EAF);
//     const kBgTop = Color(0xFFFFFFFF);
//     const kBgBottom = Color(0xFFD1C4E9);

//     final today = DateFormat('dd MMM yyyy').format(DateTime.now());

//     // Build display list with only selected fields; support search
//     final displayList = _rows.map(_toDisplay).toList();
//     final q = searchController.text.toLowerCase();

//     final filteredIndices = <int>[];
//     final filteredDisplay = <Map<String, dynamic>>[];
//     for (int i = 0; i < displayList.length; i++) {
//       final disp = displayList[i];
//       final hit =
//           disp.values.any((v) => (v ?? '').toString().toLowerCase().contains(q));
//       if (hit) {
//         filteredIndices.add(i);
//         filteredDisplay.add(disp);
//       }
//     }

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
//                           'Other Location',
//                         ].map((t) =>
//                             DropdownMenuItem(value: t, child: Text(t))).toList(),
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
//                 child: filteredDisplay.isEmpty
//                     ? const Center(child: Text('No requests'))
//                     : ListView.builder(
//                         itemCount: filteredDisplay.length,
//                         itemBuilder: (context, viewIdx) {
//                           final backendIdx = filteredIndices[viewIdx];
//                           final backendItem = _rows[backendIdx];
//                           final viewItem = filteredDisplay[viewIdx];

//                           final tappable = _isRowTappable(backendItem);

//                           final card = LeaveCard(
//                             item: viewItem, // only selected fields shown
//                             onStatusChange: (status) async {
//                               try {
//                                 final normalized = _normalizeDecision(status);
//                                 if (normalized != 'Approved' &&
//                                     normalized != 'Rejected') {
//                                   throw 'Invalid status "$status"';
//                                 }
//                                 final src = _sourceFromItemOrTab(backendItem);

//                                 if (src == 'other_location') {
//                                   final id = _pickAnyId(backendItem);
//                                   if (id.isEmpty) throw 'Missing id for other-location';
//                                   await ApiService.decideOtherLocation(
//                                     id: id,
//                                     status: normalized,
//                                     remarks: backendItem['decisionRemarks'],
//                                   );
//                                 } else {
//                                   final payloadItem =
//                                       Map<String, dynamic>.from(backendItem)
//                                         ..['status'] = normalized;
//                                   await ApiService.decideApproval(
//                                     item: payloadItem,
//                                     status: normalized,
//                                     sourceHint: src,
//                                   );
//                                 }

//                                 _snack('Updated: $normalized');
//                                 await _loadAll(adjustForType: true);
//                               } catch (e) {
//                                 _snack('Update failed: $e');
//                               }
//                             },
//                           );

//                           if (!tappable) return card;

//                           return GestureDetector(
//                             behavior: HitTestBehavior.opaque,
//                             onTap: () => _openDetails(backendItem, viewItem),
//                             child: card,
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

  List<Map<String, dynamic>> _rows = [];
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

  /// Map UI tab → API `type` query value (what your backend expects)
  String _apiTypeForTab(String ui) {
    final t = ui.trim().toLowerCase();
    if (t == 'other location' || t == 'other_location') {
      // We won’t pass this to fetchApprovals(); other-location uses its own API.
      return 'Other Location';
    }
    switch (t) {
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

  /// Heuristic to decide if a row is attendance, leaves, or other_location.
  String _sourceFromItemOrTab(Map<String, dynamic> item) {
    // Explicit source wins.
    final s = (item['source'] ?? '').toString().toLowerCase();
    if (s == 'attendance' || s == 'leaves' || s == 'other_location') return s;

    // The tab can force it.
    if (_isOtherLocationTab(selectedTab)) return 'other_location';

    // If a leaveType field is present, it's definitely leaves.
    if ((item['leaveType'] ?? item['leave type'] ?? item['leave_type']) != null) {
      return 'leaves';
    }

    // Type/category hints.
    final typeStr =
        (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
    if (typeStr.contains('other') && typeStr.contains('location')) {
      return 'other_location';
    }
    if (typeStr.contains('late') || typeStr.contains('early')) {
      return 'attendance';
    }
    if (typeStr.contains('leave') ||
        typeStr.contains('permission') ||
        typeStr.contains('overtime') ||
        typeStr.contains('half')) {
      return 'leaves';
    }

    // Field-based hints:
    if (item.containsKey('withinRadius') ||
        item.containsKey('expectedLatitude') ||
        item.containsKey('expectedLongitude') ||
        item.containsKey('distanceFromBranch') ||
        item.containsKey('requestLocation') ||
        item.containsKey('otherLocation') ||
        (item.containsKey('latitude') && item.containsKey('longitude'))) {
      return 'other_location';
    }

    // Attendance fall-back.
    return 'attendance';
  }

  // ✅ Only allow navigation for: Other Location, Late Check-In, Early Check-Out
  bool _isRowTappable(Map<String, dynamic> item) {
    if (_isOtherLocationTab(selectedTab)) return true;

    final src = _sourceFromItemOrTab(item);
    if (src == 'other_location') return true;

    if (src != 'attendance') return false;

    final type =
        (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
    final isLateIn =
        type.contains('late') && type.contains('check') && type.contains('in');
    final isEarlyOut =
        type.contains('early') && type.contains('check') && type.contains('out');

    return isLateIn || isEarlyOut;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LEAVE SUBTYPE HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  String _stringOf(Map<String, dynamic> it, List<String> keys) {
    for (final k in keys) {
      final v = it[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  String _leaveTypeOf(Map<String, dynamic> it) {
    return _stringOf(it, [
      'leave type', 'leaveType', 'leave_type',
      'leaveCategory', 'leave_category',
      'category', 'type'
    ]);
  }

  bool _looksPermission(Map<String, dynamic> it) {
    final lt = _leaveTypeOf(it).toLowerCase();
    final rsn = (it['reason'] ?? '').toString().toLowerCase();
    return lt == 'permission time' || lt == 'permission' || rsn.contains('permission');
  }

  bool _looksOvertime(Map<String, dynamic> it) {
    final lt = _leaveTypeOf(it).toLowerCase();
    final rsn = (it['reason'] ?? '').toString().toLowerCase();
    return lt == 'overtime' || lt == 'over time' || rsn.contains('overtime') || rsn.contains('over time');
  }

  bool _looksHalfday(Map<String, dynamic> it) {
    final lt = _leaveTypeOf(it).toLowerCase();
    final rsn = (it['reason'] ?? '').toString().toLowerCase();
    return lt == 'half-day' || lt == 'half day' || lt == 'halfday' ||
        (rsn.contains('half') && rsn.contains('day'));
  }

  bool _looksCompoff(Map<String, dynamic> it) {
    final lt = _leaveTypeOf(it).toLowerCase();
    final rsn = (it['reason'] ?? '').toString().toLowerCase();
    return lt == 'comp off' || lt == 'compoff' || lt == 'comp-off' ||
        rsn.contains('comp off') || rsn.contains('compoff');
  }

  bool _isSpecificSubtype(Map<String, dynamic> it) {
    return _looksPermission(it) || _looksOvertime(it) || _looksHalfday(it) || _looksCompoff(it);
  }

  /// NEW: map Firestore leaveType → **UI label used in dropdown/tabs**
  String _uiLabelForLeaveType(Map<String, dynamic> it) {
    if (_looksPermission(it)) return 'Permission';
    if (_looksOvertime(it)) return 'Over Time';
    if (_looksHalfday(it)) return 'Half Day Leave';
    if (_looksCompoff(it)) return 'Comp Off';
    // anything else (Casual/Planned/Sick/etc.) shows under generic "Leave Type"
    return 'Leave Type';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UPDATED FILTER:
  // - For the 4 specific tabs, also FILTER CLIENT-SIDE by leaveType.
  // - For "Leave Type" tab, EXCLUDE those 4 subtypes.
  // ───────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _filterByTabSmart(
      List<Map<String, dynamic>> items, String tab) {
    final t = tab.trim().toLowerCase();

    if (t == 'permission') {
      return items.where(_looksPermission).toList();
    }
    if (t == 'over time') {
      return items.where(_looksOvertime).toList();
    }
    if (t == 'half day leave') {
      return items.where(_looksHalfday).toList();
    }
    if (t == 'comp off') {
      return items.where(_looksCompoff).toList();
    }

    if (t == 'leave type') {
      return items.where((it) => !_isSpecificSubtype(it)).toList();
    }

    // All / other tabs unchanged.
    return items;
  }

  /// Fetch rows for a given tab+status.
  Future<List<Map<String, dynamic>>> _fetchByTabAndStatus(
      String tab, String status) async {
    if (_isOtherLocationTab(tab)) {
      final data = await ApiService.fetchOtherLocation(status: status);
      return _filterByTabSmart(data, tab);
    }

    final apiType = _apiTypeForTab(tab);
    final data = await ApiService.fetchApprovals(type: apiType, status: status);
    return _filterByTabSmart(data, tab);
  }

  Future<void> _loadAll({bool adjustForType = false}) async {
    setState(() => _loading = true);
    try {
      final pending  = await _fetchByTabAndStatus(selectedTab, 'Pending');
      final approved = await _fetchByTabAndStatus(selectedTab, 'Approved');
      final rejected = await _fetchByTabAndStatus(selectedTab, 'Rejected');

      final newPendingCount = pending.length;
      final newApprovedCount = approved.length;
      final newRejectedCount = rejected.length;

      String nextStatus = selectedStatusFilter;
      if (adjustForType) {
        final emptyNow = (nextStatus == 'Pending' && newPendingCount == 0) ||
            (nextStatus == 'Approved' && newApprovedCount == 0) ||
            (nextStatus == 'Rejected' && newRejectedCount == 0);
        if (emptyNow) {
          if (newPendingCount > 0) nextStatus = 'Pending';
          else if (newApprovedCount > 0) nextStatus = 'Approved';
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

  // Turn raw backend item into values for the card
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

    // Show the right UI label in the card based on leaveType
    final typeLabel = _sourceFromItemOrTab(item) == 'leaves'
        ? _uiLabelForLeaveType(item)
        : pickStr(['type', 'category'], fallback: '-');

    return <String, dynamic>{
      'type': typeLabel,
      'empid': pickStr(['empid', 'empId', 'employeeId'], fallback: '-'),
      'department': pickStr(['department', 'dept'], fallback: '-'),
      'name': pickStr(['name', 'employeeName'], fallback: '-'),
      'shift': pickStr(['shift', 'shiftGroup'], fallback: '-'),
      'requestTime': requestTime,
      'requestDate': requestDate,
      'reason': pickStr(['reason', 'otherLocation'], fallback: '-'),
      'location': pickStr(['location', 'requestLocation'], fallback: '-'),
      'branchName': pickStr(['branchName', 'branchLocation'], fallback: '-'),
      'status': pickStr(['status', 'approvalStatus'], fallback: 'Pending'),
    };
  }

  // 🔧 Prefer otherLocId first to avoid mixing ids between sources
  String _pickAnyId(Map<String, dynamic> item) {
    for (final k in [
      'otherLocId',
      'requestId',
      'id',
      'docId',
      'attendanceId',
      'leaveId',
    ]) {
      final v = item[k]?.toString();
      if (v != null && v.trim().isNotEmpty) return v;
    }
    return '';
  }

  Future<void> _openDetails(
    Map<String, dynamic> backendItem,
    Map<String, dynamic> viewItem,
  ) async {
    Map<String, dynamic> details = {};
    try {
      String src = _sourceFromItemOrTab(backendItem);
      if (_isOtherLocationTab(selectedTab)) {
        src = 'other_location';
      }

      if (src == 'attendance' || src == 'other_location') {
        final id = _pickAnyId(backendItem);
        String empid =
            (backendItem['empid'] ?? backendItem['empId'] ?? backendItem['employeeId'])?.toString() ?? '';
        String date  =
            (backendItem['requestDate'] ?? backendItem['date'] ?? backendItem['onDate'])?.toString() ?? '';
        if (date.length > 10) date = date.substring(0, 10);

        if (id.isNotEmpty) {
          details = await ApiService.fetchRequestDetails(id: id, src: src);
        } else if (empid.isNotEmpty && date.isNotEmpty) {
          details = await ApiService.fetchRequestDetails(empid: empid, date: date);
        }
      }
    } catch (e) {
      debugPrint('fetchRequestDetails failed: $e');
    }

    final merged = {...backendItem, ...viewItem, ...details};

    final decision = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RequestDetailsCard(data: merged)),
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
              Map<String, dynamic>.from(backendItem)..['status'] = normalized;
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
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const kAppBarColor = Color(0xFF8C6EAF);
    const kBgTop = Color(0xFFFFFFFF);
    const kBgBottom = Color(0xFFD1C4E9);

    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

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
                            item: viewItem,
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

                          if (!tappable) return card;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openDetails(backendItem, viewItem),
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
