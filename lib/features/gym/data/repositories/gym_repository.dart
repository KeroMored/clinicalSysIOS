import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gym_model.dart';

class GymRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'gyms';

  // Get all approved gyms
  Stream<List<GymModel>> getApprovedGyms() {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GymModel.fromFirestore(doc)).toList());
  }

  // Get pending gyms for admin approval
  Stream<List<GymModel>> getPendingGyms() {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GymModel.fromFirestore(doc)).toList());
  }

  // Get gym by ID
  Future<GymModel?> getGymById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return GymModel.fromFirestore(doc);
    }
    return null;
  }

  // Add new gym
  Future<String> addGym(GymModel gym) async {
    final docRef = await _firestore.collection(_collection).add(gym.toFirestore());
    return docRef.id;
  }

  // Update gym
  Future<void> updateGym(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  // Approve gym
  Future<void> approveGym(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'isApproved': true,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reject/Delete gym
  Future<void> deleteGym(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Search gyms using Firestore queries
  Stream<List<GymModel>> searchGyms(String query) async* {
    final lowerQuery = query.toLowerCase();
    final gymsMap = <String, GymModel>{};

    // Search by name
    final nameResults = await _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: lowerQuery)
        .where('name', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .get();

    for (final doc in nameResults.docs) {
      final gym = GymModel.fromFirestore(doc);
      gymsMap[gym.id] = gym;
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
      final gym = GymModel.fromFirestore(doc);
      gymsMap[gym.id] = gym;
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
      final gym = GymModel.fromFirestore(doc);
      gymsMap[gym.id] = gym;
    }

    yield gymsMap.values.toList();
  }

  // Filter by gender availability
  Stream<List<GymModel>> filterByGender(bool male, bool female) {
    Query query = _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true);

    if (male && !female) {
      query = query.where('hasMaleSection', isEqualTo: true);
    } else if (female && !male) {
      query = query.where('hasFemaleSection', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => GymModel.fromFirestore(doc)).toList());
  }

  // Filter by governorate
  Stream<List<GymModel>> filterByGovernorate(String governorate) {
    return _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('governorate', isEqualTo: governorate)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GymModel.fromFirestore(doc)).toList());
  }
}
