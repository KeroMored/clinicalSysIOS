import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalSupplyModel {
  static const String noHolidaysText = 'متاح طوال الإسبوع';

  static String normalizeHolidays(dynamic rawHolidays) {
    final value = (rawHolidays?.toString() ?? '').trim();
    if (value.isEmpty ||
        value == 'لا يوجد' ||
        value == 'لا يوجد - متاحون دائماً' ||
        value == 'متاح طوال الأسبوع' ||
        value == noHolidaysText) {
      return noHolidaysText;
    }
    return value;
  }

  final String id;
  final String name;
  final String? description;
  final String address;
  final List<String> phones;
  final String whatsapp;
  final double latitude;
  final double longitude;
  final String workingHours;
  final String holidays;
  final List<String> images;
  final bool hasHomeDelivery;
  final double? deliveryFee;
  final double? minimumOrderForDelivery;
  final double rating;
  final int reviewsCount;
  final bool isOpen;
  final String? closingTime;
  final List<String> services;
  final String status; // 'pending', 'approved', 'rejected'
  final String ownerName;
  final String ownerPhone;
  final List<String> authEmails;
  final String governorate;
  final String center;

  // Rating and Engagement
  final double averageRating;
  final int totalRatings;
  final int totalLikes;
  final int profileViewsCount;

  MedicalSupplyModel({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    this.phones = const [],
    required this.whatsapp,
    required this.latitude,
    required this.longitude,
    required this.workingHours,
    required this.holidays,
    required this.images,
    required this.hasHomeDelivery,
    this.deliveryFee,
    this.minimumOrderForDelivery,
    this.rating = 0.0,
    this.reviewsCount = 0,
    required this.isOpen,
    this.closingTime,
    this.services = const [],
    this.status = 'pending',
    this.ownerName = '',
    this.ownerPhone = '',
    this.authEmails = const [],
    this.governorate = 'المنيا',
    this.center = 'ملوي',
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalLikes = 0,
    this.profileViewsCount = 0,
  });

  factory MedicalSupplyModel.fromJson(Map<String, dynamic> json) {
    return MedicalSupplyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'] ?? '',
      phones: json['phones'] != null
          ? List<String>.from(json['phones'])
          : (json['phone'] != null ? [json['phone']] : []),
      whatsapp: json['whatsapp'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      workingHours: json['workingHours'] ?? '',
      holidays: normalizeHolidays(json['holidays']),
      images: List<String>.from(json['images'] ?? []),
      hasHomeDelivery: json['hasHomeDelivery'] ?? false,
      deliveryFee: json['deliveryFee']?.toDouble(),
      minimumOrderForDelivery: json['minimumOrderForDelivery']?.toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      isOpen: json['isOpen'] ?? true,
      closingTime: json['closingTime'],
      services: List<String>.from(json['services'] ?? []),
      status: json['status'] ?? 'pending',
      ownerName: json['ownerName'] ?? '',
      ownerPhone: json['ownerPhone'] ?? '',
      authEmails: json['authEmails'] != null
          ? List<String>.from(json['authEmails'])
          : (json['ownerEmail'] != null ? [json['ownerEmail']] : []),
      governorate: json['governorate'] ?? 'المنيا',
      center: json['center'] ?? 'ملوي',
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      profileViewsCount: json['profileViewsCount'] ?? 0,
    );
  }

  factory MedicalSupplyModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return MedicalSupplyModel(
      id: doc.id,
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'] ?? '',
      phones: json['phones'] != null
          ? List<String>.from(json['phones'])
          : (json['phone'] != null ? [json['phone']] : []),
      whatsapp: json['whatsapp'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      workingHours: json['workingHours'] ?? '',
      holidays: normalizeHolidays(json['holidays']),
      images: List<String>.from(json['images'] ?? []),
      hasHomeDelivery: json['hasHomeDelivery'] ?? false,
      deliveryFee: json['deliveryFee']?.toDouble(),
      minimumOrderForDelivery: json['minimumOrderForDelivery']?.toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      isOpen: json['isOpen'] ?? true,
      closingTime: json['closingTime'],
      services: List<String>.from(json['services'] ?? []),
      status: json['status'] ?? 'pending',
      ownerName: json['ownerName'] ?? '',
      ownerPhone: json['ownerPhone'] ?? '',
      authEmails: json['authEmails'] != null
          ? List<String>.from(json['authEmails'])
          : (json['ownerEmail'] != null ? [json['ownerEmail']] : []),
      governorate: json['governorate'] ?? 'المنيا',
      center: json['center'] ?? 'ملوي',
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      profileViewsCount: json['profileViewsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phones': phones,
      'whatsapp': whatsapp,
      'latitude': latitude,
      'longitude': longitude,
      'workingHours': workingHours,
      'holidays': normalizeHolidays(holidays),
      'images': images,
      'hasHomeDelivery': hasHomeDelivery,
      'deliveryFee': deliveryFee,
      'minimumOrderForDelivery': minimumOrderForDelivery,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'isOpen': isOpen,
      'closingTime': closingTime,
      'services': services,
      'status': status,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'authEmails': authEmails,
      'governorate': governorate,
      'center': center,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalLikes': totalLikes,
      'profileViewsCount': profileViewsCount,
    };
  }

  MedicalSupplyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    List<String>? phones,
    String? whatsapp,
    double? latitude,
    double? longitude,
    String? workingHours,
    String? holidays,
    List<String>? images,
    bool? hasHomeDelivery,
    double? deliveryFee,
    double? minimumOrderForDelivery,
    double? rating,
    int? reviewsCount,
    bool? isOpen,
    String? closingTime,
    List<String>? services,
    String? status,
    String? ownerName,
    String? ownerPhone,
    List<String>? authEmails,
    String? governorate,
    String? center,
  }) {
    return MedicalSupplyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phones: phones ?? this.phones,
      whatsapp: whatsapp ?? this.whatsapp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      workingHours: workingHours ?? this.workingHours,
      holidays: normalizeHolidays(holidays ?? this.holidays),
      images: images ?? this.images,
      hasHomeDelivery: hasHomeDelivery ?? this.hasHomeDelivery,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrderForDelivery:
          minimumOrderForDelivery ?? this.minimumOrderForDelivery,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isOpen: isOpen ?? this.isOpen,
      closingTime: closingTime ?? this.closingTime,
      services: services ?? this.services,
      status: status ?? this.status,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      authEmails: authEmails ?? this.authEmails,
      governorate: governorate ?? this.governorate,
      center: center ?? this.center,
    );
  }
}
