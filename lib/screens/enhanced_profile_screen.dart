import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/user_session.dart';

class EnhancedProfileScreen extends StatefulWidget {
  @override
  _EnhancedProfileScreenState createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic>? _userData;
  
  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _reportingToController = TextEditingController();
  
  String _selectedGender = 'Female';
  String _selectedShift = '9:00 AM - 6:00 PM';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await UserService.getCurrentUser();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
      
      // Initialize controllers
      _nameController.text = userData['name'] ?? '';
      _phoneController.text = userData['phoneNumber'] ?? '';
      _designationController.text = userData['designation'] ?? '';
      _departmentController.text = userData['department'] ?? '';
      _reportingToController.text = userData['reportingTo'] ?? '';
      _selectedGender = userData['gender'] ?? 'Female';
      _selectedShift = userData['shiftTiming'] ?? '9:00 AM - 6:00 PM';
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await UserService.updateProfile(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        designation: _designationController.text,
        department: _departmentController.text,
        gender: _selectedGender,
        shiftTiming: _selectedShift,
        reportingTo: _reportingToController.text,
      );

      // Reload user data
      await _loadUserData();
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileCard() {
    if (_userData == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No profile data available'),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  onPressed: _isLoading ? null : () {
                    if (_isEditing) {
                      _saveProfile();
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('Name', _nameController, 'Enter your full name'),
            _buildInfoRow('Phone', _phoneController, 'Enter phone number'),
            _buildInfoRow('Designation', _designationController, 'Enter designation'),
            _buildInfoRow('Department', _departmentController, 'Enter department'),
            _buildInfoRow('Reporting To', _reportingToController, 'Enter reporting manager'),
            _buildDropdownRow('Gender', _selectedGender, ['Male', 'Female', 'Other'], (value) {
              setState(() {
                _selectedGender = value!;
              });
            }),
            _buildDropdownRow('Shift Timing', _selectedShift, [
              '9:00 AM - 6:00 PM',
              '10:00 AM - 7:00 PM',
              '8:00 AM - 5:00 PM',
              'Flexible'
            ], (value) {
              setState(() {
                _selectedShift = value!;
              });
            }),
            _buildReadOnlyRow('Email', _userData!['email'] ?? 'N/A'),
            _buildReadOnlyRow('Role', _userData!['role'] ?? 'N/A'),
            _buildReadOnlyRow('Date of Joining', 
              _userData!['dateOfJoining'] != null 
                ? DateTime.parse(_userData!['dateOfJoining']).toString().split(' ')[0]
                : 'N/A'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                : Text(controller.text.isEmpty ? 'Not specified' : controller.text),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: _isEditing
                ? DropdownButtonFormField<String>(
                    value: value,
                    items: options.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Picture Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,
                          child: Text(
                            _userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          _userData?['name'] ?? 'User Name',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userData?['designation'] ?? 'Designation',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildProfileCard(),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _reportingToController.dispose();
    super.dispose();
  }
} 