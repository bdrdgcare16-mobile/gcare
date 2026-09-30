// lib/models/organization_context.dart

/// Runtime organization context for an authenticated org-scoped session.
///
/// Built server-side data only (companyProfile document via
/// GET /company/profile) — never from client-supplied values.
///
///   companyId         — canonical internal organization identifier
///                       (companyProfile document id, also users.companyId)
///   organizationCode  — human-readable org code (e.g. SERV001)
///   enabledFeatures   — active module ids written at activation.
///                       `null` means the organization predates feature
///                       gating (legacy org) → all modules unrestricted.
class OrganizationContext {
  /// The most recently loaded context for this session. Set by
  /// [OrganizationContextService.load] / login / AuthGuard so the
  /// navigation and feature guards can consult it synchronously.
  static OrganizationContext? current;

  final String companyId;
  final String organizationCode;
  final String organizationName;
  final String adminName;
  final List<String>? enabledFeatures;

  const OrganizationContext({
    required this.companyId,
    required this.organizationCode,
    required this.organizationName,
    required this.adminName,
    required this.enabledFeatures,
  });

  /// Parse a companyProfile payload (`{id, code, companyName, adminName,
  /// enabledFeatures, ...}`) as returned by GET /company/profile or
  /// /company/profile/check (`data` object).
  factory OrganizationContext.fromProfileJson(Map<String, dynamic> json) {
    final raw = json['enabledFeatures'];
    return OrganizationContext(
      companyId: (json['id'] ?? json['companyId'] ?? '').toString(),
      organizationCode: (json['code'] ?? json['organizationCode'] ?? '')
          .toString(),
      organizationName: (json['companyName'] ?? json['name'] ?? '').toString(),
      adminName: (json['adminName'] ?? '').toString(),
      enabledFeatures: raw is List
          ? raw.map((e) => e.toString()).toList()
          : null,
    );
  }

  /// Legacy orgs (no enabledFeatures field at all) are unrestricted —
  /// same rule as the backend requireFeature middleware.
  bool isFeatureEnabled(String featureId) =>
      enabledFeatures == null || enabledFeatures!.contains(featureId);

  /// True when ANY of [featureIds] is enabled — mirrors the backend
  /// requireAnyFeature middleware for shared surfaces (e.g. Live
  /// Attendance reachable with `attendance` OR `location_tracking`).
  bool isAnyFeatureEnabled(List<String> featureIds) =>
      enabledFeatures == null ||
      featureIds.any((id) => enabledFeatures!.contains(id));

  static void clear() => current = null;
}
