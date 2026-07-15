import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../widgets/medicine_offer_card.dart';
import '../../data/models/medicine_offer_model.dart';
import '../../../../core/services/offer_sorting_service.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

/// شاشة عروض الأدوية مع نظام ترتيب ديناميكي متقدم
class MedicineOffersScreen extends StatefulWidget {
  const MedicineOffersScreen({super.key});

  @override
  State<MedicineOffersScreen> createState() => _MedicineOffersScreenState();
}

class _MedicineOffersScreenState extends State<MedicineOffersScreen> {
  final ScrollController _scrollController = ScrollController();
  final OfferSortingService _sortingService = OfferSortingService();

  // قوائم العروض
  final List<MedicineOfferModel> _allFetchedOffers =
      []; // كل العروض المجلوبة من Firestore
  final List<MedicineOfferModel> _displayedOffers =
      []; // العروض المعروضة بعد الترتيب والتقسيم

  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  // إعدادات التقسيم والجلب
  static const int _fetchBatchSize = 50; // نجلب 50 عرض في كل مرة
  static const int _displayPageSize = 8; // نعرض 8 عروض في كل صفحة
  int _currentDisplayPage = 0;

  // تتبع العروض التي تمت مشاهدتها (لتجنب زيادة العدد أكتر من مرة)
  final Set<String> _viewedOffers = {};

  @override
  void initState() {
    super.initState();
    _loadInitialOffers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// مراقبة التمرير لتحميل المزيد من العروض
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // إذا وصلنا لآخر العروض المعروضة، نحمل المزيد
      if (!_isLoading) {
        _loadMoreDisplayedOffers();
      }
    }
  }

  /// التحميل الأولي للعروض
  Future<void> _loadInitialOffers() async {
    setState(() {
      _allFetchedOffers.clear();
      _displayedOffers.clear();
      _lastDocument = null;
      _hasMore = true;
      _currentDisplayPage = 0;
      _sortingService.resetDiversityTracking();
    });

    await _fetchOffersFromFirestore();
    _applySortingAndPagination();
  }

  /// جلب دفعة من العروض من Firestore
  Future<void> _fetchOffersFromFirestore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('medicine_offers')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_fetchBatchSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _hasMore = false;
            _isLoading = false;
          });
        }
        return;
      }

      final newOffers = snapshot.docs
          .map(
            (doc) => MedicineOfferModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      if (mounted) {
        setState(() {
          _allFetchedOffers.addAll(newOffers);
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _fetchBatchSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل العروض: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// تطبيق الترتيب الديناميكي والتقسيم على العروض المجلوبة
  void _applySortingAndPagination() {
    if (_allFetchedOffers.isEmpty) {
      setState(() {
        _displayedOffers.clear();
      });
      return;
    }

    // تطبيق الترتيب الديناميكي على كل العروض المجلوبة
    final sortedOffers = _sortingService.sortOffers(
      offers: _allFetchedOffers,
      pageNumber: 0, // نرتب كل العروض مرة واحدة
      pageSize: _allFetchedOffers.length,
    );

    // حساب عدد العروض المطلوب عرضها
    final endIndex = (_currentDisplayPage + 1) * _displayPageSize;
    final displayCount = endIndex > sortedOffers.length
        ? sortedOffers.length
        : endIndex;

    setState(() {
      _displayedOffers.clear();
      _displayedOffers.addAll(sortedOffers.take(displayCount));
    });
  }

  /// تحميل المزيد من العروض المعروضة (للتمرير)
  Future<void> _loadMoreDisplayedOffers() async {
    // إذا عرضنا كل العروض المجلوبة، نجلب دفعة جديدة
    final nextPageEndIndex = (_currentDisplayPage + 2) * _displayPageSize;

    if (nextPageEndIndex >= _allFetchedOffers.length && _hasMore) {
      // نحتاج لجلب المزيد من Firestore
      await _fetchOffersFromFirestore();
      _applySortingAndPagination();
    } else if ((_currentDisplayPage + 1) * _displayPageSize <
        _allFetchedOffers.length) {
      // لدينا عروض كافية، فقط نزيد صفحة العرض
      setState(() {
        _currentDisplayPage++;
      });
      _applySortingAndPagination();
    }
  }

  /// تحديث العروض (سحب للتحديث)
  Future<void> _refreshOffers() async {
    await _loadInitialOffers();
  }

  /// زيادة عدد المشاهدات لعرض معين
  Future<void> _incrementViewsCount(String offerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('medicine_offers')
          .doc(offerId)
          .update({'viewsCount': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('خطأ في زيادة عدد المشاهدات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'عروض الأدوية',
          gradient: AppTheme.clinicGradient,
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Tooltip(
                message: 'الترتيب ديناميكي',
                child: Icon(
                  Icons.shuffle,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _refreshOffers,
            child: _isLoading && _displayedOffers.isEmpty
                ? const Center(
                    child: AppLoadingIndicator(color: AppTheme.secondaryColor),
                  )
                : _displayedOffers.isEmpty && !_hasMore
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 100,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد عروض متاحة حالياً',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'اسحب للأسفل للتحديث',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        _displayedOffers.length +
                        (_isLoading ||
                                (_hasMore &&
                                    (_currentDisplayPage + 1) *
                                            _displayPageSize <
                                        _allFetchedOffers.length)
                            ? 1
                            : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      if (index == _displayedOffers.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: AppLoadingIndicator(
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        );
                      }

                      final offer = _displayedOffers[index];

                      if (!_viewedOffers.contains(offer.id)) {
                        _viewedOffers.add(offer.id);
                        _incrementViewsCount(offer.id);
                      }

                      return MedicineOfferCard(offer: offer);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
