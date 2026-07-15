import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/like_model.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Toggle like (add if not exists, remove if exists)
  Future<bool> toggleLike(
    String serviceId,
    String serviceType,
    String userId,
    String userEmail,
  ) async {
    try {
      // Check if like already exists
      final existingLike = await _firestore
          .collection('likes')
          .where('serviceId', isEqualTo: serviceId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingLike.docs.isNotEmpty) {
        // Unlike - remove the like
        await _firestore
            .collection('likes')
            .doc(existingLike.docs.first.id)
            .delete();
        await _updateServiceLikes(serviceId, serviceType, -1);
        return false; // unliked
      } else {
        // Like - add new like
        final like = LikeModel(
          id: '',
          serviceId: serviceId,
          serviceType: serviceType,
          userId: userId,
          userEmail: userEmail,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('likes').add(like.toMap());
        await _updateServiceLikes(serviceId, serviceType, 1);
        return true; // liked
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Check if user liked a service
  Future<bool> isLiked(String serviceId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('likes')
          .where('serviceId', isEqualTo: serviceId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get total likes count for a service
  Future<int> getLikesCount(String serviceId) async {
    try {
      final snapshot = await _firestore
          .collection('likes')
          .where('serviceId', isEqualTo: serviceId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Update service likes count
  Future<void> _updateServiceLikes(
    String serviceId,
    String serviceType,
    int increment,
  ) async {
    try {
      String collection = _getCollectionName(serviceType);
      final docRef = _firestore.collection(collection).doc(serviceId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (doc.exists) {
          // Use likesCount for delivery, totalLikes for others
          final fieldName = serviceType == 'delivery'
              ? 'likesCount'
              : 'totalLikes';
          final currentLikes = doc.data()?[fieldName] ?? 0;
          transaction.update(docRef, {fieldName: currentLikes + increment});
        }
      });
    } catch (e) {
      print('Error updating service likes: $e');
    }
  }

  /// Get collection name from service type
  String _getCollectionName(String serviceType) {
    switch (serviceType) {
      case 'clinic':
        return 'clinics';
      case 'pharmacy':
        return 'pharmacies';
      case 'laboratory':
        return 'laboratories';
      case 'radiology':
        return 'radiology_centers';
      case 'gym':
        return 'gyms';
      case 'rehabilitation':
        return 'rehabilitation_centers';
      case 'delivery':
        return 'deliveries';
      case 'medical_supply':
        return 'medical_supplies';
      default:
        return serviceType;
    }
  }

  /// Get list of users who liked a service
  Future<List<LikeModel>> getServiceLikes(String serviceId) async {
    try {
      final snapshot = await _firestore
          .collection('likes')
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => LikeModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream of likes count for real-time updates
  Stream<int> getLikesCountStream(String serviceId, String serviceType) {
    String collection = _getCollectionName(serviceType);
    final fieldName = serviceType == 'delivery' ? 'likesCount' : 'totalLikes';

    return _firestore.collection(collection).doc(serviceId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return (doc.data()?[fieldName] ?? 0) as int;
      }
      return 0;
    });
  }
}
