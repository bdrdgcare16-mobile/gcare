// lib/features/admin/disciplinary_action_detail_page.dart
import 'package:flutter/material.dart';
import 'package:serv_app/models/disciplinary_action_model.dart';
import 'package:serv_app/services/disciplinary_actions_service.dart';
import 'package:serv_app/shared/app_theme.dart';
import 'create_disciplinary_action_page.dart';

class AdminDisciplinaryActionDetailPage extends StatefulWidget {
  final DisciplinaryActionModel action;

  const AdminDisciplinaryActionDetailPage({
    super.key,
    required this.action,
  });

  @override
  State<AdminDisciplinaryActionDetailPage> createState() =>
      _AdminDisciplinaryActionDetailPageState();
}

class _AdminDisciplinaryActionDetailPageState
    extends State<AdminDisciplinaryActionDetailPage> {
  late DisciplinaryActionModel _action;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _action = widget.action;
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final updated = await DisciplinaryActionsService.getById(_action.id);
      if (!mounted) return;
      setState(() => _action = updated);
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDisciplinaryActionPage(action: _action),
      ),
    );
    if (result == true) {
      await _refresh();
    }
  }

  static String _string(String? value) =>
      value == null || value.trim().isEmpty ? '-' : value;

  static String _date(DateTime? value) {
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: kPrimaryDark,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text(
          'Disciplinary Action Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6F52A3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('Employee Information'),
                  _infoRow('Employee Name', _action.employeeName),
                  _infoRow('Employee ID', _action.employeeId),
                  _infoRow('Department', _action.department),
                  _infoRow('Designation', _action.designation),
                  _infoRow('Reporting Manager', _action.reportingManager),

                  _section('Incident Information'),
                  _infoRow('Violation Category', _action.violationCategory),
                  if (_action.violationCategory == 'Other')
                    _infoRow('Other Category', _string(_action.otherViolationCategory)),
                  _infoRow('Incident Date', _action.incidentDate),
                  _infoRow('Incident Time', _string(_action.incidentTime)),
                  _infoRow('Incident Location', _string(_action.incidentLocation)),
                  _infoRow('Incident Description', _action.incidentDescription),

                  _section('Disciplinary Information'),
                  _infoRow('Notice Type', _action.noticeType),
                  if (_action.noticeType == 'Other')
                    _infoRow('Other Notice Type', _string(_action.otherNoticeType)),
                  _infoRow('Severity', _action.severity),
                  _infoRow('Subject', _action.subject),
                  _infoRow('Reason', _action.reason),
                  _infoRow('Response Required', _action.responseRequired ? 'Yes' : 'No'),
                  if (_action.responseRequired)
                    _infoRow('Response Due Date', _string(_action.responseDueDate)),
                  _infoRow('Proposed Action', _action.proposedAction),
                  if (_action.proposedAction == 'Other')
                    _infoRow('Other Action', _string(_action.otherProposedAction)),
                  _infoRow('Effective From', _string(_action.effectiveFrom)),
                  _infoRow('Effective Until', _string(_action.effectiveUntil)),

                  _section('Issuer Information'),
                  _infoRow('Issued By', _action.createdByName),
                  _infoRow('Issued Date', _date(_action.createdAt)),

                  _section('Status'),
                  _infoRow('Current Status', _action.status.toUpperCase()),
                  if (_action.status == 'rejected') ...[
                    _infoRow('Rejected By', _string(_action.rejectedByName)),
                    _infoRow('Rejected At', _date(_action.rejectedAt)),
                    _infoRow('Rejection Reason', _string(_action.rejectionReason)),
                  ],
                  if (_action.status == 'approved') ...[
                    _infoRow('Approved By', _string(_action.approvedByName)),
                    _infoRow('Approved At', _date(_action.approvedAt)),
                  ],

                  if (_action.isEditable) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _edit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(_action.status == 'rejected' ? 'Resubmit' : 'Edit'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
