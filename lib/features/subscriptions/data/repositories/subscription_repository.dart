import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_settings_model.dart';
import '../models/subscribed_place_model.dart';
import '../models/payment_record_model.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _settingsCollection => _firestore.collection('subscription_settings');
  CollectionReference get _subscribedPlacesCollection => _firestore.collection('subscribed_places');
  CollectionReference get _paymentRecordsCollection => _firestore.collection('payment_records');

  // ==================== Settings ====================

  // Get subscription settings
  Future<SubscriptionSettingsModel> getSettings() async {
    try {
      final doc = await _settingsCollection.doc('settings').get();
      if (doc.exists) {
        return SubscriptionSettingsModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      // Create default settings if not exists
      await _settingsCollection.doc('settings').set(SubscriptionSettingsModel.defaultSettings.toMap());
      return SubscriptionSettingsModel.defaultSettings;
    } catch (e) {
      throw Exception('فشل في تحميل إعدادات الاشتراك: $e');
    }
  }

  // Update subscription settings
  Future<void> updateSettings(SubscriptionSettingsModel settings) async {
    try {
      await _settingsCollection.doc('settings').set(settings.toMap());
    } catch (e) {
      throw Exception('فشل في تحديث إعدادات الاشتراك: $e');
    }
  }

  // ==================== Subscribed Places ====================

  // Get all subscribed places
  Stream<List<SubscribedPlaceModel>> getAllSubscribedPlaces() {
    return _subscribedPlacesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscribedPlaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all subscribed places with pagination
  Stream<List<SubscribedPlaceModel>> getAllSubscribedPlacesPaginated({required int limit}) {
    return _subscribedPlacesCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscribedPlaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get more subscribed places (pagination)
  Future<List<SubscribedPlaceModel>> getMoreSubscribedPlaces({
    required int limit,
    String? afterPlaceId,
  }) async {
    try {
      Query query = _subscribedPlacesCollection.orderBy('createdAt', descending: true);

      if (afterPlaceId != null) {
        final lastDoc = await _subscribedPlacesCollection.doc(afterPlaceId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs
          .map((doc) => SubscribedPlaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('فشل في تحميل المزيد من الأماكن: $e');
    }
  }

  // Get subscribed places by type
  Stream<List<SubscribedPlaceModel>> getSubscribedPlacesByType(PlaceType type) {
    return _subscribedPlacesCollection
        .where('placeType', isEqualTo: type.englishName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscribedPlaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get subscribed place by ID
  Future<SubscribedPlaceModel?> getSubscribedPlaceById(String id) async {
    try {
      final doc = await _subscribedPlacesCollection.doc(id).get();
      if (doc.exists) {
        return SubscribedPlaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في تحميل بيانات المكان: $e');
    }
  }

  // Check if place is already subscribed
  Future<SubscribedPlaceModel?> getSubscribedPlaceByPlaceId(String placeId, PlaceType placeType) async {
    try {
      final snapshot = await _subscribedPlacesCollection
          .where('placeId', isEqualTo: placeId)
          .where('placeType', isEqualTo: placeType.englishName)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return SubscribedPlaceModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('فشل في البحث عن المكان: $e');
    }
  }

  // Add subscribed place
  Future<String> addSubscribedPlace(SubscribedPlaceModel place) async {
    try {
      final docRef = await _subscribedPlacesCollection.add(place.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إضافة المكان: $e');
    }
  }

  // Update subscribed place
  Future<void> updateSubscribedPlace(String id, Map<String, dynamic> updates) async {
    try {
      await _subscribedPlacesCollection.doc(id).update(updates);
    } catch (e) {
      throw Exception('فشل في تحديث المكان: $e');
    }
  }

  // Update notes for a place
  Future<void> updatePlaceNotes(String id, String notes) async {
    try {
      await _subscribedPlacesCollection.doc(id).update({'notes': notes});
    } catch (e) {
      throw Exception('فشل في تحديث الملاحظات: $e');
    }
  }

  // Delete subscribed place
  Future<void> deleteSubscribedPlace(String id) async {
    try {
      // Delete all payment records for this place
      final payments = await _paymentRecordsCollection
          .where('subscribedPlaceId', isEqualTo: id)
          .get();
      
      for (final doc in payments.docs) {
        await doc.reference.delete();
      }

      // Delete the place
      await _subscribedPlacesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('فشل في حذف المكان: $e');
    }
  }

  // ==================== Payment Records ====================

  // Get payment records for a place
  Stream<List<PaymentRecordModel>> getPaymentRecords(String subscribedPlaceId) {
    return _paymentRecordsCollection
        .where('subscribedPlaceId', isEqualTo: subscribedPlaceId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentRecordModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all payment records (for statistics)
  Future<List<PaymentRecordModel>> getAllPaymentRecords() async {
    try {
      final snapshot = await _paymentRecordsCollection
          .orderBy('paymentDate', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PaymentRecordModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('فشل في تحميل سجلات الدفع: $e');
    }
  }

  // Add payment record
  Future<String> addPaymentRecord(PaymentRecordModel record) async {
    try {
      // Add the payment record
      final docRef = await _paymentRecordsCollection.add(record.toMap());

      // Update the subscribed place with the new payment info
      await _subscribedPlacesCollection.doc(record.subscribedPlaceId).update({
        'lastPaymentDate': Timestamp.fromDate(record.paymentDate),
        'subscriptionEndDate': Timestamp.fromDate(record.subscriptionEndDate),
        'totalPaid': FieldValue.increment(record.amount),
        'paymentCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('فشل في تسجيل الدفع: $e');
    }
  }

  // Delete payment record
  Future<void> deletePaymentRecord(String id, String subscribedPlaceId, double amount) async {
    try {
      await _paymentRecordsCollection.doc(id).delete();

      // Update the subscribed place totals
      await _subscribedPlacesCollection.doc(subscribedPlaceId).update({
        'totalPaid': FieldValue.increment(-amount),
        'paymentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('فشل في حذف سجل الدفع: $e');
    }
  }

  // ==================== Sync Places from Collections ====================

  // Sync all approved places from all collections
  Future<void> syncAllPlaces() async {
    try {
      // Sync each place type
      for (final type in PlaceType.values) {
        await syncPlacesOfType(type);
      }
    } catch (e) {
      throw Exception('فشل في مزامنة الأماكن: $e');
    }
  }

  // Sync places of a specific type
  Future<void> syncPlacesOfType(PlaceType type) async {
    try {
      final collection = _firestore.collection(type.collectionName);
      
      // Get all approved/active places
      QuerySnapshot snapshot;
      switch (type) {
        case PlaceType.clinic:
          snapshot = await collection
              .where('status', isEqualTo: 'approved')
              .where('isActive', isEqualTo: true)
              .get();
          break;
        case PlaceType.pharmacy:
        case PlaceType.laboratory:
        case PlaceType.radiology:
        case PlaceType.rehabilitation:
        case PlaceType.gym:
          snapshot = await collection
              .where('isApproved', isEqualTo: true)
              .where('isActive', isEqualTo: true)
              .get();
          break;
        case PlaceType.nursing:
        case PlaceType.delivery:
          snapshot = await collection
              .where('isApproved', isEqualTo: true)
              .where('isActive', isEqualTo: true)
              .get();
          break;
      }

      // Add each place if not already exists
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if already exists
        final existing = await getSubscribedPlaceByPlaceId(doc.id, type);
        if (existing == null) {
          // Extract common fields based on type
          String placeName = '';
          String ownerName = '';
          String phone = '';
          String? email;
          String? address;
          String? governorate;
          String? city;

          switch (type) {
            case PlaceType.clinic:
              placeName = data['clinicName'] ?? data['doctorName'] ?? '';
              ownerName = data['doctorName'] ?? '';
              phone = data['phone'] ?? '';
              email = data['email'];
              address = data['address'];
              governorate = data['governorate'];
              city = data['city'];
              break;
            case PlaceType.pharmacy:
              placeName = data['pharmacyName'] ?? data['name'] ?? '';
              ownerName = data['ownerName'] ?? data['pharmacistName'] ?? '';
              phone = data['phone'] ?? '';
              email = data['email'];
              address = data['address'];
              governorate = data['governorate'];
              city = data['city'];
              break;
            case PlaceType.laboratory:
              placeName = data['laboratoryName'] ?? data['name'] ?? '';
              ownerName = data['ownerName'] ?? '';
              phone = data['phone'] ?? '';
              email = data['email'];
              address = data['address'];
              governorate = data['governorate'];
              city = data['city'];
              break;
            case PlaceType.radiology:
              placeName = data['centerName'] ?? data['name'] ?? '';
              ownerName = data['ownerName'] ?? '';
              phone = data['phone'] ?? '';
              email = data['email'];
              address = data['address'];
              governorate = data['governorate'];
              city = data['city'];
              break;
            case PlaceType.nursing:
              placeName = data['nurseName'] ?? '';
              ownerName = data['nurseName'] ?? '';
              phone = data['phone'] ?? '';
              email = data['email'];
              address = data['address'];
              governorate = data['governorate'];
              city = data['city'];
              break;
            case PlaceType.delivery:
              placeName = data['deliveryName'] ?? '';
              ownerName = data['deliveryName'] ?? '';
              phone = data['deliveryPhone'] ?? data['phone'] ?? '';
              email = data['email'];
              address = data['address'];
              governorate = data['governorate'];
              city = data['city'];
              break;
            case PlaceType.rehabilitation:
              placeName = data['centerName'] ?? data['name'] ?? '';
              ownerName = data['ownerName'] ?? '';
              phone = data['phone'] ?? '';
              email = data['email'];
              address = data['address'];
              governorate = data['governorate'];
              city = data['city'];
              break;
            case PlaceType.gym:
              placeName = data['name'] ?? '';
              ownerName = data['ownerName'] ?? '';
              phone = data['phone'] ?? '';
              email = data['email'];
              address = data['address'];
              governorate = data['governorate'];
              city = data['city'];
              break;
          }

          // Create subscribed place
          final place = SubscribedPlaceModel(
            id: '',
            placeId: doc.id,
            placeType: type,
            placeName: placeName,
            ownerName: ownerName,
            phone: phone,
            email: email,
            address: address,
            governorate: governorate,
            city: city,
            createdAt: DateTime.now(),
          );

          await addSubscribedPlace(place);
        }
      }
    } catch (e) {
      throw Exception('فشل في مزامنة أماكن ${type.arabicName}: $e');
    }
  }

  // ==================== Statistics ====================

  // Get subscription statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final placesSnapshot = await _subscribedPlacesCollection.get();
      final paymentsSnapshot = await _paymentRecordsCollection.get();

      final places = placesSnapshot.docs
          .map((doc) => SubscribedPlaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      int totalPlaces = places.length;
      int activePlaces = places.where((p) => !p.isSubscriptionExpired).length;
      int expiredPlaces = places.where((p) => p.isSubscriptionExpired).length;
      int expiringPlaces = places.where((p) => p.subscriptionStatus == 'ينتهي قريباً').length;

      double totalRevenue = 0;
      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRevenue += (data['amount'] ?? 0).toDouble();
      }

      // Count by type
      Map<PlaceType, int> countByType = {};
      for (final type in PlaceType.values) {
        countByType[type] = places.where((p) => p.placeType == type).length;
      }

      return {
        'totalPlaces': totalPlaces,
        'activePlaces': activePlaces,
        'expiredPlaces': expiredPlaces,
        'expiringPlaces': expiringPlaces,
        'totalRevenue': totalRevenue,
        'countByType': countByType,
        'totalPayments': paymentsSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('فشل في تحميل الإحصائيات: $e');
    }
  }

  // Search subscribed places
  Future<List<SubscribedPlaceModel>> searchPlaces(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final snapshot = await _subscribedPlacesCollection.get();
      
      return snapshot.docs
          .map((doc) => SubscribedPlaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((place) =>
              place.placeName.toLowerCase().contains(lowerQuery) ||
              place.ownerName.toLowerCase().contains(lowerQuery) ||
              place.phone.contains(lowerQuery) ||
              (place.governorate?.toLowerCase().contains(lowerQuery) ?? false) ||
              (place.city?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    } catch (e) {
      throw Exception('فشل في البحث: $e');
    }
  }

  // Get expired subscriptions
  Stream<List<SubscribedPlaceModel>> getExpiredSubscriptions() {
    return _subscribedPlacesCollection
        .where('subscriptionEndDate', isLessThan: Timestamp.now())
        .orderBy('subscriptionEndDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscribedPlaceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
