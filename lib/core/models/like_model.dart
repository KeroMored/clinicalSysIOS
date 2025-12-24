import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for likes on any service
class LikeModel {
  final String id;
  final String serviceId; // ID of clinic, pharmacy, lab, etc.
  final String serviceType; // 'clinic', 'pharmacy', 'laboratory', etc.
  final String userId;
  final String userEmail;
  final DateTime createdAt;

  LikeModel({
    required this.id,
    required this.serviceId,
    required this.serviceType,
    required this.userId,
    required this.userEmail,
    required this.createdAt,
  });

  // Convert from Firestore
  factory LikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LikeModel(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      serviceType: data['serviceType'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
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
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
