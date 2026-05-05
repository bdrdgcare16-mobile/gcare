import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'employee_detail_page.dart' show EmployeeDetailPage;

import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/models/company_profile.dart';
import 'package:serv_app/utils/performance_logger.dart';

final String _apiBase = ApiConfig.baseUrl;

// ═══════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS  — Dribbble soft-lavender × clean white
// ═══════════════════════════════════════════════════════════════════════════
class _C {
  static const lv50  = Color(0xFFF5F3FF);
  static const lv100 = Color(0xFFEDE9FE);
  static const lv200 = Color(0xFFDDD6FE);
  static const lv400 = Color(0xFFA78BFA);
  static const lv500 = Color(0xFF8B5CF6);
  static const lv600 = Color(0xFF7C3AED);
  static const lv700 = Color(0xFF6D28D9);

  static const white  = Color(0xFFFFFFFF);
  static const bg     = Color(0xFFF7F5FF);
  static const card   = Color(0xFFFFFFFF);
  static const ink    = Color(0xFF1E1B4B);
  static const muted  = Color(0xFF6B7280);
  static const border = Color(0xFFEDE9FE);

  static const green = Color(0xFF10B981);
  static const red   = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const blue  = Color(0xFF3B82F6);
}

// ═══════════════════════════════════════════════════════════════════════════
//  MODELS  — untouched
// ═══════════════════════════════════════════════════════════════════════════
class AttendanceRecord {
  final String empid, name, status;
  final String? checkIn, checkOut;
  final bool late, early;
  final int permissionCount;

