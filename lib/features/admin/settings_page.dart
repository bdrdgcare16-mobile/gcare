import 'package:flutter/material.dart';
import 'package:serv_app/features/admin/workdays_shift_page.dart';
import 'package:serv_app/features/admin/leave_page.dart';
import 'package:serv_app/features/admin/profile_page.dart';
import 'package:serv_app/features/admin/reason_master_page.dart';
import 'package:serv_app/features/admin/office_location_page.dart';

// Theme colors
const Color kPrimaryBackgroundTop    = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor             = Color(0xFF8C6EAF);
const Color kButtonColor             = Colors.white;
const Color kTextColor               = Colors.white;

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
        SnackBar(content: Text('$title clicked')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 40, // Account for padding
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                  children: [
                    TextSpan(
                      text: 'Settings',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Work Schedule tiles
              settingsTile(context, "Workdays & Shift Permission", Icons.calendar_today),
              const SizedBox(height: 8),
              settingsTile(context, "Leave Holiday", Icons.beach_access),

              const SizedBox(height: 20),

              // Corporate tiles
              settingsTile(context, "Profile", Icons.person_outline),
              const SizedBox(height: 8),
              settingsTile(context, "Office Location", Icons.location_on),

              const SizedBox(height: 20),

              // Admin tile
              settingsTile(context, "Reason Master", Icons.edit_note),

              const SizedBox(height: 40),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF655193),
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      );

  Widget settingsTile(BuildContext context, String title, IconData icon) => InkWell(
        onTap: () => _handleItemClick(context, title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF655193).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF655193)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      );
}
