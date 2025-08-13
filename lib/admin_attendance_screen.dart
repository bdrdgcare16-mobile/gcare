import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color accentColor = Color(0xFF00BFAE);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color cardColor = Colors.white;
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'All';
  String _searchText = '';

  final List<Map<String, dynamic>> _allAttendance = [
    {
      'name': 'Nishali Sharma',
      'id': 'EMP001',
      'email': 'nishali@company.com',
      'department': 'IT',
      'status': 'Present',
      'checkIn': '09:15 AM',
      'checkOut': '06:30 PM',
      'totalHours': '9h 15m',
      'location': 'Office',
    },
    {
      'name': 'Rahul Verma',
      'id': 'EMP002',
      'email': 'rahul@company.com',
      'department': 'Marketing',
      'status': 'Absent',
      'checkIn': '-',
      'checkOut': '-',
      'totalHours': '0h 0m',
      'location': '-',
    },
    {
      'name': 'Priya Singh',
      'id': 'EMP003',
      'email': 'priya@company.com',
      'department': 'HR',
      'status': 'Late',
      'checkIn': '10:30 AM',
      'checkOut': '06:45 PM',
      'totalHours': '8h 15m',
      'location': 'Office',
    },
    {
      'name': 'Amit Patel',
      'id': 'EMP004',
      'email': 'amit@company.com',
      'department': 'Finance',
      'status': 'Present',
      'checkIn': '08:45 AM',
      'checkOut': '06:15 PM',
      'totalHours': '9h 30m',
      'location': 'Office',
    },
    {
      'name': 'Sneha Reddy',
      'id': 'EMP005',
      'email': 'sneha@company.com',
      'department': 'IT',
      'status': 'Present',
      'checkIn': '09:00 AM',
      'checkOut': '06:00 PM',
      'totalHours': '9h 0m',
      'location': 'Office',
    },
    {
      'name': 'David Wilson',
      'id': 'EMP006',
      'email': 'david@company.com',
      'department': 'Sales',
      'status': 'Work From Home',
      'checkIn': '09:30 AM',
      'checkOut': '06:30 PM',
      'totalHours': '9h 0m',
      'location': 'Remote',
    },
  ];

  final Map<String, Color> statusColors = {
    'Present': Colors.green,
    'Absent': Colors.red,
    'Late': Colors.orange,
    'Work From Home': Colors.blue,
  };

  Map<String, dynamic> get _statistics {
    final totalEmployees = _allAttendance.length;
    final presentCount = _allAttendance.where((a) => a['status'] == 'Present').length;
    final absentCount = _allAttendance.where((a) => a['status'] == 'Absent').length;
    final lateCount = _allAttendance.where((a) => a['status'] == 'Late').length;
    final wfhCount = _allAttendance.where((a) => a['status'] == 'Work From Home').length;
    final attendanceRate = totalEmployees > 0 ? (presentCount / totalEmployees * 100).round() : 0;
    
    return {
      'total': totalEmployees,
      'present': presentCount,
      'absent': absentCount,
      'late': lateCount,
      'wfh': wfhCount,
      'attendanceRate': attendanceRate,
    };
  }

  List<Map<String, dynamic>> get _filteredAttendance {
    List<Map<String, dynamic>> filtered = _allAttendance.where((att) {
      final matchesStatus = _statusFilter == 'All' || att['status'] == _statusFilter;
      final matchesSearch = att['name']!.toLowerCase().contains(_searchText.toLowerCase()) ||
                           att['email']!.toLowerCase().contains(_searchText.toLowerCase()) ||
                           att['department']!.toLowerCase().contains(_searchText.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
    
    // Sort by name
    filtered.sort((a, b) => a['name'].compareTo(b['name']));
    
    return filtered;
  }

  void _exportCSV() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.download, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Export Attendance'),
          ],
        ),
        content: Text('Export attendance data for ${DateFormat('MMM d, yyyy').format(_selectedDate)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Attendance exported for ${DateFormat('MMM d, yyyy').format(_selectedDate)}'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetail(int index) async {
    final att = _filteredAttendance[index];
    final attIndex = _allAttendance.indexOf(att);
    String? newStatus = _allAttendance[attIndex]['status'];
    String? adminComments = _allAttendance[attIndex]['adminComments'] ?? '';
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: mainTextColor,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Details
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection('Employee Information', [
                          _buildDetailRow('Name', att['name']),
                          _buildDetailRow('Email', att['email']),
                          _buildDetailRow('Department', att['department']),
                          _buildDetailRow('Employee ID', att['id']),
                        ]),
                        const SizedBox(height: 16),
                        _buildDetailSection('Attendance Details', [
                          _buildDetailRow('Status', att['status']),
                          _buildDetailRow('Check In', att['checkIn']),
                          _buildDetailRow('Check Out', att['checkOut']),
                          _buildDetailRow('Total Hours', att['totalHours']),
                          _buildDetailRow('Location', att['location']),
                        ]),
                        const SizedBox(height: 16),
                        _buildDetailSection('Admin Action', [
                          Row(
                            children: [
                              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                              DropdownButton<String>(
                                value: newStatus,
                                items: ['Present', 'Absent', 'Late', 'Work From Home']
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    newStatus = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Admin Comments (Optional)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'Add any comments or notes...',
                            ),
                            maxLines: 3,
                            onChanged: (value) {
                              adminComments = value;
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primaryColor),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _allAttendance[attIndex]['status'] = newStatus!;
                                    if (adminComments!.isNotEmpty) {
                                      _allAttendance[attIndex]['adminComments'] = adminComments;
                                    }
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Attendance updated successfully!'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Save Changes'),
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
          ),
        );
      },
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
            fontSize: 16,
            color: mainTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: mainTextColor,
              ),
            ),
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
          'Attendance Management',
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
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _exportCSV,
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
                  'Daily Attendance Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor employee attendance and manage records',
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
                    _buildStatCard('Present', '${stats['present']}', Icons.check_circle, Colors.green),
                    _buildStatCard('Absent', '${stats['absent']}', Icons.cancel, Colors.red),
                    _buildStatCard('Rate', '${stats['attendanceRate']}%', Icons.trending_up, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          
          // Date selector and search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: mainTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, or department...',
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
          
          // Status filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusChip('All'),
                  const SizedBox(width: 8),
                  _statusChip('Present'),
                  const SizedBox(width: 8),
                  _statusChip('Absent'),
                  const SizedBox(width: 8),
                  _statusChip('Late'),
                  const SizedBox(width: 8),
                  _statusChip('Work From Home'),
                ],
              ),
            ),
          ),
          
          // Attendance list
          Expanded(
            child: _filteredAttendance.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 64,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No attendance records found',
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
                    itemCount: _filteredAttendance.length,
                    itemBuilder: (context, index) {
                      final att = _filteredAttendance[index];
                      return _buildAttendanceCard(att, index);
                    },
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

  Widget _buildAttendanceCard(Map<String, dynamic> att, int index) {
    final statusColor = statusColors[att['status']] ?? Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAttendanceDetail(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        att['name'][0],
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
                          att['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: mainTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${att['department']} • ${att['email']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      att['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Attendance details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.login, size: 16, color: secondaryTextColor),
                            const SizedBox(width: 8),
                            Text(
                              'Check In: ${att['checkIn']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.logout, size: 16, color: secondaryTextColor),
                            const SizedBox(width: 8),
                            Text(
                              'Check Out: ${att['checkOut']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        att['totalHours'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        att['location'],
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    final selected = _statusFilter == label;
    final colorMap = {
      'Present': Colors.green,
      'Absent': Colors.red,
      'Late': Colors.orange,
      'Work From Home': Colors.blue,
      'All': primaryColor,
    };
    final fillColor = colorMap[label] ?? Colors.grey;
    
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : fillColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: fillColor,
      backgroundColor: fillColor.withValues(alpha: 0.1),
      side: BorderSide.none,
      onSelected: (_) {
        setState(() {
          _statusFilter = label;
        });
      },
    );
  }
}
