import 'package:cloud_firestore/cloud_firestore.dart';

class CenterContentModel {
  final String id;
  final String centerId;
  final String type; // 'offer', 'video', 'image'
  final String title;
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final bool isActive;

  CenterContentModel({
    required this.id,
    required this.centerId,
    required this.type,
    required this.title,
    this.description,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'centerId': centerId,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory CenterContentModel.fromMap(Map<String, dynamic> map) {
    return CenterContentModel(
      id: map['id'] ?? '',
      centerId: map['centerId'] ?? '',
      type: map['type'] ?? 'offer',
      title: map['title'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}
