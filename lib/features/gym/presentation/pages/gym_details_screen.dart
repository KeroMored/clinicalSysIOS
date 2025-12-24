import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/gym_model.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/like_button.dart';
import '../../../../core/widgets/report_button.dart';
import '../widgets/gym_images_gallery.dart';
import '../widgets/gym_price_card.dart';
import '../widgets/gym_working_hours_card.dart';
import '../widgets/gym_description_card.dart';
import '../widgets/gym_features_card.dart';
import '../widgets/gym_reviews_button.dart';

class GymDetailsScreen extends StatelessWidget {
  final GymModel gym;

  const GymDetailsScreen({
    super.key,
    required this.gym,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar with Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.gymGradient.colors[0],
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppTheme.gymGradient.colors[0],
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gym Image
                  if (gym.images.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GymImagesGallery(
                              images: gym.images,
                              initialIndex: 0,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'gym_main_image',
                        child: Image.network(
                          gym.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.gymGradient,
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                size: 100,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.gymGradient,
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  // Dark Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Gym Info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gym.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${gym.city}, ${gym.governorate}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            // Rating
                              ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Images Gallery - first after main image
                if (gym.images.length > 1)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: gym.images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GymImagesGallery(
                                  images: gym.images,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'gym_image_$index',
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(left: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  gym.images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.gymGradient,
                                      ),
                                      child: const Icon(
                                        Icons.fitness_center_rounded,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                // Contact Section - تواصل معنا
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
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
                              gradient: AppTheme.gymGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.phone_in_talk_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'تواصل معنا',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GradientButton(
                              text: 'اتصال',
                              icon: Icons.phone_rounded,
                              gradient: AppTheme.gymGradient,
                              onPressed: () => _makePhoneCall(gym.phone),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              text: 'واتساب',
                              icon: MdiIcons.whatsapp,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                              ),
                              onPressed: () => _openWhatsApp(gym.whatsapp),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Address Card - العنوان
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
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
                              gradient: AppTheme.gymGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'العنوان',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        gym.address,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        text: 'فتح في خرائط جوجل',
                        icon: Icons.map_rounded,
                        gradient: const LinearGradient(
                          colors: [Color.fromARGB(255, 0, 0, 0), Color(0xFF434343)],
                        ),
                        onPressed: () => _openGoogleMaps(context, gym.latitude, gym.longitude),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Rating, Likes, and Report Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: RatingWidget(
                            serviceId: gym.id,
                            serviceType: 'gym',
                            averageRating: gym.averageRating,
                            totalRatings: gym.totalRatings,
                            starSize: 22,
                            onRatingAdded: () {
                              // Reload gym details if needed
                            },
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        LikeButton(
                          serviceId: gym.id,
                          serviceType: 'gym',
                          initialLikesCount: 0,
                          iconSize: 26,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        ReportButton(
                          serviceId: gym.id,
                          serviceType: 'gym',
                          serviceName: gym.name,
                          iconSize: 26,
                          showLabel: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Reviews Button
                GymReviewsButton(gym: gym),

                const SizedBox(height: 20),

                // Description - عن الجيم
                GymDescriptionCard(gym: gym),

                // Features - المميزات الإضافية
                GymFeaturesCard(gym: gym),

                const SizedBox(height: 20),

                // Working Hours - Male Section
                if (gym.hasMaleSection && gym.maleWorkingHours.isNotEmpty)
                  GymWorkingHoursCard(
                    title: 'مواعيد القسم الرجالي',
                    icon: Icons.male_rounded,
                    color: const Color(0xFF3B82F6),
                    workingHours: gym.maleWorkingHours,
                  ),

                // Working Hours - Female Section
                if (gym.hasFemaleSection && gym.femaleWorkingHours.isNotEmpty)
                  GymWorkingHoursCard(
                    title: 'مواعيد القسم النسائي',
                    icon: Icons.female_rounded,
                    color: const Color(0xFFEC4899),
                    workingHours: gym.femaleWorkingHours,
                  ),

                // Subscription Prices - الاشتراك
                if (gym.monthlySubscription != null || gym.yearlySubscription != null)
                  GymPriceCard(gym: gym),


                // Our Works Button - أعمالنا وعروضنا
             
                // Equipment & Facilities
            
              

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      print('Error making phone call: $e');
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    // Clean phone number and add country code if needed
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '2${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('+') && !cleanPhone.startsWith('2')) {
      cleanPhone = '2$cleanPhone';
    }
    
    final Uri launchUri = Uri.parse('https://wa.me/$cleanPhone');
    
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening WhatsApp: $e');
    }
  }

  Future<void> _openGoogleMaps(BuildContext context, double latitude, double longitude) async {
    final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح خرائط جوجل')),
        );
      }
    }
  }
}
