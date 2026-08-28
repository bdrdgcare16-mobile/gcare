// lib/features/supderadmin/super_admin_disciplinary_detail_page.dart
import 'package:flutter/material.dart';
import 'package:serv_app/models/disciplinary_action_model.dart';
import 'package:serv_app/services/disciplinary_actions_service.dart';
import 'package:serv_app/shared/app_theme.dart';

class SuperAdminDisciplinaryDetailPage extends StatefulWidget {
  final DisciplinaryActionModel action;
  final VoidCallback? onStatusChanged;

  const SuperAdminDisciplinaryDetailPage({
    super.key,
    required this.action,
    this.onStatusChanged,
  });

  @override
  State<SuperAdminDisciplinaryDetailPage> createState() =>
      _SuperAdminDisciplinaryDetailPageState();
}

class _SuperAdminDisciplinaryDetailPageState
    extends State<SuperAdminDisciplinaryDetailPage> {
  bool _loading = false;

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

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await DisciplinaryActionsService.approve(widget.action.id);
      if (!mounted) return;
      _showSnack('Approved successfully');
      widget.onStatusChanged?.call();
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Approval failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      await DisciplinaryActionsService.reject(widget.action.id, reason.trim());
      if (!mounted) return;
      _showSnack('Rejected successfully');
      widget.onStatusChanged?.call();
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Rejection failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject Disciplinary Action'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason *',
              hintText: 'Enter reason for rejection',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    return result;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    final isPending = a.status == 'pending';

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
                  _infoRow('Employee Name', a.employeeName),
                  _infoRow('Employee ID', a.employeeId),
                  _infoRow('Company', a.companyId),
                  _infoRow('Department', a.department),
                  _infoRow('Designation', a.designation),
                  _infoRow('Reporting Manager', a.reportingManager),

                  _section('Incident Information'),
                  _infoRow('Violation Category', a.violationCategory),
                  if (a.violationCategory == 'Other')
                    _infoRow('Other Category', _string(a.otherViolationCategory)),
                  _infoRow('Incident Date', a.incidentDate),
                  _infoRow('Incident Time', _string(a.incidentTime)),
                  _infoRow('Incident Location', _string(a.incidentLocation)),
                  _infoRow('Incident Description', a.incidentDescription),

                  _section('Disciplinary Information'),
                  _infoRow('Notice Type', a.noticeType),
                  if (a.noticeType == 'Other')
                    _infoRow('Other Notice Type', _string(a.otherNoticeType)),
                  _infoRow('Severity', a.severity),
                  _infoRow('Subject', a.subject),
                  _infoRow('Reason', a.reason),
                  _infoRow('Response Required', a.responseRequired ? 'Yes' : 'No'),
                  if (a.responseRequired)
                    _infoRow('Response Due Date', _string(a.responseDueDate)),
                  _infoRow('Proposed Action', a.proposedAction),
                  if (a.proposedAction == 'Other')
                    _infoRow('Other Action', _string(a.otherProposedAction)),
                  _infoRow('Effective From', _string(a.effectiveFrom)),
                  _infoRow('Effective Until', _string(a.effectiveUntil)),
                  _infoRow('Admin Remarks', _string(a.finalRemarks)),

                  _section('Issuer Information'),
                  _infoRow('Issued By', a.createdByName),
                  _infoRow('Issued Date', _date(a.createdAt)),

                  _section('Status'),
                  _infoRow('Current Status', a.status.toUpperCase()),
                  if (a.status == 'approved') ...[
                    _infoRow('Approved By', _string(a.approvedByName)),
                    _infoRow('Approved At', _date(a.approvedAt)),
                  ],
                  if (a.status == 'rejected') ...[
                    _infoRow('Rejected By', _string(a.rejectedByName)),
                    _infoRow('Rejected At', _date(a.rejectedAt)),
                    _infoRow('Rejection Reason', _string(a.rejectionReason)),
                  ],

                  if (isPending) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _approve,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _reject,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
