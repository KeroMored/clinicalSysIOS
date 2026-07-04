import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/auth_helpers.dart';
import '../../../../core/utils/working_hours_helper.dart';
import '../../../../core/widgets/like_button.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/report_button.dart';
import '../../../pharmacy/presentation/widgets/reviews_dialog.dart';
import '../../data/models/laboratory_model.dart';
import 'lab_booking_screen.dart';

class LaboratoryDetailsClinicStyleScreen extends StatefulWidget {
  final LaboratoryModel laboratory;

  const LaboratoryDetailsClinicStyleScreen({
    super.key,
    required this.laboratory,
  });

  @override
  State<LaboratoryDetailsClinicStyleScreen> createState() =>
      _LaboratoryDetailsClinicStyleScreenState();
}

class _LaboratoryDetailsClinicStyleScreenState
    extends State<LaboratoryDetailsClinicStyleScreen> {
  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _primaryDark = Color(0xFF115E59);
  static const Color _titleColor = Color(0xFF134E4A);
  static const String _bookingSettingsCollection = 'app_settings';
  static const String _bookingSettingsDoc = 'booking';

  late LaboratoryModel _laboratory;
  late final Future<bool> _isBookingEnabledFuture;
  bool _showAllTests = false;

  @override
  void initState() {
    super.initState();
    _laboratory = widget.laboratory;
    _isBookingEnabledFuture = _fetchIsBookingEnabled();
  }

  Future<bool> _fetchIsBookingEnabled() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_bookingSettingsCollection)
          .doc(_bookingSettingsDoc)
          .get();

      final data = doc.data();
      if (data == null) return true;

      final value = data['isBooking'];
      return value is bool ? value : true;
    } catch (e) {
      debugPrint('Error loading booking settings: $e');
      return true;
    }
  }

  bool _isLabOpenNow() {
    return WorkingHoursHelper.isServiceOpen(
      workingHours: _laboratory.workingHours.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    );
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

  Widget _buildLabStatusBadge() {
    final isOpen = _isLabOpenNow();
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

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
  }

  String _todayDayKey() {
    switch (DateTime.now().weekday) {
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

  String _formatTimeToArabic(String time) {
    if (time.trim().isEmpty) return 'غير محدد';

    try {
      final normalized = time.trim().toUpperCase();
      if (normalized.contains('AM') || normalized.contains('PM')) {
        final clean = normalized.replaceAll(RegExp(r'\s+'), '');
        final parts = clean
            .replaceAll('AM', '')
            .replaceAll('PM', '')
            .split(':');
        var hour = int.parse(parts[0]);
        final minute = parts.length > 1 ? parts[1] : '00';

        final isPM = normalized.contains('PM');
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;

        final isMorning = hour < 12;
        final arabicHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$arabicHour:$minute ${isMorning ? 'ص' : 'م'}';
      }

      final parts = normalized.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1].padLeft(2, '0');
        final isMorning = hour < 12;
        final arabicHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$arabicHour:$minute ${isMorning ? 'ص' : 'م'}';
      }
    } catch (_) {
      return time;
    }

    return time;
  }

  Widget _buildWorkingHoursContent() {
    const daysArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    final todayDayKey = _todayDayKey();
    final isOpenNow = _isLabOpenNow();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: _primaryDark,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'مواعيد العمل',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...daysArabic.entries.map((entry) {
            final hours = _laboratory.workingHours[entry.key];
            final isToday = entry.key == todayDayKey;
            final isHoliday = hours?.isHoliday ?? false;
            final isClosed = isHoliday || hours == null;

            final timeLabel = isHoliday
                ? 'عطلة رسمية'
                : (isClosed
                      ? 'مغلق'
                      : '${_formatTimeToArabic(hours.openTime)} - ${_formatTimeToArabic(hours.closeTime)}');

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? _primaryColor.withValues(alpha: 0.35)
                      : const Color(0xFFE5E7EB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? _primaryDark
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  if (isToday && !isClosed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isOpenNow
                            ? _primaryColor
                            : const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOpenNow ? 'مفتوح الآن' : 'اليوم',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isClosed
                              ? const Color(0xFF6B7280)
                              : _primaryColor,
                        ),
                      ),
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

  Widget _buildReviewsButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ReviewsDialog.show(
          context,
          serviceId: _laboratory.id,
          serviceName: _laboratory.name,
          averageRating: _laboratory.averageRating,
          totalRatings: _laboratory.totalRatings,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التقييمات',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _laboratory.averageRating.floor()
                                ? Icons.star_rounded
                                : (index < _laboratory.averageRating
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded),
                            color: const Color(0xFFFBBF24),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_laboratory.averageRating.toStringAsFixed(1)} (${_laboratory.totalRatings} تقييم)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('laboratories')
          .doc(_laboratory.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _laboratory = LaboratoryModel.fromFirestore(snapshot.data!);
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                _laboratory.name,
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
                        color: Colors.black.withOpacity(0.2),
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
                    if (_laboratory.logoUrl != null &&
                        _laboratory.logoUrl!.isNotEmpty)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(28),
                            ),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 280,
                                  width: double.infinity,
                                  child: Image.network(
                                    _laboratory.logoUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: SpinKitPulsingGrid(
                                              color: _primaryColor,
                                              size: 48,
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
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
                                          Colors.black.withValues(alpha: 0.35),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 18,
                            left: 16,
                            child: _buildLabStatusBadge(),
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
                                  Icons.science_rounded,
                                  size: 80,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: _buildLabStatusBadge(),
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
                                        Icons.science_rounded,
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
                                            _laboratory.name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: _titleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_laboratory.city} - ${_laboratory.governorate}',
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
                                Text(
                                  _laboratory.description?.trim().isNotEmpty ==
                                          true
                                      ? _laboratory.description!
                                      : 'معمل متخصص في تقديم تحاليل دقيقة وسريعة.',
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

                          if (_laboratory.estimatedResultTime != null ||
                              _laboratory.hasHomeService)
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: _sectionDecoration(),
                              child: Row(
                                children: [
                                  if (_laboratory.estimatedResultTime != null)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'زمن ظهور النتيجة',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_laboratory.estimatedResultTime} ساعة',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: _titleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_laboratory.estimatedResultTime != null &&
                                      _laboratory.hasHomeService)
                                    Container(
                                      width: 1,
                                      height: 48,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  if (_laboratory.hasHomeService)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'الخدمة المنزلية',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _laboratory.homeServiceFee != null
                                                  ? '${_laboratory.homeServiceFee!.toInt()} جنيه'
                                                  : 'متاحة',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: _titleColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (_laboratory.estimatedResultTime != null ||
                              _laboratory.hasHomeService)
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
                                        onPressed: () => _openMap(
                                          context,
                                          _laboratory.latitude,
                                          _laboratory.longitude,
                                        ),
                                        tooltip: 'افتح الخريطة',
                                        padding: const EdgeInsets.all(10),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _laboratory.address,
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
                            decoration: _sectionDecoration(color: Colors.white),
                            child: _buildWorkingHoursContent(),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            child: FutureBuilder<bool>(
                              future: _isBookingEnabledFuture,
                              builder: (context, snapshot) {
                                final isBookingEnabled = snapshot.data ?? true;
                                if (!isBookingEnabled) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [_primaryColor, _primaryDark],
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryColor.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 14,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final isAuthenticated =
                                                await AuthHelpers.requireAuth(
                                                  context,
                                                  message:
                                                      'يجب تسجيل الدخول لحجز موعد في المعمل',
                                                );

                                            if (!isAuthenticated || !mounted) {
                                              return;
                                            }

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    LabBookingScreen(
                                                      laboratory: _laboratory,
                                                    ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.calendar_month_rounded,
                                            size: 22,
                                          ),
                                          label: const Text(
                                            'احجز موعد الآن',
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
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              },
                            ),
                          ),

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
                                if (_laboratory.phones.isNotEmpty)
                                  ...List.generate(_laboratory.phones.length, (
                                    index,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _primaryDark.withValues(
                                              alpha: 0.2,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () => _makePhoneCall(
                                            context,
                                            _laboratory.phones[index],
                                          ),
                                          icon: const Icon(
                                            Icons.phone,
                                            size: 20,
                                          ),
                                          label: Text(
                                            _laboratory.phones.length > 1
                                                ? 'رقم ${index + 1}: ${_laboratory.phones[index]}'
                                                : 'اتصال: ${_laboratory.phones[index]}',
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),

                                if (_laboratory.whatsapp != null &&
                                    _laboratory.whatsapp!.trim().isNotEmpty)
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
                                      onPressed: () => _openWhatsApp(
                                        context,
                                        _laboratory.whatsapp!,
                                      ),
                                      icon: Icon(Icons.chat, size: 20),
                                      label: const Text(
                                        'واتساب',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0F766E,
                                        ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
                                    serviceId: _laboratory.id,
                                    serviceType: 'laboratory',
                                    averageRating: _laboratory.averageRating,
                                    totalRatings: _laboratory.totalRatings,
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
                                      serviceId: _laboratory.id,
                                      serviceType: 'laboratory',
                                      initialLikesCount: _laboratory.totalLikes,
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
                                      serviceId: _laboratory.id,
                                      serviceType: 'laboratory',
                                      serviceName: _laboratory.name,
                                      iconSize: 26,
                                      showLabel: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildReviewsButton(context),
                          const SizedBox(height: 12),

                          if (_laboratory.availableTests.isNotEmpty)
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
                                          color: _primaryColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.science_rounded,
                                          color: _primaryColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'التحاليل المتوفرة',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ...(_showAllTests
                                          ? _laboratory.availableTests
                                          : _laboratory.availableTests.take(10))
                                      .map(
                                        (test) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: Icon(
                                                  Icons.circle,
                                                  size: 8,
                                                  color: _primaryColor,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  test,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF475569),
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  if (_laboratory.availableTests.length > 10)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _showAllTests = !_showAllTests;
                                          });
                                        },
                                        icon: Icon(
                                          _showAllTests
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                    .keyboard_arrow_down_rounded,
                                        ),
                                        label: Text(
                                          _showAllTests
                                              ? 'عرض أقل'
                                              : 'عرض ${_laboratory.availableTests.length - 10} تحليل إضافي',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 18),
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

  String _formatWhatsAppNumber(String input) {
    String n = input.trim();
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('20')) return '20$n';
    return '20$n';
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن إجراء المكالمة')));
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رقم واتساب غير صحيح')));
      }
      return;
    }

    final String whatsappUrl = 'https://wa.me/$formatted';
    try {
      final launched = await launchUrl(Uri.parse(whatsappUrl));
      if (!launched) {
        throw 'Could not launch WhatsApp';
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب')));
      }
    }
  }

  Future<void> _openMap(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الخريطة')));
      }
    }
  }
}
