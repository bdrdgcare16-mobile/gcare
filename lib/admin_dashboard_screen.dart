import 'package:flutter/material.dart';
import 'admin_employee_screen.dart';
import 'admin_leave_request_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_payroll_screen.dart';
import 'admin_announcement_screen.dart';
import 'login_screen.dart';
import 'assign_task_screen.dart';
import 'services/admin_dashboard_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String userName;
  const AdminDashboardScreen({Key? key, required this.userName}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  // Dashboard statistics
  Map<String, dynamic> stats = {
    'totalEmployees': 0,
    'activeEmployees': 0,
    'pendingLeaves': 0,
    'todayAttendance': 0,
    'totalPayroll': 0,
    'announcements': 0,
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final dashboardStats = await AdminDashboardService.getDashboardStats();
      setState(() {
        stats = dashboardStats;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard stats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadDashboardStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _showNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with statistics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi,  ${widget.userName}!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening today',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                isLoading 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLoadingStatCard('Employees', Icons.people, Colors.blue),
                        _buildLoadingStatCard('Attendance', Icons.check_circle, Colors.green),
                        _buildLoadingStatCard('Pending', Icons.pending, Colors.orange),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Employees', '${stats['totalEmployees']}', Icons.people, Colors.blue),
                        _buildStatCard('Attendance', '${stats['todayAttendance']}', Icons.check_circle, Colors.green),
                        _buildStatCard('Pending', '${stats['pendingLeaves']}', Icons.pending, Colors.orange),
                      ],
                    ),
              ],
            ),
          ),
          
          // Dashboard content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Grid of action cards
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                      children: [
                        _buildActionCard(
                          'Employees',
                          'Manage employee information and profiles',
                          Icons.people,
                          const Color(0xFFE3F2FD),
                          const Color(0xFF1976D2),
                          () => _showQuickDataPopup('Employees', 'Total: ${stats['totalEmployees']}\nActive: ${stats['activeEmployees']}'),
                        ),
                        _buildActionCard(
                          'Leave Requests',
                          'Review and approve leave applications',
                          Icons.assignment,
                          const Color(0xFFE8F5E8),
                          const Color(0xFF388E3C),
                          () => _showQuickDataPopup('Leave Requests', 'Pending: ${stats['pendingLeaves']}\nTotal Requests: ${stats['pendingLeaves'] + 5}'),
                        ),
                        _buildActionCard(
                          'Attendance',
                          'Monitor employee attendance and reports',
                          Icons.calendar_today,
                          const Color(0xFFFFF8E1),
                          const Color(0xFFF57C00),
                          () => _showQuickDataPopup('Attendance', 'Today: ${stats['todayAttendance']}\nPresent: ${stats['todayAttendance']}\nAbsent: ${stats['totalEmployees'] - stats['todayAttendance']}\nLate: 0'),
                        ),
                        _buildActionCard(
                          'Payroll',
                          'Manage salary and payment processing',
                          Icons.payments,
                          const Color(0xFFFFEBEE),
                          const Color(0xFFD32F2F),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AdminPayrollScreen()),
                          ),
                        ),
                        _buildActionCard(
                          'Announcements',
                          'Create and manage company announcements',
                          Icons.campaign,
                          const Color(0xFFF3E5F5),
                          const Color(0xFF7B1FA2),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AdminAnnouncementScreen()),
                          ),
                        ),
                        _buildActionCard(
                          'Assign Tasks',
                          'Assign and track employee tasks',
                          Icons.assignment_turned_in,
                          const Color(0xFFE0F2F1),
                          const Color(0xFF00695C),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AssignTaskScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String description, IconData icon, Color backgroundColor, Color iconColor, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [backgroundColor, backgroundColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF222B45),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7A8F),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.logout, color: primaryColor),
              const SizedBox(width: 8),
              const Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.blue),
                  title: const Text('New Leave Request'),
                  subtitle: const Text('John Doe requested annual leave'),
                  trailing: const Text('2 min ago'),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.green),
                  title: const Text('Attendance Alert'),
                  subtitle: const Text('5 employees late today'),
                  trailing: const Text('10 min ago'),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.orange),
                  title: const Text('Payroll Reminder'),
                  subtitle: const Text('Payroll processing due tomorrow'),
                  trailing: const Text('1 hour ago'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickDataPopup(String title, String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: primaryColor),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap "View Details" to see full information',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7A8F),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to respective screen
                switch (title) {
                  case 'Employees':
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminEmployeeScreen()));
                    break;
                  case 'Leave Requests':
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLeaveRequestScreen()));
                    break;
                  case 'Attendance':
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAttendanceScreen()));
                    break;
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }
}
