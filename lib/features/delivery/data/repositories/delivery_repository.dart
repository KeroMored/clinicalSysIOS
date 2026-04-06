import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_model.dart';

class DeliveryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all approved and active deliveries
  Stream<List<DeliveryModel>> getAvailableDeliveries() {
    return _firestore
        .collection('deliveries')
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeliveryModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get all pending deliveries for approval
  Stream<List<DeliveryModel>> getPendingDeliveries() {
    return _firestore
        .collection('deliveries')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeliveryModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get all deliveries (for admin)
  Stream<List<DeliveryModel>> getAllDeliveries() {
    return _firestore
        .collection('deliveries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeliveryModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get delivery by ID
  Future<DeliveryModel?> getDeliveryById(String id) async {
    try {
      final doc = await _firestore.collection('deliveries').doc(id).get();
      if (doc.exists) {
        return DeliveryModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get delivery: $e');
    }
  }

  // Add new delivery
  Future<void> addDelivery(DeliveryModel delivery) async {
    try {
      await _firestore
          .collection('deliveries')
          .doc(delivery.id)
          .set(delivery.toMap());
    } catch (e) {
      throw Exception('Failed to add delivery: $e');
    }
  }

  // Update delivery
  Future<void> updateDelivery(DeliveryModel delivery) async {
    try {
      await _firestore
          .collection('deliveries')
          .doc(delivery.id)
          .update(delivery.toMap());
    } catch (e) {
      throw Exception('Failed to update delivery: $e');
    }
  }

  // Approve delivery
  Future<void> approveDelivery(String deliveryId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'isApproved': true,
        'isActive': true,
        'status': 'approved',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to approve delivery: $e');
    }
  }

  // Reject delivery
  Future<void> rejectDelivery(String deliveryId, String reason) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'isApproved': false,
        'isActive': false,
        'status': 'rejected',
        'notes': reason,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to reject delivery: $e');
    }
  }

  // Delete delivery
  Future<void> deleteDelivery(String deliveryId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).delete();
    } catch (e) {
      throw Exception('Failed to delete delivery: $e');
    }
  }

  // Toggle availability
  Future<void> toggleAvailability(String deliveryId, bool availableNow) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'availableNow': availableNow,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to toggle availability: $e');
    }
  }

  // Update rating
  Future<void> updateRating(String deliveryId, double newRating) async {
    try {
      final doc = await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final currentRating = (data['rating'] ?? 0.0).toDouble();
        final currentCount = data['reviewCount'] ?? 0;

        final totalRating = (currentRating * currentCount) + newRating;
        final newCount = currentCount + 1;
        final updatedRating = totalRating / newCount;

        await _firestore.collection('deliveries').doc(deliveryId).update({
          'rating': updatedRating,
          'reviewCount': newCount,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }

  // Increment completed deliveries
  Future<void> incrementCompletedDeliveries(String deliveryId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'completedDeliveries': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment completed deliveries: $e');
    }
  }

  // Return delivery to pending status
  Future<void> returnToPending(String deliveryId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'status': 'pending',
        'isApproved': false,
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to return delivery to pending: $e');
    }
  }

  // Search deliveries using Firestore queries
  Future<List<DeliveryModel>> searchDeliveries(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final deliveriesMap = <String, DeliveryModel>{};

      // Search by name
      final nameResults = await _firestore
          .collection('deliveries')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('deliveryName', isGreaterThanOrEqualTo: lowerQuery)
          .where('deliveryName', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .get();

      for (final doc in nameResults.docs) {
        final delivery = DeliveryModel.fromMap(doc.data());
        deliveriesMap[delivery.id] = delivery;
      }

      // Search by governorate
      final govResults = await _firestore
          .collection('deliveries')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('governorate', isGreaterThanOrEqualTo: lowerQuery)
          .where('governorate', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .get();

      for (final doc in govResults.docs) {
        final delivery = DeliveryModel.fromMap(doc.data());
        deliveriesMap[delivery.id] = delivery;
      }

      // Search by city
      final cityResults = await _firestore
          .collection('deliveries')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('city', isGreaterThanOrEqualTo: lowerQuery)
          .where('city', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .get();

      for (final doc in cityResults.docs) {
        final delivery = DeliveryModel.fromMap(doc.data());
        deliveriesMap[delivery.id] = delivery;
      }

      return deliveriesMap.values.toList();
    } catch (e) {
      throw Exception('Failed to search deliveries: $e');
    }
  }
}
