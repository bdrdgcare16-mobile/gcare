// lib/features/users/disciplinary_action_detail_page.dart
import 'package:flutter/material.dart';
import 'package:serv_app/models/disciplinary_action_model.dart';
import 'package:serv_app/shared/app_theme.dart';

class DisciplinaryActionDetailPage extends StatelessWidget {
  final DisciplinaryActionModel action;

  const DisciplinaryActionDetailPage({
    super.key,
    required this.action,
  });

  static String _string(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value;
  }

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
          'Disciplinary Action',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Employee Information'),
            _infoRow('Employee Name', _string(action.employeeName)),
            _infoRow('Employee ID', _string(action.employeeId)),
            _infoRow('Department', _string(action.department)),
            _infoRow('Designation', _string(action.designation)),

            _section('Incident Information'),
            _infoRow('Violation Category', _string(action.violationCategory)),
            if (action.violationCategory == 'Other')
              _infoRow('Other Category', _string(action.otherViolationCategory)),
            _infoRow('Incident Date', _string(action.incidentDate)),
            _infoRow('Incident Time', _string(action.incidentTime)),
            _infoRow('Incident Location', _string(action.incidentLocation)),
            _infoRow('Incident Description', _string(action.incidentDescription)),

            _section('Disciplinary Information'),
            _infoRow('Notice Type', _string(action.noticeType)),
            if (action.noticeType == 'Other')
              _infoRow('Other Notice Type', _string(action.otherNoticeType)),
            _infoRow('Severity', _string(action.severity)),
            _infoRow('Subject', _string(action.subject)),
            _infoRow('Reason', _string(action.reason)),
            _infoRow('Response Required', action.responseRequired ? 'Yes' : 'No'),
            if (action.responseRequired)
              _infoRow('Response Due Date', _string(action.responseDueDate)),
            _infoRow('Proposed Action', _string(action.proposedAction)),
            if (action.proposedAction == 'Other')
              _infoRow('Other Action', _string(action.otherProposedAction)),
            _infoRow('Effective From', _string(action.effectiveFrom)),
            _infoRow('Effective Until', _string(action.effectiveUntil)),

            _section('Issuer Information'),
            _infoRow('Issued By', _string(action.createdByName)),
            _infoRow('Issued Date', _date(action.createdAt)),
            _infoRow('Approved Date', _date(action.approvedAt)),
            _infoRow('Status', _string(action.status).toUpperCase()),
          ],
        ),
      ),
    );
  }
}
