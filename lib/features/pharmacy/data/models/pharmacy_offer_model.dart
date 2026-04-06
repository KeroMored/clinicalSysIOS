import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/generic_offer_sorting_service.dart';

class PharmacyOfferModel implements ISortableOffer {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String title;
  final String description;
  final String notes; // ملاحظات إضافية
  final String imageUrl; // الصورة الأساسية (للتوافق مع الكود القديم)
  final List<String> images; // قائمة الصور المتعددة
  final double? discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt; // تاريخ الإنشاء للترتيب الديناميكي
  final bool isActive;
  final int viewsCount; // عدد المشاهدات
  final String category; // تصنيف العرض

  PharmacyOfferModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.title,
    required this.description,
    this.notes = '',
    required this.imageUrl,
    this.images = const [],
    this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.isActive,
    this.viewsCount = 0,
    this.category = 'عام',
  });

  factory PharmacyOfferModel.fromJson(Map<String, dynamic> json) {
    // Handle dates safely - Firestore stores dates as Timestamp
    DateTime? startDate;
    DateTime? endDate;
    DateTime? createdAt;

    try {
      if (json['startDate'] != null) {
        if (json['startDate'] is Timestamp) {
          startDate = (json['startDate'] as Timestamp).toDate();
        } else if (json['startDate'] is String) {
          startDate = DateTime.parse(json['startDate']);
        }
      }
    } catch (e) {
      startDate = null;
    }

    try {
      if (json['endDate'] != null) {
        if (json['endDate'] is Timestamp) {
          endDate = (json['endDate'] as Timestamp).toDate();
        } else if (json['endDate'] is String) {
          endDate = DateTime.parse(json['endDate']);
        }
      }
    } catch (e) {
      endDate = null;
    }

    try {
      if (json['createdAt'] != null) {
        if (json['createdAt'] is Timestamp) {
          createdAt = (json['createdAt'] as Timestamp).toDate();
        } else if (json['createdAt'] is String) {
          createdAt = DateTime.parse(json['createdAt']);
        }
      }
    } catch (e) {
      createdAt = null;
    }

    // Fallback logic for dates
    final now = DateTime.now();

    // If createdAt is null, try using startDate, otherwise use current time
    if (createdAt == null) {
      createdAt = startDate ?? now;
    }

    // If startDate/endDate are null, set defaults
    if (startDate == null || endDate == null) {
      startDate ??= createdAt;
      endDate ??= now.add(const Duration(days: 30)); // Default 30 days validity
    }

    // Handle notes safely
    String notes = '';
    try {
      notes = (json['notes'] ?? '').toString();
    } catch (e) {
      notes = '';
    }

    // Handle images list safely
    List<String> images = [];
    try {
      if (json['images'] != null) {
        images = List<String>.from(json['images']);
      }
    } catch (e) {
      images = [];
    }

    // fallback: if images is empty but imageUrl exists, use imageUrl
    String imageUrl = (json['imageUrl'] ?? '').toString();
    if (images.isEmpty && imageUrl.isNotEmpty) {
      images = [imageUrl];
    } else if (images.isNotEmpty && imageUrl.isEmpty) {
      imageUrl = images.first;
    }

    return PharmacyOfferModel(
      id: (json['id'] ?? '').toString(),
      pharmacyId: (json['pharmacyId'] ?? '').toString(),
      pharmacyName: (json['pharmacyName'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      notes: notes,
      imageUrl: imageUrl,
      images: images,
      discountPercentage: json['discountPercentage']?.toDouble(),
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      isActive: json['isActive'] ?? true,
      viewsCount: json['viewsCount'] ?? 0,
      category: json['category'] ?? 'عام',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'title': title,
      'description': description,
      'notes': notes,
      'imageUrl': imageUrl,
      'images': images,
      'discountPercentage': discountPercentage,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'viewsCount': viewsCount,
      'category': category,
    };
  }
}
