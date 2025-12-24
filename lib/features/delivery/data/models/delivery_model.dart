import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryModel {
  final String id;
  final String deliveryName;
  final String deliveryPhone;
  final String deliveryWhatsApp;
  final String? profileImageUrl;
  final String vehicleType; // motorcycle, car, bicycle
  final String vehiclePlateNumber;
  final double deliveryFee; // رسوم التوصيل الافتراضية
  final String address;
  final String governorate;
  final String city;
  final double latitude;
  final double longitude;
  final String about;
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
    required this.deliveryPhone,
    required this.deliveryWhatsApp,
    this.profileImageUrl,
    required this.vehicleType,
    required this.vehiclePlateNumber,
    required this.deliveryFee,
    required this.address,
    required this.governorate,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.about,
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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deliveryName': deliveryName,
      'deliveryPhone': deliveryPhone,
      'deliveryWhatsApp': deliveryWhatsApp,
      'profileImageUrl': profileImageUrl,
      'vehicleType': vehicleType,
      'vehiclePlateNumber': vehiclePlateNumber,
      'deliveryFee': deliveryFee,
      'address': address,
      'governorate': governorate,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'about': about,
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
    return DeliveryModel(
      id: map['id'] ?? '',
      deliveryName: map['deliveryName'] ?? '',
      deliveryPhone: map['deliveryPhone'] ?? '',
      deliveryWhatsApp: map['deliveryWhatsApp'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      vehicleType: map['vehicleType'] ?? 'motorcycle',
      vehiclePlateNumber: map['vehiclePlateNumber'] ?? '',
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      governorate: map['governorate'] ?? '',
      city: map['city'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      about: map['about'] ?? '',
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
    String? deliveryPhone,
    String? deliveryWhatsApp,
    String? profileImageUrl,
    String? vehicleType,
    String? vehiclePlateNumber,
    double? deliveryFee,
    String? address,
    String? governorate,
    String? city,
    double? latitude,
    double? longitude,
    String? about,
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
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      deliveryWhatsApp: deliveryWhatsApp ?? this.deliveryWhatsApp,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      address: address ?? this.address,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      about: about ?? this.about,
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
}

class VehicleTypes {
  static const String motorcycle = 'دراجة نارية';
  static const String car = 'سيارة';
  static const String bicycle = 'دراجة';

  static List<String> getAllTypes() {
    return [motorcycle, car, bicycle];
  }
}
