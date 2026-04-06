import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add or update rating
  Future<void> addRating(RatingModel rating) async {
    try {
      // Check if user already rated this service
      final existingRating = await _firestore
          .collection('ratings')
          .where('serviceId', isEqualTo: rating.serviceId)
          .where('userId', isEqualTo: rating.userId)
          .limit(1)
          .get();

      if (existingRating.docs.isNotEmpty) {
        // Update existing rating
        await _firestore
            .collection('ratings')
            .doc(existingRating.docs.first.id)
            .update(rating.toMap());
      } else {
        // Add new rating
        await _firestore.collection('ratings').add(rating.toMap());
      }

      // Update service average rating
      await _updateServiceRating(rating.serviceId, rating.serviceType);
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  /// Get user's rating for a service
  Future<RatingModel?> getUserRating(String serviceId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('serviceId', isEqualTo: serviceId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return RatingModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Get all ratings for a service
  Future<List<RatingModel>> getServiceRatings(String serviceId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update service average rating
  Future<void> _updateServiceRating(
    String serviceId,
    String serviceType,
  ) async {
    try {
      print('🔄 Updating rating for $serviceType: $serviceId');
      final ratings = await getServiceRatings(serviceId);
      print('📊 Found ${ratings.length} ratings');

      if (ratings.isEmpty) {
        print('⚠️ No ratings found, setting to 0');
        await _updateServiceDocument(serviceType, serviceId, 0.0, 0);
        return;
      }

      final totalStars = ratings.fold<int>(
        0,
        (sum, rating) => sum + rating.rating,
      );
      final average = totalStars / ratings.length;
      print('⭐ Average rating: $average (from $totalStars stars)');

      await _updateServiceDocument(
        serviceType,
        serviceId,
        average,
        ratings.length,
      );
      print('✅ Rating updated successfully!');
    } catch (e) {
      print('❌ Error updating service rating: $e');
    }
  }

  /// Update service document with new rating
  Future<void> _updateServiceDocument(
    String serviceType,
    String serviceId,
    double averageRating,
    int totalRatings,
  ) async {
    String collection = _getCollectionName(serviceType);
    print(
      '📝 Updating $collection/$serviceId with avgRating=$averageRating, total=$totalRatings',
    );

    // Use transaction to safely update only rating fields without affecting likes
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(collection).doc(serviceId);
      final doc = await transaction.get(docRef);

      if (doc.exists) {
        transaction.update(docRef, {
          'averageRating': averageRating,
          'totalRatings': totalRatings,
        });
      }
    });
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
      default:
        return serviceType;
    }
  }

  /// Delete rating
  Future<void> deleteRating(
    String ratingId,
    String serviceId,
    String serviceType,
  ) async {
    try {
      await _firestore.collection('ratings').doc(ratingId).delete();
      await _updateServiceRating(serviceId, serviceType);
    } catch (e) {
      throw Exception('Failed to delete rating: $e');
    }
  }
}
