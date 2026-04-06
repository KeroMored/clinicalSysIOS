import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';

/// نموذج الإحالة (Referral)
class ReferralModel extends Equatable {
  final String id;
  final String userId; // المُحيل
  final String userName;
  final String referralCode; // كود الإحالة الفريد
  final int totalReferrals; // عدد الإحالات الناجحة
  final int pointsEarned; // النقاط المكتسبة من الإحالات
  final double discountEarned; // الخصم المكتسب
  final DateTime createdAt;
  final bool isActive;

  const ReferralModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.referralCode,
    this.totalReferrals = 0,
    this.pointsEarned = 0,
    this.discountEarned = 0,
    required this.createdAt,
    this.isActive = true,
  });

  /// توليد كود إحالة عشوائي
  static String generateReferralCode(String userId) {
    final random = Random();
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // بدون أحرف ملتبسة
    final prefix = userId.substring(0, min(3, userId.length)).toUpperCase();
    final suffix = List.generate(
      4,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return '$prefix$suffix';
  }

  factory ReferralModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReferralModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      referralCode: data['referralCode'] ?? '',
      totalReferrals: data['totalReferrals'] ?? 0,
      pointsEarned: data['pointsEarned'] ?? 0,
      discountEarned: (data['discountEarned'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'referralCode': referralCode,
      'totalReferrals': totalReferrals,
      'pointsEarned': pointsEarned,
      'discountEarned': discountEarned,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  ReferralModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? referralCode,
    int? totalReferrals,
    int? pointsEarned,
    double? discountEarned,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      referralCode: referralCode ?? this.referralCode,
      totalReferrals: totalReferrals ?? this.totalReferrals,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      discountEarned: discountEarned ?? this.discountEarned,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    referralCode,
    totalReferrals,
    pointsEarned,
    discountEarned,
    createdAt,
    isActive,
  ];
}

/// نموذج عملية الإحالة
class ReferralTransactionModel extends Equatable {
  final String id;
  final String referrerId; // المُحيل
  final String referrerName;
  final String referredUserId; // المُحال
  final String referredUserName;
  final String referralCode;
  final String laboratoryId; // معرف المعمل
  final int pointsAwarded; // النقاط الممنوحة للمُحيل
  final int pointsAwardedToReferred; // النقاط الممنوحة للمُحال
  final String? firstBookingId; // أول حجز للمُحال
  final DateTime referredAt; // تاريخ التسجيل
  final DateTime? firstBookingAt; // تاريخ أول حجز
  final String status; // pending, completed, expired

  const ReferralTransactionModel({
    required this.id,
    required this.referrerId,
    required this.referrerName,
    required this.referredUserId,
    required this.referredUserName,
    required this.referralCode,
    required this.laboratoryId,
    this.pointsAwarded = 0,
    this.pointsAwardedToReferred = 0,
    this.firstBookingId,
    required this.referredAt,
    this.firstBookingAt,
    this.status = 'pending',
  });

  static const String statusPending = 'pending';
  static const String statusCompleted = 'completed';
  static const String statusExpired = 'expired';

  /// مكافآت الإحالة
  static const int referrerRewardPoints = 100; // 100 نقطة للمُحيل
  static const int referredRewardPoints = 50; // 50 نقطة للمُحال
  static const double referrerDiscountPercent = 10; // 10% خصم للمُحيل
  static const double referredDiscountPercent = 5; // 5% خصم للمُحال

  factory ReferralTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReferralTransactionModel(
      id: doc.id,
      referrerId: data['referrerId'] ?? '',
      referrerName: data['referrerName'] ?? '',
      referredUserId: data['referredUserId'] ?? '',
      referredUserName: data['referredUserName'] ?? '',
      referralCode: data['referralCode'] ?? '',
      laboratoryId: data['laboratoryId'] ?? '',
      pointsAwarded: data['pointsAwarded'] ?? 0,
      pointsAwardedToReferred: data['pointsAwardedToReferred'] ?? 0,
      firstBookingId: data['firstBookingId'],
      referredAt: (data['referredAt'] as Timestamp).toDate(),
      firstBookingAt: data['firstBookingAt'] != null
          ? (data['firstBookingAt'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? statusPending,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'referrerId': referrerId,
      'referrerName': referrerName,
      'referredUserId': referredUserId,
      'referredUserName': referredUserName,
      'referralCode': referralCode,
      'laboratoryId': laboratoryId,
      'pointsAwarded': pointsAwarded,
      'pointsAwardedToReferred': pointsAwardedToReferred,
      'firstBookingId': firstBookingId,
      'referredAt': Timestamp.fromDate(referredAt),
      'firstBookingAt': firstBookingAt != null
          ? Timestamp.fromDate(firstBookingAt!)
          : null,
      'status': status,
    };
  }

  ReferralTransactionModel copyWith({
    String? id,
    String? referrerId,
    String? referrerName,
    String? referredUserId,
    String? referredUserName,
    String? referralCode,
    String? laboratoryId,
    int? pointsAwarded,
    int? pointsAwardedToReferred,
    String? firstBookingId,
    DateTime? referredAt,
    DateTime? firstBookingAt,
    String? status,
  }) {
    return ReferralTransactionModel(
      id: id ?? this.id,
      referrerId: referrerId ?? this.referrerId,
      referrerName: referrerName ?? this.referrerName,
      referredUserId: referredUserId ?? this.referredUserId,
      referredUserName: referredUserName ?? this.referredUserName,
      referralCode: referralCode ?? this.referralCode,
      laboratoryId: laboratoryId ?? this.laboratoryId,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      pointsAwardedToReferred:
          pointsAwardedToReferred ?? this.pointsAwardedToReferred,
      firstBookingId: firstBookingId ?? this.firstBookingId,
      referredAt: referredAt ?? this.referredAt,
      firstBookingAt: firstBookingAt ?? this.firstBookingAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    referrerId,
    referrerName,
    referredUserId,
    referredUserName,
    referralCode,
    laboratoryId,
    pointsAwarded,
    pointsAwardedToReferred,
    firstBookingId,
    referredAt,
    firstBookingAt,
    status,
  ];
}

/// إحصائيات برنامج الإحالة
class ReferralStatistics extends Equatable {
  final int totalReferrals;
  final int completedReferrals;
  final int pendingReferrals;
  final int totalPointsEarned;
  final double totalDiscountEarned;
  final List<String> topReferrers; // أفضل 5 مُحيلين

  const ReferralStatistics({
    required this.totalReferrals,
    required this.completedReferrals,
    required this.pendingReferrals,
    required this.totalPointsEarned,
    required this.totalDiscountEarned,
    required this.topReferrers,
  });

  double get completionRate =>
      totalReferrals > 0 ? (completedReferrals / totalReferrals) * 100 : 0;

  @override
  List<Object?> get props => [
    totalReferrals,
    completedReferrals,
    pendingReferrals,
    totalPointsEarned,
    totalDiscountEarned,
    topReferrers,
  ];
}
