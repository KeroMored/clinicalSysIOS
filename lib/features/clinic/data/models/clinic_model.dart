import 'package:cloud_firestore/cloud_firestore.dart';
import 'clinic_department.dart';

class ClinicModel {
  final String id;
  final String doctorName;
  final ClinicDepartment department;
  final List<String> specialization; // خدمات العيادة كنقاط
  final String about; // نبذة عن الدكتور
  final double consultationFee; // سعر الكشف
  final List<String> phones; // أرقام هاتف العيادة (يمكن أن تكون متعددة)
  final String? whatsapp; // رقم واتساب العيادة
  final String address;
  final double? latitude;
  final double? longitude;
  final String governorate; // المحافظة (مثلاً: المنيا)
  final String center; // المركز (مثلاً: ملوي)

  // Doctor Account Info
  final List<String>
  authEmails; // إيميلات المصادقة للدخول (يمكن أن تكون أكثر من إيميل)
  final List<String> doctorEmails; // إيميلات الدكاترة (صلاحيات كاملة)
  final List<String> secretaryEmails; // إيميلات السكرتيرة (صلاحيات محدودة)
  final String? doctorPhone; // رقم تليفون الدكتور الشخصي

  // Working Hours
  final Map<String, WorkingHours>
  workingHours; // Key: day name (saturday, sunday, etc.)
  final List<String> holidays; // أيام العطلات الرسمية

  // Additional Info
  final bool hasNursery; // يوجد حضانة (لعيادات الأطفال فقط)
  final bool onlineBookingEnabled; // متاح الحجز أونلاين
  final DateTime? bookingLockDate; // تاريخ قفل الحجز الأونلاين
  final String? doctorImageUrl;
  final bool isActive;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final String? ownerId; // إذا كان الدكتور يملك حساب

  // Rating and Engagement
  final double averageRating; // متوسط التقييم (0.0 - 5.0)
  final int totalRatings; // عدد التقييمات
  final int totalLikes; // عدد اللايكات

  // Analytics
  final int viewsCount; // عدد مشاهدات صفحة العيادة
  final DateTime? lastFeaturedDate; // تاريخ آخر ظهور في الإعلانات

  ClinicModel({
    required this.id,
    required this.doctorName,
    required this.department,
    required this.specialization,
    required this.about,
    required this.consultationFee,
    this.phones = const [],
    this.whatsapp,
    required this.address,
    this.latitude,
    this.longitude,
    this.governorate = 'المنيا',
    this.center = 'ملوي',
    this.authEmails = const [],
    this.doctorEmails = const [],
    this.secretaryEmails = const [],
    this.doctorPhone,
    required this.workingHours,
    required this.holidays,
    this.hasNursery = false,
    this.onlineBookingEnabled = false,
    this.bookingLockDate,
    this.doctorImageUrl,
    this.isActive = true,
    this.status = 'pending', // Default: waiting for approval
    required this.createdAt,
    this.ownerId,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalLikes = 0,
    this.viewsCount = 0,
    this.lastFeaturedDate,
  });

  factory ClinicModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Debug: Print raw data from Firestore
    print('🔍 ClinicModel.fromFirestore - Doc ID: ${doc.id}');
    print('   Raw hasNursery: ${data['hasNursery']}');
    print('   Raw onlineBookingEnabled: ${data['onlineBookingEnabled']}');
    print('   Raw doctorEmails: ${data['doctorEmails']}');
    print('   Raw secretaryEmails: ${data['secretaryEmails']}');
    print('   Raw authEmails: ${data['authEmails']}');

    // Parse working hours
    Map<String, WorkingHours> parsedWorkingHours = {};
    if (data['workingHours'] != null) {
      final hoursData = data['workingHours'] as Map<String, dynamic>;
      hoursData.forEach((day, hours) {
        if (hours != null) {
          parsedWorkingHours[day] = WorkingHours.fromMap(
            hours as Map<String, dynamic>,
          );
        }
      });
    }

