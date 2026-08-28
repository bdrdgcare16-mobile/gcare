// lib/features/admin/create_disciplinary_action_page.dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:serv_app/models/disciplinary_action_model.dart';
import 'package:serv_app/services/disciplinary_actions_service.dart';
import 'package:serv_app/shared/app_theme.dart';
import 'employee_management_page.dart';

const List<String> _violationCategories = [
  'Attendance Violation',
  'Unauthorized Absence / Leave Violation',
  'Poor Performance',
  'Misconduct / Insubordination',
  'Workplace Behaviour Violation',
  'Company Policy / Code of Conduct Violation',
  'Confidentiality / Data Security Violation',
  'Fraud / Falsification / Theft',
  'Negligence / Safety Violation',
  'Other',
];

const List<String> _noticeTypes = [
  'Verbal Warning',
  'Written Warning',
  'Memo',
  'Warning Letter',
  'Show Cause Notice',
  'Explanation Letter Request',
  'Charge Memo',
  'Final Warning',
  'Suspension Notice',
  'Domestic Enquiry Notice',
  'Disciplinary Hearing Notice',
  'Termination Notice',
  'Other',
];

const List<String> _severityLevels = ['Low', 'Medium', 'High', 'Critical'];

const List<String> _proposedActions = [
  'Counselling',
  'Verbal Warning',
  'Written Warning',
  'First Warning',
  'Second Warning',
  'Final Warning',
  'Formal Memo',
  'Show Cause Notice',
  'Explanation Required',
  'Performance Improvement Plan',
  'Mandatory Training',
  'Written Apology',
  'Transfer of Responsibility',
  'Change of Duties',
  'Removal of Certain Responsibilities',
  'Restriction of System Access',
  'Restriction of Company Asset Access',
  'Recovery of Company Property',
  'Suspension Pending Enquiry',
  'Suspension for Defined Period',
  'Domestic Enquiry',
  'Formal Disciplinary Hearing',
  'Final Warning with Monitoring Period',
  'Termination Recommendation',
  'Termination of Employment',
  'No Further Action',
  'Case Closed After Explanation',
  'Other',
];

class CreateDisciplinaryActionPage extends StatefulWidget {
  final DisciplinaryActionModel? action;

  const CreateDisciplinaryActionPage({super.key, this.action});

  @override
  State<CreateDisciplinaryActionPage> createState() =>
      _CreateDisciplinaryActionPageState();
}

