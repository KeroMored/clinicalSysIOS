import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rehabilitation_center_model.dart';

class RehabilitationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rehabilitation_centers';

  // Get approved and active centers
  Stream<List<RehabilitationCenterModel>> getAvailableCenters() {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RehabilitationCenterModel.fromMap(doc.data()))
            .toList());
  }

  // Get pending centers for approval
  Stream<List<RehabilitationCenterModel>> getPendingCenters() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RehabilitationCenterModel.fromMap(doc.data()))
            .toList());
  }

  // Get all centers (for admin)
  Stream<List<RehabilitationCenterModel>> getAllCenters() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RehabilitationCenterModel.fromMap(doc.data()))
            .toList());
  }

  // Get centers by service type
  Stream<List<RehabilitationCenterModel>> getCentersByType(String serviceType) {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('serviceTypes', arrayContains: serviceType)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RehabilitationCenterModel.fromMap(doc.data()))
            .toList());
  }

  // Get centers by governorate
  Stream<List<RehabilitationCenterModel>> getCentersByGovernorate(String governorate) {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('governorate', isEqualTo: governorate)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RehabilitationCenterModel.fromMap(doc.data()))
            .toList());
  }

  // Add new center
  Future<void> addCenter(RehabilitationCenterModel center) async {
    try {
      await _firestore.collection(_collection).doc(center.id).set(center.toMap());
    } catch (e) {
      throw Exception('فشل في إضافة المركز: $e');
    }
  }

  // Update center
  Future<void> updateCenter(RehabilitationCenterModel center) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(center.id)
          .update(center.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('فشل في تحديث المركز: $e');
    }
  }

  // Delete center
  Future<void> deleteCenter(String centerId) async {
    try {
      await _firestore.collection(_collection).doc(centerId).delete();
    } catch (e) {
      throw Exception('فشل في حذف المركز: $e');
    }
  }

  // Approve center
  Future<void> approveCenter(String centerId) async {
    try {
      await _firestore.collection(_collection).doc(centerId).update({
        'isApproved': true,
        'status': 'approved',
        'isActive': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في الموافقة على المركز: $e');
    }
  }

  // Reject center
  Future<void> rejectCenter(String centerId, String reason) async {
    try {
      await _firestore.collection(_collection).doc(centerId).update({
        'isApproved': false,
        'status': 'rejected',
        'isActive': false,
        'rejectionReason': reason,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في رفض المركز: $e');
    }
  }

  // Toggle active status
  Future<void> toggleActiveStatus(String centerId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(centerId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في تغيير حالة المركز: $e');
    }
  }

  // Update rating
  Future<void> updateRating(String centerId, double newRating, int reviewCount) async {
    try {
      await _firestore.collection(_collection).doc(centerId).update({
        'rating': newRating,
        'reviewCount': reviewCount,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث التقييم: $e');
    }
  }

  // Get center by ID
  Future<RehabilitationCenterModel?> getCenterById(String centerId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(centerId).get();
      if (doc.exists) {
        return RehabilitationCenterModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب بيانات المركز: $e');
    }
  }

  // Search centers using Firestore queries
  Future<List<RehabilitationCenterModel>> searchCenters(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final centersMap = <String, RehabilitationCenterModel>{};

      // Search by name
      final nameResults = await _firestore
          .collection(_collection)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('centerName', isGreaterThanOrEqualTo: lowerQuery)
          .where('centerName', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .get();

      for (final doc in nameResults.docs) {
        final center = RehabilitationCenterModel.fromMap(doc.data());
        centersMap[center.id] = center;
      }

      // Search by governorate
      final govResults = await _firestore
          .collection(_collection)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('governorate', isGreaterThanOrEqualTo: lowerQuery)
          .where('governorate', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .get();

      for (final doc in govResults.docs) {
        final center = RehabilitationCenterModel.fromMap(doc.data());
        centersMap[center.id] = center;
      }

      // Search by city
      final cityResults = await _firestore
          .collection(_collection)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('city', isGreaterThanOrEqualTo: lowerQuery)
          .where('city', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .get();

      for (final doc in cityResults.docs) {
        final center = RehabilitationCenterModel.fromMap(doc.data());
        centersMap[center.id] = center;
      }

      return centersMap.values.toList();
    } catch (e) {
      throw Exception('فشل في البحث عن المراكز: $e');
    }
  }
}
