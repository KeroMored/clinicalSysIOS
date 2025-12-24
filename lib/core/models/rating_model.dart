import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for rating any service (clinic, pharmacy, lab, etc.)
class RatingModel {
  final String id;
  final String serviceId; // ID of clinic, pharmacy, lab, etc.
  final String serviceType; // 'clinic', 'pharmacy', 'laboratory', etc.
  final String userId;
  final String userEmail;
  final String userName;
  final int rating; // 1 to 5 stars
  final String? comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.serviceId,
    required this.serviceType,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  // Convert from Firestore
  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      serviceType: data['serviceType'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceType': serviceType,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with
  RatingModel copyWith({
    String? id,
    String? serviceId,
    String? serviceType,
    String? userId,
    String? userEmail,
    String? userName,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return RatingModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceType: serviceType ?? this.serviceType,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
