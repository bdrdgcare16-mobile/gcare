import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/features/admin/task_assignment_history.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  // Employee-level assignment history (one row per employee per task)
  List<TaskAssignmentRow> _historyRows = [];
  bool _loadingHistory = false;
  String? _historyError;

  // Assigned Tasks table filters
  final TextEditingController _historySearchCtrl = TextEditingController();
  String _historyStatus = 'All';
  DateTime? _historyFrom;
  DateTime? _historyTo;

  // Simple "broadcast task" form (TEXT ONLY now)
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  DateTime? _dueDate;

  // dropdown state -> 'all' or 'employee'
  String _audience = 'all';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _empIdCtrl.dispose();
    _historySearchCtrl.dispose();
    super.dispose();
  }

  /// Loads the employee-level assignment history for the Assigned Tasks table.
  Future<void> _loadAssignmentHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final rows = await fetchTaskAssignmentRows();
      if (!mounted) return;
      setState(() => _historyRows = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _historyError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _pickHistoryDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _historyFrom : _historyTo) ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      final day = DateTime(picked.year, picked.month, picked.day);
      if (isFrom) {
        _historyFrom = day;
      } else {
        _historyTo = day;
      }
    });
  }

  void _applyQuickFilter(String range) {
    final rangeData = quickDateRange(range);
    if (rangeData == null) return;
    setState(() {
      _historyFrom = rangeData.from;
      _historyTo = rangeData.to;
    });
  }

  Future<void> _initData() async {
    await _loadAssignmentHistory();
  }

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /// Create a task:
  /// - If _audience == 'all': broadcast to everyone
  /// - If _audience == 'employee': assign only to given empid
  Future<void> _createBroadcastTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_audience == 'employee' && _empIdCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter: employee empid.')),
        );
      }
      return;
    }

    final uri = Uri.parse('${ApiService.baseUrl}/tasks/broadcast');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = CompanyData.token;

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = {
      "title": _titleCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "dueDate": _dueDate == null ? null : _fmtDate(_dueDate!),
      "kind": "Task",
      "audience": _audience,
      if (_audience == 'employee') "assignedTo": _empIdCtrl.text.trim(),
    };

    try {
      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (resp.statusCode == 201) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _empIdCtrl.clear();

        setState(() => _dueDate = null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task created successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the Assigned Tasks history so the new per-employee rows
        // appear immediately.
        await _loadAssignmentHistory();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${resp.statusCode} ${resp.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8C6EAF),
        centerTitle: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Tasks",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F6FF), Color(0xFFE8E4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSectionCard(
                title: "Task Assignment",
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildDropdownField(),
                          const SizedBox(height: 16),
                          if (_audience == 'employee') _buildEmployeeIdField(),
                          if (_audience == 'employee')
                            const SizedBox(height: 16),
                          _buildTitleField(),
                          const SizedBox(height: 16),
                          _buildDescriptionField(),
                          const SizedBox(height: 20),
                          _buildActionRow(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildAssignedTasksSection(),
              const SizedBox(height: 24),
              _buildSectionCard(
                title: "Task Management",
                child: Column(
                  children: const [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Assigned Tasks" history: one row per employee per task, searchable and
  /// filterable, newest assignment first.
  Widget _buildAssignedTasksSection() {
    final visible = filterTaskRows(
      rows: _historyRows,
      search: _historySearchCtrl.text,
      status: _historyStatus,
      fromDate: _historyFrom,
      toDate: _historyTo,
      useCompletedDate: false,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Assigned Tasks (${visible.length})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh, color: kTaskPrimaryDark),
                  onPressed: _loadingHistory ? null : _loadAssignmentHistory,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TaskHistoryFilterBar(
              searchController: _historySearchCtrl,
              statusFilter: _historyStatus,
              statusOptions: const [
                'All',
                'Assigned',
                'In Progress',
                'Completed',
              ],
              fromDate: _historyFrom,
              toDate: _historyTo,
              onStatusChanged: (v) => setState(() => _historyStatus = v),
              onSearchChanged: (_) => setState(() {}),
              onPickFromDate: () => _pickHistoryDate(isFrom: true),
              onPickToDate: () => _pickHistoryDate(isFrom: false),
              onClear: () => setState(() {
                _historySearchCtrl.clear();
                _historyStatus = 'All';
                _historyFrom = null;
                _historyTo = null;
              }),
              onQuickFilter: _applyQuickFilter,
            ),
            const SizedBox(height: 14),
            if (_loadingHistory)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_historyError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  _historyError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              )
            else
              TaskAssignmentTable(rows: visible),
            const SizedBox(height: 6),
            const Text(
              'Tap any row to view the full description and details.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _audience,
        isExpanded: true,
        items: const [
          DropdownMenuItem(
            value: 'all',
            child: Text('All employees'),
          ),
          DropdownMenuItem(
            value: 'employee',
            child: Text('One employee'),
          ),
        ],
        decoration: const InputDecoration(
          labelText: 'Assign to',
          labelStyle: TextStyle(color: Color(0xFF666666)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (v) {
          if (v == null) return;
          setState(() => _audience = v);
        },
      ),
    );
  }

  Widget _buildEmployeeIdField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: TextFormField(
        controller: _empIdCtrl,
        decoration: const InputDecoration(
          labelText: 'Employee ID',
          labelStyle: TextStyle(color: Color(0xFF666666)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: 'Enter employee ID',
          hintStyle: TextStyle(color: Color(0xFF999999)),
        ),
        validator: (v) {
          if (_audience == 'employee' && (v == null || v.trim().isEmpty)) {
            return 'Employee ID is required for single assignment';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: TextFormField(
        controller: _titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Task Title',
          labelStyle: TextStyle(color: Color(0xFF666666)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: 'Enter task title',
          hintStyle: TextStyle(color: Color(0xFF999999)),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: TextFormField(
        controller: _descCtrl,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Description',
          labelStyle: TextStyle(color: Color(0xFF666666)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'Describe the task details',
          hintStyle: TextStyle(color: Color(0xFF999999)),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: InkWell(
              onTap: _pickDueDate,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF8E71B7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'Pick due date (optional)'
                            : 'Due: ${_fmtDate(_dueDate!)}',
                        style: TextStyle(
                          color: _dueDate == null
                              ? const Color(0xFF666666)
                              : const Color(0xFF333333),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E71B7), Color(0xFF6B5E94)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8E71B7).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _createBroadcastTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              "Submit",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

}