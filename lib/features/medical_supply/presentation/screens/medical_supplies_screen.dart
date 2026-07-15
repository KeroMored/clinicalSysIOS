import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clinicalsystem/core/widgets/skeleton_cards.dart';
import 'package:clinicalsystem/core/services/location_service.dart';
import 'package:clinicalsystem/core/utils/pharmacy_hours_helper.dart';
import 'package:clinicalsystem/features/medical_supply/presentation/screens/medical_supply_details_screen.dart';
import 'package:clinicalsystem/features/medical_supply/data/models/medical_supply_model.dart';
import 'package:clinicalsystem/features/medical_supply/presentation/widgets/medical_supply_card.dart';
import 'package:clinicalsystem/features/auth/presentation/cubit/auth_cubit.dart';

class MedicalSuppliesScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const MedicalSuppliesScreen({super.key, this.initialSearchQuery});

  @override
  State<MedicalSuppliesScreen> createState() => _MedicalSuppliesScreenState();
}

class _MedicalSuppliesScreenState extends State<MedicalSuppliesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Pagination fields
  final List<MedicalSupplyModel> _supplies = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  DocumentSnapshot? _geoLastDocument;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasMore = true;
  static const int _pageSize = 10;
  static const int _geoBatchSize = 50;
  int _geoPage = 0;
  bool _geoExhausted = false;
  bool _geoHasMoreServer = true;
  final List<_SupplyDistanceEntry> _geoEntries = [];
  // Location fields
  Position? _userLocation;
  String _sortBy =
      'name'; // distance, rating, name (default to name to show data without location)
  bool _showOpenOnly = false;
  String _searchQuery = '';
  String _activeQuickFilter = 'all'; // all, open, distance, rating

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _tryAutoLocation();

    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
      await _searchSuppliesInDatabase(initialQuery);
    } else {
      await _loadSupplies();
    }

    if (!mounted) return;
    setState(() => _isInitializing = false);
  }

  Future<void> _tryAutoLocation() async {
    Position? position;
    try {
      position = await LocationService.getCurrentLocation().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (_) {
      position = null;
    }

    if (position != null && mounted) {
      if (mounted) {
        setState(() {
          _userLocation = position;
        });
      }
    }
    // If location not available, keep default 'name' sort
  }

  Future<void> _requestLocation() async {
    // Reset permission denial to allow retry
    LocationService.resetPermissionDenial();

    final position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      if (mounted) {
        setState(() {
          _userLocation = position;
          // Reload with distance sort
          _changeSortOption('distance');
        });
      }
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
          'لترتيب المستلزمات الطبية حسب الأقرب، يجب تفعيل خدمة الموقع والسماح للتطبيق بالوصول إليه.\n\nيمكنك تفعيله من إعدادات الجهاز.',
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
      if (!_isLoading && _hasMore && _searchQuery.isEmpty) {
        _loadSupplies();
      }
    }
  }

  Future<void> _loadSupplies() async {
    if (_isLoading || !mounted || !_hasMore) return;

    print('🔍 Loading supplies... Current count: ${_supplies.length}');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (_sortBy == 'distance' && _userLocation != null) {
        await _loadSuppliesByDistance();
      } else {
        await _loadSuppliesNormal();
      }

      print('✅ Total supplies now: ${_supplies.length}');
    } catch (e) {
      print('❌ Error loading supplies: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المستلزمات الطبية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSuppliesByDistance() async {
    try {
      final requiredCount = (_geoPage + 1) * _pageSize;
      await _ensureGeoCandidates(requiredCount);

      final sorted = List<_SupplyDistanceEntry>.from(_geoEntries)
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      final visible = sorted.take(requiredCount).map((e) => e.supply).toList();

      if (!mounted) return;
      setState(() {
        _geoPage++;
        _geoExhausted = !_geoHasMoreServer && visible.length >= sorted.length;
        _supplies
          ..clear()
          ..addAll(visible);
        _hasMore = !_geoExhausted;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading supplies by distance: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _ensureGeoCandidates(int requiredCount) async {
    if (_userLocation == null) return;
    if (!_geoHasMoreServer) return;

    while (_geoHasMoreServer && _geoEntries.length < requiredCount) {
      Query baseQuery = FirebaseFirestore.instance
          .collection('medical_supplies')
          .where('status', isEqualTo: 'approved');

      baseQuery = baseQuery.orderBy('name');

      Query query = baseQuery.limit(_geoBatchSize);
      if (_geoLastDocument != null) {
        query = query.startAfterDocument(_geoLastDocument!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        _geoHasMoreServer = false;
        break;
      }

      _geoLastDocument = snapshot.docs.last;
      _geoHasMoreServer = snapshot.docs.length == _geoBatchSize;

      for (final doc in snapshot.docs) {
        try {
          final s = MedicalSupplyModel.fromFirestore(doc);
          if (_showOpenOnly &&
              !PharmacyHoursHelper.isPharmacyOpen(
                workingHours: s.workingHours,
                holidays: s.holidays,
              )) {
            continue;
          }

          final dist = LocationService.calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            s.latitude,
            s.longitude,
          );

          _geoEntries.add(
            _SupplyDistanceEntry(supply: s, distanceKm: dist),
          );
        } catch (_) {
          // skip invalid docs
        }
      }

      if (!_geoHasMoreServer) {
        break;
      }
    }
  }

  Future<void> _loadSuppliesNormal() async {
    Query baseQuery = FirebaseFirestore.instance
        .collection('medical_supplies')
        .where('status', isEqualTo: 'approved');

    switch (_sortBy) {
      case 'rating':
        baseQuery = baseQuery.orderBy('averageRating', descending: true);
        break;
      case 'name':
      default:
        baseQuery = baseQuery.orderBy('name');
        break;
    }

    DocumentSnapshot? cursor = _lastDocument;
    bool hasMoreLocal = _hasMore;
    final collected = <MedicalSupplyModel>[];

    while (hasMoreLocal && collected.length < _pageSize) {
      Query query = baseQuery.limit(_pageSize);

      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMoreLocal = false;
        break;
      }

      cursor = snapshot.docs.last;
      hasMoreLocal = snapshot.docs.length == _pageSize;

      final batch = snapshot.docs
          .map((doc) {
            try {
              return MedicalSupplyModel.fromFirestore(doc);
            } catch (e) {
              print('❌ Error parsing supply ${doc.id}: $e');
              return null;
            }
          })
          .whereType<MedicalSupplyModel>()
          .where((s) => !_showOpenOnly || PharmacyHoursHelper.isPharmacyOpen(
                workingHours: s.workingHours,
                holidays: s.holidays,
              ))
          .toList();

      collected.addAll(batch);
    }

    final pageItems = collected.take(_pageSize).toList();

    if (mounted) {
      setState(() {
        _lastDocument = cursor;
        _supplies.addAll(pageItems);
        _hasMore = hasMoreLocal;
        _isLoading = false;
      });
    }
  }

  void _sortSupplies(List<MedicalSupplyModel> supplies) {
    switch (_sortBy) {
      case 'distance':
        if (_userLocation != null) {
          supplies.sort((a, b) {
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
          supplies.sort((a, b) => a.name.compareTo(b.name));
        }
        break;
      case 'rating':
        supplies.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'name':
        supplies.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  bool _matchesSupplyQuickFilters(MedicalSupplyModel supply) {
    if (_showOpenOnly) {
      return PharmacyHoursHelper.isPharmacyOpen(
        workingHours: supply.workingHours,
        holidays: supply.holidays,
      );
    }

    return true;
  }

  void _changeSortOption(String sortOption) {
    if (sortOption == 'all') {
      if (mounted) {
        setState(() {
          _activeQuickFilter = 'all';
          _showOpenOnly = false;
          _sortBy = 'name';
        });
        if (_searchQuery.isNotEmpty) {
          _searchSuppliesInDatabase(_searchQuery);
        } else {
          _refreshSupplies();
        }
      }
      return;
    }

    if (sortOption == 'open') {
      if (mounted) {
        setState(() {
          _activeQuickFilter = 'open';
          _showOpenOnly = true;
          _sortBy = 'name';
        });
        if (_searchQuery.isNotEmpty) {
          _searchSuppliesInDatabase(_searchQuery);
        } else {
          _refreshSupplies();
        }
      }
      return;
    }

    // If sorting by distance but location not available, request it
    if (sortOption == 'distance' && _userLocation == null) {
      _requestLocation();
      return;
    }

    if (mounted) {
      setState(() {
        _activeQuickFilter = sortOption;
        _showOpenOnly = false;
        _sortBy = sortOption;

        _supplies.clear();
        _lastDocument = null;
        _geoLastDocument = null;
        _hasMore = true;
        _geoPage = 0;
        _geoExhausted = false;
        _geoHasMoreServer = true;
        _geoEntries.clear();
      });
      if (_searchQuery.isNotEmpty) {
        _searchSuppliesInDatabase(_searchQuery);
      } else {
        _loadSupplies();
      }
    }
  }

  /// Reload a specific supply's data after changes
  Future<void> _reloadSupply(String supplyId) async {
    try {
      print('🔄 Reloading supply: $supplyId');
      final doc = await FirebaseFirestore.instance
          .collection('medical_supplies')
          .doc(supplyId)
          .get();

      if (doc.exists && mounted) {
        final updatedSupply = MedicalSupplyModel.fromFirestore(doc);
        if (mounted) {
          setState(() {
            final index = _supplies.indexWhere((s) => s.id == supplyId);
            if (index != -1) {
              _supplies[index] = updatedSupply;
              print('✅ Supply updated in list');
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error reloading supply: $e');
    }
  }

  Future<void> _refreshSupplies() async {
    if (!mounted) return;
    setState(() {
      _supplies.clear();
      _lastDocument = null;
      _geoLastDocument = null;
      _hasMore = true;
      _searchQuery = '';
      _searchController.clear();
      _geoPage = 0;
      _geoExhausted = false;
      _geoHasMoreServer = true;
      _geoEntries.clear();
    });
    await _loadSupplies();
  }

  Future<void> _searchSuppliesInDatabase(String rawQuery) async {
    final trimmed = rawQuery.trim();

    if (trimmed.isEmpty) {
      await _refreshSupplies();
      return;
    }

    if (!mounted) return;
    setState(() {
      _searchQuery = trimmed;
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('medical_supplies')
          .where('status', isEqualTo: 'approved');

      final snapshot = await query.get();

      final lower = trimmed.toLowerCase();
      final results = snapshot.docs
          .map((doc) => MedicalSupplyModel.fromFirestore(doc))
          .where((supply) {
            return supply.name.toLowerCase().contains(lower) ||
                supply.address.toLowerCase().contains(lower) ||
                supply.center.toLowerCase().contains(lower) ||
                supply.governorate.toLowerCase().contains(lower);
          })
          .where(_matchesSupplyQuickFilters)
          .toList();

      _sortSupplies(results);

      if (!mounted) return;
      setState(() {
        _supplies
          ..clear()
          ..addAll(results);
        _hasMore = false;
        _lastDocument = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في البحث: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<MedicalSupplyModel> _getDisplayedSupplies() {
    return _supplies;
  }

  Widget _buildSortChip({
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0B8293) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF0B8293) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? Colors.white : const Color(0xFF334155),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedSupplies = _getDisplayedSupplies();
    final hasSearchQuery = _searchQuery.isNotEmpty;
    final showBottomLoader = _isLoading && _supplies.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'أماكن المستلزمات الطبية',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF0B8293),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0B8293),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: (_isInitializing || _isLoading) && _supplies.isEmpty
          ? _buildInitialLoadingSkeleton()
          : Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchSuppliesInDatabase,
                      onChanged: (value) {
                        if (value.trim().isEmpty && _searchQuery.isNotEmpty) {
                          _searchSuppliesInDatabase('');
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: InputBorder.none,
                        hintText: 'بحث عن أماكن مستلزمات طبية ...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => _searchSuppliesInDatabase(
                            _searchController.text,
                          ),
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF0B8293),
                            size: 20,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSortChip(
                        label: 'الكل',
                        icon: Icons.grid_view_rounded,
                        selected: _activeQuickFilter == 'all',
                        onTap: () => _changeSortOption('all'),
                      ),
                      const SizedBox(width: 3),
                      _buildSortChip(
                        label: 'متاح الآن',
                        icon: Icons.access_time_rounded,
                        selected: _activeQuickFilter == 'open',
                        onTap: () => _changeSortOption('open'),
                      ),
                      const SizedBox(width: 3),
                      _buildSortChip(
                        label: 'الأقرب لي',
                        icon: Icons.near_me_rounded,
                        selected: _activeQuickFilter == 'distance',
                        onTap: () => _changeSortOption('distance'),
                      ),
                      const SizedBox(width: 3),
                      _buildSortChip(
                        label: 'الأعلى تقييماً',
                        icon: Icons.star_rounded,
                        selected: _activeQuickFilter == 'rating',
                        onTap: () => _changeSortOption('rating'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: displayedSupplies.isEmpty
                      ? Center(
                          child: Text(
                            hasSearchQuery
                                ? 'لا توجد أماكن مستلزمات طبية مطابقة لبحثك'
                                : 'لا توجد أماكن مستلزمات طبية متاحة حالياً',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshSupplies,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                            itemCount:
                                displayedSupplies.length +
                                (showBottomLoader ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == displayedSupplies.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Center(
                                    child: SpinKitPulsingGrid(
                                      color: Color(0xFF06B6D4),
                                      size: 22,
                                    ),
                                  ),
                                );
                              }

                              final supply = displayedSupplies[index];
                              return MedicalSupplyCard(
                                supply: supply,
                                userLocation: _userLocation,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider.value(
                                        value: context.read<AuthCubit>(),
                                        child: MedicalSupplyDetailsScreen(
                                          supply: supply,
                                        ),
                                      ),
                                    ),
                                  );
                                  if (mounted) {
                                    _reloadSupply(supply.id);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildInitialLoadingSkeleton() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const SkeletonShimmer(
            child: SkeletonBox(
              width: double.infinity,
              height: 42,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return const SkeletonShimmer(
                child: SkeletonBox(
                  width: 86,
                  height: 34,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemCount: 4,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            itemCount: 5,
            itemBuilder: (context, index) => const SkeletonPharmacyCard(),
          ),
        ),
      ],
    );
  }
}

class _SupplyDistanceEntry {
  final MedicalSupplyModel supply;
  final double distanceKm;

  const _SupplyDistanceEntry({required this.supply, required this.distanceKm});
}
