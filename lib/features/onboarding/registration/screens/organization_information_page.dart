// lib/features/onboarding/registration/screens/organization_information_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serv_app/features/onboarding/screens/select_user_type_page.dart';
import '../controllers/registration_draft_controller.dart';
import '../widgets/registration_form_section.dart';
import 'feature_selection_page.dart';

const List<String> kRegistrationStepLabels = [
  'Organization',
  'Features',
  'HR / Admin',
  'Verification',
  'Documents',
];

const List<String> _kOrgTypes = [
  'Private Limited',
  'Public Limited',
  'Partnership',
  'LLP',
  'Proprietorship',
  'Non-Profit',
  'Government',
  'Other',
];

const List<String> _kIndustries = [
  'Information Technology',
  'Manufacturing',
  'Healthcare',
  'Education',
  'Retail',
  'Finance & Banking',
  'Logistics & Transport',
  'Hospitality',
  'Construction',
  'Professional Services',
  'Other',
];

/// Step 1 — Organization Information.
class OrganizationInformationPage extends StatefulWidget {
  const OrganizationInformationPage({super.key});

  @override
  State<OrganizationInformationPage> createState() =>
      _OrganizationInformationPageState();
}

class _OrganizationInformationPageState
    extends State<OrganizationInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = RegistrationDraftController.instance;
  bool _busy = false;

  late final TextEditingController _name;
  late final TextEditingController _employeeCount;
  late final TextEditingController _branchCount;
  late final TextEditingController _address;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _gst;
  late final TextEditingController _cin;

  String? _orgType;
  String? _industry;

  @override
  void initState() {
    super.initState();
    final d = _controller.draft;
    _name = TextEditingController(text: d.organizationName);
    _employeeCount = TextEditingController(text: d.employeeCount);
    _branchCount = TextEditingController(text: d.branchCount);
    _address = TextEditingController(text: d.registeredAddress);
    _email = TextEditingController(text: d.officialEmail);
    _phone = TextEditingController(text: d.contactNumber);
    _website = TextEditingController(text: d.website);
    _gst = TextEditingController(text: d.gstNumber);
    _cin = TextEditingController(text: d.cinNumber);
    _orgType = d.organizationType.isEmpty ? null : d.organizationType;
    _industry = d.industry.isEmpty ? null : d.industry;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _employeeCount, _branchCount, _address, _email, _phone,
      _website, _gst, _cin,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _writeDraft() {
    final d = _controller.draft;
    d.organizationName = _name.text.trim();
    d.organizationType = _orgType ?? '';
    d.industry = _industry ?? '';
    d.employeeCount = _employeeCount.text.trim();
    d.branchCount = _branchCount.text.trim();
    d.registeredAddress = _address.text.trim();
    d.officialEmail = _email.text.trim();
    d.contactNumber = _phone.text.trim();
    d.website = _website.text.trim();
    d.gstNumber = _gst.text.trim();
    d.cinNumber = _cin.text.trim();
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
      RegistrationDraftController.stepOrganization,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FeatureSelectionPage()),
    );
  }

  void _back() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SelectUserTypePage()),
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

  String? _phoneValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Contact number is required';
    final ok = RegExp(r'^[+0-9][0-9\s\-()]{6,19}$').hasMatch(value);
    return ok ? null : 'Enter a valid contact number';
  }

  String? _websiteValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null; // optional
    final ok = RegExp(r'^(https?://)?[\w\-]+(\.[\w\-]+)+(/.*)?$')
        .hasMatch(value);
    return ok ? null : 'Enter a valid website URL';
  }

  String? _positiveInt(String? v, String label, {bool required = true}) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) {
      return required ? '$label is required' : null;
    }
    final n = int.tryParse(value);
    if (n == null || n < 0) return 'Enter a valid number';
    return null;
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
        borderSide: const BorderSide(color: Color(0xFF655193), width: 1.6),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationFormSection(
      title: 'Organization Information',
      subtitle: 'Step 1 of 4 — Tell us about your organization.',
      currentStep: RegistrationDraftController.stepOrganization,
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
            TextFormField(
              controller: _name,
              decoration: _decoration('Organization Name *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Organization name'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _orgType,
              decoration: _decoration('Organization Type *'),
              items: _kOrgTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _orgType = v),
              validator: (v) =>
                  v == null ? 'Select an organization type' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _industry,
              decoration: _decoration('Industry *'),
              items: _kIndustries
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _industry = v),
              validator: (v) => v == null ? 'Select an industry' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _employeeCount,
                    decoration: _decoration('Employee Count *'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => _positiveInt(v, 'Employee count'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _branchCount,
                    decoration: _decoration('No. of Branches *'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => _positiveInt(v, 'Branch count'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              decoration: _decoration('Registered Address *'),
              maxLines: 3,
              validator: (v) => _required(v, 'Registered address'),
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
              controller: _phone,
              decoration: _decoration('Contact Number *'),
              keyboardType: TextInputType.phone,
              validator: _phoneValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _website,
              decoration:
                  _decoration('Website', hint: 'Optional — e.g. https://…'),
              keyboardType: TextInputType.url,
              validator: _websiteValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _gst,
              decoration:
                  _decoration('GST Number', hint: 'Optional — if applicable'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cin,
              decoration: _decoration('CIN / Registration Number',
                  hint: 'Optional — if applicable'),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
    );
  }
}
