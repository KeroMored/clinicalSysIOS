import 'package:cloud_firestore/cloud_firestore.dart';

class NurseModel {
  final String id;
  final String nurseName;
  final String nursePhone;
  final String nurseWhatsApp;
  final String gender; // male, female
  final int yearsOfExperience;
  final String specialization; // تمريض عام، تمريض أطفال، تمريض مسنين، رعاية ما بعد العمليات، إلخ
  final String about; // نبذة عن الممرض/ة
  final List<String> services; // الخدمات المنزلية (حقن، قياس ضغط، تغيير جروح، إلخ)
  final double hourlyRate; // السعر بالساعة
  final String address;
  final String governorate;
  final String city;
  final double? latitude;
  final double? longitude;
  
  // Nurse Personal Info
  final String? email;
  final String? nationalId;
  final String? licenseNumber;
  
  // Images
  final String? profileImageUrl;
  final String? licenseImageUrl;
  final String? nationalIdImageUrl;
  
  // Availability
  final bool availableNow;
  final bool available24Hours;
  final Map<String, WorkingHours>? workingHours;
  
  // Status
  final bool isApproved;
  final bool isActive;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes; // Admin notes
  
  // Rating
  final double? rating;
  final int? reviewCount;

  NurseModel({
    required this.id,
    required this.nurseName,
    required this.nursePhone,
    required this.nurseWhatsApp,
    required this.gender,
    required this.yearsOfExperience,
    required this.specialization,
    required this.about,
    required this.services,
    required this.hourlyRate,
    required this.address,
    required this.governorate,
    required this.city,
    this.latitude,
    this.longitude,
    this.email,
    this.nationalId,
    this.licenseNumber,
    this.profileImageUrl,
    this.licenseImageUrl,
    this.nationalIdImageUrl,
    this.availableNow = false,
    this.available24Hours = false,
    this.workingHours,
    this.isApproved = false,
    this.isActive = true,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.rating,
    this.reviewCount,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nurseName': nurseName,
      'nursePhone': nursePhone,
      'nurseWhatsApp': nurseWhatsApp,
      'gender': gender,
      'yearsOfExperience': yearsOfExperience,
      'specialization': specialization,
      'about': about,
      'services': services,
      'hourlyRate': hourlyRate,
      'address': address,
      'governorate': governorate,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'email': email,
      'nationalId': nationalId,
      'licenseNumber': licenseNumber,
      'profileImageUrl': profileImageUrl,
      'licenseImageUrl': licenseImageUrl,
      'nationalIdImageUrl': nationalIdImageUrl,
      'availableNow': availableNow,
      'available24Hours': available24Hours,
      'workingHours': workingHours?.map((key, value) => MapEntry(key, value.toMap())),
      'isApproved': isApproved,
      'isActive': isActive,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'notes': notes,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  // Create from Firestore Document
  factory NurseModel.fromMap(Map<String, dynamic> map) {
    return NurseModel(
      id: map['id'] ?? '',
      nurseName: map['nurseName'] ?? '',
      nursePhone: map['nursePhone'] ?? '',
      nurseWhatsApp: map['nurseWhatsApp'] ?? '',
      gender: map['gender'] ?? 'male',
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      specialization: map['specialization'] ?? '',
      about: map['about'] ?? '',
      services: List<String>.from(map['services'] ?? []),
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      governorate: map['governorate'] ?? '',
      city: map['city'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      email: map['email'],
      nationalId: map['nationalId'],
      licenseNumber: map['licenseNumber'],
      profileImageUrl: map['profileImageUrl'],
      licenseImageUrl: map['licenseImageUrl'],
      nationalIdImageUrl: map['nationalIdImageUrl'],
      availableNow: map['availableNow'] ?? false,
      available24Hours: map['available24Hours'] ?? false,
      workingHours: (map['workingHours'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, WorkingHours.fromMap(value as Map<String, dynamic>)),
          ),
      isApproved: map['isApproved'] ?? false,
      isActive: map['isActive'] ?? true,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      notes: map['notes'],
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'],
    );
  }

  // Copy with method for updates
  NurseModel copyWith({
    String? id,
    String? nurseName,
    String? nursePhone,
    String? nurseWhatsApp,
    String? gender,
    int? yearsOfExperience,
    String? specialization,
    String? about,
    List<String>? services,
    double? hourlyRate,
    String? address,
    String? governorate,
    String? city,
    double? latitude,
    double? longitude,
    String? email,
    String? nationalId,
    String? licenseNumber,
    String? profileImageUrl,
    String? licenseImageUrl,
    String? nationalIdImageUrl,
    bool? availableNow,
    bool? available24Hours,
    Map<String, WorkingHours>? workingHours,
    bool? isApproved,
    bool? isActive,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    double? rating,
    int? reviewCount,
  }) {
    return NurseModel(
      id: id ?? this.id,
      nurseName: nurseName ?? this.nurseName,
      nursePhone: nursePhone ?? this.nursePhone,
      nurseWhatsApp: nurseWhatsApp ?? this.nurseWhatsApp,
      gender: gender ?? this.gender,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      specialization: specialization ?? this.specialization,
      about: about ?? this.about,
      services: services ?? this.services,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      address: address ?? this.address,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      nationalIdImageUrl: nationalIdImageUrl ?? this.nationalIdImageUrl,
      availableNow: availableNow ?? this.availableNow,
      available24Hours: available24Hours ?? this.available24Hours,
      workingHours: workingHours ?? this.workingHours,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

// Working Hours Model
class WorkingHours {
  final String openTime;
  final String closeTime;
  final bool isHoliday;

  WorkingHours({
    required this.openTime,
    required this.closeTime,
    this.isHoliday = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'openTime': openTime,
      'closeTime': closeTime,
      'isHoliday': isHoliday,
    };
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      openTime: map['openTime'] ?? '00:00 AM',
      closeTime: map['closeTime'] ?? '00:00 AM',
      isHoliday: map['isHoliday'] ?? false,
    );
  }
}

// Available nursing services
class NursingServices {
  static const String injection = 'حقن عضل ووريد';
  static const String bloodPressure = 'قياس ضغط الدم';
  static const String bloodSugar = 'قياس السكر';
  static const String woundCare = 'تغيير الجروح والضمادات';
  static const String ivDrip = 'محاليل وريدية';
  static const String catheter = 'تركيب وتغيير القسطرة';
  static const String physiotherapy = 'علاج طبيعي منزلي';
  static const String elderCare = 'رعاية المسنين';
  static const String postOperativeCare = 'رعاية ما بعد العمليات';
  static const String infantCare = 'رعاية الأطفال والرضع';
  static const String oxygenTherapy = 'العلاج بالأكسجين';
  static const String nasogastricTube = 'تركيب أنبوب تغذية';

  static List<String> getAllServices() {
    return [
      injection,
      bloodPressure,
      bloodSugar,
      woundCare,
      ivDrip,
      catheter,
      physiotherapy,
      elderCare,
      postOperativeCare,
      infantCare,
      oxygenTherapy,
      nasogastricTube,
    ];
  }
}

// Specializations
class NurseSpecializations {
  static const String general = 'تمريض عام';
  static const String pediatric = 'تمريض أطفال';
  static const String geriatric = 'تمريض مسنين';
  static const String surgical = 'تمريض جراحي';
  static const String emergency = 'تمريض طوارئ';
  static const String icu = 'رعاية مركزة';
  static const String maternity = 'تمريض نساء وولادة';

  static List<String> getAllSpecializations() {
    return [
      general,
      pediatric,
      geriatric,
      surgical,
      emergency,
      icu,
      maternity,
    ];
  }
}
