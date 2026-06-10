import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'offer_card.dart';
import '../../data/models/pharmacy_offer_model.dart';
import '../../../../core/services/pharmacy_offer_sorting_service.dart';
import '../../../../core/services/app_control_service.dart';
import '../../../../core/widgets/admin_views_count_toggle.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

/// شاشة كل العروض من جميع الصيدليات مع نظام ترتيب ديناميكي
class AllOffersScreen extends StatefulWidget {
  const AllOffersScreen({super.key});

  @override
  State<AllOffersScreen> createState() => _AllOffersScreenState();
}

class _AllOffersScreenState extends State<AllOffersScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _topOffersController = ScrollController();
  final PharmacyOfferSortingService _sortingService =
      PharmacyOfferSortingService();
  final AppControlService _appControlService = AppControlService();
  Timer? _topOffersAutoScrollTimer;
  bool _isTopOffersAnimating = false;
  int _lastTopOffersCount = 0;

  // قوائم العروض
  final List<PharmacyOfferModel> _allFetchedOffers = [];
  final List<PharmacyOfferModel> _displayedOffers = [];

  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  // إعدادات التقسيم والجلب
  static const int _fetchBatchSize = 10;
  static const int _displayPageSize = 10;
  int _currentDisplayPage = 0;

  // إعدادات العرض
  bool _showViewsCount = false;

  // تتبع العروض التي تمت مشاهدتها (لتجنب زيادة العدد أكتر من مرة)
  final Set<String> _viewedOffers = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadInitialOffers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _topOffersAutoScrollTimer?.cancel();
    _scrollController.dispose();
    _topOffersController.dispose();
    super.dispose();
  }

  void _startTopOffersAutoScroll() {
    _topOffersAutoScrollTimer?.cancel();
    _topOffersAutoScrollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _autoScrollTopOffers(),
    );
  }

  void _syncTopOffersAutoScroll(int offersCount) {
    if (offersCount <= 1) {
      _topOffersAutoScrollTimer?.cancel();
      _topOffersAutoScrollTimer = null;
      _lastTopOffersCount = offersCount;
      return;
    }

    if (_topOffersAutoScrollTimer != null &&
        _lastTopOffersCount == offersCount) {
      return;
    }

    _lastTopOffersCount = offersCount;
    _startTopOffersAutoScroll();
  }

  Future<void> _autoScrollTopOffers() async {
    if (!mounted || _isTopOffersAnimating || !_topOffersController.hasClients) {
      return;
    }

    final maxExtent = _topOffersController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    final current = _topOffersController.offset;
    final step = MediaQuery.sizeOf(context).width * 0.84 + 12;
    double next = current + step;

    // For short horizontal lists (2-3 cards), step can be أكبر من مدى السكرول.
    // In this case we move to the end first, then loop back to start next tick.
    if (next >= maxExtent - 4) {
      next = current >= maxExtent - 4 ? 0.0 : maxExtent;
    }

    _isTopOffersAnimating = true;
    try {
      await _topOffersController.animateTo(
        next,
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _isTopOffersAnimating = false;
    }
  }

  /// تحميل إعدادات العرض من Firestore
  Future<void> _loadSettings() async {
    try {
      final settings = await _appControlService.getOffersSettings();
      if (mounted) {
        setState(() {
          _showViewsCount = settings.showViewsCount;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل الإعدادات: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading) {
        _loadMoreDisplayedOffers();
      }
    }
  }

  /// التحميل الأولي للعروض
  Future<void> _loadInitialOffers() async {
    if (!mounted) return;
    setState(() {
      _allFetchedOffers.clear();
      _displayedOffers.clear();
      _lastDocument = null;
      _hasMore = true;
      _currentDisplayPage = 0;
      _sortingService.resetDiversityTracking();
    });

    await _fetchOffersFromFirestore();
    if (!mounted) return;
    _applySortingAndPagination();
  }

  Future<void> _fetchOffersFromFirestore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('offers')
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
            (doc) => PharmacyOfferModel.fromJson({
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

  /// تطبيق الترتيب الديناميكي والتقسيم
  void _applySortingAndPagination() {
    if (!mounted) return;
    if (_allFetchedOffers.isEmpty) {
      setState(() {
        _displayedOffers.clear();
      });
      return;
    }

    final sortedOffers = _sortingService.sortOffers(
      offers: _allFetchedOffers,
      pageNumber: 0,
      pageSize: _allFetchedOffers.length,
    );

    final endIndex = (_currentDisplayPage + 1) * _displayPageSize;
    final displayCount = endIndex > sortedOffers.length
        ? sortedOffers.length
        : endIndex;

    setState(() {
      _displayedOffers.clear();
      _displayedOffers.addAll(sortedOffers.take(displayCount));
    });
  }

  /// تحميل المزيد من العروض المعروضة
  Future<void> _loadMoreDisplayedOffers() async {
    final nextPageEndIndex = (_currentDisplayPage + 2) * _displayPageSize;

    if (nextPageEndIndex >= _allFetchedOffers.length && _hasMore) {
      await _fetchOffersFromFirestore();
      if (!mounted) return;
      _applySortingAndPagination();
    } else if ((_currentDisplayPage + 1) * _displayPageSize <
        _allFetchedOffers.length) {
      if (!mounted) return;
      setState(() {
        _currentDisplayPage++;
      });
      _applySortingAndPagination();
    }
  }

  Future<void> _refreshOffers() async {
    await _loadInitialOffers();
  }

  /// زيادة عدد المشاهدات
  Future<void> _incrementViewsCount(String offerId) async {
    try {
      await FirebaseFirestore.instance.collection('offers').doc(offerId).update(
        {'viewsCount': FieldValue.increment(1)},
      );
    } catch (e) {
      debugPrint('خطأ في زيادة عدد المشاهدات: $e');
    }
  }

  void _markOfferViewed(String offerId) {
    if (_viewedOffers.add(offerId)) {
      _incrementViewsCount(offerId);
    }
  }

  Widget _buildHorizontalTopOffers(List<PharmacyOfferModel> offers) {
    return SingleChildScrollView(
      controller: _topOffersController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int index = 0; index < offers.length; index++) ...[
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.84,
              child: Builder(
                builder: (context) {
                  final offer = offers[index];
                  _markOfferViewed(offer.id);
                  return OfferCard(
                    offerId: offer.id,
                    pharmacyId: offer.pharmacyId,
                    pharmacyName: offer.pharmacyName,
                    title: offer.title,
                    description: offer.description,
                    notes: offer.notes,
                    images: offer.images,
                    createdAt: offer.createdAt,
                    isOwnerView: false,
                    isActive: offer.isActive,
                    showViewsCount: _showViewsCount,
                    viewsCount: offer.viewsCount,
                    category: offer.category,
                  );
                },
              ),
            ),
            if (index != offers.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featuredOffers = _displayedOffers.take(5).toList();
    final verticalOffers = _displayedOffers.length > 5
        ? _displayedOffers.sublist(5)
        : <PharmacyOfferModel>[];
    final showBottomLoader =
        _hasMore ||
        (_currentDisplayPage + 1) * _displayPageSize < _allFetchedOffers.length;
    _syncTopOffersAutoScroll(featuredOffers.length);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: _refreshOffers,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: false,
                pinned: true,
                toolbarHeight: 62,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF0F172A),
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'العروض والخصومات',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                centerTitle: true,
                actions: [
                  const AdminViewsCountToggle(displayType: 'icon'),
                  IconButton(
                    tooltip: 'الترتيب ديناميكي',
                    onPressed: null,
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: Colors.teal.shade700,
                      size: 20,
                    ),
                  ),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),
              ),

              if (_isLoading && _displayedOffers.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: AppLoadingIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                )
              else if (_displayedOffers.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_offer_outlined,
                              size: 72,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'لا توجد عروض متاحة حالياً',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'تابع الصيدليات لمعرفة العروض الجديدة',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                if (featuredOffers.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildHorizontalTopOffers(featuredOffers),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == verticalOffers.length) {
                          return showBottomLoader
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00BCD4,
                                            ).withOpacity(0.1),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const AppLoadingIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF00BCD4),
                                            ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final offer = verticalOffers[index];
                        _markOfferViewed(offer.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OfferCard(
                            offerId: offer.id,
                            pharmacyId: offer.pharmacyId,
                            pharmacyName: offer.pharmacyName,
                            title: offer.title,
                            description: offer.description,
                            notes: offer.notes,
                            images: offer.images,
                            createdAt: offer.createdAt,
                            isOwnerView: false,
                            isActive: offer.isActive,
                            showViewsCount: _showViewsCount,
                            viewsCount: offer.viewsCount,
                            category: offer.category,
                          ),
                        );
                      },
                      childCount:
                          verticalOffers.length + (showBottomLoader ? 1 : 0),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
