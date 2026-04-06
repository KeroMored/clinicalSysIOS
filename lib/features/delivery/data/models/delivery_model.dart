import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryModel {
  final String id;
  final String deliveryName;
  final List<String> deliveryPhones;
  final String deliveryWhatsApp;
  final String governorate;
  final String city;
  final String center; // المركز (مثلاً: ملوي)
  final bool availableNow;
  final bool isApproved;
  final bool isActive;
  final String status; // pending, approved, rejected, suspended
  final DateTime createdAt;
  final DateTime updatedAt;
  final double rating;
  final int reviewCount;
  final int completedDeliveries;
  final String? notes;
  final double averageRating;
  final int totalRatings;
  final int likesCount;

  DeliveryModel({
    required this.id,
    required this.deliveryName,
    List<String>? deliveryPhones,
    required this.deliveryWhatsApp,
    required this.governorate,
    required this.city,
    this.center = 'ملوي',
    required this.availableNow,
    required this.isApproved,
    required this.isActive,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.completedDeliveries = 0,
    this.notes,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.likesCount = 0,
  }) : deliveryPhones = deliveryPhones ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deliveryName': deliveryName,
      'deliveryPhones': deliveryPhones,
      'deliveryWhatsApp': deliveryWhatsApp,
      'governorate': governorate,
      'city': city,
      'center': center,
      'availableNow': availableNow,
      'isApproved': isApproved,
      'isActive': isActive,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rating': rating,
      'reviewCount': reviewCount,
      'completedDeliveries': completedDeliveries,
      'notes': notes,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'likesCount': likesCount,
    };
  }

  factory DeliveryModel.fromMap(Map<String, dynamic> map) {
    // Handle legacy data with single deliveryPhone
    List<String> phones = [];
    try {
      if (map['deliveryPhones'] != null) {
        phones = List<String>.from(map['deliveryPhones']);
      } else if (map['deliveryPhone'] != null &&
          map['deliveryPhone'].toString().isNotEmpty) {
        phones = [map['deliveryPhone'].toString()];
      }
    } catch (e) {
      print('Error parsing delivery phones: $e');
      phones = [];
    }

    return DeliveryModel(
      id: map['id'] ?? '',
      deliveryName: map['deliveryName'] ?? '',
      deliveryPhones: phones,
      deliveryWhatsApp: map['deliveryWhatsApp'] ?? '',
      governorate: map['governorate'] ?? '',
      city: map['city'] ?? '',
      center: map['center'] ?? 'ملوي',
      availableNow: map['availableNow'] ?? false,
      isApproved: map['isApproved'] ?? false,
      isActive: map['isActive'] ?? false,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      completedDeliveries: map['completedDeliveries'] ?? 0,
      notes: map['notes'],
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
    );
  }

  DeliveryModel copyWith({
    String? id,
    String? deliveryName,
    List<String>? deliveryPhones,
    String? deliveryWhatsApp,
    String? governorate,
    String? city,
    String? center,
    bool? availableNow,
    bool? isApproved,
    bool? isActive,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    int? reviewCount,
    int? completedDeliveries,
    String? notes,
    double? averageRating,
    int? totalRatings,
    int? likesCount,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      deliveryName: deliveryName ?? this.deliveryName,
      deliveryPhones: deliveryPhones ?? this.deliveryPhones,
      deliveryWhatsApp: deliveryWhatsApp ?? this.deliveryWhatsApp,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      center: center ?? this.center,
      availableNow: availableNow ?? this.availableNow,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      notes: notes ?? this.notes,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      likesCount: likesCount ?? this.likesCount,
    );
  }

  // Get primary phone
  String get primaryPhone =>
      deliveryPhones.isNotEmpty ? deliveryPhones.first : '';
}
