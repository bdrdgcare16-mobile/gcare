// lib/models/disciplinary_action_model.dart

class DisciplinaryActionModel {
  final String id;
  final String companyId;
  final String employeeId;
  final String employeeUid;
  final String employeeName;
  final String department;
  final String designation;
  final String reportingManager;
  final String? issuedBy;

  final String violationCategory;
  final String? otherViolationCategory;

  final String incidentDate;
  final String? incidentTime;
  final String? incidentLocation;
  final String incidentDescription;

  final String noticeType;
  final String? otherNoticeType;

  final String severity;

  final String subject;
  final String reason;

  final bool responseRequired;
  final String? responseDueDate;

  final String proposedAction;
  final String? otherProposedAction;

  final String? finalAction;
  final String? finalRemarks;

  final String? effectiveFrom;
  final String? effectiveUntil;

  final String? attachmentUrl;

  final String status;

  final String createdBy;
  final String createdByName;
  final String createdByRole;
  final String? createdByDesignation;
  final DateTime? createdAt;

  final String? updatedBy;
  final DateTime? updatedAt;

  final String submittedBy;
  final DateTime? submittedAt;

  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;

  final String? rejectedBy;
  final String? rejectedByName;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  final List<Map<String, dynamic>> history;

  DisciplinaryActionModel({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeUid,
    required this.employeeName,
    required this.department,
    required this.designation,
    required this.reportingManager,
    this.issuedBy,
    required this.violationCategory,
    this.otherViolationCategory,
    required this.incidentDate,
    this.incidentTime,
    this.incidentLocation,
    required this.incidentDescription,
    required this.noticeType,
    this.otherNoticeType,
    required this.severity,
    required this.subject,
    required this.reason,
    required this.responseRequired,
    this.responseDueDate,
    required this.proposedAction,
    this.otherProposedAction,
    this.finalAction,
    this.finalRemarks,
    this.effectiveFrom,
    this.effectiveUntil,
    this.attachmentUrl,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.createdByRole,
    this.createdByDesignation,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    required this.submittedBy,
    this.submittedAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedByName,
    this.rejectedAt,
    this.rejectionReason,
    this.history = const [],
  });

  factory DisciplinaryActionModel.fromJson(Map<String, dynamic> json) {
    return DisciplinaryActionModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['documentId']?.toString() ??
          '',
      companyId: _string(json['companyId']),
      employeeId: _string(json['employeeId']),
      employeeUid: _string(json['employeeUid']),
      employeeName: _string(json['employeeName']),
      department: _string(json['department']),
      designation: _string(json['designation']),
      reportingManager: _string(json['reportingManager']),
      issuedBy: _nullableString(json['issuedBy']),
      violationCategory: _string(json['violationCategory']),
      otherViolationCategory: _nullableString(json['otherViolationCategory']),
      incidentDate: _string(json['incidentDate']),
      incidentTime: _nullableString(json['incidentTime']),
      incidentLocation: _nullableString(json['incidentLocation']),
      incidentDescription: _string(json['incidentDescription']),
      noticeType: _string(json['noticeType']),
      otherNoticeType: _nullableString(json['otherNoticeType']),
      severity: _string(json['severity']),
      subject: _string(json['subject']),
      reason: _string(json['reason']),
      responseRequired: _bool(json['responseRequired']),
      responseDueDate: _nullableString(json['responseDueDate']),
      proposedAction: _string(json['proposedAction']),
      otherProposedAction: _nullableString(json['otherProposedAction']),
      finalAction: _nullableString(json['finalAction']),
      finalRemarks: _nullableString(json['finalRemarks']),
      effectiveFrom: _nullableString(json['effectiveFrom']),
      effectiveUntil: _nullableString(json['effectiveUntil']),
      attachmentUrl: _nullableString(json['attachmentUrl']),
      status: _string(json['status']),
      createdBy: _string(json['createdBy']),
      createdByName: _string(json['createdByName']),
      createdByRole: _string(json['createdByRole']),
      createdByDesignation: _nullableString(json['createdByDesignation']),
      createdAt: _toDateTime(json['createdAt']),
      updatedBy: _nullableString(json['updatedBy']),
      updatedAt: _toDateTime(json['updatedAt']),
      submittedBy: _string(json['submittedBy']),
      submittedAt: _toDateTime(json['submittedAt']),
      approvedBy: _nullableString(json['approvedBy']),
      approvedByName: _nullableString(json['approvedByName']),
      approvedAt: _toDateTime(json['approvedAt']),
      rejectedBy: _nullableString(json['rejectedBy']),
      rejectedByName: _nullableString(json['rejectedByName']),
      rejectedAt: _toDateTime(json['rejectedAt']),
      rejectionReason: _nullableString(json['rejectionReason']),
      history: _toHistoryList(json['history']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'employeeId': employeeId,
      'employeeUid': employeeUid,
      'employeeName': employeeName,
      'department': department,
      'designation': designation,
      'reportingManager': reportingManager,
      'issuedBy': issuedBy,
      'violationCategory': violationCategory,
      'otherViolationCategory': otherViolationCategory,
      'incidentDate': incidentDate,
      'incidentTime': incidentTime,
      'incidentLocation': incidentLocation,
      'incidentDescription': incidentDescription,
      'noticeType': noticeType,
      'otherNoticeType': otherNoticeType,
      'severity': severity,
      'subject': subject,
      'reason': reason,
      'responseRequired': responseRequired,
      'responseDueDate': responseDueDate,
      'proposedAction': proposedAction,
      'otherProposedAction': otherProposedAction,
      'finalAction': finalAction,
      'finalRemarks': finalRemarks,
      'effectiveFrom': effectiveFrom,
      'effectiveUntil': effectiveUntil,
      'attachmentUrl': attachmentUrl,
      'status': status,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'createdByDesignation': createdByDesignation,
      'createdAt': createdAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedAt': updatedAt?.toIso8601String(),
      'submittedBy': submittedBy,
      'submittedAt': submittedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedBy': rejectedBy,
      'rejectedByName': rejectedByName,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'history': history,
    };
  }

  String get displayName =>
      '$employeeName ${employeeId.isNotEmpty ? '($employeeId)' : ''}';

  bool get isEditable => status == 'pending' || status == 'rejected';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  static String _string(dynamic value) =>
      value == null ? '' : value.toString();

  static String? _nullableString(dynamic value) =>
      value?.toString();

  static bool _bool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    final s = value.toString().toLowerCase();
    return s == 'true' || s == 'yes' || s == '1';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Map && value.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as int) * 1000,
      );
    }
    if (value is Map && value.containsKey('seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as int) * 1000,
      );
    }
    final parsed = DateTime.tryParse(value.toString());
    return parsed;
  }

  static List<Map<String, dynamic>> _toHistoryList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }
}
