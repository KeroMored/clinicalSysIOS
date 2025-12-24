import 'package:clinicalsystem/features/pharmacy/presentation/widgets/pharmacy_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../cubit/pharmacy_cubit.dart';
import '../cubit/pharmacy_state.dart';
import 'pharmacy_details_screen.dart';
import '../../data/repositories/pharmacy_repository.dart';
import '../../data/models/pharmacy_model.dart';

class ThePharmaciesScreen extends StatefulWidget {
  const ThePharmaciesScreen({super.key});

  @override
  State<ThePharmaciesScreen> createState() => _ThePharmaciesScreenState();
}

class _ThePharmaciesScreenState extends State<ThePharmaciesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  // Pagination fields
  final List<PharmacyModel> _pharmacies = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 10;  
  // Location fields
  Position? _userLocation;
  String _sortBy = 'name'; // distance, rating, name (default to name to show data without location)

  @override
  void initState() {
    super.initState();
    // Load pharmacies first without location
    _loadPharmacies();
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
        _pharmacies.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _loadPharmacies();
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
          'لترتيب الصيدليات حسب الأقرب، يجب تفعيل خدمة الموقع والسماح للتطبيق بالوصول إليه.\n\nيمكنك تفعيله من إعدادات الجهاز.',
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
  
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && !_isSearching) {
        _loadPharmacies();
      }
    }
  }
  
  Future<void> _loadPharmacies() async {
    if (_isLoading || !mounted) return;

    print('🔍 Loading pharmacies... Current count: ${_pharmacies.length}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('pharmacies')
          .where('status', isEqualTo: 'approved');

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

      print('📡 Executing Firestore query with sortBy: $_sortBy');
      final snapshot = await query.get();
      print('✅ Got ${snapshot.docs.length} documents from Firestore');

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        var newPharmacies = snapshot.docs
            .map((doc) {
              try {
                print('📦 Parsing pharmacy: ${doc.id}');
                return PharmacyModel.fromFirestore(doc);
              } catch (e) {
                print('❌ Error parsing pharmacy ${doc.id}: $e');
                return null;
              }
            })
            .whereType<PharmacyModel>()
            .toList();

        print('✅ Successfully parsed ${newPharmacies.length} pharmacies');

        // Only sort client-side for distance (requires location calculation)
        if (_sortBy == 'distance' && _userLocation != null) {
          _sortPharmacies(newPharmacies);
        }

        setState(() {
          _pharmacies.addAll(newPharmacies);
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoading = false;
        });
        
        print('✅ Total pharmacies now: ${_pharmacies.length}');
      } else {
        print('⚠️ No pharmacies found in Firestore');
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading pharmacies: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الصيدليات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sortPharmacies(List<PharmacyModel> pharmacies) {
    switch (_sortBy) {
      case 'distance':
        if (_userLocation != null) {
          pharmacies.sort((a, b) {
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
          pharmacies.sort((a, b) => a.name.compareTo(b.name));
        }
        break;
      case 'rating':
        pharmacies.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'name':
        pharmacies.sort((a, b) => a.name.compareTo(b.name));
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
        _pharmacies.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _loadPharmacies();
    }
  }

  /// Reload a specific pharmacy's data after changes
  Future<void> _reloadPharmacy(String pharmacyId) async {
    try {
      print('🔄 Reloading pharmacy: $pharmacyId');
      final doc = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .get();
      
      if (doc.exists && mounted) {
        final updatedPharmacy = PharmacyModel.fromFirestore(doc);
        setState(() {
          final index = _pharmacies.indexWhere((p) => p.id == pharmacyId);
          if (index != -1) {
            _pharmacies[index] = updatedPharmacy;
            print('✅ Pharmacy updated in list');
          }
        });
      }
    } catch (e) {
      print('❌ Error reloading pharmacy: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    context.read<PharmacyCubit>().loadPharmaciesAndOffers();
                  });
                },
              ),
              title: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن صيدلية...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      context.read<PharmacyCubit>().searchPharmacies(value);
                    } else {
                      context.read<PharmacyCubit>().loadPharmaciesAndOffers();
                    }
                  },
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: const Color(0xFFE2E8F0),
                ),
              ),
            )
          : AppBar(
              title: const Text(
                'جميع الصيدليات',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'ترتيب حسب',
                  onSelected: _changeSortOption,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'distance',
                      child: Row(
                        children: [
                          Icon(
                            Icons.near_me,
                            color: _sortBy == 'distance' ? const Color(0xFF06B6D4) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'الأقرب',
                            style: TextStyle(
                              color: _sortBy == 'distance' ? const Color(0xFF06B6D4) : const Color(0xFF0F172A),
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
                            color: _sortBy == 'rating' ? const Color(0xFF06B6D4) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'الأعلى تقييماً',
                            style: TextStyle(
                              color: _sortBy == 'rating' ? const Color(0xFF06B6D4) : const Color(0xFF0F172A),
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
                            color: _sortBy == 'name' ? const Color(0xFF06B6D4) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'الاسم',
                            style: TextStyle(
                              color: _sortBy == 'name' ? const Color(0xFF06B6D4) : const Color(0xFF0F172A),
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
      floatingActionButton: !_isSearching
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF06B6D4),
                    Color(0xFF0891B2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  setState(() => _isSearching = true);
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.search, color: Colors.white),
              ),
            )
          : null,
      backgroundColor: const Color(0xFFFAFBFC),
      body: _isSearching
          ? BlocBuilder<PharmacyCubit, PharmacyState>(
              builder: (context, state) {
                if (state is PharmacyLoading || state is PharmacySearchLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitWave(
                          color: const Color(0xFF06B6D4),
                          size: 50,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'جاري البحث...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is PharmacyError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'حدث خطأ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                  List<dynamic> pharmacies = [];
                  if (state is PharmacyLoaded) {
                    pharmacies = state.pharmacies;
                  } else if (state is PharmacySearchLoaded) {
                    pharmacies = state.pharmacies;
                  }

                if (pharmacies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.local_pharmacy,
                            size: 64,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'لا توجد نتائج للبحث',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'جرب البحث بكلمات مختلفة',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: pharmacies.length,
                    itemBuilder: (context, index) {
                      return PharmacyCard(
                        pharmacy: pharmacies[index],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => PharmacyCubit(PharmacyRepository()),
                                child: PharmacyDetailsScreen(pharmacyId: pharmacies[index].id),
                              ),
                            ),
                          );
                          // Reload pharmacy data after returning from details
                          if (mounted) {
                            _reloadPharmacy(pharmacies[index].id);
                          }
                        },
                      );
                    },
                  );
                },
              )
          : _isLoading && _pharmacies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitPulsingGrid(
                        color: const Color(0xFF06B6D4),
                        size: 60,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'جاري تحميل الصيدليات...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              : _pharmacies.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_pharmacy,
                              size: 64,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'لا توجد صيدليات متاحة حالياً',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'سيتم عرض الصيدليات هنا قريباً',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _pharmacies.length + ((_isLoading && _pharmacies.isNotEmpty) || _hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _pharmacies.length) {
                        // Show loading indicator when fetching more data
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: _isLoading
                                ? SpinKitThreeBounce(
                                    color: const Color(0xFF06B6D4),
                                    size: 30,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }

                      return PharmacyCard(
                        pharmacy: _pharmacies[index],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => PharmacyCubit(PharmacyRepository()),
                                child: PharmacyDetailsScreen(pharmacyId: _pharmacies[index].id),
                              ),
                            ),
                          );
                          // Reload pharmacy data after returning
                          if (mounted) {
                            _reloadPharmacy(_pharmacies[index].id);
                          }
                        },
                      );
                  },
                ),
    );
  }
}