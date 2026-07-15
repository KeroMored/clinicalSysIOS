import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service للتعامل مع Deep Links من الإشعارات
/// يفتح الصفحة المناسبة حسب نوع الإشعار
class DeepLinkNavigationService {
  static final DeepLinkNavigationService _instance = DeepLinkNavigationService._();
  factory DeepLinkNavigationService() => _instance;
  DeepLinkNavigationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// تسجيل الـ navigator key من main app
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  BuildContext? get _context => _navigatorKey?.currentContext;

  /// معالجة الـ Deep Link من payload الإشعار
  Future<void> handleDeepLink(Map<String, dynamic> data) async {
    if (_context == null) {
      print('❌ Context not set for navigation');
      return;
    }

    final type = data['type'] as String?;
    print('🔗 Handling deep link for type: $type');

    try {
      switch (type) {
        // عروض الصيدليات
        case 'new_pharmacy_offer':
          await _navigateToPharmacyOffer(data);
          break;

        // عروض العيادات
        case 'new_clinic_offer':
          await _navigateToClinicOffer(data);
          break;

        // عروض الأدوية
        case 'new_medicine_offer':
          await _navigateToMedicineOffer(data);
          break;

        // حجز أونلاين جديد (للعيادة)
        case 'new_booking':
          await _navigateToBookingsManagement(data);
          break;

        // تحديث حالة الحجز (للمريض)
        case 'booking_confirmed':
        case 'booking_cancelled':
          await _navigateToBookingTracking();
          break;

        // طلب دواء جديد (للصيدليات)
        case 'new_medicine_request':
          await _navigateToMedicineRequests(data);
          break;

        // حجز معمل جديد
        case 'new_lab_booking':
          await _navigateToLabBookings(data);
          break;

        // إشعار عام من الأدمن
        case 'admin_notification':
          // يفتح التطبيق بس بدون navigation محددة
          break;

        default:
          print('⚠️ Unknown notification type: $type');
      }
    } catch (e) {
      print('❌ Error handling deep link: $e');
    }
  }

  /// الانتقال لتفاصيل عرض صيدلية
  Future<void> _navigateToPharmacyOffer(Map<String, dynamic> data) async {
    final offerId = data['offerId'] as String?;
    final pharmacyId = data['pharmacyId'] as String?;

    if (offerId == null || pharmacyId == null) {
      print('❌ Missing offerId or pharmacyId');
      return;
    }

    try {
      // جلب بيانات العرض
      final offerDoc = await _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('offers')
          .doc(offerId)
          .get();

      if (!offerDoc.exists) {
        print('❌ Offer not found');
        return;
      }

      // الانتقال لصفحة تفاصيل العرض
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushNamed(
          '/pharmacy-offer-details',
          arguments: {
            'offerId': offerId,
            'pharmacyId': pharmacyId,
          },
        );
      }
    } catch (e) {
      print('❌ Error navigating to pharmacy offer: $e');
    }
  }

  /// الانتقال لتفاصيل عرض عيادة
  Future<void> _navigateToClinicOffer(Map<String, dynamic> data) async {
    final offerId = data['offerId'] as String?;

    if (offerId == null) {
      print('❌ Missing offerId');
      return;
    }

    try {
      // جلب بيانات العرض
      final offerDoc = await _firestore
          .collection('clinic_offers')
          .doc(offerId)
          .get();

      if (!offerDoc.exists) {
        print('❌ Clinic offer not found');
        return;
      }

      // الانتقال لصفحة تفاصيل العرض
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushNamed(
          '/clinic-offer-details',
          arguments: {'offerId': offerId},
        );
      }
    } catch (e) {
      print('❌ Error navigating to clinic offer: $e');
    }
  }

  /// الانتقال لتفاصيل عرض دواء
  Future<void> _navigateToMedicineOffer(Map<String, dynamic> data) async {
    final offerId = data['offerId'] as String?;

    if (offerId == null) {
      print('❌ Missing offerId');
      return;
    }

    try {
      // جلب بيانات العرض
      final offerDoc = await _firestore
          .collection('medicine_offers')
          .doc(offerId)
          .get();

      if (!offerDoc.exists) {
        print('❌ Medicine offer not found');
        return;
      }

      // الانتقال لصفحة تفاصيل العرض
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushNamed(
          '/medicine-offer-details',
          arguments: {'offerId': offerId},
        );
      }
    } catch (e) {
      print('❌ Error navigating to medicine offer: $e');
    }
  }

  /// الانتقال لصفحة إدارة الحجوزات (للعيادة)
  Future<void> _navigateToBookingsManagement(Map<String, dynamic> data) async {
    final clinicId = data['clinicId'] as String?;

    if (clinicId == null) {
      print('❌ Missing clinicId');
      return;
    }

    try {
      // جلب بيانات العيادة
      final clinicDoc = await _firestore
          .collection('clinics')
          .doc(clinicId)
          .get();

      if (!clinicDoc.exists) {
        print('❌ Clinic not found');
        return;
      }

      // الانتقال لصفحة إدارة الحجوزات
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushNamed(
          '/bookings-management',
          arguments: {
            'clinicId': clinicId,
            'initialTab': 'pending', // فتح تاب الانتظار مباشرة
          },
        );
      }
    } catch (e) {
      print('❌ Error navigating to bookings management: $e');
    }
  }

  /// الانتقال لتتبع الحجوزات (للمريض)
  Future<void> _navigateToBookingTracking() async {
    if (_context != null && _context!.mounted) {
      // العودة للشاشة الرئيسية حيث يوجد تتبع الحجوزات
      Navigator.of(_context!).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  /// الانتقال لطلبات الأدوية (للصيدليات)
  Future<void> _navigateToMedicineRequests(Map<String, dynamic> data) async {
    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pushNamed('/medicine-requests');
    }
  }

  /// الانتقال لحجوزات المعمل
  Future<void> _navigateToLabBookings(Map<String, dynamic> data) async {
    final laboratoryId = data['laboratoryId'] as String?;

    if (laboratoryId == null) {
      print('❌ Missing laboratoryId');
      return;
    }

    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pushNamed(
        '/lab-bookings-management',
        arguments: {
          'laboratoryId': laboratoryId,
        },
      );
    }
  }
}
