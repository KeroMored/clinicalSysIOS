import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/daily_featured_clinics_service.dart';
import '../data/home_fab_cache_helper.dart';
import '../../pharmacy/data/repositories/pharmacy_repository.dart';
import '../../pharmacy/presentation/cubit/pharmacy_cubit.dart';
import '../../pharmacy/presentation/screens/pharmacy_details_screen.dart';
import '../../pharmacy/presentation/screens/pharmacy_home_page.dart';
import '../../pharmacy/presentation/screens/pharmacy_control_page.dart';
import '../../pharmacy/presentation/screens/all_offers_screen.dart';
import '../../clinic/presentation/screens/clinic_details_screen.dart';
import '../../clinic/presentation/screens/clinic_home_page.dart';
import '../../clinic/presentation/screens/clinic_control_page.dart';
import '../../clinic/presentation/screens/bookings_management_screen.dart';
import '../../clinic/presentation/screens/clinics_selection_screen.dart';
import '../../clinic/data/models/clinic_model.dart';
import '../../clinic/data/models/clinic_department.dart';
import '../../clinic/data/models/booking_model.dart';
import '../../clinic/data/repositories/booking_tracking_repository.dart';
import '../../laboratory/data/models/laboratory_model.dart';
import '../../laboratory/presentation/screens/laboratory_home_page.dart';
import '../../laboratory/presentation/screens/laboratory_details_clinic_style_screen.dart';
import '../../laboratory/presentation/screens/laboratory_owner_dashboard.dart';
import '../../radiology/presentation/screens/radiology_owner_dashboard.dart';
import '../../radiology/presentation/screens/radiology_home_page.dart';
import '../../radiology/presentation/cubit/radiology_cubit.dart';
import '../../radiology/data/models/radiology_model.dart';
import '../../radiology/data/repositories/radiology_repository.dart';
import '../../profile/presentation/screens/edit_profile_screen.dart';
import '../../gym/data/models/gym_model.dart' hide WorkingHours;
import '../../gym/presentation/pages/gyms_list_screen.dart';
import '../../gym/presentation/pages/gym_details_screen.dart';
import '../../gym/presentation/pages/gym_control_page.dart';
import '../../gym/presentation/cubit/gym_cubit.dart';
import '../../gym/data/repositories/gym_repository.dart';
import '../../medical_supply/presentation/screens/medical_supplies_screen.dart';
import '../../medical_supply/presentation/screens/medical_supply_home_page.dart';
import '../../medical_supply/data/models/medical_supply_model.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../medicine_reminders/presentation/screens/medicines_screen.dart';
import '../../medicine_reminders/data/repositories/medicine_repository.dart';
import '../../medicine_reminders/presentation/cubit/medicine_cubit.dart';
import '../../medicine_reminders/presentation/cubit/medicine_state.dart';
import '../../medicine_reminders/presentation/widgets/medicine_card.dart';
import '../../medicine_reminders/presentation/screens/add_medicine_screen.dart';
import '../../medicine_reminders/presentation/screens/edit_medicine_screen.dart';
import '../../medicine_requests/presentation/screens/my_medicine_requests_screen.dart';
import '../../admin/presentation/screens/additions_screen.dart';
import '../../admin/presentation/screens/admin_home_page.dart';
import '../../emergency_numbers/presentation/screens/emergency_numbers_screen.dart';
import '../../../core/utils/app_route_observer.dart';
import '../services/daily_step_tracking_service.dart';
import 'widgets/widgets.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';
import 'package:clinicalsystem/core/widgets/skeleton_cards.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  static const Color _primary = Color(0xFF0EA5E9);
  static const Color _secondary = Color(0xFF14B8A6);
  static const Color _accent = Color(0xFFF97316);
  static const Color _background = Color(0xFFF7FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  final DailyStepTrackingService _dailyStepTrackingService =
      DailyStepTrackingService();
  final TextEditingController _searchController = TextEditingController();
  String? _lastTrackedUserId;
  int _bottomNavIndex = 0;
  bool _isSearchLoading = false;
  String _searchQuery = '';
  List<_HomeSearchResult> _searchResults = const [];
  final BookingTrackingRepository _bookingTrackingRepository =
      BookingTrackingRepository();
  List<BookingTrackingInfo> _trackingItems = const [];
  final Map<String, BookingQueueStatus> _queueStatusById = {};
  final Map<String, String> _trackingErrors = {};
  final Set<String> _trackingHiddenIds = {};
  final Set<String> _refreshingTrackingIds = {};
  final Map<String, BookingStatus> _bookingStatusById = {};
  final Map<String, StreamSubscription> _bookingStatusListeners = {};
  bool _isTrackingInfoLoading = false;
  DateTime? _lastTrackingLoadAt;
  String? _trackingUserId;
  PageRoute<dynamic>? _trackedRoute;

  void _onPermissionChanged() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    if (_dailyStepTrackingService.permissionGrantedNotifier.value) {
      _dailyStepTrackingService.start(authState.user.uid);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dailyStepTrackingService.permissionGrantedNotifier.addListener(
      _onPermissionChanged,
    );
    Future.microtask(_dailyStepTrackingService.requestPermissionOnFirstLaunch);
    Future.microtask(_ensureDailyTrackingForAuthenticatedUser);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _trackedRoute) {
      if (_trackedRoute != null) {
        appRouteObserver.unsubscribe(this);
      }
      _trackedRoute = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _loadBookingTrackingInfo(userId: authState.user.uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dailyStepTrackingService.permissionGrantedNotifier.removeListener(
      _onPermissionChanged,
    );
    _dailyStepTrackingService.stop();
    for (final listener in _bookingStatusListeners.values) {
      listener.cancel();
    }
    _bookingStatusListeners.clear();
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureDailyTrackingForAuthenticatedUser();
      _dailyStepTrackingService.refreshFromSensorOnce();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _dailyStepTrackingService.persistNow();
    }
  }

  Future<void> _ensureDailyTrackingForAuthenticatedUser() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _lastTrackedUserId = null;
      await _dailyStepTrackingService.stop();
      return;
    }

    final userId = authState.user.uid;
    await _dailyStepTrackingService.start(userId);
    _lastTrackedUserId = userId;
  }

  void _openLoginScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const LoginScreen(),
        ),
      ),
    );
  }

  void _openProfileFromHeader(AuthState authState) {
    if (authState is! Authenticated) {
      _openLoginScreen();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: authState.user),
      ),
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _scheduleTrackingReload() {
    if (_isTrackingInfoLoading) return;

    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is Authenticated
        ? authState.user.uid
        : null;

    if (currentUserId == null) {
      if (_trackingItems.isNotEmpty || _trackingHiddenIds.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _trackingItems = const [];
            _queueStatusById.clear();
            _trackingErrors.clear();
            _trackingHiddenIds.clear();
            _trackingUserId = null;
          });
        });
      }
      return;
    }

    final now = DateTime.now();
    final shouldReloadUser = _trackingUserId != currentUserId;
    final shouldReloadTime =
        _lastTrackingLoadAt == null ||
        now.difference(_lastTrackingLoadAt!) > const Duration(seconds: 4);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final shouldForceReload = await _bookingTrackingRepository
          .consumeTrackingReload();
      if (!mounted) return;
      if (shouldForceReload || shouldReloadUser || shouldReloadTime) {
        _loadBookingTrackingInfo(userId: currentUserId);
      }
    });
  }

  Future<void> _loadBookingTrackingInfo({required String userId}) async {
    if (_isTrackingInfoLoading) return;
    setState(() => _isTrackingInfoLoading = true);

    var shouldFinalize = true;
    try {
      final items = await _bookingTrackingRepository.loadTrackings(
        userId: userId,
      );
      final hiddenIds = await _bookingTrackingRepository
          .loadHiddenTrackingIds();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activeItems = items.where((item) {
        final apptDay = DateTime(
          item.appointmentDate.year,
          item.appointmentDate.month,
          item.appointmentDate.day,
        );
        return apptDay.isAtSameMomentAs(today) || apptDay.isAfter(today);
      }).toList();

      final expiredItems = items
          .where((item) {
            final apptDay = DateTime(
              item.appointmentDate.year,
              item.appointmentDate.month,
              item.appointmentDate.day,
            );
            return apptDay.isBefore(today);
          })
          .toList();

      for (final expired in expiredItems) {
        await _bookingTrackingRepository.removeTracking(expired.id);
        _bookingStatusListeners[expired.id]?.cancel();
        _bookingStatusListeners.remove(expired.id);
      }

      if (!mounted) {
        shouldFinalize = false;
        return;
      }
      final itemIds = activeItems.map((item) => item.id).toSet();
      setState(() {
        _trackingItems = activeItems;
        _trackingHiddenIds
          ..clear()
          ..addAll(hiddenIds.where(itemIds.contains));
        _trackingUserId = userId;
        _trackingErrors.removeWhere((key, _) => !itemIds.contains(key));
        _queueStatusById.removeWhere((key, _) => !itemIds.contains(key));
        _bookingStatusById
            .removeWhere((key, _) => !itemIds.contains(key));
      });
      final visibleItems = activeItems
          .where((item) => !_trackingHiddenIds.contains(item.id))
          .toList();
      if (visibleItems.isNotEmpty) {
        await Future.wait(visibleItems.map(_refreshBookingQueue));
        await Future.wait(visibleItems.map(_setupBookingStatusListener));
      }
    } catch (_) {
      // Ignore transient tracking load errors.
    } finally {
      if (shouldFinalize && mounted) {
        setState(() {
          _isTrackingInfoLoading = false;
          _lastTrackingLoadAt = DateTime.now();
        });
      }
    }
  }

  Future<void> _refreshBookingQueue(BookingTrackingInfo info) async {
    final trackingId = info.id;
    if (_refreshingTrackingIds.contains(trackingId)) return;
    setState(() {
      _refreshingTrackingIds.add(trackingId);
      _trackingErrors.remove(trackingId);
    });

    var removed = false;
    var shouldFinalize = true;
    try {
      final status = await _bookingTrackingRepository.fetchQueueStatus(info);
      if (!mounted) {
        shouldFinalize = false;
        return;
      }
      if (status.currentNumber > info.bookingNumber) {
        await _bookingTrackingRepository.removeTracking(trackingId);
        if (!mounted) {
          shouldFinalize = false;
          return;
        }
        setState(() {
          _trackingItems = _trackingItems
              .where((item) => item.id != trackingId)
              .toList();
          _queueStatusById.remove(trackingId);
          _trackingHiddenIds.remove(trackingId);
          _trackingErrors.remove(trackingId);
          _bookingStatusById.remove(trackingId);
        });
        removed = true;
      } else {
        setState(() {
          _queueStatusById[trackingId] = status;
        });
      }
    } catch (_) {
      if (!mounted) {
        shouldFinalize = false;
        return;
      }
      setState(() {
        _trackingErrors[trackingId] = 'تعذر تحديث الدور حاليا';
      });
    } finally {
      if (shouldFinalize && mounted) {
        setState(() {
          _refreshingTrackingIds.remove(trackingId);
        });
        if (removed) {
          _scheduleTrackingReload();
        }
      }
    }
  }

  Future<void> _setupBookingStatusListener(BookingTrackingInfo info) async {
    final trackingId = info.id;
    _bookingStatusListeners[trackingId]?.cancel();

    final startOfDay = DateTime(
      info.appointmentDate.year,
      info.appointmentDate.month,
      info.appointmentDate.day,
    );
    final endOfDay = DateTime(
      info.appointmentDate.year,
      info.appointmentDate.month,
      info.appointmentDate.day,
      23,
      59,
      59,
    );

    final stream = FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: info.clinicId)
        .where(
          'appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .snapshots();

    final subscription = stream.listen((snapshot) {
      if (!mounted) return;

      final matchingDoc = snapshot.docs.where((doc) {
        final data = doc.data();
        final bookingNumber = data['bookingNumber'] as int?;
        return bookingNumber == info.bookingNumber;
      }).firstOrNull;

      if (matchingDoc != null) {
        final data = matchingDoc.data();
        final statusStr = data['status'] as String? ?? 'pending';
        BookingStatus? newStatus;
        switch (statusStr) {
          case 'confirmed':
            newStatus = BookingStatus.confirmed;
            break;
          case 'cancelled':
            newStatus = BookingStatus.cancelled;
            break;
          case 'completed':
            newStatus = BookingStatus.completed;
            break;
          case 'noShow':
            newStatus = BookingStatus.noShow;
            break;
          default:
            newStatus = BookingStatus.pending;
        }

        final oldStatus = _bookingStatusById[trackingId];
        if (oldStatus != newStatus) {
          setState(() {
            _bookingStatusById[trackingId] = newStatus!;
          });

          if (newStatus == BookingStatus.confirmed &&
              oldStatus == BookingStatus.pending) {
            NotificationService.showBookingStatusNotification(
              title: 'تم تأكيد حجزك ✅',
              body: 'تم تأكيد حجزك لدى ${info.displayName} - ${info.departmentName}',
              notificationId: 70000 + trackingId.hashCode.abs(),
            );
          } else if (newStatus == BookingStatus.cancelled) {
            NotificationService.showBookingStatusNotification(
              title: 'تم إلغاء حجزك',
              body: 'تم إلغاء حجزك لدى ${info.displayName}',
              notificationId: 70000 + trackingId.hashCode.abs(),
            );
          }
        }
      }
    });

    _bookingStatusListeners[trackingId] = subscription;
  }

  Future<void> _hideTrackingCard(String trackingId) async {
    await _bookingTrackingRepository.setTrackingHidden(trackingId, true);
    if (!mounted) return;
    setState(() {
      _trackingHiddenIds.add(trackingId);
    });
  }

  String _formatTrackingDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildTrackingChip({
    required String label,
    required String value,
    required IconData icon,
    Color accentColor = const Color(0xFF0B7285),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B7285),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCardsSection(List<BookingTrackingInfo> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    final sortedItems = [...items]
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    final children = <Widget>[];
    for (var i = 0; i < sortedItems.length; i++) {
      children.add(_buildBookingTrackingCard(sortedItems[i]));
      if (i != sortedItems.length - 1) {
        children.add(const SizedBox(height: 10));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildBookingTrackingCard(BookingTrackingInfo info) {
    final queue = _queueStatusById[info.id];
    final currentNumber = queue?.currentNumber.toString() ?? '--';
    final patientsAhead = queue?.patientsAhead.toString() ?? '--';
    final isRefreshing = _refreshingTrackingIds.contains(info.id);
    final errorMessage = _trackingErrors[info.id];
    final bookingStatus = _bookingStatusById[info.id] ?? BookingStatus.pending;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (bookingStatus) {
      case BookingStatus.confirmed:
        statusColor = const Color(0xFF059669);
        statusLabel = 'مؤكد';
        statusIcon = Icons.check_circle_rounded;
        break;
      case BookingStatus.cancelled:
        statusColor = const Color(0xFFDC2626);
        statusLabel = 'ملغي';
        statusIcon = Icons.cancel_rounded;
        break;
      case BookingStatus.completed:
        statusColor = const Color(0xFF64748B);
        statusLabel = 'تم';
        statusIcon = Icons.event_available_rounded;
        break;
      case BookingStatus.noShow:
        statusColor = const Color(0xFFB45309);
        statusLabel = 'لم يحضر';
        statusIcon = Icons.event_busy_rounded;
        break;
      case BookingStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'في الانتظار';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Material(
      color: Colors.transparent,
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.merge(
            Border(right: BorderSide(color: Color(0xFF0B7285), width: 0.5)),
            Border(bottom: BorderSide(color: Color(0xFF0B7285), width: 1.5)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '[ تتبع حجزك ]',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 12,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B7285),
                        ),
                      ),
                      if (info.departmentName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          info.departmentName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _hideTrackingCard(info.id),
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF64748B),
                  splashRadius: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTrackingChip(
                    label: 'تاريخ الحجز',
                    value: _formatTrackingDate(info.appointmentDate),
                    icon: Icons.event_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTrackingChip(
                    label: 'رقمك',
                    value: info.bookingNumber.toString(),
                    icon: Icons.confirmation_number_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTrackingMetric(
                    label: 'الدور الحالي',
                    value: currentNumber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTrackingMetric(
                    label: 'المرضى قبلك',
                    value: patientsAhead,
                  ),
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isRefreshing
                    ? null
                    : () => _refreshBookingQueue(info),
                icon: isRefreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: AppLoadingIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  isRefreshing ? 'جاري التحديث...' : 'تحديث الدور',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B7285),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerFloatingActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      elevation: 2,
      backgroundColor: const Color(0xFF0B8293),
      foregroundColor: Colors.white,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(icon, size: 19),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (actionText != null && onActionTap != null)
          TextButton(onPressed: onActionTap, child: Text(actionText)),
      ],
    );
  }

  Widget _buildServicesHeader() {
    return _buildSectionHeader(
      title: 'الخدمات الطبية',
      subtitle: 'اختار الخدمة المناسبة ليك بسرعة',
    );
  }

  Widget _buildQuickCommerceActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'اختصارات سريعة',
          subtitle: 'أهم المسارات بضغطة واحدة',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _QuickActionChip(
                title: 'العروض الآن',
                icon: Icons.local_offer_rounded,
                colors: const [_primary, _secondary],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllOffersScreen()),
                  );
                },
              ),
              _QuickActionChip(
                title: 'الصيدليات',
                icon: Icons.local_pharmacy_rounded,
                colors: const [_primary, Color(0xFF0284C7)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PharmacyHomePage()),
                  );
                },
              ),
              _QuickActionChip(
                title: 'الجيم',
                icon: Icons.fitness_center_rounded,
                colors: const [Color(0xFF10B981), Color(0xFF059669)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => GymCubit(GymRepository()),
                        child: const GymsListScreen(),
                      ),
                    ),
                  );
                },
              ),
              _QuickActionChip(
                title: 'المستلزمات',
                icon: Icons.medical_services_rounded,
                colors: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthCubit>(),
                        child: const MedicalSuppliesScreen(),
                      ),
                    ),
                  );
                },
              ),
              _QuickActionChip(
                title: 'الأدوية',
                icon: Icons.medication_rounded,
                colors: const [_accent, Color(0xFFEA580C)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MedicinesScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onBottomNavTap(int index) {
    _dismissKeyboard();
    if (_bottomNavIndex == index) {
      return;
    }

    setState(() => _bottomNavIndex = index);
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        minimum: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: _BottomNavPill(
                label: 'الرئيسية',
                icon: Icons.home_rounded,
                selectedIcon: Icons.home_rounded,
                selected: _bottomNavIndex == 0,
                onTap: () => _onBottomNavTap(0),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _BottomNavPill(
                label: 'مواعيد الأدوية',
                icon: Icons.calendar_month_rounded,
                selectedIcon: Icons.calendar_month_rounded,
                selected: _bottomNavIndex == 1,
                onTap: () => _onBottomNavTap(1),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _BottomNavPill(
                label: 'طوارئ',
                icon: Icons.emergency_rounded,
                selectedIcon: Icons.emergency_rounded,
                selected: _bottomNavIndex == 2,
                onTap: () => _onBottomNavTap(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _BottomNavPill(
                label: 'الحساب',
                icon: Icons.person_rounded,
                selectedIcon: Icons.person_rounded,
                selected: _bottomNavIndex == 3,
                onTap: () => _onBottomNavTap(3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(AuthState authState) {
    return SizedBox(
      height: 54,
      child: Stack(
        children: [
          const Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mallawi Cure',
                  style: TextStyle(
                    color: Color(0xFF0F4C5C),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                  ),
                ),
                SizedBox(width: 7),
                Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF0B7285),
                  size: 22,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF334155),
                    size: 25,
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildCartAction(authState),
          ),
        ],
      ),
    );
  }

  Widget _buildCartAction(AuthState authState) {
    if (authState is! Authenticated) {
      return IconButton(
        icon: const Icon(
          Icons.shopping_cart_rounded,
          color: Color(0xFF0B8293),
          size: 22,
        ),
        tooltip: 'سلة الطلبات',
        onPressed: _openLoginScreen,
      );
    }

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('medicine_requests')
          .where('userId', isEqualTo: authState.user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(100)
          .get(),
      builder: (context, snapshot) {
        final requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_rounded,
                color: Color(0xFF0B8293),
                size: 22,
              ),
              tooltip: 'سلة الطلبات',
              onPressed: () => _openMyRequests(),
            ),
            if (requestCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      requestCount > 99 ? '99+' : requestCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openMyRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const MyMedicineRequestsScreen(),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      //margin: const EdgeInsets.symmetric(horizontal: 14),
      //  height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onTapOutside: (_) => _dismissKeyboard(),
        onChanged: _onSearchTextChanged,
        onSubmitted: _onSearchSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),

        decoration: InputDecoration(
          filled: false,
          fillColor: Colors.white,
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'ابحث عن العيادات، الصيدليات، المعامل ...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          prefixIcon: _isSearchLoading
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: AppLoadingIndicator(strokeWidth: 2),
                  ),
                )
              : Icon(
                  Icons.manage_search_rounded,
                  color: Color(0xFF0B7285),
                  size: 20,
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: IconButton(
                    onPressed: _clearSearch,
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(child: _buildSearchField()),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          height: 44,
          child: ElevatedButton(
            onPressed: _isSearchLoading ? null : _triggerSearch,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xFF0B7285),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSearchLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: AppLoadingIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search_rounded, size: 21),
          ),
        ),
      ],
    );
  }

  void _onSearchTextChanged(String value) {
    if (_searchQuery.isEmpty && _searchResults.isEmpty && !_isSearchLoading) {
      return;
    }

    setState(() {
      _searchQuery = '';
      _searchResults = const [];
      _isSearchLoading = false;
    });
  }

  void _onSearchSubmitted(String value) {
    _triggerSearch();
  }

  Future<void> _triggerSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _clearSearch();
      _dismissKeyboard();
      return;
    }

    _dismissKeyboard();
    await _performGlobalSearch(query);

    if (!mounted) return;

    if (_searchResults.isEmpty && _openByCategoryKeyword(query)) {
      return;
    }

    if (_searchResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد نتائج مطابقة حاليًا')),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = const [];
      _isSearchLoading = false;
    });
  }

  Future<void> _performGlobalSearch(String rawQuery) async {
    final query = rawQuery.trim();

    if (!mounted) {
      return;
    }

    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = const [];
        _isSearchLoading = false;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _isSearchLoading = true;
    });

    final normalized = query.toLowerCase();

    final futures = <Future<List<_HomeSearchResult>>>[
      _searchCollection(
        collection: 'pharmacies',
        type: _SearchEntityType.pharmacy,
        displayType: 'صيدلية',
        fields: const ['name', 'pharmacyName', 'description', 'address'],
        normalizedQuery: normalized,
        constraints: (ref) => ref.limit(80),
      ),
      _searchCollection(
        collection: 'clinics',
        type: _SearchEntityType.clinic,
        displayType: 'عيادة',
        fields: const [
          'name',
          'clinicName',
          'doctorName',
          'specialization',
          'address',
        ],
        normalizedQuery: normalized,
        constraints: (ref) => ref.limit(80),
      ),
      _searchCollection(
        collection: 'laboratories',
        type: _SearchEntityType.laboratory,
        displayType: 'معمل',
        fields: const ['name', 'labName', 'description', 'address'],
        normalizedQuery: normalized,
        constraints: (ref) => ref.limit(80),
      ),
      _searchCollection(
        collection: 'radiology_centers',
        type: _SearchEntityType.radiology,
        displayType: 'مركز أشعة',
        fields: const ['name', 'centerName', 'description', 'address'],
        normalizedQuery: normalized,
        constraints: (ref) => ref.limit(80),
      ),
      _searchCollection(
        collection: 'gyms',
        type: _SearchEntityType.gym,
        displayType: 'جيم',
        fields: const ['name', 'description', 'address'],
        normalizedQuery: normalized,
        constraints: (ref) => ref.limit(80),
      ),
    ];

    final results = (await Future.wait(
      futures,
    )).expand((e) => e).take(12).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _searchResults = results;
      _isSearchLoading = false;
    });
  }

  Future<List<_HomeSearchResult>> _searchCollection({
    required String collection,
    required _SearchEntityType type,
    required String displayType,
    required List<String> fields,
    required String normalizedQuery,
    required Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> ref,
    )
    constraints,
  }) async {
    try {
      final ref = FirebaseFirestore.instance.collection(collection);
      final snapshot = await constraints(ref).get();
      final matches = <_HomeSearchResult>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final searchable = _buildSearchableText(data, fields);
        if (!searchable.contains(normalizedQuery)) {
          continue;
        }

        final title = _extractFirstFilledString(data, const [
          'name',
          'pharmacyName',
          'clinicName',
          'doctorName',
          'labName',
          'centerName',
        ]);

        matches.add(
          _HomeSearchResult(
            id: doc.id,
            type: type,
            displayType: displayType,
            title: title.isEmpty ? displayType : title,
            subtitle: _extractFirstFilledString(data, const [
              'address',
              'description',
            ]),
          ),
        );
      }

      return matches;
    } catch (_) {
      return const [];
    }
  }

  String _buildSearchableText(Map<String, dynamic> data, List<String> fields) {
    final buffer = StringBuffer();
    for (final key in fields) {
      final value = data[key];
      if (value is String) {
        buffer.write(' ${value.toLowerCase()}');
      } else if (value is List) {
        for (final item in value) {
          buffer.write(' ${item.toString().toLowerCase()}');
        }
      }
    }
    return buffer.toString();
  }

  String _extractFirstFilledString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = data[key]?.toString().trim() ?? '';
      if (raw.isNotEmpty) {
        return raw;
      }
    }
    return '';
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isSearchLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: AppLoadingIndicator(minHeight: 2),
      );
    }

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Text(
            'لا توجد نتائج مطابقة. جرّب اسم آخر أو نوع خدمة.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: List.generate(_searchResults.length, (index) {
            final result = _searchResults[index];
            final isLast = index == _searchResults.length - 1;
            return InkWell(
              onTap: () => _openSearchResult(result),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF0B7285),
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result.subtitle.isEmpty
                                ? result.displayType
                                : result.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        result.displayType,
                        style: const TextStyle(
                          color: Color(0xFF0E7490),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showDetailsOpenError() {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تعذر فتح التفاصيل الآن')));
  }

  Future<void> _openSearchResult(_HomeSearchResult result) async {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = const [];
      _isSearchLoading = false;
    });

    switch (result.type) {
      case _SearchEntityType.pharmacy:
        if (result.id.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PharmacyHomePage()),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => PharmacyCubit(PharmacyRepository()),
              child: PharmacyDetailsScreen(pharmacyId: result.id),
            ),
          ),
        );
        return;
      case _SearchEntityType.clinic:
        if (result.id.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClinicHomePage()),
          );
          return;
        }
        try {
          final doc = await FirebaseFirestore.instance
              .collection('clinics')
              .doc(result.id)
              .get();

          if (!doc.exists) {
            _showDetailsOpenError();
            return;
          }

          final clinic = ClinicModel.fromFirestore(doc);
          if (!mounted) {
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClinicDetailsScreen(clinic: clinic),
            ),
          );
        } catch (_) {
          _showDetailsOpenError();
        }
        return;
      case _SearchEntityType.laboratory:
        if (result.id.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LaboratoryHomePage()),
          );
          return;
        }
        try {
          final doc = await FirebaseFirestore.instance
              .collection('laboratories')
              .doc(result.id)
              .get();

          if (!doc.exists) {
            _showDetailsOpenError();
            return;
          }

          final laboratory = LaboratoryModel.fromFirestore(doc);
          if (!mounted) {
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LaboratoryDetailsClinicStyleScreen(laboratory: laboratory),
            ),
          );
        } catch (_) {
          _showDetailsOpenError();
        }
        return;
      case _SearchEntityType.radiology:
        if (result.id.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) =>
                    RadiologyCubit(RadiologyRepository())
                      ..loadApprovedRadiologyCenters(),
                child: const RadiologyHomePage(),
              ),
            ),
          );
          return;
        }
        try {
          final doc = await FirebaseFirestore.instance
              .collection('radiology_centers')
              .doc(result.id)
              .get();
          final data = doc.data();

          if (!doc.exists || data == null) {
            _showDetailsOpenError();
            return;
          }

          final radiology = RadiologyModel.fromMap({...data, 'id': doc.id});
          if (!mounted) {
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RadiologyDetailScreen(radiology: radiology),
            ),
          );
        } catch (_) {
          _showDetailsOpenError();
        }
        return;
      case _SearchEntityType.gym:
        if (result.id.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => GymCubit(GymRepository()),
                child: const GymsListScreen(),
              ),
            ),
          );
          return;
        }
        try {
          final doc = await FirebaseFirestore.instance
              .collection('gyms')
              .doc(result.id)
              .get();

          if (!doc.exists) {
            _showDetailsOpenError();
            return;
          }

          final gym = GymModel.fromFirestore(doc);
          if (!mounted) {
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GymDetailsScreen(gym: gym)),
          );
        } catch (_) {
          _showDetailsOpenError();
        }
        return;
    }
  }

  bool _openByCategoryKeyword(String query) {
    final normalized = query.toLowerCase();
    if (normalized.contains('صيد')) {
      _openSearchResult(
        const _HomeSearchResult(
          id: '',
          type: _SearchEntityType.pharmacy,
          displayType: 'صيدلية',
          title: 'الصيدليات',
          subtitle: '',
        ),
      );
      return true;
    }
    if (normalized.contains('عياد') || normalized.contains('دكتور')) {
      _openSearchResult(
        const _HomeSearchResult(
          id: '',
          type: _SearchEntityType.clinic,
          displayType: 'عيادة',
          title: 'العيادات',
          subtitle: '',
        ),
      );
      return true;
    }
    if (normalized.contains('معمل') || normalized.contains('تحاليل')) {
      _openSearchResult(
        const _HomeSearchResult(
          id: '',
          type: _SearchEntityType.laboratory,
          displayType: 'معمل',
          title: 'المعامل',
          subtitle: '',
        ),
      );
      return true;
    }
    if (normalized.contains('اشع') || normalized.contains('أشع')) {
      _openSearchResult(
        const _HomeSearchResult(
          id: '',
          type: _SearchEntityType.radiology,
          displayType: 'مركز أشعة',
          title: 'مراكز الأشعة',
          subtitle: '',
        ),
      );
      return true;
    }
    if (normalized.contains('جيم') || normalized.contains('رياض')) {
      _openSearchResult(
        const _HomeSearchResult(
          id: '',
          type: _SearchEntityType.gym,
          displayType: 'جيم',
          title: 'الجيم',
          subtitle: '',
        ),
      );
      return true;
    }
    return false;
  }

  Widget _buildSectionRow({
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionText != null && onActionTap != null)
          TextButton(onPressed: onActionTap, child: Text(actionText)),
      ],
    );
  }

  Widget _buildPrimaryServicesGrid() {
    const Color pharmacyAccent = Color(0xFF0B7285);
    const Color clinicAccent = Color(0xFF0B7285);
    const Color labAccent = Color(0xFF0B7285);
    const Color radiologyAccent = Color(0xFF0B7285);
    const Color gymAccent = Color(0xFF0B7285);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HomePrimaryServiceCard(
                title: 'الصيدليات',
                subtitle: 'طلب أدوية أونلاين',
                icon: Icons.medication_rounded,
                backgroundColor: Colors.white,
                accentColor: pharmacyAccent,
                iconColor: pharmacyAccent,
                textColor: const Color(0xFF3C4A5D),
                borderColor: const Color(0xFFE2E8F0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PharmacyHomePage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HomePrimaryServiceCard(
                title: 'العيادات',
                subtitle: 'احجز موعدك الآن',
                icon: Icons.medical_services_rounded,
                backgroundColor: Colors.white,
                accentColor: clinicAccent,
                iconColor: clinicAccent,
                textColor: const Color(0xFF3C4A5D),
                borderColor: const Color(0xFFE2E8F0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClinicHomePage()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HomeSecondaryServiceCard(
                title: 'المعامل',
                icon: Icons.science_rounded,
                accentColor: labAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LaboratoryHomePage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeSecondaryServiceCard(
                title: 'الأشعة',
                icon: Icons.biotech_rounded,
                accentColor: radiologyAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) =>
                            RadiologyCubit(RadiologyRepository())
                              ..loadApprovedRadiologyCenters(),
                        child: const RadiologyHomePage(),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeSecondaryServiceCard(
                title: 'الجيم',
                icon: Icons.fitness_center_rounded,
                accentColor: gymAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => GymCubit(GymRepository()),
                        child: const GymsListScreen(),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

                        Expanded(
              child: _HomeSecondaryServiceCard(
                title: 'مستلزمات',
                icon: Icons.medical_services_rounded,
                accentColor: gymAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthCubit>(),
                        child: const MedicalSuppliesScreen(),
                      ),
                    ),
                  );
                },
              ),
            ),
         
          ],
        ),
      
      ],
    );
  }

  Widget _buildHomeTab(AuthState authState) {
    _scheduleTrackingReload();

    final visibleTrackings = authState is Authenticated
        ? _trackingItems
              .where((item) => !_trackingHiddenIds.contains(item.id))
              .toList()
        : const <BookingTrackingInfo>[];
    final hasTrackingCards = visibleTrackings.isNotEmpty;
    final contentBottomPadding = 24 + MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissKeyboard,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, contentBottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopHeader(authState),
                  const SizedBox(height: 8),
                  if (hasTrackingCards) ...[
                    _buildTrackingCardsSection(visibleTrackings),
                    const SizedBox(height: 12),
                  ],
                  _buildSearchBar(),
                  _buildSearchResults(),
                  const SizedBox(height: 18),
                  _buildPrimaryServicesGrid(),
                  const SizedBox(height: 18),
                  _buildSectionRow(
                    title: 'العيادات المميزة',
                    actionText: 'عرض الكل',
                    onActionTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClinicHomePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const _HomeDoctorPreviewCard(),
                  const SizedBox(height: 18),
                  _buildSectionRow(
                    title: 'العروض والخصومات',
                    actionText: 'عرض الكل',
                    onActionTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllOffersScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const HomeMixedOffersCarousel(),
                  const SizedBox(height: 16),
                  DailyActivityCard(onGuestTap: _openLoginScreen),
                  const SizedBox(height: 12),
                  const DailyInfoCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicinesTab(AuthState authState) {
    if (authState is! Authenticated) {
      return _buildAuthRequiredTab(
        title: 'مواعيد الأدوية',
        subtitle: 'سجّل دخولك لإدارة مواعيد الأدوية والتنبيهات',
      );
    }

    return BlocProvider(
      create: (_) =>
          MedicineCubit(MedicineRepository())
            ..loadUserMedicines(authState.user.uid),
      child: _HomeMedicinesTabView(userId: authState.user.uid),
    );
  }

  Widget _buildAccountTab(AuthState authState) {
    if (authState is! Authenticated) {
      return _buildAuthRequiredTab(
        title: 'الحساب',
        subtitle: 'سجّل دخولك لعرض بياناتك وإدارة حسابك',
      );
    }

    final isSpecificAdmin =
        authState.user.email.trim().toLowerCase() == 'kerolesmored@gmail.com';

    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الحساب',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final userName = authState.user.displayName.trim().isEmpty
                      ? 'مستخدم ملوي كيور'
                      : authState.user.displayName.trim();
                  final initialSource =
                      authState.user.displayName.trim().isNotEmpty
                      ? authState.user.displayName.trim()
                      : authState.user.email.trim();
                  final userInitial = initialSource.isEmpty
                      ? 'M'
                      : initialSource.characters.first.toUpperCase();

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF0B8293),
                          child: Text(
                            userInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0B8293),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                authState.user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _HomeAccountActionCard(
                title: 'الملف الشخصي',
                subtitle: 'عرض وتعديل بيانات الحساب',
                icon: Icons.person_outline_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(user: authState.user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _HomeAccountActionCard(
                title: 'إضافة مكان',
                subtitle: 'إضافة نشاطك الطبي داخل التطبيق',
                icon: Icons.add_business_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdditionsScreen()),
                  );
                },
              ),
              if (isSpecificAdmin) ...[
                const SizedBox(height: 10),
                _HomeAccountActionCard(
                  title: 'إدارة الأدمن',
                  subtitle: 'الموافقات وإدارة النظام',
                  icon: Icons.admin_panel_settings_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminHomePage()),
                    );
                  },
                ),
              ],
              const SizedBox(height: 10),
              _HomeAccountActionCard(
                title: 'أرقام الطوارئ',
                subtitle: 'الوصول السريع للأرقام المهمة',
                icon: Icons.emergency_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmergencyNumbersScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _HomeAccountActionCard(
                title: 'تسجيل الخروج',
                subtitle: 'الخروج من الحساب الحالي',
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFDC2626),
                onTap: () async {
                  final shouldSignOut = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل تريد تسجيل الخروج الآن؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('خروج'),
                        ),
                      ],
                    ),
                  );

                  if (shouldSignOut == true && mounted) {
                    await context.read<AuthCubit>().signOut();
                    if (mounted) {
                      setState(() => _bottomNavIndex = 0);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthRequiredTab({
    required String title,
    required String subtitle,
  }) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openLoginScreen,
              icon: const Icon(Icons.login_rounded),
              label: const Text('تسجيل الدخول'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B8293),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to create ClinicModel from cached data
  ClinicModel _clinicFromCachedData(String id, Map<String, dynamic> data) {
    // Parse working hours
    Map<String, WorkingHours> parsedWorkingHours = {};
    if (data['workingHours'] != null) {
      final hoursData = data['workingHours'] as Map<String, dynamic>;
      hoursData.forEach((day, hours) {
        if (hours != null) {
          parsedWorkingHours[day] = WorkingHours.fromMap(
            hours as Map<String, dynamic>,
          );
        }
      });
    }

    return ClinicModel(
      id: id,
      doctorName: data['doctorName'] ?? '',
      clinicType: data['clinicType'],
      department: ClinicDepartment.fromString(data['department'] ?? 'other'),
      specialization: data['specialization'] != null
          ? (data['specialization'] is List
              ? List<String>.from(data['specialization'])
              : [data['specialization'].toString()])
          : [],
      about: data['about'] ?? '',
      consultationFee: (data['consultationFee'] ?? 0).toDouble(),
      phones: data['phones'] != null
          ? List<String>.from(data['phones'])
          : (data['phone'] != null ? [data['phone']] : []),
      whatsapp: data['whatsapp'],
      address: data['address'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      governorate: data['governorate'] ?? 'المنيا',
      center: data['center'] ?? 'ملوي',
      authEmails: data['authEmails'] != null
          ? List<String>.from(data['authEmails'])
          : (data['doctorEmail'] != null ? [data['doctorEmail']] : []),
      doctorEmails: data['doctorEmails'] != null
          ? List<String>.from(data['doctorEmails'])
          : (data['doctorEmail'] != null ? [data['doctorEmail']] : []),
      secretaryEmails: data['secretaryEmails'] != null
          ? List<String>.from(data['secretaryEmails'])
          : [],
      doctorPhone: data['doctorPhone'],
      workingHours: parsedWorkingHours,
      holidays: List<String>.from(data['holidays'] ?? []),
      hasNursery: data['hasNursery'] ?? false,
      onlineBookingEnabled: data['onlineBookingEnabled'] ?? false,
      bookingLockDate: data['bookingLockDate'] != null
          ? (data['bookingLockDate'] is Timestamp
              ? (data['bookingLockDate'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(data['bookingLockDate']))
          : null,
      doctorImageUrl: data['doctorImageUrl'],
      isActive: data['isActive'] ?? true,
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(data['createdAt']))
          : DateTime.now(),
      ownerId: data['ownerId'],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
      viewsCount: (data['viewsCount'] as num? ?? 0).toInt(),
      profileViewsCount: (data['profileViewsCount'] as num? ?? 0).toInt(),
      lastFeaturedDate: data['lastFeaturedDate'] != null
          ? (data['lastFeaturedDate'] is Timestamp
              ? (data['lastFeaturedDate'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(data['lastFeaturedDate']))
          : null,
    );
  }

  Widget _buildCurrentTabBody(AuthState authState) {
    return IndexedStack(
      index: _bottomNavIndex,
      children: [
        _buildHomeTab(authState),
        _buildMedicinesTab(authState),
        const EmergencyNumbersScreen(),
        _buildAccountTab(authState),
      ],
    );
  }

  // دالة عرض dialog تأكيد الخروج
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    size: 48,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(height: 24),
                
                // العنوان
                const Text(
                  'تأكيد الخروج',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                
                // الرسالة
                const Text(
                  'هل أنت متأكد من الخروج من التطبيق؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // الأزرار
                Row(
                  children: [
                    // زر الإلغاء
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // زر الخروج
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          SystemNavigator.pop(); // إغلاق التطبيق
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'خروج',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false; // إذا ضغط خارج الـ dialog يرجع false
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is Authenticated &&
        _lastTrackedUserId != authState.user.uid) {
      Future.microtask(_ensureDailyTrackingForAuthenticatedUser);
    } else if (authState is! Authenticated && _lastTrackedUserId != null) {
      Future.microtask(_ensureDailyTrackingForAuthenticatedUser);
    }

    return WillPopScope(
      onWillPop: () => _showExitConfirmationDialog(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: const CustomHomeDrawer(),
      floatingActionButton: _bottomNavIndex == 0
          ? BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                // Show FAB for any location owner
                if (state is Authenticated) {
                  final role = state.user.role.trim().toLowerCase();
                  if (role == 'user' || role == 'admin') {
                    return const SizedBox.shrink();
                  }

                  // Check all location types at once - WITH CACHE
                  return FutureBuilder<Map<String, dynamic>>(
                    future: HomeFABCacheHelper.loadFABQueries(state.user.email),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final cacheData = snapshot.data!;
                        
                        // Extract data from cache format
                        final pharmacyDocs = HomeFABCacheHelper.getCollectionDocs(cacheData, 'pharmacies');
                        final clinicDocs = HomeFABCacheHelper.getCollectionDocs(cacheData, 'clinics');
                        final labDocs = HomeFABCacheHelper.getCollectionDocs(cacheData, 'laboratories');
                        final radiologyDocs = HomeFABCacheHelper.getCollectionDocs(cacheData, 'radiology_centers');
                        final gymDocs = HomeFABCacheHelper.getCollectionDocs(cacheData, 'gyms');
                        final medicalSupplyDocs = HomeFABCacheHelper.getCollectionDocs(cacheData, 'medical_supplies');

                        print('📊 [FAB DEBUG] Docs count:');
                        print('  - Pharmacy: ${pharmacyDocs.length}');
                        print('  - Clinic: ${clinicDocs.length}');
                        print('  - Lab: ${labDocs.length}');
                        print('  - Radiology: ${radiologyDocs.length}');
                        print('  - Gym: ${gymDocs.length}');
                        print('  - Medical Supply: ${medicalSupplyDocs.length}');

                        // Priority order: Pharmacy > Medical Supply > Clinic > Laboratory > Radiology > Gym
                        if (pharmacyDocs.isNotEmpty) {
                          print('✅ [FAB] Showing Pharmacy button');
                          return _buildOwnerFloatingActionButton(
                            label: 'إدارة الصيدلية',
                            icon: Icons.dashboard,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PharmacyControlPage(),
                                ),
                              );
                            },
                          );
                        } else if (medicalSupplyDocs.isNotEmpty) {
                          try {
                            final supplyMap = HomeFABCacheHelper.getFirstDocData(cacheData, 'medical_supplies');
                            if (supplyMap == null) {
                              return const SizedBox.shrink();
                            }
                            final supply = MedicalSupplyModel.fromJson(supplyMap);
                            return _buildOwnerFloatingActionButton(
                              label: 'إدارة المستلزمات',
                              icon: Icons.medical_services_rounded,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MedicalSupplyHomePage(supply: supply),
                                  ),
                                );
                              },
                            );
                          } catch (e) {
                            print('❌ Error loading medical supply: $e');
                            return const SizedBox.shrink();
                          }
                        } else if (clinicDocs.isNotEmpty) {
                          // Check if user is secretary in ONE or MULTIPLE clinics
                          final userEmail = state.user.email;
                          final List<ClinicModel> secretaryClinics = [];
                          ClinicModel? ownerClinic;

                          print('🏥 [FAB DEBUG] Found ${clinicDocs.length} clinic docs');
                          print('🏥 [FAB DEBUG] User email: $userEmail');

                          // Loop through all clinics to find where user is registered
                          for (var clinicDocData in clinicDocs) {
                            try {
                              final clinicData = clinicDocData['data'] as Map<String, dynamic>;
                              final clinicId = clinicDocData['id'] as String;
                              
                              final secretaryEmails =
                                clinicData['secretaryEmails'] != null
                                ? List<String>.from(
                                    clinicData['secretaryEmails'],
                                  )
                                : <String>[];
                              final authEmails = clinicData['authEmails'] != null
                                ? List<String>.from(clinicData['authEmails'])
                                : <String>[];

                              print('🏥 [FAB DEBUG] Clinic ID: $clinicId');
                              print('🏥 [FAB DEBUG] Secretary emails: $secretaryEmails');
                              print('🏥 [FAB DEBUG] Auth emails: $authEmails');

                              // Check if user is secretary
                              if (secretaryEmails.contains(userEmail)) {
                                print('✅ [FAB DEBUG] User is SECRETARY in clinic $clinicId');
                                secretaryClinics.add(
                                  _clinicFromCachedData(clinicId, clinicData),
                                );
                              }
                              // Check if user is owner/doctor (not secretary)
                              else if (authEmails.contains(userEmail)) {
                                print('✅ [FAB DEBUG] User is OWNER in clinic $clinicId');
                                ownerClinic = _clinicFromCachedData(clinicId, clinicData);
                              } else {
                                print('❌ [FAB DEBUG] User email NOT found in clinic $clinicId');
                              }
                            } catch (e) {
                              print('❌ Error parsing clinic from cache: $e');
                            }
                          }

                          print('🏥 [FAB DEBUG] Secretary clinics: ${secretaryClinics.length}');
                          print('🏥 [FAB DEBUG] Owner clinic: ${ownerClinic != null ? "YES" : "NO"}');

                          // Priority: Secretary > Owner
                          if (secretaryClinics.isNotEmpty) {
                            // Subscribe secretary to all clinic topics (in background)
                            final clinicIds = secretaryClinics
                                .map((c) => c.id)
                                .toList();
                            NotificationService()
                                .subscribeToMultipleClinicTopics(
                                  clinicIds,
                                  state.user.uid,
                                );

                            // User is a secretary
                            if (secretaryClinics.length == 1) {
                              // Only one clinic - go directly to bookings
                              final clinic = secretaryClinics.first;
                              return _buildOwnerFloatingActionButton(
                                label: 'الحجز',
                                icon: Icons.calendar_today,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BookingsManagementScreen(
                                            clinic: clinic,
                                          ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              // Multiple clinics - go to selection screen
                              return _buildOwnerFloatingActionButton(
                                label: 'الحجز',
                                icon: Icons.calendar_today,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ClinicsSelectionScreen(
                                            clinics: secretaryClinics,
                                          ),
                                    ),
                                  );
                                },
                              );
                            }
                          } else if (ownerClinic != null) {
                            // User is owner/doctor - goes to control page
                            return _buildOwnerFloatingActionButton(
                              label: 'إدارة العيادة',
                              icon: Icons.dashboard,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ClinicControlPage(),
                                  ),
                                );
                              },
                            );
                          }
                        } else if (labDocs.isNotEmpty) {
                          return _buildOwnerFloatingActionButton(
                            label: 'إدارة المعمل',
                            icon: Icons.dashboard,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LaboratoryOwnerDashboard(),
                                ),
                              );
                            },
                          );
                        } else if (radiologyDocs.isNotEmpty) {
                          return _buildOwnerFloatingActionButton(
                            label: 'إدارة مركز الأشعة',
                            icon: Icons.dashboard,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RadiologyOwnerDashboard(),
                                ),
                              );
                            },
                          );
                        } else if (gymDocs.isNotEmpty) {
                          return _buildOwnerFloatingActionButton(
                            label: 'إدارة الجيم',
                            icon: Icons.dashboard,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GymControlPage(
                                    gymEmail: state.user.email,
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            )
          : null,
      body: _buildCurrentTabBody(authState),
      bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }
}

