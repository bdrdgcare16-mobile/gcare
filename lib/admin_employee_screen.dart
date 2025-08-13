import 'package:flutter/material.dart';
import 'employee_profile_screen.dart';

class AdminEmployeeScreen extends StatefulWidget {
  const AdminEmployeeScreen({super.key});

  @override
  State<AdminEmployeeScreen> createState() => _AdminEmployeeScreenState();
}

class _AdminEmployeeScreenState extends State<AdminEmployeeScreen> {
  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color accentColor = Color(0xFF00BFAE);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color cardColor = Colors.white;
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  final List<Map<String, dynamic>> employees = [
    {
      'name': 'Nishali Sharma',
      'id': 'EMP001',
      'email': 'nishali@company.com',
      'phone': '+91 98765 43210',
      'department': 'IT',
      'designation': 'Software Engineer',
      'joinDate': '2023-01-15',
      'status': 'Active',
      'salary': 45000,
      'location': 'Mumbai',
    },
    {
      'name': 'Rahul Verma',
      'id': 'EMP002',
      'email': 'rahul@company.com',
      'phone': '+91 98765 43211',
      'department': 'Design',
      'designation': 'UI/UX Designer',
      'joinDate': '2023-03-20',
      'status': 'Active',
      'salary': 42000,
      'location': 'Delhi',
    },
    {
      'name': 'Priya Singh',
      'id': 'EMP003',
      'email': 'priya@company.com',
      'phone': '+91 98765 43212',
      'department': 'HR',
      'designation': 'HR Manager',
      'joinDate': '2022-11-10',
      'status': 'Active',
      'salary': 55000,
      'location': 'Bangalore',
    },
    {
      'name': 'Amit Patel',
      'id': 'EMP004',
      'email': 'amit@company.com',
      'phone': '+91 98765 43213',
      'department': 'IT',
      'designation': 'QA Analyst',
      'joinDate': '2023-06-05',
      'status': 'Active',
      'salary': 38000,
      'location': 'Mumbai',
    },
    {
      'name': 'Sneha Reddy',
      'id': 'EMP005',
      'email': 'sneha@company.com',
      'phone': '+91 98765 43214',
      'department': 'Marketing',
      'designation': 'Marketing Specialist',
      'joinDate': '2023-08-12',
      'status': 'Active',
      'salary': 40000,
      'location': 'Chennai',
    },
    {
      'name': 'David Wilson',
      'id': 'EMP006',
      'email': 'david@company.com',
      'phone': '+91 98765 43215',
      'department': 'Sales',
      'designation': 'Sales Executive',
      'joinDate': '2023-02-28',
      'status': 'Active',
      'salary': 35000,
      'location': 'Pune',
    },
  ];

  String _searchText = '';
  String _departmentFilter = 'All';
  String _sortBy = 'Name';

