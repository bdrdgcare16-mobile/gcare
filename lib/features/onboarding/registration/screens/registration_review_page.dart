// lib/features/onboarding/registration/screens/registration_review_page.dart

import 'package:flutter/material.dart';

import '../controllers/registration_draft_controller.dart';
import '../services/organization_registration_service.dart';
import '../widgets/registration_step_indicator.dart';
import 'feature_selection_page.dart';
import 'organization_information_page.dart';
import 'registration_documents_page.dart';
import 'registration_status_page.dart';

/// Step 6 (index 5) — read-only Review Application + Confirm & Submit.
///
/// Verification state and document state shown here come from the BACKEND,
/// not from local flags. The declaration checkbox is a precondition for the
/// submit call, but the backend independently re-validates everything —
/// nothing here can bypass the server-side gate.
class RegistrationReviewPage extends StatefulWidget {
  const RegistrationReviewPage({super.key});

  @override
  State<RegistrationReviewPage> createState() => _RegistrationReviewPageState();
}

class _RegistrationReviewPageState extends State<RegistrationReviewPage> {
  static const _kPrimaryDark = Color(0xFF655193);
  static const _kSuccess = Color(0xFF2E7D32);

  final _controller = RegistrationDraftController.instance;
  final _api = OrganizationRegistrationService.instance;

  static const _docTitles = <String, String>{
    'registrationCertificate': 'Organization Registration Certificate',
    'gstCertificate': 'GST Certificate',
    'authorizationLetter': 'Authorization Letter',
    'adminIdProof': 'Authorized HR/Admin ID Proof',
  };

