import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? whatsappNumber; // رقم الواتساب (اختياري)
  final String clinicId;
  final DateTime createdAt;

  PatientModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.whatsappNumber,
    required this.clinicId,
    required this.createdAt,
  });

  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientModel(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      whatsappNumber: data['whatsappNumber'],
      clinicId: data['clinicId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'clinicId': clinicId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PatientModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? whatsappNumber,
    String? clinicId,
    DateTime? createdAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      clinicId: clinicId ?? this.clinicId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
