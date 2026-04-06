import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// نموذج موعد تحليل معملي
class AppointmentModel extends Equatable {
  final String id;
  final String laboratoryId;
  final String laboratoryName;
  final String userId;
  final String userName;
  final String userPhone;
  final String testId;
  final String testName;
  final DateTime appointmentDateTime;
  final String status; // pending, confirmed, completed, cancelled
  final double price;
  final String? notes;
  final bool isHomeVisit; // زيارة منزلية
  final String? homeAddress;
  final double? homeLatitude;
  final double? homeLongitude;
  final double? homeVisitFee;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime? reminderSentAt; // آخر مرة تم إرسال تذكير
  final List<String> remindersSent; // ['24h', '1h'] - التذكيرات المرسلة

  const AppointmentModel({
    required this.id,
    required this.laboratoryId,
    required this.laboratoryName,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.testId,
    required this.testName,
    required this.appointmentDateTime,
    required this.status,
    required this.price,
    this.notes,
    this.isHomeVisit = false,
    this.homeAddress,
    this.homeLatitude,
    this.homeLongitude,
    this.homeVisitFee,
    this.cancellationReason,
    this.cancelledAt,
    required this.createdAt,
    this.reminderSentAt,
    this.remindersSent = const [],
  });

  /// حالات الموعد
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  /// أنواع التذكيرات
  static const String reminder24Hours = '24h';
  static const String reminder1Hour = '1h';

  /// التحويل من Firestore
  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      laboratoryId: data['laboratoryId'] ?? '',
      laboratoryName: data['laboratoryName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      testId: data['testId'] ?? '',
      testName: data['testName'] ?? '',
      appointmentDateTime: (data['appointmentDateTime'] as Timestamp).toDate(),
      status: data['status'] ?? statusPending,
      price: (data['price'] ?? 0).toDouble(),
      notes: data['notes'],
      isHomeVisit: data['isHomeVisit'] ?? false,
      homeAddress: data['homeAddress'],
      homeLatitude: data['homeLatitude']?.toDouble(),
      homeLongitude: data['homeLongitude']?.toDouble(),
      homeVisitFee: data['homeVisitFee']?.toDouble(),
      cancellationReason: data['cancellationReason'],
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reminderSentAt: data['reminderSentAt'] != null
          ? (data['reminderSentAt'] as Timestamp).toDate()
          : null,
      remindersSent: data['remindersSent'] != null
          ? List<String>.from(data['remindersSent'])
          : [],
    );
  }

  /// التحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'laboratoryId': laboratoryId,
      'laboratoryName': laboratoryName,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'testId': testId,
      'testName': testName,
      'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      'status': status,
      'price': price,
      'notes': notes,
      'isHomeVisit': isHomeVisit,
      'homeAddress': homeAddress,
      'homeLatitude': homeLatitude,
      'homeLongitude': homeLongitude,
      'homeVisitFee': homeVisitFee,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'reminderSentAt': reminderSentAt != null
          ? Timestamp.fromDate(reminderSentAt!)
          : null,
      'remindersSent': remindersSent,
    };
  }

  /// نسخ مع تعديلات
  AppointmentModel copyWith({
    String? id,
    String? laboratoryId,
    String? laboratoryName,
    String? userId,
    String? userName,
    String? userPhone,
    String? testId,
    String? testName,
    DateTime? appointmentDateTime,
    String? status,
    double? price,
    String? notes,
    bool? isHomeVisit,
    String? homeAddress,
    double? homeLatitude,
    double? homeLongitude,
    double? homeVisitFee,
    String? cancellationReason,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? reminderSentAt,
    List<String>? remindersSent,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      laboratoryId: laboratoryId ?? this.laboratoryId,
      laboratoryName: laboratoryName ?? this.laboratoryName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      testId: testId ?? this.testId,
      testName: testName ?? this.testName,
      appointmentDateTime: appointmentDateTime ?? this.appointmentDateTime,
      status: status ?? this.status,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      isHomeVisit: isHomeVisit ?? this.isHomeVisit,
      homeAddress: homeAddress ?? this.homeAddress,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      homeVisitFee: homeVisitFee ?? this.homeVisitFee,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      remindersSent: remindersSent ?? this.remindersSent,
    );
  }

  /// الحصول على السعر الإجمالي (سعر التحليل + رسوم الزيارة المنزلية)
  double get totalPrice {
    return price + (homeVisitFee ?? 0);
  }

  /// هل الموعد في الماضي؟
  bool get isPast {
    return appointmentDateTime.isBefore(DateTime.now());
  }

  /// هل الموعد اليوم؟
  bool get isToday {
    final now = DateTime.now();
    return appointmentDateTime.year == now.year &&
        appointmentDateTime.month == now.month &&
        appointmentDateTime.day == now.day;
  }

  /// هل الموعد قابل للإلغاء؟ (يجب أن يكون pending أو confirmed وليس في الماضي)
  bool get isCancellable {
    return (status == statusPending || status == statusConfirmed) && !isPast;
  }

  /// الحصول على لون الحالة
  String get statusColor {
    switch (status) {
      case statusPending:
        return '#FFA500'; // Orange
      case statusConfirmed:
        return '#4CAF50'; // Green
      case statusCompleted:
        return '#2196F3'; // Blue
      case statusCancelled:
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Gray
    }
  }

  /// الحصول على نص الحالة بالعربية
  String get statusText {
    switch (status) {
      case statusPending:
        return 'في انتظار التأكيد';
      case statusConfirmed:
        return 'مؤكد';
      case statusCompleted:
        return 'مكتمل';
      case statusCancelled:
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }

  /// هل تم إرسال تذكير معين؟
  bool hasReminderSent(String reminderType) {
    return remindersSent.contains(reminderType);
  }

  /// الوقت المتبقي للموعد بالدقائق
  int get minutesUntilAppointment {
    return appointmentDateTime.difference(DateTime.now()).inMinutes;
  }

  /// هل يحتاج الموعد لإرسال تذكير 24 ساعة؟
  bool get needsReminder24Hours {
    final hoursUntil = appointmentDateTime.difference(DateTime.now()).inHours;
    return hoursUntil <= 24 &&
        hoursUntil > 1 &&
        !hasReminderSent(reminder24Hours) &&
        (status == statusPending || status == statusConfirmed);
  }

  /// هل يحتاج الموعد لإرسال تذكير ساعة واحدة؟
  bool get needsReminder1Hour {
    final minutesUntil = minutesUntilAppointment;
    return minutesUntil <= 60 &&
        minutesUntil > 0 &&
        !hasReminderSent(reminder1Hour) &&
        (status == statusPending || status == statusConfirmed);
  }

  @override
  List<Object?> get props => [
    id,
    laboratoryId,
    laboratoryName,
    userId,
    userName,
    userPhone,
    testId,
    testName,
    appointmentDateTime,
    status,
    price,
    notes,
    isHomeVisit,
    homeAddress,
    homeLatitude,
    homeLongitude,
    homeVisitFee,
    cancellationReason,
    cancelledAt,
    createdAt,
    reminderSentAt,
    remindersSent,
  ];
}

/// نموذج فترة زمنية متاحة
class TimeSlot extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final int bookedCount; // عدد المواعيد المحجوزة في هذه الفترة

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.bookedCount = 0,
  });

  /// الحصول على النص الزمني (مثل: "09:00 - 09:30")
  String get timeText {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  @override
  List<Object?> get props => [startTime, endTime, isAvailable, bookedCount];
}
