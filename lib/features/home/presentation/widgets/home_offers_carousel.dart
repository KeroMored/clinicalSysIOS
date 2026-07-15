import 'dart:async';

import 'package:flutter/material.dart';

import '../../../pharmacy/presentation/screens/offer_details_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';
import 'package:clinicalsystem/core/widgets/skeleton_cards.dart';
import 'package:clinicalsystem/core/models/unified_offer_model.dart';
import 'package:clinicalsystem/core/services/unified_offers_service.dart';

enum _OfferSourceType { pharmacy, clinic, gym, medicalSupply }

// استراتيجية جديدة: 10 عروض من جميع المصادر (صيدليات + عيادات + جيم)
const int _dailyTotalOffersCount = 10;

class HomeMixedOffersCarousel extends StatefulWidget {
  const HomeMixedOffersCarousel({super.key});

  @override
  State<HomeMixedOffersCarousel> createState() =>
      _HomeMixedOffersCarouselState();
}

class _HomeMixedOffersCarouselState extends State<HomeMixedOffersCarousel> {
  late Future<List<_HomeOfferItem>> _offersFuture;
  final UnifiedOffersService _offersService = UnifiedOffersService();

  @override
  void initState() {
    super.initState();
    _offersFuture = _loadDailyOffers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// تحميل العروض باستخدام الاستراتيجية الذكية الموحدة
  Future<List<_HomeOfferItem>> _loadDailyOffers() async {
    try {
      // جلب العروض من جميع المصادر باستخدام الخدمة الموحدة
      final unifiedOffers = await _offersService.fetchAllOffers(
        limit: _dailyTotalOffersCount * 2, // جلب ضعف العدد ثم اختيار الأفضل
      );

      // ترتيب العروض باستخدام النظام الديناميكي
      final sortedOffers = _offersService.sortOffers(
        offers: unifiedOffers,
        pageNumber: 0,
        pageSize: _dailyTotalOffersCount,
      );

      // تحويل من UnifiedOfferModel إلى _HomeOfferItem
      return sortedOffers.take(_dailyTotalOffersCount).map((offer) {
        return _HomeOfferItem(
          id: offer.id,
          sourceType: _mapOfferType(offer.offerType),
          title: offer.title,
          subtitle: offer.sourceName,
          description: offer.description,
          imageUrl: offer.images.isNotEmpty ? offer.images.first : '',
          images: offer.images,
          pharmacyId: offer.offerType == OfferType.pharmacy ? offer.sourceId : null,
          clinicId: offer.offerType == OfferType.clinic ? offer.sourceId : null,
          gymId: offer.offerType == OfferType.gym ? offer.sourceId : null,
          medicalSupplyId: offer.offerType == OfferType.medicalSupply ? offer.sourceId : null,
          notes: offer.notes,
          category: offer.category,
          oldPrice: null, // يمكن إضافة دعم السعر لاحقاً
          newPrice: null,
          discountPercentage: null,
          createdAt: offer.createdAt,
        );
      }).toList();
    } catch (e) {
      print('❌ Error loading daily offers: $e');
      return [];
    }
  }

  /// تحويل نوع العرض من UnifiedOfferModel إلى النوع المحلي
  _OfferSourceType _mapOfferType(OfferType type) {
    switch (type) {
      case OfferType.pharmacy:
        return _OfferSourceType.pharmacy;
      case OfferType.clinic:
        return _OfferSourceType.clinic;
      case OfferType.gym:
        return _OfferSourceType.gym;
      case OfferType.medicalSupply:
        return _OfferSourceType.medicalSupply;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_HomeOfferItem>>(
      future: _offersFuture,
      builder: (context, snapshot) {
        final mixed = snapshot.data ?? const <_HomeOfferItem>[];

        if (snapshot.connectionState == ConnectionState.waiting &&
            mixed.isEmpty) {
          return const _HomeOffersLoading(title: 'العروض والخصومات');
        }

        if (mixed.isEmpty) {
          return const SizedBox.shrink();
        }

        return _HomeOffersCarousel(
          offers: mixed,
          onOfferTap: (offer) {
            // فتح صفحة التفاصيل الموحدة لجميع أنواع العروض
            String collectionName = '';
            if (offer.sourceType == _OfferSourceType.pharmacy) {
              collectionName = 'offers';
            } else if (offer.sourceType == _OfferSourceType.clinic) {
              collectionName = 'clinic_offers';
            } else if (offer.sourceType == _OfferSourceType.gym) {
              collectionName = 'gym_offers';
            } else if (offer.sourceType == _OfferSourceType.medicalSupply) {
              collectionName = 'medical_supply_offers';
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OfferDetailsScreen(
                  offerId: offer.id,
                  collectionName: collectionName,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeOffersCarousel extends StatefulWidget {
  final List<_HomeOfferItem> offers;
  final void Function(_HomeOfferItem offer) onOfferTap;

  const _HomeOffersCarousel({required this.offers, required this.onOfferTap});

  @override
  State<_HomeOffersCarousel> createState() => _HomeOffersCarouselState();
}

class _HomeOffersCarouselState extends State<_HomeOffersCarousel> {
  static const int _initialPage = 1000;
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = _initialPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.88,
    );
    _syncAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _HomeOffersCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offers.length != widget.offers.length) {
      _syncAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _syncAutoScroll() {
    _stopAutoScroll();
    if (widget.offers.length <= 1) {
      return;
    }

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) {
        return;
      }

      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 300,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _stopAutoScroll();
              } else if (notification is ScrollEndNotification) {
                _syncAutoScroll();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.offers.length > 1 ? null : 1,
              onPageChanged: (value) {
                _currentPage = value;
              },
              itemBuilder: (context, index) {
                final offer = widget.offers[index % widget.offers.length];
                
                // تحديد اللون حسب المصدر
                final sourceColor = offer.sourceType == _OfferSourceType.pharmacy
                    ? const Color(0xFF0B7285)
                    : offer.sourceType == _OfferSourceType.clinic
                        ? const Color(0xFF0B8293)
                        : const Color(0xFFEA580C);
                
                // تحديد gradient التحميل حسب المصدر
                final imageLoadingGradient = offer.sourceType == _OfferSourceType.pharmacy
                    ? const [Color(0xFFF5FAF9), Color(0xFFE6F0EE)]
                    : offer.sourceType == _OfferSourceType.clinic
                        ? const [Color(0xFFE0F2F1), Color(0xFFB2DFDB)]
                        : const [Color(0xFFFFF4EC), Color(0xFFFFE7D4)];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => widget.onOfferTap(offer),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.merge(
                          Border(
                            right: BorderSide(color: Colors.teal, width: 0.5),
                          ),
                          Border(
                            bottom: BorderSide(color: Colors.teal, width: 1.5),
                          ),
                        ),
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                child: Container(
                                  height: 178,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: imageLoadingGradient,
                                    ),
                                  ),
                                  child: offer.imageUrl.isNotEmpty
                                      ? Image.network(
                                          offer.imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }

                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: imageLoadingGradient,
                                                ),
                                              ),
                                              child: Center(
                                                child: AppLoadingIndicator(
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                  strokeWidth: 2.4,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(sourceColor),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              _OfferImagePlaceholder(
                                                sourceType: offer.sourceType,
                                              ),
                                        )
                                      : _OfferImagePlaceholder(
                                          sourceType: offer.sourceType,
                                        ),
                                ),
                              ),
                              if (offer.discountPercentage != null)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB91C1C),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      'خصم %${offer.discountPercentage!.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offer.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  // const SizedBox(height: 4),
                                  // Text(
                                  //   offer.subtitle,
                                  //   maxLines: 1,
                                  //   overflow: TextOverflow.ellipsis,
                                  //   style: TextStyle(
                                  //     color: sourceColor,
                                  //     fontSize: 12,
                                  //     fontWeight: FontWeight.w800,
                                  //   ),
                                  // ),
                                  const SizedBox(height: 3),
                                  Text(
                                    offer.description.isEmpty
                                        ? 'العرض متاح الآن'
                                        : offer.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _OfferPriceText(
                                          offer: offer,
                                          sourceColor: sourceColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: sourceColor,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            'تسوق',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeOffersLoading extends StatelessWidget {
  final String title;

  const _HomeOffersLoading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        const SkeletonHorizontalOfferCard(),
      ],
    );
  }
}

class _HomeOfferItem {
  final String id;
  final _OfferSourceType sourceType;
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final List<String> images;
  final String? pharmacyId;
  final String? clinicId; // إضافة دعم العيادات
  final String? gymId;
  final String? medicalSupplyId; // إضافة دعم المستلزمات الطبية
  final String notes;
  final String category;
  final double? oldPrice;
  final double? newPrice;
  final double? discountPercentage;
  final DateTime? createdAt;

  const _HomeOfferItem({
    required this.id,
    required this.sourceType,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.images,
    this.pharmacyId,
    this.clinicId, // إضافة كمعامل اختياري
    this.gymId,
    this.medicalSupplyId, // إضافة كمعامل اختياري
    required this.notes,
    required this.category,
    this.oldPrice,
    this.newPrice,
    this.discountPercentage,
    this.createdAt,
  });
}

class _OfferImagePlaceholder extends StatelessWidget {
  final _OfferSourceType sourceType;

  const _OfferImagePlaceholder({required this.sourceType});

  @override
  Widget build(BuildContext context) {
    final icon = sourceType == _OfferSourceType.pharmacy
        ? Icons.medication_rounded
        : sourceType == _OfferSourceType.clinic
            ? Icons.local_hospital_rounded
            : sourceType == _OfferSourceType.medicalSupply
                ? Icons.medical_services_rounded
                : Icons.fitness_center_rounded;
    final label = sourceType == _OfferSourceType.pharmacy
        ? 'عرض صيدلية'
        : sourceType == _OfferSourceType.clinic
            ? 'عرض عيادة'
            : sourceType == _OfferSourceType.medicalSupply
                ? 'عرض مستلزمات طبية'
                : 'عرض جيم';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _OfferPatternPainter()),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: const Color(0xFFFF6B6B), size: 34),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFE11D48),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferPriceText extends StatelessWidget {
  final _HomeOfferItem offer;
  final Color sourceColor;

  const _OfferPriceText({required this.offer, required this.sourceColor});

  String _format(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final oldPrice = offer.oldPrice;
    final newPrice = offer.newPrice;

    if (newPrice == null && oldPrice == null) {
      return Text(
        offer.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: sourceColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final shownNew = newPrice ?? oldPrice!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (oldPrice != null && shownNew < oldPrice)
          Text(
            'ج.م ${_format(oldPrice)}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          'ج.م ${_format(shownNew)}',
          style: TextStyle(
            color: sourceColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OfferPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    const spacing = 36.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
