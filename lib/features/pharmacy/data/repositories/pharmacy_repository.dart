import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pharmacy_model.dart';
import '../models/pharmacy_offer_model.dart';

class PharmacyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all pharmacies (approved only)
  Future<List<PharmacyModel>> getAllPharmacies() async {
    try {
      final snapshot = await _firestore
          .collection('pharmacies')
          .where('status', isEqualTo: 'approved')
          .get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Calculate isOpen dynamically
            final isOpen = _calculateIsOpen(
              data['workingHours'] ?? '',
              data['holidays'] ?? '',
            );
            return PharmacyModel.fromJson({
              ...data,
              'id': doc.id,
              'isOpen': isOpen,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pharmacies: $e');
    }
  }

  // Get pharmacy by ID
  Future<PharmacyModel> getPharmacyById(String id) async {
    try {
      final doc = await _firestore.collection('pharmacies').doc(id).get();
      if (!doc.exists) {
        throw Exception('Pharmacy not found');
      }
      final data = doc.data()!;
      // Calculate isOpen dynamically
      final isOpen = _calculateIsOpen(
        data['workingHours'] ?? '',
        data['holidays'] ?? '',
      );
      return PharmacyModel.fromJson({
        ...data,
        'id': doc.id,
        'isOpen': isOpen,
      });
    } catch (e) {
      throw Exception('Failed to fetch pharmacy: $e');
    }
  }

  // Get all offers
  Future<List<PharmacyOfferModel>> getAllOffers() async {
    try {
      final snapshot = await _firestore
          .collection('pharmacy_offers')
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: DateTime.now().toIso8601String())
          .get();
      return snapshot.docs
          .map((doc) => PharmacyOfferModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch offers: $e');
    }
  }

  // Get offers by pharmacy ID
  Future<List<PharmacyOfferModel>> getOffersByPharmacyId(
      String pharmacyId) async {
    try {
      final snapshot = await _firestore
          .collection('pharmacy_offers')
          .where('pharmacyId', isEqualTo: pharmacyId)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => PharmacyOfferModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pharmacy offers: $e');
    }
  }

  // Search pharmacies in database
  Future<List<PharmacyModel>> searchPharmacies(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }
      
      final lowerQuery = query.toLowerCase().trim();
      
      // Search by name using Firestore range query
      final nameSnapshot = await _firestore
          .collection('pharmacies')
          .where('status', isEqualTo: 'approved')
          .orderBy('nameLower')
          .startAt([lowerQuery])
          .endAt(['$lowerQuery\uf8ff'])
          .limit(20)
          .get();
      
      // Also search by address
      final addressSnapshot = await _firestore
          .collection('pharmacies')
          .where('status', isEqualTo: 'approved')
          .orderBy('addressLower')
          .startAt([lowerQuery])
          .endAt(['$lowerQuery\uf8ff'])
          .limit(20)
          .get();
      
      // Combine results and remove duplicates
      final Map<String, PharmacyModel> pharmaciesMap = {};
      
      for (final doc in nameSnapshot.docs) {
        final data = doc.data();
        final isOpen = _calculateIsOpen(
          data['workingHours'] ?? '',
          data['holidays'] ?? '',
        );
        pharmaciesMap[doc.id] = PharmacyModel.fromJson({
          ...data,
          'id': doc.id,
          'isOpen': isOpen,
        });
      }
      
      for (final doc in addressSnapshot.docs) {
        if (!pharmaciesMap.containsKey(doc.id)) {
          final data = doc.data();
          final isOpen = _calculateIsOpen(
            data['workingHours'] ?? '',
            data['holidays'] ?? '',
          );
          pharmaciesMap[doc.id] = PharmacyModel.fromJson({
            ...data,
            'id': doc.id,
            'isOpen': isOpen,
          });
        }
      }
      
      return pharmaciesMap.values.toList();
    } catch (e) {
      // Fallback: if indexes are not set up, search all and filter
      print('Search index not available, using fallback: $e');
      final snapshot = await _firestore
          .collection('pharmacies')
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
            return PharmacyModel.fromJson({
              ...data,
              'id': doc.id,
              'isOpen': isOpen,
            });
          })
          .where((pharmacy) =>
              pharmacy.name.toLowerCase().contains(lowerQuery) ||
              pharmacy.address.toLowerCase().contains(lowerQuery))
          .toList();
    }
  }

  // Calculate if pharmacy is currently open based on working hours
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
}
