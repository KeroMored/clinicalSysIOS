import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:clinicalsystem/core/widgets/skeleton_cards.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/utils/working_hours_helper.dart';
import '../../data/models/clinic_department.dart';
import '../../data/models/clinic_model.dart';
import 'clinic_details_screen.dart';

class ClinicsListScreen extends StatefulWidget {
  final ClinicDepartment department;

  const ClinicsListScreen({super.key, required this.department});

  @override
  State<ClinicsListScreen> createState() => _ClinicsListScreenState();
}

class _ClinicsListScreenState extends State<ClinicsListScreen> {
  final List<ClinicModel> _clinics = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  DocumentSnapshot? _lastDocument;
  DocumentSnapshot? _geoLastDocument;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasMore = true;
  String? _loadError;

  String _searchQuery = '';
  bool _showOpenOnly = false;
  bool _showNurseryOnly = false;
  String _activeQuickFilter = 'all'; // all, distance, rating, open, nursery

  Position? _userLocation;
  String _sortBy = 'name'; // distance, rating, name

  static const int _pageSize = 10;
  static const int _geoBatchSize = 50;
  int _geoPage = 0;
  bool _geoExhausted = false;
  bool _geoHasMoreServer = true;
  final List<_ClinicDistanceEntry> _geoEntries = [];