  Map<String, dynamic> get _statistics {
    final totalEmployees = employees.length;
    final activeEmployees = employees.where((e) => e['status'] == 'Active').length;
    final departments = employees.map((e) => e['department']).toSet().length;
    final avgSalary = employees.fold<double>(0, (sum, e) => sum + e['salary']) / totalEmployees;
    
    return {
      'total': totalEmployees,
      'active': activeEmployees,
      'departments': departments,
      'avgSalary': avgSalary,
    };
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    List<Map<String, dynamic>> filtered = employees.where((emp) {
      final matchesDepartment = _departmentFilter == 'All' || emp['department'] == _departmentFilter;
      final matchesSearch = emp['name']!.toLowerCase().contains(_searchText.toLowerCase()) ||
                           emp['email']!.toLowerCase().contains(_searchText.toLowerCase()) ||
                           emp['id']!.toLowerCase().contains(_searchText.toLowerCase());
      return matchesDepartment && matchesSearch;
    }).toList();
    
    // Sort
    if (_sortBy == 'Name') {
      filtered.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (_sortBy == 'Department') {
      filtered.sort((a, b) => a['department'].compareTo(b['department']));
    } else if (_sortBy == 'Salary') {
      filtered.sort((b, a) => a['salary'].compareTo(b['salary']));
    }
    
    return filtered;
  }

  List<String> get _departments {
    final depts = employees.map((e) => e['department'] as String).toSet().toList();
    depts.sort();
    return depts;
  }

  void _addEmployeeDialog() {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final designationController = TextEditingController();
    final salaryController = TextEditingController();
    String selectedDepartment = 'IT';
    String selectedLocation = 'Mumbai';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Add Employee'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter ID' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter phone' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  items: _departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                  onChanged: (value) {
                    selectedDepartment = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: designationController,
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter designation' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: salaryController,
                  decoration: const InputDecoration(
                    labelText: 'Salary',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Enter salary' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Pune']
                      .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                      .toList(),
                  onChanged: (value) {
                    selectedLocation = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  employees.add({
                    'name': nameController.text,
                    'id': idController.text,
                    'email': emailController.text,
                    'phone': phoneController.text,
                    'department': selectedDepartment,
                    'designation': designationController.text,
                    'joinDate': DateTime.now().toString().substring(0, 10),
                    'status': 'Active',
                    'salary': int.tryParse(salaryController.text) ?? 0,
                    'location': selectedLocation,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Employee added successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _viewEmployee(Map<String, dynamic> emp) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EmployeeProfileScreen(employee: emp)),
    );
  }

  void _editEmployee(Map<String, dynamic> emp) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: emp['name']);
    final idController = TextEditingController(text: emp['id']);
    final emailController = TextEditingController(text: emp['email']);
    final phoneController = TextEditingController(text: emp['phone']);
    final designationController = TextEditingController(text: emp['designation']);
    final salaryController = TextEditingController(text: emp['salary'].toString());
    String selectedDepartment = emp['department'];
    String selectedLocation = emp['location'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Edit Employee'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter ID' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter phone' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  items: _departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                  onChanged: (value) {
                    selectedDepartment = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: designationController,
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter designation' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: salaryController,
                  decoration: const InputDecoration(
                    labelText: 'Salary',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Enter salary' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Pune']
                      .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                      .toList(),
                  onChanged: (value) {
                    selectedLocation = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  final index = employees.indexWhere((e) => e['id'] == emp['id']);
                  if (index != -1) {
                    employees[index] = {
                      ...employees[index],
                      'name': nameController.text,
                      'id': idController.text,
                      'email': emailController.text,
                      'phone': phoneController.text,
                      'department': selectedDepartment,
                      'designation': designationController.text,
                      'salary': int.tryParse(salaryController.text) ?? 0,
                      'location': selectedLocation,
                    };
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Employee updated successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statistics;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Employee Management',
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
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
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
                  'Employee Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage employee information and profiles',
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
                    _buildStatCard('Active', '${stats['active']}', Icons.check_circle, Colors.green),
                    _buildStatCard('Departments', '${stats['departments']}', Icons.business, Colors.orange),
                    _buildStatCard('Avg Salary', '₹${stats['avgSalary'].round()}', Icons.account_balance_wallet, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) {
                setState(() {
                  _searchText = val;
                });
              },
            ),
          ),
          
          // Employees list
          Expanded(
            child: _filteredEmployees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No employees found',
                          style: TextStyle(
                            fontSize: 18,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final emp = _filteredEmployees[index];
                      return _buildEmployeeCard(emp);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
        onPressed: _addEmployeeDialog,
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewEmployee(emp),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    emp['name'][0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Employee info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${emp['designation']} • ${emp['department']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${emp['id']} • ${emp['email']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Salary and status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${emp['salary']}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emp['status'],
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Department filter
            DropdownButtonFormField<String>(
              value: _departmentFilter,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'All', child: Text('All Departments')),
                ..._departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))),
              ],
              onChanged: (value) {
                setState(() {
                  _departmentFilter = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Sort by
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'Name', child: Text('Name')),
                const DropdownMenuItem(value: 'Department', child: Text('Department')),
                const DropdownMenuItem(value: 'Salary', child: Text('Salary')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _departmentFilter = 'All';
                _sortBy = 'Name';
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class AdminEmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  final Function(Map<String, dynamic>) onEdit;
  const AdminEmployeeDetailScreen({super.key, required this.employee, required this.onEdit});

  @override
  State<AdminEmployeeDetailScreen> createState() => _AdminEmployeeDetailScreenState();
}

class _AdminEmployeeDetailScreenState extends State<AdminEmployeeDetailScreen> {
  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color accentColor = Color(0xFF00BFAE);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color cardColor = Colors.white;
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Employee Details',
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
          // Header with employee info
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
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.employee['name'][0],
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.employee['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.employee['designation']} • ${widget.employee['department']}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.employee['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Employee details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Personal Information', [
                    _buildDetailRow('Employee ID', widget.employee['id']),
                    _buildDetailRow('Email', widget.employee['email']),
                    _buildDetailRow('Phone', widget.employee['phone']),
                    _buildDetailRow('Location', widget.employee['location']),
                  ]),
                  const SizedBox(height: 24),
                  _buildDetailSection('Employment Details', [
                    _buildDetailRow('Department', widget.employee['department']),
                    _buildDetailRow('Designation', widget.employee['designation']),
                    _buildDetailRow('Join Date', widget.employee['joinDate']),
                    _buildDetailRow('Salary', '₹${widget.employee['salary']}'),
                  ]),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onEdit(widget.employee);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showPerformanceView(widget.employee);
                          },
                          icon: const Icon(Icons.analytics),
                          label: const Text('Performance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24), // Add bottom padding for better scrolling
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: mainTextColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: mainTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPerformanceView(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Performance - ${employee['name']}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                _buildPerformanceMetric('Attendance Rate', '95%', Colors.green),
                _buildPerformanceMetric('Task Completion', '88%', Colors.blue),
                _buildPerformanceMetric('Quality Score', '92%', Colors.orange),
                _buildPerformanceMetric('Team Collaboration', '90%', Colors.purple),
                const SizedBox(height: 20),
                const Text(
                  'Recent Achievements',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text('• Completed 15 tasks this month'),
                const Text('• Received 5 positive feedback'),
                const Text('• Helped 3 team members'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
