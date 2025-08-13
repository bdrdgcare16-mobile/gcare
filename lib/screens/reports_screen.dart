import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final reportsProvider = context.read<ReportsProvider>();
    await reportsProvider.loadAllReports(
      month: _selectedMonth,
      year: _selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Attendance'),
            Tab(text: 'Payroll'),
            Tab(text: 'Performance'),
            Tab(text: 'Leave'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(_getMonthName(index + 1)),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value!;
                      });
                      _loadReports();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value!;
                      });
                      _loadReports();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildAttendanceTab(),
                _buildPayrollTab(),
                _buildPerformanceTab(),
                _buildLeaveTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        if (reportsProvider.isLoadingDashboard) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reportsProvider.dashboardError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: TextStyle(fontSize: 18, color: Colors.red[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  reportsProvider.dashboardError!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final dashboardData = reportsProvider.dashboardData;
        if (dashboardData == null) {
          return const Center(child: Text('No dashboard data available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Total Employees',
                      value: dashboardData['totalEmployees']?.toString() ?? '0',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Today Attendance',
                      value: dashboardData['todayAttendance']?.toString() ?? '0',
                      icon: Icons.access_time,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Pending Leaves',
                      value: dashboardData['pendingLeaves']?.toString() ?? '0',
                      icon: Icons.event_note,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Completed Tasks',
                      value: '${dashboardData['completedTasks']?.toString() ?? '0'}/${dashboardData['totalTasks']?.toString() ?? '0'}',
                      icon: Icons.assignment_turned_in,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ReportCard(
                title: 'Total Payroll',
                value: '\$${(dashboardData['totalPayroll'] ?? 0).toStringAsFixed(2)}',
                icon: Icons.payment,
                color: Colors.teal,
                isFullWidth: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        if (reportsProvider.isLoadingAttendance) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reportsProvider.attendanceError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading attendance report',
                  style: TextStyle(fontSize: 18, color: Colors.red[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  reportsProvider.attendanceError!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final attendanceStats = reportsProvider.attendanceStats;
        if (attendanceStats == null) {
          return const Center(child: Text('No attendance data available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Statistics cards
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Present Days',
                      value: attendanceStats['presentDays']?.toString() ?? '0',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Absent Days',
                      value: attendanceStats['absentDays']?.toString() ?? '0',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Late Days',
                      value: attendanceStats['lateDays']?.toString() ?? '0',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Attendance Rate',
                      value: '${(attendanceStats['attendanceRate'] ?? 0).toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayrollTab() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        if (reportsProvider.isLoadingPayroll) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reportsProvider.payrollError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading payroll report',
                  style: TextStyle(fontSize: 18, color: Colors.red[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  reportsProvider.payrollError!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final payrollStats = reportsProvider.payrollStats;
        if (payrollStats == null) {
          return const Center(child: Text('No payroll data available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Statistics cards
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Total Employees',
                      value: payrollStats['totalEmployees']?.toString() ?? '0',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Total Payroll',
                      value: '\$${(payrollStats['totalPayroll'] ?? 0).toStringAsFixed(2)}',
                      icon: Icons.payment,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Average Salary',
                      value: '\$${(payrollStats['averageSalary'] ?? 0).toStringAsFixed(2)}',
                      icon: Icons.analytics,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Highest Salary',
                      value: '\$${(payrollStats['highestSalary'] ?? 0).toStringAsFixed(2)}',
                      icon: Icons.trending_up,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        if (reportsProvider.isLoadingPerformance) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reportsProvider.performanceError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading performance report',
                  style: TextStyle(fontSize: 18, color: Colors.red[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  reportsProvider.performanceError!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final performanceMetrics = reportsProvider.performanceMetrics;
        if (performanceMetrics == null) {
          return const Center(child: Text('No performance data available'));
        }

        final taskMetrics = performanceMetrics['taskMetrics'] ?? {};
        final attendanceMetrics = performanceMetrics['attendanceMetrics'] ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Task metrics
              Text(
                'Task Performance',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Completed Tasks',
                      value: taskMetrics['completedTasks']?.toString() ?? '0',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Task Completion Rate',
                      value: '${(taskMetrics['taskCompletionRate'] ?? 0).toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Attendance metrics
              Text(
                'Attendance Performance',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Present Days',
                      value: attendanceMetrics['presentDays']?.toString() ?? '0',
                      icon: Icons.access_time,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Attendance Rate',
                      value: '${(attendanceMetrics['attendanceRate'] ?? 0).toStringAsFixed(1)}%',
                      icon: Icons.analytics,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Overall score
              ReportCard(
                title: 'Overall Performance Score',
                value: '${(performanceMetrics['overallScore'] ?? 0).toStringAsFixed(1)}%',
                icon: Icons.star,
                color: Colors.purple,
                isFullWidth: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaveTab() {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        if (reportsProvider.isLoadingLeave) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reportsProvider.leaveError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading leave report',
                  style: TextStyle(fontSize: 18, color: Colors.red[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  reportsProvider.leaveError!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final leaveStats = reportsProvider.leaveStats;
        if (leaveStats == null) {
          return const Center(child: Text('No leave data available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Statistics cards
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Approved',
                      value: leaveStats['approvedRequests']?.toString() ?? '0',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Pending',
                      value: leaveStats['pendingRequests']?.toString() ?? '0',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ReportCard(
                      title: 'Rejected',
                      value: leaveStats['rejectedRequests']?.toString() ?? '0',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportCard(
                      title: 'Approval Rate',
                      value: '${(leaveStats['approvalRate'] ?? 0).toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
} 