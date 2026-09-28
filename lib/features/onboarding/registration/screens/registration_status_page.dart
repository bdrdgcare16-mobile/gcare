// lib/features/onboarding/registration/screens/registration_status_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/features/auth/auth_guard.dart';
import 'package:serv_app/features/onboarding/screens/select_user_type_page.dart';
import 'package:serv_app/features/users/login_page.dart';
import 'package:serv_app/models/company_data.dart';
import '../controllers/registration_draft_controller.dart';
import '../services/organization_registration_service.dart';
import 'organization_information_page.dart';

/// Post-submission Application Status screen.
///
/// Reports the authoritative application status — Submitted, Approved and
/// Activated are distinct stages. Once the Platform Admin activates the
/// organization (3D-D), this screen offers "Continue to Admin Dashboard",
/// which re-exchanges the applicant's Firebase session for an `admin` SERV
/// JWT via the existing /auth/firebase-login exchange — no new auth
/// mechanism. Without a live Firebase session the applicant signs in
/// again through the normal Admin login.
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
  bool _startingNew = false;
  bool _refreshingSession = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = _controller.draft;

    // Authenticated applicant: resolve the application server-side first —
    // this works on any device without the local resume credential and is
    // the authoritative routing source.
    if (CompanyData.token.isNotEmpty) {
      try {
        final app = await _api.getMyApplication();
        if (app != null) {
          d.registrationId = (app['registrationId'] ?? '').toString();
          final s = (app['status'] ?? '').toString();
          if (s.isNotEmpty) d.applicationStatus = s;
          if (!mounted) return;
          setState(() {
            _status = app;
            _loading = false;
          });
          return;
        }
      } on RegistrationApiException catch (e) {
        _error = e.message;
        // Fall through to the device-local credential path.
      }
    }

    final token = await _api.loadResumeToken();
    if (d.registrationId.isEmpty || token == null || token.isEmpty) {
      // Bound applications can still be fetched by JWT alone.
      if (d.registrationId.isNotEmpty && CompanyData.token.isNotEmpty) {
        try {
          final body = await _api.getStatus(d.registrationId, '');
          if (!mounted) return;
          setState(() {
            _status = body;
            _loading = false;
          });
          await _controller.refreshApplicationStatus();
          return;
        } on RegistrationApiException catch (e) {
          _error = e.message;
        }
      }
      setState(() {
        _loading = false;
        _error ??= 'Registration details are not available on this device.';
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

  /// Explicit applicant action: detach this device from the current
  /// application and begin a genuinely new one on a blank form.
  ///
  /// A submitted application is never modified — it stays under review and
  /// its credential is archived, not destroyed. An UNSENT editable draft is
  /// never discarded silently: it requires explicit confirmation first.
  Future<void> _onStartNewApplication() async {
    if (_startingNew) return;

    final hasUnsent = _controller.hasUnsentDraftWork;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new organization application?'),
        content: Text(
          hasUnsent
              ? 'The application on this device still has information that '
                  'has NOT been submitted for review. Starting a new '
                  'application removes that unsent work from this device — '
                  'this cannot be undone.'
              : 'This application remains under review by the SERV Platform '
                  'Admin and is not affected. A new, separate application '
                  'will start with a blank form.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start new application'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _startingNew = true);
    try {
      await _controller.startNewApplication();
    } finally {
      if (mounted) setState(() => _startingNew = false);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OrganizationInformationPage()),
    );
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
                      if (status == 'rejected') _rejectionCard(),
                      if (status == 'changes_requested') _changesCard(),
                      if (status == 'activated') _activatedCard(),
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
                      const Divider(height: 36),
                      Text(
                        'Need to register a different organization?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed:
                            _startingNew ? null : _onStartNewApplication,
                        icon: const Icon(Icons.add_business_outlined,
                            size: 18),
                        label: const Text(
                            'Start New Organization Application'),
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
      case 'activated':
        title = 'Organization activated';
        body = 'Your organization has been activated. Admin access is '
            'now available for this account.';
        icon = Icons.rocket_launch_outlined;
        color = const Color(0xFF6A1B9A);
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
      case 'activated':
        return 'Activated';
      case 'rejected':
        return 'Not accepted';
      default:
        return status.isEmpty ? '—' : status;
    }
  }

  /// Makes the Submitted → Approved → Activated distinction explicit so the
  /// applicant cannot mistake submission for an operational organization.
  /// Approved and Activated remain separate stages (3D-D).
  Widget _stageCard(String status) {
    final submitted = status.isNotEmpty && status != 'draft';
    final approved = status == 'approved' || status == 'activated';
    final activated = status == 'activated';

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

  /// Reviewer-facing messages only — decision, reasons and the reviewer
  /// note. Internal reviewer identity is never sent by the backend.
  List<String> _reviewMessages() {
    final review = _status['review'];
    if (review is! Map) return const [];
    final out = <String>[
      if (review['reasons'] is List)
        ...(review['reasons'] as List).map((e) => e.toString()),
      if ((review['note'] ?? '').toString().trim().isNotEmpty &&
          !(review['reasons'] is List &&
              (review['reasons'] as List)
                  .map((e) => e.toString())
                  .contains(review['note'].toString())))
        review['note'].toString(),
    ];
    return out;
  }

  Widget _rejectionCard() {
    final messages = _reviewMessages();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reason provided by the reviewer',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (messages.isEmpty)
            const Text('No reason was recorded.',
                style: TextStyle(fontSize: 12.5))
          else
            ...messages.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $r', style: const TextStyle(fontSize: 12.5)),
                )),
        ],
      ),
    );
  }

  /// Activated card (3D-D): organization code + Admin access. The old
  /// org_applicant JWT does not change on its own — "Continue" performs
  /// the existing Firebase Auth → SERV JWT exchange so the new session
  /// carries role 'admin' and the provisioned companyId.
  Widget _activatedCard() {
    final orgCode = (_status['organizationCode'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7E57C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Organization activated successfully.',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF4527A0))),
          const SizedBox(height: 10),
          _row('Organization Code',
              orgCode.isEmpty ? '—' : orgCode),
          const SizedBox(height: 4),
          const Text(
            'Admin access is now available for this account.',
            style: TextStyle(fontSize: 12.5, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _refreshingSession ? null : _continueToAdmin,
              icon: _refreshingSession
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.dashboard_outlined, size: 18),
              label: const Text('Continue to Admin Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Re-exchanges the live Firebase session for a fresh SERV JWT. The
  /// promoted account comes back as role 'admin' + companyId; the
  /// session is persisted and AuthGuard performs the standard routing
  /// (admin → profile check → Admin Dashboard).
  Future<void> _continueToAdmin() async {
    if (_refreshingSession) return;
    setState(() => _refreshingSession = true);
    try {
      String? idToken;
      try {
        final user = FirebaseAuth.instance.currentUser;
        idToken = await user?.getIdToken(true);
      } catch (_) {
        idToken = null;
      }
      if (idToken == null || idToken.isEmpty) {
        // No live Firebase session on this device — safe re-login path:
        // the normal Admin login performs the same firebase-login
        // exchange and returns the admin role.
        if (!mounted) return;
        _goToAdminLogin();
        return;
      }

      final session = await _api.exchangeFirebaseToken(idToken);
      final token =
          (session['token'] ?? session['data']?['token'] ?? '').toString();
      final role =
          (session['role'] ?? session['data']?['role'] ?? '').toString();
      if (token.isEmpty || role.isEmpty) {
        throw const RegistrationApiException(
            'Session refresh failed. Please sign in again.');
      }
      if (role != 'admin') {
        throw const RegistrationApiException(
            'The organization is activated but this account is not yet '
            'recognized as Admin. Please sign in again.');
      }

      final companyId = (session['companyId'] ??
              session['data']?['companyId'] ??
              session['user']?['companyId'] ??
              '')
          .toString();
      final name = (session['name'] ??
              session['data']?['name'] ??
              session['user']?['name'] ??
              '')
          .toString();
      final email = (FirebaseAuth.instance.currentUser?.email ??
              session['email'] ??
              session['data']?['email'] ??
              '')
          .toString();
      final uid = (session['uid'] ??
              session['data']?['uid'] ??
              FirebaseAuth.instance.currentUser?.uid ??
              '')
          .toString();

      CompanyData.token = token;
      CompanyData.role = role;
      CompanyData.companyId = companyId;
      if (email.isNotEmpty) CompanyData.email = email;

      final sp = await SharedPreferences.getInstance();
      await sp.setString('token', token);
      await sp.setString('role', role);
      await sp.setString('companyId', companyId);
      await sp.setString('status', 'active');
      if (name.isNotEmpty) await sp.setString('name', name);
      if (email.isNotEmpty) await sp.setString('email', email);
      if (uid.isNotEmpty) await sp.setString('userDocId', uid);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGuard()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is RegistrationApiException
                ? e.message
                : 'Could not open the Admin Dashboard. Please sign in '
                    'again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _refreshingSession = false);
    }
  }

  void _goToAdminLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _changesCard() {
    final reasons = _reviewMessages();

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
              // Pull the authoritative server draft first — existing data,
              // verification state and documents are preserved and the
              // applicant edits from the reviewed snapshot, not a stale
              // local copy.
              await _controller
                  .hydrateFromServer(_controller.draft.registrationId);
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
