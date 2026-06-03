
import 'package:flutter/material.dart';
import 'package:serv_app/features/admin/workdays_shift_page.dart';
import 'package:serv_app/features/admin/leave_page.dart';
import 'package:serv_app/features/admin/profile_page.dart';
import 'package:serv_app/features/admin/reason_master_page.dart';
import 'package:serv_app/features/admin/office_location_page.dart';

// Theme colors (unchanged)
const Color kPrimaryBackgroundTop    = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor             = Color(0xFF6A1B9A);
const Color kButtonColor             = Colors.white;
const Color kTextColor               = Colors.white;

// Design tokens — lavender/purple/white palette
const Color _kBg       = Color(0xFFF5F0FF);
const Color _kPurple   = Color(0xFF8C6EAF);
const Color _kDark     = Color(0xFF655193);
const Color _kCardBg   = Color(0xFFFFFFFF);

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _handleItemClick(BuildContext context, String title) {
    if (title == 'Workdays & Shift Permission') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkdaysShiftPage()));
    } else if (title == 'Leave Holiday') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LeavePage()));
    } else if (title == 'Profile') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyProfilePage()));
    } else if (title == 'Reason Master') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReasonMasterPage()));
    } else if (title == 'Office Location') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficeLocationPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title clicked'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  static const _sections = [
    _Section(
      label: 'Work Schedule',
      items: [
        _Item('Workdays & Shift Permission', Icons.calendar_today_rounded, Color(0xFFE8E0F5), Color(0xFF7B5EA7)),
        _Item('Leave Holiday',               Icons.beach_access_rounded,   Color(0xFFEDE7F6), Color(0xFF8C6EAF)),
      ],
    ),
    _Section(
      label: 'Corporate',
      items: [
        _Item('Profile',         Icons.person_outline_rounded,   Color(0xFFE6DEF0), Color(0xFF655193)),
        _Item('Office Location', Icons.location_on_rounded,      Color(0xFFD1C4E9), Color(0xFF9575CD)),
      ],
    ),
    _Section(
      label: 'Admin',
      items: [
        _Item('Reason Master', Icons.edit_note_rounded, Color(0xFFE8E0F5), Color(0xFF7B5EA7)),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background circles
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _kPurple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.settings_rounded, color: _kDark, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D1B4E),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  

                  const SizedBox(height: 28),

                  // Sections
                  ..._sections.map((section) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section label
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          section.label.toUpperCase(),
                          style: const TextStyle(
                            color: _kDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      // Items
                      ...section.items.map((item) => _SettingsTile(
                        item: item,
                        onTap: () => _handleItemClick(context, item.title),
                      )),
                      const SizedBox(height: 20),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ──
class _Section {
  final String label;
  final List<_Item> items;
  const _Section({required this.label, required this.items});
}

class _Item {
  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  const _Item(this.title, this.icon, this.iconBg, this.iconColor);
}

// ── Animated tile ──
class _SettingsTile extends StatefulWidget {
  final _Item item;
  final VoidCallback onTap;
  const _SettingsTile({required this.item, required this.onTap});

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile>
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
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - (_ctrl.value * 0.02),
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: item.iconColor.withOpacity(0.10),
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
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, size: 22, color: item.iconColor),
              ),
              const SizedBox(width: 14),

              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.1,
                  ),
                ),
              ),

              // Arrow chip
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: item.iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background circle ──
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