class _HomeMedicinesTabView extends StatelessWidget {
  final String userId;

  const _HomeMedicinesTabView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مواعيد الأدوية',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'تابع مواعيدك اليومية وفعل التنبيهات',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<MedicineCubit>(),
                            child: const AddMedicineScreen(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'إضافة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B8293),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<MedicineCubit, MedicineState>(
                listener: (context, state) {
                  if (state is MedicineAdded ||
                      state is MedicineUpdated ||
                      state is MedicineDeleted ||
                      state is MedicineError) {
                    String message = '';
                    if (state is MedicineAdded) {
                      message = state.message;
                    } else if (state is MedicineUpdated) {
                      message = state.message;
                    } else if (state is MedicineDeleted) {
                      message = state.message;
                    } else if (state is MedicineError) {
                      message = state.message;
                    }

                    if (message.isNotEmpty) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                  }
                },
                builder: (context, state) {
                  if (state is MedicineLoading) {
                    return const Center(child: AppLoadingIndicator());
                  }

                  if (state is MedicinesLoaded) {
                    if (state.medicines.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد أدوية مضافة حاليًا',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 18),
                      itemCount: state.medicines.length,
                      itemBuilder: (context, index) {
                        final medicine = state.medicines[index];
                        return MedicineCard(
                          medicine: medicine,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider.value(
                                  value: context.read<MedicineCubit>(),
                                  child: EditMedicineScreen(medicine: medicine),
                                ),
                              ),
                            );
                          },
                          onToggle: () {
                            context.read<MedicineCubit>().toggleMedicineStatus(
                              medicine.id,
                              !medicine.isActive,
                              userId,
                            );
                          },
                          onDelete: () {
                            final medicineCubit = context.read<MedicineCubit>();
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content: const Text('هل تريد حذف هذا الدواء؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      medicineCubit.deleteMedicine(
                                        medicine.id,
                                        userId,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAccountActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _HomeAccountActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF0B8293),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePrimaryServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
  final Color iconColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _HomePrimaryServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    this.accentColor = const Color(0xFF0EA5B8),
    required this.iconColor,
    required this.textColor,
    this.borderColor = Colors.transparent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 118,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.merge(
              Border(right: BorderSide(color: accentColor, width: 0.5)),
              Border(bottom: BorderSide(color: accentColor, width: 1.5)),
            ),
            // boxShadow: [
            //   BoxShadow(
            //     color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            //     blurRadius: 12,
            //     offset: const Offset(0, 4),
            //   ),
            // ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.95),
                            accentColor.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            accentColor.withValues(alpha: 0.20),
                            accentColor.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Icon(icon, size: 20, color: accentColor),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.86),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSecondaryServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _HomeSecondaryServiceCard({
    required this.title,
    required this.icon,
    this.accentColor = const Color(0xFF0EA5B8),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),

            //border: Border.all(color: AppTheme.secondaryColor ),
            border: Border.merge(
              Border(right: BorderSide(color: accentColor, width: 0.5)),
              Border(bottom: BorderSide(color: accentColor, width: 1.5)),
            ), // boxShadow: [
            //   BoxShadow(
            //     color: const Color(0xFF0F172A).withValues(alpha: 0.045),
            //     blurRadius: 8,
            //     offset: const Offset(0, 3),
            //   ),
            // ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        accentColor.withValues(alpha: 0.22),
                        accentColor.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(icon, size: 17, color: accentColor),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4B5B70),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeCategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeCategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6F3),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF0F766E),
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeDoctorPreviewCard extends StatefulWidget {
  const _HomeDoctorPreviewCard();

  @override
  State<_HomeDoctorPreviewCard> createState() => _HomeDoctorPreviewCardState();
}

class _HomeDoctorPreviewCardState extends State<_HomeDoctorPreviewCard> {
  static const int _dailyFeaturedClinicsCount = 10;
  static const int _dailyFeaturedClinicsFetchLimit = 500;
  static const int _initialPage = 500;

  late final PageController _pageController;
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _clinicsFuture;
  Timer? _autoScrollTimer;
  int _currentPage = _initialPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.92,
    );
    _clinicsFuture = _loadDailyClinics();
    _scheduleDailyRefresh();
  }

