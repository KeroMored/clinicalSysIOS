import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/visit_model.dart';

class VisitRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // إضافة كشف جديد
  Future<String> addVisit(VisitModel visit) async {
    try {
      final docRef = await _firestore.collection('visits').add(visit.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إضافة الكشف: ${e.toString()}');
    }
  }

  // جلب كشوفات مريض معين
  Stream<List<VisitModel>> getVisitsByPatient(String patientId) {
    return _firestore
        .collection('visits')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitModel.fromFirestore(doc))
            .toList());
  }

  // جلب كشوفات عيادة معينة
  Stream<List<VisitModel>> getVisitsByClinic(String clinicId) {
    return _firestore
        .collection('visits')
        .where('clinicId', isEqualTo: clinicId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitModel.fromFirestore(doc))
            .toList());
  }

  // جلب كشف واحد
  Future<VisitModel> getVisitById(String visitId) async {
    try {
      final doc = await _firestore.collection('visits').doc(visitId).get();
      if (!doc.exists) {
        throw Exception('الكشف غير موجود');
      }
      return VisitModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('فشل في جلب بيانات الكشف: ${e.toString()}');
    }
  }

  // تحديث كشف
  Future<void> updateVisit(String visitId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('visits').doc(visitId).update(updates);
    } catch (e) {
      throw Exception('فشل في تحديث الكشف: ${e.toString()}');
    }
  }

  // حذف كشف
  Future<void> deleteVisit(String visitId) async {
    try {
      // حذف صورة الروشتة إن وجدت
      final doc = await _firestore.collection('visits').doc(visitId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrl = data['prescriptionImageUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            // تجاهل خطأ حذف الصورة
          }
        }
      }
      
      // حذف الكشف
      await _firestore.collection('visits').doc(visitId).delete();
    } catch (e) {
      throw Exception('فشل في حذف الكشف: ${e.toString()}');
    }
  }

  // رفع صورة الروشتة
  Future<String> uploadPrescriptionImage(File imageFile, String visitId) async {
    try {
      final fileName = 'prescriptions/${visitId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('فشل في رفع صورة الروشتة: ${e.toString()}');
    }
  }

  // حذف صورة الروشتة
  Future<void> deletePrescriptionImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      throw Exception('فشل في حذف صورة الروشتة: ${e.toString()}');
    }
  }

  // إحصائيات عدد الكشوفات لمريض
  Future<int> getVisitsCountByPatient(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('visits')
          .where('patientId', isEqualTo: patientId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // إحصائيات عدد الكشوفات لعيادة
  Future<int> getVisitsCountByClinic(String clinicId) async {
    try {
      final snapshot = await _firestore
          .collection('visits')
          .where('clinicId', isEqualTo: clinicId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // آخر كشف لمريض
  Future<VisitModel?> getLastVisitByPatient(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('visits')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return VisitModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }
}
