import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/clinic_department.dart';
import '../../data/models/clinic_model.dart';
import 'clinic_details_screen.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/working_hours_helper.dart';

class ClinicsListScreen extends StatefulWidget {
  final ClinicDepartment department;

  const ClinicsListScreen({super.key, required this.department});

  @override
  State<ClinicsListScreen> createState() => _ClinicsListScreenState();
}

class _ClinicsListScreenState extends State<ClinicsListScreen> {
  final List<ClinicModel> _clinics = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 10;
  
  // Location fields
  Position? _userLocation;
  String _sortBy = 'name'; // distance, rating, name (default to name)

  @override
  void initState() {
    super.initState();
    // Load clinics first without location
    _loadClinics();
    // Try to get location automatically and sort by distance if available
    _tryAutoLocation();
    _scrollController.addListener(_onScroll);
  }
  
  Future<void> _tryAutoLocation() async {
    if (!mounted) return;
    
    LocationService.resetPermissionDenial();
    LocationService.resetPosition();
    
    final position = await LocationService.getCurrentLocation();
    
    if (!mounted) return;
    
    if (position != null) {
      setState(() {
        _userLocation = position;
        // Auto switch to distance sort
        _sortBy = 'distance';
        _clinics.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _loadClinics();
    }
    // If location not available, keep default 'name' sort
  }
  
  Future<void> _requestLocation() async {
    if (!mounted) return;
    
    // Reset permission denial flag to allow asking again
    LocationService.resetPermissionDenial();
    LocationService.resetPosition();
    
    // Request location permission
    final position = await LocationService.getCurrentLocation();
    
    if (!mounted) return;
    
    if (position != null) {
      setState(() {
        _userLocation = position;
        // Reload with distance sort
        _changeSortOption('distance');
      });
    } else {
      // Show dialog if location is not available
      _showLocationPermissionDialog();
    }
  }
  
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل الموقع'),
        content: const Text(
          'لترتيب العيادات حسب الأقرب، يجب تفعيل خدمة الموقع والسماح للتطبيق بالوصول إليه.\n\nيمكنك تفعيله من إعدادات الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _sortClinics(List<ClinicModel> clinics) {
    switch (_sortBy) {
      case 'distance':
        if (_userLocation != null) {
          clinics.sort((a, b) {
            if (a.latitude == null || a.longitude == null) return 1;
            if (b.latitude == null || b.longitude == null) return -1;
            
            final distA = LocationService.calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              a.latitude!,
              a.longitude!,
            );
            final distB = LocationService.calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              b.latitude!,
              b.longitude!,
            );
            return distA.compareTo(distB);
          });
        } else {
          clinics.sort((a, b) => a.doctorName.compareTo(b.doctorName));
        }
        break;
      case 'rating':
        clinics.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'name':
        clinics.sort((a, b) => a.doctorName.compareTo(b.doctorName));
        break;
    }
  }

