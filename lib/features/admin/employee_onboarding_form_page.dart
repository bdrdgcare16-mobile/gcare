import 'dart:convert';
import 'package:universal_io/io.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/services/onboarding_service.dart';
import 'dev/onboarding_dummy_data.dart';

class EmployeeOnboardingFormPage extends StatefulWidget {
  const EmployeeOnboardingFormPage({super.key});

  @override
  State<EmployeeOnboardingFormPage> createState() =>
      _EmployeeOnboardingFormPageState();
}

class CountryCode {
  final String id;
  final String flag;
  final String dialCode;
  final String countryName;

  const CountryCode({
    required this.id,
    required this.flag,
    required this.dialCode,
    required this.countryName,
  });
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class FullNameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = newValue.text.replaceAll(RegExp(r'[^a-zA-Z ]'), '');
    final collapsed = filtered.replaceAll(RegExp(r'\s+'), ' ');
    return TextEditingValue(
      text: collapsed,
      selection: TextSelection.collapsed(offset: collapsed.length),
    );
  }
}

class _UploadRule {
  final List<String> allowedExtensions;
  final int maxSizeMB;
  final String sizeErrorMessage;

  const _UploadRule({
    required this.allowedExtensions,
    required this.maxSizeMB,
    required this.sizeErrorMessage,
  });

  String get helperText =>
      '${allowedExtensions.map((e) => e.toUpperCase()).join(', ')} • Max $maxSizeMB MB';
  int get maxBytes => maxSizeMB * 1024 * 1024;
}

const _uploadRules = <String, _UploadRule>{
  'resume': _UploadRule(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      maxSizeMB: 5,
      sizeErrorMessage: 'File size must not exceed 5 MB.'),
  'offerLetter': _UploadRule(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      maxSizeMB: 5,
      sizeErrorMessage: 'File size must not exceed 5 MB.'),
  'aadhaarCard': _UploadRule(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      maxSizeMB: 5,
      sizeErrorMessage: 'File size must not exceed 5 MB.'),
  'panCard': _UploadRule(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      maxSizeMB: 5,
      sizeErrorMessage: 'File size must not exceed 5 MB.'),
  'bankProof': _UploadRule(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      maxSizeMB: 5,
      sizeErrorMessage: 'File size must not exceed 5 MB.'),
  'degreeCertificate': _UploadRule(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      maxSizeMB: 5,
      sizeErrorMessage: 'File size must not exceed 5 MB.'),
  'passportPhoto': _UploadRule(
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      maxSizeMB: 2,
      sizeErrorMessage: 'Passport Size Photo must not exceed 2 MB.'),
  'experienceCertificate': _UploadRule(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      maxSizeMB: 5,
      sizeErrorMessage: 'File size must not exceed 5 MB.'),
  'relievingLetter': _UploadRule(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      maxSizeMB: 5,
      sizeErrorMessage: 'File size must not exceed 5 MB.'),
};

class ImagePreviewPage extends StatelessWidget {
  final String? imagePath;
  final Uint8List? imageBytes;

  const ImagePreviewPage({
    super.key,
    this.imagePath,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Image Preview',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: imageBytes != null
              ? MemoryImage(imageBytes!)
              : FileImage(io.File(imagePath!)) as ImageProvider,
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.0,
          enableRotation: true,
        ),
      ),
    );
  }
}

class PdfPreviewPage extends StatelessWidget {
  final String? filePath;
  final Uint8List? fileBytes;

  const PdfPreviewPage({
    super.key,
    this.filePath,
    this.fileBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8C6EAF),
        title: const Text(
          'PDF Preview',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: fileBytes != null
          ? SfPdfViewer.memory(fileBytes!)
          : SfPdfViewer.file(io.File(filePath!)),
    );
  }
}

