import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_offer_model.dart';

class MedicineOfferRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'medicine_offers';

  // إضافة عرض جديد
  Future<void> addOffer(MedicineOfferModel offer) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(offer.id)
          .set(offer.toJson());
      
      // ✅ إرسال إشعار لجميع المستخدمين عن العرض الجديد
      await _sendOfferNotification(offer);
    } catch (e) {
      throw Exception('فشل في إضافة العرض: $e');
    }
  }

  // إرسال إشعار عن عرض دواء جديد
  Future<void> _sendOfferNotification(MedicineOfferModel offer) async {
    try {
      await _firestore.collection('notifications_queue').add({
        // 🔗 Deep Link Data
        'type': 'new_medicine_offer',
        'offerId': offer.id,
        
        // 📱 Notification Content
        'title': '💊 عرض جديد على ${offer.medicineName}',
        'body': '${offer.quantity} وحدة متاحة - السعر: ${offer.price} جنيه',
        
        // 🎯 Delivery Settings
        'topic': 'all_users',
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ تم إضافة إشعار عرض الدواء إلى notifications_queue');
      print('🔗 Deep Link Type: new_medicine_offer');
      print('📦 Offer ID: ${offer.id}');
    } catch (e) {
      print('❌ خطأ في إرسال إشعار العرض: $e');
      // لا نرمي خطأ هنا حتى لا نمنع حفظ العرض
    }
  }

  // جلب كل العروض النشطة من كل الصيدليات
  Future<List<MedicineOfferModel>> getAllActiveOffers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('quantity', isGreaterThan: 0)
          .orderBy('quantity')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MedicineOfferModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب العروض: $e');
    }
  }

  // جلب عروض صيدلية معينة
  Future<List<MedicineOfferModel>> getOffersByPharmacy(
    String pharmacyId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('pharmacyId', isEqualTo: pharmacyId)
          .where('isActive', isEqualTo: true)
          .where('quantity', isGreaterThan: 0)
          .orderBy('quantity')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MedicineOfferModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب عروض الصيدلية: $e');
    }
  }

  // تحديث كمية العرض
  Future<void> updateQuantity(String offerId, int newQuantity) async {
    try {
      // لو الكمية = 0، نحذف العرض
      if (newQuantity <= 0) {
        await deleteOffer(offerId);
      } else {
        await _firestore.collection(_collection).doc(offerId).update({
          'quantity': newQuantity,
        });
      }
    } catch (e) {
      throw Exception('فشل في تحديث الكمية: $e');
    }
  }

  // حذف عرض (لما الكمية تخلص)
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore.collection(_collection).doc(offerId).delete();
    } catch (e) {
      throw Exception('فشل في حذف العرض: $e');
    }
  }

  // تحديث بيانات العرض
  Future<void> updateOffer(MedicineOfferModel offer) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(offer.id)
          .update(offer.toJson());
    } catch (e) {
      throw Exception('فشل في تحديث العرض: $e');
    }
  }

  // جلب عروض الصيدلية (بما فيها الغير نشطة) - للإدارة
  Future<List<MedicineOfferModel>> getAllOffersByPharmacy(
    String pharmacyId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('pharmacyId', isEqualTo: pharmacyId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MedicineOfferModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب كل عروض الصيدلية: $e');
    }
  }
}
