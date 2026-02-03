import 'package:cloud_firestore/cloud_firestore.dart';
import 'clinic_department.dart';

class ClinicModel {
  final String id;
  final String doctorName;
  final ClinicDepartment department;
  final String specialization; // تخصص دقيق (مثلاً: جراحة قلب، أطفال حديثي الولادة)
  final String about; // نبذة عن الدكتور
  final double consultationFee; // سعر الكشف
  final List<String> phones; // أرقام هاتف العيادة (يمكن أن تكون متعددة)
  final String? whatsapp; // رقم واتساب العيادة
  final String address;
  final double? latitude;
  final double? longitude;
  
  // Doctor Account Info
  final List<String> authEmails; // إيميلات المصادقة للدخول (يمكن أن تكون أكثر من إيميل)
  final List<String> doctorEmails; // إيميلات الدكاترة (صلاحيات كاملة)
  final List<String> secretaryEmails; // إيميلات السكرتيرة (صلاحيات محدودة)
  final String? doctorPhone; // رقم تليفون الدكتور الشخصي
  
  // Working Hours
  final Map<String, WorkingHours> workingHours; // Key: day name (saturday, sunday, etc.)
  final List<String> holidays; // أيام العطلات الرسمية
  
  // Additional Info
  final bool hasNursery; // يوجد حضانة (لعيادات الأطفال فقط)
  final bool onlineBookingEnabled; // متاح الحجز أونلاين
  final String? clinicImageUrl;
  final String? doctorImageUrl;
  final bool isActive;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final String? ownerId; // إذا كان الدكتور يملك حساب
  
  // Rating and Engagement
  final double averageRating; // متوسط التقييم (0.0 - 5.0)
  final int totalRatings; // عدد التقييمات
  final int totalLikes; // عدد اللايكات

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
    this.authEmails = const [],
    this.doctorEmails = const [],
    this.secretaryEmails = const [],
    this.doctorPhone,
    required this.workingHours,
    required this.holidays,
    this.hasNursery = false,
    this.onlineBookingEnabled = false,
    this.clinicImageUrl,
    this.doctorImageUrl,
    this.isActive = true,
    this.status = 'pending', // Default: waiting for approval
    required this.createdAt,
    this.ownerId,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalLikes = 0,
  });

  factory ClinicModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse working hours
    Map<String, WorkingHours> parsedWorkingHours = {};
    if (data['workingHours'] != null) {
      final hoursData = data['workingHours'] as Map<String, dynamic>;
      hoursData.forEach((day, hours) {
        if (hours != null) {
          parsedWorkingHours[day] = WorkingHours.fromMap(hours as Map<String, dynamic>);
        }
      });
    }

    return ClinicModel(
      id: doc.id,
      doctorName: data['doctorName'] ?? '',
      department: ClinicDepartment.fromString(data['department'] ?? 'other'),
      specialization: data['specialization'] ?? '',
      about: data['about'] ?? '',
      consultationFee: (data['consultationFee'] ?? 0).toDouble(),
      phones: data['phones'] != null
          ? List<String>.from(data['phones'])
          : (data['phone'] != null ? [data['phone']] : []), // للتوافق مع البيانات القديمة
      whatsapp: data['whatsapp'],
      address: data['address'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      authEmails: data['authEmails'] != null 
          ? List<String>.from(data['authEmails'])
          : (data['doctorEmail'] != null ? [data['doctorEmail']] : []), // للتوافق مع البيانات القديمة
      doctorEmails: data['doctorEmails'] != null
          ? List<String>.from(data['doctorEmails'])
          : (data['doctorEmail'] != null ? [data['doctorEmail']] : []), // للتوافق مع doctorEmail القديم
      secretaryEmails: data['secretaryEmails'] != null
          ? List<String>.from(data['secretaryEmails'])
          : [],
      doctorPhone: data['doctorPhone'],
      workingHours: parsedWorkingHours,
      holidays: List<String>.from(data['holidays'] ?? []),
      hasNursery: data['hasNursery'] ?? false,
      onlineBookingEnabled: data['onlineBookingEnabled'] ?? false,
      clinicImageUrl: data['clinicImageUrl'],
      doctorImageUrl: data['doctorImageUrl'],
      isActive: data['isActive'] ?? true,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerId: data['ownerId'],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
    );
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
      'authEmails': authEmails,
      'doctorEmails': doctorEmails,
      'secretaryEmails': secretaryEmails,
      'doctorPhone': doctorPhone,
      'workingHours': workingHoursMap,
      'holidays': holidays,
      'hasNursery': hasNursery,
      'onlineBookingEnabled': onlineBookingEnabled,
      'clinicImageUrl': clinicImageUrl,
      'doctorImageUrl': doctorImageUrl,
      'isActive': isActive,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalLikes': totalLikes,
    };
  }
}

class WorkingHours {
  final String from; // "09:00"
  final String to;   // "17:00"
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
