import 'dart:async';

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
  List<Map<String, dynamic>> _filteredDisplay = [];
  List<int> _filteredBackendIndices = [];
  int _cPending = 0, _cApproved = 0, _cRejected = 0;
  bool _loading = false;
  bool _isFetching = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  int _requestGeneration = 0;
  String _searchQuery = '';
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _processingRequestIds = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAll(adjustForType: true);
  }

  bool _isOtherLocationTab(String label) {
    final t = label.trim().toLowerCase();
    return t == 'other location' || t == 'other_location';
  }

  String _apiTypeForTab(String ui) {
    return ui;
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
    return items;
  }

  Future<ApprovalsPage> _fetchByTabAndStatus(
    String tab,
    String status, {
    int page = 1,
    int limit = 20,
  }) async {
    final startTime = DateTime.now();
    final endpoint = _isOtherLocationTab(tab)
        ? '/attendance/other-location'
        : '/attendance/approvals';

    try {
      if (_isOtherLocationTab(tab)) {
        final pageResult = await ApiService.fetchOtherLocationApprovalsPaginated(
          status: status,
          page: page,
          limit: limit,
        );

        final data = pageResult.data
            .map(
              (item) => {
                ...item,
                'source': 'other_location',
                'type': 'Other Location',
              },
            )
            .toList();

        final endTime = DateTime.now();
        PerformanceLogger.logApiCall(
          screen: 'LeaveApprovalsScreen',
          endpoint: endpoint,
          startTime: startTime,
          endTime: endTime,
          statusCode: 200,
          itemCount: data.length,
        );

        return ApprovalsPage(
          data: data,
          pagination: pageResult.pagination,
          totals: pageResult.totals,
        );
      }

      final apiType = _apiTypeForTab(tab);
      final pageResult = await ApiService.fetchApprovalsPaginated(
        type: apiType,
        status: status,
        search: _searchQuery,
        page: page,
        limit: limit,
      );

      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'LeaveApprovalsScreen',
        endpoint: endpoint,
        startTime: startTime,
        endTime: endTime,
        statusCode: 200,
        itemCount: pageResult.data.length,
      );

      return pageResult;
    } catch (e) {
      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'LeaveApprovalsScreen',
        endpoint: endpoint,
        startTime: startTime,
        endTime: endTime,
        statusCode: 0,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> _loadAll({bool adjustForType = false, bool append = false}) async {
    if (_isFetching && append) {
      if (kDebugMode) {
        _log('Approval fetch already running. Duplicate load-more skipped.');
      }
      return;
    }

    _isFetching = true;

    if (!append) {
      _currentPage = 1;
      _hasMore = true;
      if (mounted) {
        setState(() => _loading = true);
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingMore = true);
      }
    }

    final generation = ++_requestGeneration;
    final startTime = DateTime.now();

    try {
      final pageResult = await _fetchByTabAndStatus(
        selectedTab,
        selectedStatusFilter,
        page: _currentPage,
        limit: _pageSize,
      );

      if (generation != _requestGeneration) {
        if (append && mounted) {
          setState(() => _isLoadingMore = false);
        }
        return;
      }

      final newItems = pageResult.data;
      final pagination = pageResult.pagination;
      final totals = pageResult.totals;

      final backendMs = DateTime.now().difference(startTime).inMilliseconds;
      if (kDebugMode) {
        _log(
          'Approvals loaded: type=$selectedTab, status=$selectedStatusFilter, '
          'page=$_currentPage, limit=$_pageSize, items=${newItems.length}, '
          'total=${pagination['total']}, hasMore=${pagination['hasMore']}, '
          'backendMs=$backendMs, frontendMs=${DateTime.now().difference(startTime).inMilliseconds}',
        );
      }

      if (!mounted) return;

      final mergedItems = <Map<String, dynamic>>[];
      final seenKeys = <String>{};
      for (final item in [...(append ? _rows : <Map<String, dynamic>>[]), ...newItems]) {
        final key = _stableKey(item);
        if (seenKeys.add(key)) mergedItems.add(item);
      }

      setState(() {
        _rows = mergedItems;
        _hasMore = pagination['hasMore'] == true;
        _isLoadingMore = false;
        _loading = false;

        if (totals.isNotEmpty) {
          debugPrint('[LEAVE_APPROVAL] API totals received: $totals');
          _cPending = totals['Pending'] ?? _cPending;
          _cApproved = totals['Approved'] ?? _cApproved;
          _cRejected = totals['Rejected'] ?? _cRejected;
          debugPrint('[LEAVE_APPROVAL] Updated counts - Pending: $_cPending, Approved: $_cApproved, Rejected: $_cRejected');
        } else {
          final total = (pagination['total'] as num?)?.toInt() ?? _rows.length;
          if (selectedStatusFilter == 'Pending') _cPending = total;
          if (selectedStatusFilter == 'Approved') _cApproved = total;
          if (selectedStatusFilter == 'Rejected') _cRejected = total;
        }
      });

      _applySearch();

      if (adjustForType && _rows.isEmpty) {
        final nextStatus = _cPending > 0
            ? 'Pending'
            : _cApproved > 0
                ? 'Approved'
                : _cRejected > 0
                    ? 'Rejected'
                    : null;
        if (nextStatus != null && nextStatus != selectedStatusFilter) {
          _isFetching = false;
          selectedStatusFilter = nextStatus;
          await _loadAll(adjustForType: false);
          return;
        }
      }
    } catch (e) {
      if (generation != _requestGeneration) {
        if (append && mounted) {
          setState(() => _isLoadingMore = false);
        }
        return;
      }
      if (kDebugMode) {
        _log('Failed to fetch approvals (page=$_currentPage): $e');
      }
      if (mounted) {
        _snack(
          e.toString().contains('429')
              ? 'Too many requests. Please wait and try again.'
              : 'Failed to fetch approvals. Existing data is kept.',
        );
        setState(() {
          _loading = false;
          _isLoadingMore = false;
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isFetching || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadAll(append: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max - 200) {
      _loadMore();
    }
  }

  String _stableKey(Map<String, dynamic> item) {
    final source = (item['source'] ?? '').toString();
    final id = _pickAnyId(item);
    if (id.isNotEmpty) return '${source}_$id';
    final empid = (item['empid'] ?? item['empId'] ?? item['employeeId'] ?? '').toString();
    final date = (item['requestDate'] ?? item['date'] ?? item['startDate'] ?? '').toString();
    final type = (item['type'] ?? item['category'] ?? '').toString();
    return '${source}_${empid}_${date}_$type';
  }

  void _applySearch() {
    final displayList = _rows.map(_toDisplay).toList();
    final q = _searchQuery.trim().toLowerCase();

    final indices = <int>[];
    final filtered = <Map<String, dynamic>>[];

    for (int i = 0; i < displayList.length; i++) {
      final disp = displayList[i];
      final hit = q.isEmpty ||
          disp.values.any((v) => (v ?? '').toString().toLowerCase().contains(q));
      if (hit) {
        indices.add(i);
        filtered.add(disp);
      }
    }

    if (!mounted) return;
    setState(() {
      _filteredDisplay = filtered;
      _filteredBackendIndices = indices;
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      _searchQuery = value;
      _currentPage = 1;
      _hasMore = true;
      await _loadAll();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
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

  double _monthlySummaryValue(Map<String, dynamic> item, String key) {
    final summary = item['monthlyLeaveSummary'];
    if (summary is! Map) return 0;
    final value = summary[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
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

        debugPrint('[LEAVE_APPROVAL] Before ${normalized.toLowerCase()} - Pending: $_cPending, Approved: $_cApproved, Rejected: $_cRejected');

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

        // Optimistic UI update
        setState(() {
          // Remove the approved/rejected item from the list by ID
          final itemId = _pickAnyId(backendItem);
          _rows.removeWhere((item) => _pickAnyId(item) == itemId);
          
          // Update counters locally
          if (normalized == 'Approved') {
            if (_cPending > 0) _cPending--;
            _cApproved++;
          } else if (normalized == 'Rejected') {
            if (_cPending > 0) _cPending--;
            _cRejected++;
          }
        });

        debugPrint('[LEAVE_APPROVAL] Removed item id: ${_pickAnyId(backendItem)}');
        debugPrint('[LEAVE_APPROVAL] Current rows count: ${_rows.length}');

        _snack('Updated: $normalized');

        // If list count is less than page limit, fetch next record silently in background
        if (_rows.length < _pageSize && _hasMore) {
          debugPrint('[LEAVE_APPROVAL] Background fetch triggered - current count: ${_rows.length}, page limit: $_pageSize');
          _loadMore();
        } else if (_rows.length == 0 && _cPending == 0) {
          debugPrint('[LEAVE_APPROVAL] No more pending approvals available');
        }
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

    final filteredIndices = _filteredBackendIndices;
    final filteredDisplay = _filteredDisplay;

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
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          debugPrint('[LEAVE_APPROVAL] Refresh clicked');
                          _loadAll(adjustForType: false);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 20,
                            color: Color(0xFF7C63A8),
                          ),
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
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                                      setState(() {
                                        selectedTab = val!;
                                        _currentPage = 1;
                                        _hasMore = true;
                                      });
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
                                        setState(() {
                                          selectedTab = val!;
                                          _currentPage = 1;
                                          _hasMore = true;
                                        });
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
                  onChanged: _onSearchChanged,
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
                              children: [
                                Icon(
                                  selectedStatusFilter == 'Pending' && _cPending == 0
                                      ? Icons.check_circle_outline
                                      : Icons.inbox_outlined,
                                  size: 42,
                                  color: selectedStatusFilter == 'Pending' && _cPending == 0
                                      ? const Color(0xFF4CAF50)
                                      : kTextSecondary,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  selectedStatusFilter == 'Pending' && _cPending == 0
                                      ? 'No pending approvals available'
                                      : 'No requests found',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  selectedStatusFilter == 'Pending' && _cPending == 0
                                      ? 'Tap the refresh button to check for new requests'
                                      : 'Try changing the filter or search text.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
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

                              final requestKey = _stableKey(backendItem);
                              final paidLeaveDays =
                                  _monthlySummaryValue(backendItem, 'paid');
                              final unpaidLeaveDays =
                                  _monthlySummaryValue(backendItem, 'unpaid');

                              // Use unified generic-leave detection
                              final isGenericLeave =
                                  _isGenericLeaveRequest(backendItem);
                              viewItem['isLeaveRequest'] = isGenericLeave;

                              final card = Material(
                                key: ValueKey(requestKey),
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
                                      paidLeaveDays: paidLeaveDays,
                                      unpaidLeaveDays: unpaidLeaveDays,
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

                                          debugPrint('[LEAVE_APPROVAL] Before ${normalizedStatus.toLowerCase()} - Pending: $_cPending, Approved: $_cApproved, Rejected: $_cRejected');

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

                                          debugPrint('[LEAVE_APPROVAL] Removed item id: ${_pickAnyId(backendItem)}');
                                          debugPrint('[LEAVE_APPROVAL] Current rows count: ${_rows.length}');

                                          _applySearch();
                                          _snack('Updated: $normalizedStatus');

                                          // If list count is less than page limit, fetch next record silently in background
                                          if (_rows.length < _pageSize && _hasMore) {
                                            debugPrint('[LEAVE_APPROVAL] Background fetch triggered - current count: ${_rows.length}, page limit: $_pageSize');
                                            _loadMore();
                                          } else if (_rows.length == 0 && _cPending == 0) {
                                            debugPrint('[LEAVE_APPROVAL] No more pending approvals available');
                                          }
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
        setState(() {
          selectedStatusFilter = label;
          _currentPage = 1;
          _hasMore = true;
        });
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
