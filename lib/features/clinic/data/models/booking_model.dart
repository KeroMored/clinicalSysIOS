import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending, // في انتظار التأكيد
  confirmed, // مؤكد
  cancelled, // ملغي
  completed, // تم
  noShow, // لم يحضر
}

enum VisitType {
  examination, // كشف
  followUp, // إعادة
}

class BookingModel {
  final String? id;
  final String patientName;
  final String patientPhone;
  final String clinicId;
  final String doctorName;
  final String? clinicType; // "doctor" أو "center" أو null
  final int bookingNumber; // رقم الحجز (يتم توليده تلقائياً)
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? notes; // ملاحظات إضافية
  final String? userId; // معرف المستخدم إذا كان مسجلاً
  final DateTime? archivedDate; // تاريخ أرشفة الحجز (عند إنهاء اليوم)
  final bool?
  isOnlineBooking; // حجز أونلاين من المريض (true) أو حجز يدوي من العيادة (false)
  final DateTime appointmentDate; // تاريخ ووقت الموعد المحدد للكشف
  final VisitType visitType; // نوع الزيارة: كشف أو إعادة

  BookingModel({
    this.id,
    required this.patientName,
    required this.patientPhone,
    required this.clinicId,
    required this.doctorName,
    this.clinicType, // Optional
    required this.bookingNumber,
    this.status = BookingStatus.pending,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    this.notes,
    this.userId,
    this.archivedDate,
    this.isOnlineBooking,
    required this.appointmentDate,
    this.visitType = VisitType.examination, // الافتراضي: كشف
  });

  /// الحصول على اسم الدكتور/المركز كما هو بدون إضافة بادئة
  String get displayName {
    return doctorName;
  }

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BookingModel(
      id: doc.id,
      patientName: data['patientName'] ?? '',
      patientPhone: data['patientPhone'] ?? '',
      clinicId: data['clinicId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      clinicType: data['clinicType'], // قراءة النوع من Firestore
      bookingNumber: data['bookingNumber'] ?? 0,
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      userId: data['userId'],
      archivedDate: (data['archivedDate'] as Timestamp?)?.toDate(),
      isOnlineBooking: data['isOnlineBooking'] as bool?,
      appointmentDate:
          (data['appointmentDate'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      visitType: _parseVisitType(data['visitType']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientName': patientName,
      'patientPhone': patientPhone,
      'clinicId': clinicId,
      'doctorName': doctorName,
      'clinicType': clinicType, // حفظ النوع في Firestore
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
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'visitType': _visitTypeToString(visitType),
    };
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'noShow':
        return BookingStatus.noShow;
      default:
        return BookingStatus.pending;
    }
  }

  static String _statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.noShow:
        return 'noShow';
    }
  }

  static VisitType _parseVisitType(String? type) {
    switch (type) {
      case 'followUp':
        return VisitType.followUp;
      case 'examination':
      default:
        return VisitType.examination;
    }
  }

  static String _visitTypeToString(VisitType type) {
    switch (type) {
      case VisitType.examination:
        return 'examination';
      case VisitType.followUp:
        return 'followUp';
    }
  }

  String get statusArabic {
    switch (status) {
      case BookingStatus.pending:
        return 'في الانتظار';
      case BookingStatus.confirmed:
        return 'مؤكد';
      case BookingStatus.cancelled:
        return 'تم الإلغاء';
      case BookingStatus.completed:
        return 'تم الكشف';
      case BookingStatus.noShow:
        return 'لم يحضر';
    }
  }

  String get visitTypeArabic {
    switch (visitType) {
      case VisitType.examination:
        return 'كشف';
      case VisitType.followUp:
        return 'إعادة';
    }
  }

  BookingModel copyWith({
    String? id,
    String? patientName,
    String? patientPhone,
    String? clinicId,
    String? doctorName,
    String? clinicType,
    int? bookingNumber,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? notes,
    String? userId,
    DateTime? archivedDate,
    bool? isOnlineBooking,
    DateTime? appointmentDate,
    VisitType? visitType,
  }) {
    return BookingModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      clinicId: clinicId ?? this.clinicId,
      doctorName: doctorName ?? this.doctorName,
      clinicType: clinicType ?? this.clinicType,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      archivedDate: archivedDate ?? this.archivedDate,
      isOnlineBooking: isOnlineBooking ?? this.isOnlineBooking,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      visitType: visitType ?? this.visitType,
    );
  }
}
