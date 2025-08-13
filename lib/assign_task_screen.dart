import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/task_service.dart';
import 'services/api_base.dart';
import 'services/user_session.dart';

class AssignTaskScreen extends StatefulWidget {
  @override
  _AssignTaskScreenState createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  List<Map<String, dynamic>> employees = [
    {
      'id': 1,
      'name': 'Nishali Sharma',
      'email': 'nishali@company.com',
      'department': 'IT',
      'designation': 'Software Engineer',
    },
    {
      'id': 2,
      'name': 'Rahul Verma',
      'email': 'rahul@company.com',
      'department': 'Design',
      'designation': 'UI/UX Designer',
    },
    {
      'id': 3,
      'name': 'Priya Singh',
      'email': 'priya@company.com',
      'department': 'HR',
      'designation': 'HR Manager',
    },
    {
      'id': 4,
      'name': 'Amit Patel',
      'email': 'amit@company.com',
      'department': 'IT',
      'designation': 'QA Analyst',
    },
    {
      'id': 5,
      'name': 'Sneha Reddy',
      'email': 'sneha@company.com',
      'department': 'Marketing',
      'designation': 'Marketing Specialist',
    },
  ];

  int? selectedUserId;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? selectedDeadline;
  String? selectedPriority;
  String _selectedDepartment = 'All';
  bool _isLoading = false;

  Map<String, dynamic> get _statistics {
    final totalEmployees = employees.length;
    final itEmployees = employees.where((e) => e['department'] == 'IT').length;
    final designEmployees = employees.where((e) => e['department'] == 'Design').length;
    final hrEmployees = employees.where((e) => e['department'] == 'HR').length;
    
    return {
      'total': totalEmployees,
      'it': itEmployees,
      'design': designEmployees,
      'hr': hrEmployees,
    };
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_selectedDepartment == 'All') return employees;
    return employees.where((e) => e['department'] == _selectedDepartment).toList();
  }

  List<String> get _departments {
    final depts = employees.map((e) => e['department'] as String).toSet().toList();
    depts.sort();
    depts.insert(0, 'All');
    return depts;
  }

  @override
  void initState() {
    super.initState();
    fetchEmployees(); // Load real employees from backend
  }

  Future<void> fetchEmployees() async {
    try {
      if (!UserSession.instance.isLoggedIn) {
        print('User not authenticated');
        return;
      }

      final response = await http.get(
        Uri.parse('${getBaseUrl()}/users/employees'),
        headers: getHeaders(token: UserSession.instance.token),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? body;
        setState(() {
          employees = data.map((user) => {
            'id': user['id'],
            'name': user['name'],
            'email': user['email'],
            'department': 'IT', // Default department since our schema doesn't have it
            'designation': 'Employee', // Default designation
          }).toList();
        });
      } else {
        print('Failed to load employees: ${response.statusCode}');
        // Keep using mock data if API fails
      }
    } catch (e) {
      print('Error fetching employees: $e');
      // Keep using mock data if API fails
    }
  }

  Future<void> _assignTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await TaskService.createTask(
        userId: selectedUserId!,
        title: _titleController.text,
        description: _descController.text,
        status: 'PENDING',
        dueDate: selectedDeadline,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task assigned successfully! The employee will see it in their task list.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
    final stats = _statistics;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Assign Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  'Task Assignment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Assign tasks to employees and track progress',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', '${stats['total']}', Icons.people, Colors.blue),
                    _buildStatCard('IT', '${stats['it']}', Icons.computer, Colors.green),
                    _buildStatCard('Design', '${stats['design']}', Icons.design_services, Colors.orange),
                    _buildStatCard('HR', '${stats['hr']}', Icons.people_outline, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Department filter
                    Text(
                      'Filter by Department',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartment = value!;
                          selectedUserId = null; // Reset selection when department changes
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Employee selection
                    Text(
                      'Select Employee',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: selectedUserId,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        hint: const Text('Choose an employee'),
                        items: _filteredEmployees.map((emp) => DropdownMenuItem<int>(
                          value: emp['id'] as int,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  emp['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${emp['designation']} • ${emp['department']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                        onChanged: (val) => setState(() => selectedUserId = val),
                        validator: (v) => v == null ? 'Please select an employee' : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Task details
                    Text(
                      'Task Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter task title' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: 'Task Description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter task description' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Deadline
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => selectedDeadline = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedDeadline == null
                                    ? 'Select Deadline'
                                    : 'Deadline: ${DateFormat('MMM d, yyyy').format(selectedDeadline!)}',
                                style: TextStyle(
                                  color: selectedDeadline == null ? secondaryTextColor : mainTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Priority
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Priority Level',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.priority_high),
                      ),
                      items: [
                        DropdownMenuItem(value: 'High', child: Text('High Priority')),
                        DropdownMenuItem(value: 'Medium', child: Text('Medium Priority')),
                        DropdownMenuItem(value: 'Low', child: Text('Low Priority')),
                      ],
                      onChanged: (val) => setState(() => selectedPriority = val),
                      validator: (value) => value == null ? 'Please select priority' : null,
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _assignTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Assigning Task...'),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_turned_in),
                                  SizedBox(width: 8),
                                  Text('Assign Task'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
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
}

class AssignTaskCard extends StatelessWidget {
  final VoidCallback onTap;
  const AssignTaskCard({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 40, color: const Color(0xFF9575CD)),
            const SizedBox(height: 8),
            const Text(
              'Assign Task',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}