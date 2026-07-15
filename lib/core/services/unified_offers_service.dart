import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clinicalsystem/features/pharmacy/data/models/pharmacy_offer_model.dart';
import 'package:clinicalsystem/features/clinic/data/models/clinic_offer_model.dart';
import '../models/unified_offer_model.dart';
import 'generic_offer_sorting_service.dart';

/// خدمة موحدة لجلب وترتيب العروض من جميع المصادر
/// 
/// 🎯 الاستراتيجية الاحترافية:
/// 1. **جلب متوازي**: جلب من جميع المصادر في نفس الوقت (أسرع)
/// 2. **خلط ذكي**: تنوع المصادر - لن ترى 3 عروض متتالية من نفس المصدر
/// 3. **أولوية للجديد**: العروض الأحدث لها الأولوية
/// 4. **عشوائية محكومة**: كل فتح للتطبيق = ترتيب مختلف، لكن منطقي
/// 5. **تحديث عند Refresh**: سحب للتحديث يغير الترتيب بالكامل
class UnifiedOffersService {
  final GenericOfferSortingService<UnifiedOfferModel> _sortingService =
      GenericOfferSortingService<UnifiedOfferModel>();
  
  // تتبع المصادر المستخدمة مؤخراً لضمان التنوع
  final List<OfferType> _recentSourceTypes = [];
  static const int _maxRecentSources = 3;

  /// جلب العروض من جميع المصادر (صيدليات، عيادات، جيمات، مستلزمات طبية)
  /// مع استراتيجية خلط ذكية
  Future<List<UnifiedOfferModel>> fetchAllOffers({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? specificCollection,
  }) async {
    // جلب من جميع المصادر بشكل متوازي للسرعة
    final futures = <Future<List<UnifiedOfferModel>>>[];

    // ✅ حساب عدد العروض من كل نوع للوصول لـ limit فقط
    // نجلب 3 من كل نوع عشان نضمن التنوع (3×4 = 12)
    // ثم نرجع limit فقط بعد الخلط
    final perSourceLimit = 3;

    // جلب عروض الصيدليات
    if (specificCollection == null || specificCollection == 'offers') {
      futures.add(_fetchPharmacyOffers(limit: perSourceLimit));
    }

    // جلب عروض العيادات
    if (specificCollection == null || specificCollection == 'clinic_offers') {
      futures.add(_fetchClinicOffers(limit: perSourceLimit));
    }

    // جلب عروض الجيم
    if (specificCollection == null || specificCollection == 'gym_offers') {
      futures.add(_fetchGymOffers(limit: perSourceLimit));
    }

    // جلب عروض المستلزمات الطبية
    if (specificCollection == null || specificCollection == 'medical_supply_offers') {
      futures.add(_fetchMedicalSupplyOffers(limit: perSourceLimit));
    }

    // انتظار جلب جميع العروض
    final results = await Future.wait(futures);
    
    // دمج جميع العروض في قائمة واحدة
    final List<UnifiedOfferModel> allOffers = [];
    for (var offersList in results) {
      allOffers.addAll(offersList);
    }

    // خلط ذكي يضمن تنوع المصادر
    final mixed = _smartMixOffers(allOffers);
    
    // ✅ نرجع limit فقط (10 عروض بالظبط)
    return mixed.take(limit).toList();
  }

