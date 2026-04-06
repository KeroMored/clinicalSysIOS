import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/patient_model.dart';
import '../models/medical_visit_model.dart';

class PatientsPageResult {
  final List<PatientModel> patients;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PatientsPageResult({
    required this.patients,
    required this.lastDocument,
    required this.hasMore,
  });
}

class PatientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<PatientsPageResult> getClinicPatientsPage(
    String clinicId, {
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection('patients')
        .where('clinicId', isEqualTo: clinicId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    final patients = snapshot.docs
        .map((doc) => PatientModel.fromFirestore(doc))
        .toList();

    return PatientsPageResult(
      patients: patients,
      lastDocument: snapshot.docs.isNotEmpty
          ? snapshot.docs.last
          : lastDocument,
      hasMore: snapshot.docs.length == limit,
    );
  }

  // Patients Methods
  Stream<List<PatientModel>> getClinicPatients(String clinicId) {
    return _firestore
        .collection('patients')
        .where('clinicId', isEqualTo: clinicId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PatientModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<PatientModel> addPatient(PatientModel patient) async {
    final docRef = await _firestore
        .collection('patients')
        .add(patient.toFirestore());
    final doc = await docRef.get();
    return PatientModel.fromFirestore(doc);
  }

  Future<void> updatePatient(PatientModel patient) async {
    await _firestore
        .collection('patients')
        .doc(patient.id)
        .update(patient.toFirestore());
  }

  Future<void> deletePatient(String patientId) async {
    // Delete all visits for this patient first
    final visits = await _firestore
        .collection('medical_visits')
        .where('patientId', isEqualTo: patientId)
        .get();

    for (var doc in visits.docs) {
      await doc.reference.delete();
    }

    // Delete patient
    await _firestore.collection('patients').doc(patientId).delete();
  }

  Stream<PatientModel> getPatient(String patientId) {
    return _firestore
        .collection('patients')
        .doc(patientId)
        .snapshots()
        .map((doc) => PatientModel.fromFirestore(doc));
  }

  // Medical Visits Methods
  Stream<List<MedicalVisitModel>> getPatientVisits(String patientId) {
    return _firestore
        .collection('medical_visits')
        .where('patientId', isEqualTo: patientId)
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MedicalVisitModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<MedicalVisitModel> addVisit(MedicalVisitModel visit) async {
    final docRef = await _firestore
        .collection('medical_visits')
        .add(visit.toFirestore());
    final doc = await docRef.get();
    return MedicalVisitModel.fromFirestore(doc);
  }

  Future<void> updateVisit(MedicalVisitModel visit) async {
    await _firestore
        .collection('medical_visits')
        .doc(visit.id)
        .update(visit.toFirestore());
  }

  Future<void> deleteVisit(String visitId) async {
    await _firestore.collection('medical_visits').doc(visitId).delete();
  }

  Future<String?> uploadPrescriptionImage(
    String patientId,
    String visitId,
    File imageFile,
  ) async {
    try {
      final ref = _storage.ref().child('prescriptions/$patientId/$visitId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Stream<int> getPatientVisitsCount(String patientId) {
    return _firestore
        .collection('medical_visits')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
