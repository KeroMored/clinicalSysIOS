import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/rehabilitation_center_model.dart';
import '../cubit/rehabilitation_cubit.dart';
import '../cubit/rehabilitation_state.dart';
import 'rehabilitation_center_detail_screen.dart';
import '../widgets/rehabilitation_center_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';

class RehabilitationCentersListScreen extends StatefulWidget {
  const RehabilitationCentersListScreen({super.key});

  @override
  State<RehabilitationCentersListScreen> createState() => _RehabilitationCentersListScreenState();
}

class _RehabilitationCentersListScreenState extends State<RehabilitationCentersListScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // distance, rating, name (default to name)
  
  // Pagination fields
  final List<RehabilitationCenterModel> _centers = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool _hasMore = true;
  static const int _pageSize = 10;
  
  // Location fields
  Position? _userLocation;

  @override
  void initState() {
    super.initState();
    // Try to get location first, then load centers
    _initializeData();
    _scrollController.addListener(_onScroll);
  }
  
  Future<void> _initializeData() async {
    // Try to get location automatically
    await _tryAutoLocation();
    // Load centers (with or without location)
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    await _loadCenters();
  }
  
  Future<void> _tryAutoLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
        if (mounted) {
          setState(() {
            _userLocation = position;
            // Auto switch to distance sort
            _sortBy = 'distance';
          });
        }
      } catch (e) {
        // Silently fail if location not available
      }
    } catch (e) {
      // Silently fail if location not available
    }
  }
  
  Future<void> _requestLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showLocationPermissionDialog();
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) _showLocationPermissionDialog();
        return;
      }
      
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
        if (mounted) {
          setState(() {
            _userLocation = position;
            // Reload with distance sort
            _changeSortOption('distance');
          });
        }
      } catch (e) {
        if (mounted) _showLocationPermissionDialog();
      }
    } catch (e) {
      if (mounted) _showLocationPermissionDialog();
    }
  }
  
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل الموقع'),
        content: const Text(
          'لترتيب المراكز حسب الأقرب، يجب تفعيل خدمة الموقع والسماح للتطبيق بالوصول إليه.\n\nيمكنك تفعيله من إعدادات الجهاز.',
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
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshCenters() async {
    setState(() {
      _centers.clear();
      _lastDocument = null;
      _hasMore = true;
      _isLoading = true;
    });
    await _loadCenters();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && _searchQuery.isEmpty) {
        _loadCenters();
      }
    }
  }
  
  Future<void> _loadCenters() async {
    if (!mounted) return;
    
    // Only prevent multiple simultaneous loads after the first load
    if (_isLoading && _centers.isNotEmpty) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection('rehabilitation_centers')
          .where('isApproved', isEqualTo: true);
      
      // Add orderBy based on sort option to get data from DB in correct order
      switch (_sortBy) {
        case 'rating':
          query = query.orderBy('averageRating', descending: true);
          break;
        case 'name':
          query = query.orderBy('centerName');
          break;
        case 'distance':
        default:
          // For distance, we'll sort client-side after fetching
          // Use 'centerName' as orderBy to avoid missing field errors
          query = query.orderBy('centerName');
          break;
      }
      
      query = query.limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        var newCenters = snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return RehabilitationCenterModel.fromMap(data);
            })
            .toList();

        // Only sort client-side for distance (requires location calculation)
        if (_sortBy == 'distance' && _userLocation != null) {
          _sortCenters(newCenters);
        }

        if (mounted) {
          setState(() {
            _centers.addAll(newCenters);
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula
    const double earthRadius = 6371; // Radius of earth in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
  
  void _sortCenters(List<RehabilitationCenterModel> centers) {
    switch (_sortBy) {
      case 'distance':
        if (_userLocation != null) {
          centers.sort((a, b) {
            final distA = _calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              a.latitude,
              a.longitude,
            );
            final distB = _calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              b.latitude,
              b.longitude,
            );
            return distA.compareTo(distB);
          });
        } else {
          centers.sort((a, b) => a.centerName.compareTo(b.centerName));
        }
        break;
      case 'rating':
        centers.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'name':
        centers.sort((a, b) => a.centerName.compareTo(b.centerName));
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
        _centers.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _loadCenters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'مراكز التأهيل والتخاطب',
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                      color: _sortBy == 'distance' ? const Color(0xFF7C3AED) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الأقرب',
                      style: TextStyle(
                        color: _sortBy == 'distance' ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
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
                      color: _sortBy == 'rating' ? const Color(0xFF7C3AED) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الأعلى تقييماً',
                      style: TextStyle(
                        color: _sortBy == 'rating' ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
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
                      color: _sortBy == 'name' ? const Color(0xFF7C3AED) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الاسم',
                      style: TextStyle(
                        color: _sortBy == 'name' ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
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
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن مركز تأهيل أو تخاطب...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF7C3AED),
                  size: 24,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (value.length >= 2) {
                  context.read<RehabilitationCubit>().searchCenters(value);
                } else if (value.isEmpty) {
                  context.read<RehabilitationCubit>().getAvailableCenters();
                }
              },
            ),
          ),

          // Centers List
          Expanded(
            child: _searchQuery.isNotEmpty
                ? BlocBuilder<RehabilitationCubit, RehabilitationState>(
                    builder: (context, state) {
                      if (state is RehabilitationLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SpinKitPulsingGrid(
                                color: const Color(0xFF7C3AED),
                                size: 60,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'جاري تحميل المراكز...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is RehabilitationLoaded) {
                        final filteredCenters = state.centers.where((center) {
                          return center.centerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              center.address.toLowerCase().contains(_searchQuery.toLowerCase());
                        }).toList();
                        
                        // Sort filtered results
                        _sortCenters(filteredCenters);

                        if (filteredCenters.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.medical_services_outlined,
                                    size: 80,
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'لا توجد نتائج',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    'لم نجد مراكز تأهيل تطابق بحثك',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredCenters.length,
                          itemBuilder: (context, index) {
                            final center = filteredCenters[index];
                            String? distance;
                            
                            // Calculate distance if location available
                            if (_userLocation != null) {
                              final dist = _calculateDistance(
                                _userLocation!.latitude,
                                _userLocation!.longitude,
                                center.latitude,
                                center.longitude,
                              );
                              distance = '${dist.toStringAsFixed(1)} كم';
                            }
                            
                            return RehabilitationCenterCard(
                              center: center,
                              distance: distance,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RehabilitationCenterDetailScreen(center: center),
                                  ),
                                );
                                // Refresh data when returning from details
                                if (mounted) {
                                  _refreshCenters();
                                }
                              },
                            );
                          },
                        );
                      }

                      if (state is RehabilitationError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 100, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('حدث خطأ: ${state.message}', style: const TextStyle(fontSize: 16, color: Colors.red), textAlign: TextAlign.center),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  )
                : _isLoading && _centers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SpinKitPulsingGrid(
                              color: const Color(0xFF7C3AED),
                              size: 60,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'جاري تحميل المراكز...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _centers.isEmpty && !_isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.medical_services_outlined,
                                    size: 80,
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'لا توجد مراكز متاحة',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    'لا توجد مراكز تأهيل وتخاطب مسجلة حالياً',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _centers.length + ((_isLoading && _centers.isNotEmpty) || _hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _centers.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _isLoading
                                    ? SpinKitFadingCircle(
                                        color: AppTheme.rehabilitationGradient.colors[0],
                                        size: 40,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }

                          final center = _centers[index];
                          String? distance;
                          
                          // Calculate distance if location available
                          if (_userLocation != null) {
                            final dist = _calculateDistance(
                              _userLocation!.latitude,
                              _userLocation!.longitude,
                              center.latitude,
                              center.longitude,
                            );
                            distance = '${dist.toStringAsFixed(1)} كم';
                          }
                          
                          return RehabilitationCenterCard(
                            center: center,
                            distance: distance,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RehabilitationCenterDetailScreen(center: center),
                                ),
                              );
                              // Refresh data when returning from details
                              if (mounted) {
                                _refreshCenters();
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

}