  Map<String, dynamic> _verification = {};
  Map<String, dynamic> _documents = {};
  bool _loading = true;
  bool _submitting = false;
  bool _declared = false;
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
        _error = 'Could not reach the registration server. Save your draft '
            'and try again before submitting.';
      });
      return;
    }
    try {
      final server = await _api.getDraft(d.registrationId, token);
      setState(() {
        _verification = (server['verification'] is Map)
            ? Map<String, dynamic>.from(server['verification'])
            : <String, dynamic>{};
        _documents = (server['documents'] is Map)
            ? Map<String, dynamic>.from(server['documents'])
            : <String, dynamic>{};
        _loading = false;
      });
    } on RegistrationApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  bool _verified(String channel) {
    final v = _verification[channel];
    return v is Map && v['verified'] == true;
  }

  Future<void> _submit() async {
    // Duplicate-click protection: the guard plus the disabled button mean a
    // second tap cannot start a second request.
    if (_submitting || !_declared) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _controller.submitApplication();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegistrationStatusPage()),
      );
    } on RegistrationApiException catch (e) {
      // The submit request may have reached the server even though the
      // client observed a failure (e.g. the response was lost to a timeout
      // or a dropped connection). Reconcile against the AUTHORITATIVE
      // application status before allowing a retry — repeat submissions
      // are idempotent server-side, and this prevents a false local
      // "failure" while the application is actually pending_approval.
      await _controller.refreshApplicationStatus();
      if (!mounted) return;
      if (_controller.draft.isSubmitted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegistrationStatusPage()),
        );
        return;
      }
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  void _back() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegistrationDocumentsPage()),
    );
  }

  Future<void> _editDetails() async {
    await _controller.goToStep(RegistrationDraftController.stepOrganization);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OrganizationInformationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _controller.draft;
    final orgEmail = d.officialEmail.trim().toLowerCase();
    final adminEmail = d.adminEmail.trim().toLowerCase();
    final adminEmailRequired =
        adminEmail.isNotEmpty && adminEmail != orgEmail;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Application')),
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
                      const RegistrationStepIndicator(
                        currentStep: 5,
                        labels: kRegistrationStepLabels,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Review your application',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check every section below. After submission the '
                        'application becomes read-only until the SERV '
                        'Platform Admin completes their review.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null) _errorBox(_error!),
                      _section('Organization Information', [
                        _row('Organization name', d.organizationName),
                        _row('Organization type', d.organizationType),
                        _row('Industry', d.industry),
                        _row('Employee count', d.employeeCount),
                        _row('Branch count', d.branchCount),
                        _row('Registered address', d.registeredAddress),
                        _row('Official email', d.officialEmail),
                        _row('Contact number', d.contactNumber),
                        if (d.website.trim().isNotEmpty)
                          _row('Website', d.website),
                        if (d.gstNumber.trim().isNotEmpty)
                          _row('GST number', d.gstNumber),
                        if (d.cinNumber.trim().isNotEmpty)
                          _row('CIN / registration number', d.cinNumber),
                      ]),
                      _section('Requested HRMS Features', [
                        if (d.requestedFeatures.isEmpty)
                          const Text('No modules requested',
                              style: TextStyle(color: Colors.black54))
                        else
                          ...kSelectableFeatures
                              .where((f) => d.requestedFeatures.contains(f.id))
                              .map((f) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 4),
                                    child: Row(children: [
                                      const Icon(Icons.check,
                                          size: 16, color: _kPrimaryDark),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(f.title)),
                                    ]),
                                  )),
                        const SizedBox(height: 8),
                        const Text(
                          'These are requested modules only. They are not '
                          'approved or enabled.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ]),
                      _section('Authorized HR / Admin', [
                        _row('Full name', d.adminFullName),
                        _row('Designation', d.adminDesignation),
                        _row('Official email', d.adminEmail),
                        _row('Mobile number', d.adminMobile),
                      ]),
                      _section('Contact Verification', [
                        _verificationRow(
                            'Organization email', 'orgEmail', true),
                        _verificationRow(
                            'HR/Admin email', 'adminEmail', adminEmailRequired),
                        _verificationRow(
                            'HR/Admin mobile', 'adminMobile', true),
                      ]),
                      _section('Uploaded Documents', [
                        for (final entry in _docTitles.entries)
                          _documentRow(entry.key, entry.value, d),
                        const SizedBox(height: 8),
                        const Text(
                          'Uploaded documents are stored privately and have '
                          'not yet been checked or authenticated by SERV.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ]),
                      _declarationBox(),
                      const SizedBox(height: 20),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: _kPrimaryDark),
                        onPressed:
                            (_declared && !_submitting) ? _submit : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                )
                              : const Text('Confirm & Submit'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting ? null : _back,
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting ? null : _editDetails,
                              child: const Text('Edit Details'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _errorBox(String message) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(message, style: TextStyle(color: Colors.red.shade800)),
      );

  Widget _section(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const Divider(height: 18),
            ...children,
          ],
        ),
      );

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

  Widget _verificationRow(String label, String channel, bool required) {
    final verified = _verified(channel);
    final Widget trailing;
    if (!required) {
      trailing = const Text('Not required',
          style: TextStyle(fontSize: 12, color: Colors.black45));
    } else if (verified) {
      trailing = const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, size: 16, color: _kSuccess),
        SizedBox(width: 4),
        Text('Verified',
            style: TextStyle(
                fontSize: 12.5,
                color: _kSuccess,
                fontWeight: FontWeight.w600)),
      ]);
    } else {
      trailing = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
        const SizedBox(width: 4),
        Text('Not verified',
            style: TextStyle(
                fontSize: 12.5,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600)),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          trailing,
        ],
      ),
    );
  }

  Widget _documentRow(
    String field,
    String title,
    dynamic draft,
  ) {
    final required = field == 'gstCertificate'
        ? draft.gstNumber.trim().isNotEmpty as bool
        : true;
    final meta = _documents[field];
    final uploaded = meta is Map;

    final Widget trailing;
    if (!required && !uploaded) {
      trailing = const Text('Not applicable',
          style: TextStyle(fontSize: 12, color: Colors.black45));
    } else if (uploaded) {
      trailing = const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, size: 16, color: _kSuccess),
        SizedBox(width: 4),
        Text('Uploaded',
            style: TextStyle(
                fontSize: 12.5,
                color: _kSuccess,
                fontWeight: FontWeight.w600)),
      ]);
    } else {
      trailing = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
        const SizedBox(width: 4),
        Text('Missing',
            style: TextStyle(
                fontSize: 12.5,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600)),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13)),
                if (uploaded)
                  Text(
                    (meta['originalName'] ?? '').toString(),
                    style: const TextStyle(
                        fontSize: 11.5, color: Colors.black54),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _declarationBox() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
        ),
        // Transparent Material gives the CheckboxListTile's ink splash an
        // ink host ABOVE the DecoratedBox — without it Flutter asserts that
        // the tile's background/splash would be invisible.
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Declaration',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _kPrimaryDark,
                value: _declared,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _declared = v == true),
                title: const Text(
                  'I have reviewed the information above, confirm that it is '
                  'accurate and complete, and I am authorized by this '
                  'organization to submit this application to SERV.',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
}
