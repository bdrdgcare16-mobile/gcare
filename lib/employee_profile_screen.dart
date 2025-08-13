import 'package:flutter/material.dart';
import 'login_screen.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? employee;
  
  const EmployeeProfileScreen({super.key, this.employee});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  // Color scheme based on the image
  static const Color primaryColor = Color(0xFF3B82F6); // Blue
  static const Color lightPurple = Color(0xFFF3F4F6); // Light background
  static const Color cardColor = Colors.white;
  static const Color mainTextColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color accentColor = Color(0xFF60A5FA);

  // Sample employee data (in real app, this would come from API/database)
  late Map<String, dynamic> employeeData;

  @override
  void initState() {
    super.initState();
    employeeData = widget.employee ?? {
      'name': 'Divya D V',
      'id': 'AI2025',
      'role': 'Student',
      'email': 'divya.ai@gmail.com',
      'phone': '9876543210',
      'department': 'AI Department',
      'designation': 'Student',
      'joinDate': '2024-01-15',
      'status': 'Active',
    };
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
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terms and Conditions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 12),
              Text(
                'By using this employee management system, you agree to the following terms and conditions:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '1. You will use the system responsibly and ethically.',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '2. You will maintain the confidentiality of your login credentials.',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '3. You will not share sensitive information with unauthorized persons.',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '4. You will report any security concerns immediately.',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '5. The company reserves the right to modify these terms at any time.',
                style: TextStyle(fontSize: 14),
              ),
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

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurple,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Employee Profile',
          style: TextStyle(
            color: mainTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        employeeData['name'][0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // User Details
                  Text(
                    employeeData['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employeeData['id']} | ${employeeData['role']}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employeeData['email'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employeeData['phone'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Menu Options Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Change Password
                  _buildMenuCard(
                    icon: Icons.lock,
                    title: 'Change Password',
                    onTap: _showChangePasswordDialog,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Multi Language
                  _buildMenuCard(
                    icon: Icons.language,
                    title: 'Multi Language',
                    onTap: _showMultiLanguageDialog,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Privacy Policy
                  _buildMenuCard(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: _showPrivacyPolicy,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Terms & Conditions
                  _buildMenuCard(
                    icon: Icons.description,
                    title: 'Terms & Conditions',
                    onTap: _showTermsConditions,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Logout
                  _buildMenuCard(
                    icon: Icons.logout,
                    title: 'Log Out',
                    onTap: _logout,
                    isLogout: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : primaryColor,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : mainTextColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isLogout ? Colors.red : secondaryTextColor,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
} 