class _EmployeeOnboardingFormPageState
    extends State<EmployeeOnboardingFormPage> {
  bool _isDataLoaded = false; // Prevent duplicate data loading
  final _formKey = GlobalKey<FormState>();

  String? gender;
  String? workMode;
  String? employeeType;
  String? experienceLevel;

  // New state variables for form fields
  DateTime? selectedDate;
  String? selectedCountryId = 'IN'; // Default to India
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _dateOfJoiningController =
      TextEditingController();
  final TextEditingController _permanentAddressController =
      TextEditingController();
  final TextEditingController _emergencyContactNameController =
      TextEditingController();

  // Bank & Payroll controllers
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountHolderNameController =
      TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();
  final TextEditingController _aadhaarNumberController =
      TextEditingController();
  final TextEditingController _pfNumberController = TextEditingController();
  final TextEditingController _esiNumberController = TextEditingController();
  final TextEditingController _basicSalaryController = TextEditingController();
  final TextEditingController _hraController = TextEditingController();
  final TextEditingController _allowancesController = TextEditingController();
  final TextEditingController _grossSalaryController = TextEditingController();
  final TextEditingController _netSalaryController = TextEditingController();

  // Company details controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _branchLocationController =
      TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _officialEmailController =
      TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _shiftTimeController = TextEditingController();
  final TextEditingController _yearsOfExperienceController =
      TextEditingController();
  final TextEditingController _reportingManagerController =
      TextEditingController();

  // Pincode validation states
  bool _isCheckingPincode = false;
  String? _pincodeError;
  bool _isCityStateAutoFilled = false;

  // Date of joining state
  DateTime? selectedDateOfJoining;

  // Emergency contact country code
  String? selectedEmergencyCountryId = 'IN'; // Default to India

  // Document files storage
  String? resumeFile;
  String? offerLetterFile;
  String? aadhaarCardFile;
  String? panCardFile;
  String? bankProofFile;
  String? degreeCertificateFile;
  String? passportPhotoFile;
  String? experienceCertificateFile;
  String? relievingLetterFile;

  // Map to track uploaded files
  Map<String, PlatformFile> uploadedFiles = {};

  // Loading state for submission
  bool _isSubmitting = false;

  // Shift dropdown state (fetched from /api/shifts, scoped to the admin's company)
  List<Map<String, dynamic>> _shifts = [];
  bool _isLoadingShifts = false;
  String? _shiftsError;
  String? _selectedShiftName;

  // Country codes with unique IDs
  final List<CountryCode> countryCodes = [
    const CountryCode(
        id: 'IN', flag: '🇮🇳', dialCode: '+91', countryName: 'India'),
    const CountryCode(
        id: 'US', flag: '🇺🇸', dialCode: '+1', countryName: 'United States'),
    const CountryCode(
        id: 'GB', flag: '🇬🇧', dialCode: '+44', countryName: 'United Kingdom'),
    const CountryCode(
        id: 'AE',
        flag: '🇦🇪',
        dialCode: '+971',
        countryName: 'United Arab Emirates'),
    const CountryCode(
        id: 'AU', flag: '🇦🇺', dialCode: '+61', countryName: 'Australia'),
    const CountryCode(
        id: 'CA', flag: '🇨🇦', dialCode: '+1', countryName: 'Canada'),
    const CountryCode(
        id: 'SG', flag: '🇸🇬', dialCode: '+65', countryName: 'Singapore'),
    const CountryCode(
        id: 'MY', flag: '🇲🇾', dialCode: '+60', countryName: 'Malaysia'),
    const CountryCode(
        id: 'LK', flag: '🇱🇰', dialCode: '+94', countryName: 'Sri Lanka'),
    const CountryCode(
        id: 'NP', flag: '🇳🇵', dialCode: '+977', countryName: 'Nepal'),
    const CountryCode(
        id: 'BD', flag: '🇧🇩', dialCode: '+880', countryName: 'Bangladesh'),
    const CountryCode(
        id: 'PK', flag: '🇵🇰', dialCode: '+92', countryName: 'Pakistan'),
    const CountryCode(
        id: 'SA', flag: '🇸🇦', dialCode: '+966', countryName: 'Saudi Arabia'),
    const CountryCode(
        id: 'QA', flag: '🇶🇦', dialCode: '+974', countryName: 'Qatar'),
    const CountryCode(
        id: 'KW', flag: '🇰🇼', dialCode: '+965', countryName: 'Kuwait'),
    const CountryCode(
        id: 'OM', flag: '🇴🇲', dialCode: '+968', countryName: 'Oman'),
  ];

  InputDecoration inputDecoration(String label, {bool isRequired = false}) {
    return InputDecoration(
      label: isRequired
          ? Text.rich(
              TextSpan(
                text: label,
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            )
          : Text(label),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
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
        borderSide: const BorderSide(color: Color(0xFF655193), width: 1.5),
      ),
      labelStyle: const TextStyle(
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 12,
      ),
      errorMaxLines: 3,
      helperMaxLines: 2,
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4B3B73),
        ),
      ),
    );
  }

  Widget textField(String label,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: inputDecoration(label, isRequired: isRequired),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: inputDecoration(label, isRequired: isRequired),
        isExpanded: true,
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget uploadField(String title,
      {String? fileName,
      required String documentType,
      bool isRequired = false}) {
    final uploadedFile = uploadedFiles[documentType];
    final isUploaded = uploadedFile != null &&
        ((uploadedFile.path != null && uploadedFile.path!.isNotEmpty) ||
            (uploadedFile.bytes != null && uploadedFile.bytes!.isNotEmpty));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              isUploaded
                  ? const Icon(Icons.check_circle,
                      color: Colors.green, size: 20)
                  : const Icon(Icons.upload_file, color: Color(0xFF655193)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: title,
                        children: isRequired
                            ? [
                                const TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ]
                            : null,
                      ),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _uploadRules[documentType]?.helperText ?? '',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    if (isUploaded)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          uploadedFile.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View button
                  IconButton(
                    onPressed:
                        isUploaded ? () => viewDocument(documentType) : null,
                    icon: Icon(
                      Icons.visibility,
                      color: isUploaded ? const Color(0xFF655193) : Colors.grey,
                      size: 20,
                    ),
                    tooltip: 'View Document',
                  ),
                  const SizedBox(width: 4),
                  // Upload/Change button
                  TextButton(
                    onPressed: () => pickDocument(documentType),
                    child: Text(
                      isUploaded ? "Change" : "Upload",
                      style: const TextStyle(color: Color(0xFF655193)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _selectDateOfJoining(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateOfJoining ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDateOfJoining) {
      setState(() {
        selectedDateOfJoining = picked;
        _dateOfJoiningController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _calculateSalaries() {
    final basicSalary = double.tryParse(_basicSalaryController.text) ?? 0;
    final hra = double.tryParse(_hraController.text) ?? 0;
    final allowances = double.tryParse(_allowancesController.text) ?? 0;

    final gross = basicSalary + hra + allowances;
    final net = gross; // For now, net = gross (no deductions)

    setState(() {
      _grossSalaryController.text = gross.toStringAsFixed(2);
      _netSalaryController.text = net.toStringAsFixed(2);
    });
  }

  /// Resets the entire form to its initial empty state after successful submission
  void _resetOnboardingForm() {
    if (!mounted) return;
    setState(() {
      // Clear all TextEditingController values
      _dobController.clear();
      _fullNameController.clear();
      _emailController.clear();
      _mobileController.clear();
      _pincodeController.clear();
      _cityController.clear();
      _stateController.clear();
      _emergencyContactController.clear();
      _countryController.clear();
      _dateOfJoiningController.clear();
      _permanentAddressController.clear();
      _emergencyContactNameController.clear();
      _bankNameController.clear();
      _accountHolderNameController.clear();
      _accountNumberController.clear();
      _ifscCodeController.clear();
      _panNumberController.clear();
      _aadhaarNumberController.clear();
      _pfNumberController.clear();
      _esiNumberController.clear();
      _basicSalaryController.clear();
      _hraController.clear();
      _allowancesController.clear();
      _grossSalaryController.clear();
      _netSalaryController.clear();
      _companyNameController.clear();
      _branchLocationController.clear();
      _departmentController.clear();
      _designationController.clear();
      _officialEmailController.clear();
      _employeeIdController.clear();
      _shiftTimeController.clear();
      _yearsOfExperienceController.clear();
      _reportingManagerController.clear();

      // Reset dropdown selections to default/initial state
      gender = null;
      workMode = null;
      employeeType = null;
      experienceLevel = null;
      selectedCountryId = 'IN'; // Default to India
      selectedEmergencyCountryId = 'IN'; // Default to India

      // Reset date selections
      selectedDate = null;
      selectedDateOfJoining = null;

      // Reset file upload state
      uploadedFiles.clear();
      resumeFile = null;
      offerLetterFile = null;
      aadhaarCardFile = null;
      panCardFile = null;
      bankProofFile = null;
      degreeCertificateFile = null;
      passportPhotoFile = null;
      experienceCertificateFile = null;
      relievingLetterFile = null;

      // Reset validation states
      _pincodeError = null;
      _isCityStateAutoFilled = false;

      // Reset shift selection
      _selectedShiftName = null;

      // Reset form validation state
      _formKey.currentState?.reset();
    });
  }

  Future<void> _showSuccessDialog({
    required String fullName,
    required String dob,
  }) async {
    final now = DateTime.now();
    bool isBirthday = false;
    try {
      final parsed = DateFormat('dd-MM-yyyy').parse(dob);
      isBirthday = parsed.day == now.day && parsed.month == now.month;
    } catch (_) {
      isBirthday = false;
    }

    final message = isBirthday
        ? 'Employee onboarded successfully!\n\nHappy Birthday, $fullName!'
        : 'Employee onboarded successfully!';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOnboardingForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check required documents
    final requiredDocs = ['resume', 'offerLetter', 'aadhaarCard', 'panCard'];
    final missingDocs =
        requiredDocs.where((doc) => !uploadedFiles.containsKey(doc)).toList();

    if (missingDocs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Please upload required documents: ${missingDocs.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get country codes with fallback to India if not selected
      final selectedCountry = countryCodes.firstWhere(
        (country) => country.id == selectedCountryId,
        orElse: () => countryCodes.firstWhere((country) => country.id == 'IN'),
      );

      final selectedEmergencyCountry = countryCodes.firstWhere(
        (country) => country.id == selectedEmergencyCountryId,
        orElse: () => countryCodes.firstWhere((country) => country.id == 'IN'),
      );

      // Build form data
      final formData = OnboardingService.buildFormData(
        // Personal Details
        fullName:
            _fullNameController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
        gender: gender ?? '',
        dob: _dobController.text,
        personalEmail: _emailController.text,
        mobileCountryCode: selectedCountry.dialCode,
        mobileNumber: _mobileController.text,
        address: '',
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        country: _countryController.text,
        permanentAddress: _permanentAddressController.text,
        emergencyContactName: _emergencyContactNameController.text,
        emergencyCountryCode: selectedEmergencyCountry.dialCode,
        emergencyContactNumber: _emergencyContactController.text,

        // Company Details
        companyName: _companyNameController.text,
        branchLocation: _branchLocationController.text,
        dateOfJoining: _dateOfJoiningController.text,
        department: _departmentController.text,
        designation: _designationController.text,
        officialEmail: _officialEmailController.text,
        employeeId: _employeeIdController.text,
        shiftTime: _shiftTimeController.text,
        workMode: workMode ?? '',
        employeeType: employeeType ?? '',
        experienceLevel: experienceLevel ?? '',
        yearsOfExperience: experienceLevel == "Experienced"
            ? _yearsOfExperienceController.text
            : null,
        reportingManager: _reportingManagerController.text,

        // Bank Details
        bankName: _bankNameController.text,
        accountHolderName: _accountHolderNameController.text,
        accountNumber: _accountNumberController.text,
        ifscCode: _ifscCodeController.text,
        panNumber: _panNumberController.text,
        aadhaarNumber: _aadhaarNumberController.text,
        pfNumber: _pfNumberController.text.isNotEmpty
            ? _pfNumberController.text
            : null,
        esiNumber: _esiNumberController.text.isNotEmpty
            ? _esiNumberController.text
            : null,
        basicSalary: _basicSalaryController.text,
        hra: _hraController.text.isNotEmpty ? _hraController.text : '0',
        allowances: _allowancesController.text.isNotEmpty
            ? _allowancesController.text
            : '0',
        grossSalary: _grossSalaryController.text,
        netSalary: _netSalaryController.text,
      );

      // Address is no longer collected in the Admin Employee Onboarding form,
      // so do not send it to the backend.
      formData.remove('address');

      debugPrint(formData.toString());

      // Submit to backend
      final result = await OnboardingService.submitOnboarding(
        formData: formData,
        files: uploadedFiles,
      );

      if (result['success']) {
        final fullName =
            _fullNameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
        final dob = _dobController.text;
        await _showSuccessDialog(fullName: fullName, dob: dob);
        if (mounted) _resetOnboardingForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Submission failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> pickDocument(String key) async {
    try {
      final rule = _uploadRules[key];
      final allowedExtensions =
          rule?.allowedExtensions ?? ['pdf', 'jpg', 'jpeg', 'png'];
      final maxBytes = rule?.maxBytes ?? (5 * 1024 * 1024);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final selectedFile = result.files.single;
        if (selectedFile.bytes == null && selectedFile.path == null) return;
        if (selectedFile.size > maxBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(rule?.sizeErrorMessage ??
                    'File size must not exceed 5 MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        debugPrint("Selected file name: ${selectedFile.name}");
        debugPrint("Selected file path: ${selectedFile.path}");
        debugPrint("Selected file size: ${selectedFile.size} bytes");

        setState(() {
          uploadedFiles[key] = selectedFile;
        });
      }
    } catch (e) {
      debugPrint("File picker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to open file picker: $e")),
      );
    }
  }

  Future<void> viewDocument(String key) async {
    try {
      final file = uploadedFiles[key];

      if (file == null ||
          (file.bytes == null && (file.path == null || file.path!.isEmpty))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload a file first")),
        );
        return;
      }

      final filePath = file.path;
      final fileBytes = file.bytes;
      final fileName = file.name.toLowerCase();

      debugPrint("Opening file: $fileName");
      if (filePath != null) debugPrint("File path: $filePath");

      // Detect file type and navigate to appropriate preview page
      if (fileName.endsWith('.png') ||
          fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImagePreviewPage(
              imagePath: filePath,
              imageBytes: fileBytes,
            ),
          ),
        );
      } else if (fileName.endsWith('.pdf')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewPage(
              filePath: filePath,
              fileBytes: fileBytes,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unsupported file format")),
        );
      }
    } catch (e) {
      debugPrint("View document error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to open document: $e")),
      );
    }
  }

  Future<void> _fetchCityAndState(String pincode) async {
    if (pincode.length != 6) return;

    setState(() {
      _isCheckingPincode = true;
      _pincodeError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/$pincode'),
      );

      debugPrint('[Onboarding] Pincode API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        // API returns a List, not a direct Map
        if (decodedResponse is List &&
            decodedResponse.isNotEmpty &&
            decodedResponse[0]["Status"] == "Success" &&
            decodedResponse[0]["PostOffice"] != null &&
            decodedResponse[0]["PostOffice"].isNotEmpty) {
          final postOffice = decodedResponse[0]["PostOffice"][0];
          final city = postOffice["District"] ?? '';
          final state = postOffice["State"] ?? '';

          debugPrint(
              '[ONBOARDING DEBUG] Pincode auto-fill - City: "$city", State: "$state"');
          debugPrint(
              '[ONBOARDING DEBUG] Before auto-fill - cityController: "${_cityController.text}", stateController: "${_stateController.text}"');

          setState(() {
            _cityController.text = city;
            _stateController.text = state;
            _isCityStateAutoFilled = true;
            _pincodeError = null;
          });

          debugPrint(
              '[ONBOARDING DEBUG] After auto-fill - cityController: "${_cityController.text}", stateController: "${_stateController.text}"');
        } else {
          setState(() {
            _cityController.clear();
            _stateController.clear();
            _isCityStateAutoFilled = false;
            _pincodeError = 'Invalid pincode';
          });
        }
      } else {
        setState(() {
          _cityController.clear();
          _stateController.clear();
          _isCityStateAutoFilled = false;
          _pincodeError = 'Invalid pincode';
        });
      }
    } catch (e) {
      debugPrint('Pincode API Error: $e');
      setState(() {
        _cityController.clear();
        _stateController.clear();
        _isCityStateAutoFilled = false;
        _pincodeError = 'Invalid pincode';
      });
    } finally {
      setState(() {
        _isCheckingPincode = false;
      });
    }
  }

  void _fillDummyOnboardingData() {
    if (_isDataLoaded) {
      debugPrint(
          '[ONBOARDING DEBUG] _fillDummyOnboardingData skipped - data already loaded');
      return;
    }

    debugPrint('[ONBOARDING DEBUG] _fillDummyOnboardingData called');
    debugPrint(
        '[ONBOARDING DEBUG] Before filling - fullName: "${_fullNameController.text}"');

    // Clear controllers first to prevent duplicate values
    _fullNameController.clear();
    _dobController.clear();
    _emailController.clear();
    _mobileController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _countryController.clear();
    _permanentAddressController.clear();
    _emergencyContactNameController.clear();
    _emergencyContactController.clear();

    _fullNameController.text = OnboardingDummyData.fullName;
    debugPrint(
        '[ONBOARDING DEBUG] After filling fullName: "${_fullNameController.text}"');

    gender = OnboardingDummyData.gender;
    _dobController.text = OnboardingDummyData.dob;
    selectedDate = DateTime(2000, 1, 15);
    _emailController.text = OnboardingDummyData.personalEmail;
    selectedCountryId = OnboardingDummyData.countryId;
    _mobileController.text = OnboardingDummyData.mobileNumber;
    _cityController.text = OnboardingDummyData.city;
    _stateController.text = OnboardingDummyData.state;
    _pincodeController.text = OnboardingDummyData.pincode;
    _countryController.text = OnboardingDummyData.country;
    _permanentAddressController.text = OnboardingDummyData.permanentAddress;
    _emergencyContactNameController.text =
        OnboardingDummyData.emergencyContactName;
    selectedEmergencyCountryId = OnboardingDummyData.emergencyCountryId;
    _emergencyContactController.text =
        OnboardingDummyData.emergencyContactNumber;

    _companyNameController.text = OnboardingDummyData.companyName;
    _branchLocationController.text = OnboardingDummyData.branchLocation;
    _dateOfJoiningController.text = OnboardingDummyData.dateOfJoining;
    selectedDateOfJoining = DateTime(2026, 8, 1);
    _departmentController.text = OnboardingDummyData.department;
    _designationController.text = OnboardingDummyData.designation;
    _officialEmailController.text = OnboardingDummyData.officialEmail;
    _employeeIdController.text = OnboardingDummyData.employeeId;
    _shiftTimeController.text = OnboardingDummyData.shiftTime;
    workMode = OnboardingDummyData.workMode;
    employeeType = OnboardingDummyData.employeeType;
    experienceLevel = OnboardingDummyData.experienceLevel;
    _yearsOfExperienceController.text = OnboardingDummyData.yearsOfExperience;
    _reportingManagerController.text = OnboardingDummyData.reportingManager;

    // Clear remaining controllers before setting values
    _bankNameController.clear();
    _accountHolderNameController.clear();
    _accountNumberController.clear();
    _ifscCodeController.clear();
    _panNumberController.clear();
    _aadhaarNumberController.clear();
    _pfNumberController.clear();
    _esiNumberController.clear();
    _basicSalaryController.clear();
    _hraController.clear();
    _allowancesController.clear();
    _grossSalaryController.clear();
    _netSalaryController.clear();

    _bankNameController.text = OnboardingDummyData.bankName;
    _accountHolderNameController.text = OnboardingDummyData.accountHolderName;
    _accountNumberController.text = OnboardingDummyData.accountNumber;
    _ifscCodeController.text = OnboardingDummyData.ifscCode;
    _panNumberController.text = OnboardingDummyData.panNumber;
    _aadhaarNumberController.text = OnboardingDummyData.aadhaarNumber;
    _pfNumberController.text = OnboardingDummyData.pfNumber;
    _esiNumberController.text = OnboardingDummyData.esiNumber;
    _basicSalaryController.text = OnboardingDummyData.basicSalary;
    _hraController.text = OnboardingDummyData.hra;
    _allowancesController.text = OnboardingDummyData.allowances;
    _grossSalaryController.text = OnboardingDummyData.grossSalary;
    _netSalaryController.text = OnboardingDummyData.netSalary;

    debugPrint('[ONBOARDING DEBUG] _fillDummyOnboardingData completed');
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[ONBOARDING DEBUG] initState called');
    _loadShifts();
    if (OnboardingDummyData.enabled && !_isDataLoaded) {
      debugPrint('[ONBOARDING DEBUG] Calling _fillDummyOnboardingData');
      _isDataLoaded = true;
      _fillDummyOnboardingData();
    } else {
      debugPrint(
          '[ONBOARDING DEBUG] OnboardingDummyData is disabled or data already loaded');
    }
  }

  /// Loads shift templates from the existing /api/shifts endpoint. The backend
  /// already filters by the authenticated user's companyId, so no manual
  /// companyId is sent from the client.
  Future<void> _loadShifts() async {
    setState(() {
      _isLoadingShifts = true;
      _shiftsError = null;
    });

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (CompanyData.token.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${CompanyData.token}';
      }

      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/shifts'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is List
            ? decoded.cast<Map<String, dynamic>>()
            : decoded is Map<String, dynamic> && decoded['data'] is List
                ? (decoded['data'] as List).cast<Map<String, dynamic>>()
                : <Map<String, dynamic>>[];

        // Defensive: keep only shifts that belong to the admin's company.
        // The backend already filters, but this prevents any unexpected data
        // from being shown if the response format ever changes.
        final companyId = CompanyData.companyId;
        _shifts = list.where((s) {
          final shiftCompanyId = s['companyId']?.toString() ?? '';
          return shiftCompanyId.isEmpty || shiftCompanyId == companyId;
        }).toList();
      } else {
        _shiftsError = 'Failed to load shifts (${res.statusCode})';
      }
    } catch (e) {
      _shiftsError = 'Network error: $e';
    } finally {
      setState(() {
        _isLoadingShifts = false;
      });
    }
  }

  /// Converts a 24-hour "HH:mm" time string to Indian 12-hour format with AM/PM.
  /// Examples: 09:30 -> 09:30 AM, 17:30 -> 05:30 PM, 00:00 -> 12:00 AM,
  /// 12:00 -> 12:00 PM.
  String _formatTime12Hour(String hhmm) {
    try {
      final parts = hhmm.trim().split(':');
      if (parts.length < 2) return hhmm;
      final hour = int.tryParse(parts[0]) ?? -1;
      final minute = int.tryParse(parts[1]) ?? -1;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return hhmm;

      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final mm = minute.toString().padLeft(2, '0');
      return '$displayHour:$mm $period';
    } catch (_) {
      return hhmm;
    }
  }

  /// Builds the human-readable label for a shift item, combining its name and
  /// start/end times in 12-hour AM/PM format (e.g. "General (09:30 AM - 05:30 PM)").
  String _shiftLabel(Map<String, dynamic> shift) {
    final name = (shift['name']?.toString() ?? '').trim();
    final shiftname = (shift['shiftname']?.toString() ?? '').trim();
    final start = (shift['startTime']?.toString() ?? '').trim();
    final end = (shift['endTime']?.toString() ?? '').trim();
    final displayName = name.isNotEmpty
        ? name
        : (shiftname.isNotEmpty ? shiftname : 'Unnamed Shift');

    if (start.isNotEmpty && end.isNotEmpty) {
      return '$displayName (${_formatTime12Hour(start)} - ${_formatTime12Hour(end)})';
    }
    return displayName;
  }

  @override
  void dispose() {
    _dobController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _emergencyContactController.dispose();
    _countryController.dispose();
    _dateOfJoiningController.dispose();
    _permanentAddressController.dispose();
    _emergencyContactNameController.dispose();
    _bankNameController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _panNumberController.dispose();
    _aadhaarNumberController.dispose();
    _pfNumberController.dispose();
    _esiNumberController.dispose();
    _basicSalaryController.dispose();
    _hraController.dispose();
    _allowancesController.dispose();
    _grossSalaryController.dispose();
    _netSalaryController.dispose();
    _companyNameController.dispose();
    _branchLocationController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _officialEmailController.dispose();
    _employeeIdController.dispose();
    _shiftTimeController.dispose();
    _yearsOfExperienceController.dispose();
    _reportingManagerController.dispose();
    super.dispose();
  }

  Widget formCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.width < 360 ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(h, 8, h, h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                        children: [
                          TextSpan(
                            text: 'Employee',
                            style: TextStyle(color: Color(0xFF1E1B4B)),
                          ),
                          TextSpan(
                            text: ' Onboarding',
                            style: TextStyle(color: Color(0xFF8B5CF6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              sectionTitle("Section 1 - Personal Details"),
              formCard([
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _fullNameController,
                    decoration: inputDecoration("Full Name", isRequired: true),
                    inputFormatters: [
                      FullNameInputFormatter(),
                    ],
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Full Name is required.';
                      }
                      final normalized =
                          trimmed.replaceAll(RegExp(r'\s+'), ' ');
                      if (!RegExp(r'^[a-zA-Z]+(?: [a-zA-Z]+)*$')
                          .hasMatch(normalized)) {
                        return 'Full Name must contain letters only.';
                      }
                      return null;
                    },
                  ),
                ),
                dropdownField(
                  label: "Gender",
                  value: gender,
                  items: ["Male", "Female", "Other"],
                  onChanged: (val) => setState(() => gender = val),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    decoration:
                        inputDecoration("Date of Birth", isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Date of Birth is required";
                      }
                      return null;
                    },
                    onTap: () => _selectDate(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        inputDecoration("Personal Email", isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email is required";
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return "Enter a valid email address";
                      }
                      if (!value.endsWith('@gmail.com')) {
                        return "Only Gmail address is allowed";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: selectedCountryId,
                          decoration: inputDecoration("Code"),
                          isExpanded: true,
                          selectedItemBuilder: (context) {
                            return countryCodes.map((country) {
                              return Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${country.flag} ${country.dialCode}',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          },
                          items: countryCodes.map((country) {
                            return DropdownMenuItem<String>(
                              value: country.id,
                              child: Row(
                                children: [
                                  Text(
                                    country.flag,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${country.dialCode} ${country.countryName}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCountryId = value;
                              // Auto-fill Country field when country code is selected
                              final selectedCountry = countryCodes.firstWhere(
                                (country) => country.id == value,
                                orElse: () => const CountryCode(
                                    id: '',
                                    flag: '',
                                    dialCode: '',
                                    countryName: ''),
                              );
                              _countryController.text =
                                  selectedCountry.countryName;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 7,
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: inputDecoration("Mobile Number",
                              isRequired: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Mobile number is required";
                            }
                            if (value.length != 10) {
                              return "Mobile number must be exactly 10 digits";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _cityController,
                    decoration: inputDecoration("City", isRequired: true),
                    readOnly: _isCityStateAutoFilled,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isCityStateAutoFilled
                          ? Colors.grey.shade600
                          : Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "City is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _stateController,
                    decoration: inputDecoration("State", isRequired: true),
                    readOnly: _isCityStateAutoFilled,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isCityStateAutoFilled
                          ? Colors.grey.shade600
                          : Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "State is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration:
                        inputDecoration("Pincode", isRequired: true).copyWith(
                      errorText: _pincodeError,
                      suffixIcon: _isCheckingPincode
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF655193),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Pincode is required";
                      }
                      if (value.length != 6) {
                        return "Pincode must be exactly 6 digits";
                      }
                      if (_pincodeError != null) {
                        return _pincodeError;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value.length == 6) {
                        _fetchCityAndState(value);
                      } else if (value.length < 6) {
                        setState(() {
                          _pincodeError = null;
                          if (!_isCityStateAutoFilled) {
                            _cityController.clear();
                            _stateController.clear();
                          }
                        });
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _countryController,
                    decoration: inputDecoration("Country", isRequired: true),
                    readOnly: true,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Country is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _permanentAddressController,
                    maxLines: 2,
                    decoration:
                        inputDecoration("Permanent Address", isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Permanent Address is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _emergencyContactNameController,
                    decoration: inputDecoration("Emergency Contact Name",
                        isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Emergency Contact Name is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: selectedEmergencyCountryId,
                          decoration: inputDecoration("Code"),
                          isExpanded: true,
                          selectedItemBuilder: (context) {
                            return countryCodes.map((country) {
                              return Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${country.flag} ${country.dialCode}',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          },
                          items: countryCodes.map((country) {
                            return DropdownMenuItem<String>(
                              value: country.id,
                              child: Row(
                                children: [
                                  Text(
                                    country.flag,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${country.dialCode} ${country.countryName}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedEmergencyCountryId = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 7,
                        child: TextFormField(
                          controller: _emergencyContactController,
                          keyboardType: TextInputType.phone,
                          decoration: inputDecoration(
                              "Emergency Contact Number",
                              isRequired: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Emergency contact number is required";
                            }
                            if (value.length != 10) {
                              return "Emergency contact number must be exactly 10 digits";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              sectionTitle("Section 2 - Company Details"),
              formCard([
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _companyNameController,
                    decoration:
                        inputDecoration("Company Name", isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Company Name is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _branchLocationController,
                    decoration:
                        inputDecoration("Branch / Location", isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Branch / Location is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _dateOfJoiningController,
                    readOnly: true,
                    decoration:
                        inputDecoration("Date of Joining", isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Date of joining is required";
                      }
                      return null;
                    },
                    onTap: () => _selectDateOfJoining(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _departmentController,
                    decoration: inputDecoration("Department", isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Department is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _designationController,
                    decoration:
                        inputDecoration("Designation", isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Designation is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _officialEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        inputDecoration("Official Email", isRequired: true),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return "Official Email is required.";
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(trimmed)) {
                        return "Please enter a valid official email.";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _employeeIdController,
                    decoration:
                        inputDecoration("Employee ID", isRequired: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Employee ID is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _isLoadingShifts
                      ? InputDecorator(
                          decoration:
                              inputDecoration("Shift Time", isRequired: true),
                          child: const SizedBox(
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        )
                      : _shiftsError != null
                          ? InputDecorator(
                              decoration: inputDecoration("Shift Time",
                                      isRequired: true)
                                  .copyWith(
                                errorText: _shiftsError,
                                errorMaxLines: 2,
                              ),
                              child: const SizedBox(height: 20),
                            )
                          : _shifts.isEmpty
                              ? InputDecorator(
                                  decoration: inputDecoration("Shift Time",
                                          isRequired: true)
                                      .copyWith(
                                    errorText:
                                        "No shifts available for your company",
                                    errorMaxLines: 2,
                                  ),
                                  child: const SizedBox(height: 20),
                                )
                              : DropdownButtonFormField<String>(
                                  value: _selectedShiftName,
                                  isExpanded: true,
                                  decoration: inputDecoration("Shift Time",
                                      isRequired: true),
                                  items: _shifts.map((shift) {
                                    final value = (shift['name']?.toString() ??
                                            shift['shiftname']?.toString() ??
                                            '')
                                        .trim();
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        _shiftLabel(shift),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedShiftName = value;
                                      _shiftTimeController.text = value ?? '';
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Shift Time is required";
                                    }
                                    return null;
                                  },
                                ),
                ),
                dropdownField(
                  label: "Work Mode",
                  value: workMode,
                  items: ["Work From Office", "Work From Home", "Hybrid"],
                  onChanged: (val) => setState(() => workMode = val),
                ),
                dropdownField(
                  label: "Employee Type",
                  value: employeeType,
                  items: ["Full Time", "Part Time", "Intern", "Contract"],
                  onChanged: (val) => setState(() => employeeType = val),
                ),
                dropdownField(
                  label: "Experience Level",
                  value: experienceLevel,
                  items: ["Fresher", "Experienced"],
                  onChanged: (val) => setState(() => experienceLevel = val),
                ),
                if (experienceLevel == "Experienced")
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: _yearsOfExperienceController,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration("Years of Experience",
                          isRequired: true),
                      validator: (value) {
                        if (experienceLevel == "Experienced" &&
                            (value == null || value.isEmpty)) {
                          return "Years of Experience is required for experienced employees";
                        }
                        if (value != null && value.isNotEmpty) {
                          final years = int.tryParse(value);
                          if (years == null || years <= 0) {
                            return "Years of Experience must be greater than 0";
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _reportingManagerController,
                    decoration:
                        inputDecoration("Reporting Manager", isRequired: true),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return "Reporting Manager is required.";
                      }
                      return null;
                    },
                  ),
                ),
              ]),
              sectionTitle("Section 3 - Bank & Payroll Details"),
              formCard([
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _bankNameController,
                    decoration: inputDecoration("Bank Name", isRequired: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Bank Name is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _accountHolderNameController,
                    decoration: inputDecoration("Account Holder Name",
                        isRequired: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Account Holder Name is required";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration:
                        inputDecoration("Account Number", isRequired: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(18),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Account Number is required";
                      }
                      if (value.length < 9 || value.length > 18) {
                        return "Account Number must be between 9 and 18 digits";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _ifscCodeController,
                    decoration: inputDecoration("IFSC Code", isRequired: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      UpperCaseTextFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "IFSC Code is required";
                      }
                      final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
                      if (!ifscRegex.hasMatch(value)) {
                        return "Enter a valid IFSC Code";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _panNumberController,
                    decoration: inputDecoration("PAN Number", isRequired: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "PAN Number is required";
                      }
                      final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                      if (!panRegex.hasMatch(value)) {
                        return "Enter a valid PAN Number";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _aadhaarNumberController,
                    keyboardType: TextInputType.number,
                    decoration:
                        inputDecoration("Aadhaar Number", isRequired: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Aadhaar Number is required";
                      }
                      if (value.length != 12) {
                        return "Aadhaar Number must be exactly 12 digits";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _pfNumberController,
                    decoration: inputDecoration("PF Number"),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                          return "PF Number must be alphanumeric";
                        }
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _esiNumberController,
                    keyboardType: TextInputType.number,
                    decoration: inputDecoration("ESI Number"),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return "ESI Number must contain digits only";
                        }
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _basicSalaryController,
                    keyboardType: TextInputType.number,
                    decoration:
                        inputDecoration("Basic Salary", isRequired: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _calculateSalaries(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Basic Salary is required";
                      }
                      final salary = double.tryParse(value);
                      if (salary == null || salary <= 0) {
                        return "Basic Salary must be greater than 0";
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _hraController,
                    keyboardType: TextInputType.number,
                    decoration: inputDecoration("HRA", isRequired: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _calculateSalaries(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _allowancesController,
                    keyboardType: TextInputType.number,
                    decoration:
                        inputDecoration("Allowances", isRequired: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _calculateSalaries(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _grossSalaryController,
                    keyboardType: TextInputType.number,
                    decoration:
                        inputDecoration("Gross Salary", isRequired: false),
                    readOnly: true,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: _netSalaryController,
                    keyboardType: TextInputType.number,
                    decoration:
                        inputDecoration("Net Salary", isRequired: false),
                    readOnly: true,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ]),
              sectionTitle("Section 4 - Document Uploads"),
              formCard([
                uploadField("Resume",
                    fileName: resumeFile,
                    documentType: 'resume',
                    isRequired: true),
                uploadField("Offer Letter",
                    fileName: offerLetterFile,
                    documentType: 'offerLetter',
                    isRequired: true),
                uploadField("Aadhaar Card",
                    fileName: aadhaarCardFile,
                    documentType: 'aadhaarCard',
                    isRequired: true),
                uploadField("PAN Card",
                    fileName: panCardFile,
                    documentType: 'panCard',
                    isRequired: true),
                uploadField("Bank Proof",
                    fileName: bankProofFile, documentType: 'bankProof'),
                uploadField("Degree / Provisional Certificate",
                    fileName: degreeCertificateFile,
                    documentType: 'degreeCertificate'),
                uploadField("Passport Size Photo",
                    fileName: passportPhotoFile, documentType: 'passportPhoto'),
                if (experienceLevel == "Experienced")
                  uploadField("Experience Certificate",
                      fileName: experienceCertificateFile,
                      documentType: 'experienceCertificate'),
                if (experienceLevel == "Experienced")
                  uploadField("Relieving Letter",
                      fileName: relievingLetterFile,
                      documentType: 'relievingLetter'),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF655193),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: _isSubmitting ? null : _submitOnboardingForm,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Submitting...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "Submit Onboarding Form",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
