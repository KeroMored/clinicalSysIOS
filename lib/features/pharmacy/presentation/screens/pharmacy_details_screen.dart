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

class PharmacyDetailsScreen extends StatefulWidget {
  final String pharmacyId;

  const PharmacyDetailsScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<PharmacyDetailsScreen> createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PharmacyCubit>().loadPharmacyDetails(widget.pharmacyId);
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
      // appBar: AppBar(
      //   title: const Text('تفاصيل الصيدلية'),
      //   centerTitle: true,
      // leading: IconButton(
      //   icon: const Icon(Icons.arrow_back),
      //   onPressed: () {
      //     Navigator.of(context).pop();
      //   },  
      // ),  
      // ),
      body: BlocBuilder<PharmacyCubit, PharmacyState>(
        builder: (context, state) {
          if (state is PharmacyDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PharmacyError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ: ${state.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<PharmacyCubit>()
                          .loadPharmacyDetails(widget.pharmacyId);
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
    );
  }

  Widget _buildPharmacyDetails(BuildContext context, PharmacyModel pharmacy) {
    // Calculate if pharmacy is actually open based on hours
    final isActuallyOpen = PharmacyHoursHelper.isPharmacyOpen(
      workingHours: pharmacy.workingHours,
      holidays: pharmacy.holidays,
    );
    
    return CustomScrollView(
      slivers: [
        // App Bar with Image
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppTheme.secondaryColor,
          flexibleSpace: FlexibleSpaceBar(
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pharmacy.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            background: pharmacy.images.isNotEmpty
                ? GestureDetector(
                    onTap: () {
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
                    child: Hero(
                      tag: 'pharmacy_${pharmacy.id}',
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            pharmacy.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                          // Status Badge at bottom-left
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActuallyOpen
                                    ? const Color(0xFF10B981).withValues(alpha: 0.95)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isActuallyOpen ? Icons.check_circle : Icons.cancel,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isActuallyOpen ? 'متاح' : 'مغلق',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildPlaceholderImage(),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Insurance Companies Section (if available)
                if (pharmacy.hasInsurance && pharmacy.insuranceCompanies.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppTheme.pharmacyGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.health_and_safety,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'متعاقد مع شركات التأمين',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'الشركات المتعاقد معها:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...pharmacy.insuranceCompanies.map((company) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF06B6D4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    company,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.darkColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Contact Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppTheme.pharmacyGradient,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Phone Numbers (Multiple)
                      if (pharmacy.phones.isNotEmpty) ...[
                        ...List.generate(pharmacy.phones.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _makePhoneCall(pharmacy.phones[index]),
                                icon: const Icon(Icons.phone, size: 20),
                                label: Text(
                                  pharmacy.phones.length > 1 
                                      ? 'رقم ${index + 1}: ${pharmacy.phones[index]}'
                                      : 'اتصال: ${pharmacy.phones[index]}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BCD4),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      
                      // WhatsApp Button
                      if (pharmacy.whatsapp.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF25D366).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _openWhatsApp(pharmacy.whatsapp),
                            icon:  Icon(MdiIcons.whatsapp, size: 20),
                            label: const Text(
                              'واتساب',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rating, Likes, and Report Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: RatingWidget(
                            serviceId: pharmacy.id,
                            serviceType: 'pharmacy',
                            averageRating: pharmacy.averageRating,
                            totalRatings: pharmacy.totalRatings,
                            starSize: 22,
                            onRatingAdded: () {
                              // Reload pharmacy details after rating
                              context.read<PharmacyCubit>().loadPharmacyDetails(widget.pharmacyId);
                            },
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        LikeButton(
                          serviceId: pharmacy.id,
                          serviceType: 'pharmacy',
                          initialLikesCount: pharmacy.totalLikes,
                          iconSize: 26,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        ReportButton(
                          serviceId: pharmacy.id,
                          serviceType: 'pharmacy',
                          serviceName: pharmacy.name,
                          iconSize: 26,
                          showLabel: true,
                        ),
                      ],
                    ),
                  ),
                ),
                 const SizedBox(height: 16),
  _buildReviewsButton(context, pharmacy),
 const SizedBox(height: 16), 
                // Address
                PharmacyInfoSection(
                  icon: Icons.location_on,
                  title: 'العنوان',
                  content: pharmacy.address,
                  trailing: IconButton(
                    icon: const Icon(Icons.location_on, color: Colors.blue),
                    onPressed: () => _openMap(pharmacy.latitude, pharmacy.longitude),
                  ),
                ),
                const SizedBox(height: 16),

                // Working Hours
                PharmacyInfoSection(
                  icon: Icons.schedule,
                  title: 'مواعيد العمل',
                  content: _formatWorkingHours(pharmacy.workingHours),
                ),
                const SizedBox(height: 16),

                // Holidays
                PharmacyInfoSection(
                  icon: Icons.event_busy,
                  title: 'الإجازات',
                  content: pharmacy.holidays,
                ),
                const SizedBox(height: 16),

                // Description (if exists)
                if (pharmacy.description != null && pharmacy.description!.isNotEmpty) ...[
                  PharmacyInfoSection(
                    icon: Icons.description,
                    title: 'عن الصيدلية',
                    content: pharmacy.description!,
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // Home Delivery Section
                if (pharmacy.hasHomeDelivery) ...[
                  PharmacyDeliverySection(
                    pharmacy: pharmacy,
                  ),
                  const SizedBox(height: 24),
                ],

                // Services
                if (pharmacy.services.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.pharmacyGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'الخدمات المتاحة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pharmacy.services
                        .map((service) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                service,
                                style: const TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // زر العروض
                _buildOffersButton(context, pharmacy),
                const SizedBox(height: 24),

                // زر عرض التقييمات
              

                // Images Gallery
                if (pharmacy.images.length > 1) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.pharmacyGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'صور الصيدلية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: pharmacy.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                pharmacy.images[index],
                                width: 170,
                                height: 130,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06B6D4),
            Color(0xFF0891B2),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: SvgPicture.asset(
            'assets/images/pharmacy.svg',
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  String _formatWhatsAppNumber(String input) {
    String n = input.trim();
    n = n.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('00')) n = n.substring(2);
    if (n.startsWith('0')) n = n.substring(1);
    n = n.replaceAll(RegExp(r'[^0-9]'), '');
    return n;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم واتساب غير صحيح')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح واتساب')),
        );
      }
    }
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح الخريطة')),
        );
      }
    }
  }

  Widget _buildOffersButton(BuildContext context, PharmacyModel pharmacy) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
        ),
        borderRadius: BorderRadius.circular(16),
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
              SizedBox(width: 12),
              Text(
                'عروض الصيدلية',
                style: TextStyle(
                  fontSize: 18,
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
                  colors: [
                    const Color(0xFFFBBF24),
                    const Color(0xFFF59E0B),
                  ],
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