  void _scheduleDailyRefresh() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    Timer(timeUntilMidnight, () {
      _autoScrollTimer?.cancel();
      _clinicsFuture = _loadDailyClinics();
      if (mounted) {
        setState(() {});
        _scheduleDailyRefresh();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _syncAutoScroll(int itemCount) {
    _autoScrollTimer?.cancel();
    if (itemCount <= 1) {
      return;
    }

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) {
        return;
      }

      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  double? _extractNumeric(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw is num) {
        return raw.toDouble();
      }

      if (raw is String) {
        final normalized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
        final parsed = double.tryParse(normalized);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadDailyClinics() async {
    try {
      final featuredIds =
          await DailyFeaturedClinicsService.getTodayFeaturedClinicIds();

      if (featuredIds.isEmpty) {
        return _fallbackClinics();
      }

      final batches = <List<String>>[];
      for (var i = 0; i < featuredIds.length; i += 10) {
        batches.add(
          featuredIds.sublist(
            i,
            i + 10 > featuredIds.length ? featuredIds.length : i + 10,
          ),
        );
      }

      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final batch in batches) {
        final snapshot = await FirebaseFirestore.instance
            .collection('clinics')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        docs.addAll(snapshot.docs);
      }

      if (docs.isEmpty) {
        return _fallbackClinics();
      }

      docs.shuffle();
      return docs;
    } catch (e) {
      print('⚠️ _loadDailyClinics error: $e');
      return _fallbackClinics();
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _fallbackClinics() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .get();
      final docs = snapshot.docs;
      if (docs.isEmpty) return [];
      docs.shuffle();
      return docs.take(_dailyFeaturedClinicsCount).toList();
    } catch (e) {
      print('⚠️ _fallbackClinics error: $e');
      return [];
    }
  }

  Widget _clinicImagePlaceholder() {
    // نسخة 1: باللوجو (أبسط وأنظف)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white
      /*   gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
         /*  colors: [
            const Color(0xFFF8FAFC),
          //  const Color(0xFFE0F2FE).withOpacity(0.5),
            const Color.fromARGB(255, 255, 255, 255),
          ], */
          stops: const [0.0, 0.5, 1.0],
        ), */
      ),
      child: Center(
        child: Container(
          color: Colors.white,
        //  padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/images/clinicLogo.png',
           // width: 120,
           // height: 120,
            fit: BoxFit.fill,
            // Add subtle shadow
            //color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.05),
            colorBlendMode: BlendMode.dstATop,
          ),
        ),
      ),
    );
    