  AttendanceRecord({
    required this.empid, required this.name, required this.status,
    this.checkIn, this.checkOut,
    required this.late, required this.early, required this.permissionCount,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
    final empid = j['empid'] as String;
    final name = j['name'] as String;
    final status = j['status'] as String;
    final checkIn = j['checkIn'] as String?;
    final checkOut = j['checkOut'] as String?;
    final late = (j['late'] as bool?) ?? false;
    final early = (j['early'] as bool?) ?? false;
    final permissionCount = (j['permissionCount'] as num?)?.toInt() ?? 0;
    
    // Debug logging for late check-in analysis
    debugPrint('FRONTEND ATTENDANCE DEBUG: employeeId=$empid, name=$name, status=$status, checkIn=$checkIn, checkOut=$checkOut, adminDisplayLate=$late, adminDisplayEarly=$early, permissionCount=$permissionCount');
    
    return AttendanceRecord(
      empid: empid, name: name, status: status,
      checkIn: checkIn, checkOut: checkOut,
      late: late, early: early, permissionCount: permissionCount,
    );
  }
}

class _EmployeeMeta {
  final String empid; final String? dept, shiftGroup;
  _EmployeeMeta({required this.empid, this.dept, this.shiftGroup});
  factory _EmployeeMeta.fromJson(Map<String, dynamic> j) => _EmployeeMeta(
    empid: (j['empid'] ?? '').toString(),
    dept: j['dept']?.toString(), shiftGroup: j['shiftGroup']?.toString(),
  );
}

class _CheckedInRow {
  final String empid, name, date, checkIn;
  final String? dept, shiftGroup;
  _CheckedInRow({required this.empid, required this.name, required this.date,
    required this.checkIn, this.dept, this.shiftGroup});
}

class _AItem {
  final String title; final int count; final List<AttendanceRecord> list;
  final IconData icon; final Color color; final VoidCallback? onTap;
  _AItem(this.title, this.count, this.list, this.icon, this.color, this.onTap);
}

// ═══════════════════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════════════════
class LiveAttendancePage extends StatefulWidget {
  final CompanyProfile companyProfile;
  const LiveAttendancePage({super.key, required this.companyProfile});
  @override
  _LiveAttendancePageState createState() => _LiveAttendancePageState();
}

class _LiveAttendancePageState extends State<LiveAttendancePage>
    with SingleTickerProviderStateMixin {

  bool _isLoading = true;
  String? _error;
  List<AttendanceRecord> _records = [];
  bool _shiftsLoaded = false, _employeesLoaded = false;
  int _pendingApprovalsCount = 0;
  final Map<String, _EmployeeMeta>  _metaById        = {};
  final Map<String, TimeOfDay>      _shiftStartByName = {};

  late AnimationController _ac;
  late Animation<double>   _fade;

  // ── lifecycle ────────────────────────────────────────────────────────
  Future<void> _debugFirebaseAuth() async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      print('Firebase UID: ${u?.uid}');
      print('Firebase Claims: ${(await u?.getIdTokenResult(true))?.claims}');
    } catch (e) { print('Firebase debug error: $e'); }
  }

  @override
  void initState() {
    super.initState();
    _ac   = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _debugFirebaseAuth();
    _fetchAll();
  }

  @override void dispose() { _ac.dispose(); super.dispose(); }

  // ── data ─────────────────────────────────────────────────────────────
  Future<void> _fetchAll() async {
    final screenStartTime = DateTime.now();
    setState(() { _isLoading = true; _error = null; });
    try {
      // ✅ OPTIMIZATION: Load shifts and employees in parallel if not already cached
      List<Future<void>> futures = [];
      
      if (!_shiftsLoaded) {
        futures.add(_loadShiftsFromApi().then((_) => _shiftsLoaded = true));
      }
      if (!_employeesLoaded) {
        futures.add(_fetchEmployeesMeta().then((_) => _employeesLoaded = true));
      }
      
      // Always load live attendance and pending approvals in parallel
      futures.addAll([
        _fetchLiveAttendance(),
        _fetchPendingApprovalsCount()
      ]);
      
      await Future.wait(futures);
      _ac.forward(from: 0);
      
      final screenEndTime = DateTime.now();
      PerformanceLogger.logScreenLoad(
        screen: 'LiveAttendancePage',
        startTime: screenStartTime,
        endTime: screenEndTime,
        metadata: {
          'recordsCount': _records.length,
          'pendingApprovals': _pendingApprovalsCount,
        },
      );
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _fetchLiveAttendance() async {
    final startTime = DateTime.now();
    try {
      final resp = await http.get(
        Uri.parse('${ApiService.baseUrl}/attendance/live'),
        headers: {'Content-Type':'application/json',
          'Authorization':'Bearer ${_safe(CompanyData.token)}'},
      );
      
      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'LiveAttendancePage',
        endpoint: '/attendance/live',
        startTime: startTime,
        endTime: endTime,
        statusCode: resp.statusCode,
        itemCount: resp.statusCode == 200 ? (jsonDecode(resp.body) as List).length : 0,
      );
      
      if (resp.statusCode != 200) {
        if (!mounted) return;
        setState(() => _error = 'Error ${resp.statusCode}: ${resp.body}'); return;
      }
      final recs = (jsonDecode(resp.body) as List)
          .map((e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (!mounted) return;
      setState(() => _records = recs);
    } catch (e) { 
      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'LiveAttendancePage',
        endpoint: '/attendance/live',
        startTime: startTime,
        endTime: endTime,
        statusCode: 0,
        error: e.toString(),
      );
      if (!mounted) return; 
      setState(() => _error = 'Failed to load: $e'); 
    }
  }

  Future<void> _fetchPendingApprovalsCount() async {
    final startTime = DateTime.now();
    try {
      final l = await ApiService.fetchApprovals(type: 'All', status: 'Pending');
      final endTime = DateTime.now();
      
      PerformanceLogger.logApiCall(
        screen: 'LiveAttendancePage',
        endpoint: '/attendance/approvals',
        startTime: startTime,
        endTime: endTime,
        statusCode: 200,
        itemCount: l.length,
      );
      
      if (!mounted) return;
      setState(() => _pendingApprovalsCount = l.length);
    } catch (e) { 
      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'LiveAttendancePage',
        endpoint: '/attendance/approvals',
        startTime: startTime,
        endTime: endTime,
        statusCode: 0,
        error: e.toString(),
      );
      if (!mounted) return; 
      setState(() => _pendingApprovalsCount = 0); 
    }
  }

  Future<void> _fetchEmployeesMeta() async {
    try {
      final resp = await http.get(Uri.parse('${ApiService.baseUrl}/employees'),
        headers: {'Content-Type':'application/json',
          'Authorization':'Bearer ${_safe(CompanyData.token)}'},
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final List<dynamic> data = decoded is List ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List)
                ? decoded['data'] as List<dynamic>
                : (decoded is Map<String, dynamic> && decoded['employees'] is List)
                    ? decoded['employees'] as List<dynamic> : <dynamic>[];
        _metaById.clear();
        for (final e in data) {
          final m = _EmployeeMeta.fromJson(Map<String, dynamic>.from(e as Map));
          if (m.empid.isNotEmpty) _metaById[m.empid] = m;
        }
      }
    } catch (e) { debugPrint('Employees meta: $e'); }
  }

  Future<void> _loadShiftsFromApi() async {
    try {
      final resp = await http.get(Uri.parse('${ApiService.baseUrl}/shifts'),
        headers: {'Content-Type':'application/json',
          'Authorization':'Bearer ${_safe(CompanyData.token)}'},
      );
      if (resp.statusCode != 200) return;
      final decoded = jsonDecode(resp.body);
      final List<dynamic> data = decoded is List ? decoded
          : (decoded is Map<String, dynamic> && decoded['data'] is List)
              ? decoded['data'] as List<dynamic> : <dynamic>[];
      _shiftStartByName.clear();
      for (final e in data) {
        final map = Map<String, dynamic>.from(e as Map);
        final name = (map['shiftname'] ?? map['name'] ?? '').toString().trim();
        final startStr = (map['startTime'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        TimeOfDay? tod = startStr.isNotEmpty ? _parseHHmm(startStr) : null;
        tod ??= _parseNameRange((map['name'] ?? '').toString())?.$1;
        if (tod != null) _shiftStartByName[name] = tod;
      }
    } catch (e) { debugPrint('Shifts: $e'); }
  }

  // ── computed — all unchanged ──────────────────────────────────────────
  bool _isStatus(AttendanceRecord r, String s) =>
      r.status.toLowerCase() == s.toLowerCase();

  int get presentCount  => _records.where((r) {
    final s = r.status.toLowerCase(); return s == 'present' || s.contains('half');
  }).length;
  int get absentCount   => _records.where((r) => _isStatus(r, 'absent')).length;
  int get onLeaveCount  => _records.where((r) => _isStatus(r, 'leave')).length;
  int get checkInCount  => _records.where((r) => r.checkIn  != null).length;
  int get checkOutCount => _records.where((r) => r.checkOut != null).length;

  List<AttendanceRecord> get halfDayRecords {
    final out = <AttendanceRecord>[];
    for (final r in _records) {
      if (r.status.toLowerCase().contains('half')) { out.add(r); continue; }
      if (_isHalfByLateCheckIn(r)) out.add(r);
    }
    return out;
  }
  int get halfDayCount        => halfDayRecords.length;
  int get lateCheckInCount {
    final lateRecords = <AttendanceRecord>[];
    final nonLateRecords = <AttendanceRecord>[];
    
    // Calculate late check-in using proper DateTime comparison with grace period
    for (final r in _records) {
      if (r.checkIn == null || r.checkIn!.isEmpty) {
        nonLateRecords.add(r);
        continue;
      }
      
      final shiftMeta = _metaById[r.empid];
      final shiftGroup = shiftMeta?.shiftGroup?.trim() ?? '';
      final shiftStart = _shiftStartByName[shiftGroup];
      
      if (shiftStart == null) {
        nonLateRecords.add(r);
        continue;
      }
      
      // Parse check-in time
      final checkInParts = r.checkIn!.split(':');
      if (checkInParts.length < 2) {
        nonLateRecords.add(r);
        continue;
      }
      
      final checkInHour = int.tryParse(checkInParts[0]) ?? 0;
      final checkInMinute = int.tryParse(checkInParts[1]) ?? 0;
      
      // Create DateTime objects for today
      final now = DateTime.now();
      final shiftStartDateTime = DateTime(now.year, now.month, now.day, shiftStart.hour, shiftStart.minute, 0);
      final shiftStartWithGrace = shiftStartDateTime.add(const Duration(minutes: 5)); // 5 minutes grace period
      final checkInDateTime = DateTime(now.year, now.month, now.day, checkInHour, checkInMinute, 0);
      
      // Check if this is Open Shift
      final isOpenShift = shiftGroup.toLowerCase().contains('open');
      
      // Calculate if actually late - Open Shift employees are never late
      final isActuallyLate = !isOpenShift &&
          checkInDateTime.isAfter(shiftStartWithGrace);
      
      if (isActuallyLate) {
        lateRecords.add(r);
      } else {
        nonLateRecords.add(r);
      }
      
      // Debug logging
      debugPrint('''
LATE CHECK-IN CALCULATION DEBUG:
empid: ${r.empid}
name: ${r.name}
shiftGroup: $shiftGroup
isOpenShift: $isOpenShift
shiftStartTime: ${shiftStart.hour.toString().padLeft(2, '0')}:${shiftStart.minute.toString().padLeft(2, '0')}
checkInTime: ${r.checkIn}
graceDeadline: ${shiftStartWithGrace.toIso8601String()}
frontendCalculatedLate: $isActuallyLate
backendLateValue: ${r.late}
displayReason: ${isOpenShift ? 'Open Shift - never late' : (isActuallyLate ? 'Frontend DateTime calculation' : 'Not late')}
''');
    }
    
    return lateRecords.length;
  }
  int get earlyCheckOutCount  => _records.where((r) => r.early).length;
  int get waitingApprovalCount => _pendingApprovalsCount;
  int get fieldAttendanceCount =>
      _records.where((r) => _isStatus(r, 'fieldattendance')).length;

  // ── build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: _isLoading
          ? _loader()
          : _error != null
              ? _errorView()
              : FadeTransition(
                  opacity: _fade,
                  child: RefreshIndicator(
                    color: _C.lv500,
                    backgroundColor: _C.white,
                    onRefresh: _fetchAll,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _header()),
                        SliverToBoxAdapter(child: _heroBanner()),
                        SliverToBoxAdapter(child: _checkActions()),
                        SliverToBoxAdapter(child: _sectionLabel('Attendance Status')),
                        SliverToBoxAdapter(child: _statusRow()),
                        SliverToBoxAdapter(child: _sectionLabel('Activity Overview')),
                        SliverToBoxAdapter(child: _activityGrid()),
                        const SliverToBoxAdapter(child: SizedBox(height: 36)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(
      color: _C.lv500,
      strokeWidth: 3,
    ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off_rounded, size: 48, color: _C.red.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: _C.muted, fontSize: 14)),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _fetchAll,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Retry'),
          style: FilledButton.styleFrom(backgroundColor: _C.lv500,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    ),
  );

  // ════════════════════════════════════════════════════════════════════════
  //  HEADER
  // ════════════════════════════════════════════════════════════════════════
  Widget _header() {
    final date = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());
    return Container(
      color: _C.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(width: 7, height: 7,
                            decoration: const BoxDecoration(
                              color: _C.green, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('Live  ·  $date',
                              style: const TextStyle(color: _C.muted,
                                  fontSize: 11, fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2)),
                        ]),
                        const SizedBox(height: 4),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w800,
                              letterSpacing: -0.5, height: 1.15,
                            ),
                            children: [
                              TextSpan(text: 'Attendance\n', style: TextStyle(color: _C.ink)),
                              TextSpan(text: 'Dashboard', style: TextStyle(color: _C.lv500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Employee list pill
                  GestureDetector(
                    onTap: _showCheckedInEmployeesPopup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _C.lv100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.lv200),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.people_alt_rounded, color: _C.lv600, size: 16),
                        const SizedBox(width: 6),
                        const Text('Employees',
                            style: TextStyle(color: _C.lv600, fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Company banner
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _C.lv50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.lv200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _C.lv200,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.domain_rounded, color: _C.lv700, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.companyProfile.name,
                          style: const TextStyle(color: _C.ink, fontSize: 13,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                      Text(widget.companyProfile.adminName,
                          style: const TextStyle(color: _C.muted, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _C.border),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  HERO BANNER  (present/total + mini stats)
  // ════════════════════════════════════════════════════════════════════════
  Widget _heroBanner() {
    final total = _records.length;
    final pct   = total == 0 ? 0.0 : (presentCount / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF9C7CF2),  // lighter start
              Color(0xFF7E57C2),  // medium
              Color(0xFF5E35B1),  // darker end
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: _C.lv500.withOpacity(0.38),
                blurRadius: 22, offset: const Offset(0, 9)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Today's Overview",
                    style: TextStyle(color: Colors.white.withOpacity(0.75),
                        fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$presentCount',
                      style: const TextStyle(color: Colors.white, fontSize: 40,
                          fontWeight: FontWeight.w900, height: 1)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 4),
                    child: Text('/ $total',
                        style: TextStyle(color: Colors.white.withOpacity(0.55),
                            fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ]),
                Text('Employees present',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 5),
                Text('${(pct * 100).toStringAsFixed(0)}% attendance rate',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 14),
            // Right mini stats
            Column(children: [
              _miniBadge('$absentCount',   'Absent'),
              const SizedBox(height: 10),
              _miniBadge('$onLeaveCount',  'On Leave'),
              const SizedBox(height: 10),
              _miniBadge('$halfDayCount',  'Half Day'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String val, String lbl) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.13),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.18)),
    ),
    child: Column(children: [
      Text(val, style: const TextStyle(color: Colors.white,
          fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 1),
      Text(lbl, style: TextStyle(color: Colors.white.withOpacity(0.7),
          fontSize: 10, fontWeight: FontWeight.w500)),
    ]),
  );

  // ════════════════════════════════════════════════════════════════════════
  //  CHECK IN / OUT CARDS
  // ════════════════════════════════════════════════════════════════════════
  Widget _checkActions() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Row(children: [
      Expanded(child: _checkCard(
        count: checkInCount, label: 'Checked In', icon: Icons.login_rounded,
        accent: _C.green,
        onTap: () => _showEmployeePopup('Checked-in Employees',
            _records.where((r) => r.checkIn != null).toList()),
      )),
      const SizedBox(width: 12),
      Expanded(child: _checkCard(
        count: checkOutCount, label: 'Checked Out', icon: Icons.logout_rounded,
        accent: _C.lv500,
        onTap: () => _showEmployeePopup('Checked-out Employees',
            _records.where((r) => r.checkOut != null).toList()),
      )),
    ]),
  );

  Widget _checkCard({required int count, required String label,
      required IconData icon, required Color accent, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
            boxShadow: [BoxShadow(color: accent.withOpacity(0.11),
                blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$count', style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.w800, color: accent, height: 1)),
              const SizedBox(height: 3),
              Text(label, style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w600, color: _C.ink)),
              Text('today', style: const TextStyle(fontSize: 11, color: _C.muted)),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _C.muted),
          ]),
        ),
      );

  // ════════════════════════════════════════════════════════════════════════
  //  SECTION LABEL
  // ════════════════════════════════════════════════════════════════════════
  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Text(t, style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w700, color: _C.ink, letterSpacing: 0.1)),
  );

  // ════════════════════════════════════════════════════════════════════════
  //  STATUS ROW
  // ════════════════════════════════════════════════════════════════════════
  Widget _statusRow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(children: [
      Expanded(child: _statusTile('Present', presentCount, _C.green,
          Icons.check_circle_rounded,
          _records.where((r) => _isStatus(r,'present') ||
              r.status.toLowerCase().contains('half')).toList())),
      const SizedBox(width: 10),
      Expanded(child: _statusTile('Absent', absentCount, _C.red,
          Icons.cancel_rounded,
          _records.where((r) => _isStatus(r,'absent')).toList())),
      const SizedBox(width: 10),
      Expanded(child: _statusTile('On Leave', onLeaveCount, _C.amber,
          Icons.beach_access_rounded,
          _records.where((r) => _isStatus(r,'leave')).toList())),
    ]),
  );

  Widget _statusTile(String lbl, int n, Color c, IconData icon,
      List<AttendanceRecord> list) =>
      GestureDetector(
        onTap: () => _showEmployeePopup('$lbl Employees', list),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$n', style: TextStyle(fontSize: 28,
                  fontWeight: FontWeight.w700, color: c, height: 1)),
              const SizedBox(height: 8),
              Text(lbl, style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: c),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  // ════════════════════════════════════════════════════════════════════════
  //  ACTIVITY GRID
  // ════════════════════════════════════════════════════════════════════════
  Widget _activityGrid() {
    // Calculate corrected late records
    final correctedLateRecords = <AttendanceRecord>[];
    for (final r in _records) {
      if (r.checkIn == null || r.checkIn!.isEmpty) continue;
      
      final shiftMeta = _metaById[r.empid];
      final shiftGroup = shiftMeta?.shiftGroup?.trim() ?? '';
      final shiftStart = _shiftStartByName[shiftGroup];
      
      if (shiftStart == null) continue;
      
      final checkInParts = r.checkIn!.split(':');
      if (checkInParts.length < 2) continue;
      
      final checkInHour = int.tryParse(checkInParts[0]) ?? 0;
      final checkInMinute = int.tryParse(checkInParts[1]) ?? 0;
      
      final now = DateTime.now();
      final shiftStartDateTime = DateTime(now.year, now.month, now.day, shiftStart.hour, shiftStart.minute, 0);
      final shiftStartWithGrace = shiftStartDateTime.add(const Duration(minutes: 5));
      final checkInDateTime = DateTime(now.year, now.month, now.day, checkInHour, checkInMinute, 0);
      
      // Check if this is Open Shift
      final isOpenShift = shiftGroup.toLowerCase().contains('open');
      
      // Calculate if actually late - Open Shift employees are never late
      final isActuallyLate = !isOpenShift &&
          checkInDateTime.isAfter(shiftStartWithGrace);
      
      if (isActuallyLate) {
        correctedLateRecords.add(r);
      }
    }
    
    final items = [
      _AItem('Half Day',          halfDayCount,       halfDayRecords,
          Icons.hourglass_top_rounded,     _C.lv500,  null),
      _AItem('Late Check-in',     lateCheckInCount,   correctedLateRecords,
          Icons.schedule_rounded,          _C.amber,  null),
      _AItem('Early Check-out',   earlyCheckOutCount, _records.where((r) => r.early).toList(),
          Icons.exit_to_app_rounded,       _C.red,    null),
      _AItem('Waiting for\nApprovals', waitingApprovalCount, const [],
          Icons.pending_actions_rounded,   _C.blue,   _showPendingApprovalsPopup),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12,
          mainAxisSpacing: 12, childAspectRatio: 1.28,
        ),
        itemBuilder: (_, i) => _aCard(items[i]),
      ),
    );
  }

  Widget _aCard(_AItem it) => GestureDetector(
    onTap: it.onTap ?? () => _showEmployeePopup(it.title.replaceAll('\n', ' '), it.list),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(), // Empty space at top
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _C.ink, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('tap to view',
                  style: const TextStyle(fontSize: 10, color: _C.muted)),
            ],
          ),
          Text('${it.count}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                  color: it.color, height: 1)),
        ],
      ),
    ),
  );

  // ════════════════════════════════════════════════════════════════════════
  //  BOTTOM SHEET HELPER
  // ════════════════════════════════════════════════════════════════════════
  void _sheet({required String title, required int count,
      required IconData icon, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: _C.lv200,
                    borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _C.lv100,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: _C.lv600, size: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700, color: _C.ink))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _C.lv100,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('$count', style: const TextStyle(color: _C.lv600,
                      fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),
            ),
            const Divider(height: 1, color: _C.border),
            Expanded(child: SingleChildScrollView(controller: sc, child: child)),
          ]),
        ),
      ),
    );
  }

  // ── employee list tile ─────────────────────────────────────────────────
  Widget _empRow({required String name, required String sub,
      required Widget trail, String? extra, required VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border),
          ),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: _C.lv100, radius: 20,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: _C.lv600,
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 13, color: _C.ink)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 11, color: _C.muted)),
              if (extra != null && extra.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Shift: $extra',
                    style: const TextStyle(fontSize: 11, color: _C.muted)),
              ],
            ])),
            trail,
          ]),
        ),
      );

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
  );

  Widget _emptyState(String msg, IconData ic, Color c) => SizedBox(height: 180,
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(ic, size: 40, color: c.withOpacity(0.35)),
      const SizedBox(height: 10),
      Text(msg, style: const TextStyle(color: _C.muted, fontSize: 13)),
    ])),
  );

  Color _statusColor(String s) {
    final l = s.toLowerCase();
    if (l == 'present') return _C.green;
    if (l == 'absent')  return _C.red;
    if (l == 'leave')   return _C.amber;
    if (l.contains('half')) return _C.lv500;
    return _C.muted;
  }

  // ════════════════════════════════════════════════════════════════════════
  //  POPUP METHODS — same logic, new visual
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _showCheckedInEmployeesPopup() async {
    final todayYmd = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final checkedIn = _records.where((r) => r.checkIn != null).toList();
    if (checkedIn.isEmpty) { _showSimpleInfo('No one has checked-in today.'); return; }
    if (_metaById.isEmpty) { await _fetchEmployeesMeta(); if (!mounted) return; }

    final rows = checkedIn.map((r) {
      final m = _metaById[r.empid];
      return _CheckedInRow(empid: r.empid, name: r.name, date: todayYmd,
          checkIn: r.checkIn!, dept: m?.dept, shiftGroup: m?.shiftGroup);
    }).toList();

    _sheet(
      title: 'Employee List', count: rows.length, icon: Icons.people_alt_rounded,
      child: ListView.separated(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final e = rows[i];
          return _empRow(
            name: e.name, sub: '${e.empid}  ·  ${e.dept ?? '-'}',
            trail: _badge(e.checkIn, _C.green), extra: e.shiftGroup,
            onTap: () {
              AttendanceRecord? rec;
              for (final r in _records) { if (r.empid == e.empid) { rec = r; break; } }
              final detail = <String, dynamic>{
                'id': e.empid, 'name': e.name, 'date': e.date,
                'checkIn': e.checkIn, 'checkOut': rec?.checkOut,
                'department': e.dept ?? '-', 'shift': e.shiftGroup ?? '-',
                'location': '-', 'latitude': null, 'longitude': null,
                'status': rec?.status ?? '-', 'geofence': '-',
              };
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => EmployeeDetailPage(employee: detail),
                    settings: const RouteSettings(name: 'EmployeeDetailPage')),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPendingApprovalsPopup() async {
    try {
      final pendings = await ApiService.fetchApprovals(type: 'All', status: 'Pending');
      _sheet(
        title: 'Waiting for Approvals', count: pendings.length,
        icon: Icons.pending_actions_rounded,
        child: pendings.isEmpty
            ? _emptyState('No pending approvals', Icons.check_circle_outline_rounded, _C.green)
            : ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: pendings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = pendings[i];
                  return _empRow(
                    name: (item['name'] ?? '-').toString(),
                    sub: 'ID: ${item['empid'] ?? '-'}',
                    trail: _badge('Pending', _C.amber),
                    onTap: null,
                  );
                },
              ),
      );
    } catch (e) { _showSimpleInfo('Failed to load: $e'); }
  }

  void _showEmployeePopup(String title, List<AttendanceRecord> list) {
    _sheet(
      title: title, count: list.length, icon: Icons.group_rounded,
      child: list.isEmpty
          ? _emptyState('No employees found', Icons.person_off_outlined, _C.muted)
          : ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final r = list[i];
                return _empRow(
                  name: r.name, sub: 'ID: ${r.empid}',
                  trail: _badge(r.status, _statusColor(r.status)),
                  onTap: () {
                    final detail = <String, dynamic>{
                      'id': r.empid, 'name': r.name,
                      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      'checkIn': r.checkIn ?? '-', 'checkOut': r.checkOut,
                      'department': '-', 'shift': '-',
                      'location': '-', 'latitude': null, 'longitude': null,
                      'status': r.status, 'geofence': '-',
                    };
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          builder: (_) => EmployeeDetailPage(employee: detail)),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showSimpleInfo(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Info', style: TextStyle(color: _C.ink, fontWeight: FontWeight.w700)),
        content: Text(msg, style: const TextStyle(color: _C.muted)),
        actions: [TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK', style: TextStyle(color: _C.lv500, fontWeight: FontWeight.w600)),
        )],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  LOGIC HELPERS — untouched
  // ════════════════════════════════════════════════════════════════════════
  bool _isHalfByLateCheckIn(AttendanceRecord r) {
    if (r.checkIn == null || r.checkIn!.isEmpty) return false;
    final shiftName = _metaById[r.empid]?.shiftGroup?.trim();
    if (shiftName == null || shiftName.isEmpty) return false;
    
    // Check if this is Open Shift
    final isOpenShift = shiftName.toLowerCase().contains('open');
    debugPrint('FRONTEND HALF-DAY DEBUG: empid=${r.empid} shiftName=$shiftName isOpenShift=$isOpenShift');
    
    // For Open Shift, don't calculate half-day based on late check-in
    if (isOpenShift) {
      debugPrint('FRONTEND HALF-DAY: empid=${r.empid} Open Shift - skipping late check-in half-day calculation');
      return false;
    }
    
    // Fixed Shift: Apply existing logic
    final startTod = _shiftStartByName[shiftName];
    if (startTod == null) return false;
    final now = DateTime.now();
    final startDT = DateTime(now.year, now.month, now.day, startTod.hour, startTod.minute);
    final parts = r.checkIn!.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    final inDT = DateTime(now.year, now.month, now.day, h, m, s);
    final diff = inDT.difference(startDT).inMinutes;
    debugPrint('FRONTEND HALF-DAY: empid=${r.empid} Fixed Shift diffMin=$diff');
    return diff >= 240;
  }

  TimeOfDay? _parseHHmm(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (m == null) return null;
    final hh = int.tryParse(m.group(1)!); final mm = int.tryParse(m.group(2)!);
    if (hh == null || mm == null) return null;
    if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
    return TimeOfDay(hour: hh, minute: mm);
  }

  (TimeOfDay?, TimeOfDay?)? _parseNameRange(String s) {
    final m = RegExp(
      r'(\d{1,2})(?:[:\.](\d{1,2}))?\s*(AM|PM)\s*-\s*(\d{1,2})(?:[:\.](\d{1,2}))?\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(s);
    if (m == null) return null;
    int h1 = int.parse(m.group(1)!); int m1 = int.tryParse(m.group(2) ?? '0') ?? 0;
    final p1 = (m.group(3) ?? '').toUpperCase();
    int h2 = int.parse(m.group(4)!); int m2 = int.tryParse(m.group(5) ?? '0') ?? 0;
    final p2 = (m.group(6) ?? '').toUpperCase();
    return (TimeOfDay(hour: _to24h(h1, p1), minute: m1),
            TimeOfDay(hour: _to24h(h2, p2), minute: m2));
  }

  int _to24h(int h, String period) { int hh = h % 12; if (period == 'PM') hh += 12; return hh; }
}

String _safe(String? s) => s ?? '';
