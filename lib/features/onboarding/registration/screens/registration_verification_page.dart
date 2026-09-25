// lib/features/onboarding/registration/screens/registration_verification_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/registration_draft_controller.dart';
import '../services/organization_registration_service.dart';
import '../widgets/registration_step_indicator.dart';
import 'organization_information_page.dart';
import 'registration_documents_page.dart';

/// One contact-verification channel on the registration wizard.
class _Channel {
  final String key; // backend channel id
  final String title;
  final String destination;
  final bool required;

  _Channel({
    required this.key,
    required this.title,
    required this.destination,
    required this.required,
  });
}

/// Functional contact-verification screen (replaces the old placeholder).
///
/// Verification status is ALWAYS read from the backend — a local boolean
/// can never mark a contact verified. OTP codes are delivered by email/SMS;
/// in DEV emulator mode the API may return `devCode`, which is surfaced in
/// a clearly-labelled debug hint for local testing only.
class RegistrationVerificationPage extends StatefulWidget {
  const RegistrationVerificationPage({super.key});

  @override
  State<RegistrationVerificationPage> createState() =>
      _RegistrationVerificationPageState();
}

class _RegistrationVerificationPageState
    extends State<RegistrationVerificationPage> {
  static const _kPrimary = Color(0xFF1565C0);
  static const _kSuccess = Color(0xFF2E7D32);
  static const _kCooldown = Duration(seconds: 60);

  final _controller = RegistrationDraftController.instance;
  final _api = OrganizationRegistrationService.instance;

  final Map<String, TextEditingController> _codeCtrls = {};
  final Map<String, DateTime> _cooldownUntil = {};
  final Map<String, bool> _verified = {};
  final Map<String, String?> _devCodes = {};

  List<_Channel> _channels = [];
  String _registrationId = '';
  String _resumeToken = '';
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Timer? _ticker;

  bool get _allVerified =>
      _channels.every((c) => !c.required || _verified[c.key] == true);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in _codeCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final d = _controller.draft;
    // Ensure a server draft exists before verification can be requested.
    if (d.registrationId.isEmpty) {
      await _controller.persist();
    }
    // Bound applications are authorized by the applicant JWT alone — the
    // device-local resume token is only a fallback credential.
    final token = await _api.applicantCredential();
    if (d.registrationId.isEmpty || token == null) {
      setState(() {
        _loading = false;
        _error =
            'Could not connect to the registration server. Save your draft '
            'and try again.';
      });
      return;
    }
    _registrationId = d.registrationId;
    _resumeToken = token;

    // Authoritative verification state comes from the server draft.
    try {
      final server = await _api.getDraft(_registrationId, _resumeToken);
      final verification = (server['verification'] is Map)
          ? Map<String, dynamic>.from(server['verification'])
          : <String, dynamic>{};

      final orgEmail = d.officialEmail.trim().toLowerCase();
      final adminEmail = d.adminEmail.trim().toLowerCase();

      _channels = [
        _Channel(
          key: 'orgEmail',
          title: 'Organization email',
          destination: d.officialEmail,
          required: true,
        ),
        _Channel(
          key: 'adminEmail',
          title: 'HR/Admin email',
          destination: d.adminEmail,
          required: adminEmail.isNotEmpty && adminEmail != orgEmail,
        ),
        _Channel(
          key: 'adminMobile',
          title: 'HR/Admin mobile',
          destination: d.adminMobile,
          required: true,
        ),
      ];

      for (final c in _channels) {
        final st = verification[c.key];
        _verified[c.key] = st is Map && st['verified'] == true;
        _codeCtrls[c.key] = TextEditingController();
      }
      setState(() => _loading = false);
    } on RegistrationApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  int _cooldownRemaining(String key) {
    final until = _cooldownUntil[key];
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left > 0 ? left : 0;
  }

  Future<void> _sendCode(_Channel c) async {
    if (_busy || _cooldownRemaining(c.key) > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final body = await _api.requestOtp(_registrationId, _resumeToken, c.key);
      _cooldownUntil[c.key] = DateTime.now().add(_kCooldown);
      // DEV-only: emulator responses may carry the test code.
      if (body['devCode'] != null) {
        _devCodes[c.key] = body['devCode'].toString();
      }
      _snack('Verification code sent to ${c.destination}');
    } on RegistrationApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode(_Channel c) async {
    final code = _codeCtrls[c.key]!.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code sent to ${c.destination}');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.confirmOtp(_registrationId, _resumeToken, c.key, code);
      setState(() {
        _verified[c.key] = true;
        _devCodes.remove(c.key);
      });
      _snack('${c.title} verified');
    } on RegistrationApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _busy = true);
    await _controller.persist();
    if (!mounted) return;
    setState(() => _busy = false);
    _snack('Draft saved');
  }

  Future<void> _continue() async {
    if (!_allVerified) return;
    await _controller.markStepCompleted(
      RegistrationDraftController.stepVerification,
      nextStep: 4,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationDocumentsPage()),
    );
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Verification'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _saveDraft,
            child: const Text('Save Draft',
                style: TextStyle(color: Colors.white)),
          ),
        ],
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
                      const RegistrationStepIndicator(
                        currentStep: 3,
                        labels: kRegistrationStepLabels,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verify your contact details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A 6-digit code will be sent to each contact below. '
                        'Codes expire after 10 minutes.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(_error!,
                              style: TextStyle(color: Colors.red.shade800)),
                        ),
                      for (final c in _channels) ...[
                        _channelCard(c),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed:
                            (_allVerified && !_busy) ? _continue : null,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _channelCard(_Channel c) {
    final verified = _verified[c.key] == true;
    final cooldown = _cooldownRemaining(c.key);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: verified ? _kSuccess : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(c.destination,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
              if (verified)
                const Row(children: [
                  Icon(Icons.check_circle, color: _kSuccess, size: 18),
                  SizedBox(width: 4),
                  Text('Verified',
                      style: TextStyle(
                          color: _kSuccess, fontWeight: FontWeight.w600)),
                ])
              else if (c.required)
                const Text('Required',
                    style: TextStyle(color: Colors.black45, fontSize: 12))
              else
                const Text('Not required',
                    style: TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ),
          if (c.required && !verified) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrls[c.key],
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: '6-digit code',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: cooldown > 0 || _busy ? null : () => _sendCode(c),
                  child: Text(cooldown > 0 ? 'Resend (${cooldown}s)' : 'Send code'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                  onPressed: _busy ? null : () => _verifyCode(c),
                  child: const Text('Verify'),
                ),
              ],
            ),
            if (_devCodes[c.key] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'DEV code: ${_devCodes[c.key]}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.deepOrange,
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
