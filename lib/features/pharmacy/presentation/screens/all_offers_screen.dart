import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/models/unified_offer_model.dart';
import '../../../../core/services/unified_offers_service.dart';
import '../../../../core/widgets/unified_offer_card.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';
import 'package:clinicalsystem/core/widgets/skeleton_cards.dart';

/// شاشة كل العروض من جميع المصادر (صيدليات، عيادات، جيمات) مع نظام ترتيب ديناميكي
class AllOffersScreen extends StatefulWidget {
  const AllOffersScreen({super.key});

  @override
  State<AllOffersScreen> createState() => _AllOffersScreenState();
}

class _AllOffersScreenState extends State<AllOffersScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _topOffersController = ScrollController();
  final UnifiedOffersService _unifiedOffersService = UnifiedOffersService();
  Timer? _topOffersAutoScrollTimer;
  bool _isTopOffersAnimating = false;
  int _lastTopOffersCount = 0;

  // قوائم العروض الموحدة
  final List<UnifiedOfferModel> _allFetchedOffers = [];
  final List<UnifiedOfferModel> _displayedOffers = [];

  bool _isLoading = false;
  bool _hasMore = true;

  // إعدادات التقسيم والجلب
  static const int _fetchBatchSize = 15;
  static const int _displayPageSize = 10;
  int _currentDisplayPage = 0;

  // تتبع العروض التي تمت مشاهدتها
  final Set<String> _viewedOffers = {};

  @override
  void initState() {
    super.initState();
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
      _hasMore = true;
      _currentDisplayPage = 0;
      _unifiedOffersService.resetDiversityTracking();
    });

    await _fetchOffersFromFirestore();
    if (!mounted) return;
    _applySortingAndPagination();
  }

  Future<void> _fetchOffersFromFirestore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      // جلب العروض من جميع المصادر
      final newOffers = await _unifiedOffersService.fetchAllOffers(
        limit: _fetchBatchSize,
      );

      if (newOffers.isEmpty) {
        if (mounted) {
          setState(() {
            _hasMore = false;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _allFetchedOffers.addAll(newOffers);
          _hasMore = newOffers.length == _fetchBatchSize;
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

    final sortedOffers = _unifiedOffersService.sortOffers(
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
  void _markOfferViewed(UnifiedOfferModel offer) {
    if (_viewedOffers.add(offer.id)) {
      UnifiedOfferCard.incrementViewsCount(offer);
    }
  }

  Widget _buildHorizontalTopOffers(List<UnifiedOfferModel> offers) {
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
                  _markOfferViewed(offer);
                  return UnifiedOfferCard(
                    offer: offer,
                    showViewsCount: true, // دايماً true
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

  Widget _buildOffersLoadingSkeleton() {
    final cardWidth = MediaQuery.of(context).size.width * 0.84;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: cardWidth,
                child: const SkeletonHorizontalOfferCard(),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: cardWidth,
                child: const SkeletonHorizontalOfferCard(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SkeletonOfferCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final featuredOffers = _displayedOffers.take(5).toList();
    final verticalOffers = _displayedOffers.length > 5
        ? _displayedOffers.sublist(5)
        : <UnifiedOfferModel>[];
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
                SliverToBoxAdapter(child: _buildOffersLoadingSkeleton())
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
                        _markOfferViewed(offer);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: UnifiedOfferCard(
                            offer: offer,
                            showViewsCount: true, // دايماً true
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
