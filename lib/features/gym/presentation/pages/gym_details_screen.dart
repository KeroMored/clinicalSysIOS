import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/like_button.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/report_button.dart';
import '../../data/models/gym_model.dart';
import 'gym_works_screen.dart';
import '../widgets/gym_images_gallery.dart';
import '../widgets/gym_reviews_button.dart';

class GymDetailsScreen extends StatefulWidget {
  final GymModel gym;

  const GymDetailsScreen({super.key, required this.gym});

  @override
  State<GymDetailsScreen> createState() => _GymDetailsScreenState();
}

class _GymDetailsScreenState extends State<GymDetailsScreen> {
  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _primaryDark = Color(0xFF115E59);
  static const Color _titleColor = Color(0xFF134E4A);

  late GymModel _gym;

  @override
  void initState() {
    super.initState();
    _gym = widget.gym;
  }

  Future<void> _reloadGym() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(_gym.id)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _gym = GymModel.fromFirestore(doc);
        });
      }
    } catch (e) {
      debugPrint('Error reloading gym: $e');
    }
  }

  BoxDecoration _sectionDecoration({Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  bool _isGymOpenNow() {
    final now = DateTime.now();
    final dayKey = _currentDayKey(now);

    final source = _gym.hasMaleSection
        ? _gym.maleWorkingHours
        : (_gym.hasFemaleSection
              ? _gym.femaleWorkingHours
              : (_gym.maleWorkingHours.isNotEmpty
                    ? _gym.maleWorkingHours
                    : _gym.femaleWorkingHours));

    final today = source[dayKey];
    if (today == null || today.isHoliday) {
      return false;
    }

    int parse(String t) {
      final p = t.split(':');
      if (p.length != 2) return -1;
      final h = int.tryParse(p[0]) ?? -1;
      final m = int.tryParse(p[1]) ?? -1;
      if (h < 0 || m < 0) return -1;
      return (h * 60) + m;
    }

    final open = parse(today.openTime);
    final close = parse(today.closeTime);
    if (open < 0 || close < 0) {
      return false;
    }

    final nowMinutes = (now.hour * 60) + now.minute;
    if (close >= open) {
      return nowMinutes >= open && nowMinutes <= close;
    }

    return nowMinutes >= open || nowMinutes <= close;
  }

  Widget _buildGymStatusBadge() {
    final isOpen = _isGymOpenNow();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF0F766E) : const Color(0xFFB91C1C),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'متاح الآن' : 'مغلق الآن',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gyms')
          .doc(_gym.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _gym = GymModel.fromFirestore(snapshot.data!);
        }

        final String? mainImageUrl = _gym.images.isNotEmpty
            ? _gym.images.first
            : ((_gym.logoUrl != null && _gym.logoUrl!.trim().isNotEmpty)
                  ? _gym.logoUrl!
                  : null);
        final String mainHeroTag = 'gym_${_gym.id}';

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                _gym.name,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _primaryColor,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF5FAF9), Color(0xFFEDF4F3)],
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (mainImageUrl != null)
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _GymFullScreenImage(
                                    imageUrl: mainImageUrl,
                                    heroTag: mainHeroTag,
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: mainHeroTag,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(28),
                                ),
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      height: 280,
                                      width: double.infinity,
                                      child: Image.network(
                                        mainImageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child: SpinKitPulsingGrid(
                                                  color: _primaryColor,
                                                  size: 48,
                                                ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 60,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.35,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 18,
                            left: 16,
                            child: _buildGymStatusBadge(),
                          ),
                        ],
                      )
                    else
                      Stack(
                        children: [
                          Container(
                            height: 280,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _primaryColor.withValues(alpha: 0.14),
                                  _primaryDark.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(28),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.fitness_center_rounded,
                                  size: 80,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: _buildGymStatusBadge(),
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: _sectionDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.fitness_center_rounded,
                                        color: _primaryColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _gym.name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: _titleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _gym.hasMaleSection &&
                                                    _gym.hasFemaleSection
                                                ? ' رجالي ونسائي'
                                                : (_gym.hasMaleSection
                                                      ? 'قسم رجالي'
                                                      : (_gym.hasFemaleSection
                                                            ? 'قسم نسائي'
                                                            : 'جيم')),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: const Color(0xFFE2E8F0),
                                ),
                                const SizedBox(height: 16),
                                if (_gym.description.isNotEmpty)
                                  Text(
                                    _gym.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF475569),
                                      height: 1.6,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_gym.monthlySubscription != null ||
                              _gym.yearlySubscription != null ||
                              _gym.singleSessionPrice != null)
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: _sectionDecoration(),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.payments_rounded,
                                      color: _primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'سعر الاشتراك الشهري',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _gym.monthlySubscription != null
                                              ? '${_gym.monthlySubscription!.toInt()} جنيه'
                                              : 'غير محدد',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: _titleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_gym.monthlySubscription != null ||
                              _gym.yearlySubscription != null ||
                              _gym.singleSessionPrice != null)
                            const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: _sectionDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: _primaryColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'العنوان',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _titleColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: _primaryDark,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _openGoogleMaps(context),
                                        tooltip: 'افتح الخريطة',
                                        padding: const EdgeInsets.all(10),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _gym.address,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF475569),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: _sectionDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _primaryDark,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.phone_in_talk_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'تواصل معنا',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _primaryDark.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _makePhoneCall(context, _gym.phone),
                                    icon: const Icon(Icons.phone, size: 20),
                                    label: Text(
                                      'اتصال: ${_gym.phone}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryDark,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 16,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF25D366,
                                      ).withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openWhatsApp(context),
                                    icon: Icon(FontAwesomeIcons.whatsapp, size: 20),
                                    label: const Text(
                                      'واتساب',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F766E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 16,
                                      ),
                                      elevation: 0,
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_gym.images.length > 1)
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: _sectionDecoration(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'صور الجيم',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 90,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _gym.images.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      GymImagesGallery(
                                                        images: _gym.images,
                                                        initialIndex: index,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                _gym.images[index],
                                                width: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      width: 120,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.image_outlined,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_gym.images.length > 1)
                            const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: _sectionDecoration(),
                            child: _buildGymFeatures(),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: _sectionDecoration(),
                            child: _buildWorkingHoursSection(),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primaryColor, _primaryDark],
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GymWorksScreen(gymId: _gym.id),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.local_offer_rounded,
                                  size: 22,
                                ),
                                label: const Text(
                                  'أعمالنا وعروضنا',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: _sectionDecoration(),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: RatingWidget(
                                    serviceId: _gym.id,
                                    serviceType: 'gym',
                                    averageRating: _gym.averageRating,
                                    totalRatings: _gym.totalRatings,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 55,
                                  color: Colors.grey[200],
                                ),
                                Expanded(
                                  child: Center(
                                    child: LikeButton(
                                      serviceId: _gym.id,
                                      serviceType: 'gym',
                                      initialLikesCount: _gym.totalLikes,
                                      iconSize: 26,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 55,
                                  color: Colors.grey[200],
                                ),
                                Expanded(
                                  child: Center(
                                    child: ReportButton(
                                      serviceId: _gym.id,
                                      serviceType: 'gym',
                                      serviceName: _gym.name,
                                      iconSize: 26,
                                      showLabel: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GymReviewsButton(gym: _gym),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGymFeatures() {
    final features = <String>[];

    if (_gym.hasPersonalTraining) features.add('مدرب شخصي');
    if (_gym.hasNutritionConsultation) features.add('استشارات تغذية');
    if (_gym.hasSwimmingPool) features.add('حمام سباحة');
    if (_gym.hasSauna) features.add('ساونا');
    if (_gym.hasSteamRoom) features.add('غرفة بخار');
    if (_gym.hasYogaClasses) features.add('يوجا');
    if (_gym.hasCrossFit) features.add('كروس فيت');
    if (_gym.hasMartialArts) features.add('فنون قتالية');
    if (_gym.hasCardio) features.add('كارديو');
    if (_gym.hasWeightLifting) features.add('رفع أثقال');
    if (_gym.hasBodybuilding) features.add('كمال أجسام');
    if (_gym.hasFunctionalTraining) features.add('تدريب وظيفي');
    if (_gym.hasGroupClasses) features.add('حصص جماعية');

    if (features.isEmpty) {
      return const Text(
        'لا توجد مميزات إضافية',
        style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'مميزات الجيم',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 8, color: _primaryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursSection() {
    if (_gym.maleWorkingHours.isEmpty && _gym.femaleWorkingHours.isEmpty) {
      return const Text(
        'لا توجد مواعيد متاحة',
        style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'مواعيد العمل',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_gym.maleWorkingHours.isNotEmpty)
          _buildSingleWorkingHoursCard(
            title: 'مواعيد القسم الرجالي',
            icon: Icons.male_rounded,
            iconColor: const Color(0xFF2563EB),
            workingHours: _gym.maleWorkingHours,
          ),
        if (_gym.maleWorkingHours.isNotEmpty &&
            _gym.femaleWorkingHours.isNotEmpty)
          const SizedBox(height: 10),
        if (_gym.femaleWorkingHours.isNotEmpty)
          _buildSingleWorkingHoursCard(
            title: 'مواعيد القسم النسائي',
            icon: Icons.female_rounded,
            iconColor: const Color(0xFFDB2777),
            workingHours: _gym.femaleWorkingHours,
          ),
      ],
    );
  }

  Widget _buildSingleWorkingHoursCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Map<String, WorkingHours> workingHours,
  }) {
    final today = _todayDayKey();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._dayOrder.map((day) {
            final hours = workingHours[day];
            final isToday = day == today;

            final rowBg = isToday
                ? _primaryColor.withValues(alpha: 0.08)
                : Colors.transparent;
            final dayTextColor = isToday
                ? _primaryColor
                : const Color(0xFF1E293B);

            final timeText = hours == null || hours.isHoliday
                ? 'إجازة'
                : '${_formatTime12Arabic(hours.openTime)} - ${_formatTime12Arabic(hours.closeTime)}';

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: rowBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          _arabicDay(day),
                          style: TextStyle(
                            fontSize: 12,
                            color: dayTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'اليوم',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: hours == null || hours.isHoliday
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _todayDayKey() {
    return _currentDayKey(DateTime.now());
  }

  String _currentDayKey(DateTime now) {
    switch (now.weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
      default:
        return 'sunday';
    }
  }

  String _formatTime12Arabic(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) {
      return time24;
    }

    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) {
      return time24;
    }

    final period = h >= 12 ? 'م' : 'ص';
    var hour12 = h % 12;
    if (hour12 == 0) {
      hour12 = 12;
    }

    if (m == 0) {
      return '$hour12 $period';
    }

    final minute = m.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  static const List<String> _dayOrder = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  String _arabicDay(String day) {
    const map = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };
    return map[day] ?? day;
  }

  String _formatWhatsAppNumber(String input) {
    String n = input.trim();
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('20')) return n;
    return '20$n';
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      final formatted = _formatWhatsAppNumber(_gym.whatsapp);
      final message =
          'مرحباً 👋\nأريد الاستفسار عن عرض أو اشتراك في ${_gym.name}';
      final url =
          'https://wa.me/$formatted?text=${Uri.encodeComponent(message)}';
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب')));
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    try {
      final launchUri = Uri(scheme: 'tel', path: phone);
      await launchUrl(launchUri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر الاتصال')));
      }
    }
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    try {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${_gym.latitude},${_gym.longitude}';
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الخرائط')));
      }
    }
  }
}

class _GymFullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _GymFullScreenImage({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.white54,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
