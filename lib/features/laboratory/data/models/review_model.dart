import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// نموذج تقييم المعمل
class LabReviewModel extends Equatable {
  final String id;
  final String laboratoryId;
  final String laboratoryName;
  final String userId;
  final String userName;
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;
  final String? resultId; // ربط بنتيجة التحليل
  final bool isVerified; // تقييم موثق (حجز فعلي)

  const LabReviewModel({
    required this.id,
    required this.laboratoryId,
    required this.laboratoryName,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.resultId,
    this.isVerified = false,
  });

  factory LabReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LabReviewModel(
      id: doc.id,
      laboratoryId: data['laboratoryId'] ?? '',
      laboratoryName: data['laboratoryName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resultId: data['resultId'],
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'laboratoryId': laboratoryId,
      'laboratoryName': laboratoryName,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'resultId': resultId,
      'isVerified': isVerified,
    };
  }

  @override
  List<Object?> get props => [
        id,
        laboratoryId,
        laboratoryName,
        userId,
        userName,
        rating,
        comment,
        createdAt,
        resultId,
        isVerified,
      ];
}

/// إحصائيات التقييمات
class ReviewStatistics extends Equatable {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // {5: 10, 4: 5, ...}
  final int verifiedReviews;

  const ReviewStatistics({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.verifiedReviews,
  });

  int get percentage5Star =>
      totalReviews > 0 ? ((ratingDistribution[5] ?? 0) * 100 ~/ totalReviews) : 0;
  int get percentage4Star =>
      totalReviews > 0 ? ((ratingDistribution[4] ?? 0) * 100 ~/ totalReviews) : 0;
  int get percentage3Star =>
      totalReviews > 0 ? ((ratingDistribution[3] ?? 0) * 100 ~/ totalReviews) : 0;
  int get percentage2Star =>
      totalReviews > 0 ? ((ratingDistribution[2] ?? 0) * 100 ~/ totalReviews) : 0;
  int get percentage1Star =>
      totalReviews > 0 ? ((ratingDistribution[1] ?? 0) * 100 ~/ totalReviews) : 0;

  @override
  List<Object?> get props =>
      [averageRating, totalReviews, ratingDistribution, verifiedReviews];
}
