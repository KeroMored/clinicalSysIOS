import 'package:cloud_firestore/cloud_firestore.dart';

class VisitModel {
  final String id;
  final String patientId;
  final String clinicId;
  final DateTime date;
  final String time;
  final String diagnosis;
  final List<String> medicines;
  final String? prescriptionImageUrl;
  final String notes;
  final DateTime createdAt;

  VisitModel({
    required this.id,
    required this.patientId,
    required this.clinicId,
    required this.date,
    required this.time,
    required this.diagnosis,
    required this.medicines,
    this.prescriptionImageUrl,
    required this.notes,
    required this.createdAt,
  });

  factory VisitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      clinicId: data['clinicId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: data['time'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      medicines: List<String>.from(data['medicines'] ?? []),
      prescriptionImageUrl: data['prescriptionImageUrl'],
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'clinicId': clinicId,
      'date': Timestamp.fromDate(date),
      'time': time,
      'diagnosis': diagnosis,
      'medicines': medicines,
      'prescriptionImageUrl': prescriptionImageUrl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  VisitModel copyWith({
    String? id,
    String? patientId,
    String? clinicId,
    DateTime? date,
    String? time,
    String? diagnosis,
    List<String>? medicines,
    String? prescriptionImageUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return VisitModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      clinicId: clinicId ?? this.clinicId,
      date: date ?? this.date,
      time: time ?? this.time,
      diagnosis: diagnosis ?? this.diagnosis,
      medicines: medicines ?? this.medicines,
      prescriptionImageUrl: prescriptionImageUrl ?? this.prescriptionImageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
