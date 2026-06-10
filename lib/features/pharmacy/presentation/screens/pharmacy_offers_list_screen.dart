import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/pharmacy_offer_model.dart';
import 'offer_card.dart';
import '../../../../core/services/pharmacy_offer_sorting_service.dart';
import '../../../../core/services/app_control_service.dart';
import '../../../../core/widgets/admin_views_count_toggle.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

/// شاشة عروض الصيدلية مع نظام ترتيب ديناميكي متقدم
class PharmacyOffersListScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  // Theme colors
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0B8293), Color(0xFF179AAC)],
  );

  const PharmacyOffersListScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
  });

  @override
  State<PharmacyOffersListScreen> createState() =>
      _PharmacyOffersListScreenState();
}

class _PharmacyOffersListScreenState extends State<PharmacyOffersListScreen> {
  final ScrollController _scrollController = ScrollController();
  final PharmacyOfferSortingService _sortingService =
      PharmacyOfferSortingService();
  final AppControlService _appControlService = AppControlService();

  // قوائم العروض
  final List<PharmacyOfferModel> _allFetchedOffers =
      []; // كل العروض المجلوبة من Firestore
  final List<PharmacyOfferModel> _displayedOffers =
      []; // العروض المعروضة بعد الترتيب

  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  // إعدادات التقسيم والجلب
  static const int _fetchBatchSize = 50; // نجلب 50 عرض في كل مرة
  static const int _displayPageSize = 8; // نعرض 8 عروض في كل صفحة
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
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _fetchOffersFromFirestore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('offers')
          .where('pharmacyId', isEqualTo: widget.pharmacyId)
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
      pageNumber: 0,
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
    final nextPageEndIndex = (_currentDisplayPage + 2) * _displayPageSize;

    if (nextPageEndIndex >= _allFetchedOffers.length && _hasMore) {
      await _fetchOffersFromFirestore();
      _applySortingAndPagination();
    } else if ((_currentDisplayPage + 1) * _displayPageSize <
        _allFetchedOffers.length) {
      setState(() {
        _currentDisplayPage++;
      });
      _applySortingAndPagination();
    }
  }

  Future<void> _refreshOffers() async {
    await _loadInitialOffers();
  }

  /// زيادة عدد المشاهدات لعرض معين
  Future<void> _incrementViewsCount(String offerId) async {
    try {
      await FirebaseFirestore.instance.collection('offers').doc(offerId).update(
        {'viewsCount': FieldValue.increment(1)},
      );
    } catch (e) {
      debugPrint('خطأ في زيادة عدد المشاهدات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user's pharmacy ID if authenticated
    final authState = context.read<AuthCubit>().state;
    String? currentUserPharmacyId;
    if (authState is Authenticated && authState.user.isPharmacyOwner) {
      currentUserPharmacyId = authState.user.pharmacyId;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: PharmacyOffersListScreen._backgroundColor,
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
                title: Text(
                  'عرض جميع العروض',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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
                      color: PharmacyOffersListScreen._primaryColor,
                      size: 20,
                    ),
                  ),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                sliver: _isLoading && _displayedOffers.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PharmacyOffersListScreen
                                          ._primaryColor
                                          .withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const AppLoadingIndicator(
                                  color: PharmacyOffersListScreen._primaryColor,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'جاري تحميل العروض...',
                                style: TextStyle(
                                  color:
                                      PharmacyOffersListScreen._textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _displayedOffers.isEmpty && !_hasMore
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == _displayedOffers.length) {
                              return (_isLoading ||
                                      (_hasMore &&
                                          (_currentDisplayPage + 1) *
                                                  _displayPageSize <
                                              _allFetchedOffers.length))
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFDCE6EF),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: PharmacyOffersListScreen
                                                    ._primaryColor
                                                    .withOpacity(0.08),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const AppLoadingIndicator(
                                            color: PharmacyOffersListScreen
                                                ._primaryColor,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }

                            final offer = _displayedOffers[index];
                            final isOwner =
                                currentUserPharmacyId == widget.pharmacyId &&
                                widget.pharmacyId.isNotEmpty;

                            // زيادة عدد المشاهدات تلقائياً عند ظهور العرض
                            if (!_viewedOffers.contains(offer.id)) {
                              _viewedOffers.add(offer.id);
                              // زيادة العدد في الخلفية (fire and forget)
                              _incrementViewsCount(offer.id);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: OfferCard(
                                pharmacyId: widget.pharmacyId,
                                pharmacyName: widget.pharmacyName,
                                offerId: offer.id,
                                title: offer.title,
                                description: offer.description,
                                notes: offer.notes,
                                images: offer.images,
                                createdAt: offer.createdAt,
                                isOwnerView: isOwner,
                                isActive: offer.isActive,
                                showViewsCount: _showViewsCount,
                                viewsCount: offer.viewsCount,
                                category: offer.category,
                              ),
                            );
                          },
                          childCount:
                              _displayedOffers.length +
                              ((_isLoading ||
                                      (_hasMore &&
                                          (_currentDisplayPage + 1) *
                                                  _displayPageSize <
                                              _allFetchedOffers.length))
                                  ? 1
                                  : 0),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDE7EF)),
                boxShadow: [
                  BoxShadow(
                    color: PharmacyOffersListScreen._primaryColor.withOpacity(
                      0.08,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 80,
                color: PharmacyOffersListScreen._textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد عروض حالياً',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: PharmacyOffersListScreen._textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'سيتم عرض العروض هنا عند إضافتها',
              style: TextStyle(
                fontSize: 13,
                color: PharmacyOffersListScreen._textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
