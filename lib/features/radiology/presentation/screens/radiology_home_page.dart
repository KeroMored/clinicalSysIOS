import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:math' show cos, sqrt, asin;
import '../../data/models/radiology_model.dart';
import '../cubit/radiology_cubit.dart';
import '../cubit/radiology_state.dart';
import '../widgets/radiology_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/like_button.dart';
import '../../../pharmacy/presentation/widgets/reviews_dialog.dart';
import '../../../../core/widgets/report_button.dart';

class RadiologyHomePage extends StatefulWidget {
  const RadiologyHomePage({super.key});

  @override
  State<RadiologyHomePage> createState() => _RadiologyHomePageState();
}

class _RadiologyHomePageState extends State<RadiologyHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGovernorate;
  String? _selectedService;
  bool _showEmergencyOnly = false;
  bool _showHomeVisitOnly = false;
  Position? _currentPosition;
  String _sortBy = 'distance'; // distance, rating, name
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _tryAutoLocation();
    if (!mounted) return;
    _loadCenters();
    setState(() => _isInitializing = false);
  }

  // 🔥 Get location in background and update sort if available
  Future<void> _tryAutoLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      // Get location with timeout
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 3));

        if (mounted) {
          setState(() {
            _currentPosition = position;
            // Auto switch to distance sort if location available
            _sortBy = 'distance';
          });
        }
      } catch (e) {
        // Continue without location if it takes too long
        print('Location timeout or error: $e');
      }
    } catch (e) {
      print('Location error: $e');
    }
  }

  void _loadCenters() {
    if (!mounted) return;
    context.read<RadiologyCubit>().loadApprovedRadiologyCenters();
  }

  void _showLocationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 12),
            Text('تفعيل الموقع'),
          ],
        ),
        content: const Text(
          'قم بتفعيل الموقع لعرض المراكز الأقرب إليك',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _applyFilters() {
    if (!mounted) return;
    if (_showHomeVisitOnly) {
      context.read<RadiologyCubit>().loadHomeVisitRadiologyCenters();
    } else if (_selectedService != null) {
      context.read<RadiologyCubit>().filterByService(_selectedService!);
    } else if (_selectedGovernorate != null) {
      context.read<RadiologyCubit>().filterByGovernorate(_selectedGovernorate!);
    } else {
      context.read<RadiologyCubit>().loadApprovedRadiologyCenters();
    }
  }

  void _clearFilters() {
    if (!mounted) return;
    setState(() {
      _selectedGovernorate = null;
      _selectedService = null;
      _showEmergencyOnly = false;
      _showHomeVisitOnly = false;
      _searchController.clear();
    });
    context.read<RadiologyCubit>().loadApprovedRadiologyCenters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'مراكز الأشعة',
        gradient: AppTheme.radiologyGradient,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'ترتيب حسب',
            onSelected: (value) {
              if (!mounted) return;
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me,
                      color: _sortBy == 'distance' ? Colors.teal : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الأقرب',
                      style: TextStyle(
                        color: _sortBy == 'distance'
                            ? Colors.teal
                            : const Color(0xFF0F172A),
                        fontWeight: _sortBy == 'distance'
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                      color: _sortBy == 'rating' ? Colors.teal : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الأعلى تقييماً',
                      style: TextStyle(
                        color: _sortBy == 'rating'
                            ? Colors.teal
                            : const Color(0xFF0F172A),
                        fontWeight: _sortBy == 'rating'
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                      color: _sortBy == 'name' ? Colors.teal : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الاسم',
                      style: TextStyle(
                        color: _sortBy == 'name'
                            ? Colors.teal
                            : const Color(0xFF0F172A),
                        fontWeight: _sortBy == 'name'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: Column(
          children: [
            _buildIntroCard(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(child: _buildRadiologyList()),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
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
              gradient: AppTheme.radiologyGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_information_rounded,
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
                  'مراكز أشعة معتمدة',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'اختر المركز الأنسب حسب القرب والتقييم',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن مركز أشعة أو خدمة...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF0F766E),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    if (mounted) {
                      context
                          .read<RadiologyCubit>()
                          .loadApprovedRadiologyCenters();
                    }
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          if (mounted) {
            setState(() {});
            if (value.length >= 2) {
              context.read<RadiologyCubit>().searchRadiologyCenters(value);
            } else if (value.isEmpty) {
              context.read<RadiologyCubit>().loadApprovedRadiologyCenters();
            }
          }
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_selectedGovernorate == null &&
        _selectedService == null &&
        !_showEmergencyOnly &&
        !_showHomeVisitOnly) {
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
              backgroundColor: Colors.deepPurple.shade100,
            ),
          if (_selectedService != null)
            Chip(
              label: Text(_selectedService!),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _selectedService = null);
                _applyFilters();
              },
              backgroundColor: Colors.deepPurple.shade100,
            ),
          if (_showEmergencyOnly)
            Chip(
              label: const Text('خدمة طوارئ'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _showEmergencyOnly = false);
                _applyFilters();
              },
              backgroundColor: Colors.red.shade100,
            ),
          if (_showHomeVisitOnly)
            Chip(
              label: const Text('زيارة منزلية'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _showHomeVisitOnly = false);
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

  Widget _buildRadiologyList() {
    // Show loading during initialization
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitPulsingGrid(
              color: AppTheme.radiologyGradient.colors[0],
              size: 60,
            ),
            const SizedBox(height: 24),
            const Text(
              'جاري تحميل مراكز الأشعة...',
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

    return BlocBuilder<RadiologyCubit, RadiologyState>(
      builder: (context, state) {
        if (state is RadiologyLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitPulsingGrid(
                  color: AppTheme.radiologyGradient.colors[0],
                  size: 60,
                ),
                const SizedBox(height: 24),
                const Text(
                  'جاري تحميل مراكز الأشعة...',
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

        if (state is RadiologyError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<RadiologyCubit>()
                      .loadApprovedRadiologyCenters(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        List<RadiologyModel> centers = [];
        if (state is RadiologyLoaded) {
          centers = state.radiologyCenters;
        } else if (state is RadiologySearchLoaded) {
          centers = state.searchResults;
        } else if (state is RadiologyFilteredByGovernorate) {
          centers = state.radiologyCenters;
        } else if (state is RadiologyFilteredByService) {
          centers = state.radiologyCenters;
        } else if (state is RadiologyEmergencyLoaded) {
          centers = state.radiologyCenters;
        } else if (state is RadiologyHomeVisitLoaded) {
          centers = state.radiologyCenters;
        }

        // Sort centers
        if (_currentPosition != null && _sortBy == 'distance') {
          centers.sort((a, b) {
            final distA = _calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              a.latitude,
              a.longitude,
            );
            final distB = _calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              b.latitude,
              b.longitude,
            );
            return distA.compareTo(distB);
          });
        } else if (_sortBy == 'rating') {
          centers.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        } else if (_sortBy == 'name') {
          centers.sort((a, b) => a.centerName.compareTo(b.centerName));
        }

        if (centers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد مراكز أشعة متاحة',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'جرب البحث أو تغيير الفلاتر',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: centers.length,
          itemBuilder: (context, index) {
            final center = centers[index];
            String? distance;

            // Calculate distance if location available
            if (_currentPosition != null) {
              final dist = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                center.latitude,
                center.longitude,
              );
              distance = '${dist.toStringAsFixed(1)} كم';
            }

            return RadiologyCard(
              radiology: center,
              distance: distance,
              onTap: () => _showRadiologyDetails(center),
            );
          },
        );
      },
    );
  }

  void _showRadiologyDetails(RadiologyModel radiology) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RadiologyDetailScreen(radiology: radiology),
      ),
    );
  }
}

// Detail screen will be in a separate file
class RadiologyDetailScreen extends StatefulWidget {
  final RadiologyModel radiology;

  const RadiologyDetailScreen({super.key, required this.radiology});

  @override
  State<RadiologyDetailScreen> createState() => _RadiologyDetailScreenState();
}

class _RadiologyDetailScreenState extends State<RadiologyDetailScreen> {
  late RadiologyModel radiology;

  @override
  void initState() {
    super.initState();
    radiology = widget.radiology;
  }

  Future<void> _reloadRadiology() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('radiology_centers')
          .doc(radiology.id)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          radiology = RadiologyModel.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String _formatTimeToArabic(String time) {
    // Handle time in format "HH:mm"
    final parts = time.split(':');
    if (parts.length != 2) return time;

    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];

    String period;
    if (hour == 0) {
      hour = 12;
      period = 'صباحاً';
    } else if (hour < 12) {
      period = 'صباحاً';
    } else if (hour == 12) {
      period = 'مساءً';
    } else {
      hour = hour - 12;
      period = 'مساءً';
    }

    if (minute == '00') {
      return '$hour $period';
    }
    return '$hour:$minute $period';
  }

  String _formatWhatsAppNumber(String phoneNumber) {
    String formatted = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    formatted = formatted.replaceAll('+', '');
    if (formatted.startsWith('00')) {
      formatted = formatted.substring(2);
    }
    if (formatted.startsWith('0')) {
      formatted = '20${formatted.substring(1)}';
    }
    if (!formatted.startsWith('20')) {
      formatted = '20$formatted';
    }
    return formatted;
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final String formattedNumber = _formatWhatsAppNumber(phoneNumber);
    final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNumber');
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _openMap(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الخريطة')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: GradientAppBar(
        title: radiology.centerName,
        gradient: AppTheme.pharmacyGradient,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildInfoSection(),
              const SizedBox(height: 16),
              _buildContactSection(context),
              const SizedBox(height: 16),
              _buildMapSection(context),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: RatingWidget(
                          serviceId: radiology.id,
                          serviceType: 'radiology',
                          averageRating: radiology.averageRating,
                          totalRatings: radiology.totalRatings,
                          starSize: 22,
                          onRatingAdded: _reloadRadiology,
                        ),
                      ),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      LikeButton(
                        serviceId: radiology.id,
                        serviceType: 'radiology',
                        initialLikesCount: radiology.totalLikes,
                        iconSize: 26,
                        onLikeChanged: _reloadRadiology,
                      ),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      ReportButton(
                        serviceId: radiology.id,
                        serviceType: 'radiology',
                        serviceName: radiology.centerName,
                        iconSize: 26,
                        showLabel: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildReviewsButton(context, radiology),

              const SizedBox(height: 16),

              _buildServicesSection(),
              const SizedBox(height: 16),
              _buildWorkingHoursSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.pharmacyGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.monitor_heart_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  radiology.centerName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  radiology.address,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات المركز',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),

            const Divider(),
            // Description if available
            if (radiology.description != null &&
                radiology.description!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.teal.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        radiology.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
            ],
            _buildInfoRow(Icons.location_on, 'العنوان', radiology.address),
            _buildInfoRow(Icons.phone, 'هاتف المركز', radiology.centerPhone),
            _buildInfoRow(
              Icons.chat,
              'واتساب المركز',
              radiology.centerWhatsApp,
            ),
            if (radiology.licenseNumber != null)
              _buildInfoRow(
                Icons.card_membership,
                'رقم الترخيص',
                radiology.licenseNumber!,
              ),
            if (radiology.homeVisit)
              _buildInfoRow(
                Icons.home,
                'الزيارة المنزلية',
                'متاح',
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    if (radiology.services.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الخدمات المتاحة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: radiology.services.map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.teal.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        service,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection() {
    if (radiology.workingHours.isEmpty) return const SizedBox.shrink();

    final daysInArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مواعيد العمل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),

            const Divider(),

            ...daysInArabic.entries.map((entry) {
              final hours = radiology.workingHours[entry.key];
              if (hours == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      hours.isHoliday
                          ? 'مغلق'
                          : '${_formatTimeToArabic(hours.openTime)} - ${_formatTimeToArabic(hours.closeTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: hours.isHoliday ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات التواصل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),

            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _makePhoneCall(context, radiology.centerPhone),
                    icon: const Icon(Icons.phone),
                    label: const Text('مكالمة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openWhatsApp(context, radiology.centerWhatsApp),
                    icon: Icon(Icons.chat),
                    label: const Text('واتساب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الموقع على الخريطة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),

            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _openMap(context, radiology.latitude, radiology.longitude),
                icon: const Icon(Icons.map),
                label: const Text('فتح الموقع في الخريطة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsButton(BuildContext context, RadiologyModel radiology) {
    return GestureDetector(
      onTap: () {
        ReviewsDialog.show(
          context,
          serviceId: radiology.id,
          serviceName: radiology.centerName,
          averageRating: radiology.averageRating,
          totalRatings: radiology.totalRatings,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.teal.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.08),
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
                            index < radiology.averageRating.floor()
                                ? Icons.star_rounded
                                : (index < radiology.averageRating
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded),
                            color: const Color(0xFFFBBF24),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${radiology.averageRating.toStringAsFixed(1)} (${radiology.totalRatings} تقييم)',
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
}
