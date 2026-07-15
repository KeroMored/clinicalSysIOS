import 'package:flutter/material.dart';

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
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/like_button.dart';
import '../../../../core/widgets/report_button.dart';
import '../../../pharmacy/presentation/widgets/reviews_dialog.dart';
import 'lab_booking_screen.dart';
import 'laboratory_details_clinic_style_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class LaboratoryHomePage extends StatefulWidget {
  const LaboratoryHomePage({super.key});

  @override
  State<LaboratoryHomePage> createState() => _LaboratoryHomePageState();
}

class _LaboratoryHomePageState extends State<LaboratoryHomePage> {
  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _primaryAccent = Color(0xFF0B8293);
  final LaboratoryRepository _labRepo = LaboratoryRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<LaboratoryModel> _searchResults = [];
  bool _isSearchLoading = false;
  String? _searchError;
  bool _showOpenOnly = false;
  String _activeQuickFilter = 'all'; // all, open, distance, rating

  // Pagination fields
  final List<LaboratoryModel> _laboratories = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasMore = true;
  String? _loadError;
  static const int _pageSize = 10;

  // Location fields
  Position? _userLocation;
  String _sortBy = 'name'; // distance, rating, name

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _tryAutoLocation();
      await _resetAndReload();
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
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
      setState(() {
        _userLocation = position;
        _sortBy = 'distance';
      });
    }
  }

  List<LaboratoryModel> _mapVisibleLabs(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) => LaboratoryModel.fromFirestore(doc))
        .where((lab) => lab.isVisible)
        .toList();
  }

  void _resetPagination() {
    _laboratories.clear();
    _lastDocument = null;
    _hasMore = true;
  }

  Future<void> _resetAndReload() async {
    if (!mounted) return;
    setState(() {
      _resetPagination();
      _loadError = null;
    });
    await _loadLaboratories();
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

  Future<void> _requestLocation() async {
    LocationService.resetPermissionDenial();
    LocationService.resetPosition();

    final position = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (position == null) {
      _showLocationPermissionDialog();
      return;
    }

    setState(() {
      _userLocation = position;
      _sortBy = 'distance';
      _activeQuickFilter = 'distance';
    });
    await _resetAndReload();
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل الموقع'),
        content: const Text(
          'لترتيب المعامل حسب الأقرب، فعّل خدمة الموقع ومنح إذن الوصول للتطبيق.',
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

  Future<void> _changeSortOption(String sortOption) async {
    if (sortOption == 'distance' && _userLocation == null) {
      await _requestLocation();
      return;
    }

    if (_sortBy == sortOption || !mounted) return;
    setState(() {
      _sortBy = sortOption;
    });

    if (_searchQuery.isNotEmpty) {
      await _performSearch(_searchQuery);
      return;
    }

    await _resetAndReload();
  }

  bool _isLabOpenNow(LaboratoryModel lab) {
    return WorkingHoursHelper.isServiceOpen(
      workingHours: lab.workingHours.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    );
  }

  String? _distanceForLab(LaboratoryModel lab) {
    if (_userLocation == null) return null;
    final distance = LocationService.calculateDistance(
      _userLocation!.latitude,
      _userLocation!.longitude,
      lab.latitude,
      lab.longitude,
    );
    return '${distance.toStringAsFixed(1)} كم';
  }

  bool _matchesLabQuickFilters(LaboratoryModel lab) {
    if (_showOpenOnly && !_isLabOpenNow(lab)) {
      return false;
    }

    return true;
  }

  Future<void> _onQuickFilterSelected(String filterId) async {
    if (!mounted) return;

    if (filterId == 'open') {
      setState(() {
        _activeQuickFilter = 'open';
        _showOpenOnly = true;
      });

      if (_searchQuery.isNotEmpty) {
        await _performSearch(_searchQuery);
      } else {
        await _resetAndReload();
      }
      return;
    }

    setState(() {
      _activeQuickFilter = filterId;
      _showOpenOnly = false;
    });

    if (filterId == 'all') {
      await _changeSortOption('name');
    } else if (filterId == 'distance') {
      await _changeSortOption('distance');
    } else if (filterId == 'rating') {
      await _changeSortOption('rating');
    }
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    IconData? icon,
  }) {
    final selected = _activeQuickFilter == id;

    return InkWell(
      onTap: () => _onQuickFilterSelected(id),
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && _searchQuery.isEmpty) {
        _loadLaboratories();
      }
    }
  }

  Future<void> _performSearch([String? rawQuery]) async {
    final query = (rawQuery ?? _searchController.text).trim();

    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    if (!mounted) return;
    setState(() {
      _searchQuery = query;
      _isSearchLoading = true;
      _searchError = null;
    });

    try {
      final results = await _labRepo.searchLaboratoriesByName(query);
      if (!mounted) return;

      final filtered = results.where(_matchesLabQuickFilters).toList();
      _sortLaboratories(filtered);

      setState(() {
        _searchResults
          ..clear()
          ..addAll(filtered);
        _isSearchLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults.clear();
        _isSearchLoading = false;
        _searchError = 'تعذر تنفيذ البحث حاليا، حاول مرة أخرى';
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    if (!mounted) return;

    setState(() {
      _searchQuery = '';
      _searchResults.clear();
      _searchError = null;
      _isSearchLoading = false;
    });

    if (_laboratories.isEmpty) {
      _resetAndReload();
    }
  }

  Future<void> _loadLaboratories() async {
    if (_isLoading || !mounted || !_hasMore) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
        Query baseQuery = FirebaseFirestore.instance
          .collection('laboratories')
          .where('status', isEqualTo: 'approved');

      DocumentSnapshot? cursor = _lastDocument;
      bool hasMoreLocal = _hasMore;
      final collectedLabs = <LaboratoryModel>[];

      while (hasMoreLocal && collectedLabs.length < _pageSize) {
        Query query = baseQuery;

        switch (_sortBy) {
          case 'rating':
            query = query.orderBy('averageRating', descending: true);
            break;
          case 'name':
            query = query.orderBy('name');
            break;
          case 'distance':
          default:
            // Distance is still computed client-side after fetch.
            query = query.orderBy('name');
            break;
        }

        query = query.limit(_pageSize);

        if (cursor != null) {
          query = query.startAfterDocument(cursor);
        }

        late QuerySnapshot snapshot;
        try {
          snapshot = await query.get();
        } catch (_) {
          Query fallbackQuery = baseQuery.orderBy(FieldPath.documentId);
          fallbackQuery = fallbackQuery.limit(_pageSize);
          if (cursor != null) {
            fallbackQuery = fallbackQuery.startAfterDocument(cursor);
          }
          snapshot = await fallbackQuery.get();
        }

        if (snapshot.docs.isEmpty) {
          hasMoreLocal = false;
          break;
        }

        cursor = snapshot.docs.last;
        hasMoreLocal = snapshot.docs.length == _pageSize;

        final visibleLabs = _mapVisibleLabs(snapshot);
        final matchedLabs = visibleLabs.where(_matchesLabQuickFilters).toList();
        if (matchedLabs.isNotEmpty) {
          collectedLabs.addAll(matchedLabs);
        }
      }

      final pageLabs = collectedLabs.take(_pageSize).toList();
      if (_sortBy == 'distance' && _userLocation != null) {
        _sortLaboratories(pageLabs);
      }

      if (!mounted) return;
      setState(() {
        _lastDocument = cursor;
        _laboratories.addAll(pageLabs);
        _hasMore = hasMoreLocal;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'تعذر تحميل المعامل حاليا، حاول مرة أخرى';
        });
      }
    }
  }

  Widget _buildLaboratoryHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.laboratoryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.science_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر المعمل المناسب',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'نتائج سريعة ومعامل معتمدة بالقرب منك',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'معامل التحاليل',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0891B2),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),

          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFAFBFC), Color(0xFFF1F5F9)],
            ),
          ),
          child: Column(
            children: [
              //   _buildLaboratoryHeaderCard(),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          FocusScope.of(context).unfocus();
                          _performSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'ابحث عن معمل...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _primaryAccent,
                          ),
                          suffixIcon: _searchController.text.trim().isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _primaryAccent,
                              width: 1.3,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) {
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: _primaryAccent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _performSearch();
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  children: [
                    _buildFilterChip(
                      id: 'all',
                      label: 'الكل',
                      icon: Icons.grid_view_rounded,
                    ),
                    const SizedBox(width: 3),
                    _buildFilterChip(
                      id: 'open',
                      label: 'متاح الآن',
                      icon: Icons.access_time_rounded,
                    ),
                    const SizedBox(width: 3),
                    _buildFilterChip(
                      id: 'distance',
                      label: 'الأقرب',
                      icon: Icons.near_me_rounded,
                    ),
                    const SizedBox(width: 3),
                    _buildFilterChip(
                      id: 'rating',
                      label: 'الأعلى تقييما',
                      icon: Icons.star_rounded,
                    ),
                  ],
                ),
              ),

              // Laboratory List
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _isSearchLoading
                          ? const Center(child: AppLoadingIndicator())
                          : _searchError != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 72,
                                    color: Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchError!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: _performSearch,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            )
                          : Builder(
                              builder: (context) {
                                final laboratories = _searchResults;

                                if (laboratories.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.science_outlined,
                                          size: 80,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'لا توجد نتائج مطابقة',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                 padding: EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: laboratories.length,
                                  itemBuilder: (context, index) {
                                    final lab = laboratories[index];
                                    final isOpen =
                                        WorkingHoursHelper.isServiceOpen(
                                          workingHours: lab.workingHours.map(
                                            (key, value) =>
                                                MapEntry(key, value.toMap()),
                                          ),
                                        );
                                    return Padding(
                                 padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: LaboratoryCard(
                                        
                                        laboratory: lab,
                                        isOpen: isOpen,
                                        distanceText: _distanceForLab(lab),
                                        onTap: () async {
                                          if (!mounted) return;
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  LaboratoryDetailsClinicStyleScreen(
                                                    laboratory: lab,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                    : (_isInitializing || _isLoading) && _laboratories.isEmpty
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
                                fontSize: 14,
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
                            Icon(
                              _loadError == null
                                  ? Icons.science_outlined
                                  : Icons.wifi_off_rounded,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _loadError ?? 'لا توجد معامل متاحة',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_loadError != null) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _resetAndReload,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount:
                            _laboratories.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _laboratories.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: SpinKitPulsingGrid(
                                  color: AppTheme.laboratoryGradient.colors[0],
                                  size: 30,
                                ),
                              ),
                            );
                          }

                          final lab = _laboratories[index];
                          final isOpen = WorkingHoursHelper.isServiceOpen(
                            workingHours: lab.workingHours.map(
                              (key, value) => MapEntry(key, value.toMap()),
                            ),
                          );
                          return LaboratoryCard(
                            laboratory: lab,
                            isOpen: isOpen,
                            distanceText: _distanceForLab(lab),
                            onTap: () async {
                              if (!mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LaboratoryDetailsClinicStyleScreen(
                                        laboratory: lab,
                                      ),
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
      ),
    );
  }
}

class LaboratoryDetailsScreen extends StatefulWidget {
  final LaboratoryModel laboratory;

  const LaboratoryDetailsScreen({super.key, required this.laboratory});

  @override
  State<LaboratoryDetailsScreen> createState() =>
      _LaboratoryDetailsScreenState();
}

class _LaboratoryDetailsScreenState extends State<LaboratoryDetailsScreen> {
  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _primaryDark = Color(0xFF115E59);
  bool _showAllTests = false; // لتتبع عرض جميع التحاليل

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('laboratories')
          .doc(widget.laboratory.id)
          .snapshots(),
      builder: (context, snapshot) {
        // Use updated data if available
        LaboratoryModel currentLab = widget.laboratory;
        if (snapshot.hasData && snapshot.data!.exists) {
          currentLab = LaboratoryModel.fromFirestore(snapshot.data!);
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF5FAF9), Color(0xFFEDF4F3)],
                ),
              ),
              child: CustomScrollView(
                slivers: [
                  // Modern App Bar with Logo
                  SliverAppBar(
                    expandedHeight: 260,
                    pinned: true,
                    backgroundColor: _primaryColor,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentLab.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                      background: currentLab.logoUrl != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  currentLab.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.laboratoryGradient,
                                    ),
                                    child: const Icon(
                                      Icons.science_rounded,
                                      color: Colors.white,
                                      size: 80,
                                    ),
                                  ),
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
                              ],
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.laboratoryGradient,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.science_rounded,
                                  color: Colors.white,
                                  size: 80,
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description Card
                          if (currentLab.description != null &&
                              currentLab.description!.isNotEmpty) ...[
                            _buildSectionCard(
                              icon: Icons.description_rounded,
                              title: 'عن المعمل',
                              child: Text(
                                currentLab.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF475569),
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Info Badges
                          if (currentLab.hasHomeService ||
                              currentLab.estimatedResultTime != null) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (currentLab.hasHomeService)
                                  _buildBadge(
                                    Icons.home_rounded,
                                    'خدمة منزلية',
                                    _primaryColor,
                                  ),
                                if (currentLab.estimatedResultTime != null)
                                  _buildBadge(
                                    Icons.access_time_rounded,
                                    'النتيجة خلال ${currentLab.estimatedResultTime} ساعة',
                                    Colors.orange,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Rating, Likes, Report Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: RatingWidget(
                                    serviceId: currentLab.id,
                                    serviceType: 'laboratory',
                                    averageRating: currentLab.averageRating,
                                    totalRatings: currentLab.totalRatings,
                                    starSize: 20,
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
                          const SizedBox(height: 16),

                          // Reviews Button
                          _buildReviewsButton(context, currentLab),
                          const SizedBox(height: 16),

                          // Contact Information Card
                          _buildSectionCard(
                            icon: Icons.phone_in_talk_rounded,
                            title: 'تواصل معنا',
                            child: Column(
                              children: [
                                // أرقام التليفون (دعم أرقام متعددة)
                                ...currentLab.phones.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final phone = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _primaryColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _makePhoneCall(context, phone),
                                        icon: const Icon(Icons.phone, size: 20),
                                        label: Text(
                                          currentLab.phones.length > 1
                                              ? 'اتصال ${index + 1}: $phone'
                                              : 'اتصال: $phone',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),

                                // WhatsApp Button (if whatsapp number exists)
                                if (currentLab.whatsapp != null &&
                                    currentLab.whatsapp!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF25D366,
                                          ).withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openWhatsApp(
                                          context,
                                          currentLab.whatsapp!,
                                        ),
                                        icon: Icon(Icons.chat, size: 20),
                                        label: Text(
                                          'واتساب: ${currentLab.whatsapp}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF25D366,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Map Button
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _primaryDark.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openMap(
                                      context,
                                      currentLab.latitude,
                                      currentLab.longitude,
                                    ),
                                    icon: const Icon(
                                      Icons.map_rounded,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'عرض على الخريطة',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryDark,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Address
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: _primaryColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          currentLab.address,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF475569),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Home Service Card
                          if (currentLab.hasHomeService) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _primaryColor.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE7F5F3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.home_rounded,
                                      color: _primaryColor,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'خدمة التحاليل المنزلية متاحة',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (currentLab.homeServiceFee !=
                                            null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'رسوم الخدمة: ${currentLab.homeServiceFee} جنيه',
                                            style: const TextStyle(
                                              color: _primaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Working Hours Card
                          if (currentLab.workingHours.isNotEmpty) ...[
                            _buildSectionCard(
                              icon: Icons.access_time_rounded,
                              title: 'مواعيد العمل',
                              child: _buildWorkingHoursContent(currentLab),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Available Tests Card
                          if (currentLab.availableTests.isNotEmpty) ...[
                            _buildSectionCard(
                              icon: Icons.science_rounded,
                              title: 'التحاليل المتوفرة',
                              child: Column(
                                children: [
                                  // عرض التحاليل (10 أو الكل حسب الحالة)
                                  ...(_showAllTests
                                          ? currentLab.availableTests
                                          : currentLab.availableTests.take(10))
                                      .map(
                                        (test) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: _primaryColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  test,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF334155),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                  // زر "عرض المزيد" أو "عرض أقل"
                                  if (currentLab.availableTests.length >
                                      10) ...[
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showAllTests = !_showAllTests;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _primaryColor.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _showAllTests
                                                  ? Icons
                                                        .keyboard_arrow_up_rounded
                                                  : Icons
                                                        .keyboard_arrow_down_rounded,
                                              color: _primaryColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _showAllTests
                                                  ? 'عرض أقل'
                                                  : 'عرض ${currentLab.availableTests.length - 10} تحليل إضافي',
                                              style: TextStyle(
                                                color: _primaryColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE7F5F3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: _primaryColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'للاستفسار عن الأسعار، يرجى التواصل مع المعمل مباشرة',
                                            style: const TextStyle(
                                              color: Color(0xFF0F766E),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Book Now Button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: AppTheme.laboratoryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LabBookingScreen(
                                      laboratory: currentLab,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'احجز الآن',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  gradient: AppTheme.laboratoryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildWorkingHoursContent(LaboratoryModel laboratory) {
    final daysArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    // ترتيب الأيام بشكل صحيح
    final orderedDays = [
      'saturday',
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
    ];

    return Column(
      children: orderedDays
          .where((day) => laboratory.workingHours.containsKey(day))
          .map((day) {
            final entry = MapEntry(day, laboratory.workingHours[day]!);
            final dayName = daysArabic[entry.key] ?? entry.key;
            final hours = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${hours.openTime} - ${hours.closeTime}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(),
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
            color: _primaryColor,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${hours.openTime} - ${hours.closeTime}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
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
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = input.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return '20$n';
    // ضيف +20 قدام الرقم
    return '20$n';
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن إجراء المكالمة')));
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رقم واتساب غير صحيح')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب')));
      }
    }
  }

  Future<void> _openMap(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الخريطة')));
      }
    }
  }
}
