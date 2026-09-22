// lib/features/onboarding/registration/screens/registration_status_page.dart

import 'package:flutter/material.dart';

import 'package:serv_app/features/onboarding/screens/select_user_type_page.dart';
import '../controllers/registration_draft_controller.dart';
import '../services/organization_registration_service.dart';
import 'organization_information_page.dart';

/// Post-submission Application Status screen.
///
/// Deliberately does NOT claim that an organization account exists. Approval
/// and activation are separate, later stages owned by the SERV Platform
/// Admin; this screen only reports the authoritative application status.
class RegistrationStatusPage extends StatefulWidget {
  const RegistrationStatusPage({super.key});

  @override
  State<RegistrationStatusPage> createState() => _RegistrationStatusPageState();
}

class _RegistrationStatusPageState extends State<RegistrationStatusPage> {
  static const _kPrimaryDark = Color(0xFF655193);

  final _controller = RegistrationDraftController.instance;
  final _api = OrganizationRegistrationService.instance;

  Map<String, dynamic> _status = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = _controller.draft;
    final token = await _api.loadResumeToken();
    if (d.registrationId.isEmpty || token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Registration details are not available on this device.';
      });
      return;
    }
    try {
      final body = await _api.getStatus(d.registrationId, token);
      if (!mounted) return;
      setState(() {
        _status = body;
        _loading = false;
      });
      await _controller.refreshApplicationStatus();
    } on RegistrationApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // The cached status still drives the display — an outage must not
        // make a submitted application look unsubmitted.
        _error = e.message;
      });
    }
  }

  String get _effectiveStatus {
    final server = (_status['status'] ?? '').toString();
    return server.isNotEmpty
        ? server
        : _controller.draft.applicationStatus;
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    DateTime? dt;
    if (raw is String) {
      dt = DateTime.tryParse(raw);
    } else if (raw is Map && raw['_seconds'] is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(
          (raw['_seconds'] as num).toInt() * 1000);
    } else if (raw is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    if (dt == null) return '—';
    final l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} '
        '${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final d = _controller.draft;
    final status = _effectiveStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _headline(status),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            'Showing the last known status. $_error',
                            style:
                                TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      _detailCard(d, status),
                      const SizedBox(height: 16),
                      _stageCard(status),
                      const SizedBox(height: 16),
                      if (status == 'changes_requested') _changesCard(),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh status'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const SelectUserTypePage()),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _headline(String status) {
    late final String title;
    late final String body;
    late final IconData icon;
    late final Color color;

    switch (status) {
      case 'approved':
        title = 'Application approved';
        body = 'Your application has been approved. Organization activation '
            'is handled separately by the SERV Platform Admin.';
        icon = Icons.verified_outlined;
        color = const Color(0xFF2E7D32);
        break;
      case 'rejected':
        title = 'Application not accepted';
        body = 'The SERV Platform Admin did not accept this application. '
            'Please contact SERV support for details.';
        icon = Icons.cancel_outlined;
        color = Colors.red.shade700;
        break;
      case 'changes_requested':
        title = 'Changes requested';
        body = 'The SERV Platform Admin has asked for corrections before '
            'the review can continue.';
        icon = Icons.edit_note_outlined;
        color = Colors.orange.shade800;
        break;
      default:
        title = 'Application submitted for review';
        body = 'Your application is awaiting review by the SERV Platform '
            'Admin. Submission does not mean the application has been '
            'approved, and no organization account has been created yet. '
            'You will be contacted on the verified email address once the '
            'review is complete.';
        icon = Icons.hourglass_top_outlined;
        color = _kPrimaryDark;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }

  Widget _detailCard(dynamic draft, String status) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Application details',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const Divider(height: 18),
            _row('Organization',
                (_status['organizationName'] ?? draft.organizationName)
                    .toString()),
            _row('Application reference', draft.registrationId.toString()),
            _row('Submitted on', _formatDate(_status['submittedAt'])),
            _row('Current status', _statusLabel(status)),
          ],
        ),
      );

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_approval':
        return 'Submitted — awaiting Platform Admin review';
      case 'changes_requested':
        return 'Changes requested';
      case 'approved':
        return 'Approved — not yet activated';
      case 'rejected':
        return 'Not accepted';
      default:
        return status.isEmpty ? '—' : status;
    }
  }

  /// Makes the Submitted → Approved → Activated distinction explicit so the
  /// applicant cannot mistake submission for an operational organization.
  Widget _stageCard(String status) {
    final submitted = status.isNotEmpty && status != 'draft';
    final approved = status == 'approved';
    // 3D-A never activates an organization.
    const activated = false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const Divider(height: 18),
          _stageRow('Submitted', 'Application sent to SERV for review',
              submitted),
          _stageRow('Approved', 'Platform Admin has approved the application',
              approved),
          _stageRow('Activated',
              'Organization and Admin access are operational', activated),
        ],
      ),
    );
  }

  Widget _stageRow(String title, String subtitle, bool done) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: done ? const Color(0xFF2E7D32) : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              done ? FontWeight.w700 : FontWeight.w500)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _changesCard() {
    final review = _status['review'];
    final reasons = (review is Map && review['reasons'] is List)
        ? (review['reasons'] as List).map((e) => e.toString()).toList()
        : const <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Requested corrections',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (reasons.isEmpty)
            const Text('No specific reasons were recorded.',
                style: TextStyle(fontSize: 12.5))
          else
            ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $r', style: const TextStyle(fontSize: 12.5)),
                )),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await _controller
                  .goToStep(RegistrationDraftController.stepOrganization);
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => const OrganizationInformationPage()),
              );
            },
            child: const Text('Edit application'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text('$label:',
                  style: const TextStyle(
                      fontSize: 12.5, color: Colors.black54)),
            ),
            Expanded(
              child: Text(
                value.trim().isEmpty ? '—' : value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}
