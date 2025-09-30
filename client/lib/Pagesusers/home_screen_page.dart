import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'attendance_page.dart';
import 'profile_page.dart';
import 'package:serv_app/Pagesusers/myserv_page.dart';
import 'package:serv_app/common/app_scaffold.dart';

// App Colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class HomeScreen extends StatelessWidget {
  final String userName;
  final String employeeDocId;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.employeeDocId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Top bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SERV',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 23,
                                  color: kAppBarColor,
                                ),
                              ),
                              // ⬇️ Icons with clear location symbol + margins (boxed badges)
                              Row(
                                children: const [
                                  _IconBadge(icon: Icons.location_on),
                                  SizedBox(width: 12),
                                  _IconBadge(icon: Icons.warning),
                                  SizedBox(width: 12),
                                  _IconBadge(icon: Icons.person),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(height: 3, color: kAppBarColor),

                        // ↓ Added extra space (0.5cm ~ 12px)
                        const SizedBox(height: 12),

                        Center(
                          child: Text(
                            'Hello, $userName',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Center(
                          child: Text(
                            'With SERV, You Deserve the Best',
                            style: TextStyle(
                              color: kAppBarColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          height: 250,
                          width: 250,
                          child: Image.asset(
                              'assets/images/attendance-management.png'),
                        ),

                        // ↓ Added extra space before buttons (1cm ~ 24px)
                        const SizedBox(height: 24),

                        // Attendance and My Serv buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Attendance
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AttendanceScreen(
                                        employeeDocId: employeeDocId,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: kPrimaryBackgroundBottom,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 5,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.calendar_month,
                                          size: 50, color: kAppBarColor),
                                      SizedBox(height: 8),
                                      Text('Attendance',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black)),
                                    ],
                                  ),
                                ),
                              ),

                              // My Serv
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const MyServPage()),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: kPrimaryBackgroundBottom,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 5,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.handshake,
                                          size: 50, color: kAppBarColor),
                                      SizedBox(height: 8),
                                      Text('My Serv',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),

      // Bottom bar
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.only(
          bottom: math.max(
            16.0,
            MediaQuery.of(context).viewPadding.bottom + 8.0,
          ),
        ),
        child: Container(
          height: 50,
          decoration: const BoxDecoration(color: kAppBarColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const BottomNavItem(icon: Icons.home, label: 'Home'),
              BottomNavItem(
                icon: Icons.person,
                label: 'Profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(userData: {
                        'name': userName,
                        'id': employeeDocId,
                      }),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small boxed badge for top-right icons (adds margin + visible symbol)
class _IconBadge extends StatelessWidget {
  final IconData icon;
  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kAppBarColor.withOpacity(0.6), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.black87, size: 20),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: kTextColor, size: 18),
          Text(
            label,
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
