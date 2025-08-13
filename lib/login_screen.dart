import 'package:flutter/material.dart';
import 'forgot_password_page.dart';
import 'sign_up_page.dart';
import 'dart:async';
import 'task_screen.dart';
import 'attendance_screen.dart';
import 'profile_screen.dart';
import 'leave_and_permission_screen.dart';
import 'payroll_screen.dart';
import 'admin_dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/dashboard_service.dart';
import 'services/announcement_service.dart';
import 'screens/face_recognition_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _loggedIn = false;
  String _userName = 'User';
  bool _clockedIn = true;
  Duration _workDuration = Duration.zero;
  Timer? _timer;
  String _attendanceTime = '10:00 AM';
  DateTime _selectedDate = DateTime.now();
  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  
  // Dashboard data
  Map<String, dynamic> _dashboardData = {};
  bool _dashboardLoading = true;
  List<dynamic> _announcements = [];
  bool _announcementsLoading = true;

  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color accentColor = Color(0xFF00BFAE);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color cardColor = Colors.white;
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadAnnouncements();
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await DashboardService.getEmployeeDashboardData();
      setState(() {
        _dashboardData = data;
        _dashboardLoading = false;
        _userName = data['userName'] ?? 'User';
        _workDuration = Duration(minutes: (data['workDuration'] ?? 0).toInt());
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _dashboardLoading = false;
      });
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final announcements = await AnnouncementService.getLatestAnnouncements();
      setState(() {
        _announcements = announcements;
        _announcementsLoading = false;
      });
    } catch (e) {
      print('Error loading announcements: $e');
      setState(() {
        _announcementsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building LoginScreen...');
    if (_loggedIn) {
      print('📊 User is logged in, showing dashboard');
      return _buildDashboard();
    }
    print('🔐 User not logged in, showing login form');
    return _buildLoginForm();
  }

  Widget _buildLoginForm() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/App Name
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.business,
                          size: 60,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Employee Management',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: secondaryTextColor.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: secondaryTextColor.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                                                        filled: true,
                            fillColor: backgroundColor.withValues(alpha: 0.3),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(Icons.lock, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                color: secondaryTextColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: secondaryTextColor.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: secondaryTextColor.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: backgroundColor.withValues(alpha: 0.3),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Remember Me & Forgot Password
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                              activeColor: primaryColor,
                            ),
                            Text(
                              'Remember me',
                              style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Login Buttons
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator(color: primaryColor))
                        else ...[
                          ElevatedButton(
                            onPressed: () => _loginAsEmployee(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Login as Employee',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _loginAsAdmin(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Login as Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Face Registration Test
                  
                  const SizedBox(height: 16),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: secondaryTextColor),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignUpPage()),
                          );
                        },
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Login methods
  Future<void> _loginAsEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      final result = await AuthService().login(email, password);
      
      if (result['user']['role'] == 'EMPLOYEE') {
        // Update user name from session
        final user = result['user'] ?? {};
        setState(() {
          _userName = (user['name'] is String && user['name'] != null) ? user['name'] : 'User';
          _loggedIn = true;
          _clockedIn = false;
          _workDuration = Duration.zero;
          _isLoading = false;
        });
        _loadDashboardData();
        // Don't navigate to TaskScreen - let the build method show the dashboard
        // The dashboard will be shown automatically when _loggedIn is true
      } else {
        _showErrorSnackBar('Invalid employee credentials');
      }
    } catch (e) {
      _showErrorSnackBar('Login failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginAsAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      final result = await AuthService().login(email, password);
      
      if (result['user']['role'] == 'ADMIN') {
        final user = result['user'] ?? {};
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboardScreen(userName: (user['name'] is String && user['name'] != null) ? user['name'] : 'User'),
          ),
        );
      } else {
        _showErrorSnackBar('Invalid admin credentials');
      }
    } catch (e) {
      _showErrorSnackBar('Login failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _workDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notifications', style: TextStyle(color: mainTextColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.info, color: accentColor),
                title: Text('Welcome to Employee Dashboard'),
                subtitle: Text('You have successfully logged in'),
              ),
              ListTile(
                leading: Icon(Icons.task, color: Colors.blue),
                title: Text('Tasks Updated'),
                subtitle: Text('New tasks have been assigned'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout', style: TextStyle(color: mainTextColor)),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _loggedIn = false;
                  _userName = 'User';
                  _workDuration = Duration.zero;
                  _clockedIn = true;
                });
                _stopTimer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  Widget _buildDashboard() {
    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD), // Solid light blue
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with avatar, notification, and logout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryColor,
                        radius: 20,
                        child: Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Text('Hi, $_userName', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mainTextColor)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.refresh, color: mainTextColor, size: 24),
                        onPressed: () {
                          setState(() {
                            _dashboardLoading = true;
                            _announcementsLoading = true;
                          });
                          _loadDashboardData();
                          _loadAnnouncements();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: mainTextColor, size: 24),
                        onPressed: () {
                          _showNotifications();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, color: mainTextColor, size: 24),
                        onPressed: () {
                          _showLogoutDialog(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Attendance Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 8,
                margin: EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFF8FBFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Decorative wave or curve (optional)
                      // SizedBox(height: 8),
                      // Clock image
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.15),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.access_time,
                          size: 48,
                          color: Color(0xFF00BFAE),
                        ),
                      ),
                      SizedBox(height: 18),
                      // Time breakdown with labels and background
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFE3F6FD), // Soft blue background
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ModernTimeBox(_workDuration.inHours.toString().padLeft(2, '0'), label: 'Hrs'),
                            SizedBox(width: 10),
                            _ModernTimeBox((_workDuration.inMinutes % 60).toString().padLeft(2, '0'), label: 'Min'),
                            SizedBox(width: 10),
                            _ModernTimeBox((_workDuration.inSeconds % 60).toString().padLeft(2, '0'), label: 'Sec'),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Shift info
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFEDF4FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _dashboardData['shiftTiming'] ?? 'Template 4 - 09:00 AM To 05:00 AM',
                          style: TextStyle(fontSize: 15, color: Color(0xFF223A5E)),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Check In/Out button with gradient
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (_clockedIn) {
                                _stopTimer();
                              } else {
                                _workDuration = Duration.zero;
                                _startTimer();
                              }
                              _clockedIn = !_clockedIn;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                            backgroundColor: _clockedIn
                                ? Color(0xFF223A5E) // Deep blue for Check Out
                                : Color(0xFF00BFAE), // Green/teal for Check In
                            shadowColor: Colors.blueAccent.withValues(alpha: 0.2),
                          ),
                          child: Text(
                            _clockedIn ? 'Check Out' : 'Check In',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Location Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: cardColor,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Icon(
                      Icons.location_on,
                      color: const Color.fromARGB(255, 29, 128, 194),
                      size: 40,
                    ),
                  ),
                  title: Text('Location', style: TextStyle(color: mainTextColor)),
                  subtitle: Text(_dashboardData['location'] ?? '123 Main Street, Anytown', style: TextStyle(color: secondaryTextColor)),
                ),
              ),
              const SizedBox(height: 24),
              Text("Today's Tasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mainTextColor)),
              const SizedBox(height: 12),
              // Tasks List - Real data from database
              _dashboardLoading 
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: (_dashboardData['todayTasks'] as List<dynamic>? ?? []).map((task) {
                      Color statusColor = Colors.blue;
                      IconData taskIcon = Icons.task;
                      
                      switch (task['status']?.toString().toUpperCase()) {
                        case 'COMPLETED':
                          statusColor = Colors.green;
                          taskIcon = Icons.check_circle;
                          break;
                        case 'IN_PROGRESS':
                          statusColor = Colors.orange;
                          taskIcon = Icons.pending;
                          break;
                        case 'PENDING':
                        default:
                          statusColor = Colors.blue;
                          taskIcon = Icons.schedule;
                          break;
                      }
                      
                      return _taskTile(
                        taskIcon, 
                        task['title'] ?? 'Task', 
                        task['status'] ?? 'Pending', 
                        statusColor, 
                        (task['status']?.toString().toUpperCase() ?? 'PENDING') == 'COMPLETED', 
                        mainTextColor, 
                        secondaryTextColor
                      );
                    }).toList(),
                  ),
              const SizedBox(height: 32),
              // Announcements Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Latest Announcements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mainTextColor)),
                  IconButton(
                    icon: Icon(Icons.refresh, color: primaryColor),
                    onPressed: () {
                      setState(() {
                        _announcementsLoading = true;
                      });
                      _loadAnnouncements();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Announcements List
              _announcementsLoading 
                ? Center(child: CircularProgressIndicator())
                : _announcements.isEmpty
                  ? Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No announcements yet',
                          style: TextStyle(color: secondaryTextColor, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      children: _announcements.take(3).map((announcement) {
                        Color priorityColor = Colors.blue;
                        IconData priorityIcon = Icons.info;
                        
                        switch (announcement['priority']?.toString().toLowerCase()) {
                          case 'high':
                            priorityColor = Colors.red;
                            priorityIcon = Icons.priority_high;
                            break;
                          case 'medium':
                            priorityColor = Colors.orange;
                            priorityIcon = Icons.info;
                            break;
                          case 'low':
                            priorityColor = Colors.green;
                            priorityIcon = Icons.check_circle;
                            break;
                        }
                        
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: priorityColor.withValues(alpha: 0.1),
                              child: Icon(priorityIcon, color: priorityColor, size: 20),
                            ),
                            title: Text(
                              announcement['title'] ?? 'Announcement',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: mainTextColor,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  announcement['content'] ?? '',
                                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  announcement['createdAt'] != null 
                                    ? DateTime.parse(announcement['createdAt']).toString().substring(0, 10)
                                    : 'Today',
                                  style: TextStyle(color: secondaryTextColor, fontSize: 10),
                                ),
                              ],
                            ),
                            trailing: announcement['isPinned'] == true
                              ? Icon(Icons.push_pin, color: Colors.orange, size: 16)
                              : null,
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 32),
              // Dashboard title and notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mainTextColor)),
                  // Removed notification bell
                ],
              ),
              const SizedBox(height: 16),
              // Quick Actions Grid
              Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: mainTextColor)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _quickActionTile(Icons.calendar_today, 'Attendance', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AttendanceScreen()),
                    );
                  }, color: Color(0xFF42A5F5), textColor: Colors.black),
                  _quickActionTile(Icons.description, 'Leave & Permission', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LeaveGridPage()),
                    );
                  }, color: Color(0xFF42A5F5), textColor: Colors.black),
                  _quickActionTile(Icons.checklist, 'Tasks', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TaskScreen()),
                    );
                  }, color: Color(0xFF42A5F5), textColor: Colors.black),
                  _quickActionTile(Icons.attach_money, 'Payroll', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PayrollScreen()),
                    );
                  }, color: Color(0xFF42A5F5), textColor: Colors.black),
                  _quickActionTile(Icons.person, 'Profile', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  }, color: Color(0xFF42A5F5), textColor: Colors.black),
                  _quickActionTile(Icons.face, 'Face Recognition', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FaceRecognitionScreen()),
                    );
                  }, color: Color(0xFF42A5F5), textColor: Colors.black),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: accentColor,
        unselectedItemColor: secondaryTextColor,
        backgroundColor: cardColor,
        type: BottomNavigationBarType.fixed,  // Add this for 4+ items
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaskScreen()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
          if (index == 3) {  // NEW: Face Recognition
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FaceRecognitionScreen()),
            );
          }
          // You can add navigation for other indices if needed
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.face), label: 'Face ID'),  // NEW
        ],
      ),
    );
  }
}

