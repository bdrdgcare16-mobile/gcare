// lib/features/onboarding/registration/screens/registration_documents_page.dart

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../controllers/registration_draft_controller.dart';
import '../services/organization_registration_service.dart';
import '../widgets/registration_step_indicator.dart';
import 'organization_information_page.dart';
import 'registration_review_page.dart';

class _DocField {
  final String key;
  final String title;
  final String hint;
  final bool Function() requiredFn;

  _DocField({
    required this.key,
    required this.title,
    required this.hint,
    required this.requiredFn,
  });
}

/// Organization document-upload screen (step 4).
///
/// Documents upload to the DEV Firebase Storage emulator via the backend;
/// the backend validates actual file content (PDF/JPG/PNG magic bytes),
/// enforces the resume credential, and stores metadata on the registration
/// document. Refresh-safe: existing uploads are restored from the server.
class RegistrationDocumentsPage extends StatefulWidget {
  const RegistrationDocumentsPage({super.key});

  @override
  State<RegistrationDocumentsPage> createState() =>
      _RegistrationDocumentsPageState();
}

class _RegistrationDocumentsPageState
    extends State<RegistrationDocumentsPage> {
  static const _kSuccess = Color(0xFF2E7D32);
  static const _kMaxBytes = 10 * 1024 * 1024;

  final _controller = RegistrationDraftController.instance;
  final _api = OrganizationRegistrationService.instance;

  late final List<_DocField> _fields;

  final Map<String, Map<String, dynamic>> _uploaded = {};
  final Map<String, bool> _uploading = {};
  final Map<String, String?> _pickedName = {};

  String _registrationId = '';
  String _resumeToken = '';
  bool _loading = true;
  String? _error;

  bool get _allRequiredUploaded =>
      _fields.every((f) => !f.requiredFn() || _uploaded.containsKey(f.key));

  @override
  void initState() {
    super.initState();
    final d = _controller.draft;
    _fields = [
      _DocField(
        key: 'registrationCertificate',
        title: 'Organization Registration Certificate',
        hint: 'Certificate of incorporation / registration',
        requiredFn: () => true,
      ),
      _DocField(
        key: 'gstCertificate',
        title: 'GST Certificate',
        hint: 'Required when a GST number was provided',
        requiredFn: () => d.gstNumber.trim().isNotEmpty,
      ),
      _DocField(
        key: 'authorizationLetter',
        title: 'Authorization Letter',
        hint: 'Letter authorizing the HR/Admin to register',
        requiredFn: () => true,
      ),
      _DocField(
        key: 'adminIdProof',
        title: 'Authorized HR/Admin ID Proof',
        hint: 'Government-issued ID of the authorized contact',
        requiredFn: () => true,
      ),
    ];
    _load();
  }

  Future<void> _load() async {
    final d = _controller.draft;
    if (d.registrationId.isEmpty) {
      await _controller.persist();
    }
    final token = await _api.loadResumeToken();
    if (d.registrationId.isEmpty || token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Could not connect to the registration server.';
      });
      return;
    }
    _registrationId = d.registrationId;
    _resumeToken = token;
    await _refreshDocuments();
  }

  Future<void> _refreshDocuments() async {
    try {
      final body = await _api.listDocuments(_registrationId, _resumeToken);
      final docs = (body['documents'] is Map)
          ? Map<String, dynamic>.from(body['documents'])
          : <String, dynamic>{};
      setState(() {
        _uploaded
          ..clear()
          ..addAll(docs.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
          ));
        _loading = false;
      });
    } on RegistrationApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _pickAndUpload(_DocField f) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // required on web
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      setState(() => _error = 'Could not read the selected file.');
      return;
    }
    if (file.size > _kMaxBytes) {
      setState(() => _error = '${f.title}: file exceeds the 10 MB limit.');
      return;
    }

    setState(() {
      _uploading[f.key] = true;
      _pickedName[f.key] = file.name;
      _error = null;
    });
    try {
      await _api.uploadDocument(
        _registrationId,
        _resumeToken,
        f.key,
        file.name,
        file.bytes!,
      );
      await _refreshDocuments();
      _snack('${f.title} uploaded');
    } on RegistrationApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploading[f.key] = false);
    }
  }

  /// Documents complete → Review Application (step 5).
  Future<void> _finish() async {
    if (!_allRequiredUploaded) return;
    await _controller.markStepCompleted(
      RegistrationDraftController.stepDocuments,
      nextStep: RegistrationDraftController.stepReview,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationReviewPage()),
    );
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Documents')),
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
                        currentStep: 4,
                        labels: kRegistrationStepLabels,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Upload organization documents',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accepted formats: PDF, JPG, PNG (max 10 MB each). '
                        'Files are stored privately and reviewed by SERV.',
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
                      for (final f in _fields) ...[
                        _docCard(f),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed:
                            _allRequiredUploaded ? _finish : null,
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

  Widget _docCard(_DocField f) {
    final uploaded = _uploaded[f.key];
    final uploading = _uploading[f.key] == true;
    final required = f.requiredFn();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: uploaded != null ? _kSuccess : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(f.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      required ? 'Required' : 'Optional',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(f.hint,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
                if (uploaded != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: _kSuccess, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${uploaded['originalName']} uploaded',
                          style: const TextStyle(
                              fontSize: 12, color: _kSuccess),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          uploading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : OutlinedButton.icon(
                  onPressed: () => _pickAndUpload(f),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(uploaded != null ? 'Replace' : 'Upload'),
                ),
        ],
      ),
    );
  }
}
