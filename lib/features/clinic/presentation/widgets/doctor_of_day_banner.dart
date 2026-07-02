import 'package:clinicalsystem/features/clinic/data/models/clinic_department.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../screens/clinic_details_screen.dart';
import '../../data/models/clinic_model.dart';
import 'doctor_of_day_notification.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class DoctorOfTheDayBanner extends StatefulWidget {
  const DoctorOfTheDayBanner({super.key});

  @override
  State<DoctorOfTheDayBanner> createState() => _DoctorOfTheDayBannerState();
}

class _DoctorOfTheDayBannerState extends State<DoctorOfTheDayBanner> {
  static const int _initialPage = 1000;
  List<Map<String, dynamic>> _featuredDoctors = [];
  bool _isLoading = true;
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = _initialPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.86,
    );
    _loadFeaturedDoctors();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFeaturedDoctors() async {
    final doctors = await DoctorOfTheDayNotification.getTodaysFeaturedDoctors();
    if (mounted) {
      setState(() {
        _featuredDoctors = doctors;
        _isLoading = false;
      });

      // Start auto-scroll only if we have more than 1 doctor
      if (_featuredDoctors.length > 1) {
        _startAutoScroll();
      }
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _featuredDoctors.length > 1) {
        _pageController.animateToPage(
          _currentPage + 1,
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _doctorSubtitle(Map<String, dynamic> doctor) {
    final about = doctor['about'];
    if (about != null && about.toString().trim().isNotEmpty) {
      return about.toString();
    }

    final specData = doctor['specialization'];
    if (specData is List && specData.isNotEmpty) {
      return specData.map((e) => e.toString()).join(' • ');
    }

    if (specData != null && specData.toString().trim().isNotEmpty) {
      return specData.toString();
    }

    return 'متابعة دقيقة وتشخيص متخصص';
  }

  String? _resolveImageUrl(Map<String, dynamic> doctor) {
    final candidates = [
      doctor['doctorImageUrl'],
      doctor['profileImageUrl'],
      doctor['imageUrl'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  Future<void> _navigateToClinic(String clinicId) async {
    try {
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .get();

      if (clinicDoc.exists && mounted) {
        final clinic = ClinicModel.fromFirestore(clinicDoc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClinicDetailsScreen(clinic: clinic, isFromBanner: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildBannerLoadingPlaceholder();
    }

    if (_featuredDoctors.isEmpty) {
      return const SizedBox.shrink();
    }

    // If only one doctor, show without PageView
    if (_featuredDoctors.length == 1) {
      return Container(
        height: 300,
        margin: const EdgeInsets.symmetric(vertical: 14),
        child: _buildDoctorCard(_featuredDoctors.first),
      );
    }

    // Multiple doctors with premium auto-scroll carousel
    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _stopAutoScroll();
                } else if (notification is ScrollEndNotification) {
                  _startAutoScroll();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  final mappedIndex = index % _featuredDoctors.length;

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double page = _currentPage.toDouble();

                      if (_pageController.hasClients &&
                          _pageController.position.hasContentDimensions) {
                        page = _pageController.page ?? _currentPage.toDouble();
                      }

                      final distance = (index - page).abs();
                      final scale = (1 - (distance * 0.1)).clamp(0.9, 1.0);
                      final opacity = (1 - (distance * 0.35)).clamp(0.6, 1.0);

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(opacity: opacity, child: child),
                      );
                    },
                    child: _buildDoctorCard(_featuredDoctors[mappedIndex]),
                  );
                },
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_featuredDoctors.length, (index) {
              final isActive =
                  (_currentPage % _featuredDoctors.length) == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF00BCD4)
                      : const Color(0xFF00BCD4).withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerLoadingPlaceholder() {
    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Color(0xFF94A3B8),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 170,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (_) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF00BCD4,
                          ).withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final imageUrl = _resolveImageUrl(doctor);
    final subtitle = _doctorSubtitle(doctor);

    return GestureDetector(
      onTap: () => _navigateToClinic(doctor['id']),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BCD4).withValues(alpha: 0.16),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.low,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildImageLoadingPlaceholder();
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImageFallback();
                              },
                            )
                          : _buildImageFallback(),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'دكتور اليوم',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if ((doctor['profileViewsCount'] ?? 0) > 0)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${doctor['profileViewsCount']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'د. ${doctor['doctorName'] ?? 'غير متوفر'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ClinicDepartment.fromString(
                        doctor['department'] ?? 'other',
                      ).arabicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF26A69A), Color(0xFF00897B)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_hospital_rounded,
          color: Colors.white,
          size: 46,
        ),
      ),
    );
  }

  Widget _buildImageLoadingPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const SizedBox(
            width: 26,
            height: 26,
            child: AppLoadingIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
            ),
          ),
        ),
      ),
    );
  }
}
