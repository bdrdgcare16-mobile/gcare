// lib/features/platform_admin/platform_admin_registration_detail_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/services/platform_admin_registration_service.dart';

/// Detail view of one organization registration application in the
/// browser Platform Admin portal (Milestones 3D-B/C). Requested features
/// are labelled REQUESTED — never approved or enabled. When the
/// application is pending_approval the Platform Admin can record a
/// review decision (Approve / Reject / Request Changes). Approval means
/// REVIEW APPROVED ONLY — it does not create an organization, org code,
/// Admin account, or enable features.
class PlatformAdminRegistrationDetailPage extends StatefulWidget {
  final String registrationId;

  const PlatformAdminRegistrationDetailPage({
    super.key,
    required this.registrationId,
  });

  @override
  State<PlatformAdminRegistrationDetailPage> createState() =>
      _PlatformAdminRegistrationDetailPageState();
}

class _PlatformAdminRegistrationDetailPageState
    extends State<PlatformAdminRegistrationDetailPage> {
  Map<String, dynamic>? _registration;
  bool _isLoading = true;
  String? _errorMessage;
  String? _openingField;
  /// Non-null while a review decision is in flight — disables all
  /// action buttons and prevents double submission.
  String? _runningAction;

  static const _docLabels = <String, String>{
    'registrationCertificate': 'Registration Certificate',
    'gstCertificate': 'GST Certificate',
    'authorizationLetter': 'Authorization Letter',
    'adminIdProof': 'Admin ID Proof',
  };

  static const _featureLabels = <String, String>{
    'employee_master': 'Employee Master',
    'organization_structure': 'Organization Structure',
    'users_and_roles': 'Users & Roles',
    'attendance': 'Attendance',
    'location_tracking': 'Location Tracking',
    'tasks': 'Tasks',
    'shifts': 'Shifts',
    'leave_management': 'Leave Management',
    'payroll': 'Payroll',
    'recruitment': 'Recruitment',
    'performance': 'Performance',
    'reporting': 'Reporting',
  };

  static const _channelLabels = <String, String>{
    'orgEmail': 'Organization Email',
    'adminEmail': 'Admin Email',
    'adminMobile': 'Admin Mobile',
  };

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final reg = await PlatformAdminRegistrationService.instance
          .getRegistration(widget.registrationId);
      if (!mounted) return;
      setState(() => _registration = reg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDocument(String field, String filename) async {
    setState(() => _openingField = field);
    try {
      final opened = await PlatformAdminRegistrationService.instance
          .openDocument(widget.registrationId, field, filename);
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Document downloaded (inline viewing is web-only)'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open document: $e')),
      );
    } finally {
      if (mounted) setState(() => _openingField = null);
    }
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try {
      final d = v is String
          ? DateTime.parse(v)
          : (v is Map && v['_seconds'] != null)
              ? DateTime.fromMillisecondsSinceEpoch(
                  (v['_seconds'] as int) * 1000)
              : null;
      if (d == null) return '—';
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_approval':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'changes_requested':
        return Colors.blue;
      case 'pending_verification':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B3B73),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final displayValue = value?.toString() ?? '—';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayValue.isEmpty ? '—' : displayValue,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String id) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFC107)),
      ),
      child: Text(
        '${_featureLabels[id] ?? id} — REQUESTED',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF795548),
        ),
      ),
    );
  }

  Widget _verificationRow(String channel, dynamic state) {
    final s = state is Map ? state : const {};
    final verified = s['verified'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _channelLabels[channel] ?? channel,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            s['target']?.toString() ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Icon(
            verified ? Icons.check_circle : Icons.cancel,
            color: verified ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            verified ? 'Verified' : 'Not verified',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: verified ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentRow(String field, dynamic meta) {
    final m = meta is Map ? meta : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _docLabels[field] ?? field,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (m != null)
                  Text(
                    '${m['originalName'] ?? ''} '
                    '(${((m['size'] ?? 0) / 1024).toStringAsFixed(1)} KB)',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
              ],
            ),
          ),
          if (m != null)
            _openingField == field
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton.icon(
                    onPressed: () => _openDocument(
                      field,
                      m['originalName']?.toString() ?? 'document',
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Document'),
                  )
          else
            const Text('Not uploaded', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _auditRow(dynamic entry) {
    final e = entry is Map ? entry : const {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              _fmtDate(e['at']),
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              '${e['action'] ?? ''}'
              '${e['actor'] != null && e['actor'] != '' ? ' — ${e['actor']}' : ''}'
              '${e['note'] != null && e['note'] != '' ? ' (${e['note']})' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Resubmission context panel — shown only when the application was
  /// resubmitted at least once (resubmissionCount > 0). Surfaces the
  /// previous request-for-changes, the resubmission time, and the
  /// revision number so the reviewer never mistakes it for a first
  /// submission.
  Widget _resubmissionPanel(Map<String, dynamic> reg) {
    final count = (reg['resubmissionCount'] as num?)?.toInt() ?? 0;
    if (count <= 0) return const SizedBox.shrink();

    final history = (reg['reviewHistory'] as List? ?? const [])
        .whereType<Map>()
        .where((h) => h['decision'] == 'changes_requested')
        .toList();
    final prevRequest = history.isNotEmpty ? history.last : null;
    final prevMessage =
        (prevRequest?['note'] ??
                (prevRequest?['reasons'] as List?)?.join(', '))
            ?.toString() ??
        '';
    final prevAt = _fmtDate(prevRequest?['decidedAt']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7E57C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_edu,
                  size: 18, color: Color(0xFF5E35B1)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Resubmitted Application',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF4527A0),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E35B1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RESUBMITTED • REVISION ${count + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (prevRequest != null) ...[
            const Text(
              'Previous Request for Changes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5E35B1),
              ),
            ),
            const SizedBox(height: 4),
            if (prevMessage.isNotEmpty)
              Text(
                '"$prevMessage"',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Requested at: $prevAt'
              '${(prevRequest['reviewerEmail'] ?? '').toString().isNotEmpty ? ' by ${prevRequest['reviewerEmail']}' : ''}',
              style:
                  const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Previous decision: Changes Requested  •  '
            'Resubmitted: ${_fmtDate(reg['resubmittedAt'])}  •  '
            'Revision: ${count + 1}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  /// Renders one server-computed changed-field entry (old → new, feature
  /// add/remove, document replaced/added/removed).
  Widget _changeRow(dynamic entry) {
    final c = entry is Map ? entry : const {};
    final label = c['label']?.toString() ?? c['field']?.toString() ?? '';
    final changeType = c['changeType']?.toString() ?? 'modified';
    final added = (c['added'] as List? ?? const []);
    final removed = (c['removed'] as List? ?? const []);

    Widget line(String prefix, String value, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, top: 2),
        child: Text(
          '$prefix: $value',
          style: TextStyle(fontSize: 12, color: color ?? Colors.black87),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          if (changeType == 'modified' &&
              (c['oldValue'] != null || c['newValue'] != null)) ...[
            line('Old', '${c['oldValue'] ?? '—'}',
                color: Colors.red.shade700),
            line('New', '${c['newValue'] ?? '—'}',
                color: Colors.green.shade700),
          ],
          if (added.isNotEmpty)
            line('Added', added.join(', '), color: Colors.green.shade700),
          if (removed.isNotEmpty)
            line('Removed', removed.join(', '),
                color: Colors.red.shade700),
          if (changeType == 'replaced')
            line('Status', 'Replaced'
                '${(c['newValue'] ?? '').toString().isNotEmpty ? ' — ${c['newValue']}' : ''}',
                color: Colors.blue.shade700),
          if (changeType == 'added')
            line('Status', 'Added'
                '${(c['newValue'] ?? '').toString().isNotEmpty ? ' — ${c['newValue']}' : ''}',
                color: Colors.green.shade700),
          if (changeType == 'removed')
            line('Status', 'Removed'
                '${(c['oldValue'] ?? '').toString().isNotEmpty ? ' — ${c['oldValue']}' : ''}',
                color: Colors.red.shade700),
        ],
      ),
    );
  }

  /// CHANGES MADE — the server-computed diff of the latest resubmission.
  /// Unchanged fields are never listed.
  Widget _changesSection(Map<String, dynamic> reg) {
    final changed = (reg['changedFields'] as List? ?? const []);
    final count = (reg['resubmissionCount'] as num?)?.toInt() ?? 0;
    if (count <= 0) return const SizedBox.shrink();
    return _section('Changes Made by Applicant', [
      if (changed.isEmpty)
        const Text(
          'No field changes detected since the previous review.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        )
      else
        for (final c in changed) _changeRow(c),
    ]);
  }

  /// Review decision panel (3D-C). Action buttons exist only while the
  /// application is pending_approval; a decided application shows a
  /// recorded-decision note instead — there is no reopen action.
  Widget _reviewActions(String status) {
    if (status != 'pending_approval') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9D0EA)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: Color(0xFF6E6390)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This application is not awaiting review. Decisions are '
                'final — no review actions are available.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6E6390)),
              ),
            ),
          ],
        ),
      );
    }

    final busy = _runningAction != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9D0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Decision',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B3B73),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Approving records a review decision only — no organization, '
            'account, or feature is activated.',
            style: TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
          if (((_registration?['resubmissionCount'] as num?)?.toInt() ??
                  0) >
              0)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'This application has been resubmitted after requested '
                'corrections.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5E35B1),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: busy ? null : () => _onReviewAction('approve'),
                icon: _runningAction == 'approve'
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => _onReviewAction('request-changes'),
                icon: _runningAction == 'request-changes'
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_note_outlined, size: 18),
                label: const Text('Request Changes'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _onReviewAction('reject'),
                icon: _runningAction == 'reject'
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Confirmation + input dialog for a review decision, then the API
  /// call. Buttons are disabled while the request runs.
  Future<void> _onReviewAction(String action) async {
    final spec = switch (action) {
      'approve' => (
          title: 'Approve application?',
          fieldLabel: 'Reviewer note (optional)',
          required: false,
          confirmLabel: 'Approve',
          hint:
              'This records a review approval only. No organization or account is created.',
        ),
      'reject' => (
          title: 'Reject application?',
          fieldLabel: 'Rejection reason (required — shown to applicant)',
          required: true,
          confirmLabel: 'Reject application',
          hint: 'A reason is required and becomes part of the audit trail.',
        ),
      _ => (
          title: 'Request changes?',
          fieldLabel: 'Message to applicant (required)',
          required: true,
          confirmLabel: 'Request changes',
          hint:
              'Describe exactly what the applicant must correct before resubmission.',
        ),
    };

    // The text lives in a plain variable — no controller means nothing to
    // dispose while the dialog's exit animation is still in the tree.
    var entered = '';
    final decision = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? validation;
        return StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            title: Text(spec.title),
            scrollable: true,
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec.hint,
                      style: const TextStyle(
                          fontSize: 12.5, color: Colors.black54)),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 4,
                    maxLength: 4000,
                    decoration: InputDecoration(
                      labelText: spec.fieldLabel,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                      errorText: validation,
                    ),
                    onChanged: (v) {
                      entered = v;
                      if (validation != null) {
                        setDlg(() => validation = null);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final t = entered.trim();
                  if (spec.required && t.isEmpty) {
                    setDlg(
                        () => validation = 'This field is required.');
                    return;
                  }
                  Navigator.of(ctx).pop(t);
                },
                child: Text(spec.confirmLabel),
              ),
            ],
          ),
        );
      },
    );
    if (decision == null || !mounted) return;
    entered = decision;

    setState(() => _runningAction = action);
    try {
      final svc = PlatformAdminRegistrationService.instance;
      switch (action) {
        case 'approve':
          await svc.approveRegistration(
            widget.registrationId,
            comment: entered.isEmpty ? null : entered,
          );
          break;
        case 'reject':
          await svc.rejectRegistration(widget.registrationId, entered);
          break;
        default:
          await svc.requestChanges(widget.registrationId, entered);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review decision recorded')),
      );
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review action failed: $e')),
      );
      // A 409 means another reviewer decided first — refresh so the
      // new status (and missing action buttons) are shown.
      await _fetch();
    } finally {
      if (mounted) setState(() => _runningAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = _registration;
    final org = reg?['organization'] as Map? ?? {};
    final contact = reg?['adminContact'] as Map? ?? {};
    final verification = reg?['verification'] as Map? ?? {};
    final documents = reg?['documents'] as Map? ?? {};
    final features = (reg?['requestedFeatures'] as List? ?? []);
    final audit = (reg?['auditTrail'] as List? ?? []);
    final status = reg?['status']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E2450),
        elevation: 0,
        title: Text(
          'Application Review — ${widget.registrationId}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status banner — read-only, no decision actions.
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: _statusColor(status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _statusColor(status)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Status: '
                                      '${status.toUpperCase().replaceAll('_', ' ')}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Submitted: ${_fmtDate(reg?['submittedAt'])}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (reg != null) _resubmissionPanel(reg),

                            _reviewActions(status),

                            if (reg != null) _changesSection(reg),

                            _section('Organization Information', [
                              _detailRow('Legal Name', org['name']),
                              _detailRow('Type', org['type']),
                              _detailRow('Industry', org['industry']),
                              _detailRow('Employees', org['employeeCount']),
                              _detailRow('Branches', org['branchCount']),
                              _detailRow('Registered Address',
                                  org['registeredAddress']),
                              _detailRow(
                                  'Official Email', org['officialEmail']),
                              _detailRow(
                                  'Contact Number', org['contactNumber']),
                              _detailRow('Website', org['website']),
                              _detailRow('GST Number', org['gstNumber']),
                              _detailRow('CIN', org['cinNumber']),
                            ]),

                            _section('Requested HRMS Features', [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'These features were REQUESTED by the '
                                  'applicant. Nothing is approved or '
                                  'enabled until platform admin approval '
                                  '(a later milestone).',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              Wrap(
                                children: features
                                    .map((f) => _featureChip(f.toString()))
                                    .toList(),
                              ),
                              if (features.isEmpty)
                                const Text(
                                  'No features requested',
                                  style: TextStyle(color: Colors.grey),
                                ),
                            ]),

                            _section('Authorized HR / Admin Contact', [
                              _detailRow('Full Name', contact['fullName']),
                              _detailRow(
                                  'Designation', contact['designation']),
                              _detailRow('Email', contact['email']),
                              _detailRow('Mobile', contact['mobile']),
                            ]),

                            _section('Contact Verification', [
                              for (final ch in _channelLabels.keys)
                                _verificationRow(ch, verification[ch]),
                            ]),

                            _section('Uploaded Documents', [
                              for (final field in _docLabels.keys)
                                _documentRow(field, documents[field]),
                            ]),

                            _section('Application Timeline', [
                              _detailRow('Application ID',
                                  widget.registrationId),
                              _detailRow(
                                  'Created', _fmtDate(reg?['createdAt'])),
                              _detailRow('Last Updated',
                                  _fmtDate(reg?['updatedAt'])),
                              _detailRow('Submitted',
                                  _fmtDate(reg?['submittedAt'])),
                              _detailRow(
                                'Declaration',
                                reg?['declarationAccepted'] == true
                                    ? 'Accepted ${_fmtDate(reg?['declarationAcceptedAt'])}'
                                    : 'Not recorded',
                              ),
                              _detailRow('Resubmissions',
                                  reg?['resubmissionCount'] ?? 0),
                            ]),

                            if (audit.isNotEmpty)
                              _section('Audit Trail', [
                                for (final e in audit) _auditRow(e),
                              ]),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
