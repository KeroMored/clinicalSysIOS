import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryModel {
  final String id;
  final String deliveryName;
  final List<String> deliveryPhones; // Changed to list for multiple phones
  final String deliveryWhatsApp;
  final String? profileImageUrl;
  final String vehicleType; // motorcycle, car, bicycle
  final String vehiclePlateNumber;
  final double deliveryFee; // رسوم التوصيل الافتراضية
  final String address;
  final String governorate;
  final String city;
  final String center; // المركز (مثلاً: ملوي)
  final double? latitude; // Optional - not used
  final double? longitude; // Optional - not used
  final String? about; // Made optional
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
    this.profileImageUrl,
    required this.vehicleType,
    required this.vehiclePlateNumber,
    required this.deliveryFee,
    required this.address,
    required this.governorate,
    required this.city,
    this.center = 'ملوي',
    this.latitude, // Optional
    this.longitude, // Optional
    this.about, // Now optional
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
      'profileImageUrl': profileImageUrl,
      'vehicleType': vehicleType,
      'vehiclePlateNumber': vehiclePlateNumber,
      'deliveryFee': deliveryFee,
      'address': address,
      'governorate': governorate,
      'city': city,
      'center': center,
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
    // Handle legacy data with single deliveryPhone
    List<String> phones = [];
    try {
      if (map['deliveryPhones'] != null) {
        phones = List<String>.from(map['deliveryPhones']);
      } else if (map['deliveryPhone'] != null && map['deliveryPhone'].toString().isNotEmpty) {
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
      profileImageUrl: map['profileImageUrl'],
      vehicleType: map['vehicleType'] ?? 'motorcycle',
      vehiclePlateNumber: map['vehiclePlateNumber'] ?? '',
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      governorate: map['governorate'] ?? '',
      city: map['city'] ?? '',
      center: map['center'] ?? 'ملوي',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      about: map['about'], // Now nullable
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
    String? profileImageUrl,
    String? vehicleType,
    String? vehiclePlateNumber,
    double? deliveryFee,
    String? address,
    String? governorate,
    String? city,
    String? center,
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
      deliveryPhones: deliveryPhones ?? this.deliveryPhones,
      deliveryWhatsApp: deliveryWhatsApp ?? this.deliveryWhatsApp,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      address: address ?? this.address,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      center: center ?? this.center,
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
  
  // Get primary phone
  String get primaryPhone => deliveryPhones.isNotEmpty ? deliveryPhones.first : '';
}

class VehicleTypes {
  static const String motorcycle = 'دراجة نارية';
  static const String car = 'سيارة';
  static const String bicycle = 'دراجة';

  static List<String> getAllTypes() {
    return [motorcycle, car, bicycle];
  }
}