    /* نسخة 2: بالدوائر والأيقونة (الحالية - أكثر تفصيل)
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0EA5E9).withOpacity(0.08),
            const Color(0xFF06B6D4).withOpacity(0.12),
            const Color(0xFF0891B2).withOpacity(0.08),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles in background
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0EA5E9).withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withOpacity(0.08),
              ),
            ),
          ),
          // Medical icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.medical_services_rounded,
                color: const Color(0xFF0891B2),
                size: 42,
              ),
            ),
          ),
        ],
      ),
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: _clinicsFuture,
      builder: (context, snapshot) {
        final docs = snapshot.data ?? const [];

        if (snapshot.connectionState == ConnectionState.waiting &&
            docs.isEmpty) {
          return _buildLoadingPlaceholder();
        }

        if (docs.isEmpty) {
          return _buildEmptyPlaceholder();
        }

        _syncAutoScroll(docs.length);

        return SizedBox(
          height: 304,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _stopAutoScroll();
              } else if (notification is ScrollEndNotification) {
                _syncAutoScroll(docs.length);
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: docs.length > 1 ? null : 1,
              onPageChanged: (value) => _currentPage = value,
              itemBuilder: (context, index) {
                final clinicDoc = docs[index % docs.length];
                final clinicData = clinicDoc.data();
                final clinic = ClinicModel.fromFirestore(clinicDoc);
                final doctorName = clinic.doctorName.trim();
                final clinicName = clinic.department.arabicName.trim().isEmpty
                    ? 'عيادة مميزة'
                    : clinic.department.arabicName.trim();
                final about = clinic.about.trim();
                final specialtyLabel = clinic.specialization.isNotEmpty
                    ? clinic.specialization.first.trim()
                    : '';
                final imageUrl = (clinic.doctorImageUrl ?? '').trim();

                final discountPercentage = _extractNumeric(clinicData, const [
                  'discountPercentage',
                  'offerDiscount',
                  'discount',
                ]);
                final offerPrice = _extractNumeric(clinicData, const [
                  'offerPrice',
                  'newPrice',
                  'consultationOfferFee',
                ]);
                final hasSpecialOffer =
                    (discountPercentage != null && discountPercentage > 0) ||
                    (offerPrice != null && offerPrice > 0);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClinicDetailsScreen(clinic: clinic),
                          ),
                        );
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.merge(
                            Border(
                              right: BorderSide(color: Colors.teal, width: 0.5),
                            ),
                            Border(
                              bottom: BorderSide(
                                color: Colors.teal,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                  child: Container(
                                    height: 154,
                                    width: double.infinity,
                                    color: const Color(0xFFE2E8F0),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }

                                              return Container(
                                                color: const Color(0xFFE2E8F0),
                                                child: Center(
                                                  child: AppLoadingIndicator(
                                                    value:
                                                        loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                        : null,
                                                    strokeWidth: 2.4,
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                          Color
                                                        >(Color(0xFF0E7490)),
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (_, __, ___) =>
                                                _clinicImagePlaceholder(),
                                          )
                                        : _clinicImagePlaceholder(),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFDC2626),
                                          Color(0xFFEA580C),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      hasSpecialOffer
                                          ? 'عرض مميز'
                                          : 'دكتور اليوم',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctorName.isEmpty
                                        ? 'دكتور متاح'
                                        : doctorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    specialtyLabel.isEmpty
                                        ? clinicName
                                        : '$clinicName - $specialtyLabel',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0E7490),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (about.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      about,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF0B7285),
                                            Color(0xFF0891B2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'احجز الآن',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: 304,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: double.infinity,
              height: 154,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            SizedBox(height: 12),
            SkeletonBox(width: 170, height: 14),
            SizedBox(height: 8),
            SkeletonBox(width: 140, height: 13),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 11),
            SizedBox(height: 14),
            SkeletonBox(
              width: 92,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      height: 304,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(
        child: Text(
          'ستظهر العيادات المميزة هنا..',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HomePharmacyOffersPreview extends StatelessWidget {
  const _HomePharmacyOffersPreview();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];

        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final firstTwo = docs.take(2).toList();

        return Row(
          children: List.generate(firstTwo.length, (index) {
            final data = firstTwo[index].data();
            final title = (data['title']?.toString() ?? 'عرض صيدلية').trim();
            final category = (data['category']?.toString() ?? 'منتجات طبية')
                .trim();
            final discount = (data['discountPercentage'] is num)
                ? (data['discountPercentage'] as num).toDouble()
                : null;
            final oldPrice = _extractPrice(data, [
              'oldPrice',
              'priceBefore',
              'beforePrice',
              'listPrice',
            ]);
            final newPrice = _extractPrice(data, [
              'newPrice',
              'priceAfter',
              'afterPrice',
              'price',
              'offerPrice',
            ]);
            final images = (data['images'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList();
            final imageUrl = images.isNotEmpty
                ? images.first
                : (data['imageUrl']?.toString() ?? '').trim();

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 8 : 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllOffersScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 112,
                              width: double.infinity,
                              color: const Color(0xFFCFD8DC),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, fit: BoxFit.cover)
                                  : const Icon(
                                      Icons.medication_rounded,
                                      color: Color(0xFF0B7285),
                                      size: 32,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.isEmpty ? 'منتجات طبية' : category,
                            style: const TextStyle(
                              color: Color(0xFF0F766E),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 18 / 1.5,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (newPrice != null)
                            Row(
                              children: [
                                if (oldPrice != null && oldPrice > newPrice)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      'ج.م ${oldPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Text(
                                  'ج.م ${newPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFF0B7285),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              discount == null
                                  ? 'عرض متاح الآن'
                                  : 'خصم ${discount.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Color(0xFF0B7285),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double? _extractPrice(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw is num) {
        return raw.toDouble();
      }
      if (raw is String) {
        final normalized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
        final parsed = double.tryParse(normalized);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}

enum _SearchEntityType {
  pharmacy,
  clinic,
  laboratory,
  radiology,
  gym,
}

class _HomeSearchResult {
  final String id;
  final _SearchEntityType type;
  final String displayType;
  final String title;
  final String subtitle;

  const _HomeSearchResult({
    required this.id,
    required this.type,
    required this.displayType,
    required this.title,
    required this.subtitle,
  });
}

class _QuickActionChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.title,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavPill({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 28, 127, 145),
                      Color(0xFF0B7285),
                    ],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