  bool get _canUseNurseryFilter =>
      widget.department == ClinicDepartment.pediatrics;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applySearch() {
    _searchClinicsInDatabase(_searchController.text);
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
          'لترتيب العيادات حسب الأقرب، فعّل خدمة الموقع ومنح إذن الوصول للتطبيق.',
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
        _loadClinics();
      }
    }
  }

  void _resetPagination() {
    _clinics.clear();
    _lastDocument = null;
    _geoLastDocument = null;
    _geoPage = 0;
    _geoExhausted = false;
    _geoHasMoreServer = true;
    _geoEntries.clear();
    _hasMore = true;
  }

  Future<void> _resetAndReload() async {
    if (!mounted) return;
    setState(() {
      _resetPagination();
      _loadError = null;
    });
    await _loadClinics();
  }

  Future<void> _searchClinicsInDatabase(String rawQuery) async {
    final trimmed = rawQuery.trim();

    if (trimmed.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchQuery = '';
      });
      await _resetAndReload();
      return;
    }

    if (!mounted) return;
    setState(() {
      _searchQuery = trimmed;
      _isLoading = true;
      _loadError = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('department', isEqualTo: widget.department.englishName)
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .get();

      final lower = trimmed.toLowerCase();
      final results = snapshot.docs
          .map((doc) => ClinicModel.fromFirestore(doc))
          .where((clinic) {
            if (!clinic.doctorName.toLowerCase().contains(lower)) {
              return false;
            }

            return _matchesClinicQuickFilters(clinic);
          })
          .toList();

      _sortClinics(results);

      if (!mounted) return;
      setState(() {
        _clinics
          ..clear()
          ..addAll(results);
        _hasMore = false;
        _isLoading = false;
        _lastDocument = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'تعذر تنفيذ البحث حالياً';
      });
    }
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
      default:
        clinics.sort((a, b) => a.doctorName.compareTo(b.doctorName));
        break;
    }
  }

  bool _matchesClinicQuickFilters(ClinicModel clinic) {
    if (_showNurseryOnly && !clinic.hasNursery) {
      return false;
    }

    if (_showOpenOnly && !_isClinicOpenNow(clinic)) {
      return false;
    }

    return true;
  }

  Future<void> _changeSortOption(String sortOption) async {
    if (sortOption == 'distance' && _userLocation == null) {
      await _requestLocation();
      return;
    }

    if (!mounted) return;
    setState(() {
      _sortBy = sortOption;
      _clinics.clear();
      _lastDocument = null;
      _geoLastDocument = null;
      _hasMore = true;
      _geoPage = 0;
      _geoExhausted = false;
      _geoHasMoreServer = true;
      _geoEntries.clear();
    });

    if (_searchQuery.isNotEmpty) {
      await _searchClinicsInDatabase(_searchQuery);
      return;
    }

    await _resetAndReload();
  }

  Future<void> _loadClinics() async {
    if (_isLoading || !mounted || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      if (_sortBy == 'distance' && _userLocation != null) {
        await _loadClinicsByDistance();
      } else {
        await _loadClinicsNormal();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'تعذر تحميل العيادات حالياً';
      });
    }
  }

  Future<void> _loadClinicsByDistance() async {
    try {
      final requiredCount = (_geoPage + 1) * _pageSize;
      await _ensureGeoCandidates(requiredCount);

      final sorted = List<_ClinicDistanceEntry>.from(_geoEntries)
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      final visible = sorted.take(requiredCount).map((e) => e.clinic).toList();

      if (!mounted) return;
      setState(() {
        _geoPage++;
        _geoExhausted = !_geoHasMoreServer && visible.length >= sorted.length;
        _clinics
          ..clear()
          ..addAll(visible);
        _hasMore = !_geoExhausted;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'تعذر تحميل العيادات حالياً';
      });
    }
  }

  Future<void> _ensureGeoCandidates(int requiredCount) async {
    if (_userLocation == null) return;
    if (!_geoHasMoreServer) return;

    while (_geoHasMoreServer && _geoEntries.length < requiredCount) {
      Query baseQuery = FirebaseFirestore.instance
          .collection('clinics')
          .where('department', isEqualTo: widget.department.englishName)
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true);

      if (_showNurseryOnly) {
        baseQuery = baseQuery.where('hasNursery', isEqualTo: true);
      }

      baseQuery = baseQuery.orderBy('doctorName');

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
          final c = ClinicModel.fromFirestore(doc);
          if (!_matchesClinicQuickFilters(c)) {
            continue;
          }

          final lat = c.latitude;
          final lng = c.longitude;
          final dist = (lat == null || lng == null)
              ? double.infinity
              : LocationService.calculateDistance(
                  _userLocation!.latitude,
                  _userLocation!.longitude,
                  lat,
                  lng,
                );

          _geoEntries.add(_ClinicDistanceEntry(clinic: c, distanceKm: dist));
        } catch (_) {
          // skip invalid docs
        }
      }

      if (!_geoHasMoreServer) {
        break;
      }
    }
  }

  Future<void> _loadClinicsNormal() async {
    Query baseQuery = FirebaseFirestore.instance
        .collection('clinics')
        .where('department', isEqualTo: widget.department.englishName)
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true);

    if (_showNurseryOnly) {
      baseQuery = baseQuery.where('hasNursery', isEqualTo: true);
    }

    if (_sortBy == 'rating') {
      baseQuery = baseQuery.orderBy('averageRating', descending: true);
    } else {
      baseQuery = baseQuery.orderBy('doctorName');
    }

    DocumentSnapshot? cursor = _lastDocument;
    bool hasMoreLocal = _hasMore;
    final collected = <ClinicModel>[];

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
          .map((doc) => ClinicModel.fromFirestore(doc))
          .where(_matchesClinicQuickFilters)
          .toList();

      collected.addAll(batch);
    }

    final fetched = collected.take(_pageSize).toList();

    if (!mounted) return;
    setState(() {
      _lastDocument = cursor;
      _clinics.addAll(fetched);
      _hasMore = hasMoreLocal;
      _isLoading = false;
    });
  }

  bool _isClinicOpenNow(ClinicModel clinic) {
    return WorkingHoursHelper.isServiceOpen(
      workingHours: clinic.workingHours.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      holidays: clinic.holidays,
    );
  }

  List<ClinicModel> _getDisplayedClinics() {
    return _clinics;
  }

  Future<void> _refreshClinic(String clinicId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .get();

      if (!doc.exists || !mounted) return;

      final i = _clinics.indexWhere((item) => item.id == clinicId);
      if (i == -1) return;

      setState(() {
        _clinics[i] = ClinicModel.fromFirestore(doc);
      });
    } catch (_) {
      // Silent refresh failure is fine here.
    }
  }

  Future<void> _onQuickFilterSelected(String filterId) async {
    if (!mounted) return;

    if (filterId == 'open') {
      setState(() {
        _activeQuickFilter = 'open';
        _showOpenOnly = true;
        _showNurseryOnly = false;
      });

      if (_searchQuery.isNotEmpty) {
        await _searchClinicsInDatabase(_searchQuery);
      } else {
        await _resetAndReload();
      }
      return;
    }

    if (filterId == 'nursery') {
      if (!_canUseNurseryFilter) {
        return;
      }
      setState(() {
        _activeQuickFilter = 'nursery';
        _showOpenOnly = false;
        _showNurseryOnly = true;
      });

      if (_searchQuery.isNotEmpty) {
        await _searchClinicsInDatabase(_searchQuery);
      } else {
        await _resetAndReload();
      }
      return;
    }

    setState(() {
      _activeQuickFilter = filterId;
      _showOpenOnly = false;
      _showNurseryOnly = false;
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
  Widget build(BuildContext context) {
    final displayed = _getDisplayedClinics();
    final showInitialLoading =
        (_isInitializing || _isLoading) && _clinics.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'عيادات ${widget.department.arabicName}',
          style: const TextStyle(
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _applySearch(),
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم الدكتور',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF0B8293),
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _applySearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0B8293),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFF0B8293),
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
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
                if (_canUseNurseryFilter) ...[
                  const SizedBox(width: 3),
                  _buildFilterChip(
                    id: 'nursery',
                    label: 'حضّانة',
                    icon: Icons.child_friendly_rounded,
                  ),
                ],
                const SizedBox(width: 3),
                _buildFilterChip(
                  id: 'rating',
                  label: 'الأعلى تقييما',
                  icon: Icons.star_rounded,
                ),
              ],
            ),
          ),
          Expanded(
            child: showInitialLoading
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                    itemCount: 5,
                    itemBuilder: (context, index) => const SkeletonClinicCard(),
                  )
                : displayed.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _clinics.isEmpty
                              ? (_loadError ?? 'لا توجد عيادات متاحة حاليا')
                              : 'لا توجد نتائج مطابقة',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                    itemCount: displayed.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == displayed.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _isLoading
                                ? SpinKitPulsingGrid(
                                    color: const Color(0xFF0891B2),
                                    size: 20,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }

                      final clinic = displayed[index];
                      return _buildClinicCard(context, clinic);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, ClinicModel clinic) {
    String? distance;
    if (_userLocation != null &&
        clinic.latitude != null &&
        clinic.longitude != null) {
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClinicDetailsScreen(clinic: clinic),
              ),
            );

            if (result == true || result == null) {
              _refreshClinic(clinic.id);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOpen ? 'متاح الآن' : 'مغلق الآن',
                              style: TextStyle(
                                fontSize: 10,
                                color: isOpen
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'يبعد $distance',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF0369A1),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'د. ${clinic.doctorName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        clinic.department.arabicName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        clinic.about,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            clinic.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.favorite_rounded,
                            size: 12,
                            color: Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${clinic.totalLikes}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          if (clinic.profileViewsCount > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.visibility_outlined,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${clinic.profileViewsCount}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Color(0xFF0B8293),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              clinic.address,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF0F172A),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildClinicImage(clinic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClinicImage(ClinicModel clinic) {
    final imageUrl = clinic.doctorImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildClinicImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _buildClinicImagePlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildClinicImagePlaceholder();
      },
    );
  }

  Widget _buildClinicImagePlaceholder() {
    return Container(
      color: const Color(0xFF0B8293),
      child: const Center(
        child: Icon(
          Icons.local_hospital_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _ClinicDistanceEntry {
  final ClinicModel clinic;
  final double distanceKm;

  const _ClinicDistanceEntry({required this.clinic, required this.distanceKm});
}
