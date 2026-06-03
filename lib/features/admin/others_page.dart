import 'package:flutter/material.dart';
import 'my_task_page.dart';
import 'rewards_page.dart';
import 'feedback_page.dart';
import 'event_update_page.dart';

// ✅ Color constants (unchanged)
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF6A1B9A);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// Design tokens — lavender/purple/white palette
const Color _kBg1 = Color(0xFFF5F0FF);
const Color _kBg2 = Color(0xFFEDE7F6);
const Color _kAccent = Color(0xFF8C6EAF);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kIconBg1 = Color(0xFFE8E0F5);
const Color _kIconBg2 = Color(0xFFEDE7F6);
const Color _kIconBg3 = Color(0xFFE6DEF0);
const Color _kIconBg4 = Color(0xFFD1C4E9);

class OthersPage extends StatelessWidget {
  const OthersPage({super.key});

  static const _items = [
    _MenuItem(
      title: 'My Tasks',
      subtitle: 'View & manage your tasks',
      icon: Icons.checklist_rounded,
      iconBg: _kIconBg1,
      iconColor: Color(0xFF7B5EA7),
    ),
    _MenuItem(
      title: 'Rewards',
      subtitle: 'Check your earned rewards',
      icon: Icons.emoji_events_rounded,
      iconBg: _kIconBg2,
      iconColor: Color(0xFF8C6EAF),
    ),
    _MenuItem(
      title: 'Feedback',
      subtitle: 'Share your thoughts',
      icon: Icons.chat_bubble_outline_rounded,
      iconBg: _kIconBg3,
      iconColor: Color(0xFF655193),
    ),
    _MenuItem(
      title: 'Event Updates',
      subtitle: 'Stay up to date on events',
      icon: Icons.event_note_rounded,
      iconBg: _kIconBg4,
      iconColor: Color(0xFF9575CD),
    ),
  ];

  void _navigate(BuildContext context, int index) {
    final pages = <Widget>[
      const MyTasksPage(),
      const RewardsPage(),
      const FeedbackPage(employeeName: '', employeeId: ''),
      const EventUpdatesPage(),
    ];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg1,
      body: Stack(
        children: [
          // ── subtle background blobs ──
          Positioned(
            top: -60,
            right: -40,
            child: _Circle(size: 200, color: const Color(0xFF8C6EAF).withOpacity(0.08)),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: _Circle(size: 180, color: const Color(0xFF655193).withOpacity(0.07)),
          ),
          Positioned(
            top: 200,
            left: -30,
            child: _Circle(size: 130, color: const Color(0xFFD1C4E9).withOpacity(0.5)),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kButtonColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.grid_view_rounded,
                              color: kButtonColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'More',
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
                      
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Card list ──
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return _FeatureCard(
                        item: item,
                        onTap: () => _navigate(context, i),
                        index: i,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ──
class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

// ── Animated card ──
class _FeatureCard extends StatefulWidget {
  final _MenuItem item;
  final VoidCallback onTap;
  final int index;
  const _FeatureCard({
    required this.item,
    required this.onTap,
    required this.index,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
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
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: item.iconColor.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, size: 26, color: item.iconColor),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow chip
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: item.iconColor,
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

// ── Background circle ──
class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
