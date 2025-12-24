import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../cubit/gym_cubit.dart';
import '../cubit/gym_state.dart';
import '../widgets/gym_card.dart';
import 'gym_details_screen.dart';
import '../../data/models/gym_model.dart';

class GymsListScreen extends StatefulWidget {
  const GymsListScreen({super.key});

  @override
  State<GymsListScreen> createState() => _GymsListScreenState();
}

class _GymsListScreenState extends State<GymsListScreen> {
  String _searchQuery = '';
  
  // Pagination fields
  final List<GymModel> _gyms = [];
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
    // Load gyms first without location
    _loadGyms();
    // Try to get location automatically and sort by distance if available
    _tryAutoLocation();
    _scrollController.addListener(_onScroll);
  }
  
  Future<void> _tryAutoLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _userLocation = position;
        // Auto switch to distance sort
        _sortBy = 'distance';
        _gyms.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _loadGyms();
    }
    // If location not available, keep default 'name' sort
  }
  
  Future<void> _requestLocation() async {
    // Reset permission denial to allow retry
    LocationService.resetPermissionDenial();
    
    final position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _userLocation = position;
        // Reload with distance sort
        _changeSortOption('distance');
      });
    } else if (mounted) {
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
          'لترتيب الجيمات حسب الأقرب، يجب تفعيل خدمة الموقع والسماح للتطبيق بالوصول إليه.\n\nيمكنك تفعيله من إعدادات الجهاز.',
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
  
  // تحديث جيم واحد بعد الرجوع من صفحة التفاصيل
  Future<void> _refreshSingleGym(String gymId, int index) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .get();
      
      if (doc.exists && mounted) {
        final updatedGym = GymModel.fromFirestore(doc);
        setState(() {
          _gyms[index] = updatedGym;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && _searchQuery.isEmpty) {
        _loadGyms();
      }
    }
  }
  
  Future<void> _loadGyms() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('gyms')
          .where('isApproved', isEqualTo: true);
      
      // Add orderBy based on sort option to get data from DB in correct order
      switch (_sortBy) {
        case 'rating':
          query = query.orderBy('averageRating', descending: true);
          break;
        case 'name':
          query = query.orderBy('name');
          break;
        case 'distance':
        default:
          // For distance, we'll sort client-side after fetching
          // Use 'name' as orderBy to avoid missing field errors
          query = query.orderBy('name');
          break;
      }
      
      query = query.limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        var newGyms = snapshot.docs
            .map((doc) => GymModel.fromFirestore(doc))
            .toList();

        // Only sort client-side for distance (requires location calculation)
        if (_sortBy == 'distance' && _userLocation != null) {
          _sortGyms(newGyms);
        }

        setState(() {
          _gyms.addAll(newGyms);
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (query.isEmpty) {
      // Reload pagination data
      _gyms.clear();
      _lastDocument = null;
      _hasMore = true;
      _loadGyms();
    } else {
      context.read<GymCubit>().searchGyms(query);
    }
  }



  void _sortGyms(List<GymModel> gyms) {
    switch (_sortBy) {
      case 'distance':
        if (_userLocation != null) {
          gyms.sort((a, b) {
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
          gyms.sort((a, b) => a.name.compareTo(b.name));
        }
        break;
      case 'rating':
        gyms.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'name':
        gyms.sort((a, b) => a.name.compareTo(b.name));
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
        _gyms.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _loadGyms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GradientAppBar(
        title: 'الجيمات',
        gradient: AppTheme.gymGradient,
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
                      color: _sortBy == 'distance' ? const Color(0xFFEF4444) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الأقرب',
                      style: TextStyle(
                        color: _sortBy == 'distance' ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
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
                      color: _sortBy == 'rating' ? const Color(0xFFEF4444) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الأعلى تقييماً',
                      style: TextStyle(
                        color: _sortBy == 'rating' ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
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
                      color: _sortBy == 'name' ? const Color(0xFFEF4444) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الاسم',
                      style: TextStyle(
                        color: _sortBy == 'name' ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
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
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'ابحث عن جيم...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.gymGradient.colors[0],
                  size: 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _onSearch('');
                        },
                        color: Colors.grey,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),

          // Gyms List
          Expanded(
            child: _searchQuery.isNotEmpty
                ? BlocBuilder<GymCubit, GymState>(
                    builder: (context, state) {
                      if (state is GymLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SpinKitPulsingGrid(
                                color: AppTheme.gymGradient.colors[0],
                                size: 60,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'جاري تحميل الجيمات...',
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

                      if (state is GymError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('حدث خطأ', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(state.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                              ),
                            ],
                          ),
                        );
                      }

                      final gyms = state is GymLoaded
                          ? state.gyms
                          : state is GymSearchLoaded
                              ? state.searchResults
                              : state is GymFilteredByType
                                  ? state.gyms
                                  : [];

                      if (gyms.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  size: 80,
                                  color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.5),
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
                                  'لم نجد جيمات تطابق بحثك',
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
                        padding: const EdgeInsets.all(16),
                        itemCount: gyms.length,
                        itemBuilder: (context, index) {
                          final gym = gyms[index];
                          String? distance;
                          
                          // Calculate distance if location available
                          if (_userLocation != null) {
                            final dist = LocationService.calculateDistance(
                              _userLocation!.latitude,
                              _userLocation!.longitude,
                              gym.latitude,
                              gym.longitude,
                            );
                            distance = '${dist.toStringAsFixed(1)} كم';
                          }
                          
                          return GymCard(
                            gym: gym,
                            distance: distance,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GymDetailsScreen(gym: gym),
                                ),
                              );
                              // Refresh the gym data when returning
                              if (mounted) {
                                context.read<GymCubit>().searchGyms(_searchQuery);
                              }
                            },
                          );
                        },
                      );
                    },
                  )
                : _isLoading && _gyms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SpinKitPulsingGrid(
                              color: AppTheme.gymGradient.colors[0],
                              size: 60,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'جاري تحميل الجيمات...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _gyms.isEmpty && !_isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    size: 80,
                                    color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'لا توجد جيمات متاحة',
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
                                    'لا توجد جيمات مسجلة حالياً',
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
                        padding: const EdgeInsets.all(16),
                        itemCount: _gyms.length + ((_isLoading && _gyms.isNotEmpty) || _hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _gyms.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _isLoading
                                    ? SpinKitFadingCircle(
                                        color: AppTheme.gymGradient.colors[0],
                                        size: 40,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }

                          final gym = _gyms[index];
                          String? distance;
                          
                          // Calculate distance if location available
                          if (_userLocation != null) {
                            final dist = LocationService.calculateDistance(
                              _userLocation!.latitude,
                              _userLocation!.longitude,
                              gym.latitude,
                              gym.longitude,
                            );
                            distance = '${dist.toStringAsFixed(1)} كم';
                          }
                          
                          return GymCard(
                            gym: gym,
                            distance: distance,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GymDetailsScreen(gym: gym),
                                ),
                              );
                              // Refresh the gym data when returning
                              if (mounted) {
                                _refreshSingleGym(gym.id, index);
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
