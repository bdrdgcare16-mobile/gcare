// lib/features/onboarding/registration/screens/feature_selection_page.dart

import 'package:flutter/material.dart';

import 'package:serv_app/models/hrms_features.dart';

import '../controllers/registration_draft_controller.dart';
import '../widgets/registration_form_section.dart';
import 'organization_information_page.dart';
import 'admin_information_page.dart';

const Color _kPrimaryDark = Color(0xFF655193);

/// BASIC HRMS — core modules every SERV HRMS organization gets by default.
/// Rendered selected + locked; the backend also injects them server-side
/// into requestedFeatures so they can never be dropped.
const List<RegistrationFeature> kBasicFeatures = [
  RegistrationFeature('attendance', 'Attendance',
      'Check-in/check-out with geofence support.'),
  RegistrationFeature('employee_master', 'Employee Master',
      'Employee records, documents and profiles.'),
  RegistrationFeature('feedback', 'Feedback',
      'Employee feedback and responses.'),
  RegistrationFeature('shifts', 'Shift Management',
      'Shift scheduling and rotation.'),
];

/// Requested-feature catalogue for the applicant — OPTIONAL modules only.
///
/// These are REQUESTED modules only — approval and enablement happen on the
/// platform side (Milestone 3D). Selecting here never activates a feature.
///
/// Only modules with a genuine usable implementation (backend routes +
/// reachable UI) are offered — see kImplementedOptionalFeatures. Keys such
/// as organization_structure, users_and_roles, recruitment and reporting
/// remain canonical and stay readable in existing data, but are not
/// selectable by new registrations.
final List<RegistrationFeature> kOptionalFeatures =
    kSelectableOptionalCatalogue
        .where((f) => kImplementedOptionalFeatures.contains(f.id))
        .toList();

/// Full optional catalogue — every canonical optional key with its display
/// metadata. Filtered down to [kOptionalFeatures] for the selection UI and
/// used by review surfaces to label historical selections safely.
const List<RegistrationFeature> kSelectableOptionalCatalogue = [
  RegistrationFeature('organization_structure', 'Organization Structure',
      'Branches, departments and designations.'),
  RegistrationFeature('users_and_roles', 'Users and Roles',
      'User accounts and role-based access.'),
  RegistrationFeature('location_tracking', 'Location Tracking',
      'Work-hours employee location tracking.'),
  RegistrationFeature('geo_fence', 'Geo Fence',
      'Restrict attendance check-in/check-out to the configured office '
      'location radius.'),
  RegistrationFeature('tasks', 'Tasks',
      'Task assignment and tracking.'),
  RegistrationFeature('leave_management', 'Leave Management',
      'Leave types, requests and approvals.'),
  RegistrationFeature('payroll', 'Payroll',
      'Salary processing and payslips.'),
  RegistrationFeature('recruitment', 'Recruitment',
      'Candidate pipeline and onboarding.'),
  RegistrationFeature('performance', 'Performance',
      'Employee rewards and recognition.'),
  RegistrationFeature('reporting', 'Reporting',
      'Analytics and management reports.'),
  RegistrationFeature('events', 'Events',
      'Organization events and announcements.'),
];

/// Full catalogue (basic + all canonical optionals) — used by review
/// surfaces so historical selections still render a friendly label even
/// when the module is no longer selectable.
final List<RegistrationFeature> kSelectableFeatures = [
  ...kBasicFeatures,
  ...kSelectableOptionalCatalogue,
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
    // Basic HRMS features are locked — never toggled from this UI.
    if (isBasicHrmsFeature(id)) return;
    setState(() {
      if (selected == true) {
        _controller.draft.requestedFeatures.add(id);
      } else {
        _controller.draft.requestedFeatures.remove(id);
      }
    });
  }

  Widget _featureCard(
    RegistrationFeature f, {
    required bool selected,
    required bool locked,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? _kPrimaryDark : Colors.grey.shade300,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: _kPrimaryDark,
        value: selected,
        // Locked basics: onChanged null disables interaction so the
        // applicant cannot deselect mandatory core modules.
        onChanged: locked ? null : (v) => _toggle(f.id, v),
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
    );
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
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Basic HRMS — Included by Default',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: _kPrimaryDark,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'These core HRMS modules are included by default.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ),
          ...kBasicFeatures.map((f) => _featureCard(
                f,
                selected: true,
                locked: true,
              )),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Optional HRMS Modules',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: _kPrimaryDark,
              ),
            ),
          ),
          ...kOptionalFeatures.map((f) => _featureCard(
                f,
                selected: selected.contains(f.id),
                locked: false,
              )),
          const SizedBox(height: 8),
          // Count only modules selectable in the current flow — legacy
          // keys already in the draft are preserved but not counted here.
          Text(
            '${selected.where(kImplementedOptionalFeatures.contains).length + kBasicFeatures.length} feature(s) requested',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
