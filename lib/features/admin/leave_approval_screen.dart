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

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen>
    with TickerProviderStateMixin {
  String selectedTab = 'All';
  String selectedStatusFilter = 'Pending';
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> _rows = [];
  int _cPending = 0, _cApproved = 0, _cRejected = 0;
  bool _loading = false;
  bool _isFetching = false;
  final Set<String> _processingRequestIds = <String>{};

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadAll(adjustForType: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _recalculateCountsFromAllData(List<Map<String, dynamic>> allData) {
    String rowStatus(Map<String, dynamic> e) {
      return (e['status'] ?? e['approvalStatus'] ?? '').toString().trim();
    }

    _cPending = allData.where((e) => rowStatus(e) == 'Pending').length;
    _cApproved = allData.where((e) => rowStatus(e) == 'Approved').length;
    _cRejected = allData.where((e) => rowStatus(e) == 'Rejected').length;
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
      _log(
          'No leave type found in item, available keys: ${it.keys.toList()}');
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

            final key = id.isNotEmpty
                ? '$source-$id'
                : '$source-$empid-$date-$type';

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

      final pending =
          allData.where((e) => rowStatus(e) == 'Pending').toList();
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
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D1B5E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  Map<String, dynamic> _toDisplay(Map<String, dynamic> item) {
    String pickStr(List keys, {String fallback = '-'}) {
      for (final k in keys) {
        final v = item[k]?.toString();
        if (v != null && v.trim().isNotEmpty) return v;
      }
      return fallback;
    }

    final requestTime =
        pickStr(['requestTime', 'time', 'checkIn', 'checkOut']);
    final requestDate = pickStr(
        ['requestDate', 'date', 'startDate', 'selectDate'],
        fallback: '');

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

  // ─── DESIGN TOKENS ────────────────────────────────────────────────────────
  static const kGradientStart = Color(0xFFFF2D8B);   // hot pink
  static const kGradientMid   = Color(0xFFBB22C9);   // vibrant purple
  static const kGradientEnd   = Color(0xFF2B0E6B);   // deep indigo
  static const kAccentPink    = Color(0xFFFF3CA0);
  static const kAccentViolet  = Color(0xFFAB5CF7);
  static const kAccentGold    = Color(0xFFF5C542);
  static const kCardBg        = Color(0x26FFFFFF);   // white 15% alpha
  static const kCardBorder    = Color(0x40FFFFFF);   // white 25% alpha
  static const kTextPrimary   = Colors.white;
  static const kTextSub       = Color(0xCCFFFFFF);   // white 80%
  static const kTextMuted     = Color(0x99FFFFFF);   // white 60%

  @override
  Widget build(BuildContext context) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kGradientStart, kGradientMid, kGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative blobs in background
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(today),
                    const SizedBox(height: 20),
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    _buildFilterCard(),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _loading
                          ? _buildLoadingState()
                          : filteredDisplay.isEmpty
                              ? _buildEmptyState()
                              : _buildList(filteredIndices, filteredDisplay),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String today) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFFFCCE8)],
              ).createShader(bounds),
              child: const Text(
                'Leave',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFCCE8), Color(0xFFE8B4FF)],
              ).createShader(bounds),
              child: const Text(
                'Approvals',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.05,
                  letterSpacing: -1,
                ),
              ),
            ),
          ],
        ),
        // Live badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: kCardBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4ADE80)
                        .withOpacity(_pulseAnimation.value),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ADE80)
                            .withOpacity(_pulseAnimation.value * 0.6),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live',
                style: TextStyle(
                  color: kTextSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatChip(
          label: 'Pending',
          count: _cPending,
          color: const Color(0xFFFFD700),
          icon: Icons.hourglass_top_rounded,
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          label: 'Approved',
          count: _cApproved,
          color: const Color(0xFF4ADE80),
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          label: 'Rejected',
          count: _cRejected,
          color: const Color(0xFFFF6B6B),
          icon: Icons.cancel_rounded,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kCardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: kAccentPink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Request Filters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDropdown(),
                const SizedBox(width: 8),
                _buildStatusButton('Pending', _cPending),
                const SizedBox(width: 8),
                _buildStatusButton('Approved', _cApproved),
                const SizedBox(width: 8),
                _buildStatusButton('Rejected', _cRejected),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
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
            color: Colors.white,
            size: 18,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: const Color(0xFF3D1B7A),
          borderRadius: BorderRadius.circular(16),
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
                  child: Text(
                    t,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCardBorder, width: 1),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search by employee, type, department...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.6),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.5),
              width: 1.2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: TextStyle(
              color: kTextSub,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 34,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No requests found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try changing the filter or search text.',
            style: TextStyle(
              fontSize: 12,
              color: kTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      List<int> filteredIndices, List<Map<String, dynamic>> filteredDisplay) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredDisplay.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, viewIdx) {
        final backendIdx = filteredIndices[viewIdx];
        final backendItem = _rows[backendIdx];
        final viewItem = filteredDisplay[viewIdx];

        final tappable = _isRowTappable(backendItem);

        final requestKey = _pickAnyId(backendItem).isNotEmpty
            ? _pickAnyId(backendItem)
            : '${backendItem['empid']}_${backendItem['requestDate']}_${backendItem['type']}';

        return Container(
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kCardBorder, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withOpacity(0.08),
              highlightColor: Colors.white.withOpacity(0.04),
              onTap: tappable
                  ? () => _openDetails(backendItem, viewItem)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent,
                ),
                child: LeaveCard(
                  item: viewItem,
                  isProcessing: _processingRequestIds.contains(requestKey),
                  onStatusChange: (status) async {
                    if (_processingRequestIds.contains(requestKey)) return;

                    setState(() {
                      _processingRequestIds.add(requestKey);
                    });

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

                      if (!mounted) return;

                      setState(() {
                        final oldStatus = (backendItem['status'] ??
                                backendItem['approvalStatus'] ??
                                'Pending')
                            .toString()
                            .trim();

                        backendItem['status'] = normalized;
                        backendItem['approvalStatus'] = normalized;
                        viewItem['status'] = normalized.toLowerCase();

                        if (oldStatus == 'Pending' && _cPending > 0) {
                          _cPending--;
                        } else if (oldStatus == 'Approved' &&
                            _cApproved > 0) {
                          _cApproved--;
                        } else if (oldStatus == 'Rejected' &&
                            _cRejected > 0) {
                          _cRejected--;
                        }

                        if (normalized == 'Approved') {
                          _cApproved++;
                        } else if (normalized == 'Rejected') {
                          _cRejected++;
                        }

                        if (selectedStatusFilter == 'Pending') {
                          _rows.removeAt(backendIdx);
                        } else {
                          _rows[backendIdx] = backendItem;
                        }
                      });

                      _snack('Updated: $normalized');
                    } catch (e) {
                      _snack('Update failed: $e');
                    } finally {
                      if (mounted) {
                        setState(() {
                          _processingRequestIds.remove(requestKey);
                        });
                      }
                    }
                  },
                  onPayrollStatusChange: (payrollStatus) async {
                    try {
                      if (payrollStatus != 'paid' &&
                          payrollStatus != 'unpaid') {
                        throw 'Invalid payroll status "$payrollStatus"';
                      }

                      final requestId = _pickAnyId(backendItem);
                      final source = _sourceFromItemOrTab(backendItem);

                      if (requestId.isEmpty) throw 'Missing request ID';

                      await ApiService.updateLeavePayrollStatus(
                        requestId: requestId,
                        payrollStatus: payrollStatus,
                        source: source,
                      );

                      _snack(
                        'Marked as ${payrollStatus == 'paid' ? 'Paid' : 'Unpaid'}',
                      );
                      await _loadAll(adjustForType: true);
                    } catch (e) {
                      _snack('Payroll status update failed: $e');
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusButton(String label, int count) {
    final isSelected = selectedStatusFilter == label;

    final Color activeColor = label == 'Pending'
        ? const Color(0xFFFFD700)
        : label == 'Approved'
            ? const Color(0xFF4ADE80)
            : const Color(0xFFFF6B6B);

    return GestureDetector(
      onTap: () async {
        setState(() => selectedStatusFilter = label);
        await _loadAll();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.22)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? activeColor.withOpacity(0.6)
                : Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: isSelected ? activeColor : Colors.white.withOpacity(0.65),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}