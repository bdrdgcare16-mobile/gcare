import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/countries.dart' as ipf;
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:serv_app/features/admin/admin_dashboard_page.dart';
import 'package:serv_app/features/company_admin/company_admin_page.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/models/company_profile.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/utils/logout.dart';
import 'package:serv_app/features/admin/admin_theme.dart';

// Lavender design tokens for this page (per spec)
const Color _kPageBg = Color(0xFFF7F3FC);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF6F42C1);
const Color _kPrimaryDark = Color(0xFF4B287C);
const Color _kFieldFill = Color(0xFFF2ECFA);
const Color _kBorder = Color(0xFFE4D8F3);
const Color _kFocus = Color(0xFF8B5CF6);
const Color _kError = Color(0xFFDC3545);
const Color _kText = Color(0xFF2E2350);
const Color _kMuted = Color(0xFF7C6E9B);

class CompanyDetailsFormPage extends StatefulWidget {
  const CompanyDetailsFormPage({super.key});

  @override
  State<CompanyDetailsFormPage> createState() => _CompanyDetailsFormPageState();
}

class _CompanyDetailsFormPageState extends State<CompanyDetailsFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminRoleController = TextEditingController();

  final _companyNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _websiteFocus = FocusNode();
  final _adminNameFocus = FocusNode();
  final _adminRoleFocus = FocusNode();

  XFile? _logoFile;
  Uint8List? _logoBytes;
  String? _logoError;
  bool _isSubmitting = false;
  // Once the user has attempted a submit, the phone error is surfaced via
  // decoration.errorText as well (IntlPhoneField's internal validator only
  // reports values computed during onChanged, so a never-touched field
  // would otherwise pass form validation silently).
  bool _phoneForceError = false;
  final ImagePicker _picker = ImagePicker();

  ipf.Country _country = ipf.countries.firstWhere((c) => c.code == 'IN');

  String _getMimeType(String name) {
    final extension = name.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _adminNameController.dispose();
    _adminRoleController.dispose();
    _companyNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _websiteFocus.dispose();
    _adminNameFocus.dispose();
    _adminRoleFocus.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    // Downscale large picks — the logo is stored as a base64 data URI inside
    // the Firestore profile document, whose per-field limit is ~1MB, so the
    // backend only accepts images up to ~700KB.
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final mimeType = (picked.mimeType != null && picked.mimeType!.isNotEmpty)
        ? picked.mimeType!
        : _getMimeType(picked.name);

    if (!const ['image/jpeg', 'image/png', 'image/gif'].contains(mimeType)) {
      setState(() => _logoError = 'Only JPEG, PNG or GIF images are allowed');
      return;
    }
    if (bytes.length > 700 * 1024) {
      setState(() => _logoError = 'Logo must be smaller than 700KB');
      return;
    }

    setState(() {
      _logoFile = picked;
      _logoBytes = bytes;
      _logoError = null;
    });
  }

  void _removeLogo() {
    setState(() {
      _logoFile = null;
      _logoBytes = null;
      _logoError = null;
    });
  }

  // ---------- Validators ----------

  String? _validateCompanyName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Company name is required' : null;

  String? _validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email address is required';
    if (s.contains(' ')) return 'Email must not contain spaces';
    final pattern =
        r'^[A-Za-z0-9]+([._-]?[A-Za-z0-9]+)*@[A-Za-z0-9-]+(\.[A-Za-z]{2,})+$';
    return RegExp(pattern).hasMatch(s) ? null : 'Enter a valid email address';
  }

  String _nationalNumber(String raw, ipf.Country country) {
    var n = raw.replaceAll(RegExp(r'[^0-9]'), '');
    // Strip an accidentally pasted country-code prefix (e.g. "91" for India)
    // when the remaining digits form a plausible national number.
    if (n.startsWith(country.dialCode) &&
        n.length - country.dialCode.length >= country.minLength &&
        n.length - country.dialCode.length <= country.maxLength) {
      n = n.substring(country.dialCode.length);
    }
    return n;
  }

  String? _validatePhoneValue(String raw, ipf.Country country) {
    final s = raw.trim();
    if (s.isEmpty) return 'Phone number is required';
    if (RegExp(r'[A-Za-z]').hasMatch(s)) {
      return 'Phone number must contain digits only';
    }
    final national = _nationalNumber(s, country);
    if (country.code == 'IN') {
      if (national.length != 10) {
        return 'Enter a valid 10-digit mobile number';
      }
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(national)) {
        return 'Indian mobile numbers start with 6, 7, 8 or 9';
      }
      return null;
    }
    if (national.length < country.minLength ||
        national.length > country.maxLength) {
      return 'Enter a valid phone number for ${country.name}';
    }
    return null;
  }

  String? _validatePhone(PhoneNumber? _) =>
      _validatePhoneValue(_phoneController.text, _country);

  String? _validateUrl(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // optional
    final uri = Uri.tryParse(s);
    final ok = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.contains('.');
    return ok ? null : 'Enter a valid URL (e.g. https://example.com)';
  }

  String? _validatePersonName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Admin full name is required';
    final ok =
        RegExp(r"^[\p{L}]+(?:[ .'-][\p{L}]+)*$", unicode: true).hasMatch(s);
    return ok ? null : 'Enter a valid name';
  }

  String? _validateDesignation(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Designation is required' : null;

  void _focusFirstInvalid() {
    final checks = <FocusNode, String? Function()>{
      _companyNameFocus: () =>
          _validateCompanyName(_companyNameController.text),
      _emailFocus: () => _validateEmail(_emailController.text),
      _phoneFocus: () => _validatePhoneValue(_phoneController.text, _country),
      _websiteFocus: () => _validateUrl(_websiteController.text),
      _adminNameFocus: () => _validatePersonName(_adminNameController.text),
      _adminRoleFocus: () => _validateDesignation(_adminRoleController.text),
    };
    for (final entry in checks.entries) {
      if (entry.value() != null) {
        entry.key.requestFocus();
        break;
      }
    }
  }

  // ---------- Submit ----------

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final fieldsOk = _formKey.currentState?.validate() ?? false;
    // IntlPhoneField's own validator only runs on change — validate the
    // phone value directly so an untouched field can't slip through.
    final phoneError = _validatePhoneValue(_phoneController.text, _country);
    if (phoneError != null && !_phoneForceError) {
      setState(() => _phoneForceError = true);
    }
    if (!fieldsOk || phoneError != null) {
      _focusFirstInvalid();
      return;
    }

    final token = CompanyData.token;
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Save fields into shared model
      CompanyData.companyName = _companyNameController.text.trim();
      CompanyData.email = _emailController.text.trim();
      CompanyData.phone =
          '+${_country.dialCode}${_nationalNumber(_phoneController.text, _country)}';
      CompanyData.website = _websiteController.text.trim();
      CompanyData.adminName = _adminNameController.text.trim();
      CompanyData.adminRole = _adminRoleController.text.trim();

      final Map<String, dynamic> requestBody = {
        'companyName': CompanyData.companyName,
        'email': CompanyData.email,
        'phone': CompanyData.phone,
        'website': CompanyData.website,
        'adminName': CompanyData.adminName,
        'designation': CompanyData.adminRole,
      };

      if (_logoFile != null && _logoBytes != null) {
        requestBody['logoBase64'] = base64Encode(_logoBytes!);
        requestBody['logoMimeType'] =
            (_logoFile!.mimeType != null && _logoFile!.mimeType!.isNotEmpty)
                ? _logoFile!.mimeType!
                : _getMimeType(_logoFile!.name);
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/company/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final bool isSuccess = responseData['message']
                ?.toString()
                .toLowerCase()
                .contains('success') ??
            false;

        if (isSuccess) {
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            if (!mounted) return;

            // Company Admin completes this form on first login — it goes
            // to its own scoped dashboard, never the SERV admin one.
            final Widget next = CompanyData.role == 'company_admin'
                ? const CompanyAdminPage()
                : AdminDashboard(
                    companyProfile: CompanyProfile(
                      name: CompanyData.companyName,
                      adminName: CompanyData.adminName,
                      logoUrl: _logoFile?.path,
                    ),
                  );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => next),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Submission failed'),
              ),
            );
          }
        }
      } else {
        String message = 'Submission failed: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            message = errorData['message'].toString();
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // ---------- Back ----------

  Future<void> _onBack() async {
    if (_isSubmitting) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    // No safe previous screen (this page is reached via pushReplacement /
    // pushAndRemoveUntil after login) — run the standard logout flow which
    // clears the session and lands on LoginPage. Profile completion is
    // never bypassed: logging in again re-runs the profile check.
    await logout(context);
  }

  // ---------- UI ----------

  InputDecoration _decoration({
    required String label,
    String? hint,
    bool required = true,
  }) {
    return InputDecoration(
      label: required
          ? Text.rich(
              TextSpan(
                text: label,
                children: const [
                  TextSpan(text: ' *', style: TextStyle(color: _kError)),
                ],
              ),
            )
          : Text(label),
      hintText: hint,
      filled: true,
      fillColor: _kFieldFill,
      // Subtle brighten on hover, lighter still on focus (M3 state overlays).
      hoverColor: const Color(0x59FFFFFF),
      focusColor: const Color(0x8FFFFFFF),
      labelStyle: const TextStyle(
        color: _kPrimaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle:
          const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kFocus, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kError, width: 1.8),
      ),
      errorMaxLines: 2,
    );
  }

  Widget _backButton() {
    return TextButton.icon(
      onPressed: _isSubmitting ? null : _onBack,
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        foregroundColor: _kPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? _kPrimary.withValues(alpha: 0.10)
              : null,
        ),
      ),
    );
  }

  Widget _logoPicker() {
    final hasLogo = _logoFile != null && _logoBytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Logo (optional)',
          style: TextStyle(
            color: _kPrimaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSubmitting ? null : _pickLogo,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kFieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _logoError != null ? _kError : _kBorder,
                width: 1.2,
              ),
            ),
            child: hasLogo
                ? Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _logoBytes!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _logoFile!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _isSubmitting ? null : _pickLogo,
                        child: const Text('Change',
                            style: TextStyle(color: _kPrimary)),
                      ),
                      TextButton(
                        onPressed: _isSubmitting ? null : _removeLogo,
                        child: const Text('Remove',
                            style: TextStyle(color: _kError)),
                      ),
                    ],
                  )
                : const Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          color: _kPrimary, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload company logo',
                              style: TextStyle(
                                color: _kText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'JPEG, PNG or GIF · up to 700KB',
                              style: TextStyle(color: _kMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.add_photo_alternate_outlined, color: _kMuted),
                    ],
                  ),
          ),
        ),
        if (_logoError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              _logoError!,
              style: const TextStyle(color: _kError, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hPad = width < 480 ? 16.0 : 24.0;
    final double cardPad = width < 480 ? 20.0 : 32.0;
    const double gap = 18.0;

    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _backButton(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: cardPad,
                      vertical: cardPad,
                    ),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D4B287C),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Company Details',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _kText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Complete your company profile to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _kMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          _logoPicker(),
                          const SizedBox(height: gap),
                          TextFormField(
                            controller: _companyNameController,
                            focusNode: _companyNameFocus,
                            enabled: !_isSubmitting,
                            decoration: _decoration(label: 'Company Name'),
                            textInputAction: TextInputAction.next,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: _validateCompanyName,
                          ),
                          const SizedBox(height: gap),
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            enabled: !_isSubmitting,
                            decoration: _decoration(
                              label: 'Official Email Address',
                              hint: 'name@company.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: gap),
                          IntlPhoneField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            enabled: !_isSubmitting,
                            initialCountryCode: 'IN',
                            disableLengthCheck: true,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                  _country.maxLength + 6),
                            ],
                            decoration: _decoration(
                              label: 'Phone Number',
                              hint: 'Enter phone number',
                            ).copyWith(
                              errorText: _phoneForceError
                                  ? _validatePhoneValue(
                                      _phoneController.text, _country)
                                  : null,
                            ),
                            dropdownTextStyle: const TextStyle(
                              color: _kText,
                              fontWeight: FontWeight.w600,
                            ),
                            dropdownIcon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _kPrimaryDark,
                            ),
                            flagsButtonPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            pickerDialogStyle: PickerDialogStyle(
                              backgroundColor: Colors.white,
                              searchFieldInputDecoration: _decoration(
                                label: 'Search country',
                                required: false,
                              ),
                            ),
                            validator: _validatePhone,
                            onChanged: (p) {
                              // Keep the latest ISO/dial code in sync with
                              // whatever the user picked, and rebuild so a
                              // forced error clears as the user fixes it.
                              final c = ipf.countries.firstWhere(
                                (c) => c.code == p.countryISOCode,
                                orElse: () => _country,
                              );
                              setState(() => _country = c);
                            },
                            onCountryChanged: (c) =>
                                setState(() => _country = c),
                          ),
                          const SizedBox(height: gap),
                          TextFormField(
                            controller: _websiteController,
                            focusNode: _websiteFocus,
                            enabled: !_isSubmitting,
                            decoration: _decoration(
                              label: 'Official Website (optional)',
                              hint: 'https://example.com',
                              required: false,
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: _validateUrl,
                          ),
                          const SizedBox(height: gap),
                          TextFormField(
                            controller: _adminNameController,
                            focusNode: _adminNameFocus,
                            enabled: !_isSubmitting,
                            decoration: _decoration(label: 'Admin Full Name'),
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: _validatePersonName,
                          ),
                          const SizedBox(height: gap),
                          TextFormField(
                            controller: _adminRoleController,
                            focusNode: _adminRoleFocus,
                            enabled: !_isSubmitting,
                            decoration: _decoration(label: 'Admin Designation'),
                            textInputAction: TextInputAction.done,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: _validateDesignation,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    _kPrimary.withValues(alpha: 0.65),
                                disabledForegroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ).copyWith(
                                overlayColor: WidgetStateProperty.resolveWith(
                                  (states) => states
                                          .contains(WidgetState.hovered)
                                      ? _kPrimaryDark.withValues(alpha: 0.28)
                                      : null,
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Submit'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
