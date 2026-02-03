import 'package:cloud_firestore/cloud_firestore.dart';

/// نتيجة التحليل
class LabResultModel {
  final String id;
  final String bookingId; // معرف الحجز
  final String laboratoryId; // معرف المعمل
  final String laboratoryName; // اسم المعمل
  final String userId; // معرف المريض
  final String userName; // اسم المريض
  final String userPhone; // رقم المريض
  final String? userEmail; // إيميل المريض
  
  // تفاصيل النتيجة
  final List<String> testNames; // أسماء التحاليل
  final String? resultPdfUrl; // رابط ملف PDF للنتيجة
  final String? resultImageUrl; // رابط صورة النتيجة (اختياري)
  final List<String>? additionalFiles; // ملفات إضافية
  
  // معلومات النتيجة
  final DateTime testDate; // تاريخ إجراء التحليل
  final DateTime resultDate; // تاريخ جاهزية النتيجة
  final String? doctorName; // اسم الطبيب الذي أجرى التحليل
  final String? technicianName; // اسم الفني
  
  // الإشعارات
  final bool notificationSent; // تم إرسال إشعار؟
  final DateTime? notificationSentAt; // وقت إرسال الإشعار
  final bool viewed; // المريض شاف النتيجة؟
  final DateTime? viewedAt; // وقت المشاهدة
  final int viewCount; // عدد مرات المشاهدة
  
  // ملاحظات
  final String? notes; // ملاحظات المعمل على النتيجة
  final String? recommendation; // توصيات
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  LabResultModel({
    required this.id,
    required this.bookingId,
    required this.laboratoryId,
    required this.laboratoryName,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userEmail,
    required this.testNames,
    this.resultPdfUrl,
    this.resultImageUrl,
    this.additionalFiles,
    required this.testDate,
    required this.resultDate,
    this.doctorName,
    this.technicianName,
    this.notificationSent = false,
    this.notificationSentAt,
    this.viewed = false,
    this.viewedAt,
    this.viewCount = 0,
    this.notes,
    this.recommendation,
    required this.createdAt,
    this.updatedAt,
  });

  // Getters for compatibility with result_sharing_service
  String get testName => testNames.isNotEmpty ? testNames.join(', ') : 'تحليل معملي';
  String get patientName => userName;
  DateTime get uploadedAt => resultDate;
  String? get pdfUrl => resultPdfUrl;

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'laboratoryId': laboratoryId,
      'laboratoryName': laboratoryName,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'testNames': testNames,
      'resultPdfUrl': resultPdfUrl,
      'resultImageUrl': resultImageUrl,
      'additionalFiles': additionalFiles,
      'testDate': Timestamp.fromDate(testDate),
      'resultDate': Timestamp.fromDate(resultDate),
      'doctorName': doctorName,
      'technicianName': technicianName,
      'notificationSent': notificationSent,
      'notificationSentAt': notificationSentAt != null ? Timestamp.fromDate(notificationSentAt!) : null,
      'viewed': viewed,
      'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
      'viewCount': viewCount,
      'notes': notes,
      'recommendation': recommendation,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore
  factory LabResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LabResultModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      laboratoryId: data['laboratoryId'] ?? '',
      laboratoryName: data['laboratoryName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userEmail: data['userEmail'],
      testNames: List<String>.from(data['testNames'] ?? []),
      resultPdfUrl: data['resultPdfUrl'],
      resultImageUrl: data['resultImageUrl'],
      additionalFiles: data['additionalFiles'] != null 
          ? List<String>.from(data['additionalFiles'])
          : null,
      testDate: (data['testDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resultDate: (data['resultDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      doctorName: data['doctorName'],
      technicianName: data['technicianName'],
      notificationSent: data['notificationSent'] ?? false,
      notificationSentAt: (data['notificationSentAt'] as Timestamp?)?.toDate(),
      viewed: data['viewed'] ?? false,
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate(),
      viewCount: data['viewCount'] ?? 0,
      notes: data['notes'],
      recommendation: data['recommendation'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  LabResultModel copyWith({
    String? id,
    String? bookingId,
    String? laboratoryId,
    String? laboratoryName,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    List<String>? testNames,
    String? resultPdfUrl,
    String? resultImageUrl,
    List<String>? additionalFiles,
    DateTime? testDate,
    DateTime? resultDate,
    String? doctorName,
    String? technicianName,
    bool? notificationSent,
    DateTime? notificationSentAt,
    bool? viewed,
    DateTime? viewedAt,
    int? viewCount,
    String? notes,
    String? recommendation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LabResultModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      laboratoryId: laboratoryId ?? this.laboratoryId,
      laboratoryName: laboratoryName ?? this.laboratoryName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      testNames: testNames ?? this.testNames,
      resultPdfUrl: resultPdfUrl ?? this.resultPdfUrl,
      resultImageUrl: resultImageUrl ?? this.resultImageUrl,
      additionalFiles: additionalFiles ?? this.additionalFiles,
      testDate: testDate ?? this.testDate,
      resultDate: resultDate ?? this.resultDate,
      doctorName: doctorName ?? this.doctorName,
      technicianName: technicianName ?? this.technicianName,
      notificationSent: notificationSent ?? this.notificationSent,
      notificationSentAt: notificationSentAt ?? this.notificationSentAt,
      viewed: viewed ?? this.viewed,
      viewedAt: viewedAt ?? this.viewedAt,
      viewCount: viewCount ?? this.viewCount,
      notes: notes ?? this.notes,
      recommendation: recommendation ?? this.recommendation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
