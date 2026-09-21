// lib/features/onboarding/registration/screens/registration_verification_placeholder_page.dart

import 'package:flutter/material.dart';

import '../controllers/registration_draft_controller.dart';
import '../widgets/registration_step_indicator.dart';
import 'organization_information_page.dart';
import 'admin_information_page.dart';

const Color _kPrimaryDark = Color(0xFF655193);

/// Step 4 — Email and Mobile Verification (placeholder).
///
/// Real OTP verification is implemented in the next milestone. This screen
/// shows a truthful status of the draft and never claims verification,
/// submission or approval has happened.
class RegistrationVerificationPlaceholderPage extends StatelessWidget {
  const RegistrationVerificationPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final d = RegistrationDraftController.instance.draft;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEF9),
      appBar: AppBar(
        title: const Text('Verification'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const RegistrationStepIndicator(
                    currentStep:
                        RegistrationDraftController.stepVerification,
                    labels: kRegistrationStepLabels,
                  ),
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 72,
                    color: _kPrimaryDark,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Email and Mobile Verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Verification will be available in the next stage.\n\n'
                    'Your organization details have been saved as a draft on '
                    'this device. You can return later and continue where you '
                    'left off.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _summaryCard(d),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const AdminInformationPage(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Review my details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimaryDark,
                      side: const BorderSide(color: _kPrimaryDark),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(d) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12.5, color: Colors.black54),
                ),
              ),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Draft summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kPrimaryDark,
              ),
            ),
            const Divider(height: 20),
            row('Organization', d.organizationName),
            row('Type', d.organizationType),
            row('Email', d.officialEmail),
            row('Features', '${d.requestedFeatures.length} requested'),
            row('HR/Admin', d.adminFullName),
            row('Status', 'Draft — not submitted'),
          ],
        ),
      ),
    );
  }
}