  void _changeSortOption(String sortOption) {
    // If sorting by distance but location not available, request it
    if (sortOption == 'distance' && _userLocation == null) {
      _requestLocation();
      return;
    }
    
    if (mounted) {
      setState(() {
        _sortBy = sortOption;
        // Clear existing data and reload from database with new sort order
        _clinics.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _loadClinics();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadClinics();
      }
    }
  }

  Future<void> _loadClinics() async {
    if (_isLoading || !mounted) return;
    
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('clinics')
          .where('department', isEqualTo: widget.department.name)
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true);

      // Add orderBy based on sort option to get data from DB in correct order
      switch (_sortBy) {
        case 'rating':
          query = query.orderBy('averageRating', descending: true);
          break;
        case 'name':
          query = query.orderBy('doctorName');
          break;
        case 'distance':
        default:
          // For distance, we'll sort client-side after fetching
          // Use 'doctorName' as orderBy to avoid missing field errors
          query = query.orderBy('doctorName');
          break;
      }

      query = query.limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      _lastDocument = snapshot.docs.last;

      var newClinics = snapshot.docs
          .map((doc) => ClinicModel.fromFirestore(doc))
          .toList();

      // Only sort client-side for distance (requires location calculation)
      if (_sortBy == 'distance' && _userLocation != null) {
        _sortClinics(newClinics);
      }

      setState(() {
        _clinics.addAll(newClinics);
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Check if clinic is open now
  bool _isClinicOpenNow(ClinicModel clinic) {
    final now = DateTime.now();
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final currentDay = dayNames[now.weekday - 1];
    
    // Debug logging
    print('=== Clinic Status Debug ===');
    print('Doctor: ${clinic.doctorName}');
    print('Current DateTime: $now');
    print('Current Day: $currentDay (weekday: ${now.weekday})');
    print('Current Time: ${now.hour}:${now.minute}');
    print('Holidays: ${clinic.holidays}');
    print('Working Hours:');
    clinic.workingHours.forEach((day, hours) {
      print('  $day: from ${hours.from} to ${hours.to}, isClosed: ${hours.isClosed}');
    });
    
    final isOpen = WorkingHoursHelper.isServiceOpen(
      workingHours: clinic.workingHours.map((key, value) => MapEntry(key, value.toMap())),
      holidays: clinic.holidays,
    );
    print('Result: ${isOpen ? "OPEN" : "CLOSED"}');
    print('========================\n');
    
    return isOpen;
  }

  // Build info item widget
  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'عيادات ${widget.department.arabicName}',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0891B2)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Color(0xFF0891B2)),
            tooltip: 'ترتيب حسب',
            onSelected: _changeSortOption,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me,
                      color: _sortBy == 'distance' ? const Color(0xFF0891B2) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الأقرب',
                      style: TextStyle(
                        color: _sortBy == 'distance' ? const Color(0xFF0891B2) : const Color(0xFF0F172A),
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
                      color: _sortBy == 'rating' ? const Color(0xFF0891B2) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الأعلى تقييماً',
                      style: TextStyle(
                        color: _sortBy == 'rating' ? const Color(0xFF0891B2) : const Color(0xFF0F172A),
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
                      color: _sortBy == 'name' ? const Color(0xFF0891B2) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الاسم',
                      style: TextStyle(
                        color: _sortBy == 'name' ? const Color(0xFF0891B2) : const Color(0xFF0F172A),
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
      body: _isLoading && _clinics.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitPulsingGrid(
                    color: const Color(0xFF0891B2),
                    size: 60,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'جاري تحميل العيادات...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : _clinics.isEmpty && !_isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0891B2).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'لا توجد عيادات متاحة حالياً',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'سيتم إضافة عيادات جديدة قريباً',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _clinics.length + ((_isLoading && _clinics.isNotEmpty) || _hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _clinics.length) {
                  // Show loading indicator when fetching more data
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _isLoading
                          ? SpinKitPulsingGrid(
                              color: const Color(0xFF0891B2),
                              size: 40,
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }
                final clinic = _clinics[index];
                return _buildClinicCard(context, clinic, index);
              },
            ),
    );
  }

  Future<void> _refreshClinic(String clinicId, int index) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .get();
      
      if (doc.exists && mounted) {
        setState(() {
          _clinics[index] = ClinicModel.fromFirestore(doc);
        });
      }
    } catch (e) {
      debugPrint('Error refreshing clinic: $e');
    }
  }

  Widget _buildClinicCard(BuildContext context, ClinicModel clinic, int index) {
    // Calculate distance if location available
    String? distance;
    if (_sortBy == 'distance' && _userLocation != null && clinic.latitude != null && clinic.longitude != null) {
      final dist = LocationService.calculateDistance(
        _userLocation!.latitude,
        _userLocation!.longitude,
        clinic.latitude!,
        clinic.longitude!,
      );
      distance = '${dist.toStringAsFixed(1)} كم';
    }
    
    final isOpen = _isClinicOpenNow(clinic);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ClinicDetailsScreen(clinic: clinic),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
            
            // Refresh this specific clinic data after returning
            if (result == true || result == null) {
              _refreshClinic(clinic.id, index);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Doctor Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "د. ${clinic.doctorName}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clinic.specialization,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
             
             Column(
              children: [
                       Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOpen
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        isOpen ? 'متاح الآن' : 'مغلق',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOpen
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                
              ],
             )    

                 
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 12),
                // Info Row
               
             
                Row(
                  children: [
                    // Rating
                    Expanded(
                      flex: 1,
                      child: _buildInfoItem(
                        Icons.star_rounded,
                        '${clinic.averageRating.toStringAsFixed(1)}',
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Likes
                    Expanded(
                      flex: 1,
                      child: _buildInfoItem(
                        Icons.favorite_rounded,
                        '${clinic.totalLikes}',
                        const Color(0xFFEC4899),
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildInfoItem(
                          Icons.location_on_rounded,
                          distance,
                          const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
  Padding(
                 padding: const EdgeInsets.only(bottom:4.0),
                 child: Row(
                  
                    children: [ 
                     // Online Booking badge
                      if (clinic.onlineBookingEnabled) ...[
                     //   const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                       
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 14,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'متاح الحجز أونلاين',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF3B82F6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Incubator badge (if applicable)
                      if (clinic.department == ClinicDepartment.pediatrics &&
                          clinic.hasNursery) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.child_care_rounded,
                                    size: 14,
                                    color: Color(0xFFEC4899),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'يوجد حضانة',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFEC4899),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ]
                 ),
               ),
               




                // Address
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clinic.address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
        ),
      ),
    );
  }
}
