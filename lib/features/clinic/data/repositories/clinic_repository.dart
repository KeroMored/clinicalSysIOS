import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clinic_model.dart';
import '../models/clinic_department.dart';

class ClinicRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all clinics (approved only for public view)
  Stream<List<ClinicModel>> getAllClinics() {
    return _firestore
        .collection('clinics')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClinicModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get clinics by department (approved only)
  Stream<List<ClinicModel>> getClinicsByDepartment(
    ClinicDepartment department,
  ) {
    return _firestore
        .collection('clinics')
        .where('department', isEqualTo: department.englishName)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClinicModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get clinic by ID
  Future<ClinicModel> getClinicById(String clinicId) async {
    final doc = await _firestore.collection('clinics').doc(clinicId).get();
    return ClinicModel.fromFirestore(doc);
  }

  // Add new clinic (Admin only)
  Future<String> addClinic(ClinicModel clinic) async {
    final docRef = await _firestore
        .collection('clinics')
        .add(clinic.toFirestore());
    return docRef.id;
  }

  // Update clinic
  Future<void> updateClinic(
    String clinicId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('clinics').doc(clinicId).update(updates);
  }

  // Delete clinic (soft delete - set isActive to false)
  Future<void> deleteClinic(String clinicId) async {
    await _firestore.collection('clinics').doc(clinicId).update({
      'isActive': false,
    });
  }

  // Search clinics using Firestore queries
  Future<List<ClinicModel>> searchClinics(String query) async {
    final lowerQuery = query.toLowerCase();
    final clinicsMap = <String, ClinicModel>{};

    // Search by doctorName
    final nameResults = await _firestore
        .collection('clinics')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .where('doctorName', isGreaterThanOrEqualTo: lowerQuery)
        .where('doctorName', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .get();

    for (final doc in nameResults.docs) {
      final clinic = ClinicModel.fromFirestore(doc);
      clinicsMap[clinic.id] = clinic;
    }

    // Search by specialization
    final specResults = await _firestore
        .collection('clinics')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .where('specialization', isGreaterThanOrEqualTo: lowerQuery)
        .where('specialization', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .get();

    for (final doc in specResults.docs) {
      final clinic = ClinicModel.fromFirestore(doc);
      clinicsMap[clinic.id] = clinic;
    }

    // Search by department
    final deptResults = await _firestore
        .collection('clinics')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .where('department', isGreaterThanOrEqualTo: lowerQuery)
        .where('department', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .get();

    for (final doc in deptResults.docs) {
      final clinic = ClinicModel.fromFirestore(doc);
      clinicsMap[clinic.id] = clinic;
    }

    return clinicsMap.values.toList();
  }

  // Get count of clinics by department
  Future<Map<ClinicDepartment, int>> getClinicCountByDepartment() async {
    final snapshot = await _firestore
        .collection('clinics')
        .where('isActive', isEqualTo: true)
        .get();

    Map<ClinicDepartment, int> counts = {};
    for (var dept in ClinicDepartment.values) {
      counts[dept] = 0;
    }

    for (var doc in snapshot.docs) {
      final clinic = ClinicModel.fromFirestore(doc);
      counts[clinic.department] = (counts[clinic.department] ?? 0) + 1;
    }

    return counts;
  }
}
