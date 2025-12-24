import 'package:clinicalsystem/features/clinic/data/models/clinic_department.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../screens/clinic_details_screen.dart';
import '../../data/models/clinic_model.dart';
import 'doctor_of_day_notification.dart';

class DoctorOfTheDayBanner extends StatefulWidget {
  const DoctorOfTheDayBanner({super.key});

  @override
  State<DoctorOfTheDayBanner> createState() => _DoctorOfTheDayBannerState();
}

class _DoctorOfTheDayBannerState extends State<DoctorOfTheDayBanner> {
  List<Map<String, dynamic>> _featuredDoctors = [];
  bool _isLoading = true;
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
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

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _featuredDoctors.length > 1) {
        _currentPage = (_currentPage + 1) % _featuredDoctors.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
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
            builder: (context) => ClinicDetailsScreen(
              clinic: clinic,
              isFromBanner: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container();
    }

    if (_featuredDoctors.isEmpty) {
      return const SizedBox.shrink();
    }

    // If only one doctor, show without PageView
    if (_featuredDoctors.length == 1) {
      return _buildDoctorCard(_featuredDoctors.first);
    }

    // Multiple doctors with auto-scroll
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: PageView.builder(
        controller: _pageController,
        itemCount: _featuredDoctors.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildDoctorCard(_featuredDoctors[index]);
        },
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return GestureDetector(
      onTap: () => _navigateToClinic(doctor['id']),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF26A69A).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              if (doctor['doctorImageUrl'] != null)
                Positioned.fill(
                  child: Image.network(
                    doctor['doctorImageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF26A69A),
                              Color(0xFF00897B),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge and indicators
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'دكتور اليوم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Page indicators (only show if multiple doctors)
                        if (_featuredDoctors.length > 1) ...[
                          Row(
                            children: List.generate(
                              _featuredDoctors.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Click hint
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Doctor Info
                    Row(
                      children: [
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'د. ${doctor['doctorName'] ?? 'غير متوفر'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ClinicDepartment.fromString(doctor['department'] ?? 'other').arabicName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 15,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                doctor['specialization'] ?? 'تخصص عام',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 12,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Location
                              if (doctor['address'] != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 15,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        doctor['address'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 12,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
