import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminLeaveRequestScreen extends StatefulWidget {
  const AdminLeaveRequestScreen({super.key});

  @override
  State<AdminLeaveRequestScreen> createState() => _AdminLeaveRequestScreenState();
}

class _AdminLeaveRequestScreenState extends State<AdminLeaveRequestScreen> {
  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color accentColor = Color(0xFF00BFAE);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color cardColor = Colors.white;
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  final List<Map<String, dynamic>> _allRequests = [
    {
      'id': 'LR001',
      'name': 'Nishali Sharma',
      'email': 'nishali@company.com',
      'department': 'IT',
      'type': 'Sick Leave',
      'from': '2024-08-01',
      'to': '2024-08-03',
      'days': 3,
      'status': 'Pending',
      'reason': 'Fever and cold symptoms. Doctor advised complete rest for recovery.',
      'comments': 'Doctor advised rest.',
      'proof': '', // No proof
      'submittedAt': '2024-07-30 10:30:00',
    },
    {
      'id': 'LR002',
      'name': 'Rahul Verma',
      'email': 'rahul@company.com',
      'department': 'Marketing',
      'type': 'Casual Leave',
      'from': '2024-08-05',
      'to': '2024-08-06',
      'days': 2,
      'status': 'Approved',
      'reason': 'Family function - cousin\'s wedding ceremony',
      'comments': 'Need to travel out of town for the event.',
      'proof': 'https://via.placeholder.com/80',
      'submittedAt': '2024-07-28 14:15:00',
    },
    {
      'id': 'LR003',
      'name': 'Priya Singh',
      'email': 'priya@company.com',
      'department': 'HR',
      'type': 'Earned Leave',
      'from': '2024-08-10',
      'to': '2024-08-12',
      'days': 3,
      'status': 'Rejected',
      'reason': 'Annual family vacation to Goa',
      'comments': 'Annual trip planned with family.',
      'proof': '',
      'submittedAt': '2024-07-25 09:45:00',
    },
    {
      'id': 'LR004',
      'name': 'Amit Patel',
      'email': 'amit@company.com',
      'department': 'Finance',
      'type': 'Work From Home',
      'from': '2024-08-07',
      'to': '2024-08-07',
      'days': 1,
      'status': 'Approved',
      'reason': 'Home renovation work - need to supervise contractors',
      'comments': 'Can work remotely and attend all meetings.',
      'proof': '',
      'submittedAt': '2024-07-29 16:20:00',
    },
    {
      'id': 'LR005',
      'name': 'Sneha Reddy',
      'email': 'sneha@company.com',
      'department': 'IT',
      'type': 'Sick Leave',
      'from': '2024-08-02',
      'to': '2024-08-02',
      'days': 1,
      'status': 'Pending',
      'reason': 'Severe headache and migraine',
      'comments': 'Will provide medical certificate.',
      'proof': '',
      'submittedAt': '2024-07-31 08:10:00',
    },
  ];

  final statusColors = {
    'Pending': Colors.orange,
    'Approved': Colors.green,
    'Rejected': Colors.red,
  };

  String _searchText = '';
  String _statusFilter = 'All';
  String _sortOption = 'Date (Latest)';

  Map<String, dynamic> get _statistics {
    final totalRequests = _allRequests.length;
    final pendingRequests = _allRequests.where((req) => req['status'] == 'Pending').length;
    final approvedRequests = _allRequests.where((req) => req['status'] == 'Approved').length;
    final rejectedRequests = _allRequests.where((req) => req['status'] == 'Rejected').length;
    
    return {
      'total': totalRequests,
      'pending': pendingRequests,
      'approved': approvedRequests,
      'rejected': rejectedRequests,
    };
  }

