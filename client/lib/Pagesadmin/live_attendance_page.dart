import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'company_setup_page.dart';
// ✅ Use a single, unambiguous import that exposes the class symbol:
import 'employee_detail_page.dart' show EmployeeDetailPage;

import 'package:serv_app/models/company_data.dart';

// 🔹 use the same API helper as approvals screen
import '../services/api_service.dart';

const String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

/// Record returned by /api/attendance/live
class AttendanceRecord {
  final String empid;
  final String name;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final bool late;
  final bool early;
  final int permissionCount;

  AttendanceRecord({
    required this.empid,
    required this.name,
    required this.status,
    this.checkIn,
    this.checkOut,
    required this.late,
    required this.early,
    required this.permissionCount,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      empid: json['empid'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
      late: (json['late'] as bool?) ?? false,
      early: (json['early'] as bool?) ?? false,
      permissionCount: (json['permissionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Minimal employee info (from employees DB) used to enrich the list
class _EmployeeMeta {
  final String empid;
  final String? dept;
  final String? shiftGroup;

  _EmployeeMeta({required this.empid, this.dept, this.shiftGroup});

  factory _EmployeeMeta.fromJson(Map<String, dynamic> j) {
    return _EmployeeMeta(
      empid: (j['empid'] ?? '').toString(),
      dept: j['dept']?.toString(),
      shiftGroup: j['shiftGroup']?.toString(),
    );
  }
}

/// Row shown in the Employee List popup (attendance + employee meta joined)
class _CheckedInRow {
  final String empid;
  final String name;
  final String date; // yyyy-MM-dd
  final String checkIn; // as returned by attendance
  final String? dept;
  final String? shiftGroup;

  _CheckedInRow({
    required this.empid,
    required this.name,
    required this.date,
    required this.checkIn,
    this.dept,
    this.shiftGroup,
  });
}

class LiveAttendancePage extends StatefulWidget {
  final CompanyProfile companyProfile;

  const LiveAttendancePage({super.key, required this.companyProfile});

  @override
  _LiveAttendancePageState createState() => _LiveAttendancePageState();
}

class _LiveAttendancePageState extends State<LiveAttendancePage> {
  bool _isLoading = true;
  String? _error;
  List<AttendanceRecord> _records = [];

  // pending approvals count shown in "Waiting for Approvals"
  int _pendingApprovalsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _fetchLiveAttendance(),
        _fetchPendingApprovalsCount(), // ← same source as approvals screen
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLiveAttendance() async {
    final url = Uri.parse('$_apiBase/attendance/live');
    try {
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_safe(CompanyData.token)}',
        },
      );
      if (resp.statusCode != 200) {
        setState(() => _error = 'Error ${resp.statusCode}: ${resp.body}');
        return;
      }
      final List<dynamic> jsonList = jsonDecode(resp.body);
      final records = jsonList
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _records = records);
    } catch (e) {
      setState(() => _error = 'Failed to load: $e');
    }
  }

  /// ✅ Use the SAME service as LeaveApprovalsScreen so counts match exactly
  Future<void> _fetchPendingApprovalsCount() async {
    try {
      final list = await ApiService.fetchApprovals(
        type: 'All',
        status: 'Pending',
      );
      if (!mounted) return;
      setState(() => _pendingApprovalsCount = list.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingApprovalsCount = 0);
    }
  }

  // counts for tiles
  bool _isStatus(AttendanceRecord r, String s) =>
      r.status.toLowerCase() == s.toLowerCase();

  int get presentCount => _records.where((r) => _isStatus(r, 'present')).length;
  int get absentCount => _records.where((r) => _isStatus(r, 'absent')).length;
  int get onLeaveCount => _records.where((r) => _isStatus(r, 'leave')).length;
  int get checkInCount => _records.where((r) => r.checkIn != null).length;
  int get checkOutCount => _records.where((r) => r.checkOut != null).length;
  int get halfDayCount =>
      _records.where((r) => r.checkIn != null && r.checkOut == null).length;
  int get lateCheckInCount => _records.where((r) => r.late).length;
  int get earlyCheckOutCount => _records.where((r) => r.early).length;
  int get waitingApprovalCount => _pendingApprovalsCount;
  int get fieldAttendanceCount =>
      _records.where((r) => _isStatus(r, 'fieldattendance')).length;

  // ——— employee list popup (today’s check-ins with dept/shift) ———

  Future<void> _showCheckedInEmployeesPopup() async {
    final todayYmd = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final checkedIn = _records.where((r) => r.checkIn != null).toList();

    if (checkedIn.isEmpty) {
      _showSimpleInfo('No one has checked-in today.');
      return;
    }

    Map<String, _EmployeeMeta> metaById = {};
    try {
      final uri = Uri.parse('$_apiBase/employees');
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_safe(CompanyData.token)}',
        },
      );
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body) as List;
        for (final e in data) {
          if (e is Map<String, dynamic>) {
            final m = _EmployeeMeta.fromJson(e);
            if (m.empid.isNotEmpty) metaById[m.empid] = m;
          }
        }
      }
    } catch (_) {
      // ignore; dept/shift will be shown as '-'
    }

    final rows = <_CheckedInRow>[];
    for (final r in checkedIn) {
      final m = metaById[r.empid];
      rows.add(_CheckedInRow(
        empid: r.empid,
        name: r.name,
        date: todayYmd,
        checkIn: r.checkIn!,
        dept: m?.dept,
        shiftGroup: m?.shiftGroup,
      ));
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF3E5F5),
        title: const Text(
          'Employee List',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (ctx, i) {
              final e = rows[i];

              final card = Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.15),
                      spreadRadius: 1.5,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "ID: ${e.empid} | Date: ${e.date}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Divider(),
                    Text("Check-in: ${e.checkIn}",
                        style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text("Department: ${e.dept ?? '-'}",
                        style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text("Shift: ${e.shiftGroup ?? '-'}",
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              );

              return InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  AttendanceRecord? rec;
                  for (final r in _records) {
                    if (r.empid == e.empid) {
                      rec = r;
                      break;
                    }
                  }

                  final detail = <String, dynamic>{
                    'id': e.empid,
                    'name': e.name,
                    'date': e.date,
                    'checkIn': e.checkIn,
                    'checkOut': rec?.checkOut,
                    'department': e.dept ?? '-',
                    'shift': e.shiftGroup ?? '-',
                    'location': '-',
                    'latitude': null,
                    'longitude': null,
                    'status': rec?.status ?? '-',
                    'geofence': '-',
                  };

                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => EmployeeDetailPage(employee: detail),
                      settings: const RouteSettings(name: 'EmployeeDetailPage'),
                    ),
                  );
                },
                child: card,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Close", style: TextStyle(color: Color(0xFF6A1B9A))),
          ),
        ],
      ),
    );
  }

  /// NEW: exact popup for “Waiting for Approvals”
  Future<void> _showPendingApprovalsPopup() async {
    try {
      final pendings = await ApiService.fetchApprovals(
        type: 'All',
        status: 'Pending',
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFF3E5F5),
          title: const Text(
            'Waiting for Approvals',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A1B9A),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 360,
            child: pendings.isEmpty
                ? const Center(child: Text('No pending requests'))
                : ListView.builder(
                    itemCount: pendings.length,
                    itemBuilder: (_, i) {
                      final item = pendings[i];
                      final name = (item['name'] ?? '').toString();
                      final empid = (item['empid'] ?? '').toString();
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFCE93D8),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          name.isEmpty ? '-' : name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'ID: ${empid.isEmpty ? '-' : empid}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Close', style: TextStyle(color: Color(0xFF6A1B9A))),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSimpleInfo('Failed to load pending approvals: $e');
    }
  }

  void _showSimpleInfo(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Info'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildDateRow(currentDate),
                        const SizedBox(height: 12),
                        _buildCheckButtons(),
                        const SizedBox(height: 12),
                        _buildStatusBoxes(),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            "Activity",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildActivityGrid(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF8C6EAF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Live Attendance",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.companyProfile.name,
              style: const TextStyle(color: Colors.white)),
          Text("ID | ${widget.companyProfile.adminName}",
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const _HeaderIcon(
                  label: 'Map', icon: Icons.map, color: Colors.green),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _showCheckedInEmployeesPopup,
                child: const _HeaderIcon(
                  label: 'Employee List',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String currentDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text("Today - $currentDate",
          style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCheckButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => _showEmployeePopup(
              "Checked-in Employees",
              _records.where((r) => r.checkIn != null).toList(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF655193),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text("Check-in $checkInCount",
                style: const TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => _showEmployeePopup(
              "Checked-out Employees",
              _records.where((r) => r.checkOut != null).toList(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF655193),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text("Check-out $checkOutCount",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBoxes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statusBox(
            "Present",
            presentCount,
            Colors.green,
            _records.where((r) => _isStatus(r, 'present')).toList(),
          ),
          _statusBox(
            "Absent",
            absentCount,
            Colors.red,
            _records.where((r) => _isStatus(r, 'absent')).toList(),
          ),
          _statusBox(
            "On Leave",
            onLeaveCount,
            Colors.orange,
            _records.where((r) => _isStatus(r, 'leave')).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _activityCard(
            "Half Day",
            halfDayCount,
            _records
                .where((r) => r.checkIn != null && r.checkOut == null)
                .toList(),
          ),
          _activityCard(
            "Late Check-in",
            lateCheckInCount,
            _records.where((r) => r.late).toList(),
          ),
          _activityCard(
            "Early Check-out",
            earlyCheckOutCount,
            _records.where((r) => r.early).toList(),
          ),
          _activityCard(
            "Waiting for Approvals",
            waitingApprovalCount,
            const <AttendanceRecord>[],
            fontSize: 10,
            onTap: _showPendingApprovalsPopup,
          ),
          _activityCard(
            "Field Attendance",
            fieldAttendanceCount,
            _records.where((r) => _isStatus(r, 'fieldattendance')).toList(),
          ),
        ],
      ),
    );
  }

  void _showEmployeePopup(String title, List<AttendanceRecord> list) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF3E5F5),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final r = list[i];
              return ListTile(
                onTap: () {
                  final detail = <String, dynamic>{
                    'id': r.empid,
                    'name': r.name,
                    'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'checkIn': r.checkIn ?? '-',
                    'checkOut': r.checkOut,
                    'department': '-', // unknown here
                    'shift': '-',       // unknown here
                    'location': '-',
                    'latitude': null,
                    'longitude': null,
                    'status': r.status,
                    'geofence': '-',
                  };
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => EmployeeDetailPage(employee: detail),
                    ),
                  );
                },
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFCE93D8),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(r.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("ID: ${r.empid}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Close", style: TextStyle(color: Color(0xFF6A1B9A))),
          ),
        ],
      ),
    );
  }

  Widget _statusBox(
    String title,
    int count,
    Color color,
    List<AttendanceRecord> list,
  ) =>
      Expanded(
        child: GestureDetector(
          onTap: () => _showEmployeePopup("$title Employees", list),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );

  Widget _activityCard(
    String title,
    int value,
    List<AttendanceRecord> list, {
    double fontSize = 12,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap ?? () => _showEmployeePopup(title, list),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD1C4E9).withOpacity(0.1),
            border: Border.all(color: const Color(0xFF8C6EAF).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("$value",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                title,
                style:
                    TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

String _safe(String? s) => s ?? '';

class _HeaderIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _HeaderIcon(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}