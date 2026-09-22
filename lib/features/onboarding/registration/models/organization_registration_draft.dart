// lib/features/onboarding/registration/models/organization_registration_draft.dart

/// Local, non-secret draft of an organization registration application.
///
/// Stored on-device only (SharedPreferences). This is NOT synced across
/// devices and does NOT survive reinstall — the backend draft system in a
/// later milestone provides that.
///
/// Never store passwords, OTPs, document bytes, ID documents or tokens here.
class OrganizationRegistrationDraft {
  // Step 1 — Organization information
  String organizationName;
  String organizationType;
  String industry;
  String employeeCount;
  String branchCount;
  String registeredAddress;
  String officialEmail;
  String contactNumber;
  String website;
  String gstNumber;
  String cinNumber;

  // Step 2 — Requested HRMS features (applicant's wish-list only).
  // Approved/enabled features are decided by the platform admin later;
  // selecting here never activates anything.
  final Set<String> requestedFeatures;

  // Step 3 — Authorized HR/Admin contact
  String adminFullName;
  String adminDesignation;
  String adminEmail;
  String adminMobile;

  /// Wizard position: 0 = organization info, 1 = features, 2 = admin info,
  /// 3 = verification placeholder.
  int currentStep;

  /// The furthest step the applicant has completed and may jump back to.
  int maxCompletedStep;

  /// Server-side draft ID (from POST /org-registration/draft).
  ///
  /// NOT a credential — it is useless without the resume token, which is
  /// stored separately in flutter_secure_storage.
  String registrationId;

  /// True when the last backend sync failed — the local draft is preserved
  /// and will be re-synced on the next save.
  bool backendSyncFailed;

  /// Last-known AUTHORITATIVE application status from the backend.
  ///
  /// Cached locally only so a backend outage cannot revert an already
  /// submitted application to the editable wizard. It is never used to
  /// claim submission — only the server can set a non-draft status.
  String applicationStatus;

  OrganizationRegistrationDraft({
    this.organizationName = '',
    this.organizationType = '',
    this.industry = '',
    this.employeeCount = '',
    this.branchCount = '',
    this.registeredAddress = '',
    this.officialEmail = '',
    this.contactNumber = '',
    this.website = '',
    this.gstNumber = '',
    this.cinNumber = '',
    Set<String>? requestedFeatures,
    this.adminFullName = '',
    this.adminDesignation = '',
    this.adminEmail = '',
    this.adminMobile = '',
    this.currentStep = 0,
    this.maxCompletedStep = -1,
    this.registrationId = '',
    this.backendSyncFailed = false,
    this.applicationStatus = 'draft',
  }) : requestedFeatures = requestedFeatures ?? <String>{};

  /// True when the backend has taken over the application (no more edits).
  bool get isSubmitted => const {
        'submitted',
        'pending_verification',
        'pending_approval',
        'approved',
        'rejected',
      }.contains(applicationStatus);

  /// True when the reviewer sent it back for corrections (editable again).
  bool get needsChanges => applicationStatus == 'changes_requested';

  bool get isEmpty =>
      organizationName.isEmpty &&
      organizationType.isEmpty &&
      industry.isEmpty &&
      employeeCount.isEmpty &&
      branchCount.isEmpty &&
      registeredAddress.isEmpty &&
      officialEmail.isEmpty &&
      contactNumber.isEmpty &&
      website.isEmpty &&
      gstNumber.isEmpty &&
      cinNumber.isEmpty &&
      requestedFeatures.isEmpty &&
      adminFullName.isEmpty &&
      adminDesignation.isEmpty &&
      adminEmail.isEmpty &&
      adminMobile.isEmpty &&
      currentStep == 0;

  Map<String, dynamic> toJson() => {
        'organizationName': organizationName,
        'organizationType': organizationType,
        'industry': industry,
        'employeeCount': employeeCount,
        'branchCount': branchCount,
        'registeredAddress': registeredAddress,
        'officialEmail': officialEmail,
        'contactNumber': contactNumber,
        'website': website,
        'gstNumber': gstNumber,
        'cinNumber': cinNumber,
        'requestedFeatures': requestedFeatures.toList(),
        'adminFullName': adminFullName,
        'adminDesignation': adminDesignation,
        'adminEmail': adminEmail,
        'adminMobile': adminMobile,
        'currentStep': currentStep,
        'maxCompletedStep': maxCompletedStep,
        'registrationId': registrationId,
        'backendSyncFailed': backendSyncFailed,
        'applicationStatus': applicationStatus,
      };

  factory OrganizationRegistrationDraft.fromJson(
      Map<String, dynamic> json) {
    return OrganizationRegistrationDraft(
      organizationName: (json['organizationName'] ?? '').toString(),
      organizationType: (json['organizationType'] ?? '').toString(),
      industry: (json['industry'] ?? '').toString(),
      employeeCount: (json['employeeCount'] ?? '').toString(),
      branchCount: (json['branchCount'] ?? '').toString(),
      registeredAddress: (json['registeredAddress'] ?? '').toString(),
      officialEmail: (json['officialEmail'] ?? '').toString(),
      contactNumber: (json['contactNumber'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      gstNumber: (json['gstNumber'] ?? '').toString(),
      cinNumber: (json['cinNumber'] ?? '').toString(),
      requestedFeatures: (json['requestedFeatures'] is List)
          ? (json['requestedFeatures'] as List)
              .map((e) => e.toString())
              .toSet()
          : <String>{},
      adminFullName: (json['adminFullName'] ?? '').toString(),
      adminDesignation: (json['adminDesignation'] ?? '').toString(),
      adminEmail: (json['adminEmail'] ?? '').toString(),
      adminMobile: (json['adminMobile'] ?? '').toString(),
      currentStep: (json['currentStep'] is num)
          ? (json['currentStep'] as num).toInt()
          : 0,
      maxCompletedStep: (json['maxCompletedStep'] is num)
          ? (json['maxCompletedStep'] as num).toInt()
          : -1,
      registrationId: (json['registrationId'] ?? '').toString(),
      backendSyncFailed: json['backendSyncFailed'] == true,
      applicationStatus:
          (json['applicationStatus'] ?? 'draft').toString().isEmpty
              ? 'draft'
              : (json['applicationStatus'] ?? 'draft').toString(),
    );
  }
}
