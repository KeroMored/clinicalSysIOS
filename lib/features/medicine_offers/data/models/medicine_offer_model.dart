import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/generic_offer_sorting_service.dart';

class MedicineOfferModel implements ISortableOffer {
  final String id;
  final String pharmacyId; // معرف الصيدلية
  final String pharmacyName; // اسم الصيدلية
  final String medicineName; // اسم الدواء
  final int quantity; // الكمية المتاحة
  final double price; // السعر
  final String description; // وصف العرض
  final String? imageUrl; // صورة الدواء (اختياري)
  final DateTime createdAt; // تاريخ النشر
  final bool isActive; // هل العرض متاح
  final int viewsCount; // عدد المشاهدات
  final String category; // تصنيف الدواء (مسكنات، مضادات حيوية، إلخ)

  MedicineOfferModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.medicineName,
    required this.quantity,
    required this.price,
    this.description = '',
    this.imageUrl,
    required this.createdAt,
    this.isActive = true,
    this.viewsCount = 0,
    this.category = 'عام', // القيمة الافتراضية
  });

  // Convert from Firestore document
  factory MedicineOfferModel.fromJson(Map<String, dynamic> json) {
    return MedicineOfferModel(
      id: json['id'] ?? '',
      pharmacyId: json['pharmacyId'] ?? '',
      pharmacyName: json['pharmacyName'] ?? '',
      medicineName: json['medicineName'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      viewsCount: json['viewsCount'] ?? 0,
      category: json['category'] ?? 'عام',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'medicineName': medicineName,
      'quantity': quantity,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'viewsCount': viewsCount,
      'category': category,
    };
  }

  // Copy with method for updating
  MedicineOfferModel copyWith({
    String? id,
    String? pharmacyId,
    String? pharmacyName,
    String? medicineName,
    int? quantity,
    double? price,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    bool? isActive,
    int? viewsCount,
    String? category,
  }) {
    return MedicineOfferModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      viewsCount: viewsCount ?? this.viewsCount,
      category: category ?? this.category,
    );
  }
}
