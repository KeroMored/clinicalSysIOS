import 'package:cloud_firestore/cloud_firestore.dart';
import 'working_hours.dart';

class LaboratoryModel {
  final String id;
  final String name;
  final String ownerName;
  final List<String> authEmails; // إيميلات المصادقة للدخول
  final String ownerPhone;
  final String address;
  final String city;
  final String governorate;
  final double latitude;
  final double longitude;
  final String? logoUrl;
  final List<String> availableTests; // قائمة التحاليل المتاحة
  final Map<String, WorkingHours> workingHours;
  final bool isVisible;
  final String status; // pending, approved, rejected
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hasHomeService; // خدمة تحاليل منزلية
  final double? homeServiceFee; // رسوم الخدمة المنزلية
  final String? description;
  final int? estimatedResultTime; // وقت ظهور النتيجة بالساعات
  final double averageRating; // متوسط التقييم (0.0 - 5.0)
  final int totalRatings; // عدد التقييمات
  final int totalLikes; // عدد اللايكات

  LaboratoryModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.authEmails,
    required this.ownerPhone,
    required this.address,
    required this.city,
    required this.governorate,
    required this.latitude,
    required this.longitude,
    this.logoUrl,
    required this.availableTests,
    required this.workingHours,
    this.isVisible = true,
    this.status = 'pending',
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.hasHomeService = false,
    this.homeServiceFee,
    this.description,
    this.estimatedResultTime,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalLikes = 0,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerName': ownerName,
      'authEmails': authEmails,
      'ownerPhone': ownerPhone,
      'address': address,
      'city': city,
      'governorate': governorate,
      'latitude': latitude,
      'longitude': longitude,
      'logoUrl': logoUrl,
      'availableTests': availableTests,
      'workingHours': workingHours.map((key, value) => MapEntry(key, value.toMap())),
      'isVisible': isVisible,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'hasHomeService': hasHomeService,
      'homeServiceFee': homeServiceFee,
      'description': description,
      'estimatedResultTime': estimatedResultTime,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalLikes': totalLikes,
    };
  }

  // Create from Firestore
  factory LaboratoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return LaboratoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      ownerName: data['ownerName'] ?? '',
      authEmails: data['authEmails'] != null
          ? List<String>.from(data['authEmails'])
          : (data['ownerEmail'] != null ? [data['ownerEmail']] : []),
      ownerPhone: data['ownerPhone'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      governorate: data['governorate'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      logoUrl: data['logoUrl'],
      availableTests: List<String>.from(data['availableTests'] ?? []),
      workingHours: (data['workingHours'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, WorkingHours.fromMap(value)),
          ) ??
          {},
      isVisible: data['isVisible'] ?? true,
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      hasHomeService: data['hasHomeService'] ?? false,
      homeServiceFee: data['homeServiceFee']?.toDouble(),
      description: data['description'],
      estimatedResultTime: data['estimatedResultTime'],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
    );
  }

  // Copy with method
  LaboratoryModel copyWith({
    String? id,
    String? name,
    String? ownerName,
    List<String>? authEmails,
    String? ownerPhone,
    String? address,
    String? city,
    String? governorate,
    double? latitude,
    double? longitude,
    String? logoUrl,
    List<String>? availableTests,
    Map<String, WorkingHours>? workingHours,
    bool? isVisible,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasHomeService,
    double? homeServiceFee,
    String? description,
    int? estimatedResultTime,
  }) {
    return LaboratoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      authEmails: authEmails ?? this.authEmails,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      governorate: governorate ?? this.governorate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      logoUrl: logoUrl ?? this.logoUrl,
      availableTests: availableTests ?? this.availableTests,
      workingHours: workingHours ?? this.workingHours,
      isVisible: isVisible ?? this.isVisible,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasHomeService: hasHomeService ?? this.hasHomeService,
      homeServiceFee: homeServiceFee ?? this.homeServiceFee,
      description: description ?? this.description,
      estimatedResultTime: estimatedResultTime ?? this.estimatedResultTime,
    );
  }
}
