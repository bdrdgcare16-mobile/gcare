// lib/features/onboarding/models/organization_policy_model.dart

/// An organization HR policy version returned by
/// GET /organization/policies.
class OrganizationPolicy {
  final String policyId;
  final String type;
  final String title;
  final String description;
  final int version;
  final String content;
  final String? documentUrl;
  final DateTime? publishedAt;
  final bool required;
  final bool requiresSeparateConsent;
  final bool accepted;
  final int? acceptedVersion;

  const OrganizationPolicy({
    required this.policyId,
    required this.type,
    required this.title,
    required this.description,
    required this.version,
    required this.content,
    this.documentUrl,
    this.publishedAt,
    required this.required,
    required this.requiresSeparateConsent,
    required this.accepted,
    this.acceptedVersion,
  });

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    if (raw is Map) {
      final seconds = raw['_seconds'] ?? raw['seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
      return null;
    }
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  factory OrganizationPolicy.fromJson(Map<String, dynamic> json) {
    final policyId = (json['policyId'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final version = json['version'];

    // A policy without a usable identity/version is malformed — never
    // silently treat it as acceptable data.
    if (policyId.isEmpty || title.isEmpty || version is! num) {
      throw const FormatException('Malformed policy record');
    }

    return OrganizationPolicy(
      policyId: policyId,
      type: (json['type'] ?? '').toString(),
      title: title,
      description: (json['description'] ?? '').toString(),
      version: version.toInt(),
      content: (json['content'] ?? '').toString(),
      documentUrl: json['documentUrl']?.toString(),
      publishedAt: _parseTimestamp(json['publishedAt']),
      required: json['required'] == true,
      requiresSeparateConsent: json['requiresSeparateConsent'] == true,
      accepted: json['accepted'] == true,
      acceptedVersion: (json['acceptedVersion'] is num)
          ? (json['acceptedVersion'] as num).toInt()
          : null,
    );
  }
}

/// A required policy the employee has not yet accepted at the current version.
class PendingRequiredPolicy {
  final String policyId;
  final String title;
  final int version;

  const PendingRequiredPolicy({
    required this.policyId,
    required this.title,
    required this.version,
  });

  factory PendingRequiredPolicy.fromJson(Map<String, dynamic> json) {
    final policyId = (json['policyId'] ?? '').toString();
    final version = json['version'];
    if (policyId.isEmpty || version is! num) {
      throw const FormatException('Malformed pending policy record');
    }
    return PendingRequiredPolicy(
      policyId: policyId,
      title: (json['title'] ?? '').toString(),
      version: version.toInt(),
    );
  }
}

/// Response of GET /organization/policies/acceptance-status.
class PolicyAcceptanceStatus {
  final bool allAccepted;
  final List<PendingRequiredPolicy> pendingRequired;

  const PolicyAcceptanceStatus({
    required this.allAccepted,
    required this.pendingRequired,
  });

  factory PolicyAcceptanceStatus.fromJson(Map<String, dynamic> json) {
    final allAccepted = json['allAccepted'];
    if (allAccepted is! bool) {
      throw const FormatException('Malformed acceptance-status response');
    }
    final pending = (json['pendingRequired'] is List)
        ? (json['pendingRequired'] as List)
            .whereType<Map>()
            .map((e) => PendingRequiredPolicy.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <PendingRequiredPolicy>[];
    return PolicyAcceptanceStatus(
      allAccepted: allAccepted,
      pendingRequired: pending,
    );
  }
}
