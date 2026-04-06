import '../../features/pharmacy/data/models/pharmacy_offer_model.dart';
import 'generic_offer_sorting_service.dart';

/// خدمة الترتيب الديناميكي لعروض الصيدليات (PharmacyOfferModel)
///
/// Wrapper حول GenericOfferSortingService لسهولة الاستخدام
/// مع تخصيص لنوع PharmacyOfferModel
class PharmacyOfferSortingService {
  final GenericOfferSortingService<PharmacyOfferModel> _genericService;

  PharmacyOfferSortingService()
    : _genericService = GenericOfferSortingService<PharmacyOfferModel>();

  /// ترتيب عروض الصيدليات بنظام التصنيف الديناميكي
  List<PharmacyOfferModel> sortOffers({
    required List<PharmacyOfferModel> offers,
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
