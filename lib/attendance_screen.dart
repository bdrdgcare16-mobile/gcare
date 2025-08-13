import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'services/attendance_service.dart';
import 'providers/realtime_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isCheckedIn = false;
  DateTime? checkInTime;
  DateTime? checkOutTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeRealtime();
    _loadTodayAttendance();
  }

  Future<void> _initializeRealtime() async {
    final realtimeProvider = context.read<RealtimeProvider>();
    await realtimeProvider.initialize();
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final attendanceService = AttendanceService();
      final todayAttendance = await attendanceService.getTodayAttendance();
      
      setState(() {
        isCheckedIn = todayAttendance['hasCheckedIn'] ?? false;
        if (todayAttendance['checkInTime'] != null) {
          checkInTime = DateTime.parse(todayAttendance['checkInTime']);
        }
        if (todayAttendance['checkOutTime'] != null) {
          checkOutTime = DateTime.parse(todayAttendance['checkOutTime']);
        }
      });
    } catch (e) {
      print('Error loading today attendance: $e');
    }
  }

  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color accentColor = Color(0xFF00BFAE);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color cardColor = Colors.white;
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  // Example attendance summary
  int present = 18;
  int absent = 2;
  int late = 1;
  int halfDay = 1;

  // Example calendar data
  final Map<DateTime, String> attendanceMap = {
    DateTime(2024, 6, 1): 'Present',
    DateTime(2024, 6, 2): 'Absent',
    DateTime(2024, 6, 3): 'Present',
    DateTime(2024, 6, 4): 'Late',
    DateTime(2024, 6, 5): 'Half Day',
    // ... more days
  };

  final Map<String, Color> attendanceColors = {
    'Present': Colors.green,
    'Absent': Colors.red,
    'Late': Colors.orange,
    'Half Day': Colors.purple,
  };

  DateTime _displayedMonth = DateTime.now();

  int _selectedPastMonth = DateTime.now().month;
  int _selectedPastYear = DateTime.now().year;

  List<MapEntry<DateTime, String>> _getMonthAttendance(int year, int month) {
    return attendanceMap.entries
        .where((e) => e.key.year == year && e.key.month == month)
        .toList()
      ..sort((a, b) => a.key.day.compareTo(b.key.day));
  }

  Future<void> _handleCheckInOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!isCheckedIn) {
        // Check In
        await AttendanceService().checkIn();
        setState(() {
          isCheckedIn = true;
          checkInTime = DateTime.now();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully checked in at ${DateFormat('hh:mm a').format(DateTime.now())}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // Check Out
        await AttendanceService().checkOut();
        setState(() {
          isCheckedIn = false;
          checkOutTime = DateTime.now();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully checked out at ${DateFormat('hh:mm a').format(DateTime.now())}'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isCheckedIn ? 'check out' : 'check in'}. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStatus = attendanceMap[DateTime(now.year, now.month, now.day)] ?? 'Not Marked';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<RealtimeProvider>(
            builder: (context, realtimeProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(
                      realtimeProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                      color: realtimeProvider.isConnected ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      realtimeProvider.isConnected ? 'Live' : 'Offline',
                      style: TextStyle(
                        color: realtimeProvider.isConnected ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Date and Time Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(now),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Today\'s Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('hh:mm').format(now),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('a').format(now),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Check In/Out Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCheckedIn 
                        ? [Colors.red.withValues(alpha: 0.1), Colors.red.withValues(alpha: 0.05)]
                        : [accentColor.withValues(alpha: 0.1), accentColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      isCheckedIn ? Icons.logout : Icons.login,
                      size: 48,
                      color: isCheckedIn ? Colors.red : accentColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCheckedIn
                          ? 'Checked In at ${checkInTime != null ? DateFormat('hh:mm a').format(checkInTime!) : ''}'
                          : 'Not Checked In',
                      style: TextStyle(
                        color: isCheckedIn ? Colors.red : accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleCheckInOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCheckedIn ? Colors.red : accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isCheckedIn ? 'Check Out' : 'Check In',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Today's Attendance Status
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: attendanceColors[todayStatus]?.withValues(alpha: 0.1) ?? Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: attendanceColors[todayStatus] ?? Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Status',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            todayStatus,
                            style: TextStyle(
                              color: attendanceColors[todayStatus] ?? mainTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Attendance Summary
            Text(
              'Monthly Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: mainTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryBox('Present', present, Colors.green),
                _summaryBox('Absent', absent, Colors.red),
                _summaryBox('Late', late, Colors.orange),
                _summaryBox('Half Day', halfDay, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            
            // Monthly Calendar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Calendar View',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: mainTextColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left, color: primaryColor),
                              onPressed: () {
                                setState(() {
                                  final newMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
                                  _displayedMonth = newMonth;
                                  _selectedPastMonth = newMonth.month;
                                  _selectedPastYear = newMonth.year;
                                });
                              },
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_displayedMonth),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right, color: primaryColor),
                              onPressed: () {
                                setState(() {
                                  final newMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
                                  _displayedMonth = newMonth;
                                  _selectedPastMonth = newMonth.month;
                                  _selectedPastYear = newMonth.year;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCalendar(context, _displayedMonth.year, _displayedMonth.month),
                    const SizedBox(height: 16),
                    // Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: attendanceColors.entries
                          .map((e) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: e.value,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    e.key,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Past Attendance Records Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('View Past Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => PastAttendanceSheet(
                      attendanceMap: attendanceMap,
                      attendanceColors: attendanceColors,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Attendance list for selected month
            if (_getMonthAttendance(_selectedPastYear, _selectedPastMonth).isNotEmpty) ...[
              Text(
                '${DateFormat('MMMM yyyy').format(_displayedMonth)} Records',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: mainTextColor,
                ),
              ),
              const SizedBox(height: 12),
              ..._getMonthAttendance(_selectedPastYear, _selectedPastMonth).map((entry) => Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (attendanceColors[entry.value] ?? Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: attendanceColors[entry.value] ?? Colors.grey,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        DateFormat('MMM d, yyyy').format(entry.key),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: mainTextColor,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (attendanceColors[entry.value] ?? Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: attendanceColors[entry.value],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(String label, int count, Color color) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, int year, int month) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday
    final List<Widget> dayWidgets = [];
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final type = attendanceMap[date];
      dayWidgets.add(
        Container(
          margin: const EdgeInsets.all(2),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: type != null ? attendanceColors[type]?.withValues(alpha: 0.7) : Colors.grey[200],
            child: Text(
              '$day',
              style: TextStyle(
                color: type != null ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }
}

class PastAttendanceSheet extends StatelessWidget {
  final Map<DateTime, String> attendanceMap;
  final Map<String, Color> attendanceColors;

  const PastAttendanceSheet({
    Key? key,
    required this.attendanceMap,
    required this.attendanceColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group by month
    final grouped = <String, List<MapEntry<DateTime, String>>>{};
    for (var entry in attendanceMap.entries) {
      final month = DateFormat('MMMM yyyy').format(entry.key);
      grouped.putIfAbsent(month, () => []).add(entry);
    }
    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a)); // latest first

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: controller,
          children: [
            const Center(
              child: Text('Past Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 12),
            ...months.map((month) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                ...grouped[month]!.map((entry) => ListTile(
                  leading: Icon(Icons.calendar_today, color: attendanceColors[entry.value] ?? Colors.grey),
                  title: Text(DateFormat('MMM d, yyyy').format(entry.key)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (attendanceColors[entry.value] ?? Colors.grey).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: attendanceColors[entry.value],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),
                const Divider(),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
