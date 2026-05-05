import 'dart:convert';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:serv_app/features/users/attendance_model_page.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:serv_app/features/users/my_attendance_detail_page.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/utils/performance_logger.dart';

// ================= THEME =================
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

const Color kPresentColor = Color.fromARGB(255, 173, 235, 148);
const Color kAbsentColor = Color.fromARGB(255, 236, 148, 142);
const Color kLeaveColor = Colors.orange;
const Color kHolidayColor = Colors.blue;
const Color kWeekOffColor = Colors.purple;
const Color kHalfDayColor = Color.fromARGB(169, 220, 233, 30);

// ============== WIDGET CLASSES =================
class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        LegendCircle(color: kPresentColor, label: "Present"),
        LegendCircle(color: kAbsentColor, label: "Absent"),
        LegendCircle(color: kLeaveColor, label: "Leave"),
        LegendCircle(color: kHolidayColor, label: "Holiday"),
        LegendCircle(color: kWeekOffColor, label: "Week Off"),
        LegendCircle(color: kHalfDayColor, label: "Half Day"),
      ],
    );
  }
}

class LegendCircle extends StatelessWidget {
  final Color color;
  final String label;

  const LegendCircle({required this.color, required this.label, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class TotalDaysCard extends StatelessWidget {
  final int totalDays;
  final int remainingDays;

  const TotalDaysCard({
    Key? key,
    required this.totalDays,
    required this.remainingDays,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat('d MMMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: kPrimaryBackgroundBottom,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_month, size: 40, color: kAppBarColor),
          const SizedBox(height: 10),
          Text(
            "Today: $todayFormatted",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Remaining: $remainingDays Days",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatusCard(this.label, this.value, this.color, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class BottomStatBox extends StatelessWidget {
  final String title;
  final String count;

  const BottomStatBox(this.title, this.count, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kAppBarColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============== API BASE =================
final String apiBase = ApiService.baseUrl;

// ====== helpers ======
bool _looksLikeJwt(String v) =>
    RegExp(r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$').hasMatch(v);

// ============== PAGE =====================
class MyAttendancePage extends StatefulWidget {
  final AttendanceData? data;

  const MyAttendancePage({super.key, this.data});

  @override
  State<MyAttendancePage> createState() => _MyAttendancePageState();
}

class _MyAttendancePageState extends State<MyAttendancePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String? _empid;
  String? _token;
  Map<String, String> _dayStatusByDate = {};

  int _present = 0;
  int _absent = 0;
  int _leave = 0;
  int _late = 0;
  int _early = 0;
  int _permission = 0;

  AttendanceData get _fallbackData => widget.data ??
      AttendanceData(
        totalDays: 0,
        presentCount: 0,
        absentCount: 0,
        leaveCount: 0,
        lateCheckIn: 0,
        earlyCheckOut: 0,
        permissionCount: 0,
        presentDates: const [],
        absentDates: const [],
      );

  @override
  void initState() {
    super.initState();
    _token = _getToken();
    _persistTokenIfPresent();
    _bootstrap().then((_) => _loadMonth(_focusedDay));
  }

  /// Copy token from in-memory CompanyData to localStorage if present.
  void _persistTokenIfPresent() {
    try {
      final t = CompanyData.token;
      if (t != null && t.isNotEmpty) {
        html.window.localStorage['token'] = t;
        html.window.localStorage['jwt'] = t;
      }
    } catch (_) {}
  }

  Future<void> _bootstrap() async {
    _empid = _tryEmpIdFromModel(widget.data) ??
        _tryEmpIdFromLocalStorage() ??
        await _fetchEmpIdFromAuthMe();
  }

  String? _tryEmpIdFromModel(AttendanceData? d) {
    if (d == null) return null;
    try {
      final dyn = d as dynamic;
      final v = (dyn.empId ?? dyn.empid)?.toString();
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  String? _tryEmpIdFromLocalStorage() {
    debugPrint('[MyAttendance] Checking localStorage for employee ID...');
    
    // Get all localStorage keys for debugging
    final allKeys = html.window.localStorage.keys.toList();
    debugPrint('[MyAttendance] Available localStorage keys: $allKeys');
    
    // Check 'me' object first
    final meRaw = html.window.localStorage['me'];
    if (meRaw != null && meRaw.isNotEmpty) {
      try {
        final me = jsonDecode(meRaw);
        if (me is Map) {
          debugPrint('[MyAttendance] Found me object with keys: ${me.keys.toList()}');
          
          // Check direct fields in 'me'
          final directKeys = ['empid', 'empId', 'employeeId', 'employee_id', 'id'];
          for (final key in directKeys) {
            if (me[key] != null && me[key].toString().isNotEmpty) {
              debugPrint('[MyAttendance] Found employee ID in me.$key: ${me[key]}');
              return me[key].toString();
            }
          }
          
          // Check nested employeeProfile
          final ep = me['employeeProfile'];
          if (ep is Map) {
            debugPrint('[MyAttendance] Found employeeProfile with keys: ${ep.keys.toList()}');
            for (final key in directKeys) {
              if (ep[key] != null && ep[key].toString().isNotEmpty) {
                debugPrint('[MyAttendance] Found employee ID in employeeProfile.$key: ${ep[key]}');
                return ep[key].toString();
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[MyAttendance] Error parsing me object: $e');
      }
    }

    // Check direct localStorage keys
    const keys = ['empid', 'empId', 'employeeId', 'employee_id', 'id', 'userId', 'user_id'];
    for (final k in keys) {
      final v = html.window.localStorage[k];
      if (v != null && v.isNotEmpty) {
        debugPrint('[MyAttendance] Found employee ID in localStorage key $k: $v');
        return v;
      }
    }

    debugPrint('[MyAttendance] No employee ID found in localStorage');
    return null;
  }

  Future<String?> _fetchEmpIdFromAuthMe() async {
    final startTime = DateTime.now();
    final token = _token;
    if (token == null || token.isEmpty) return null;

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/auth/me');
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'MyAttendancePage',
        endpoint: '/auth/me',
        startTime: startTime,
        endTime: endTime,
        statusCode: resp.statusCode,
        itemCount: resp.statusCode == 200 ? 1 : 0,
      );

      if (resp.statusCode == 200) {
        final me = jsonDecode(resp.body);
        html.window.localStorage['me'] = jsonEncode(me);

        final ep = me['employeeProfile'];
        if ((me['empid'] ?? '').toString().isNotEmpty) {
          return me['empid'].toString();
        }
        if (ep is Map && (ep['empid'] ?? '').toString().isNotEmpty) {
          return ep['empid'].toString();
        }
      }
    } catch (e) {
      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'MyAttendancePage',
        endpoint: '/auth/me',
        startTime: startTime,
        endTime: endTime,
        statusCode: 0,
        error: e.toString(),
      );
    }

    return null;
  }

  String? _getToken() {
    const keys = ['token', 'jwt', 'auth_token', 'access_token'];

    for (final k in keys) {
      final v = html.window.localStorage[k];
      if (v != null && v.isNotEmpty) return v;
    }

    try {
      for (final k in html.window.localStorage.keys) {
        final v = html.window.localStorage[k];
        if (v != null && _looksLikeJwt(v)) return v;
      }
    } catch (_) {}

    try {
      for (final k in html.window.sessionStorage.keys) {
        final v = html.window.sessionStorage[k];
        if (v != null && _looksLikeJwt(v)) return v;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _loadMonth(DateTime anchor) async {
    final startTime = DateTime.now();
    debugPrint('LOAD MONTH START');

    final fallback = _fallbackData;

    if (_empid == null || _empid!.isEmpty) {
      debugPrint('EmpId is null or empty');

      setState(() {
        _present = fallback.presentCount;
        _absent = fallback.absentCount;
        _leave = fallback.leaveCount;
        _late = fallback.lateCheckIn;
        _early = fallback.earlyCheckOut;
        _permission = fallback.permissionCount;
        _dayStatusByDate = {};
      });
      return;
    }

    final y = anchor.year;
    final m = anchor.month.toString().padLeft(2, '0');
    final token = _token;

    final uri =
        Uri.parse('${ApiService.baseUrl}/attendance/monthly/$_empid/$y/$m');

    debugPrint('EmpId: $_empid');
    debugPrint('Monthly URL: $uri');

    try {
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'MyAttendancePage',
        endpoint: '/attendance/monthly/$_empid/$y/$m',
        startTime: startTime,
        endTime: endTime,
        statusCode: resp.statusCode,
        itemCount: resp.statusCode == 200 ? (jsonDecode(resp.body) as List).length : 0,
      );

      debugPrint('Monthly API status code: ${resp.statusCode}');
      debugPrint('Monthly API body: ${resp.body}');

      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        debugPrint('[MyAttendance] Monthly API body: ${resp.body}');
        
        if (data.isNotEmpty) {
          debugPrint('[MyAttendance] First item keys: ${(data.first as Map).keys.toList()}');
        }

        Map<String, String> ds = {};

        int present = 0;
        int absent = 0;
        int leave = 0;
        int late = 0;
        int early = 0;
        int permission = 0;

        for (final item in data) {
          if (item is! Map) continue;
          
          final date = item['date']?.toString();
          final checkIn = item['checkIn']?.toString();
          final checkOut = item['checkOut']?.toString();
          final leaveStatus = item['leaveStatus']?.toString();

          if (date == null || date.isEmpty) continue;

          // Check for late check-in from API fields
          final isLateFromApi = (item['isLate'] as bool?) ?? 
                               (item['late'] as bool?) ??
                               (item['lateCheckIn'] as bool?) ??
                               (item['lateCheckin'] as bool?) ??
                               (item['status']?.toString().toLowerCase() == 'late check-in') ??
                               (item['attendanceStatus']?.toString().toLowerCase() == 'late check-in');

          // Time-based late calculation as fallback
          bool isLateFromTime = false;
          if (!isLateFromApi && checkIn != null && checkIn.isNotEmpty && checkIn != '-' && checkIn.toLowerCase() != 'null') {
            // Default shift start time (can be enhanced to fetch from shift settings)
            const shiftStart = '09:30'; // Default shift start time
            const graceMinutes = 0; // No grace time
            
            try {
              final checkInTime = DateFormat('HH:mm').parse(checkIn);
              final shiftStartTime = DateFormat('HH:mm').parse(shiftStart);
              
              final lateThreshold = shiftStartTime.add(Duration(minutes: graceMinutes));
              isLateFromTime = checkInTime.isAfter(lateThreshold);
              
              debugPrint('[MyAttendance] Time-based late check - checkIn: $checkIn, shiftStart: $shiftStart, lateThreshold: ${DateFormat('HH:mm').format(lateThreshold)}, isLate: $isLateFromTime');
            } catch (e) {
              debugPrint('[MyAttendance] Error parsing time for late calculation: $e');
              isLateFromTime = false;
            }
          }

          final isLate = isLateFromApi ?? isLateFromTime;

          // Check for early checkout
          final isEarly = (item['isEarly'] as bool?) ??
                         (item['early'] as bool?) ??
                         (item['earlyCheckOut'] as bool?) ??
                         (item['earlyCheckout'] as bool?) ??
                         (item['status']?.toString().toLowerCase() == 'early checkout') ??
                         (item['attendanceStatus']?.toString().toLowerCase() == 'early checkout') ??
                         false;

          // Check for permission
          final isPermission = (item['isPermission'] as bool?) ??
                              (item['permission'] as bool?) ??
                              (item['hasPermission'] as bool?) ??
                              (item['status']?.toString().toLowerCase() == 'permission') ??
                              (item['attendanceStatus']?.toString().toLowerCase() == 'permission') ??
                              false;

          // Count late, early, permission
          if (isLate) late++;
          if (isEarly) early++;
          if (isPermission) permission++;

          debugPrint('[MyAttendance] Processing $date - checkIn: $checkIn, isLateFromApi: $isLateFromApi, isLateFromTime: $isLateFromTime, final isLate: $isLate, isEarly: $isEarly, isPermission: $isPermission');

          // Priority Logic for calendar status
          if (leaveStatus != null &&
              leaveStatus.isNotEmpty &&
              leaveStatus.toLowerCase() == 'approved') {
            ds[date] = 'Leave';
            leave++;
          } else if (checkIn != null &&
              checkIn.isNotEmpty &&
              checkIn != '-' &&
              checkIn.toLowerCase() != 'null') {
            ds[date] = 'Present';
            present++;
          } else {
            ds[date] = 'Absent';
            absent++;
          }
        }

        debugPrint('[MyAttendance] Monthly counts - Present: $present, Absent: $absent, Leave: $leave');
        debugPrint('[MyAttendance] Late check-in count: $late');
        debugPrint('[MyAttendance] Early checkout count: $early');
        debugPrint('[MyAttendance] Permission count: $permission');
        debugPrint('[MyAttendance] Monthly statuses: $ds');

        setState(() {
          _dayStatusByDate = ds;

          _present = present;
          _absent = absent;
          _leave = leave;
          _late = late;
          _early = early;
          _permission = permission;
        });
      } else {
        setState(() {
          _present = fallback.presentCount;
          _absent = fallback.absentCount;
          _leave = fallback.leaveCount;
          _late = fallback.lateCheckIn;
          _early = fallback.earlyCheckOut;
          _permission = fallback.permissionCount;
        });
      }
    } catch (e) {
      final endTime = DateTime.now();
      PerformanceLogger.logApiCall(
        screen: 'MyAttendancePage',
        endpoint: '/attendance/monthly/$_empid/$y/$m',
        startTime: startTime,
        endTime: endTime,
        statusCode: 0,
        error: e.toString(),
      );
      debugPrint('LOAD MONTH ERROR: $e');

      setState(() {
        _present = fallback.presentCount;
        _absent = fallback.absentCount;
        _leave = fallback.leaveCount;
        _late = fallback.lateCheckIn;
        _early = fallback.earlyCheckOut;
        _permission = fallback.permissionCount;
      });
    }
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color? _colorForDay(DateTime day) {
    final rawStatus = _dayStatusByDate[_ymd(day)];
    final status = rawStatus?.trim().toLowerCase();

    final now = DateTime.now();
    final fallback = _fallbackData;

    if (day.isAfter(DateTime(now.year, now.month, now.day))) {
      if (day.weekday == DateTime.sunday) return kWeekOffColor;
      if (status == 'holiday') return kHolidayColor;
      return null;
    }

    switch (status) {
      case 'present':
        return kPresentColor;
      case 'absent':
        return kAbsentColor;
      case 'leave':
        return kLeaveColor;
      case 'holiday':
        return kHolidayColor;
      case 'weekoff':
      case 'week off':
        return kWeekOffColor;
      case 'halfday':
      case 'half day':
        return kHalfDayColor;
      default:
        if (fallback.presentDates.any((d) => isSameDay(d, day))) {
          return kPresentColor;
        }
        if (fallback.absentDates.any((d) => isSameDay(d, day))) {
          return kAbsentColor;
        }
        return null;
    }
  }

  void _openDetail(DateTime day) async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dayOnly = DateTime(day.year, day.month, day.day);

    if (dayOnly.isAfter(todayOnly)) return;

    if (_empid == null || _empid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load attendance details. Please log out and log in again.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyAttendanceDetailPage(
          empId: _empid!,
          date: day,
          baseUrl: apiBase,
          bearerToken: _getToken(),
        ),
      ),
    );

    _loadMonth(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final totalDays = _present + _absent + _leave;
    final totalDaysInMonth = DateUtils.getDaysInMonth(
      _focusedDay.year,
      _focusedDay.month,
    );

    final remainingDays =
        (today.year == _focusedDay.year && today.month == _focusedDay.month)
            ? (totalDaysInMonth - today.day)
            : (today.isBefore(DateTime(_focusedDay.year, _focusedDay.month))
                ? totalDaysInMonth
                : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: kAppBarColor,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TotalDaysCard(
                  totalDays: totalDays,
                  remainingDays: remainingDays,
                ),
                const SizedBox(height: 20),
                SizedBox(height: 400, child: _buildCalendar()),
                const SizedBox(height: 20),
                const Text(
                  "Legend",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const _LegendRow(),
                const SizedBox(height: 20),
                _buildStatusSummary(),
                const SizedBox(height: 20),
                _buildBottomStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: kPrimaryBackgroundTop,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TableCalendar(
        focusedDay: _focusedDay,
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        rowHeight: 44,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _openDetail(selectedDay);
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
          _loadMonth(focusedDay);
        },
        calendarStyle: const CalendarStyle(
          weekendTextStyle: TextStyle(color: Colors.red),
          outsideDaysVisible: false,
          isTodayHighlighted: false,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, _) =>
              _dayCell(day, color: _colorForDay(day)),
          selectedBuilder: (context, day, _) =>
              _dayCell(day, isSelected: true, color: _colorForDay(day)),
          todayBuilder: (context, day, _) =>
              _dayCell(day, isToday: true, color: _colorForDay(day)),
          outsideBuilder: (context, day, _) =>
              _dayCell(day, color: null, dim: true),
        ),
      ),
    );
  }

  Widget _dayCell(
    DateTime day, {
    Color? color,
    bool isSelected = false,
    bool isToday = false,
    bool dim = false,
  }) {
    final Color bg = (color != null)
        ? color
        : (isSelected
            ? kAppBarColor
            : (isToday ? kButtonColor : Colors.transparent));

    final hasBg = bg != Colors.transparent;
    final textColor = hasBg ? kTextColor : (dim ? Colors.grey : Colors.black87);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final double pad = 6;
        final double dia = (size - pad * 2).clamp(18.0, 999.0);

        return Center(
          child: Container(
            width: dia,
            height: dia,
            decoration: BoxDecoration(
              color: hasBg ? bg.withValues(alpha: 0.90) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: hasBg ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        StatusCard("Present", _present.toString(), kPresentColor),
        StatusCard("Absent", _absent.toString(), kAbsentColor),
        StatusCard("Leave", _leave.toString(), kLeaveColor),
      ],
    );
  }

  Widget _buildBottomStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          BottomStatBox("Late Check-in", _late.toString()),
          const SizedBox(width: 12),
          BottomStatBox("Early Check-out", _early.toString()),
          const SizedBox(width: 12),
          BottomStatBox("Permission Count", _permission.toString()),
        ],
      ),
    );
  }
}