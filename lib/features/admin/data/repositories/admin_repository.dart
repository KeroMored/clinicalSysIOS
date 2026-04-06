import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pharmacy_request_model.dart';
import '../../../pharmacy/data/models/pharmacy_model.dart';
import '../../../laboratory/data/models/laboratory_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all pending pharmacy requests
  Future<List<PharmacyRequestModel>> getPendingPharmacyRequests() async {
    try {
      // Get from pharmacies collection where status is pending
      final snapshot = await _firestore
          .collection('pharmacies')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert pharmacy data to request model format
        return PharmacyRequestModel(
          id: doc.id,
          name: data['name'] ?? '',
          address: data['address'] ?? '',
          phones: data['phones'] != null
              ? List<String>.from(data['phones'])
              : (data['phone'] != null ? [data['phone']] : []),
          whatsapp: data['whatsapp'] ?? '',

          latitude: (data['latitude'] ?? 0.0).toDouble(),
          longitude: (data['longitude'] ?? 0.0).toDouble(),
          workingHours: data['workingHours'] ?? '',
          holidays: data['holidays'] ?? '',
          images: List<String>.from(data['images'] ?? []),
          hasHomeDelivery: data['hasHomeDelivery'] ?? false,
          deliveryFee: data['deliveryFee']?.toDouble(),
          minimumOrderForDelivery: data['minimumOrderForDelivery']?.toDouble(),
          services: List<String>.from(data['services'] ?? []),
          status: data['status'] ?? 'pending',
          requestDate: DateTime.now(),
          ownerName: data['ownerName'] ?? '',
          ownerPhone: data['ownerPhone'] ?? '',
          ownerEmail: data['ownerEmail'] ?? '',
          hasInsurance: data['hasInsurance'] ?? false,
          insuranceCompanies: data['insuranceCompanies'] != null
              ? List<String>.from(data['insuranceCompanies'])
              : [],
          description: data['description'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pharmacy requests: $e');
    }
  }

  // Get pharmacy requests by status (all, pending, rejected)
  Future<List<PharmacyRequestModel>> getPharmacyRequestsByStatus(
    String status,
  ) async {
    try {
      Query query = _firestore.collection('pharmacies');

      // If status is not 'all', filter by status
      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PharmacyRequestModel(
          id: doc.id,
          name: data['name'] ?? '',
          address: data['address'] ?? '',
          phones: data['phones'] != null
              ? List<String>.from(data['phones'])
              : (data['phone'] != null ? [data['phone']] : []),
          whatsapp: data['whatsapp'] ?? '',

          latitude: (data['latitude'] ?? 0.0).toDouble(),
          longitude: (data['longitude'] ?? 0.0).toDouble(),
          workingHours: data['workingHours'] ?? '',
          holidays: data['holidays'] ?? '',
          images: List<String>.from(data['images'] ?? []),
          hasHomeDelivery: data['hasHomeDelivery'] ?? false,
          deliveryFee: data['deliveryFee']?.toDouble(),
          minimumOrderForDelivery: data['minimumOrderForDelivery']?.toDouble(),
          services: List<String>.from(data['services'] ?? []),
          status: data['status'] ?? 'pending',
          requestDate: DateTime.now(),
          ownerName: data['ownerName'] ?? '',
          ownerPhone: data['ownerPhone'] ?? '',
          ownerEmail: data['ownerEmail'] ?? '',
          hasInsurance: data['hasInsurance'] ?? false,
          insuranceCompanies: data['insuranceCompanies'] != null
              ? List<String>.from(data['insuranceCompanies'])
              : [],
          description: data['description'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pharmacy requests: $e');
    }
  }

  // Get all pharmacy requests (any status)
  Future<List<PharmacyRequestModel>> getAllPharmacyRequests() async {
    try {
      final snapshot = await _firestore
          .collection('pharmacy_requests')
          .orderBy('requestDate', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                PharmacyRequestModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pharmacy requests: $e');
    }
  }

  // Get request by ID
  Future<PharmacyRequestModel> getRequestById(String id) async {
    try {
      final doc = await _firestore
          .collection('pharmacy_requests')
          .doc(id)
          .get();
      if (!doc.exists) {
        throw Exception('Request not found');
      }
      return PharmacyRequestModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to fetch request: $e');
    }
  }

  // Approve pharmacy request
  Future<void> approvePharmacyRequest(String requestId) async {
    try {
      // Get the pharmacy document first to retrieve authEmails
      final pharmacyDoc = await _firestore
          .collection('pharmacies')
          .doc(requestId)
          .get();

      if (!pharmacyDoc.exists) {
        throw Exception('Pharmacy not found');
      }

      final pharmacyData = pharmacyDoc.data()!;
      final authEmails = List<String>.from(pharmacyData['authEmails'] ?? []);

      // Update the status from pending to approved
      await _firestore.collection('pharmacies').doc(requestId).update({
        'status': 'approved',
      });

      // ✅ CRITICAL FIX: ربط جميع المستخدمين الموجودين بالإيميلات المحددة بالصيدلية
      for (final email in authEmails) {
        await _linkExistingUsersToPharmacy(email, requestId);
      }
    } catch (e) {
      throw Exception('Failed to approve pharmacy request: $e');
    }
  }

  // Reject pharmacy request
  Future<void> rejectPharmacyRequest(
    String requestId,
    String rejectionReason,
  ) async {
    try {
      await _firestore.collection('pharmacies').doc(requestId).update({
        'status': 'rejected',
        'rejectionReason': rejectionReason,
      });
    } catch (e) {
      throw Exception('Failed to reject pharmacy request: $e');
    }
  }

  // Set pharmacy status to pending
  Future<void> setPendingPharmacyRequest(String requestId) async {
    try {
      await _firestore.collection('pharmacies').doc(requestId).update({
        'status': 'pending',
        'rejectionReason':
            FieldValue.delete(), // Remove rejection reason if exists
      });
    } catch (e) {
      throw Exception('Failed to set pharmacy to pending: $e');
    }
  }

  // Submit new pharmacy request
  Future<void> submitPharmacyRequest(PharmacyRequestModel request) async {
    try {
      await _firestore.collection('pharmacy_requests').add(request.toJson());
    } catch (e) {
      throw Exception('Failed to submit pharmacy request: $e');
    }
  }

  // Get pending requests count
  Future<int> getPendingPharmacyRequestsCount() async {
    try {
      final snapshot = await _firestore
          .collection('pharmacy_requests')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get pending count: $e');
    }
  }

  // Add pharmacy directly (bypassing the request system)
  Future<void> addPharmacyDirectly(PharmacyRequestModel request) async {
    try {
      // Add directly to pharmacies collection with pending status
      final pharmacyData = PharmacyModel(
        id: '',
        name: request.name,
        address: request.address,
        phones: request.phones,
        whatsapp: request.whatsapp,

        latitude: request.latitude,
        longitude: request.longitude,
        workingHours: request.workingHours,
        holidays: request.holidays,
        images: request.images,
        hasHomeDelivery: request.hasHomeDelivery,
        deliveryFee: request.deliveryFee,
        minimumOrderForDelivery: request.minimumOrderForDelivery,
        rating: 0.0,
        reviewsCount: 0,
        isOpen: _calculateIsOpen(request.workingHours, request.holidays),
        services: request.services,
        status: 'pending', // Start as pending
        ownerName: request.ownerName,
        ownerPhone: request.ownerPhone,
        authEmails: [request.ownerEmail],
        hasInsurance: request.hasInsurance,
        insuranceCompanies: request.insuranceCompanies,
        description: request.description,
      ).toJson();

      final pharmacyDoc = await _firestore
          .collection('pharmacies')
          .add(pharmacyData);
      final pharmacyId = pharmacyDoc.id;

      // ✅ CRITICAL FIX: ربط جميع المستخدمين الموجودين بالإيميل المحدد بالصيدلية الجديدة
      await _linkExistingUsersToPharmacy(request.ownerEmail, pharmacyId);
    } catch (e) {
      throw Exception('Failed to add pharmacy directly: $e');
    }
  }

  // ✅ NEW: ربط المستخدمين الموجودين بالصيدلية الجديدة
  Future<void> _linkExistingUsersToPharmacy(
    String email,
    String pharmacyId,
  ) async {
    try {
      // البحث عن المستخدمين بهذا الإيميل
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        print('⚠️ No existing users found with email: $email');
        return;
      }

      // تحديث جميع المستخدمين المطابقين
      for (final userDoc in usersSnapshot.docs) {
        await userDoc.reference.update({
          'role': 'pharmacy',
          'pharmacyId': pharmacyId,
        });

        print(
          '✅ Updated user ${userDoc.id} with pharmacy role and ID: $pharmacyId',
        );

        // إنشاء pharmacy_subscription للمستخدم
        await _firestore
            .collection('pharmacy_subscriptions')
            .doc(userDoc.id)
            .set({
              'subscribedAt': FieldValue.serverTimestamp(),
              'topic': 'pharmacy_requests',
              'isActive': true,
              'pharmacyId': pharmacyId,
            });

        print('✅ Created pharmacy_subscription for user ${userDoc.id}');
      }
    } catch (e) {
      print('❌ Error linking existing users to pharmacy: $e');
      // لا نرمي exception هنا لأننا لا نريد فشل إضافة الصيدلية
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

      // Parse working hours (format: "9:00 AM - 10:00 PM" or "09:00-22:00")
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
      // Remove any AM/PM and extra spaces
      time = time.replaceAll(RegExp(r'[AaPpMm\s]'), '').trim();

      final parts = time.split(':');
      if (parts.length != 2) return null;

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Convert to 24-hour format if needed
      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      return hour * 60 + minute;
    } catch (e) {
      return null;
    }
  }

  // ============ CLINIC REQUESTS MANAGEMENT ============

  // Get pending clinic requests
  Future<List<Map<String, dynamic>>> getPendingClinicRequests() async {
    try {
      final snapshot = await _firestore
          .collection('clinics')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch clinic requests: $e');
    }
  }

  // Get clinic requests by status
  Future<List<Map<String, dynamic>>> getClinicRequestsByStatus(
    String status,
  ) async {
    try {
      Query query = _firestore.collection('clinics');

      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch clinic requests: $e');
    }
  }

  // Approve clinic request
  Future<void> approveClinicRequest(String clinicId) async {
    try {
      await _firestore.collection('clinics').doc(clinicId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to approve clinic: $e');
    }
  }

  // Reject clinic request
  Future<void> rejectClinicRequest(String clinicId, String reason) async {
    try {
      await _firestore.collection('clinics').doc(clinicId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });
    } catch (e) {
      throw Exception('Failed to reject clinic: $e');
    }
  }

  // Delete clinic permanently
  Future<void> deleteClinic(String clinicId) async {
    try {
      await _firestore.collection('clinics').doc(clinicId).delete();
    } catch (e) {
      throw Exception('Failed to delete clinic: $e');
    }
  }

  // ========== LABORATORY MANAGEMENT ==========

  // Get all laboratory requests
  Stream<List<LaboratoryModel>> getAllLaboratoryRequests() {
    return _firestore
        .collection('laboratories')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LaboratoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get pending laboratory requests
  Stream<List<LaboratoryModel>> getPendingLaboratoryRequests() {
    return _firestore
        .collection('laboratories')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LaboratoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get laboratory requests by status
  Stream<List<LaboratoryModel>> getLaboratoryRequestsByStatus(String status) {
    return _firestore
        .collection('laboratories')
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LaboratoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Approve laboratory request
  Future<void> approveLaboratoryRequest(String labId) async {
    try {
      await _firestore.collection('laboratories').doc(labId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      });
    } catch (e) {
      throw Exception('Failed to approve laboratory: $e');
    }
  }

  // Reject laboratory request
  Future<void> rejectLaboratoryRequest(String labId, String reason) async {
    try {
      await _firestore.collection('laboratories').doc(labId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });
    } catch (e) {
      throw Exception('Failed to reject laboratory: $e');
    }
  }

  // Back laboratory to pending
  Future<void> backLaboratoryToPending(String labId) async {
    try {
      await _firestore.collection('laboratories').doc(labId).update({
        'status': 'pending',
        'approvedAt': null,
        'rejectedAt': null,
        'rejectionReason': null,
      });
    } catch (e) {
      throw Exception('Failed to back laboratory to pending: $e');
    }
  }

  // Delete laboratory permanently
  Future<void> deleteLaboratory(String labId) async {
    try {
      await _firestore.collection('laboratories').doc(labId).delete();
    } catch (e) {
      throw Exception('Failed to delete laboratory: $e');
    }
  }

  // ============ NURSING FUNCTIONS ============

  // Get pending nurse requests
  Future<List<Map<String, dynamic>>> getPendingNurseRequests() async {
    try {
      final snapshot = await _firestore
          .collection('nurses')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch nurse requests: $e');
    }
  }

  // Get nurse requests by status
  Future<List<Map<String, dynamic>>> getNurseRequestsByStatus(
    String status,
  ) async {
    try {
      Query query = _firestore.collection('nurses');

      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch nurse requests: $e');
    }
  }

  // Approve nurse request
  Future<void> approveNurseRequest(String nurseId) async {
    try {
      await _firestore.collection('nurses').doc(nurseId).update({
        'status': 'approved',
        'isApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to approve nurse: $e');
    }
  }

  // Reject nurse request
  Future<void> rejectNurseRequest(String nurseId, String reason) async {
    try {
      await _firestore.collection('nurses').doc(nurseId).update({
        'status': 'rejected',
        'isApproved': false,
        'notes': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject nurse: $e');
    }
  }

  // Delete nurse request
  Future<void> deleteNurseRequest(String nurseId) async {
    try {
      await _firestore.collection('nurses').doc(nurseId).delete();
    } catch (e) {
      throw Exception('Failed to delete nurse: $e');
    }
  }

  // Add nurse directly by admin (approved immediately)
  Future<void> addNurse(dynamic nurse) async {
    try {
      final nurseData = nurse.toMap();
      await _firestore.collection('nurses').doc(nurse.id).set(nurseData);
    } catch (e) {
      throw Exception('Failed to add nurse: $e');
    }
  }

  // Add delivery directly by admin (pending approval)
  Future<void> addDelivery(dynamic delivery) async {
    try {
      final deliveryData = delivery.toMap();
      await _firestore
          .collection('deliveries')
          .doc(delivery.id)
          .set(deliveryData);
    } catch (e) {
      throw Exception('Failed to add delivery: $e');
    }
  }

  Future<void> addRehabilitationCenter(dynamic center) async {
    try {
      final centerData = center.toMap();
      await _firestore
          .collection('rehabilitation_centers')
          .doc(center.id)
          .set(centerData);
    } catch (e) {
      throw Exception('Failed to add rehabilitation center: $e');
    }
  }
}
