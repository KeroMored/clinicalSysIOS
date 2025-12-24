import 'package:cloud_firestore/cloud_firestore.dart';

class RehabilitationTypes {
  static const String speechTherapy = 'علاج تخاطب';
  static const String physicalTherapy = 'علاج طبيعي';
  static const String occupationalTherapy = 'علاج وظيفي';
  static const String behaviorTherapy = 'تعديل سلوك';
  static const String autismCenter = 'مركز توحد';
  static const String specialEducation = 'تربية خاصة';
  static const String hearingRehab = 'تأهيل سمعي';
  static const String mentalHealth = 'صحة نفسية';
  
  static List<String> get allTypes => [
    speechTherapy,
    physicalTherapy,
    occupationalTherapy,
    behaviorTherapy,
    autismCenter,
    specialEducation,
    hearingRehab,
    mentalHealth,
  ];
}

class WorkingHours {
  final String from;
  final String to;
  final bool isClosed;

  WorkingHours({
    required this.from,
    required this.to,
    this.isClosed = false,
  });

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      from: map['from'] ?? '09:00',
      to: map['to'] ?? '17:00',
      isClosed: map['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'isClosed': isClosed,
    };
  }
}

class RehabilitationCenterModel {
  final String id;
  final String centerName;
  final String directorName;
  final String phone;
  final String? whatsapp;
  final List<String> authEmails; // إيميلات المصادقة للدخول
  final List<String> serviceTypes;
  final String address;
  final double latitude;
  final double longitude;
  final String? profileImageUrl;
  final String description;
  final Map<String, WorkingHours> workingDays; // أيام العمل ومواعيدها
  final bool hasHomeService;
  final bool isApproved;
  final bool isActive;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double rating; // old field - keep for backward compatibility
  final int reviewCount; // old field
  final double averageRating; // متوسط التقييم (0.0 - 5.0) - new field
  final int totalRatings; // عدد التقييمات
  final int totalLikes; // عدد اللايكات

  RehabilitationCenterModel({
    required this.id,
    required this.centerName,
    required this.directorName,
    required this.phone,
    this.whatsapp,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalLikes = 0,
    required this.authEmails,
    required this.serviceTypes,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.profileImageUrl,
    required this.description,
    required this.workingDays,
    this.hasHomeService = false,
    this.isApproved = false,
    this.isActive = true,
    this.status = 'pending',
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> workingDaysMap = {};
    workingDays.forEach((day, hours) {
      workingDaysMap[day] = hours.toMap();
    });

    return {
      'id': id,
      'centerName': centerName,
      'directorName': directorName,
      'phone': phone,
      'whatsapp': whatsapp,
      'authEmails': authEmails,
      'serviceTypes': serviceTypes,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'profileImageUrl': profileImageUrl,
      'description': description,
      'workingDays': workingDaysMap,
      'hasHomeService': hasHomeService,
      'isApproved': isApproved,
      'isActive': isActive,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rating': rating,
      'reviewCount': reviewCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalLikes': totalLikes,
    };
  }

  factory RehabilitationCenterModel.fromMap(Map<String, dynamic> map) {
    Map<String, WorkingHours> parsedWorkingDays = {};
    if (map['workingDays'] != null) {
      final daysData = map['workingDays'] as Map<String, dynamic>;
      daysData.forEach((day, hours) {
        if (hours != null) {
          parsedWorkingDays[day] = WorkingHours.fromMap(hours as Map<String, dynamic>);
        }
      });
    }

    return RehabilitationCenterModel(
      id: map['id'] ?? '',
      centerName: map['centerName'] ?? '',
      directorName: map['directorName'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'],
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      totalLikes: map['totalLikes'] ?? 0,
      authEmails: map['authEmails'] != null
          ? List<String>.from(map['authEmails'])
          : (map['ownerEmail'] != null ? [map['ownerEmail']] : []),
      serviceTypes: List<String>.from(map['serviceTypes'] ?? []),
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      profileImageUrl: map['profileImageUrl'],
      description: map['description'] ?? '',
      workingDays: parsedWorkingDays,
      hasHomeService: map['hasHomeService'] ?? false,
      isApproved: map['isApproved'] ?? false,
      isActive: map['isActive'] ?? true,
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  RehabilitationCenterModel copyWith({
    String? id,
    String? centerName,
    String? directorName,
    String? phone,
    String? whatsapp,
    List<String>? authEmails,
    List<String>? serviceTypes,
    String? address,
    double? latitude,
    double? longitude,
    String? profileImageUrl,
    String? description,
    Map<String, WorkingHours>? workingDays,
    bool? hasHomeService,
    bool? isApproved,
    bool? isActive,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    int? reviewCount,
  }) {
    return RehabilitationCenterModel(
      id: id ?? this.id,
      centerName: centerName ?? this.centerName,
      directorName: directorName ?? this.directorName,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      authEmails: authEmails ?? this.authEmails,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      description: description ?? this.description,
      workingDays: workingDays ?? this.workingDays,
      hasHomeService: hasHomeService ?? this.hasHomeService,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
