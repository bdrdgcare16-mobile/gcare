import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'login_screen.dart';
import 'services/user_session.dart';
import 'services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String email = 'user@example.com';
  String phone = '1234567890';
  String designation = 'Employee';
  String department = 'General';
  String gender = 'Not specified';
  String reportingTo = 'Manager';
  String dateOfJoining = 'Not specified';
  String employeeId = 'EMP000';
  String shiftTiming = '9:00 AM - 6:00 PM';
  bool _isLoading = false;
  String? _selectedImagePath;

  // Color scheme based on the new profile screen design
  static const Color primaryColor =  Color(0xFF223A5E); // Dark Blue
  static const Color backgroundColor = Color(0xFFF3F4F6); // Light background
  static const Color cardColor = Colors.white; // White card background
  static const Color mainTextColor = Color(0xFF1F2937); // Dark text
  static const Color secondaryTextColor = Color(0xFF6B7280); // Gray text
  static const Color accentColor = Color(0xFF3B82F6); // Light blue accent
  static const Color iconColor = Color(0xFF00BFAE); // Teal camera icon

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to get fresh data from API
      final authService = AuthService();
      final response = await authService.getProfile();
      
      if (response['user'] != null) {
        final user = response['user'];
        setState(() {
          email = user['email'] ?? 'user@example.com';
          phone = user['phoneNumber'] ?? 'Not specified';
          designation = user['designation'] ?? 'Employee';
          department = user['department'] ?? 'General';
          gender = user['gender'] ?? 'Not specified';
          reportingTo = user['reportingTo'] ?? 'Manager';
          dateOfJoining = user['dateOfJoining'] != null 
              ? DateTime.parse(user['dateOfJoining']).toString().split(' ')[0]
              : 'Not specified';
          employeeId = 'EMP${user['id']?.toString().padLeft(3, '0') ?? '000'}';
          shiftTiming = user['shiftTiming'] ?? '9:00 AM - 6:00 PM';
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Fallback to session data
      final user = UserSession.instance.currentUser;
      if (user != null) {
        setState(() {
          email = user['email'] ?? 'user@example.com';
          phone = user['phoneNumber'] ?? 'Not specified';
          designation = user['designation'] ?? 'Employee';
          department = user['department'] ?? 'General';
          gender = user['gender'] ?? 'Not specified';
          reportingTo = user['reportingTo'] ?? 'Manager';
          dateOfJoining = user['dateOfJoining'] != null 
              ? DateTime.parse(user['dateOfJoining']).toString().split(' ')[0]
              : 'Not specified';
          employeeId = 'EMP${user['id']?.toString().padLeft(3, '0') ?? '000'}';
          shiftTiming = user['shiftTiming'] ?? '9:00 AM - 6:00 PM';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editField(String title, String currentValue, ValueChanged<String> onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text;
              try {
                // Update via API
                final authService = AuthService();
                Map<String, dynamic> updateData = {};
                
                switch (title.toLowerCase()) {
                  case 'name':
                    updateData['name'] = newValue;
                    break;
                  case 'phone':
                  case 'phone number':
                    updateData['phoneNumber'] = newValue;
                    break;
                  case 'designation':
                    updateData['designation'] = newValue;
                    break;
                  case 'department':
                    updateData['department'] = newValue;
                    break;
                  case 'gender':
                    updateData['gender'] = newValue;
                    break;
                  case 'reporting to':
                    updateData['reportingTo'] = newValue;
                    break;
                  case 'shift timing':
                    updateData['shiftTiming'] = newValue;
                    break;
                }
                
                await authService.updateProfile(
                  name: updateData['name'],
                  phoneNumber: updateData['phoneNumber'],
                  designation: updateData['designation'],
                  department: updateData['department'],
                  gender: updateData['gender'],
                  reportingTo: updateData['reportingTo'],
                  shiftTiming: updateData['shiftTiming'],
                );
                onSave(newValue);
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title updated successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update $title. Please try again.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _getImage(ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _getImage(ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
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

  Future<void> _getImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.white,
      child: Center(
        child: Text(
          'N',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ),
    );
  }



  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              _showEditProfileDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
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
                                    // Profile Avatar
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _selectedImagePath != null
                                ? Image.file(
                                    File(_selectedImagePath!),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                                  )
                                : Image.asset(
                                    'assets/avatar.png',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFF00BFAE),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name and Title
                  Text(
                    UserSession.instance.userName ?? 'User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    designation,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    department,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            
            // Profile Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee Information Card
                  Card(
                    elevation: 8,
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.badge, color: iconColor, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Employee Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: mainTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Employee ID', employeeId, Icons.badge),
                          _buildInfoRow('Designation', designation, Icons.work),
                          _buildInfoRow('Department', department, Icons.apartment),
                          _buildInfoRow('Reporting To', reportingTo, Icons.person_outline),
                          _buildInfoRow('Date of Joining', dateOfJoining, Icons.calendar_today),
                          _buildInfoRow('Gender', gender, Icons.male),
                          _buildInfoRow('Shift Timing', shiftTiming, Icons.access_time),
                          _buildInfoRow('Status', 'Active', Icons.check_circle),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Contact Information Card
                  Card(
                    elevation: 8,
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.contact_mail, color: iconColor, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Contact Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: mainTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildEditableInfoRow('Email', email, Icons.email, () {
                            _editField('Email', email, (value) {
                              setState(() => email = value);
                            });
                          }),
                          const SizedBox(height: 12),
                          _buildEditableInfoRow('Contact', phone, Icons.phone_in_talk, () => _editField('Contact', phone, (value) {
                            setState(() {
                              phone = value;
                            });
                          })),
                          const SizedBox(height: 12),
                          _buildEditableInfoRow('Address', '123 Main Street, Anytown', Icons.home, () => _editField('Address', '123 Main Street, Anytown', (value) {
                            // Update address logic here
                          })),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Settings and Actions
                  Card(
                    elevation: 8,
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings, color: iconColor, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Settings & Actions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: mainTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Change Password
                          _buildActionCard(
                            icon: Icons.lock,
                            title: 'Change Password',
                            onTap: () => _showChangePasswordDialog(),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Multi Language
                          _buildActionCard(
                            icon: Icons.language,
                            title: 'Multi Language',
                            onTap: () => _showMultiLanguageDialog(),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Privacy Policy
                          _buildActionCard(
                            icon: Icons.privacy_tip,
                            title: 'Privacy Policy',
                            onTap: () => _showPrivacyPolicy(),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Terms & Conditions
                          _buildActionCard(
                            icon: Icons.description,
                            title: 'Terms & Conditions',
                            onTap: () => _showTermsConditions(),
                          ),
                          

                          
                          // Logout
                          _buildActionCard(
                            icon: Icons.logout,
                            title: 'Log Out',
                            onTap: _logout,
                            isLogout: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: mainTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, String value, IconData icon, VoidCallback onEdit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
              child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: mainTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              color: iconColor,
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : iconColor,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Color(0xFF1F2937),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isLogout ? Colors.red : Color(0xFF6B7280),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showMultiLanguageDialog() {
    String selectedLanguage = 'English';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Language'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: selectedLanguage,
                onChanged: (value) => setState(() => selectedLanguage = value!),
              ),
              RadioListTile<String>(
                title: const Text('हिंदी'),
                value: 'Hindi',
                groupValue: selectedLanguage,
                onChanged: (value) => setState(() => selectedLanguage = value!),
              ),
              RadioListTile<String>(
                title: const Text('தமிழ்'),
                value: 'Tamil',
                groupValue: selectedLanguage,
                onChanged: (value) => setState(() => selectedLanguage = value!),
              ),
              RadioListTile<String>(
                title: const Text('తెలుగు'),
                value: 'Telugu',
                groupValue: selectedLanguage,
                onChanged: (value) => setState(() => selectedLanguage = value!),
              ),
            ],
          ),
        ),
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
                  content: Text('Language changed to $selectedLanguage'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 12),
              Text(
                'This privacy policy describes how we collect, use, and protect your personal information when you use our employee management system.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'Information We Collect:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Personal identification information\n• Contact information\n• Employment details\n• Attendance records'),
              SizedBox(height: 12),
              Text(
                'How We Use Your Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• To manage your employment\n• To process attendance\n• To handle payroll\n• To communicate with you'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome to Serv!!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF223A5E)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please read these Terms and Conditions carefully before using our Attendance and Payroll App. By accessing or using the app, you agree to be bound by these Terms.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              
              _buildTermsSection('1. Acceptance of Terms', 'By registering, accessing, or using [App Name], you confirm that you are legally competent and authorized to enter into this agreement on behalf of yourself or your organization.'),
              
              _buildTermsSection('2. User Responsibilities', '• You agree to use the app only for lawful purposes.\n• You are responsible for maintaining the confidentiality of your login credentials.\n• Users must ensure accuracy in reporting attendance and personal information.'),
              
              _buildTermsSection('3. Attendance Tracking', '• The app collects employee attendance data through methods such as geolocation, QR scan, or biometric input (depending on your plan).\n• Employees must mark attendance within designated hours and at authorized locations.\n• Any fraudulent or false check-in attempts may lead to disciplinary action.'),
              
              _buildTermsSection('4. Payroll Management', '• Payroll is generated based on attendance records, leaves, overtime, and organizational rules.\n• The app calculates salaries, deductions, and bonuses as per the company\'s policy.\n• The company is responsible for reviewing and approving final payroll details before disbursing salaries.'),
              
              _buildTermsSection('5. Data Privacy and Security', '• We collect and store personal and organizational data to provide our services.\n• All user data is encrypted and handled according to our Privacy Policy.\n• We do not share your information with third parties without consent, unless required by law.'),
              
              _buildTermsSection('6. Modifications and Updates', 'We reserve the right to update or modify these Terms at any time. Continued use of the app after such changes constitutes your agreement to the new Terms.'),
              
              _buildTermsSection('7. Termination', '• We may suspend or terminate your account if you violate these Terms.\n• Upon termination, all rights granted to you will cease immediately.'),
              
              _buildTermsSection('8. Limitation of Liability', 'We are not liable for:\n• Any loss of data caused by user error or technical issues.\n• Payroll miscalculations resulting from incorrect attendance inputs.\n• Any indirect, incidental, or consequential damages arising from your use of the app.'),
              
              _buildTermsSection('9. Governing Law', 'These Terms shall be governed by and interpreted in accordance with the laws of India/TamilNadu.'),
              
              _buildTermsSection('10. Contact Us', 'For questions or support, contact us at:\n📧 Info@serv.co.in\n📞 9042525258'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF223A5E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: UserSession.instance.userName ?? 'User');
    final TextEditingController designationController = TextEditingController(text: designation);
    final TextEditingController departmentController = TextEditingController(text: department);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: designationController,
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Here you would typically save to backend
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
