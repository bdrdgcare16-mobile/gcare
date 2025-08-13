import 'package:flutter/material.dart';
import 'employee_profile_screen.dart';

class TestEmployeeProfile extends StatelessWidget {
  const TestEmployeeProfile({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample employee data for testing
    final sampleEmployee = {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Employee Profile'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Employee Profile Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Click the button below to view the new employee profile screen',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeProfileScreen(
                      employee: sampleEmployee,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Employee Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Features included:\n• Modern purple design\n• Employee avatar with initials\n• Contact information\n• Menu options (Change Password, Multi Language, etc.)\n• Logout functionality',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
} 