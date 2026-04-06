import '../../features/medicine_offers/data/models/medicine_offer_model.dart';
import 'generic_offer_sorting_service.dart';

/// خدمة الترتيب الديناميكي لعروض الأدوية (MedicineOfferModel)
///
/// Wrapper حول GenericOfferSortingService لسهولة الاستخدام
/// مع تخصيص لنوع MedicineOfferModel
class OfferSortingService {
  final GenericOfferSortingService<MedicineOfferModel> _genericService;

  OfferSortingService()
    : _genericService = GenericOfferSortingService<MedicineOfferModel>();

  /// ترتيب عروض الأدوية بنظام التصنيف الديناميكي
  List<MedicineOfferModel> sortOffers({
    required List<MedicineOfferModel> offers,
    required int pageNumber,
    required int pageSize,
  }) {
    return _genericService.sortOffers(
      offers: offers,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  /// إعادة تعيين عدادات التنوع
  void resetDiversityTracking() {
    _genericService.resetDiversityTracking();
  }
}
