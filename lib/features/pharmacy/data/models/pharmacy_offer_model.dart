class PharmacyOfferModel {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String title;
  final String description;
  final String imageUrl;
  final double? discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  PharmacyOfferModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory PharmacyOfferModel.fromJson(Map<String, dynamic> json) {
    return PharmacyOfferModel(
      id: json['id'] ?? '',
      pharmacyId: json['pharmacyId'] ?? '',
      pharmacyName: json['pharmacyName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      discountPercentage: json['discountPercentage']?.toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'discountPercentage': discountPercentage,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}
