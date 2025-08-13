import 'package:flutter/material.dart';
import 'leave_and_permission_screen.dart';
import 'leave_type_screen.dart';
import 'com_off_screen.dart';
import 'permission_time_screen.dart';
import 'overtime_screen.dart';

class LeaveGridPage extends StatefulWidget {
  const LeaveGridPage({super.key});

  @override
  _LeaveGridPageState createState() => _LeaveGridPageState();
}

class _LeaveGridPageState extends State<LeaveGridPage> {
  @override
  Widget build(BuildContext context) {
    // Color scheme
    const Color primaryColor = Color(0xFF223A5E);
    const Color accentColor = Color(0xFF00BFAE);
    const Color backgroundColor = Color(0xFFE3F2FD);
    const Color cardColor = Colors.white;
    const Color mainTextColor = Color(0xFF222B45);
    const Color secondaryTextColor = Color(0xFF6B7A8F);

    // Card data: icon, label, onTap, description
    final List<_LeaveCardData> cards = [
      _LeaveCardData(
        icon: Icons.calendar_today,
        label: 'Leave Type',
        description: 'Apply for different types of leave',
        color: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1976D2),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LeaveScreen()),
          );
        },
      ),
      _LeaveCardData(
        icon: Icons.schedule,
        label: 'Permission Time',
        description: 'Request permission for short time',
        color: const Color(0xFFE8F5E8),
        iconColor: const Color(0xFF388E3C),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PermissionTimeScreen()),
          );
        },
      ),
      _LeaveCardData(
        icon: Icons.access_time,
        label: 'Over Time',
        description: 'Apply for overtime work',
        color: const Color(0xFFFFF8E1),
        iconColor: const Color(0xFFF57C00),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OverTimeScreen()),
          );
        },
      ),
      _LeaveCardData(
        icon: Icons.check_circle_outline,
        label: 'Comp Off',
        description: 'Request compensatory off',
        color: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF7B1FA2),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CompOffScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Leave & Permission',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showLeaveHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your leave requests and permissions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryCard('Available', '15 days', Icons.event_available, Colors.green),
                    _summaryCard('Used', '8 days', Icons.event_busy, Colors.orange),
                    _summaryCard('Pending', '2 days', Icons.pending, Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          // Grid of options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: cards.map((card) => _LeaveCard(card: card)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('Sick Leave'),
                subtitle: const Text('Jan 15-17, 2024'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Approved',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.orange),
                title: const Text('Personal Leave'),
                subtitle: const Text('Feb 5-7, 2024'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.grey),
                title: const Text('Casual Leave'),
                subtitle: const Text('Mar 10, 2024'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Rejected',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _LeaveCardData {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  _LeaveCardData({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.iconColor,
    this.onTap,
  });
}

class _LeaveCard extends StatelessWidget {
  final _LeaveCardData card;
  const _LeaveCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: card.onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [card.color, card.color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: card.iconColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  card.icon,
                  color: card.iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                card.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF222B45),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                card.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7A8F),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LeaveTypePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leave Type')),
      body: Center(child: Text('Leave Type Page')),
    );
  }
}

class PermissionTimePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Permission Time')),
      body: Center(child: Text('Permission Time Page')),
    );
  }
}
