import 'package:cloud_firestore/cloud_firestore.dart';

class GymModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String governorate;
  final String center; // المركز (مثلاً: ملوي)
  final double latitude;
  final double longitude;
  final List<String> phones; // Support multiple phone numbers
  final String whatsapp;
  final String? logoUrl;
  final List<String> images;

  // Gym specific features
  final bool hasMaleSection;
  final bool hasFemaleSection;
  final bool hasPersonalTraining;
  final bool hasNutritionConsultation;
  final bool hasSwimmingPool;
  final bool hasSauna;
  final bool hasSteamRoom;
  final bool hasYogaClasses;
  final bool hasCrossFit;
  final bool hasMartialArts;

  // Training Types (أنواع التدريب)
  final bool hasCardio; // كارديو - تمارين التخسيس
  final bool hasWeightLifting; // رفع الأثقال
  final bool hasBodybuilding; // تدريب كمال أجسام
  final bool hasFunctionalTraining; // تدريب وظيفي
  final bool hasGroupClasses; // حصص جماعية

  // New dynamic lists for features and training types
  final List<String> features; // قائمة المميزات الديناميكية
  final List<String> trainingTypes; // قائمة أنواع التدريب الديناميكية

  // Working hours
  final Map<String, GymWorkingHours> maleWorkingHours;
  final Map<String, GymWorkingHours> femaleWorkingHours;

  // Pricing
  final double? monthlySubscription;
  final double? yearlySubscription;
  final double? singleSessionPrice;

  // Rating (old fields - keep for backward compatibility)
  final double rating;
  final int reviewsCount;

  // New rating fields
  final double averageRating; // متوسط التقييم (0.0 - 5.0)
  final int totalRatings; // عدد التقييمات
  final int totalLikes; // عدد اللايكات

  // Owner info
  final String ownerId;
  final String ownerName;
  final List<String> authEmails; // إيميلات المصادقة للدخول

  // Status
  final bool isApproved;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? approvedAt;

  GymModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.governorate,
    this.center = 'ملوي',
    required this.latitude,
    required this.longitude,
    required this.phones,
    required this.whatsapp,
    this.logoUrl,
    required this.images,
    required this.hasMaleSection,
    required this.hasFemaleSection,
    this.hasPersonalTraining = false,
    this.hasNutritionConsultation = false,
    this.hasSwimmingPool = false,
    this.hasSauna = false,
    this.hasSteamRoom = false,
    this.hasYogaClasses = false,
    this.hasCrossFit = false,
    this.hasMartialArts = false,
    this.hasCardio = false,
    this.hasWeightLifting = false,
    this.hasBodybuilding = false,
    this.hasFunctionalTraining = false,
    this.hasGroupClasses = false,
    this.features = const [],
    this.trainingTypes = const [],
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalLikes = 0,
    required this.maleWorkingHours,
    required this.femaleWorkingHours,
    this.monthlySubscription,
    this.yearlySubscription,
    this.singleSessionPrice,

    this.rating = 0.0,
    this.reviewsCount = 0,
    required this.ownerId,
    required this.ownerName,
    required this.authEmails,
    this.isApproved = false,
    this.isActive = true,
    required this.createdAt,
    this.approvedAt,
  });

  factory GymModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GymModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      governorate: data['governorate'] ?? '',
      center: data['center'] ?? 'ملوي',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      phones: data['phones'] != null
          ? List<String>.from(data['phones'])
          : (data['phone'] != null ? [data['phone']] : []), // Backward compatibility
      whatsapp: data['whatsapp'] ?? '',
      logoUrl: data['logoUrl'],
      images: List<String>.from(data['images'] ?? []),
      hasMaleSection: data['hasMaleSection'] ?? false,
      hasFemaleSection: data['hasFemaleSection'] ?? false,
      hasPersonalTraining: data['hasPersonalTraining'] ?? false,
      hasNutritionConsultation: data['hasNutritionConsultation'] ?? false,
      hasSwimmingPool: data['hasSwimmingPool'] ?? false,
      hasSauna: data['hasSauna'] ?? false,
      hasSteamRoom: data['hasSteamRoom'] ?? false,
      hasYogaClasses: data['hasYogaClasses'] ?? false,
      hasCrossFit: data['hasCrossFit'] ?? false,
      hasMartialArts: data['hasMartialArts'] ?? false,
      hasCardio: data['hasCardio'] ?? false,
      hasWeightLifting: data['hasWeightLifting'] ?? false,
      hasBodybuilding: data['hasBodybuilding'] ?? false,
      hasFunctionalTraining: data['hasFunctionalTraining'] ?? false,
      hasGroupClasses: data['hasGroupClasses'] ?? false,
      features: List<String>.from(data['features'] ?? []),
      trainingTypes: List<String>.from(data['trainingTypes'] ?? []),
      maleWorkingHours:
          (data['maleWorkingHours'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              GymWorkingHours.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      femaleWorkingHours:
          (data['femaleWorkingHours'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              GymWorkingHours.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      monthlySubscription: data['monthlySubscription']?.toDouble(),
      yearlySubscription: data['yearlySubscription']?.toDouble(),
      singleSessionPrice: data['singleSessionPrice']?.toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      authEmails: data['authEmails'] != null
          ? List<String>.from(data['authEmails'])
          : (data['ownerEmail'] != null ? [data['ownerEmail']] : []),
      isApproved: data['isApproved'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'governorate': governorate,
      'center': center,
      'latitude': latitude,
      'longitude': longitude,
      'phones': phones,
      'whatsapp': whatsapp,
      'logoUrl': logoUrl,
      'images': images,
      'hasMaleSection': hasMaleSection,
      'hasFemaleSection': hasFemaleSection,
      'hasPersonalTraining': hasPersonalTraining,
      'hasNutritionConsultation': hasNutritionConsultation,
      'hasSwimmingPool': hasSwimmingPool,
      'hasSauna': hasSauna,
      'hasSteamRoom': hasSteamRoom,
      'hasYogaClasses': hasYogaClasses,
      'hasCrossFit': hasCrossFit,
      'hasMartialArts': hasMartialArts,
      'hasCardio': hasCardio,
      'hasWeightLifting': hasWeightLifting,
      'hasBodybuilding': hasBodybuilding,
      'hasFunctionalTraining': hasFunctionalTraining,
      'hasGroupClasses': hasGroupClasses,
      'features': features,
      'trainingTypes': trainingTypes,
      'maleWorkingHours': maleWorkingHours.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'femaleWorkingHours': femaleWorkingHours.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'monthlySubscription': monthlySubscription,
      'yearlySubscription': yearlySubscription,
      'singleSessionPrice': singleSessionPrice,

      'rating': rating,
      'reviewsCount': reviewsCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalLikes': totalLikes,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'authEmails': authEmails,
      'isApproved': isApproved,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }
}

class WorkingHours {
  final String openTime;
  final String closeTime;
  final bool isHoliday;

  WorkingHours({
    required this.openTime,
    required this.closeTime,
    this.isHoliday = false,
  });

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      openTime: map['openTime'] ?? '00:00',
      closeTime: map['closeTime'] ?? '00:00',
      isHoliday: map['isHoliday'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'openTime': openTime,
      'closeTime': closeTime,
      'isHoliday': isHoliday,
    };
  }
}

class TimeSlot {
  final String from;
  final String to;

  TimeSlot({required this.from, required this.to});

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(from: map['from'] ?? '09:00', to: map['to'] ?? '17:00');
  }

  Map<String, dynamic> toMap() {
    return {'from': from, 'to': to};
  }
}

class GymWorkingHours {
  final List<TimeSlot> slots;
  final bool isClosed;

  GymWorkingHours({
    List<TimeSlot>? slots,
    this.isClosed = false,
  }) : slots = slots ?? [TimeSlot(from: '08:00', to: '22:00')];

  factory GymWorkingHours.fromMap(Map<String, dynamic> map) {
    List<TimeSlot> parsedSlots = [];
    
    // Support new format with slots
    if (map['slots'] != null && map['slots'] is List) {
      for (var slotMap in map['slots']) {
        parsedSlots.add(TimeSlot.fromMap(slotMap as Map<String, dynamic>));
      }
    }
    // Support old format with openTime/closeTime
    else if (map['openTime'] != null && map['closeTime'] != null) {
      parsedSlots.add(TimeSlot(
        from: map['openTime'],
        to: map['closeTime'],
      ));
    } else {
      parsedSlots.add(TimeSlot(from: '08:00', to: '22:00'));
    }

    return GymWorkingHours(
      slots: parsedSlots,
      isClosed: map['isClosed'] ?? map['isHoliday'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slots': slots.map((s) => s.toMap()).toList(),
      'isClosed': isClosed,
      // Keep old format for backward compatibility
      'openTime': slots.isNotEmpty ? slots.first.from : '08:00',
      'closeTime': slots.isNotEmpty ? slots.first.to : '22:00',
      'isHoliday': isClosed,
    };
  }
}