class _CreateDisciplinaryActionPageState
    extends State<CreateDisciplinaryActionPage> {
  final _formKey = GlobalKey<FormState>();
  final List<Employee> _employees = [];
  Employee? _selectedEmployee;

  final _employeeNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _employeeCompanyIdController = TextEditingController();
  final _employeeDepartmentController = TextEditingController();
  final _employeeDesignationController = TextEditingController();

  final _reportingManagerController = TextEditingController();
  final _issuedByController = TextEditingController();

  String? _violationCategory;
  final _otherViolationController = TextEditingController();

  final _incidentDateController = TextEditingController();
  final _incidentTimeController = TextEditingController();
  final _incidentLocationController = TextEditingController();
  final _incidentDescriptionController = TextEditingController();

  String? _noticeType;
  final _otherNoticeTypeController = TextEditingController();

  String? _severity;
  final _subjectController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _responseRequired = false;
  final _responseDueDateController = TextEditingController();

  String? _proposedAction;
  final _otherProposedActionController = TextEditingController();

  final _effectiveFromController = TextEditingController();
  final _effectiveUntilController = TextEditingController();
  final _adminRemarksController = TextEditingController();

  bool _loadingEmployees = true;
  bool _submitting = false;
  String? _error;
  late final bool _isEdit;
  bool _isResubmit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.action != null;
    _isResubmit = widget.action != null && widget.action!.status == 'rejected';
    _prefillControllers();
    _loadEmployees();
  }

  void _prefillControllers() {
    final a = widget.action;
    if (a == null) return;

    _violationCategory = a.violationCategory;
    _otherViolationController.text = a.otherViolationCategory ?? '';
    _incidentDateController.text = a.incidentDate;
    _incidentTimeController.text = a.incidentTime ?? '';
    _incidentLocationController.text = a.incidentLocation ?? '';
    _incidentDescriptionController.text = a.incidentDescription;
    _noticeType = a.noticeType;
    _otherNoticeTypeController.text = a.otherNoticeType ?? '';
    _severity = a.severity;
    _subjectController.text = a.subject;
    _reasonController.text = a.reason;
    _responseRequired = a.responseRequired;
    _responseDueDateController.text = a.responseDueDate ?? '';
    _proposedAction = a.proposedAction;
    _otherProposedActionController.text = a.otherProposedAction ?? '';
    _effectiveFromController.text = a.effectiveFrom ?? '';
    _effectiveUntilController.text = a.effectiveUntil ?? '';
    _adminRemarksController.text = a.finalRemarks ?? '';
    _reportingManagerController.text = a.reportingManager;
    _issuedByController.text = a.issuedBy ?? '';
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _employeeIdController.dispose();
    _employeeCompanyIdController.dispose();
    _employeeDepartmentController.dispose();
    _employeeDesignationController.dispose();
    _reportingManagerController.dispose();
    _issuedByController.dispose();
    _otherViolationController.dispose();
    _incidentDateController.dispose();
    _incidentTimeController.dispose();
    _incidentLocationController.dispose();
    _incidentDescriptionController.dispose();
    _otherNoticeTypeController.dispose();
    _subjectController.dispose();
    _reasonController.dispose();
    _responseDueDateController.dispose();
    _otherProposedActionController.dispose();
    _effectiveFromController.dispose();
    _effectiveUntilController.dispose();
    _adminRemarksController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _loadingEmployees = true;
      _error = null;
    });

    try {
      _employees.clear();
      String? lastDocId;
      while (true) {
        final result = await EmployeeService.fetchEmployees(
          limit: 100,
          lastDocId: lastDocId,
        );
        final list = result['employees'] as List<Employee>;
        _employees.addAll(list);

        final newLast = result['lastDocId'] as String?;
        if (newLast == null ||
            newLast.isEmpty ||
            list.isEmpty ||
            list.length < 100) {
          break;
        }
        lastDocId = newLast;
      }

      if (_isEdit) {
        _selectedEmployee = _employees.cast<Employee?>().firstWhere(
              (e) => e?.id == widget.action?.employeeId,
              orElse: () => null,
            );
      }
      _populateEmployeeInfo();

      if (!mounted) return;
      setState(() => _loadingEmployees = false);
    } catch (e) {
      debugPrint('[DisciplinaryActions] Employee load error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load employees';
        _loadingEmployees = false;
      });
    }
  }

  void _populateEmployeeInfo() {
    final e = _selectedEmployee;
    _employeeNameController.text = e?.name.trim().isNotEmpty == true ? e!.name : '-';
    _employeeIdController.text = e?.id.trim().isNotEmpty == true ? e!.id : '-';
    _employeeCompanyIdController.text =
        e?.companyId.trim().isNotEmpty == true ? e!.companyId : '-';
    _employeeDepartmentController.text =
        e?.dept.trim().isNotEmpty == true ? e!.dept : '-';
    _employeeDesignationController.text =
        e?.designation.trim().isNotEmpty == true ? e!.designation : '-';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      setState(() => _error = 'Please select an employee');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final fields = <String, String>{
        'employeeId': _selectedEmployee!.id,
        'reportingManager': _reportingManagerController.text.trim(),
        'issuedBy': _issuedByController.text.trim(),
        'violationCategory': _violationCategory!,
        if (_violationCategory == 'Other')
          'otherViolationCategory': _otherViolationController.text.trim(),
        'incidentDate': _incidentDateController.text.trim(),
        if (_incidentTimeController.text.trim().isNotEmpty)
          'incidentTime': _incidentTimeController.text.trim(),
        if (_incidentLocationController.text.trim().isNotEmpty)
          'incidentLocation': _incidentLocationController.text.trim(),
        'incidentDescription': _incidentDescriptionController.text.trim(),
        'noticeType': _noticeType!,
        if (_noticeType == 'Other')
          'otherNoticeType': _otherNoticeTypeController.text.trim(),
        'severity': _severity!,
        'subject': _subjectController.text.trim(),
        'reason': _reasonController.text.trim(),
        'responseRequired': _responseRequired ? 'true' : 'false',
        if (_responseRequired && _responseDueDateController.text.trim().isNotEmpty)
          'responseDueDate': _responseDueDateController.text.trim(),
        'proposedAction': _proposedAction!,
        if (_proposedAction == 'Other')
          'otherProposedAction': _otherProposedActionController.text.trim(),
        if (_effectiveFromController.text.trim().isNotEmpty)
          'effectiveFrom': _effectiveFromController.text.trim(),
        if (_effectiveUntilController.text.trim().isNotEmpty)
          'effectiveUntil': _effectiveUntilController.text.trim(),
        if (_adminRemarksController.text.trim().isNotEmpty)
          'adminRemarks': _adminRemarksController.text.trim(),
      };

      if (_isEdit) {
        final id = widget.action!.id;
        if (_isResubmit) {
          await DisciplinaryActionsService.resubmit(
            id: id,
            fields: fields,
          );
        } else {
          await DisciplinaryActionsService.update(
            id: id,
            fields: fields,
          );
        }
      } else {
        await DisciplinaryActionsService.create(
          fields: fields,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: kPrimaryDark),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: kPrimaryDark,
        ),
      ),
    );
  }

  Widget _employeeSelector() {
    if (_loadingEmployees) {
      return TextFormField(
        decoration: _decoration('Employee *').copyWith(
          hintText: 'Loading employees...',
          prefixIcon: const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        enabled: false,
        readOnly: true,
      );
    }

    if (_employees.isEmpty) {
      return TextFormField(
        decoration: _decoration('Employee *').copyWith(
          hintText: 'No employees found',
        ),
        enabled: false,
        readOnly: true,
      );
    }

    final items = _employees
        .map((e) => DropdownMenuItem<Employee>(
              value: e,
              child: Text('${e.id} - ${e.name}', overflow: TextOverflow.ellipsis),
            ))
        .toList();

    return DropdownButtonFormField<Employee>(
      value: _selectedEmployee,
      decoration: _decoration('Employee *'),
      isExpanded: true,
      items: items,
      onChanged: (value) {
        setState(() {
          _selectedEmployee = value;
          _populateEmployeeInfo();
        });
      },
      validator: (value) => value == null ? 'Employee is required' : null,
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: _decoration(label).copyWith(
        filled: true,
        fillColor: const Color(0xFFF3F0FF),
      ),
      readOnly: true,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      decoration: _decoration(label),
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.normal,
      ),
      validator: validator,
    );
  }

  Widget _buildDateField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      decoration: _decoration(label),
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          c.text = _formatDate(picked);
        }
      },
      validator: (v) => v == null || v.trim().isEmpty ? '$label is required' : null,
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildTimeField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      decoration: _decoration(label),
      readOnly: true,
      onTap: () async {
        final now = TimeOfDay.now();
        final picked = await showTimePicker(
          context: context,
          initialTime: now,
        );
        if (picked != null) {
          c.text = _formatTime(picked);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: Text(
          _isResubmit
              ? 'Resubmit Disciplinary Action'
              : _isEdit
                  ? 'Edit Disciplinary Action'
                  : 'Create Disciplinary Action',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6F52A3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingEmployees && _employees.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Employee Information'),
                    _employeeSelector(),
                    const SizedBox(height: 12),
                    _buildInfoField('Employee Name', _employeeNameController),
                    const SizedBox(height: 12),
                    _buildInfoField('Employee ID', _employeeIdController),
                    const SizedBox(height: 12),
                    _buildInfoField('Company ID', _employeeCompanyIdController),
                    const SizedBox(height: 12),
                    _buildInfoField('Department', _employeeDepartmentController),
                    const SizedBox(height: 12),
                    _buildInfoField('Designation', _employeeDesignationController),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _reportingManagerController,
                      'Reporting Manager *',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Reporting Manager is required' : null,
                    ),

                    _section('Incident Information'),
                    DropdownButtonFormField<String>(
                      value: _violationCategory,
                      decoration: _decoration('Violation Category *'),
                      isExpanded: true,
                      items: _violationCategories
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _violationCategory = value),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    if (_violationCategory == 'Other') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otherViolationController,
                        decoration: _decoration('Other Violation Details *'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildDateField(_incidentDateController, 'Incident Date *'),
                    const SizedBox(height: 12),
                    _buildTimeField(_incidentTimeController, 'Incident Time'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _incidentLocationController,
                      decoration: _decoration('Incident Location'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _incidentDescriptionController,
                      decoration: _decoration('Incident Description *'),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    _section('Disciplinary Process'),
                    DropdownButtonFormField<String>(
                      value: _noticeType,
                      decoration: _decoration('Notice / Proceeding Type *'),
                      isExpanded: true,
                      items: _noticeTypes
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _noticeType = value),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    if (_noticeType == 'Other') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otherNoticeTypeController,
                        decoration: _decoration('Other Notice Type *'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _severity,
                      decoration: _decoration('Severity *'),
                      isExpanded: true,
                      items: _severityLevels
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _severity = value),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subjectController,
                      decoration: _decoration('Subject *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasonController,
                      decoration: _decoration('Reason *'),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _responseRequired,
                          onChanged: (v) => setState(() => _responseRequired = v ?? false),
                          activeColor: kPrimaryDark,
                        ),
                        const Text('Response Required'),
                      ],
                    ),
                    if (_responseRequired) ...[
                      const SizedBox(height: 8),
                      _buildDateField(_responseDueDateController, 'Response Due Date *'),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _proposedAction,
                      decoration: _decoration('Proposed Disciplinary Action *'),
                      isExpanded: true,
                      items: _proposedActions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _proposedAction = value),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    if (_proposedAction == 'Other') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otherProposedActionController,
                        decoration: _decoration('Other Disciplinary Action *'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildDateField(_effectiveFromController, 'Effective From'),
                    const SizedBox(height: 12),
                    _buildDateField(_effectiveUntilController, 'Effective Until'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminRemarksController,
                      decoration: _decoration('Admin Remarks'),
                      maxLines: 2,
                    ),

                    _section('Issued By'),
                    _buildTextField(
                      _issuedByController,
                      'Issued By *',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Issued By is required' : null,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isResubmit
                                ? 'Resubmit for Approval'
                                : _isEdit
                                    ? 'Update'
                                    : 'Submit for Approval'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
