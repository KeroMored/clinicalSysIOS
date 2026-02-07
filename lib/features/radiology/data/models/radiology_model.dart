import 'package:cloud_firestore/cloud_firestore.dart';
import 'working_hours.dart';

class RadiologyModel {
  final String id;
  final String centerName;
  final String centerPhone;
  final String centerWhatsApp;
  final String ownerName;
  final String ownerPhone;
  final List<String> authEmails; // إيميلات المصادقة للدخول
  final String address;
  final double latitude;
  final double longitude;
  final String governorate;
  final String city;
  final String center; // المركز (مثلاً: ملوي)
  final String? description; // وصف مركز الأشعة
  final List<String> services; // X-Ray, CT Scan, MRI, Ultrasound, Mammography, DEXA Scan, etc.
  final bool homeVisit; // Mobile radiology service
  final String? licenseNumber;
  final String? licenseImageUrl;
  final Map<String, WorkingHours> workingHours;
  final bool isApproved;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes; // Admin notes
  final double? rating; // Average rating (old field - keep for backward compatibility)
  final int? reviewCount; // old field
  final double averageRating; // متوسط التقييم (0.0 - 5.0) - new field
  final int totalRatings; // عدد التقييمات
  final int totalLikes; // عدد اللايكات

  RadiologyModel({
    required this.id,
    required this.centerName,
    required this.centerPhone,
    required this.centerWhatsApp,
    required this.ownerName,
    required this.ownerPhone,
    required this.authEmails,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.governorate,
    required this.city,
    this.center = 'ملوي',
    this.description,
    required this.services,
    required this.homeVisit,
    this.licenseNumber,
    this.licenseImageUrl,
    required this.workingHours,
    this.isApproved = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.rating,
    this.reviewCount,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalLikes = 0,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'centerName': centerName,
      'centerPhone': centerPhone,
      'centerWhatsApp': centerWhatsApp,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'authEmails': authEmails,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'governorate': governorate,
      'city': city,
      'center': center,
      'description': description,
      'services': services,
      'homeVisit': homeVisit,
      'licenseNumber': licenseNumber,
      'licenseImageUrl': licenseImageUrl,
      'workingHours': workingHours.map((key, value) => MapEntry(key, value.toMap())),
      'isApproved': isApproved,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'notes': notes,
      'rating': rating,
      'reviewCount': reviewCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalLikes': totalLikes,
    };
  }

  // Create from Firestore Document
  factory RadiologyModel.fromMap(Map<String, dynamic> map) {
    return RadiologyModel(
      id: map['id'] ?? '',
      centerName: map['centerName'] ?? '',
      centerPhone: map['centerPhone'] ?? '',
      centerWhatsApp: map['centerWhatsApp'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      authEmails: map['authEmails'] != null
          ? List<String>.from(map['authEmails'])
          : (map['ownerEmail'] != null ? [map['ownerEmail']] : []),
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      governorate: map['governorate'] ?? '',
      city: map['city'] ?? '',
      center: map['center'] ?? 'ملوي',
      description: map['description'],
      services: List<String>.from(map['services'] ?? []),
      homeVisit: map['homeVisit'] ?? false,
      licenseNumber: map['licenseNumber'],
      licenseImageUrl: map['licenseImageUrl'],
      workingHours: (map['workingHours'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, WorkingHours.fromMap(value as Map<String, dynamic>)),
          ) ??
          {},
      isApproved: map['isApproved'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      notes: map['notes'],
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'],
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      totalLikes: map['totalLikes'] ?? 0,
    );
  }

  // Copy with method for updates
  RadiologyModel copyWith({
    String? id,
    String? centerName,
    String? centerPhone,
    String? centerWhatsApp,
    String? ownerName,
    String? ownerPhone,
    List<String>? authEmails,
    String? address,
    double? latitude,
    double? longitude,
    String? governorate,
    String? city,
    String? center,
    String? description,
    List<String>? services,
    bool? homeVisit,
    String? licenseNumber,
    String? licenseImageUrl,
    Map<String, WorkingHours>? workingHours,
    bool? isApproved,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    double? rating,
    int? reviewCount,
  }) {
    return RadiologyModel(
      id: id ?? this.id,
      centerName: centerName ?? this.centerName,
      centerPhone: centerPhone ?? this.centerPhone,
      centerWhatsApp: centerWhatsApp ?? this.centerWhatsApp,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      authEmails: authEmails ?? this.authEmails,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      center: center ?? this.center,
      description: description ?? this.description,
      services: services ?? this.services,
      homeVisit: homeVisit ?? this.homeVisit,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      workingHours: workingHours ?? this.workingHours,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

// Available radiology services
class RadiologyServices {
  static const String xRay = 'أشعة سينية (X-Ray)';
  static const String ctScan = 'أشعة مقطعية (CT Scan)';
  static const String mri = 'رنين مغناطيسي (MRI)';
  static const String ultrasound = 'موجات فوق صوتية (Ultrasound)';
  static const String ultrasound4D = 'سونار رباعي الأبعاد (4D Ultrasound)';
  static const String mammography = 'ماموجرام (Mammography)';
  static const String dexaScan = 'قياس كثافة العظام (DEXA Scan)';
  static const String fluoroscopy = 'فلوروسكوبي (Fluoroscopy)';
  static const String doppler = 'دوبلر (Doppler)';
  static const String echocardiography = 'إيكو القلب (Echocardiography)';
  static const String panoramic = 'أشعة بانوراما (Panoramic X-Ray)';

  static List<String> getAllServices() {
    return [
      xRay,
      ctScan,
      mri,
      ultrasound,
      ultrasound4D,
      mammography,
      dexaScan,
      fluoroscopy,
      doppler,
      echocardiography,
      panoramic,
    ];
  }
}
