// lib/features/users/my_disciplinary_actions_page.dart
import 'package:flutter/material.dart';
import 'package:serv_app/models/disciplinary_action_model.dart';
import 'package:serv_app/services/disciplinary_actions_service.dart';
import 'package:serv_app/shared/app_theme.dart';
import 'disciplinary_action_detail_page.dart';

class MyDisciplinaryActionsPage extends StatefulWidget {
  const MyDisciplinaryActionsPage({super.key});

  @override
  State<MyDisciplinaryActionsPage> createState() =>
      _MyDisciplinaryActionsPageState();
}

class _MyDisciplinaryActionsPageState extends State<MyDisciplinaryActionsPage> {
  List<DisciplinaryActionModel> _actions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await DisciplinaryActionsService.getMyActions();
      if (!mounted) return;
      setState(() {
        _actions = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load disciplinary actions';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return kPrimaryDark;
    }
  }

  Widget _buildCard(DisciplinaryActionModel action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  action.noticeType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _severityColor(action.severity).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  action.severity,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _severityColor(action.severity),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action.subject,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Violation: ${action.violationCategory}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Issued: ${action.submittedAt != null ? _formatDate(action.submittedAt!) : '-'}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DisciplinaryActionDetailPage(
                          action: action,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryDark,
                    side: const BorderSide(color: kPrimaryDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text(
          'My Disciplinary Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: kPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadActions,
        color: kPrimaryDark,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryDark));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadActions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_actions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No disciplinary actions found.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _actions.length,
      itemBuilder: (context, index) => _buildCard(_actions[index]),
    );
  }
}
