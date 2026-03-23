class CompanyProfile {
  final String name;
  final String adminName;
  final String? logoUrl;

  CompanyProfile({
    required this.name,
    required this.adminName,
    this.logoUrl,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      name: (json['name'] ?? '').toString(),
      adminName: (json['adminName'] ?? '').toString(),
      logoUrl: json['logoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'adminName': adminName,
      'logoUrl': logoUrl,
    };
  }

  bool get hasLogo => logoUrl != null && logoUrl!.trim().isNotEmpty;

  String get initials {
    final source = adminName.trim().isNotEmpty ? adminName : name;
    if (source.trim().isEmpty) return 'A';

    final parts = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}