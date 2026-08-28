// lib/features/admin/admin_disciplinary_actions_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:serv_app/models/disciplinary_action_model.dart';
import 'package:serv_app/services/disciplinary_actions_service.dart';
import 'package:serv_app/shared/app_theme.dart';
import 'create_disciplinary_action_page.dart';
import 'disciplinary_action_detail_page.dart';

class AdminDisciplinaryActionsPage extends StatefulWidget {
  const AdminDisciplinaryActionsPage({super.key});

  @override
  State<AdminDisciplinaryActionsPage> createState() =>
      _AdminDisciplinaryActionsPageState();
}

class _AdminDisciplinaryActionsPageState
    extends State<AdminDisciplinaryActionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = ['All', 'pending', 'approved', 'rejected'];
  String _selectedStatus = 'All';

  List<DisciplinaryActionModel> _actions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await DisciplinaryActionsService.getAdminList(
        status: _selectedStatus,
      );
      if (!mounted) return;
      setState(() => _actions = data);
    } catch (e) {
      if (!mounted) return;
      debugPrint('[DisciplinaryActions] Admin list error: $e');
      setState(() => _errorMessage = 'Failed to load disciplinary actions');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {});
    });
  }

  List<DisciplinaryActionModel> get _filteredActions {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _actions;
    return _actions.where((a) {
      return a.employeeName.toLowerCase().contains(q) ||
          a.employeeId.toLowerCase().contains(q) ||
          a.violationCategory.toLowerCase().contains(q) ||
          a.noticeType.toLowerCase().contains(q) ||
          a.status.toLowerCase().contains(q);
    }).toList();
  }

  int _countByStatus(String status) {
    return _actions
        .where((a) => a.status.toLowerCase() == status.toLowerCase())
        .length;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _summaryCard(String title, int count, Color color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final cards = [
          _summaryCard('Total', _actions.length, Colors.blue),
          _summaryCard('Pending', _countByStatus('pending'), Colors.orange),
          _summaryCard('Approved', _countByStatus('approved'), Colors.green),
          _summaryCard('Rejected', _countByStatus('rejected'), Colors.red),
        ];

        if (isMobile) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 8), Expanded(child: cards[1])]),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: cards[2]), const SizedBox(width: 8), Expanded(child: cards[3])]),
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimaryDark),
      ),
    );
  }

  Widget _buildFilters() {
    final searchField = TextField(
      controller: _searchController,
      decoration: _inputDecoration('Search').copyWith(
        hintText: 'Name, ID, category, notice',
        prefixIcon: const Icon(Icons.search, size: 20),
      ),
      onChanged: _onSearchChanged,
    );

    final statusField = DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: _inputDecoration('Status'),
      isExpanded: true,
      items: _statusFilters
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedStatus = value ?? 'All');
        _loadActions();
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(
            children: [
              searchField,
              const SizedBox(height: 10),
              statusField,
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: searchField),
            const SizedBox(width: 12),
            Expanded(child: statusField),
          ],
        );
      },
    );
  }

  Widget _buildCard(DisciplinaryActionModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.employeeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(a.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Employee ID: ${a.employeeId}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const Divider(height: 18),
          _infoRow('Department', a.department),
          _infoRow('Notice Type', a.noticeType),
          _infoRow('Violation', a.violationCategory),
          _infoRow('Severity', a.severity),
          _infoRow('Created', a.createdAt != null ? _formatDate(a.createdAt!) : '-'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openDetails(a),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryDark,
                    side: const BorderSide(color: kPrimaryDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _openDetails(DisciplinaryActionModel a) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminDisciplinaryActionDetailPage(action: a)),
    );
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateDisciplinaryActionPage()),
    );
    if (result == true) {
      _loadActions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: const Text(
          'Disciplinary Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6F52A3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: kPrimaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Disciplinary Action', style: TextStyle(color: Colors.white)),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _filteredActions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilters(),
              const SizedBox(height: 12),
              _buildSummaryCards(),
              if (_filteredActions.isEmpty) ...[
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'No disciplinary actions found.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ],
          );
        }
        return _buildCard(_filteredActions[index - 1]);
      },
    );
  }
}