    return ClinicModel(
      id: doc.id,
      doctorName: data['doctorName'] ?? '',
      department: ClinicDepartment.fromString(data['department'] ?? 'other'),
      specialization: _parseSpecialization(data['specialization']),
      about: data['about'] ?? '',
      consultationFee: (data['consultationFee'] ?? 0).toDouble(),
      phones: data['phones'] != null
          ? List<String>.from(data['phones'])
          : (data['phone'] != null
                ? [data['phone']]
                : []), // للتوافق مع البيانات القديمة
      whatsapp: data['whatsapp'],
      address: data['address'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      governorate: data['governorate'] ?? 'المنيا',
      center: data['center'] ?? 'ملوي',
      authEmails: data['authEmails'] != null
          ? List<String>.from(data['authEmails'])
          : (data['doctorEmail'] != null
                ? [data['doctorEmail']]
                : []), // للتوافق مع البيانات القديمة
      doctorEmails: data['doctorEmails'] != null
          ? List<String>.from(data['doctorEmails'])
          : (data['doctorEmail'] != null
                ? [data['doctorEmail']]
                : []), // للتوافق مع doctorEmail القديم
      secretaryEmails: data['secretaryEmails'] != null
          ? List<String>.from(data['secretaryEmails'])
          : [],
      doctorPhone: data['doctorPhone'],
      workingHours: parsedWorkingHours,
      holidays: List<String>.from(data['holidays'] ?? []),
      hasNursery: data['hasNursery'] ?? false,
      onlineBookingEnabled: data['onlineBookingEnabled'] ?? false,
      bookingLockDate: (data['bookingLockDate'] as Timestamp?)?.toDate(),
      doctorImageUrl: data['doctorImageUrl'],
      isActive: data['isActive'] ?? true,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerId: data['ownerId'],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
      viewsCount: (data['viewsCount'] as num? ?? 0).toInt(),
      lastFeaturedDate: data['lastFeaturedDate'] is Timestamp
          ? (data['lastFeaturedDate'] as Timestamp).toDate()
          : null,
    );
  }

  // Helper to handle old String and new List<String> formats
  static List<String> _parseSpecialization(dynamic spec) {
    if (spec == null) return [];
    if (spec is List) {
      return List<String>.from(spec);
    }
    if (spec is String) {
      if (spec.trim().isEmpty) return [];
      // تحويل النص القديم إلى قائمة (فصل بالفواصل أو النقاط)
      return spec
          .split(RegExp(r'[,،]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> workingHoursMap = {};
    workingHours.forEach((day, hours) {
      workingHoursMap[day] = hours.toMap();
    });

    return {
      'doctorName': doctorName,
      'department': department.englishName,
      'specialization': specialization,
      'about': about,
      'consultationFee': consultationFee,
      'phones': phones,
      'whatsapp': whatsapp,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'governorate': governorate,
      'center': center,
      'authEmails': authEmails,
      'doctorEmails': doctorEmails,
      'secretaryEmails': secretaryEmails,
      'doctorPhone': doctorPhone,
      'workingHours': workingHoursMap,
      'holidays': holidays,
      'hasNursery': hasNursery,
      'onlineBookingEnabled': onlineBookingEnabled,
      'bookingLockDate':
          bookingLockDate != null ? Timestamp.fromDate(bookingLockDate!) : null,
      'doctorImageUrl': doctorImageUrl,
      'isActive': isActive,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalLikes': totalLikes,
      'viewsCount': viewsCount,
      'lastFeaturedDate': lastFeaturedDate != null
          ? Timestamp.fromDate(lastFeaturedDate!)
          : null,
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

class WorkingHours {
  final List<TimeSlot> slots;
  final bool isClosed;

  WorkingHours({
    List<TimeSlot>? slots,
    this.isClosed = false,
  }) : slots = slots ?? [TimeSlot(from: '09:00', to: '17:00')];

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    List<TimeSlot> parsedSlots = [];
    if (map['slots'] != null && map['slots'] is List) {
      for (var slotMap in map['slots']) {
        parsedSlots.add(TimeSlot.fromMap(slotMap as Map<String, dynamic>));
      }
    } else if (map['from'] != null && map['to'] != null) {
      parsedSlots.add(TimeSlot(
        from: map['from'],
        to: map['to'],
      ));
    } else {
      parsedSlots.add(TimeSlot(from: '09:00', to: '17:00'));
    }

    return WorkingHours(
      slots: parsedSlots,
      isClosed: map['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slots': slots.map((s) => s.toMap()).toList(),
      'isClosed': isClosed,
      'from': slots.isNotEmpty ? slots.first.from : '09:00',
      'to': slots.isNotEmpty ? slots.first.to : '17:00',
    };
  }
}
