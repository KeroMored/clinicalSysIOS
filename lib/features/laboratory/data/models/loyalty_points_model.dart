import 'package:cloud_firestore/cloud_firestore.dart';

/// نظام نقاط الولاء للعملاء المتكررين
class LoyaltyPointsModel {
  final String id;
  final String userId; // معرف المستخدم
  final String userName; // اسم المستخدم
  final String userPhone; // رقم المستخدم
  final String? userEmail;

  // النقاط
  final int totalPoints; // إجمالي النقاط المكتسبة
  final int usedPoints; // النقاط المستخدمة
  final int availablePoints; // النقاط المتاحة

  // الإحصائيات
  final int totalBookings; // عدد الحجوزات الإجمالي
  final double totalSpent; // إجمالي المبلغ المنفق
  final int lastYearBookings; // حجوزات آخر سنة
  final double lastYearSpent; // المنفق في آخر سنة

  // المستوى
  final String tier; // 'bronze', 'silver', 'gold', 'platinum'
  final DateTime? tierUpdatedAt;

  // آخر تحديث
  final DateTime? lastBookingDate; // آخر حجز
  final DateTime? lastPointsEarnedDate; // آخر اكتساب نقاط
  final DateTime? lastPointsUsedDate; // آخر استخدام نقاط

  final DateTime createdAt;
  final DateTime? updatedAt;

  LoyaltyPointsModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userEmail,
    this.totalPoints = 0,
    this.usedPoints = 0,
    this.availablePoints = 0,
    this.totalBookings = 0,
    this.totalSpent = 0.0,
    this.lastYearBookings = 0,
    this.lastYearSpent = 0.0,
    this.tier = 'bronze',
    this.tierUpdatedAt,
    this.lastBookingDate,
    this.lastPointsEarnedDate,
    this.lastPointsUsedDate,
    required this.createdAt,
    this.updatedAt,
  });

  // النسبة المئوية للوصول للمستوى التالي
  double get progressToNextTier {
    switch (tier) {
      case 'bronze':
        return (availablePoints / 1000).clamp(0.0, 1.0); // 1000 نقطة للفضي
      case 'silver':
        return (availablePoints / 2500).clamp(0.0, 1.0); // 2500 للذهبي
      case 'gold':
        return (availablePoints / 5000).clamp(0.0, 1.0); // 5000 للبلاتيني
      case 'platinum':
        return 1.0; // أعلى مستوى
      default:
        return 0.0;
    }
  }

  // اسم المستوى بالعربي
  String get tierNameAr {
    switch (tier) {
      case 'bronze':
        return 'برونزي';
      case 'silver':
        return 'فضي';
      case 'gold':
        return 'ذهبي';
      case 'platinum':
        return 'بلاتيني';
      default:
        return tier;
    }
  }

  // نسبة الخصم حسب المستوى
  int get discountPercentage {
    switch (tier) {
      case 'bronze':
        return 5; // 5% خصم
      case 'silver':
        return 10; // 10% خصم
      case 'gold':
        return 15; // 15% خصم
      case 'platinum':
        return 20; // 20% خصم
      default:
        return 0;
    }
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'totalPoints': totalPoints,
      'usedPoints': usedPoints,
      'availablePoints': availablePoints,
      'totalBookings': totalBookings,
      'totalSpent': totalSpent,
      'lastYearBookings': lastYearBookings,
      'lastYearSpent': lastYearSpent,
      'tier': tier,
      'tierUpdatedAt': tierUpdatedAt != null
          ? Timestamp.fromDate(tierUpdatedAt!)
          : null,
      'lastBookingDate': lastBookingDate != null
          ? Timestamp.fromDate(lastBookingDate!)
          : null,
      'lastPointsEarnedDate': lastPointsEarnedDate != null
          ? Timestamp.fromDate(lastPointsEarnedDate!)
          : null,
      'lastPointsUsedDate': lastPointsUsedDate != null
          ? Timestamp.fromDate(lastPointsUsedDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore
  factory LoyaltyPointsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LoyaltyPointsModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userEmail: data['userEmail'],
      totalPoints: data['totalPoints'] ?? 0,
      usedPoints: data['usedPoints'] ?? 0,
      availablePoints: data['availablePoints'] ?? 0,
      totalBookings: data['totalBookings'] ?? 0,
      totalSpent: (data['totalSpent'] ?? 0.0).toDouble(),
      lastYearBookings: data['lastYearBookings'] ?? 0,
      lastYearSpent: (data['lastYearSpent'] ?? 0.0).toDouble(),
      tier: data['tier'] ?? 'bronze',
      tierUpdatedAt: (data['tierUpdatedAt'] as Timestamp?)?.toDate(),
      lastBookingDate: (data['lastBookingDate'] as Timestamp?)?.toDate(),
      lastPointsEarnedDate: (data['lastPointsEarnedDate'] as Timestamp?)
          ?.toDate(),
      lastPointsUsedDate: (data['lastPointsUsedDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  LoyaltyPointsModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    int? totalPoints,
    int? usedPoints,
    int? availablePoints,
    int? totalBookings,
    double? totalSpent,
    int? lastYearBookings,
    double? lastYearSpent,
    String? tier,
    DateTime? tierUpdatedAt,
    DateTime? lastBookingDate,
    DateTime? lastPointsEarnedDate,
    DateTime? lastPointsUsedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoyaltyPointsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      totalPoints: totalPoints ?? this.totalPoints,
      usedPoints: usedPoints ?? this.usedPoints,
      availablePoints: availablePoints ?? this.availablePoints,
      totalBookings: totalBookings ?? this.totalBookings,
      totalSpent: totalSpent ?? this.totalSpent,
      lastYearBookings: lastYearBookings ?? this.lastYearBookings,
      lastYearSpent: lastYearSpent ?? this.lastYearSpent,
      tier: tier ?? this.tier,
      tierUpdatedAt: tierUpdatedAt ?? this.tierUpdatedAt,
      lastBookingDate: lastBookingDate ?? this.lastBookingDate,
      lastPointsEarnedDate: lastPointsEarnedDate ?? this.lastPointsEarnedDate,
      lastPointsUsedDate: lastPointsUsedDate ?? this.lastPointsUsedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// سجل معاملة النقاط (للتتبع)
class PointsTransactionModel {
  final String id;
  final String userId;
  final String laboratoryId;
  final String? bookingId; // إذا كانت مرتبطة بحجز

  // تفاصيل المعاملة
  final String type; // 'earn' أو 'redeem' أو 'expire' أو 'bonus'
  final int points; // عدد النقاط (موجب للاكتساب، سالب للاستخدام)
  final String description; // وصف المعاملة

  // قبل وبعد
  final int pointsBefore; // النقاط قبل المعاملة
  final int pointsAfter; // النقاط بعد المعاملة

  // تفاصيل إضافية
  final double? relatedAmount; // المبلغ المرتبط (للحجز مثلاً)
  final String? referenceId; // معرف مرجعي

  final DateTime createdAt;

  PointsTransactionModel({
    required this.id,
    required this.userId,
    required this.laboratoryId,
    this.bookingId,
    required this.type,
    required this.points,
    required this.description,
    required this.pointsBefore,
    required this.pointsAfter,
    this.relatedAmount,
    this.referenceId,
    required this.createdAt,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'laboratoryId': laboratoryId,
      'bookingId': bookingId,
      'type': type,
      'points': points,
      'description': description,
      'pointsBefore': pointsBefore,
      'pointsAfter': pointsAfter,
      'relatedAmount': relatedAmount,
      'referenceId': referenceId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore
  factory PointsTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PointsTransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      laboratoryId: data['laboratoryId'] ?? '',
      bookingId: data['bookingId'],
      type: data['type'] ?? 'earn',
      points: data['points'] ?? 0,
      description: data['description'] ?? '',
      pointsBefore: data['pointsBefore'] ?? 0,
      pointsAfter: data['pointsAfter'] ?? 0,
      relatedAmount: data['relatedAmount']?.toDouble(),
      referenceId: data['referenceId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// حساب النقاط من المبلغ
class PointsCalculator {
  // كل 10 جنيه = 1 نقطة
  static const double pointsPerAmount = 0.1;

  // حساب النقاط المكتسبة من مبلغ
  static int calculateEarnedPoints(double amount) {
    return (amount * pointsPerAmount).floor();
  }

  // حساب قيمة النقاط بالجنيه
  static double calculatePointsValue(int points) {
    return points / pointsPerAmount;
  }

  // تحديد المستوى من النقاط المتاحة
  static String determineTier(int availablePoints) {
    if (availablePoints >= 5000) return 'platinum';
    if (availablePoints >= 2500) return 'gold';
    if (availablePoints >= 1000) return 'silver';
    return 'bronze';
  }

  // نسبة الخصم حسب المستوى
  static int getTierDiscount(String tier) {
    switch (tier) {
      case 'platinum':
        return 20;
      case 'gold':
        return 15;
      case 'silver':
        return 10;
      case 'bronze':
        return 5;
      default:
        return 0;
    }
  }
}
