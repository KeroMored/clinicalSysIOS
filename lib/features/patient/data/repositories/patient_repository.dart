import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';

class PatientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة مريض جديد
  Future<String> addPatient(PatientModel patient) async {
    try {
      final docRef = await _firestore
          .collection('patients')
          .add(patient.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إضافة المريض: ${e.toString()}');
    }
  }

  // جلب جميع مرضى العيادة مع real-time updates
  Stream<List<PatientModel>> getPatientsByClinic(String clinicId) {
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

  // جلب مريض واحد
  Future<PatientModel> getPatientById(String patientId) async {
    try {
      final doc = await _firestore.collection('patients').doc(patientId).get();
      if (!doc.exists) {
        throw Exception('المريض غير موجود');
      }
      return PatientModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('فشل في جلب بيانات المريض: ${e.toString()}');
    }
  }

  // تحديث بيانات مريض
  Future<void> updatePatient(
    String patientId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('patients').doc(patientId).update(updates);
    } catch (e) {
      throw Exception('فشل في تحديث بيانات المريض: ${e.toString()}');
    }
  }

  // حذف مريض
  Future<void> deletePatient(String patientId) async {
    try {
      // حذف المريض
      await _firestore.collection('patients').doc(patientId).delete();

      // حذف جميع الكشوفات الخاصة به
      final visits = await _firestore
          .collection('visits')
          .where('patientId', isEqualTo: patientId)
          .get();

      for (var doc in visits.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('فشل في حذف المريض: ${e.toString()}');
    }
  }

  // البحث عن مرضى بالاسم أو رقم الهاتف
  Stream<List<PatientModel>> searchPatients(String clinicId, String query) {
    // البحث بالاسم
    final nameQuery = _firestore
        .collection('patients')
        .where('clinicId', isEqualTo: clinicId)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();

    // البحث برقم الهاتف
    final phoneQuery = _firestore
        .collection('patients')
        .where('clinicId', isEqualTo: clinicId)
        .where('phoneNumber', isGreaterThanOrEqualTo: query)
        .where('phoneNumber', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();

    // دمج النتائج
    return nameQuery.asyncMap((nameSnapshot) async {
      final phoneSnapshot = await phoneQuery.first;

      final results = <String, PatientModel>{};

      for (var doc in nameSnapshot.docs) {
        results[doc.id] = PatientModel.fromFirestore(doc);
      }

      for (var doc in phoneSnapshot.docs) {
        results[doc.id] = PatientModel.fromFirestore(doc);
      }

      return results.values.toList();
    });
  }

  // إحصائيات عدد المرضى
  Future<int> getPatientsCount(String clinicId) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('clinicId', isEqualTo: clinicId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
