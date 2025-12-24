import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/radiology_model.dart';

class RadiologyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'radiology_centers';

  // Add new radiology center
  Future<void> addRadiologyCenter(RadiologyModel radiology) async {
    try {
      await _firestore.collection(_collection).doc(radiology.id).set(radiology.toMap());
    } catch (e) {
      throw Exception('فشل في إضافة مركز الأشعة: $e');
    }
  }

  // Update radiology center
  Future<void> updateRadiologyCenter(RadiologyModel radiology) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(radiology.id)
          .update(radiology.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('فشل في تحديث مركز الأشعة: $e');
    }
  }

  // Delete radiology center
  Future<void> deleteRadiologyCenter(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('فشل في حذف مركز الأشعة: $e');
    }
  }

  // Get all radiology centers
  Stream<List<RadiologyModel>> getAllRadiologyCenters() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RadiologyModel.fromMap(doc.data())).toList();
    });
  }

  // Get approved radiology centers only (for users)
  Stream<List<RadiologyModel>> getApprovedRadiologyCenters() {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RadiologyModel.fromMap(doc.data())).toList();
    });
  }

  // Get pending radiology centers (for admin approval)
  Stream<List<RadiologyModel>> getPendingRadiologyCenters() {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RadiologyModel.fromMap(doc.data())).toList();
    });
  }

  // Get radiology center by ID
  Future<RadiologyModel?> getRadiologyCenterById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return RadiologyModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب بيانات مركز الأشعة: $e');
    }
  }

  // Get radiology center by owner email
  Stream<RadiologyModel?> getRadiologyCenterByOwnerEmail(String email) {
    return _firestore
        .collection(_collection)
        .where('authEmails', arrayContains: email)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return RadiologyModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    });
  }

  // Search radiology centers by name in database
  Future<List<RadiologyModel>> searchRadiologyCenters(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }
      
      final lowerQuery = query.toLowerCase().trim();
      
      // Try to search by name using Firestore range query
      try {
        final nameSnapshot = await _firestore
            .collection(_collection)
            .where('isApproved', isEqualTo: true)
            .where('isActive', isEqualTo: true)
            .orderBy('centerNameLower')
            .startAt([lowerQuery])
            .endAt(['$lowerQuery\uf8ff'])
            .limit(20)
            .get();
        
        if (nameSnapshot.docs.isNotEmpty) {
          return nameSnapshot.docs
              .map((doc) => RadiologyModel.fromMap(doc.data()))
              .toList();
        }
      } catch (e) {
        print('Search index not available: $e');
      }
      
      // Fallback: search all and filter
      final snapshot = await _firestore
          .collection(_collection)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => RadiologyModel.fromMap(doc.data()))
          .where((radiology) =>
              radiology.centerName.toLowerCase().contains(lowerQuery) ||
              radiology.address.toLowerCase().contains(lowerQuery) ||
              radiology.governorate.toLowerCase().contains(lowerQuery) ||
              radiology.city.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      throw Exception('فشل في البحث: $e');
    }
  }

  // Filter by governorate
  Stream<List<RadiologyModel>> getRadiologyCentersByGovernorate(String governorate) {
    return _firestore
        .collection(_collection)
        .where('governorate', isEqualTo: governorate)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RadiologyModel.fromMap(doc.data())).toList();
    });
  }

  // Filter by service
  Stream<List<RadiologyModel>> getRadiologyCentersByService(String service) {
    return _firestore
        .collection(_collection)
        .where('services', arrayContains: service)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RadiologyModel.fromMap(doc.data())).toList();
    });
  }

  // Get radiology centers with home visit service
  Stream<List<RadiologyModel>> getHomeVisitRadiologyCenters() {
    return _firestore
        .collection(_collection)
        .where('homeVisit', isEqualTo: true)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RadiologyModel.fromMap(doc.data())).toList();
    });
  }

  // Approve radiology center
  Future<void> approveRadiologyCenter(String id, {String? notes}) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isApproved': true,
        'updatedAt': Timestamp.now(),
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      throw Exception('فشل في الموافقة على مركز الأشعة: $e');
    }
  }

  // Reject radiology center
  Future<void> rejectRadiologyCenter(String id, String notes) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isApproved': false,
        'isActive': false,
        'notes': notes,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في رفض مركز الأشعة: $e');
    }
  }

  // Toggle active status
  Future<void> toggleActiveStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في تغيير حالة مركز الأشعة: $e');
    }
  }

  // Return radiology center to pending status
  Future<void> returnRadiologyToPending(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isApproved': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في إرجاع المركز لقيد الانتظار: $e');
    }
  }

  // Get approved radiology centers for admin (includes all approved)
  Stream<List<RadiologyModel>> getApprovedRadiologyCentersForAdmin() {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RadiologyModel.fromMap(doc.data())).toList();
    });
  }
}
