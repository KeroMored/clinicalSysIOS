import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/laboratory_model.dart';

class LaboratoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'laboratories';

  // Get all approved laboratories
  Stream<List<LaboratoryModel>> getLaboratories() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaboratoryModel.fromFirestore(doc))
            .toList());
  }

  // Get laboratory by ID
  Future<LaboratoryModel?> getLaboratoryById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return LaboratoryModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get laboratory: $e');
    }
  }

  // Get laboratory by owner email
  Stream<LaboratoryModel?> getLaboratoryByOwnerEmail(String ownerEmail) {
    return _firestore
        .collection(_collection)
        .where('authEmails', arrayContains: ownerEmail)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return LaboratoryModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // Search laboratories in database
  Stream<List<LaboratoryModel>> searchLaboratories(String query) {
    if (query.trim().isEmpty) {
      return Stream.value([]);
    }
    
    final lowerQuery = query.toLowerCase().trim();
    
    // Search in database using Firestore
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // Try to search by name prefix first
      try {
        final nameSnapshot = await _firestore
            .collection(_collection)
            .where('status', isEqualTo: 'approved')
            .where('isVisible', isEqualTo: true)
            .orderBy('nameLower')
            .startAt([lowerQuery])
            .endAt(['$lowerQuery\uf8ff'])
            .limit(20)
            .get();
        
        if (nameSnapshot.docs.isNotEmpty) {
          return nameSnapshot.docs
              .map((doc) => LaboratoryModel.fromFirestore(doc))
              .toList();
        }
      } catch (e) {
        print('Name search index not available: $e');
      }
      
      // Fallback: filter from current snapshot
      final labs = snapshot.docs
          .map((doc) => LaboratoryModel.fromFirestore(doc))
          .toList();
      
      return labs.where((lab) {
        return lab.name.toLowerCase().contains(lowerQuery) ||
            lab.city.toLowerCase().contains(lowerQuery) ||
            lab.address.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  // Filter laboratories by city
  Stream<List<LaboratoryModel>> getLaboratoriesByCity(String city) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .where('city', isEqualTo: city)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaboratoryModel.fromFirestore(doc))
            .toList());
  }

  // Filter laboratories by governorate
  Stream<List<LaboratoryModel>> getLaboratoriesByGovernorate(String governorate) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .where('governorate', isEqualTo: governorate)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaboratoryModel.fromFirestore(doc))
            .toList());
  }

  // Filter laboratories by available test
  Stream<List<LaboratoryModel>> getLaboratoriesByTest(String testName) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .where('availableTests', arrayContains: testName)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaboratoryModel.fromFirestore(doc))
            .toList());
  }

  // Filter laboratories with home service
  Stream<List<LaboratoryModel>> getLaboratoriesWithHomeService() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .where('hasHomeService', isEqualTo: true)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaboratoryModel.fromFirestore(doc))
            .toList());
  }

  // Add new laboratory
  Future<String> addLaboratory(LaboratoryModel laboratory) async {
    try {
      final docRef = await _firestore.collection(_collection).add(laboratory.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add laboratory: $e');
    }
  }

  // Update laboratory
  Future<void> updateLaboratory(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update laboratory: $e');
    }
  }

  // Toggle laboratory visibility
  Future<void> toggleVisibility(String id, bool isVisible) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isVisible': isVisible,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle visibility: $e');
    }
  }

  // Delete laboratory
  Future<void> deleteLaboratory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete laboratory: $e');
    }
  }

  // Get nearby laboratories (based on coordinates)
  Stream<List<LaboratoryModel>> getNearbyLaboratories(
    double userLat,
    double userLng,
    double radiusInKm,
  ) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final labs = snapshot.docs
          .map((doc) => LaboratoryModel.fromFirestore(doc))
          .toList();

      // Filter by distance
      return labs.where((lab) {
        final distance = _calculateDistance(
          userLat,
          userLng,
          lab.latitude,
          lab.longitude,
        );
        return distance <= radiusInKm;
      }).toList();
    });
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
