class OnboardingModel {
  final String id;
  final Map<String, dynamic> personalDetails;
  final Map<String, dynamic> companyDetails;
  final Map<String, dynamic> bankDetails;
  final Map<String, dynamic> documents;
  final String status;

  OnboardingModel({
    required this.id,
    required this.personalDetails,
    required this.companyDetails,
    required this.bankDetails,
    required this.documents,
    required this.status,
  });

  factory OnboardingModel.fromJson(Map<String, dynamic> json) {
    return OnboardingModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['documentId']?.toString() ??
          '',
      personalDetails: json['personalDetails'] is Map
          ? Map<String, dynamic>.from(json['personalDetails'] as Map)
          : <String, dynamic>{},
      companyDetails: json['companyDetails'] is Map
          ? Map<String, dynamic>.from(json['companyDetails'] as Map)
          : <String, dynamic>{},
      bankDetails: json['bankDetails'] is Map
          ? Map<String, dynamic>.from(json['bankDetails'] as Map)
          : <String, dynamic>{},
      documents: json['documents'] is Map
          ? Map<String, dynamic>.from(json['documents'] as Map)
          : <String, dynamic>{},
      status: json['status']?.toString() ?? 'pending',
    );
  }
}
