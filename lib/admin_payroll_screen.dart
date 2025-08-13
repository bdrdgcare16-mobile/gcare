import 'package:flutter/material.dart';
import 'admin_payroll_detail_screen.dart';

class AdminPayrollScreen extends StatefulWidget {
  @override
  _AdminPayrollScreenState createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  // Example data
  List<Map<String, dynamic>> employees = [
    {
      'id': 'EMP001',
      'name': 'Alice Johnson',
      'department': 'HR',
      'position': 'HR Manager',
      'netPay': 50000,
      'grossPay': 60000,
      'deductions': 10000,
      'pending': false,
      'status': 'Paid',
      'paymentMethod': 'Bank Transfer',
    },
    {
      'id': 'EMP002',
      'name': 'Bob Smith',
      'department': 'IT',
      'position': 'Senior Developer',
      'netPay': 48000,
      'grossPay': 55000,
      'deductions': 7000,
      'pending': true,
      'status': 'Pending',
      'paymentMethod': 'Bank Transfer',
    },
    {
      'id': 'EMP003',
      'name': 'Carol Davis',
      'department': 'Finance',
      'position': 'Accountant',
      'netPay': 42000,
      'grossPay': 48000,
      'deductions': 6000,
      'pending': false,
      'status': 'Paid',
      'paymentMethod': 'Bank Transfer',
    },
    {
      'id': 'EMP004',
      'name': 'David Wilson',
      'department': 'Marketing',
      'position': 'Marketing Specialist',
      'netPay': 38000,
      'grossPay': 43000,
      'deductions': 5000,
      'pending': false,
      'status': 'Paid',
      'paymentMethod': 'Bank Transfer',
    },
    {
      'id': 'EMP005',
      'name': 'Eva Brown',
      'department': 'IT',
      'position': 'UI/UX Designer',
      'netPay': 45000,
      'grossPay': 52000,
      'deductions': 7000,
      'pending': true,
      'status': 'Pending',
      'paymentMethod': 'Bank Transfer',
    },
  ];

  List<Map<String, dynamic>> filteredEmployees = [];
  String? _selectedDepartment;
  String _sortBy = 'Name';
  String _selectedStatus = 'All';

  List<String> get _departments {
    final depts = employees.map((e) => e['department'] as String).toSet().toList();
    depts.sort();
    return depts;
  }

  Map<String, dynamic> get _statistics {
    final totalEmployees = employees.length;
    final paidEmployees = employees.where((e) => e['status'] == 'Paid').length;
    final pendingEmployees = employees.where((e) => e['status'] == 'Pending').length;
    final totalPayroll = employees.fold<double>(0, (sum, e) => sum + (e['netPay'] as int));
    
    return {
      'totalEmployees': totalEmployees,
      'paidEmployees': paidEmployees,
      'pendingEmployees': pendingEmployees,
      'totalPayroll': totalPayroll,
    };
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = List.from(employees);
    
    // Filter by department
    if (_selectedDepartment != null && _selectedDepartment!.isNotEmpty) {
      temp = temp.where((e) => e['department'] == _selectedDepartment).toList();
    }
    
    // Filter by status
    if (_selectedStatus != 'All') {
      temp = temp.where((e) => e['status'] == _selectedStatus).toList();
    }
    
    // Sort
    if (_sortBy == 'Name') {
      temp.sort((a, b) => a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
    } else if (_sortBy == 'Net Pay') {
      temp.sort((b, a) => a['netPay'].compareTo(b['netPay']));
    } else if (_sortBy == 'Department') {
      temp.sort((a, b) => a['department'].toLowerCase().compareTo(b['department'].toLowerCase()));
    }
    
    setState(() {
      filteredEmployees = temp;
    });
  }

  @override
  void initState() {
    super.initState();
    filteredEmployees = employees;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      filteredEmployees = employees
          .where((emp) =>
              emp['name']
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              emp['id']
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statistics;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Payroll Management',
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
                  'Payroll Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage employee salaries and payments',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', '${stats['totalEmployees']}', Icons.people, Colors.blue),
                    _buildStatCard('Paid', '${stats['paidEmployees']}', Icons.check_circle, Colors.green),
                    _buildStatCard('Pending', '${stats['pendingEmployees']}', Icons.pending, Colors.orange),
                    _buildStatCard('Total Payroll', '₹${(stats['totalPayroll'] / 1000).toStringAsFixed(0)}K', Icons.account_balance_wallet, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // Employees list
          Expanded(
            child: filteredEmployees.isEmpty
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];
                      return _buildEmployeeCard(emp);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
        onPressed: () {
          _showAddEmployeeDialog();
        },
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
    final statusColor = emp['status'] == 'Paid' ? Colors.green : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPayrollDetailScreen(employee: emp),
            ),
          );
        },
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
                      '${emp['position']} • ${emp['department']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${emp['id']}',
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
                    '₹${emp['netPay']}',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emp['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
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
              value: _selectedDepartment,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Departments')),
                ..._departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Status filter
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'All', child: Text('All Status')),
                const DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                const DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                  _applyFilters();
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
                const DropdownMenuItem(value: 'Net Pay', child: Text('Net Pay')),
                const DropdownMenuItem(value: 'Department', child: Text('Department')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _applyFilters();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDepartment = null;
                _selectedStatus = 'All';
                _sortBy = 'Name';
                filteredEmployees = employees;
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

  void _showAddEmployeeDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _idController = TextEditingController();
    final _deptController = TextEditingController();
    final _positionController = TextEditingController();
    final _netPayController = TextEditingController();
    final _grossPayController = TextEditingController();
    String _selectedStatus = 'Pending';

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
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter ID' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deptController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter department' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter position' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _grossPayController,
                  decoration: const InputDecoration(
                    labelText: 'Gross Pay',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Enter gross pay' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _netPayController,
                  decoration: const InputDecoration(
                    labelText: 'Net Pay',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Enter net pay' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    const DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  ],
                  onChanged: (value) {
                    _selectedStatus = value!;
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
                final grossPay = int.tryParse(_grossPayController.text) ?? 0;
                final netPay = int.tryParse(_netPayController.text) ?? 0;
                final deductions = grossPay - netPay;
                
                setState(() {
                  employees.add({
                    'id': _idController.text,
                    'name': _nameController.text,
                    'department': _deptController.text,
                    'position': _positionController.text,
                    'netPay': netPay,
                    'grossPay': grossPay,
                    'deductions': deductions,
                    'pending': _selectedStatus == 'Pending',
                    'status': _selectedStatus,
                    'paymentMethod': 'Bank Transfer',
                  });
                  filteredEmployees = employees;
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
}