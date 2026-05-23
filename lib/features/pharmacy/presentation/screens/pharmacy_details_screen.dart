import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/pharmacy_cubit.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/like_button.dart';
import '../../../../core/widgets/report_button.dart';
import '../cubit/pharmacy_state.dart';
import '../../data/models/pharmacy_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'pharmacy_offers_list_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pharmacy_hours_helper.dart';
import '../widgets/reviews_dialog.dart';
import '../widgets/pharmacy_info_section.dart';
import '../widgets/pharmacy_delivery_section.dart';
import '../widgets/pharmacy_full_screen_image.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class PharmacyDetailsScreen extends StatefulWidget {
  final String pharmacyId;

  const PharmacyDetailsScreen({super.key, required this.pharmacyId});

  @override
  State<PharmacyDetailsScreen> createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> {
  static const String _bookingSettingsCollection = 'app_settings';
  static const String _bookingSettingsDoc = 'booking';
  late final Future<bool> _isBookingEnabledFuture;

  @override
  void initState() {
    super.initState();
    _isBookingEnabledFuture = _fetchIsBookingEnabled();
    context.read<PharmacyCubit>().loadPharmacyDetails(widget.pharmacyId);
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

  String _formatTimeToArabic(String time) {
    // Handle time in format "HH:mm"
    final parts = time.split(':');
    if (parts.length != 2) return time;

    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];

    String period;
    if (hour == 0) {
      hour = 12;
      period = 'صباحاً';
    } else if (hour < 12) {
      period = 'صباحاً';
    } else if (hour == 12) {
      period = 'مساءً';
    } else {
      hour = hour - 12;
      period = 'مساءً';
    }

    if (minute == '00') {
      return '$hour $period';
    }
    return '$hour:$minute $period';
  }

  String _formatWorkingHours(String workingHours) {
    // Replace time patterns in the format "HH:mm - HH:mm" or "HH:mm"
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})');
    return workingHours.replaceAllMapped(timePattern, (match) {
      final time = '${match.group(1)}:${match.group(2)}';
      return _formatTimeToArabic(time);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 58,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF0891B2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'تفاصيل الصيدلية',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: BlocBuilder<PharmacyCubit, PharmacyState>(
          builder: (context, state) {
            if (state is PharmacyDetailsLoading) {
              return const Center(
                child: AppLoadingIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              );
            }

            if (state is PharmacyError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PharmacyCubit>().loadPharmacyDetails(
                          widget.pharmacyId,
                        );
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            if (state is PharmacyDetailsLoaded) {
              return _buildPharmacyDetails(context, state.pharmacy);
            }

            return const Center(child: Text('لا توجد بيانات'));
          },
        ),
      ),
    );
  }

  Widget _buildPharmacyDetails(BuildContext context, PharmacyModel pharmacy) {
    final isActuallyOpen = PharmacyHoursHelper.isPharmacyOpen(
      workingHours: pharmacy.workingHours,
      holidays: pharmacy.holidays,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: pharmacy.images.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PharmacyFullScreenImage(
                          imageUrl: pharmacy.images.first,
                          heroTag: 'pharmacy_${pharmacy.id}',
                        ),
                      ),
                    );
                  },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (pharmacy.images.isNotEmpty)
                      Hero(
                        tag: 'pharmacy_${pharmacy.id}',
                        child: Image.network(
                          pharmacy.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        ),
                      )
                    else
                      _buildPlaceholderImage(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.12),
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pharmacy.address,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < pharmacy.averageRating.floor()
                            ? Icons.star_rounded
                            : (index < pharmacy.averageRating
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded),
                        color: const Color(0xFFFBBF24),
                        size: 16,
                      );
                    }),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pharmacy.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFF0B8293),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActuallyOpen
                        ? const Color(0xFFDDF7EC)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActuallyOpen ? 'متاح' : 'مغلق',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActuallyOpen
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _buildSectionHeader('معلومات التواصل'),
          const SizedBox(height: 8),
          _buildContactSection(pharmacy),

          const SizedBox(height: 16),

          _buildSectionHeader('معلومات الصيدلية'),
          const SizedBox(height: 8),

          _buildLocationSection(pharmacy),
          const SizedBox(height: 10),

          PharmacyInfoSection(
            icon: Icons.access_time_rounded,
            title: 'مواعيد العمل',
            content: _formatWorkingHours(pharmacy.workingHours),
          ),
          const SizedBox(height: 10),

          PharmacyInfoSection(
            icon: Icons.event_busy,
            title: 'الإجازات',
            content: pharmacy.holidays,
          ),
          const SizedBox(height: 10),

          if (pharmacy.description != null &&
              pharmacy.description!.isNotEmpty) ...[
            PharmacyInfoSection(
              icon: Icons.description,
              title: 'عن الصيدلية',
              content: pharmacy.description!,
            ),
            const SizedBox(height: 10),
          ],

          if (pharmacy.services.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الخدمات المتاحة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pharmacy.services
                        .map(
                          (service) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              service,
                              style: const TextStyle(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (pharmacy.images.length > 1) ...[
            const SizedBox(height: 14),
            const Text(
              'صور الصيدلية',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkColor,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pharmacy.images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        pharmacy.images[index],
                        width: 170,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (pharmacy.hasInsurance &&
              pharmacy.insuranceCompanies.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'شركات التأمين',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pharmacy.insuranceCompanies
                        .map(
                          (company) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              company,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 12,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (pharmacy.hasHomeDelivery) ...[
            _buildSectionHeader('خدمات التوصيل'),
            const SizedBox(height: 8),
            PharmacyDeliverySection(pharmacy: pharmacy),
            const SizedBox(height: 10),
          ],

          FutureBuilder<bool>(
            future: _isBookingEnabledFuture,
            builder: (context, snapshot) {
              final isBookingEnabled = snapshot.data ?? true;
              if (!isBookingEnabled) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const SizedBox(height: 12),
                  _buildOffersButton(context, pharmacy),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'التفاعل والتقييم',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildEngagementItem(
                        label: 'التقييم',
                        child: RatingWidget(
                          serviceId: pharmacy.id,
                          serviceType: 'pharmacy',
                          averageRating: pharmacy.averageRating,
                          totalRatings: pharmacy.totalRatings,
                          starSize: 16,
                          onRatingAdded: () {
                            context.read<PharmacyCubit>().loadPharmacyDetails(
                              widget.pharmacyId,
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: const Color(0xFFE5E7EB),
                    ),
                    Expanded(
                      child: _buildEngagementItem(
                        label: 'القلوب',
                        child: LikeButton(
                          serviceId: pharmacy.id,
                          serviceType: 'pharmacy',
                          initialLikesCount: pharmacy.totalLikes,
                          iconSize: 23,
                        ),
                      ),
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: const Color(0xFFE5E7EB),
                    ),
                    Expanded(
                      child: _buildEngagementItem(
                        label: 'إبلاغ',
                        child: ReportButton(
                          serviceId: pharmacy.id,
                          serviceType: 'pharmacy',
                          serviceName: pharmacy.name,
                          iconSize: 21,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          _buildReviewsButton(context, pharmacy),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildEngagementItem({required Widget child, required String label}) {
    return Column(
      children: [
        child,
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFD4EEF0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: AppTheme.secondaryColor, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(PharmacyModel pharmacy) {
    final phones = pharmacy.phones
        .where((phone) => phone.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          if (phones.isEmpty && pharmacy.whatsapp.isEmpty)
            const Text(
              'لا توجد أرقام تواصل متاحة حالياً',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (phones.isNotEmpty)
            ...List.generate(phones.length, (index) {
              final phone = phones[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == phones.length - 1 ? 0 : 10,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0B8293,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          size: 18,
                          color: Color(0xFF0B8293),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'رقم ${index + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _makePhoneCall(phone),
                        icon: const Icon(
                          Icons.call_rounded,
                          color: Color(0xFF0B8293),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (pharmacy.whatsapp.isNotEmpty) ...[
            if (phones.isNotEmpty) const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      MdiIcons.whatsapp,
                      color: const Color(0xFF16A34A),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'واتساب',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          pharmacy.whatsapp,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openWhatsApp(pharmacy.whatsapp),
                    icon: Icon(MdiIcons.whatsapp, color: Color(0xFF16A34A)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection(PharmacyModel pharmacy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                  children: [
                      Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.location_on_rounded, color: AppTheme.secondaryColor, size: 18),
          ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'العنوان',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                                     SizedBox(height: 4),
                                      Text(
                                        maxLines: 3,
                                        pharmacy.address,
                                        style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                      height: 1.5,
                                        ),
                                      ),
                        ],
                      ),
                    ),
                  ],
                ),
      
              ],
            ),
          ),
          const SizedBox(width: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openMap(pharmacy.latitude, pharmacy.longitude),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF0B8293),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: SvgPicture.asset(
            'assets/images/pharmacy.svg',
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  String _formatWhatsAppNumber(String input) {
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = input.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return n;
    // ضيف +20 قدام الرقم
    return '20$n';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن إجراء المكالمة')));
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رقم واتساب غير صحيح')));
      }
      return;
    }
    final String whatsappUrl = "https://wa.me/$formatted";
    try {
      bool launched = await launchUrl(Uri.parse(whatsappUrl));
      if (!launched) {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب')));
      }
    }
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الخريطة')));
      }
    }
  }

  Widget _buildOffersButton(BuildContext context, PharmacyModel pharmacy) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to pharmacy-specific offers
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<AuthCubit>(),
                  child: PharmacyOffersListScreen(
                    pharmacyId: pharmacy.id,
                    pharmacyName: pharmacy.name,
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_rounded, size: 24, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'عروض الصيدلية',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsButton(BuildContext context, PharmacyModel pharmacy) {
    return GestureDetector(
      onTap: () {
        ReviewsDialog.show(
          context,
          serviceId: pharmacy.id,
          serviceName: pharmacy.name,
          averageRating: pharmacy.averageRating,
          totalRatings: pharmacy.totalRatings,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
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

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التقييمات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < pharmacy.averageRating.floor()
                                ? Icons.star_rounded
                                : (index < pharmacy.averageRating
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded),
                            color: const Color(0xFFFBBF24),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pharmacy.averageRating.toStringAsFixed(1)} (${pharmacy.totalRatings} تقييم)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
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
}
