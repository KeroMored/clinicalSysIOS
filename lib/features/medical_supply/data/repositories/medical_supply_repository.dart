import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_supply_model.dart';
import '../models/medical_supply_offer_model.dart';

class MedicalSupplyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all medical supplies (approved only)
  Future<List<MedicalSupplyModel>> getAllMedicalSupplies() async {
    try {
      final snapshot = await _firestore
          .collection('medical_supplies')
          .where('status', isEqualTo: 'approved')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Calculate isOpen dynamically
        final isOpen = _calculateIsOpen(
          data['workingHours'] ?? '',
          data['holidays'] ?? '',
        );
        return MedicalSupplyModel.fromJson({
          ...data,
          'id': doc.id,
          'isOpen': isOpen,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch medical supplies: $e');
    }
  }

  // Get medical supply by ID
  Future<MedicalSupplyModel> getMedicalSupplyById(String id) async {
    try {
      final doc = await _firestore.collection('medical_supplies').doc(id).get();
      if (!doc.exists) {
        throw Exception('Medical supply place not found');
      }
      final data = doc.data()!;
      // Calculate isOpen dynamically
      final isOpen = _calculateIsOpen(
        data['workingHours'] ?? '',
        data['holidays'] ?? '',
      );
      return MedicalSupplyModel.fromJson({...data, 'id': doc.id, 'isOpen': isOpen});
    } catch (e) {
      throw Exception('Failed to fetch medical supply place: $e');
    }
  }

  // Get medical supply by owner email
  Future<MedicalSupplyModel?> getMedicalSupplyByOwnerEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('medical_supplies')
          .where('authEmails', arrayContains: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      final isOpen = _calculateIsOpen(
        data['workingHours'] ?? '',
        data['holidays'] ?? '',
      );
      return MedicalSupplyModel.fromJson({
        ...data,
        'id': doc.id,
        'isOpen': isOpen,
      });
    } catch (e) {
      print('Error fetching medical supply by email: $e');
      return null;
    }
  }

  // Search medical supplies in database
  Future<List<MedicalSupplyModel>> searchMedicalSupplies(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final lowerQuery = query.toLowerCase().trim();

      // Search by name using Firestore range query
      final nameSnapshot = await _firestore
          .collection('medical_supplies')
          .where('status', isEqualTo: 'approved')
          .orderBy('nameLower')
          .startAt([lowerQuery])
          .endAt(['$lowerQuery\uf8ff'])
          .limit(20)
          .get();

      // Also search by address
      final addressSnapshot = await _firestore
          .collection('medical_supplies')
          .where('status', isEqualTo: 'approved')
          .orderBy('addressLower')
          .startAt([lowerQuery])
          .endAt(['$lowerQuery\uf8ff'])
          .limit(20)
          .get();

      // Combine results and remove duplicates
      final Map<String, MedicalSupplyModel> suppliesMap = {};

      for (final doc in nameSnapshot.docs) {
        final data = doc.data();
        final isOpen = _calculateIsOpen(
          data['workingHours'] ?? '',
          data['holidays'] ?? '',
        );
        suppliesMap[doc.id] = MedicalSupplyModel.fromJson({
          ...data,
          'id': doc.id,
          'isOpen': isOpen,
        });
      }

      for (final doc in addressSnapshot.docs) {
        if (!suppliesMap.containsKey(doc.id)) {
          final data = doc.data();
          final isOpen = _calculateIsOpen(
            data['workingHours'] ?? '',
            data['holidays'] ?? '',
          );
          suppliesMap[doc.id] = MedicalSupplyModel.fromJson({
            ...data,
            'id': doc.id,
            'isOpen': isOpen,
          });
        }
      }

      return suppliesMap.values.toList();
    } catch (e) {
      // Fallback: if indexes are not set up, search all and filter
      print('Search index not available, using fallback: $e');
      final snapshot = await _firestore
          .collection('medical_supplies')
          .where('status', isEqualTo: 'approved')
          .get();

      final lowerQuery = query.toLowerCase().trim();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            final isOpen = _calculateIsOpen(
              data['workingHours'] ?? '',
              data['holidays'] ?? '',
            );
            return MedicalSupplyModel.fromJson({
              ...data,
              'id': doc.id,
              'isOpen': isOpen,
            });
          })
          .where(
            (supply) =>
                supply.name.toLowerCase().contains(lowerQuery) ||
                supply.address.toLowerCase().contains(lowerQuery),
          )
          .toList();
    }
  }

  // Calculate if medical supply place is currently open based on working hours
  bool _calculateIsOpen(String workingHours, String holidays) {
    try {
      final now = DateTime.now();
      final currentDay = _getDayName(now.weekday);

      // Check if today is a holiday
      if (holidays.contains(currentDay)) {
        return false;
      }

      // Parse working hours (format: "09:00-22:00")
      final hoursParts = workingHours.split('-');
      if (hoursParts.length != 2) {
        return true; // Default to open if format is unclear
      }

      final openTime = _parseTime(hoursParts[0].trim());
      final closeTime = _parseTime(hoursParts[1].trim());

      if (openTime == null || closeTime == null) {
        return true; // Default to open if parsing fails
      }

      final currentMinutes = now.hour * 60 + now.minute;

      // Handle cases where closing time is after midnight
      if (closeTime < openTime) {
        return currentMinutes >= openTime || currentMinutes <= closeTime;
      }

      return currentMinutes >= openTime && currentMinutes <= closeTime;
    } catch (e) {
      return true; // Default to open on error
    }
  }

  String _getDayName(int weekday) {
    const days = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };
    return days[weekday] ?? '';
  }

  int? _parseTime(String time) {
    try {
      // Remove any extra spaces
      time = time.trim();

      final parts = time.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      return hour * 60 + minute;
    } catch (e) {
      return null;
    }
  }

  // Increment profile views count
  Future<void> incrementProfileViews(String id) async {
    try {
      await _firestore.collection('medical_supplies').doc(id).update({
        'profileViewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing profile views: $e');
    }
  }

  // Toggle like for medical supply place
  Future<void> toggleLike(String id, bool isLiked) async {
    try {
      await _firestore.collection('medical_supplies').doc(id).update({
        'totalLikes': FieldValue.increment(isLiked ? 1 : -1),
      });
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  // Get all offers from medical_supply_offers collection
  Future<List<MedicalSupplyOfferModel>> getAllOffers() async {
    try {
      final snapshot = await _firestore
          .collection('medical_supply_offers')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return MedicalSupplyOfferModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      print('Error fetching medical supply offers: $e');
      return [];
    }
  }

  // Get offers by medical supply ID
  Future<List<MedicalSupplyOfferModel>> getOffersByMedicalSupplyId(String supplyId) async {
    try {
      final snapshot = await _firestore
          .collection('medical_supply_offers')
          .where('supplyId', isEqualTo: supplyId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return MedicalSupplyOfferModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      print('Error fetching offers for medical supply $supplyId: $e');
      return [];
    }
  }
}
