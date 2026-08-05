import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/utils/performance_logger.dart';
import 'leave_card.dart';
import 'leave_detail_screen.dart' show RequestDetailsCard;
import 'package:flutter/foundation.dart';

void _log(Object message) {
  if (kDebugMode) {
    print(message);
  }
}

class LeaveApprovalsScreen extends StatefulWidget {
  const LeaveApprovalsScreen({super.key});

  @override
  State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
  String selectedTab = 'All';
  String selectedStatusFilter = 'Pending';
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> _rows = [];
  int _cPending = 0, _cApproved = 0, _cRejected = 0;
  bool _loading = false;
  bool _isFetching = false;
  final Set<String> _processingRequestIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadAll(adjustForType: true);
  }

  // Calculate paid/unpaid leave totals for an employee for the current month
  Map<String, double> _calculateEmployeeLeaveTotals(String empid, List<Map<String, dynamic>> allLeaves) {
    double paidTotal = 0;
    double unpaidTotal = 0;
    
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    for (var leave in allLeaves) {
      // Only count approved leaves with leavePayType
      if (leave['status'] != 'Approved' || leave['leavePayType'] == null) continue;
      if (leave['empid']?.toString() != empid) continue;
      
      final leavePayType = leave['leavePayType']?.toString().toLowerCase();
      if (leavePayType != 'paid' && leavePayType != 'unpaid') continue;

      // Parse leave dates
      final startDateStr = leave['startDate']?.toString() ?? leave['fromDate']?.toString();
      final endDateStr = leave['endDate']?.toString() ?? leave['toDate']?.toString();
      
      if (startDateStr == null || endDateStr == null) continue;

      DateTime? startDate;
      DateTime? endDate;
      
      try {
        startDate = DateTime.parse(startDateStr);
        endDate = DateTime.parse(endDateStr);
      } catch (e) {
        continue;
      }

      // Calculate duration in current month
      double daysInMonth = 0;
      
      for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
        if (date.month == currentMonth && date.year == currentYear) {
          daysInMonth += 1;
        }
      }

      // Handle half-day leaves
      if (leave['session'] != null && (leave['session'] == 'Morning' || leave['session'] == 'Afternoon')) {
        daysInMonth = daysInMonth / 2;
      }

      if (leavePayType == 'paid') {
        paidTotal += daysInMonth;
      } else {
        unpaidTotal += daysInMonth;
      }
    }

    return {'paid': paidTotal, 'unpaid': unpaidTotal};
  }

  bool _isOtherLocationTab(String label) {
    final t = label.trim().toLowerCase();
    return t == 'other location' || t == 'other_location';
  }

  String _apiTypeForTab(String ui) {
    final t = ui.trim().toLowerCase();

    if (kDebugMode) {
      _log('Getting API type for UI tab: $t');
    }

    if (t == 'other location' || t == 'other_location') {
      return 'Other Location';
    }

    if (t == 'permission' ||
        t == 'over time' ||
        t == 'half day leave' ||
        t == 'comp off' ||
        t == 'leave type') {
      _log('Fetching all requests for client-side filtering - tab: $t');
      return 'all';
    }

    switch (t) {
      case 'late check in':
        return 'attendance:late_check_in';
      case 'early check out':
        return 'attendance:early_check_out';
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
    if (s == 'attendance' || s == 'leaves' || s == 'other_location') {
      return s;
    }

    if ((item['leaveType'] ?? item['leave type'] ?? item['leave_type']) !=
        null) {
      return 'leaves';
    }

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

    if (item.containsKey('withinRadius') ||
        item.containsKey('expectedLatitude') ||
        item.containsKey('expectedLongitude') ||
        item.containsKey('distanceFromBranch') ||
        item.containsKey('requestLocation') ||
        item.containsKey('otherLocation') ||
        (item.containsKey('latitude') && item.containsKey('longitude'))) {
      return 'other_location';
    }

    return 'attendance';
  }

  bool _isRowTappable(Map<String, dynamic> item) {
    if (_isOtherLocationTab(selectedTab)) return true;

    final src = _sourceFromItemOrTab(item);
    if (src == 'other_location') return true;

    if (src != 'attendance') return false;

    final type =
        (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
    final isLateIn =
        type.contains('late') && type.contains('check') && type.contains('in');
    final isEarlyOut = type.contains('early') &&
        type.contains('check') &&
        type.contains('out');

    return isLateIn || isEarlyOut;
  }

  String _stringOf(Map<String, dynamic> it, List<String> keys) {
    for (final k in keys) {
      final v = it[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  String _leaveTypeOf(Map<String, dynamic> it) {
    final leaveType = _stringOf(it, [
      'leave type',
      'leaveType',
      'leave_type',
      'leaveCategory',
      'leave_category',
      'category',
      'type'
    ]);
    if (leaveType.isNotEmpty) {
      _log('Found leave type: "$leaveType" in item: ${it.toString()}');
    } else {
      _log('No leave type found in item, available keys: ${it.keys.toList()}');
    }
    return leaveType;
  }

  bool _looksPermission(Map<String, dynamic> it) {
    final lt = _leaveTypeOf(it);
    final ltLower = lt.toLowerCase();
    final rsn = (it['reason'] ?? '').toString().toLowerCase();
    final isMatch = ltLower == 'permission time' ||
        ltLower == 'permission' ||
        ltLower == 'permission_time' ||
        rsn.contains('permission');
    if (isMatch) {
      _log('Permission match - Type: "$lt", Reason: "$rsn"');
    }
    return isMatch;
  }

  bool _looksOvertime(Map<String, dynamic> it) {
    final lt = _leaveTypeOf(it);
    final ltLower = lt.toLowerCase();
    final rsn = (it['reason'] ?? '').toString().toLowerCase();
    final isMatch = ltLower == 'overtime' ||
        ltLower == 'over time' ||
        ltLower == 'over_time' ||
        rsn.contains('overtime') ||
        rsn.contains('over time');
    if (isMatch) {
      _log('Overtime match - Type: "$lt", Reason: "$rsn"');
    }
    return isMatch;
  }

  bool _looksHalfday(Map<String, dynamic> it) {
    final lt = _leaveTypeOf(it);
    final ltLower = lt.toLowerCase();
    final rsn = (it['reason'] ?? '').toString().toLowerCase();
    final isMatch = ltLower == 'half-day' ||
        ltLower == 'half day' ||
        ltLower == 'halfday' ||
        ltLower == 'half_day' ||
        ltLower == 'half-day' ||
        (rsn.contains('half') && rsn.contains('day'));
    if (isMatch) {
      _log('Half day match - Type: "$lt", Reason: "$rsn"');
    }
    return isMatch;
  }

  bool _looksCompoff(Map<String, dynamic> it) {
    final lt = _leaveTypeOf(it);
    final ltLower = lt.toLowerCase();
    final rsn = (it['reason'] ?? '').toString().toLowerCase();
    final isMatch = ltLower == 'comp off' ||
        ltLower == 'compoff' ||
        ltLower == 'comp-off' ||
        ltLower == 'comp_off' ||
        rsn.contains('comp off') ||
        rsn.contains('compoff');
    if (isMatch) {
      _log('Comp off match - Type: "$lt", Reason: "$rsn"');
    }
    return isMatch;
  }

  String _uiLabelForLeaveType(Map<String, dynamic> it) {
    if (_looksPermission(it)) return 'Permission';
    if (_looksOvertime(it)) return 'Over Time';
    if (_looksHalfday(it)) return 'Half Day Leave';
    if (_looksCompoff(it)) return 'Comp Off';
    return 'Leave Type';
  }

  bool _isGenericLeaveRequest(Map<String, dynamic> item) {
    final source = _sourceFromItemOrTab(item).trim().toLowerCase();
    final uiType = _uiLabelForLeaveType(item)
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    return source == 'leaves' && (uiType == 'leave type' || uiType == 'leave');
  }

  List<Map<String, dynamic>> _filterByTabSmart(
      List<Map<String, dynamic>> items, String tab) {
    final t = tab.trim().toLowerCase();
    if (kDebugMode) {
      _log('=== FILTERING DEBUG START ===');
      _log('Selected dropdown value: "$tab"');
      _log('Normalized tab: "$t"');
      _log('Total items before filtering: ${items.length}');
      final itemsToLog = items.take(3).toList();
      for (var i = 0; i < itemsToLog.length; i++) {
        _log(
            'Item $i - Source: "${itemsToLog[i]['source']}", Type: "${itemsToLog[i]['type']}"');
      }
    }

    if (t == 'late check in' || t == 'early check out') {
      final result = items.where((item) {
        final source = (item['source'] ?? '').toString().toLowerCase();
        final type = (item['type'] ?? '').toString().toLowerCase();

        if (source != 'attendance') return false;

        final isMatch = type == t;
        if (isMatch) {
          _log('Found attendance request - Source: $source, Type: "$type"');
        }
        return isMatch;
      }).toList();

      _log('Found ${result.length} items matching tab: $t');
      return result;
    }

    if (t == 'permission' ||
        t == 'over time' ||
        t == 'half day leave' ||
        t == 'comp off' ||
        t == 'leave type') {
      final result = items.where((item) {
        final source = (item['source'] ?? '').toString().toLowerCase();
        final backendType = (item['type'] ?? '').toString().toLowerCase();

        if (source != 'leaves') return false;

        final isMatch = backendType == t;
        if (isMatch) {
          _log(
              'Found leave request - Source: $source, Backend Type: "$backendType"');
        }
        return isMatch;
      }).toList();

      _log('Found ${result.length} items matching tab: $t');
      return result;
    }

    if (t == 'leave type') {
      final result = items.where((item) {
        final source = (item['source'] ?? '').toString().toLowerCase();
        final backendType = (item['type'] ?? '').toString().toLowerCase();

        if (source != 'leaves') return false;

        final isSpecialType = backendType == 'permission' ||
            backendType == 'over time' ||
            backendType == 'half day leave' ||
            backendType == 'comp off';

        final isGenericLeave = !isSpecialType && backendType == 'leave type';
        if (isGenericLeave) {
          _log(
              'Found generic leave request - Source: $source, Backend Type: "$backendType"');
        }
        return isGenericLeave;
      }).toList();

      _log('Found ${result.length} generic leave type items');
      if (kDebugMode) {
        _log('=== FILTERING DEBUG END ===');
      }
      return result;
    }

    if (t == 'other location' || t == 'other_location') {
      return items.where((item) {
        final source = (item['source'] ?? '').toString().toLowerCase();
        return source == 'other_location';
      }).toList();
    }

    _log(
        'No specific filter for tab "$t", returning all ${items.length} items');
    if (kDebugMode) {
      _log('=== FILTERING DEBUG END ===');
    }
    return items;
  }

  Future<List<Map<String, dynamic>>> _fetchByTabAndStatus(
      String tab, String status) async {
    final startTime = DateTime.now();
    _log('Fetching data for tab: $tab, status: $status');

    List<Map<String, dynamic>> result;

    try {
      if (_isOtherLocationTab(tab)) {
        final data = await ApiService.fetchOtherLocationApprovals(
          status: status,
        );

        result = data
            .map(
              (item) => {
                ...item,
                'source': 'other_location',
                'type': 'Other Location',
              },
            )
            .toList();
      } else {
        final t = tab.trim().toLowerCase();

        if (t == 'all') {
          _log('Fetching all approvals without duplicate merge');

          final data = await ApiService.fetchApprovals(
            type: 'All',
            status: status,
          );

          final uniqueMap = <String, Map<String, dynamic>>{};

          for (final item in data) {
            final id = _pickAnyId(item);
            final source = (item['source'] ?? '').toString();
            final empid =
                (item['empid'] ?? item['empId'] ?? item['employeeId'] ?? '')
                    .toString();
            final date =
                (item['requestDate'] ?? item['date'] ?? item['startDate'] ?? '')
                    .toString();
            final type =
                (item['type'] ?? item['category'] ?? item['leaveType'] ?? '')
                    .toString();

            final key =
                id.isNotEmpty ? '$source-$id' : '$source-$empid-$date-$type';

            uniqueMap[key] = item;
          }

          result = _filterByTabSmart(
            uniqueMap.values.toList(),
            tab,
          );

          if (kDebugMode) {
            _log('Fetched all approvals: ${data.length}');
            _log(
                'Unique approvals after removing duplicates: ${result.length}');
          }
        } else if (t == 'late check in' || t == 'early check out') {
          _log('Fetching attendance data for tab: $tab');

          final data = await ApiService.fetchAttendanceApprovals(
            status: status,
          );

          if (kDebugMode) {
            _log('Fetched ${data.length} attendance items');
          }

          result = _filterByTabSmart(data, tab);
        } else if (t == 'permission' ||
            t == 'over time' ||
            t == 'half day leave' ||
            t == 'comp off' ||
            t == 'leave type') {
          _log('Fetching leave data for tab: $tab');

          final data = await ApiService.fetchLeaveApprovals(
            status: status,
          );

          if (kDebugMode) {
            _log('Fetched ${data.length} leave items');
          }

          result = _filterByTabSmart(data, tab);
        } else {
          final apiType = _apiTypeForTab(tab);
          _log('API type for tab "$tab": $apiType');

          final data = await ApiService.fetchApprovals(
            type: apiType,
            status: status,
          );

          if (kDebugMode) {
            _log('Fetched ${data.length} items from API');
          }

          result = _filterByTabSmart(data, tab);
        }
      }

      final endTime = DateTime.now();

      PerformanceLogger.logApiCall(
        screen: 'LeaveApprovalsScreen',
        endpoint: 'approvals/$tab',
        startTime: startTime,
        endTime: endTime,
        statusCode: 200,
        itemCount: result.length,
      );

      return result;
    } catch (e) {
      final endTime = DateTime.now();

      PerformanceLogger.logApiCall(
        screen: 'LeaveApprovalsScreen',
        endpoint: 'approvals/$tab',
        startTime: startTime,
        endTime: endTime,
        statusCode: 0,
        error: e.toString(),
      );

      rethrow;
    }
  }

  Future<void> _loadAll({bool adjustForType = false}) async {
    if (_isFetching) {
      _log('Approval fetch already running. Duplicate call skipped.');
      return;
    }

    _isFetching = true;

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final allData = await _fetchByTabAndStatus(selectedTab, 'All');

      String rowStatus(Map<String, dynamic> e) {
        return (e['status'] ?? e['approvalStatus'] ?? '').toString().trim();
      }

      final pending = allData.where((e) => rowStatus(e) == 'Pending').toList();
      final approved =
          allData.where((e) => rowStatus(e) == 'Approved').toList();
      final rejected =
          allData.where((e) => rowStatus(e) == 'Rejected').toList();

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
      _log('Failed to fetch approvals without clearing old data: $e');

      if (mounted) {
        _snack(
          e.toString().contains('429')
              ? 'Too many requests. Please wait and try again.'
              : 'Failed to fetch approvals. Existing data is kept.',
        );
      }

      // Important:
      // Do not clear _rows.
      // Do not set counts to 0.
    } finally {
      _isFetching = false;

      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4A3B67),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Map<String, dynamic> _toDisplay(Map<String, dynamic> item) {
    String pickStr(List keys, {String fallback = '-'}) {
      for (final k in keys) {
        final v = item[k];
        if (v == null) continue;

        if (v is String) {
          if (v.trim().isNotEmpty) return v.trim();
          continue;
        }

        if (v is Map) {
          // common nested keys that may contain the reason text
          for (final cand in [
            'reason',
            'remarks',
            'description',
            'otherLocation',
            'note',
            'details'
          ]) {
            final s = v[cand]?.toString();
            if (s != null && s.trim().isNotEmpty) return s.trim();
          }
          // fallback to JSON-like string
          final s = v.toString();
          if (s.trim().isNotEmpty) return s;
          continue;
        }

        if (v is List) {
          final s = v
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .join(', ');
          if (s.isNotEmpty) return s;
          continue;
        }

        final s = v.toString();
        if (s.trim().isNotEmpty) return s.trim();
      }
      return fallback;
    }

    final requestTime = pickStr(['requestTime', 'time', 'checkIn', 'checkOut']);
    final requestDate = pickStr(
        ['requestDate', 'date', 'startDate', 'selectDate'],
        fallback: '');

    final typeLabel = _sourceFromItemOrTab(item) == 'leaves'
        ? _uiLabelForLeaveType(item)
        : pickStr(['type', 'category'], fallback: '-');

    // Preserve the original leaveType field for classification
    final originalLeaveType = item['leaveType'];

    return <String, dynamic>{
      'type': typeLabel,
      'leaveType': originalLeaveType, // Preserve original leaveType
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
        String empid = (backendItem['empid'] ??
                    backendItem['empId'] ??
                    backendItem['employeeId'])
                ?.toString() ??
            '';
        String date = (backendItem['requestDate'] ??
                    backendItem['date'] ??
                    backendItem['onDate'])
                ?.toString() ??
            '';
        if (date.length > 10) date = date.substring(0, 10);

        if (id.isNotEmpty) {
          details = await ApiService.fetchRequestDetails(id: id, src: src);
        } else if (empid.isNotEmpty && date.isNotEmpty) {
          details =
              await ApiService.fetchRequestDetails(empid: empid, date: date);
        }
      }
    } catch (e) {
      debugPrint('fetchRequestDetails failed: $e');
    }

    final merged = {...backendItem, ...viewItem, ...details};

    if (!mounted) return;
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

        final isGenericLeave = _isGenericLeaveRequest(backendItem);
        // Prevent approving generic Leave Type from details page (requires Paid/Unpaid selection on main screen)
        if (isGenericLeave && normalized == 'Approved') {
          _snack(
              'Please select Paid Leave or Unpaid Leave on the main approvals screen before approving.');
          return;
        }

        if (src == 'other_location') {
          final id = _pickAnyId(backendItem);
          if (id.isEmpty) throw 'Missing id for other-location';
          await ApiService.decideOtherLocation(
            id: id,
            status: normalized,
            remarks: backendItem['decisionRemarks'],
          );
        } else {
          final payload = Map<String, dynamic>.from(backendItem)
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
  }

  @override
  Widget build(BuildContext context) {
    const kAppBarColor = Color(0xFF7C63A8);
    const kTextPrimary = Color(0xFF2D2438);
    const kTextSecondary = Color(0xFF6E647D);
    const kSurface = Colors.white;
    const kBgTop = Color(0xFFFDFBFF);
    const kBgBottom = Color(0xFFF1EAF9);
    const kBorder = Color(0xFFE4DDF0);

    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    final displayList = _rows.map(_toDisplay).toList();
    final q = searchController.text.toLowerCase();

    final filteredIndices = <int>[];
    final filteredDisplay = <Map<String, dynamic>>[];
    for (int i = 0; i < displayList.length; i++) {
      final disp = displayList[i];
      final hit = disp.values
          .any((v) => (v ?? '').toString().toLowerCase().contains(q));
      if (hit) {
        filteredIndices.add(i);
        filteredDisplay.add(disp);
      }
    }

    return Scaffold(
      backgroundColor: kBgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kBgTop, kBgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(
                          text: 'Leave\n',
                          style: TextStyle(color: Color(0xFF1E1B4B)),
                        ),
                        TextSpan(
                          text: 'Approvals',
                          style: TextStyle(color: Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live  ·  ',
                        style: TextStyle(
                          color: Color(0xFF8B7AA8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        today,
                        style: const TextStyle(
                          color: Color(0xFF8B7AA8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSurface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        
                        if (isMobile) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F3FC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: kBorder),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedTab,
                                    onChanged: (val) async {
                                      setState(() => selectedTab = val!);
                                      await _loadAll(adjustForType: true);
                                    },
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: kTextPrimary,
                                    ),
                                    style: const TextStyle(
                                      color: kTextPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    dropdownColor: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
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
                                    ]
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                              _buildStatusButton("Pending", _cPending),
                              _buildStatusButton("Approved", _cApproved),
                              _buildStatusButton("Rejected", _cRejected),
                            ],
                          );
                        } else {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F3FC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedTab,
                                      onChanged: (val) async {
                                        setState(() => selectedTab = val!);
                                        await _loadAll(adjustForType: true);
                                      },
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: kTextPrimary,
                                      ),
                                      style: const TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      dropdownColor: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
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
                                      ]
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(t),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                                _buildStatusButton("Pending", _cPending),
                                const SizedBox(width: 8),
                                _buildStatusButton("Approved", _cApproved),
                                const SizedBox(width: 8),
                                _buildStatusButton("Rejected", _cRejected),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0E000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14,
                    color: kTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by employee, type, department...',
                    hintStyle: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: kTextSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFBDA9DD),
                        width: 1.2,
                      ),
                    ),
                    filled: true,
                    fillColor: kSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredDisplay.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 42,
                                  color: kTextSecondary,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No requests found',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Try changing the filter or search text.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredDisplay.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, viewIdx) {
                              final backendIdx = filteredIndices[viewIdx];
                              final backendItem = _rows[backendIdx];
                              final viewItem = filteredDisplay[viewIdx];

                              final tappable = _isRowTappable(backendItem);

                              final requestKey = _pickAnyId(backendItem)
                                      .isNotEmpty
                                  ? _pickAnyId(backendItem)
                                  : '${backendItem['empid']}_${backendItem['requestDate']}_${backendItem['type']}';

                              // Use unified generic-leave detection
                              final isGenericLeave =
                                  _isGenericLeaveRequest(backendItem);
                              viewItem['isLeaveRequest'] = isGenericLeave;

                              final card = Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: tappable
                                      ? () => _openDetails(
                                            backendItem,
                                            viewItem,
                                          )
                                      : null,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: Colors.transparent,
                                    ),
                                    child: LeaveCard(
                                      item: viewItem,
                                      isProcessing:
                                          _processingRequestIds.contains(
                                        requestKey,
                                      ),
                                      paidLeaveDays: _calculateEmployeeLeaveTotals(
                                        backendItem['empid']?.toString() ?? backendItem['id']?.toString() ?? '',
                                        _rows,
                                      )['paid'],
                                      unpaidLeaveDays: _calculateEmployeeLeaveTotals(
                                        backendItem['empid']?.toString() ?? backendItem['id']?.toString() ?? '',
                                        _rows,
                                      )['unpaid'],
                                      onStatusChange: (status) async {
                                        if (_processingRequestIds
                                            .contains(requestKey)) {
                                          return;
                                        }

                                        // Handle new paid/unpaid approval actions
                                        String? leavePayType;
                                        String normalizedStatus;

                                        if (status == 'approved_paid') {
                                          leavePayType = 'paid';
                                          normalizedStatus = 'Approved';
                                        } else if (status == 'approved_unpaid') {
                                          leavePayType = 'unpaid';
                                          normalizedStatus = 'Approved';
                                        } else {
                                          normalizedStatus = _normalizeDecision(status);
                                        }

                                        setState(() {
                                          _processingRequestIds.add(requestKey);
                                        });

                                        try {
                                          if (normalizedStatus != 'Approved' &&
                                              normalizedStatus != 'Rejected') {
                                            throw 'Invalid status "$status"';
                                          }

                                          final src =
                                              _sourceFromItemOrTab(backendItem);

                                          if (src == 'other_location') {
                                            final id = _pickAnyId(backendItem);
                                            if (id.isEmpty) {
                                              throw 'Missing id for other-location';
                                            }

                                            await ApiService
                                                .decideOtherLocation(
                                              id: id,
                                              status: normalizedStatus,
                                              remarks: backendItem[
                                                  'decisionRemarks'],
                                            );
                                          } else {
                                            final payloadItem =
                                                Map<String, dynamic>.from(
                                                    backendItem)
                                                  ..['status'] = normalizedStatus;

                                            await ApiService.decideApproval(
                                              item: payloadItem,
                                              status: normalizedStatus,
                                              sourceHint: src,
                                              leavePayType: leavePayType,
                                            );
                                          }

                                          if (!mounted) return;

                                          setState(() {
                                            final oldStatus =
                                                (backendItem['status'] ??
                                                        backendItem[
                                                            'approvalStatus'] ??
                                                        'Pending')
                                                    .toString()
                                                    .trim();

                                            backendItem['status'] = normalizedStatus;
                                            backendItem['approvalStatus'] =
                                                normalizedStatus;
                                            viewItem['status'] =
                                                normalizedStatus.toLowerCase();

                                            if (oldStatus == 'Pending' &&
                                                _cPending > 0) {
                                              _cPending--;
                                            } else if (oldStatus ==
                                                    'Approved' &&
                                                _cApproved > 0) {
                                              _cApproved--;
                                            } else if (oldStatus ==
                                                    'Rejected' &&
                                                _cRejected > 0) {
                                              _cRejected--;
                                            }

                                            if (normalizedStatus == 'Approved') {
                                              _cApproved++;
                                            } else if (normalizedStatus ==
                                                'Rejected') {
                                              _cRejected++;
                                            }

                                            if (selectedStatusFilter ==
                                                'Pending') {
                                              _rows.removeAt(backendIdx);
                                            } else {
                                              _rows[backendIdx] = backendItem;
                                            }
                                          });

                                          _snack('Updated: $normalizedStatus');
                                        } catch (e) {
                                          _snack('Update failed: $e');
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _processingRequestIds
                                                  .remove(requestKey);
                                            });
                                          }
                                        }
                                      },
                                      // payroll handled via `leavePayType` during approval
                                    ),
                                  ),
                                ),
                              );

                              return card;
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, int count) {
    final isSelected = selectedStatusFilter == label;

    final Color bgColor = label == 'Pending'
        ? const Color(0xFFFFE4EF)
        : label == 'Approved'
            ? const Color(0xFFE2F7EA)
            : const Color(0xFFFFE4E4);

    final Color selectedColor = label == 'Pending'
        ? const Color(0xFFE85C9E)
        : label == 'Approved'
            ? const Color(0xFF33A96B)
            : const Color(0xFFD95C5C);

    final Color textColor = isSelected ? Colors.white : const Color(0xFF3D3150);

    return GestureDetector(
      onTap: () async {
        setState(() => selectedStatusFilter = label);
        await _loadAll();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFE4DDF0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