  /// جلب عروض الصيدليات
  Future<List<UnifiedOfferModel>> _fetchPharmacyOffers({
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final pharmacyOffer = PharmacyOfferModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        return UnifiedOfferModel.fromPharmacy(pharmacyOffer);
      }).toList();
    } catch (e) {
      print('❌ Error fetching pharmacy offers: $e');
      return [];
    }
  }

  /// جلب عروض العيادات
  Future<List<UnifiedOfferModel>> _fetchClinicOffers({
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('clinic_offers')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final clinicOffer = ClinicOfferModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        return UnifiedOfferModel.fromClinic(clinicOffer);
      }).toList();
    } catch (e) {
      print('❌ Error fetching clinic offers: $e');
      return [];
    }
  }

  /// جلب عروض الجيم
  Future<List<UnifiedOfferModel>> _fetchGymOffers({
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('gym_offers')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UnifiedOfferModel(
          offerId: doc.id,
          offerType: OfferType.gym,
          sourceId: data['gymId'] ?? '',
          sourceName: data['gymName'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          notes: data['notes'] ?? '',
          images: List<String>.from(data['images'] ?? []),
          id: doc.id,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          viewsCount: data['viewsCount'] ?? 0,
          category: data['category'] ?? 'عام',
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching gym offers: $e');
      return [];
    }
  }

  /// جلب عروض المستلزمات الطبية
  Future<List<UnifiedOfferModel>> _fetchMedicalSupplyOffers({
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('medical_supply_offers')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UnifiedOfferModel(
          offerId: doc.id,
          offerType: OfferType.medicalSupply,
          sourceId: data['supplyId'] ?? '',
          sourceName: data['supplyName'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          notes: data['notes'] ?? '',
          images: List<String>.from(data['images'] ?? []),
          id: doc.id,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          viewsCount: data['viewsCount'] ?? 0,
          category: data['category'] ?? 'مستلزمات طبية',
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching medical supply offers: $e');
      return [];
    }
  }
  
  /// خلط ذكي للعروض يضمن:
  /// 1. تنوع المصادر (لا تتكرر نفس المصدر 3 مرات متتالية)
  /// 2. أولوية للعروض الأحدث
  /// 3. عشوائية محكومة
  List<UnifiedOfferModel> _smartMixOffers(List<UnifiedOfferModel> offers) {
    if (offers.isEmpty) return [];
    
    // فرز حسب التاريخ أولاً (الأحدث أولاً)
    offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // تقسيم العروض حسب المصدر
    final pharmacyOffers = offers.where((o) => o.offerType == OfferType.pharmacy).toList();
    final clinicOffers = offers.where((o) => o.offerType == OfferType.clinic).toList();
    final gymOffers = offers.where((o) => o.offerType == OfferType.gym).toList();
    final medicalSupplyOffers = offers.where((o) => o.offerType == OfferType.medicalSupply).toList();
    
    // خلط ذكي يضمن التنوع
    final mixed = <UnifiedOfferModel>[];
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    
    int pharmacyIndex = 0;
    int clinicIndex = 0;
    int gymIndex = 0;
    int medicalSupplyIndex = 0;
    
    OfferType? lastType;
    int sameTypeCount = 0;
    
    while (pharmacyIndex < pharmacyOffers.length || 
           clinicIndex < clinicOffers.length || 
           gymIndex < gymOffers.length ||
           medicalSupplyIndex < medicalSupplyOffers.length) {
      
      // قائمة الأنواع المتاحة
      final availableTypes = <OfferType>[];
      if (pharmacyIndex < pharmacyOffers.length) availableTypes.add(OfferType.pharmacy);
      if (clinicIndex < clinicOffers.length) availableTypes.add(OfferType.clinic);
      if (gymIndex < gymOffers.length) availableTypes.add(OfferType.gym);
      if (medicalSupplyIndex < medicalSupplyOffers.length) availableTypes.add(OfferType.medicalSupply);
      
      if (availableTypes.isEmpty) break;
      
      // إذا تكرر نفس النوع 2 مرات، اختر نوع مختلف
      if (lastType != null && sameTypeCount >= 2 && availableTypes.length > 1) {
        availableTypes.remove(lastType);
      }
      
      // اختيار نوع عشوائي من الأنواع المتاحة
      final selectedType = availableTypes[random.nextInt(availableTypes.length)];
      
      // إضافة العرض حسب النوع المختار
      if (selectedType == OfferType.pharmacy && pharmacyIndex < pharmacyOffers.length) {
        mixed.add(pharmacyOffers[pharmacyIndex++]);
      } else if (selectedType == OfferType.clinic && clinicIndex < clinicOffers.length) {
        mixed.add(clinicOffers[clinicIndex++]);
      } else if (selectedType == OfferType.gym && gymIndex < gymOffers.length) {
        mixed.add(gymOffers[gymIndex++]);
      } else if (selectedType == OfferType.medicalSupply && medicalSupplyIndex < medicalSupplyOffers.length) {
        mixed.add(medicalSupplyOffers[medicalSupplyIndex++]);
      }
      
      // تحديث عداد التكرار
      if (selectedType == lastType) {
        sameTypeCount++;
      } else {
        sameTypeCount = 1;
        lastType = selectedType;
      }
    }
    
    return mixed;
  }

  /// ترتيب العروض باستخدام نظام الترتيب الديناميكي
  List<UnifiedOfferModel> sortOffers({
    required List<UnifiedOfferModel> offers,
    required int pageNumber,
    required int pageSize,
  }) {
    return _sortingService.sortOffers(
      offers: offers,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  /// إعادة تعيين تتبع التنوع
  void resetDiversityTracking() {
    _sortingService.resetDiversityTracking();
  }
}
