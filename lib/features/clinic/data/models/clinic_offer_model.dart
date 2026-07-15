import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/generic_offer_sorting_service.dart';

class ClinicOfferModel implements ISortableOffer {
  @override
  final String id;
  final String clinicId;
  final String clinicName;
  final String doctorName;
  final String? clinicType; // "doctor" أو "center" أو null
  final String title;
  final String description;
  final String notes;
  final String imageUrl;
  final List<String> images;
  final double? discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  @override
  final DateTime createdAt;
  final bool isActive;
  @override
  final int viewsCount;
  @override
  final String category;

  ClinicOfferModel({
    required this.id,
    required this.clinicId,
    required this.clinicName,
    required this.doctorName,
    this.clinicType, // Optional
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

  factory ClinicOfferModel.fromJson(Map<String, dynamic> json) {
    // Handle dates safely
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

    // Fallback logic
    final now = DateTime.now();
    createdAt ??= startDate ?? now;
    startDate ??= createdAt;
    endDate ??= now.add(const Duration(days: 30));

    // Handle notes
    String notes = '';
    try {
      notes = (json['notes'] ?? '').toString();
    } catch (e) {
      notes = '';
    }

    // Handle images
    List<String> images = [];
    try {
      if (json['images'] != null) {
        images = List<String>.from(json['images']);
      }
    } catch (e) {
      images = [];
    }

    String imageUrl = (json['imageUrl'] ?? '').toString();
    if (images.isEmpty && imageUrl.isNotEmpty) {
      images = [imageUrl];
    } else if (images.isNotEmpty && imageUrl.isEmpty) {
      imageUrl = images.first;
    }

    return ClinicOfferModel(
      id: (json['id'] ?? '').toString(),
      clinicId: (json['clinicId'] ?? '').toString(),
      clinicName: (json['clinicName'] ?? '').toString(),
      doctorName: (json['doctorName'] ?? '').toString(),
      clinicType: json['clinicType'], // قراءة النوع من Firestore
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
      'clinicId': clinicId,
      'clinicName': clinicName,
      'doctorName': doctorName,
      'clinicType': clinicType,
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

  /// الحصول على اسم الدكتور/المركز كما هو بدون إضافة بادئة
  String get displayName {
    return doctorName;
  }
}