Widget _taskTile(IconData icon, String title, String status, Color color, bool isCompleted, [Color? mainTextColor, Color? secondaryTextColor]) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 1,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: mainTextColor ?? Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _quickActionTile(IconData icon, String label, {VoidCallback? onTap, Color? color, Color? textColor}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 1,
    color: color ??  const Color.fromARGB(255, 152, 180, 243), // Changed to use the provided color
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: textColor ?? Colors.white), // Changed to use the provided textColor
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: textColor ?? Colors.white), // Changed to use the provided textColor
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // Helper function to get task icon based on title
  IconData _getTaskIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('meeting')) return Icons.meeting_room;
    if (lowerTitle.contains('presentation')) return Icons.assignment_turned_in;
    if (lowerTitle.contains('collaboration') || lowerTitle.contains('team')) return Icons.group;
    if (lowerTitle.contains('design')) return Icons.design_services;
    if (lowerTitle.contains('development') || lowerTitle.contains('api')) return Icons.code;
    if (lowerTitle.contains('report')) return Icons.assessment;
    if (lowerTitle.contains('review')) return Icons.rate_review;
    return Icons.task;
  }

  // Helper function to get status color
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'PENDING':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Add this widget outside your class (for the time boxes)
class _TimeBox extends StatelessWidget {
  final String value;
  final Color? color;
  const _TimeBox(this.value, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F6FD), // Light blue background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color ?? const Color.fromARGB(255, 107, 133, 207), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: color ?? const Color.fromARGB(255, 152, 180, 243),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _ModernTimeBox extends StatelessWidget {
  final String value;
  final String label;
  const _ModernTimeBox(this.value, {required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            border: Border.all(color: Color(0xFF00BFAE), width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Color(0xFF00BFAE),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF223A5E))),
      ],
    );
  }
}