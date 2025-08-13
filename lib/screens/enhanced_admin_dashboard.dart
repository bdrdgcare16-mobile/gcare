import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/user_session.dart';
import '../services/task_service.dart';
import '../services/attendance_service.dart';

class EnhancedAdminDashboard extends StatefulWidget {
  @override
  _EnhancedAdminDashboardState createState() => _EnhancedAdminDashboardState();
}

class _EnhancedAdminDashboardState extends State<EnhancedAdminDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _attendance = [];
  
  // Statistics
  int _totalEmployees = 0;
  int _activeTasks = 0;
  int _completedTasks = 0;
  int _presentToday = 0;
  int _absentToday = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load all data in parallel
      final results = await Future.wait([
        UserService.getAllEmployees(),
        TaskService.getAllTasks(),
        AttendanceService().getTodayAttendance(),
      ]);

      setState(() {
        _employees = results[0] as List<Map<String, dynamic>>;
        _tasks = results[1] as List<Map<String, dynamic>>;
        _attendance = results[2] as List<Map<String, dynamic>>;
        
        // Calculate statistics
        _totalEmployees = _employees.length;
        _activeTasks = _tasks.where((task) => task['status'] == 'PENDING').length;
        _completedTasks = _tasks.where((task) => task['status'] == 'COMPLETED').length;
        _presentToday = _attendance.where((att) => att['status'] == 'PRESENT').length;
        _absentToday = _totalEmployees - _presentToday;
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatisticsCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Employees',
                    _totalEmployees.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Tasks',
                    _activeTasks.toString(),
                    Icons.assignment,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Completed Tasks',
                    _completedTasks.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Present Today',
                    _presentToday.toString(),
                    Icons.person_pin,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Employees (${_employees.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Employee'),
                  onPressed: () => _showAddEmployeeDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final employee = _employees[index];
                final isPresent = _attendance.any((att) => 
                  att['userId'] == employee['id'] && att['status'] == 'PRESENT'
                );
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      employee['name'].substring(0, 1).toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(employee['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee['designation'] ?? 'N/A'),
                      Text(employee['department'] ?? 'N/A'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPresent ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.assignment),
                        onPressed: () => _showAssignTaskDialog(employee),
                        tooltip: 'Assign Task',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final designationController = TextEditingController();
    final departmentController = TextEditingController();
    final reportingToController = TextEditingController();
    
    String selectedGender = 'Female';
    String selectedShift = '9:00 AM - 6:00 PM';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Employee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
              ),
              TextField(
                controller: designationController,
                decoration: InputDecoration(labelText: 'Designation'),
              ),
              TextField(
                controller: departmentController,
                decoration: InputDecoration(labelText: 'Department'),
              ),
              TextField(
                controller: reportingToController,
                decoration: InputDecoration(labelText: 'Reporting To'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Gender: '),
                  DropdownButton<String>(
                    value: selectedGender,
                    items: ['Male', 'Female', 'Other'].map((gender) {
                      return DropdownMenuItem(value: gender, child: Text(gender));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Shift: '),
                  DropdownButton<String>(
                    value: selectedShift,
                    items: [
                      '9:00 AM - 6:00 PM',
                      '10:00 AM - 7:00 PM',
                      '8:00 AM - 5:00 PM',
                    ].map((shift) {
                      return DropdownMenuItem(value: shift, child: Text(shift));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedShift = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await UserService.addEmployee(
                  name: nameController.text,
                  email: emailController.text,
                  password: passwordController.text,
                  phoneNumber: phoneController.text,
                  designation: designationController.text,
                  department: departmentController.text,
                  gender: selectedGender,
                  shiftTiming: selectedShift,
                  reportingTo: reportingToController.text,
                );
                
                Navigator.pop(context);
                _loadDashboardData(); // Refresh data
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Employee added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add employee: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Add Employee'),
          ),
        ],
      ),
    );
  }

  void _showAssignTaskDialog(Map<String, dynamic> employee) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Task to ${employee['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Task Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Task Description'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('Due Date: '),
                Text(selectedDate.toString().split(' ')[0]),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
                             try {
                 await TaskService.createTask(
                   title: titleController.text,
                   description: descriptionController.text,
                   userId: employee['id'],
                   status: 'PENDING',
                   dueDate: selectedDate,
                 );
                
                Navigator.pop(context);
                _loadDashboardData(); // Refresh data
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task assigned successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to assign task: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Assign Task'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatisticsCard(),
                  _buildEmployeesList(),
                ],
              ),
            ),
    );
  }
} 