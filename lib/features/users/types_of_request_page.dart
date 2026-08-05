import 'package:flutter/material.dart';
import 'package:serv_app/features/users/apply_leave_form_page.dart';
import 'request_leave_page.dart';
import 'permission_time_page.dart';
import 'over_time_page.dart';
import 'half_day_time_page.dart';

// Theme colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;
const Color kIconColor = Color(0xFF3D0066);

// Design system colors
const Color kPageBackground = Color(0xFFF5F0FF);
const Color kCardColor = Colors.white;
const Color kPrimaryPurple = Color(0xFF8C6EAF);
const Color kDarkPurple = Color(0xFF655193);

class TypeOfRequestPage extends StatelessWidget {
  const TypeOfRequestPage({super.key});

  final List<Map<String, dynamic>> requestTypes = const [
    {
      'title': 'Apply for leave',
      'icon': Icons.calendar_today,
      'badgeColor': Color(0xFFE8E0F5),
    },
    {
      'title': 'Request permission',
      'icon': Icons.access_time,
      'badgeColor': Color(0xFFEDE7F6),
    },
    {
      'title': 'Log extra hours',
      'icon': Icons.timer,
      'badgeColor': Color(0xFFE6DEF0),
    },
    {
      'title': 'Half day request',
      'icon': Icons.timelapse,
      'badgeColor': Color(0xFFD1C4E9),
    },
    {
      'title': 'Compensatory off',
      'icon': Icons.sync_alt,
      'badgeColor': Color(0xFFE8E0F5),
    },
  ];

  // ─── ALL NAVIGATION LOGIC UNCHANGED ───────────────────────────────────────
  void _handleNavigation(BuildContext context, String title) {
    if (title == 'Apply for leave') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const RequestLeavePage(),
      );
    } else if (title == 'Request permission') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PermissionTimePage(isPopup: false),
      );
    } else if (title == 'Log extra hours') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const OverTimePage(isPopup: false),
      );
    } else if (title == 'Half day request') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const HalfDayTimePage(
          isPopup: false,
          totalHalfDays: 8,
          takenHalfDays: 4,
          status: "Available",
        ),
      );
    } else if (title == 'Compensatory off') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ApplyHalfDayForm(),
      );
    }
  }
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBackground,
      // ── AppBar (restored) ──────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text(
          "Type Of Requests",
          style: TextStyle(fontSize: 18, color: kTextColor, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kAppBarColor,
        centerTitle: false,
        iconTheme: const IconThemeData(color: kTextColor),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── Floating purple decorative circles ────────────────────────────
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryPurple.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kDarkPurple.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryPurple.withOpacity(0.07),
              ),
            ),
          ),

          // ── Grid ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: requestTypes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final item = requestTypes[index];
                return _RequestCard(
                  title: item['title'] as String,
    
                  icon: item['icon'] as IconData,
                  badgeColor: item['badgeColor'] as Color,
                  onTap: () => _handleNavigation(context, item['title']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stateful card with press-to-scale animation ───────────────────────────────
class _RequestCard extends StatefulWidget {
  final String title;
 
  final IconData icon;
  final Color badgeColor;
  final VoidCallback onTap;

  const _RequestCard({
    required this.title,
   
    required this.icon,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.95);
  void _onTapUp(TapUpDetails _) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kDarkPurple.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // ── Center everything in the card ──────────────────────────────
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon badge — centered ──────────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      kIconColor,
                      BlendMode.srcIn,
                    ),
                    child: Icon(widget.icon, size: 26),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ── Title — centered ───────────────────────────────────────
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kDarkPurple,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              // ── Subtitle — centered ────────────────────────────────────
              
            ],
          ),
        ),
      ),
    );
  }
}