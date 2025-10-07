import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'attendance_page.dart';
import 'profile_page.dart';
import 'package:serv_app/Pagesusers/myserv_page.dart';

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
    // Match Android bottom system bar to footer color (prevents white strip)
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: kAppBarColor,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    final size = MediaQuery.of(context).size;
    final isShort = size.height < 650; // small screens tuning

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false, // keep layout fixed
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---------- Fixed Header ----------
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.black),
                          SizedBox(width: 22),
                          Icon(Icons.warning, color: Colors.black),
                          SizedBox(width: 22),
                          Icon(Icons.person, color: Colors.black),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 3, color: kAppBarColor),

                // ---------- Main Content (no scroll) ----------
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      Text(
                        'Hello, $userName',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'With SERV, You Deserve the Best',
                        style: TextStyle(
                          color: kAppBarColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Illustration — responsive sizing to avoid overflow on small screens
                      SizedBox(
                        width: size.width * 0.55,
                        height: isShort ? 170 : 210,
                        child: Image.asset(
                            'assets/images/attendance-management.png'),
                      ),

                      // Push tiles up a bit and keep them visible on small screens
                      SizedBox(height: isShort ? 10 : 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _HomeTile(
                              icon: Icons.calendar_month,
                              label: 'Attendance',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceScreen(
                                        employeeDocId: employeeDocId),
                                  ),
                                );
                              },
                            ),
                            _HomeTile(
                              icon: Icons.handshake,
                              label: 'My Serv',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyServPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Small spacer to keep distance from footer
                      SizedBox(height: isShort ? 6 : 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ---------- Shorter Footer ----------
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 48, // reduced height
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
      ),
    );
  }
}

// ---------- Small square tile widget ----------
class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final tileW = size.width * 0.33; // responsive width
    final tileH = size.height < 650 ? 96.0 : 106.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: tileW,
        height: tileH,
        decoration: BoxDecoration(
          color: kPrimaryBackgroundBottom,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5.0,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 46, color: kAppBarColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Footer item ----------
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
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 86,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kTextColor, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
