import 'package:cloud_firestore/cloud_firestore.dart';

enum LabBookingStatus {
  pending, // في انتظار التأكيد
  confirmed, // مؤكد
  cancelled, // ملغي
  completed, // تم إجراء التحليل
}

class LabBookingModel {
  final String? id;
  final String patientName;
  final String patientPhone;
  final String laboratoryId;
  final String laboratoryName;
  final int bookingNumber; // رقم الحجز (يتم توليده تلقائياً)
  final LabBookingStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? notes; // ملاحظات إضافية
  final String? userId; // معرف المستخدم إذا كان مسجلاً
  final DateTime? archivedDate; // تاريخ أرشفة الحجز (عند إنهاء اليوم)
  final bool?
  isOnlineBooking; // حجز أونلاين من المريض (true) أو حجز يدوي من المعمل (false)
  final String? testType; // نوع التحليل (مثل: صورة دم كاملة، تحليل سكر، إلخ)
  final String? serviceType; // نوع الخدمة: 'lab' للمعمل، 'home' للمنزل

  LabBookingModel({
    this.id,
    required this.patientName,
    required this.patientPhone,
    required this.laboratoryId,
    required this.laboratoryName,
    required this.bookingNumber,
    this.status = LabBookingStatus.pending,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    this.notes,
    this.userId,
    this.archivedDate,
    this.isOnlineBooking,
    this.testType,
    this.serviceType,
  });

  factory LabBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LabBookingModel(
      id: doc.id,
      patientName: data['patientName'] ?? '',
      patientPhone: data['patientPhone'] ?? '',
      laboratoryId: data['laboratoryId'] ?? '',
      laboratoryName: data['laboratoryName'] ?? '',
      bookingNumber: data['bookingNumber'] ?? 0,
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      userId: data['userId'],
      archivedDate: (data['archivedDate'] as Timestamp?)?.toDate(),
      isOnlineBooking: data['isOnlineBooking'] as bool?,
      testType: data['testType'] as String?,
      serviceType: data['serviceType'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientName': patientName,
      'patientPhone': patientPhone,
      'laboratoryId': laboratoryId,
      'laboratoryName': laboratoryName,
      'bookingNumber': bookingNumber,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null
          ? Timestamp.fromDate(confirmedAt!)
          : null,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'notes': notes,
      'userId': userId,
      'archivedDate': archivedDate != null
          ? Timestamp.fromDate(archivedDate!)
          : null,
      'isOnlineBooking': isOnlineBooking,
      'testType': testType,
      'serviceType': serviceType,
    };
  }

  static LabBookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return LabBookingStatus.confirmed;
      case 'cancelled':
        return LabBookingStatus.cancelled;
      case 'completed':
        return LabBookingStatus.completed;
      default:
        return LabBookingStatus.pending;
    }
  }

  static String _statusToString(LabBookingStatus status) {
    switch (status) {
      case LabBookingStatus.pending:
        return 'pending';
      case LabBookingStatus.confirmed:
        return 'confirmed';
      case LabBookingStatus.cancelled:
        return 'cancelled';
      case LabBookingStatus.completed:
        return 'completed';
    }
  }

  String get statusArabic {
    switch (status) {
      case LabBookingStatus.pending:
        return 'في الانتظار';
      case LabBookingStatus.confirmed:
        return 'مؤكد';
      case LabBookingStatus.cancelled:
        return 'تم الإلغاء';
      case LabBookingStatus.completed:
        return 'تم إجراء التحليل';
    }
  }

  LabBookingModel copyWith({
    String? id,
    String? patientName,
    String? patientPhone,
    String? laboratoryId,
    String? laboratoryName,
    int? bookingNumber,
    LabBookingStatus? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? notes,
    String? userId,
    DateTime? archivedDate,
    bool? isOnlineBooking,
    String? testType,
    String? serviceType,
  }) {
    return LabBookingModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      laboratoryId: laboratoryId ?? this.laboratoryId,
      laboratoryName: laboratoryName ?? this.laboratoryName,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      archivedDate: archivedDate ?? this.archivedDate,
      isOnlineBooking: isOnlineBooking ?? this.isOnlineBooking,
      testType: testType ?? this.testType,
      serviceType: serviceType ?? this.serviceType,
    );
  }

  // الحصول على نوع الخدمة بالعربية
  String get serviceTypeArabic {
    if (serviceType == 'home') return 'خدمة منزلية';
    if (serviceType == 'lab') return 'في المعمل';
    return 'غير محدد';
  }
}
