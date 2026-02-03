import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/working_hours_helper.dart';
import '../../data/models/laboratory_model.dart';
import '../../data/repositories/laboratory_repository.dart';
import '../widgets/laboratory_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/like_button.dart';
import '../../../../core/widgets/report_button.dart';
import '../../../pharmacy/presentation/widgets/reviews_dialog.dart';
import 'lab_booking_screen.dart';

class LaboratoryHomePage extends StatefulWidget {
  const LaboratoryHomePage({super.key});

  @override
  State<LaboratoryHomePage> createState() => _LaboratoryHomePageState();
}

class _LaboratoryHomePageState extends State<LaboratoryHomePage> {
  final LaboratoryRepository _labRepo = LaboratoryRepository();
  String _searchQuery = '';
  
  // Pagination fields
  final List<LaboratoryModel> _laboratories = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 10;
  
  // Location fields
  Position? _userLocation;
  String _sortBy = 'distance'; // distance, rating, name

  @override
  void initState() {
    super.initState();
    _requestLocationAndLoad();
    _scrollController.addListener(_onScroll);
  }
  
  Future<void> _requestLocationAndLoad() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _userLocation = position;
        _sortBy = 'distance';
      });
    }
    if (mounted) {
      _loadLaboratories();
    }
  }

  void _sortLaboratories(List<LaboratoryModel> labs) {
    switch (_sortBy) {
      case 'distance':
        if (_userLocation != null) {
          labs.sort((a, b) {
            final distA = LocationService.calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              a.latitude,
              a.longitude,
            );
            final distB = LocationService.calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              b.latitude,
              b.longitude,
            );
            return distA.compareTo(distB);
          });
        } else {
          labs.sort((a, b) => a.name.compareTo(b.name));
        }
        break;
      case 'rating':
        labs.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'name':
        labs.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  void _changeSortOption(String sortOption) {
    if (mounted) {
      setState(() {
        _sortBy = sortOption;
        _sortLaboratories(_laboratories);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && _searchQuery.isEmpty) {
        _loadLaboratories();
      }
    }
  }

  Future<void> _loadLaboratories() async {
    if (_isLoading || !mounted) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection('laboratories')
          .where('status', isEqualTo: 'approved')
          .where('isVisible', isEqualTo: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        var newLabs = snapshot.docs
            .map((doc) => LaboratoryModel.fromFirestore(doc))
            .toList();

        // Sort based on selected option
        _sortLaboratories(newLabs);

        if (mounted) {
          setState(() {
            _laboratories.addAll(newLabs);
            _hasMore = snapshot.docs.length == _pageSize;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasMore = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'معامل التحاليل',
          gradient: AppTheme.laboratoryGradient,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.white),
              tooltip: 'ترتيب حسب',
              onSelected: _changeSortOption,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'distance',
                  child: Row(
                    children: [
                      Icon(
                        Icons.near_me,
                        color: _sortBy == 'distance' ? const Color(0xFF8B5CF6) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'الأقرب',
                        style: TextStyle(
                          color: _sortBy == 'distance' ? const Color(0xFF8B5CF6) : const Color(0xFF0F172A),
                          fontWeight: _sortBy == 'distance' ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rating',
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: _sortBy == 'rating' ? const Color(0xFF8B5CF6) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'الأعلى تقييماً',
                        style: TextStyle(
                          color: _sortBy == 'rating' ? const Color(0xFF8B5CF6) : const Color(0xFF0F172A),
                          fontWeight: _sortBy == 'rating' ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_by_alpha,
                        color: _sortBy == 'name' ? const Color(0xFF8B5CF6) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'الاسم',
                        style: TextStyle(
                          color: _sortBy == 'name' ? const Color(0xFF8B5CF6) : const Color(0xFF0F172A),
                          fontWeight: _sortBy == 'name' ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن معمل...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  if (mounted) {
                    setState(() => _searchQuery = value);
                  }
                },
              ),
            ),
            
            // Laboratory List
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? StreamBuilder<List<LaboratoryModel>>(
                      stream: _labRepo.searchLaboratories(_searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                        }

                        final laboratories = snapshot.data ?? [];

                        if (laboratories.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.science_outlined, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('لا توجد نتائج للبحث', style: TextStyle(fontSize: 18, color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: laboratories.length,
                          itemBuilder: (context, index) {
                            final lab = laboratories[index];
                            final isOpen = WorkingHoursHelper.isServiceOpen(
                              workingHours: lab.workingHours.map((key, value) => MapEntry(key, value.toMap())),
                            );
                            return LaboratoryCard(
                              laboratory: lab,
                              isOpen: isOpen,
                              onTap: () async {
                                if (!mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LaboratoryDetailsScreen(laboratory: lab),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    )
                  : _isLoading && _laboratories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SpinKitPulsingGrid(
                                color: AppTheme.laboratoryGradient.colors[0],
                                size: 60,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'جاري تحميل المعامل...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _laboratories.isEmpty && !_isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.science_outlined, size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  const Text('لا توجد معامل متاحة', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _laboratories.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _laboratories.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: SpinKitThreeBounce(
                                    color: AppTheme.laboratoryGradient.colors[0],
                                    size: 30,
                                  ),
                                ),
                              );
                            }

                            final lab = _laboratories[index];
                            final isOpen = WorkingHoursHelper.isServiceOpen(
                              workingHours: lab.workingHours.map((key, value) => MapEntry(key, value.toMap())),
                            );
                            return LaboratoryCard(
                              laboratory: lab,
                              isOpen: isOpen,
                              onTap: () async {
                                if (!mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LaboratoryDetailsScreen(laboratory: lab),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class LaboratoryDetailsScreen extends StatelessWidget {
  final LaboratoryModel laboratory;

  const LaboratoryDetailsScreen({super.key, required this.laboratory});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('laboratories')
          .doc(laboratory.id)
          .snapshots(),
      builder: (context, snapshot) {
        // Use updated data if available
        LaboratoryModel currentLab = laboratory;
        if (snapshot.hasData && snapshot.data!.exists) {
          currentLab = LaboratoryModel.fromFirestore(snapshot.data!);
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text(currentLab.name),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and basic info
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade600, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: currentLab.logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(17),
                                  child: Image.network(
                                    currentLab.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.science_rounded,
                                      color: Colors.green.shade600,
                                      size: 60,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.science_rounded,
                                  color: Colors.green.shade600,
                                  size: 60,
                                ),
                        ),
                        const SizedBox(height: 20),
                        // Name
                        Text(
                          currentLab.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                    // Description
                    if (currentLab.description != null && currentLab.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          currentLab.description!,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    // Additional Info Badges
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (currentLab.hasHomeService)
                          _buildBadge(
                            Icons.home_rounded,
                            'خدمة منزلية',
                            Colors.blue,
                          ),
                        if (currentLab.estimatedResultTime != null)
                          _buildBadge(
                            Icons.access_time_rounded,
                            'النتيجة خلال ${currentLab.estimatedResultTime} ساعة',
                            Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Rating, Likes, Report Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
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
                            serviceId: currentLab.id,
                            serviceType: 'laboratory',
                            averageRating: currentLab.averageRating,
                            totalRatings: currentLab.totalRatings,
                            starSize: 22,
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        LikeButton(
                          serviceId: currentLab.id,
                          serviceType: 'laboratory',
                          initialLikesCount: currentLab.totalLikes,
                          iconSize: 26,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        ReportButton(
                          serviceId: currentLab.id,
                          serviceType: 'laboratory',
                          serviceName: currentLab.name,
                          iconSize: 26,
                          showLabel: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Reviews Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildReviewsButton(context, currentLab),
              ),
              const SizedBox(height: 16),

              // Contact Information
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات التواصل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow(Icons.location_on, currentLab.address),
                    
                    const SizedBox(height: 16),
                    
                    // Contact Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(context, currentLab.ownerPhone),
                            icon: const Icon(Icons.phone),
                            label: const Text('اتصال'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openWhatsApp(context, currentLab.ownerPhone),
                            icon: Icon(MdiIcons.whatsapp),
                            label: const Text('واتساب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Map Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openMap(context, currentLab.latitude, currentLab.longitude),
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('عرض على الخريطة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                    
                    // Working Hours if available
                    if (currentLab.workingHours.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildWorkingHoursSection(currentLab),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    if (currentLab.hasHomeService) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.home, color: Colors.blue, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'خدمة التحاليل المنزلية متاحة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (currentLab.homeServiceFee != null)
                                    Text(
                                      'رسوم الخدمة: ${currentLab.homeServiceFee} جنيه',
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // قسم الأسعار - التحاليل الشائعة
              if (currentLab.availableTests.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 التحاليل المتوفرة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade50, Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            ...currentLab.availableTests.take(10).map((test) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      test,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            if (currentLab.availableTests.length > 10) ...[
                              const SizedBox(height: 8),
                              Text(
                                'و ${currentLab.availableTests.length - 10} تحليل آخر',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'للاستفسار عن الأسعار، يرجى التواصل مع المعمل مباشرة',
                                style: TextStyle(color: Colors.blue, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // زر احجز الآن الكبير
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LabBookingScreen(laboratory: currentLab),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'احجز الآن',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursSection(LaboratoryModel laboratory) {
    final daysArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مواعيد العمل',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
        ...laboratory.workingHours.entries.map((entry) {
          final dayName = daysArabic[entry.key] ?? entry.key;
          final hours = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${hours.openTime} - ${hours.closeTime}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewsButton(BuildContext context, LaboratoryModel laboratory) {
    return GestureDetector(
      onTap: () {
        ReviewsDialog.show(
          context,
          serviceId: laboratory.id,
          serviceName: laboratory.name,
          averageRating: laboratory.averageRating,
          totalRatings: laboratory.totalRatings,
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
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFBBF24),
                    Color(0xFFF59E0B),
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
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < laboratory.averageRating.floor()
                                ? Icons.star_rounded
                                : (index < laboratory.averageRating
                                    ? Icons.star_half_rounded
                                    : Icons.star_outline_rounded),
                            color: const Color(0xFFFBBF24),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${laboratory.averageRating.toStringAsFixed(1)} (${laboratory.totalRatings} تقييم)',
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

  String _formatWhatsAppNumber(String input) {
    // Keep digits and '+' only initially
    String n = input.trim();
    // Remove all spaces, dashes, and parentheses
    n = n.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Remove leading '+'
    if (n.startsWith('+')) n = n.substring(1);
    // Convert leading '00' international prefix to just country code
    if (n.startsWith('00')) n = n.substring(2);
    // Remove a single leading '0' for local numbers as requested
    if (n.startsWith('0')) n = n.substring(1);
    // Finally, strip any remaining non-digits to be safe
    n = n.replaceAll(RegExp(r'[^0-9]'), '');
    return n;
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) {
      if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح واتساب')),
        );
      }
    }
  }

  Future<void> _openMap(BuildContext context, double latitude, double longitude) async {
    final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح الخريطة')),
        );
      }
    }
  }
}