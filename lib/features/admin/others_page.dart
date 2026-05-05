import 'package:flutter/material.dart';
import 'my_task_page.dart';
import 'rewards_page.dart';
import 'feedback_page.dart';
import 'event_update_page.dart';

// ✅ Your color constants
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class OthersPage extends StatelessWidget {
  const OthersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: ListView(
              children: [
                _buildPremiumCard(
                  context,
                  'My Tasks',
                  Icons.checklist,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyTasksPage()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildPremiumCard(
                  context,
                  'Rewards',
                  Icons.emoji_events,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RewardsPage()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildPremiumCard(
                  context,
                  'Feedback',
                  Icons.message,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeedbackPage(employeeName: '', employeeId: '')),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildPremiumCard(
                  context,
                  'Event Updates',
                  Icons.event,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EventUpdatesPage()),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: kButtonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 24, color: kButtonColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: kButtonColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title, {
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: isSelected ? Colors.white : Colors.white,
            foregroundColor: isSelected ? kButtonColor : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: isSelected ? BorderSide(color: kButtonColor, width: 2) : BorderSide.none,
            ),
          ),
          onPressed: onTap,
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}