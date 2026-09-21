// lib/features/onboarding/registration/widgets/registration_form_section.dart

import 'package:flutter/material.dart';
import 'registration_step_indicator.dart';

const Color _kPrimaryDark = Color(0xFF655193);

/// Consistent wizard scaffold: step indicator + scrollable form body +
/// Back / Save Draft / Next actions. Responsive for web and narrow widths.
class RegistrationFormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final int currentStep;
  final List<String> stepLabels;
  final Widget form;
  final VoidCallback? onBack;
  final VoidCallback onSaveDraft;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool busy;

  const RegistrationFormSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentStep,
    required this.stepLabels,
    required this.form,
    required this.onSaveDraft,
    this.onBack,
    this.onNext,
    this.nextLabel = 'Next',
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EEF9),
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: RegistrationStepIndicator(
                    currentStep: currentStep,
                    labels: stepLabels,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: form,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE8E0F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (onBack != null)
                        OutlinedButton(
                          onPressed: busy ? null : onBack,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimaryDark,
                            side: const BorderSide(color: _kPrimaryDark),
                            minimumSize: const Size(88, 48),
                          ),
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: busy ? null : onSaveDraft,
                        child: const Text(
                          'Save Draft',
                          style: TextStyle(color: _kPrimaryDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (onNext != null)
                        ElevatedButton(
                          onPressed: busy ? null : onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimaryDark,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(104, 48),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(nextLabel),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
