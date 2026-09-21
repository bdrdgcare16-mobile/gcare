// lib/features/onboarding/registration/screens/admin_information_page.dart

import 'package:flutter/material.dart';

import '../controllers/registration_draft_controller.dart';
import '../widgets/registration_form_section.dart';
import 'organization_information_page.dart';
import 'feature_selection_page.dart';
import 'registration_verification_placeholder_page.dart';

/// Step 3 — Authorized HR/Admin Information.
///
/// Collects contact details only. No Firebase account, role, JWT, password
/// or company profile is created here — that happens during backend
/// verification and approval milestones.
class AdminInformationPage extends StatefulWidget {
  const AdminInformationPage({super.key});

  @override
  State<AdminInformationPage> createState() => _AdminInformationPageState();
}

class _AdminInformationPageState extends State<AdminInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = RegistrationDraftController.instance;
  bool _busy = false;

  late final TextEditingController _name;
  late final TextEditingController _designation;
  late final TextEditingController _email;
  late final TextEditingController _mobile;

  @override
  void initState() {
    super.initState();
    final d = _controller.draft;
    _name = TextEditingController(text: d.adminFullName);
    _designation = TextEditingController(text: d.adminDesignation);
    _email = TextEditingController(text: d.adminEmail);
    _mobile = TextEditingController(text: d.adminMobile);
  }

  @override
  void dispose() {
    for (final c in [_name, _designation, _email, _mobile]) {
      c.dispose();
    }
    super.dispose();
  }

  void _writeDraft() {
    final d = _controller.draft;
    d.adminFullName = _name.text.trim();
    d.adminDesignation = _designation.text.trim();
    d.adminEmail = _email.text.trim();
    d.adminMobile = _mobile.text.trim();
  }

  Future<void> _saveDraft() async {
    setState(() => _busy = true);
    _writeDraft();
    await _controller.persist();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved on this device.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _next() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    _writeDraft();
    await _controller.markStepCompleted(
      RegistrationDraftController.stepAdmin,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegistrationVerificationPlaceholderPage(),
      ),
    );
  }

  void _back() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FeatureSelectionPage()),
    );
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _emailValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Official email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Enter a valid email address';
  }

  /// Indian 10-digit mobile format check.
  ///
  /// This validates FORMAT ONLY — it does not prove the number exists or
  /// belongs to the applicant. Ownership is verified by OTP in a later
  /// milestone.
  String? _mobileValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Mobile number must contain digits only';
    }
    if (value.length != 10) {
      return 'Enter a 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]').hasMatch(value)) {
      return 'Mobile number must start with 6, 7, 8 or 9';
    }
    // Reject a single repeated digit (1111111111, 0000000000, …).
    if (RegExp(r'^(\d)\1{9}$').hasMatch(value)) {
      return 'Enter a valid mobile number';
    }
    return null;
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F4FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF655193), width: 1.6),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationFormSection(
      title: 'Authorized HR / Admin',
      subtitle:
          'Step 3 of 4 — Who will administer this organization account? '
          'No login is created yet; access is granted after verification and approval.',
      currentStep: RegistrationDraftController.stepAdmin,
      stepLabels: kRegistrationStepLabels,
      onBack: _back,
      onSaveDraft: _saveDraft,
      onNext: _next,
      busy: _busy,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'This person will receive account access only after the '
                'organization application is verified and approved.',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: _decoration('Full Name *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Full name'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _designation,
              decoration: _decoration('Designation *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Designation'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              decoration: _decoration('Official Email Address *'),
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _mobile,
              decoration: _decoration('Mobile Number *'),
              keyboardType: TextInputType.phone,
              validator: _mobileValidator,
            ),
          ],
        ),
      ),
    );
  }
}
