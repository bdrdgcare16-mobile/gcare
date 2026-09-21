// lib/features/onboarding/registration/screens/feature_selection_page.dart

import 'package:flutter/material.dart';

import '../controllers/registration_draft_controller.dart';
import '../widgets/registration_form_section.dart';
import 'organization_information_page.dart';
import 'admin_information_page.dart';

const Color _kPrimaryDark = Color(0xFF655193);

/// Requested-feature catalogue for the applicant.
///
/// These are REQUESTED modules only — approval and enablement happen on the
/// platform side (Milestone 3D). Selecting here never activates a feature.
const List<RegistrationFeature> kSelectableFeatures = [
  RegistrationFeature('employee_master', 'Employee Master',
      'Employee records, documents and profiles.'),
  RegistrationFeature('organization_structure', 'Organization Structure',
      'Branches, departments and designations.'),
  RegistrationFeature('users_and_roles', 'Users and Roles',
      'User accounts and role-based access.'),
  RegistrationFeature('attendance', 'Attendance',
      'Check-in/check-out with geofence support.'),
  RegistrationFeature('location_tracking', 'Location Tracking',
      'Work-hours employee location tracking.'),
  RegistrationFeature('tasks', 'Tasks',
      'Task assignment and tracking.'),
  RegistrationFeature('shifts', 'Shifts',
      'Shift scheduling and rotation.'),
  RegistrationFeature('leave_management', 'Leave Management',
      'Leave types, requests and approvals.'),
  RegistrationFeature('payroll', 'Payroll',
      'Salary processing and payslips.'),
  RegistrationFeature('recruitment', 'Recruitment',
      'Candidate pipeline and onboarding.'),
  RegistrationFeature('performance', 'Performance',
      'Reviews, goals and appraisals.'),
  RegistrationFeature('reporting', 'Reporting',
      'Analytics and management reports.'),
];

class RegistrationFeature {
  final String id;
  final String title;
  final String description;
  const RegistrationFeature(this.id, this.title, this.description);
}

/// Step 2 — HRMS Feature Selection.
class FeatureSelectionPage extends StatefulWidget {
  const FeatureSelectionPage({super.key});

  @override
  State<FeatureSelectionPage> createState() => _FeatureSelectionPageState();
}

class _FeatureSelectionPageState extends State<FeatureSelectionPage> {
  final _controller = RegistrationDraftController.instance;
  bool _busy = false;

  Future<void> _saveDraft() async {
    setState(() => _busy = true);
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
    setState(() => _busy = true);
    await _controller.markStepCompleted(
      RegistrationDraftController.stepFeatures,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminInformationPage()),
    );
  }

  void _back() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OrganizationInformationPage()),
    );
  }

  void _toggle(String id, bool? selected) {
    setState(() {
      if (selected == true) {
        _controller.draft.requestedFeatures.add(id);
      } else {
        _controller.draft.requestedFeatures.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _controller.draft.requestedFeatures;

    return RegistrationFormSection(
      title: 'Feature Selection',
      subtitle:
          'Step 2 of 4 — Choose the HRMS modules your organization wants. '
          'Selections are requests only; they are activated after platform approval.',
      currentStep: RegistrationDraftController.stepFeatures,
      stepLabels: kRegistrationStepLabels,
      onBack: _back,
      onSaveDraft: _saveDraft,
      onNext: _next,
      busy: _busy,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Requested features are reviewed by the SERV platform team. '
              'Selecting a module does not activate it.',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          ...kSelectableFeatures.map((f) => Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected.contains(f.id)
                        ? _kPrimaryDark
                        : Colors.grey.shade300,
                    width: selected.contains(f.id) ? 1.5 : 1,
                  ),
                ),
                child: CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: _kPrimaryDark,
                  value: selected.contains(f.id),
                  onChanged: (v) => _toggle(f.id, v),
                  title: Text(
                    f.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Text(
                    f.description,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          Text(
            '${selected.length} feature(s) requested',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