  List<Map<String, dynamic>> get _filteredRequests {
    List<Map<String, dynamic>> filtered = _allRequests.where((req) {
      final matchesStatus = _statusFilter == 'All' || req['status'] == _statusFilter;
      final matchesSearch = req['name']!.toLowerCase().contains(_searchText.toLowerCase()) ||
                           req['email']!.toLowerCase().contains(_searchText.toLowerCase()) ||
                           req['department']!.toLowerCase().contains(_searchText.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
    
    // Sort
    if (_sortOption == 'Date (Latest)') {
      filtered.sort((a, b) => b['submittedAt'].compareTo(a['submittedAt']));
    } else if (_sortOption == 'Date (Oldest)') {
      filtered.sort((a, b) => a['submittedAt'].compareTo(b['submittedAt']));
    } else if (_sortOption == 'Employee Name (A-Z)') {
      filtered.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (_sortOption == 'Department') {
      filtered.sort((a, b) => a['department'].compareTo(b['department']));
    }
    
    return filtered;
  }

  void _showRequestDetails(int index) async {
    final filtered = _filteredRequests;
    final reqIndex = _allRequests.indexOf(filtered[index]);
    String? newStatus = _allRequests[reqIndex]['status'];
    String? adminComments = _allRequests[reqIndex]['adminComments'] ?? '';
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final req = _allRequests[reqIndex];
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
                        Icons.assignment,
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
                            'Leave Request Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: mainTextColor,
                            ),
                          ),
                          Text(
                            'ID: ${req['id']}',
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
                          _buildDetailRow('Name', req['name']),
                          _buildDetailRow('Email', req['email']),
                          _buildDetailRow('Department', req['department']),
                        ]),
                        const SizedBox(height: 16),
                        _buildDetailSection('Leave Details', [
                          _buildDetailRow('Type', req['type']),
                          _buildDetailRow('From', _formatDate(req['from'])),
                          _buildDetailRow('To', _formatDate(req['to'])),
                          _buildDetailRow('Days', '${req['days']} days'),
                          _buildDetailRow('Reason', req['reason']),
                          _buildDetailRow('Comments', req['comments'] ?? '-'),
                        ]),
                        const SizedBox(height: 16),
                        _buildDetailSection('Proof Document', [
                          req['proof'] != null && req['proof']!.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.attach_file, color: primaryColor),
                                      const SizedBox(width: 8),
                                      Text('Document attached'),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.image_not_supported, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text('No document attached', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                        ]),
                        const SizedBox(height: 16),
                        _buildDetailSection('Admin Action', [
                          Row(
                            children: [
                              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                              DropdownButton<String>(
                                value: newStatus,
                                items: ['Pending', 'Approved', 'Rejected']
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
                                    _allRequests[reqIndex]['status'] = newStatus!;
                                    if (adminComments!.isNotEmpty) {
                                      _allRequests[reqIndex]['adminComments'] = adminComments;
                                    }
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Leave request ${newStatus!.toLowerCase()} successfully!'),
                                      backgroundColor: statusColors[newStatus!],
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ),
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
            width: 80,
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statistics;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Leave Requests',
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
                  'Leave Request Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review and manage employee leave requests',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', '${stats['total']}', Icons.assignment, Colors.blue),
                    _buildStatCard('Pending', '${stats['pending']}', Icons.pending, Colors.orange),
                    _buildStatCard('Approved', '${stats['approved']}', Icons.check_circle, Colors.green),
                    _buildStatCard('Rejected', '${stats['rejected']}', Icons.cancel, Colors.red),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusChip('All'),
                  const SizedBox(width: 8),
                  _statusChip('Pending'),
                  const SizedBox(width: 8),
                  _statusChip('Approved'),
                  const SizedBox(width: 8),
                  _statusChip('Rejected'),
                ],
              ),
            ),
          ),
          
          // Requests list
          Expanded(
            child: _filteredRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No leave requests found',
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
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) {
                      final req = _filteredRequests[index];
                      return _buildRequestCard(req, index);
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

  Widget _buildRequestCard(Map<String, dynamic> req, int index) {
    final statusColor = statusColors[req['status']] ?? Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRequestDetails(index),
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
                        req['name'][0],
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
                          req['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: mainTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${req['department']} • ${req['email']}',
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
                      req['status'],
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
              
              // Leave details
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: secondaryTextColor),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(req['from'])} - ${_formatDate(req['to'])}',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: secondaryTextColor),
                  const SizedBox(width: 8),
                  Text(
                    '${req['days']} days',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Leave type and reason
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: secondaryTextColor),
                  const SizedBox(width: 8),
                  Text(
                    req['type'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: mainTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Text(
                req['reason'],
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
      'Pending': Colors.orange,
      'Approved': Colors.green,
      'Rejected': Colors.red,
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sort Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Date (Latest)'),
              value: 'Date (Latest)',
              groupValue: _sortOption,
              onChanged: (value) {
                setState(() {
                  _sortOption = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Date (Oldest)'),
              value: 'Date (Oldest)',
              groupValue: _sortOption,
              onChanged: (value) {
                setState(() {
                  _sortOption = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Employee Name (A-Z)'),
              value: 'Employee Name (A-Z)',
              groupValue: _sortOption,
              onChanged: (value) {
                setState(() {
                  _sortOption = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Department'),
              value: 'Department',
              groupValue: _sortOption,
              onChanged: (value) {
                setState(() {
                  _sortOption = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
