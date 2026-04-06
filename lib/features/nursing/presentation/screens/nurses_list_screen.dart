import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../../data/models/nurse_model.dart';
import '../cubit/nurse_cubit.dart';
import '../cubit/nurse_state.dart';
import 'nurse_detail_screen.dart';
import '../widgets/nurse_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class NursesListScreen extends StatefulWidget {
  const NursesListScreen({super.key});

  @override
  State<NursesListScreen> createState() => _NursesListScreenState();
}

class _NursesListScreenState extends State<NursesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGovernorate;
  String? _selectedSpecialization;
  String? _selectedGender;
  bool _showAvailable24Only = false;
  bool _showAvailableNowOnly = false;

  // Pagination fields
  final List<NurseModel> _nurses = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasMore = true;
  static const int _pageSize = 10;

  // Location fields
  Position? _userLocation;
  String _sortBy = 'name'; // distance, rating, name (default to name)

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _requestLocation();
    await _loadNurses();

    if (!mounted) return;
    setState(() => _isInitializing = false);
  }

  Future<void> _requestLocation() async {
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && !_hasActiveFilters()) {
        _loadNurses();
      }
    }
  }

  bool _hasActiveFilters() {
    return _searchController.text.length >= 2 ||
        _selectedGovernorate != null ||
        _selectedSpecialization != null ||
        _selectedGender != null ||
        _showAvailable24Only ||
        _showAvailableNowOnly;
  }

  Future<void> _loadNurses() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('nurses')
          .where('isApproved', isEqualTo: true);

      // Add orderBy based on sort option to get data from DB in correct order
      switch (_sortBy) {
        case 'rating':
          query = query.orderBy('averageRating', descending: true);
          break;
        case 'name':
          query = query.orderBy('nurseName');
          break;
        case 'distance':
        default:
          // For distance, we'll sort client-side after fetching
          query = query.orderBy('createdAt', descending: true);
          break;
      }

      query = query.limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        var newNurses = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return NurseModel.fromMap(data);
        }).toList();

        // Only sort client-side for distance (requires location calculation)
        if (_sortBy == 'distance' && _userLocation != null) {
          newNurses.sort((a, b) {
            // Skip if location not available
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
        }

        setState(() {
          _nurses.addAll(newNurses);
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

  void _applyFilters() {
    if (_showAvailable24Only) {
      context.read<NurseCubit>().loadAvailable24HoursNurses();
    } else if (_showAvailableNowOnly) {
      context.read<NurseCubit>().loadAvailableNowNurses();
    } else if (_selectedGender != null) {
      context.read<NurseCubit>().filterByGender(_selectedGender!);
    } else if (_selectedSpecialization != null) {
      context.read<NurseCubit>().filterBySpecialization(
        _selectedSpecialization!,
      );
    } else if (_selectedGovernorate != null) {
      context.read<NurseCubit>().filterByGovernorate(_selectedGovernorate!);
    } else {
      context.read<NurseCubit>().loadApprovedNurses();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedGovernorate = null;
      _selectedSpecialization = null;
      _selectedGender = null;
      _showAvailable24Only = false;
      _showAvailableNowOnly = false;
      _searchController.clear();
    });
    context.read<NurseCubit>().loadApprovedNurses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'خدمات التمريض المنزلي',
        gradient: AppTheme.nursingGradient,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildNursesList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن ممرض/ممرضة...',
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<NurseCubit>().loadApprovedNurses();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {});
          if (value.length >= 2) {
            context.read<NurseCubit>().searchNurses(value);
          } else if (value.isEmpty) {
            context.read<NurseCubit>().loadApprovedNurses();
          }
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_selectedGovernorate == null &&
        _selectedSpecialization == null &&
        _selectedGender == null &&
        !_showAvailable24Only &&
        !_showAvailableNowOnly) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        children: [
          if (_selectedGovernorate != null)
            Chip(
              label: Text(_selectedGovernorate!),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _selectedGovernorate = null);
                _applyFilters();
              },
              backgroundColor: Colors.teal.shade100,
            ),
          if (_selectedSpecialization != null)
            Chip(
              label: Text(_selectedSpecialization!),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _selectedSpecialization = null);
                _applyFilters();
              },
              backgroundColor: Colors.teal.shade100,
            ),
          if (_selectedGender != null)
            Chip(
              label: Text(_selectedGender == 'male' ? 'ممرض' : 'ممرضة'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _selectedGender = null);
                _applyFilters();
              },
              backgroundColor: Colors.teal.shade100,
            ),
          if (_showAvailable24Only)
            Chip(
              label: const Text('متاح 24 ساعة'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _showAvailable24Only = false);
                _applyFilters();
              },
              backgroundColor: Colors.green.shade100,
            ),
          if (_showAvailableNowOnly)
            Chip(
              label: const Text('متاح الآن'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _showAvailableNowOnly = false);
                _applyFilters();
              },
              backgroundColor: Colors.blue.shade100,
            ),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('مسح الكل'),
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildNursesList() {
    if (_isInitializing || (_isLoading && _nurses.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitPulsingGrid(
              color: AppTheme.nursingGradient.colors[0],
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'جاري تحميل خدمات التمريض...',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return _hasActiveFilters()
        ? BlocBuilder<NurseCubit, NurseState>(
            builder: (context, state) {
              if (state is NurseLoading) {
                return const Center(
                  child: AppLoadingIndicator(color: Colors.teal),
                );
              }

              if (state is NurseError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              List<NurseModel> nurses = [];
              if (state is NurseLoaded) {
                nurses = state.nurses;
              } else if (state is NurseSearchLoaded) {
                nurses = state.searchResults;
              } else if (state is NurseFilteredByGovernorate ||
                  state is NurseFilteredBySpecialization ||
                  state is NurseFilteredByGender ||
                  state is NurseAvailable24Hours ||
                  state is NurseAvailableNow) {
                nurses = (state as dynamic).nurses;
              }

              if (nurses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد نتائج',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: nurses.length,
                itemBuilder: (context, index) {
                  return NurseCard(
                    nurse: nurses[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NurseDetailScreen(nurse: nurses[index]),
                        ),
                      );
                    },
                  );
                },
              );
            },
          )
        : _nurses.isEmpty && !_isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد ممرضين متاحين',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount:
                _nurses.length +
                ((_isLoading && _nurses.isNotEmpty) || _hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _nurses.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoading
                        ? SpinKitPulsingGrid(
                            color: AppTheme.nursingGradient.colors[0],
                            size: 40,
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }

              return NurseCard(
                nurse: _nurses[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NurseDetailScreen(nurse: _nurses[index]),
                    ),
                  );
                },
              );
            },
          );
  }
}
