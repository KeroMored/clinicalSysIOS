import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/location_service.dart';
import '../../data/models/gym_model.dart';
import '../widgets/gym_card.dart';
import 'gym_details_screen.dart';

class GymsListScreen extends StatefulWidget {
  const GymsListScreen({super.key});

  @override
  State<GymsListScreen> createState() => _GymsListScreenState();
}

class _GymsListScreenState extends State<GymsListScreen> {
  final List<GymModel> _gyms = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasMore = true;
  String? _loadError;

  String _searchQuery = '';
  Position? _userLocation;
  String _sortBy = 'name'; // distance, rating, name
  String _activeQuickFilter = 'all'; // all, distance, rating, open

  static const int _pageSize = 10;

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
    if (!mounted) {
      return;
    }

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
          'لترتيب الجيمات حسب الأقرب، فعّل خدمة الموقع ومنح إذن الوصول للتطبيق.',
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
        _loadGyms();
      }
    }
  }

  void _resetPagination() {
    _gyms.clear();
    _lastDocument = null;
    _hasMore = true;
  }

  Future<void> _resetAndReload() async {
    if (!mounted) return;
    setState(() {
      _resetPagination();
      _loadError = null;
    });
    await _loadGyms();
  }

  Future<void> _loadGyms() async {
    if (_isLoading || !_hasMore) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('gyms')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true);

      if (_sortBy == 'rating') {
        query = query.orderBy('averageRating', descending: true);
      } else {
        query = query.orderBy('name');
      }

      query = query.limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      if (!mounted) {
        return;
      }

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      _lastDocument = snapshot.docs.last;
      final fetched = snapshot.docs
          .map((doc) => GymModel.fromFirestore(doc))
          .toList();

      if (_sortBy == 'distance') {
        _sortGyms(fetched);
      }

      setState(() {
        _gyms.addAll(fetched);
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = 'تعذر تحميل الجيمات حالياً';
      });
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
      default:
        gyms.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  void _applySearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  List<GymModel> _getDisplayedGyms() {
    final q = _searchQuery.trim().toLowerCase();

    return _gyms.where((gym) {
      final matchesSearch =
          q.isEmpty ||
          gym.name.toLowerCase().contains(q) ||
          gym.description.toLowerCase().contains(q);

      return matchesSearch;
    }).toList();
  }

  Future<void> _changeSortOption(String sortOption) async {
    if (sortOption == 'distance' && _userLocation == null) {
      await _requestLocation();
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _sortBy = sortOption;
    });

    await _resetAndReload();
  }

  Future<void> _refreshSingleGym(String gymId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .get();

      if (!doc.exists || !mounted) {
        return;
      }

      final i = _gyms.indexWhere((item) => item.id == gymId);
      if (i == -1) {
        return;
      }

      setState(() {
        _gyms[i] = GymModel.fromFirestore(doc);
      });
    } catch (_) {
      // Ignore single-item refresh failures.
    }
  }

  void _onQuickFilterSelected(String filterId) {
    if (!mounted) {
      return;
    }

    setState(() {
      _activeQuickFilter = filterId;
    });

    if (filterId == 'all') {
      _changeSortOption('name');
      return;
    }

    if (filterId == 'distance') {
      _changeSortOption('distance');
      return;
    }

    if (filterId == 'rating') {
      _changeSortOption('rating');
      return;
    }

    if (filterId == 'open') {
      _changeSortOption('name');
    }
  }

  bool _isGymOpenNow(GymModel gym) {
    final now = DateTime.now();
    String dayKey;
    switch (now.weekday) {
      case DateTime.monday:
        dayKey = 'monday';
        break;
      case DateTime.tuesday:
        dayKey = 'tuesday';
        break;
      case DateTime.wednesday:
        dayKey = 'wednesday';
        break;
      case DateTime.thursday:
        dayKey = 'thursday';
        break;
      case DateTime.friday:
        dayKey = 'friday';
        break;
      case DateTime.saturday:
        dayKey = 'saturday';
        break;
      case DateTime.sunday:
      default:
        dayKey = 'sunday';
        break;
    }

    Map<String, WorkingHours> hours = {};
    if (gym.hasMaleSection && gym.maleWorkingHours.isNotEmpty) {
      hours = gym.maleWorkingHours;
    } else if (gym.hasFemaleSection && gym.femaleWorkingHours.isNotEmpty) {
      hours = gym.femaleWorkingHours;
    } else if (gym.maleWorkingHours.isNotEmpty) {
      hours = gym.maleWorkingHours;
    } else if (gym.femaleWorkingHours.isNotEmpty) {
      hours = gym.femaleWorkingHours;
    }

    final working = hours[dayKey];
    if (working == null || working.isHoliday) {
      return false;
    }

    int parse(String t) {
      final p = t.split(':');
      if (p.length != 2) return -1;
      final h = int.tryParse(p[0]) ?? -1;
      final m = int.tryParse(p[1]) ?? -1;
      if (h < 0 || m < 0) return -1;
      return (h * 60) + m;
    }

    final open = parse(working.openTime);
    final close = parse(working.closeTime);
    if (open < 0 || close < 0) {
      return false;
    }

    final nowMinutes = (now.hour * 60) + now.minute;
    if (close >= open) {
      return nowMinutes >= open && nowMinutes <= close;
    }

    return nowMinutes >= open || nowMinutes <= close;
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
    final displayed = _getDisplayedGyms();
    final showInitialLoading = (_isInitializing || _isLoading) && _gyms.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الجيمات',
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
                      hintText: 'ابحث باسم الجيم',
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SpinKitPulsingGrid(
                          color: Color(0xFF0891B2),
                          size: 44,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'جاري تحميل الجيمات...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : displayed.isEmpty
                ? Center(
                    child: Text(
                      _gyms.isEmpty
                          ? (_loadError ?? 'لا توجد جيمات متاحة حاليا')
                          : 'لا توجد نتائج مطابقة',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
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
                                ? const SpinKitPulsingGrid(
                                    color: Color(0xFF0891B2),
                                    size: 20,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }

                      final gym = displayed[index];
                      final isOpen = _isGymOpenNow(gym);
                      String? distance;
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
                        isOpen: isOpen,
                        distance: distance,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GymDetailsScreen(gym: gym),
                            ),
                          );

                          if (result == true || result == null) {
                            _refreshSingleGym(gym.id);
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
