import 'package:flutter/material.dart';
import 'package:serv_app/features/users/my_attendance_page.dart';
import 'package:serv_app/features/users/my_track_page.dart';
import 'package:serv_app/features/users/my_request_page.dart';
import 'package:serv_app/features/users/my_tasks_page.dart';
import 'package:serv_app/features/users/events_page.dart';
import 'package:serv_app/features/users/my_rewards_page.dart';
import 'package:serv_app/features/users/types_of_request_page.dart';
import 'package:serv_app/features/users/employee_payslip_page.dart';

// Theme colors (unchanged)
const Color kPrimaryBackgroundTop    = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor             = Color(0xFF8C6EAF);
const Color kButtonColor             = Color(0xFF655193);
const Color kTextColor               = Colors.white;
const Color kIconColor               = Color(0xFF3D0066);

// Design tokens
const Color _kBg       = Color(0xFFF5F0FF);
const Color _kPurple   = Color(0xFF8C6EAF);
const Color _kDark     = Color(0xFF655193);

class MyServPage extends StatelessWidget {
  const MyServPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_ServItemData> items = [
      _ServItemData(
        imagePath: 'assets/images/attendance.png',
        label: 'Attendance',
        iconBg: const Color(0xFFE8E0F5),
        onTap: () {
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAttendancePage()));
        },
      ),
      _ServItemData(
        imagePath: 'assets/images/my-track.png',
        label: 'My Track',
        iconBg: const Color(0xFFEDE7F6),
        onTap: () {
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTrackPage()));
        },
      ),
      _ServItemData(
        imagePath: 'assets/images/myrequest.png',
        label: 'My Request',
        iconBg: const Color(0xFFE6DEF0),
        onTap: () {
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRequestPage()));
        },
      ),
      _ServItemData(
        imagePath: 'assets/images/type_of_request3.png',
        label: 'Type of Request',
        iconBg: const Color(0xFFD1C4E9),
        onTap: () {
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => TypeOfRequestPage()));
        },
      ),
      _ServItemData(
        imagePath: 'assets/images/task5.png',
        label: 'My Task',
        iconBg: const Color(0xFFE8E0F5),
        onTap: () {
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  MyTasksPage()));
        },
      ),
      _ServItemData(
        imagePath: 'assets/images/event_icon.png',
        label: 'Events Update',
        iconBg: const Color(0xFFEDE7F6),
        onTap: () {
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserEventUpdatesPage()));
        },
      ),
      _ServItemData(
        imagePath: 'assets/images/rewards1.png',
        label: 'Rewards',
        iconBg: const Color(0xFFE6DEF0),
        onTap: () {
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserRewardsPage()));
        },
      ),
      _ServItemData(
        imagePath: 'assets/images/reports.png',
        label: 'Payslip',
        iconBg: const Color(0xFFE8E0F5),
        onTap: () {
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeePayslipPage()));
        },
      ),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      // ── AppBar added ──────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text(
          "My SERV",
          style: TextStyle(
            fontSize: 18,
            color: kTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: kAppBarColor,
        centerTitle: false,
        iconTheme: const IconThemeData(color: kTextColor),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background circles (unchanged)
          Positioned(
            top: -60, right: -40,
            child: _Circle(size: 200, color: _kPurple.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 60, left: -50,
            child: _Circle(size: 180, color: _kDark.withOpacity(0.07)),
          ),
          Positioned(
            top: 220, left: -30,
            child: _Circle(size: 130, color: const Color(0xFFD1C4E9).withOpacity(0.5)),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _ServCard(
                          imagePath: item.imagePath,
                          label: item.label,
                          iconBg: item.iconBg,
                          onTap: item.onTap,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model (unchanged) ──
class _ServItemData {
  final String imagePath;
  final String label;
  final Color iconBg;
  final VoidCallback onTap;

  _ServItemData({
    required this.imagePath,
    required this.label,
    required this.iconBg,
    required this.onTap,
  });
}

// ── Animated card (unchanged) ──
class _ServCard extends StatefulWidget {
  final String imagePath;
  final String label;
  final Color iconBg;
  final VoidCallback? onTap;

  const _ServCard({
    required this.imagePath,
    required this.label,
    required this.iconBg,
    this.onTap,
  });

  @override
  State<_ServCard> createState() => _ServCardState();
}

class _ServCardState extends State<_ServCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - (_ctrl.value * 0.03),
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon badge
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        kIconColor,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D1B4E),
                    letterSpacing: -0.1,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Background circle (unchanged) ──
class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}