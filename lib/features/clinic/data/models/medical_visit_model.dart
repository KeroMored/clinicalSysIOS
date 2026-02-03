import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalVisitModel {
  final String id;
  final String patientId;
  final String clinicId;
  final DateTime visitDate;
  final String? diagnosis; // اختياري الآن
  final List<String> medications;
  final List<String> prescriptionImageUrls; // قائمة صور بدلاً من صورة واحدة
  final DateTime createdAt;

  MedicalVisitModel({
    required this.id,
    required this.patientId,
    required this.clinicId,
    required this.visitDate,
    this.diagnosis,
    required this.medications,
    List<String>? prescriptionImageUrls,
    required this.createdAt,
  }) : prescriptionImageUrls = prescriptionImageUrls ?? [];

  factory MedicalVisitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // دعم الصيغة القديمة (prescriptionImageUrl) والجديدة (prescriptionImageUrls)
    List<String> imageUrls = [];
    if (data['prescriptionImageUrls'] != null) {
      imageUrls = List<String>.from(data['prescriptionImageUrls']);
    } else if (data['prescriptionImageUrl'] != null && data['prescriptionImageUrl'] != '') {
      imageUrls = [data['prescriptionImageUrl'] as String];
    }
    
    return MedicalVisitModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      clinicId: data['clinicId'] ?? '',
      visitDate: (data['visitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      diagnosis: data['diagnosis'],
      medications: List<String>.from(data['medications'] ?? []),
      prescriptionImageUrls: imageUrls,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'clinicId': clinicId,
      'visitDate': Timestamp.fromDate(visitDate),
      'diagnosis': diagnosis,
      'medications': medications,
      'prescriptionImageUrls': prescriptionImageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MedicalVisitModel copyWith({
    String? id,
    String? patientId,
    String? clinicId,
    DateTime? visitDate,
    String? diagnosis,
    List<String>? medications,
    List<String>? prescriptionImageUrls,
    DateTime? createdAt,
  }) {
    return MedicalVisitModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      clinicId: clinicId ?? this.clinicId,
      visitDate: visitDate ?? this.visitDate,
      diagnosis: diagnosis ?? this.diagnosis,
      medications: medications ?? this.medications,
      prescriptionImageUrls: prescriptionImageUrls ?? this.prescriptionImageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // للتوافق مع الكود القديم
  String? get prescriptionImageUrl => prescriptionImageUrls.isNotEmpty ? prescriptionImageUrls.first : null;
}
