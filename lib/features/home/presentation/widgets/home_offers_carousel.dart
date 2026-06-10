import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../gym/presentation/pages/gym_offer_detail_screen.dart';
import '../../../pharmacy/presentation/screens/pharmacy_offer_detail_screen.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

enum _OfferSourceType { pharmacy, gym }

const int _dailyPharmacyOffersCount = 8;
const int _dailyGymOffersCount = 2;
const int _dailyTotalOffersCount =
    _dailyPharmacyOffersCount + _dailyGymOffersCount;
const int _dailyPharmacyOffersFetchLimit = 8;
const int _dailyGymContentFetchLimit = 4;

class HomeMixedOffersCarousel extends StatefulWidget {
  const HomeMixedOffersCarousel({super.key});

  @override
  State<HomeMixedOffersCarousel> createState() =>
      _HomeMixedOffersCarouselState();
}

class _HomeMixedOffersCarouselState extends State<HomeMixedOffersCarousel> {
  late Future<List<_HomeOfferItem>> _offersFuture;
  final Map<String, String> _gymNamesCache = {};

  @override
  void initState() {
    super.initState();
    _offersFuture = _loadDailyOffers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  int _stableHash(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  int _daysSinceRotationEpoch(DateTime now) {
    final utcDate = DateTime.utc(now.year, now.month, now.day);
    final epoch = DateTime.utc(2024, 1, 1);
    return utcDate.difference(epoch).inDays;
  }

  DateTime? _extractCreatedAt(Map<String, dynamic> data) {
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  double _offerQualityScore(_HomeOfferItem offer, DateTime now) {
    final createdAt = offer.createdAt;
    final ageDays = createdAt == null ? 365 : now.difference(createdAt).inDays;
    final freshnessScore = (30 - ageDays).clamp(0, 30).toDouble();
    final discountScore = (offer.discountPercentage ?? 0).clamp(0, 90);
    final hasImageBonus = offer.imageUrl.isNotEmpty ? 8.0 : 0.0;
    final hasPriceBonus = (offer.oldPrice != null || offer.newPrice != null)
        ? 4.0
        : 0.0;
    final validSavingBonus =
        (offer.oldPrice != null &&
            offer.newPrice != null &&
            offer.newPrice! < offer.oldPrice!)
        ? 5.0
        : 0.0;

    return (freshnessScore * 1.6) +
        discountScore +
        hasImageBonus +
        hasPriceBonus +
        validSavingBonus;
  }

  List<_HomeOfferItem> _pickDailyItems(List<_HomeOfferItem> source, int count) {
    if (source.isEmpty || count <= 0) {
      return const [];
    }

    final now = DateTime.now();
    final ranked = [...source]
      ..sort((a, b) {
        final scoreA = _offerQualityScore(a, now);
        final scoreB = _offerQualityScore(b, now);

        final byScore = scoreB.compareTo(scoreA);
        if (byScore != 0) {
          return byScore;
        }

        return _stableHash(a.id).compareTo(_stableHash(b.id));
      });

    if (ranked.length <= count) {
      return ranked;
    }

    final rotationPoolSize = math.min(
      ranked.length,
      math.max(count * 2, count),
    );
    final rotationPool = ranked.take(rotationPoolSize).toList();
    final startIndex =
        (_daysSinceRotationEpoch(now) * count) % rotationPool.length;

    return List<_HomeOfferItem>.generate(
      count,
      (index) => rotationPool[(startIndex + index) % rotationPool.length],
    );
  }

  _HomeOfferItem? _mapPharmacyOfferDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = (data['title']?.toString() ?? '').trim();
    if (title.isEmpty) {
      return null;
    }

    final images = (data['images'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final imageUrl = images.isNotEmpty
        ? images.first
        : (data['imageUrl']?.toString() ?? '');
    final normalizedImageUrl = imageUrl.trim();
    final normalizedImages = images.isNotEmpty
        ? images
        : (normalizedImageUrl.isNotEmpty
              ? <String>[normalizedImageUrl]
              : const <String>[]);
    final discount = _extractPercent(data, const [
      'discountPercentage',
      'discount',
    ]);
    final oldPrice = _extractPrice(data, const [
      'oldPrice',
      'priceBefore',
      'beforePrice',
      'listPrice',
    ]);
    var newPrice = _extractPrice(data, const [
      'newPrice',
      'priceAfter',
      'afterPrice',
      'price',
      'offerPrice',
    ]);

    if (newPrice == null && oldPrice != null && discount != null) {
      newPrice = oldPrice * (1 - (discount / 100));
    }

    final safeOldPrice = oldPrice;
    final safeNewPrice =
        (newPrice != null && safeOldPrice != null && newPrice > safeOldPrice)
        ? safeOldPrice
        : newPrice;

    return _HomeOfferItem(
      id: doc.id,
      sourceType: _OfferSourceType.pharmacy,
      title: title,
      subtitle: (data['pharmacyName']?.toString() ?? 'صيدلية').trim(),
      description: (data['description']?.toString() ?? '').trim(),
      imageUrl: normalizedImageUrl,
      images: normalizedImages,
      pharmacyId: (data['pharmacyId']?.toString() ?? '').trim(),
      notes: (data['notes']?.toString() ?? '').trim(),
      category: (data['category']?.toString() ?? 'عام').trim(),
      oldPrice: safeOldPrice,
      newPrice: safeNewPrice,
      discountPercentage: discount,
      gymId: null,
      createdAt: _extractCreatedAt(data),
    );
  }

  Future<List<_HomeOfferItem>> _buildGymOffersFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> gymOfferDocs,
  ) async {
    if (gymOfferDocs.isEmpty) {
      return const [];
    }

    final gymIds = gymOfferDocs
        .map((doc) => (doc.data()['gymId']?.toString() ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final missingIds = gymIds.where((id) => !_gymNamesCache.containsKey(id));
    if (missingIds.isNotEmpty) {
      final gymDocs = await Future.wait(
        missingIds.map(
          (id) => FirebaseFirestore.instance.collection('gyms').doc(id).get(),
        ),
      );

      for (final gymDoc in gymDocs) {
        if (!gymDoc.exists) {
          _gymNamesCache[gymDoc.id] = 'جيم';
          continue;
        }

        final gymData = gymDoc.data();
        final gymName = (gymData?['name']?.toString() ?? 'جيم').trim();
        _gymNamesCache[gymDoc.id] = gymName.isEmpty ? 'جيم' : gymName;
      }
    }

    return gymOfferDocs.map((doc) {
      final data = doc.data();
      final gymId = (data['gymId']?.toString() ?? '').trim();
      final gymName = gymId.isNotEmpty
          ? (_gymNamesCache[gymId] ?? 'جيم')
          : 'جيم';
      final discount = _extractPercent(data, const [
        'discountPercentage',
        'discount',
      ]);
      final mediaUrl = (data['mediaUrl']?.toString() ?? '').trim();
      final oldPrice = _extractPrice(data, const [
        'oldPrice',
        'priceBefore',
        'beforePrice',
        'listPrice',
      ]);
      var newPrice = _extractPrice(data, const [
        'newPrice',
        'priceAfter',
        'afterPrice',
        'price',
        'offerPrice',
      ]);

      if (newPrice == null && oldPrice != null && discount != null) {
        newPrice = oldPrice * (1 - (discount / 100));
      }

      return _HomeOfferItem(
        id: doc.id,
        sourceType: _OfferSourceType.gym,
        title: (data['title']?.toString() ?? 'عرض جيم').trim(),
        subtitle: gymName,
        description: (data['description']?.toString() ?? '').trim(),
        imageUrl: mediaUrl,
        images: mediaUrl.isNotEmpty ? <String>[mediaUrl] : const <String>[],
        pharmacyId: null,
        notes: '',
        category: 'عروض الجيم',
        oldPrice: oldPrice,
        newPrice: newPrice,
        discountPercentage: discount,
        gymId: gymId,
        createdAt: _extractCreatedAt(data),
      );
    }).toList();
  }

  Future<List<_HomeOfferItem>> _fetchPharmacyOffers() async {
    final query = FirebaseFirestore.instance
        .collection('offers')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(_dailyPharmacyOffersFetchLimit);
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await query.get();
    } catch (_) {
      snapshot = await query.get(const GetOptions(source: Source.cache));
    }

    return snapshot.docs
        .map(_mapPharmacyOfferDoc)
        .whereType<_HomeOfferItem>()
        .toList();
  }

  Future<List<_HomeOfferItem>> _fetchGymOffers() async {
    final gymContentQuery = FirebaseFirestore.instance
        .collection('gym_content')
        .orderBy('createdAt', descending: true)
        .limit(_dailyGymContentFetchLimit);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await gymContentQuery.get();
    } catch (_) {
      snapshot = await gymContentQuery.get(
        const GetOptions(source: Source.cache),
      );
    }

    final gymOfferDocs = snapshot.docs.where((doc) {
      final type = (doc.data()['type']?.toString() ?? '').trim().toLowerCase();
      return type == 'offer';
    }).toList();

    if (gymOfferDocs.isEmpty) {
      return [];
    }

    return _buildGymOffersFromDocs(gymOfferDocs);
  }

  Future<List<_HomeOfferItem>> _loadDailyOffers() async {
    final pharmacyOffers = await _fetchPharmacyOffers();
    final gymOffers = await _fetchGymOffers();

    final selectedPharmacy = _pickDailyItems(
      pharmacyOffers,
      _dailyPharmacyOffersCount,
    );
    final selectedGym = _pickDailyItems(gymOffers, _dailyGymOffersCount);

    final mixed = _buildMixedOffers(
      pharmacyOffers: selectedPharmacy,
      gymOffers: selectedGym,
    );
    return mixed;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_HomeOfferItem>>(
      future: _offersFuture,
      builder: (context, snapshot) {
        final mixed = snapshot.data ?? const <_HomeOfferItem>[];

        if (snapshot.connectionState == ConnectionState.waiting &&
            mixed.isEmpty) {
          return const _HomeOffersLoading(title: 'عروض الصيدليات والجيم');
        }

        if (mixed.isEmpty) {
          return const SizedBox.shrink();
        }

        return _HomeOffersCarousel(
          offers: mixed,
          onOfferTap: (offer) {
            if (offer.sourceType == _OfferSourceType.pharmacy) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PharmacyOfferDetailScreen(
                    offerId: offer.id,
                    pharmacyId: offer.pharmacyId ?? '',
                    pharmacyName: offer.subtitle,
                    title: offer.title,
                    description: offer.description,
                    notes: offer.notes,
                    images: offer.images,
                    createdAt: offer.createdAt,
                    category: offer.category.isEmpty ? 'عام' : offer.category,
                    discountPercentage: offer.discountPercentage,
                  ),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GymOfferDetailScreen(
                  offerId: offer.id,
                  gymId: offer.gymId ?? '',
                  gymName: offer.subtitle,
                  title: offer.title,
                  description: offer.description,
                  imageUrl: offer.imageUrl,
                  createdAt: offer.createdAt,
                  discountPercentage: offer.discountPercentage,
                  oldPrice: offer.oldPrice,
                  newPrice: offer.newPrice,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

List<_HomeOfferItem> _buildMixedOffers({
  required List<_HomeOfferItem> pharmacyOffers,
  required List<_HomeOfferItem> gymOffers,
}) {
  final pharmacyBatch = pharmacyOffers.take(_dailyPharmacyOffersCount).toList();
  final gymBatch = gymOffers.take(_dailyGymOffersCount).toList();
  final mixed = <_HomeOfferItem>[];

  int pharmacyIndex = 0;
  int gymIndex = 0;

  const layoutPattern = <_OfferSourceType>[
    _OfferSourceType.pharmacy,
    _OfferSourceType.pharmacy,
    _OfferSourceType.pharmacy,
    _OfferSourceType.pharmacy,
    _OfferSourceType.gym,
    _OfferSourceType.pharmacy,
    _OfferSourceType.pharmacy,
    _OfferSourceType.pharmacy,
    _OfferSourceType.gym,
    _OfferSourceType.pharmacy,
  ];

  for (final slot in layoutPattern) {
    if (slot == _OfferSourceType.pharmacy) {
      if (pharmacyIndex < pharmacyBatch.length) {
        mixed.add(pharmacyBatch[pharmacyIndex++]);
      } else if (gymIndex < gymBatch.length) {
        mixed.add(gymBatch[gymIndex++]);
      }
      continue;
    }

    if (gymIndex < gymBatch.length) {
      mixed.add(gymBatch[gymIndex++]);
    } else if (pharmacyIndex < pharmacyBatch.length) {
      mixed.add(pharmacyBatch[pharmacyIndex++]);
    }
  }

  if (mixed.length < _dailyTotalOffersCount) {
    for (final offer in pharmacyOffers.skip(_dailyPharmacyOffersCount)) {
      if (mixed.length == _dailyTotalOffersCount) break;
      mixed.add(offer);
    }
  }

  if (mixed.length < _dailyTotalOffersCount) {
    for (final offer in gymOffers.skip(_dailyGymOffersCount)) {
      if (mixed.length == _dailyTotalOffersCount) break;
      mixed.add(offer);
    }
  }

  return mixed;
}

double? _extractPrice(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final raw = data[key];
    if (raw is num) {
      return raw.toDouble();
    }

    if (raw is String) {
      final normalized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
      final parsed = double.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}

double? _extractPercent(Map<String, dynamic> data, List<String> keys) {
  final percent = _extractPrice(data, keys);
  if (percent == null || percent <= 0 || percent >= 100) {
    return null;
  }
  return percent;
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
                final sourceColor =
                    offer.sourceType == _OfferSourceType.pharmacy
                    ? const Color(0xFF0B7285)
                    : const Color(0xFFEA580C);
                final imageLoadingGradient =
                    offer.sourceType == _OfferSourceType.pharmacy
                    ? const [Color(0xFFF5FAF9), Color(0xFFE6F0EE)]
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
        Container(
          height: 286,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: AppLoadingIndicator(strokeWidth: 2)),
        ),
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
  final String notes;
  final String category;
  final double? oldPrice;
  final double? newPrice;
  final double? discountPercentage;
  final String? gymId;
  final DateTime? createdAt;

  const _HomeOfferItem({
    required this.id,
    required this.sourceType,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.images,
    required this.pharmacyId,
    required this.notes,
    required this.category,
    required this.oldPrice,
    required this.newPrice,
    required this.discountPercentage,
    required this.gymId,
    required this.createdAt,
  });
}

class _OfferImagePlaceholder extends StatelessWidget {
  final _OfferSourceType sourceType;

  const _OfferImagePlaceholder({required this.sourceType});

  @override
  Widget build(BuildContext context) {
    final icon = sourceType == _OfferSourceType.pharmacy
        ? Icons.medication_rounded
        : Icons.fitness_center_rounded;
    final label = sourceType == _OfferSourceType.pharmacy
        ? 'عرض صيدلية'
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
