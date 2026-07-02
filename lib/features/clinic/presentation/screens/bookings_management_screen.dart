import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/clinic_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/services/booking_block_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/patient_cubit.dart';
import 'patient_details_screen.dart';
import 'add_booking_screen.dart';
import 'bookings_history_screen.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class BookingsManagementScreen extends StatefulWidget {
  final ClinicModel clinic;

  const BookingsManagementScreen({super.key, required this.clinic});

  @override
  State<BookingsManagementScreen> createState() =>
      _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);
  DateTime? _localBookingLockDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _localBookingLockDate = widget.clinic.bookingLockDate;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isBookingLocked() {
    final lockDate = _localBookingLockDate;
    if (lockDate == null) return false;
    final now = DateTime.now();
    return lockDate.year == now.year &&
        lockDate.month == now.month &&
        lockDate.day == now.day;
  }

  Future<void> _toggleBookingLock() async {
    final isLocked = _isBookingLocked();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(isLocked ? 'فتح الحجز' : 'قفل الحجز'),
        content: Text(
          isLocked
              ? 'هل تريد السماح بالحجز الاونلاين اليوم؟'
              : "هل تريد غلق الحجز الاونلاين اليوم ؟ ",
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocked ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isLocked ? 'نعم' : 'قفل'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final newLockDate = isLocked ? null : Timestamp.fromDate(DateTime.now());
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinic.id)
          .update({'bookingLockDate': newLockDate});

      setState(() {
        _localBookingLockDate = newLockDate?.toDate();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLocked ? 'تم فتح الحجز' : 'تم قفل الحجز'),
            backgroundColor: isLocked ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _endDay() async {
    // التأكد من وجود حجوزات غير مؤرشفة
    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinic.id)
        .where('archivedDate', isNull: true)
        .get();

    if (bookingsSnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد حجوزات للأرشفة'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // تأكيد العملية
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('إنهاء اليوم'),
        content: Text(
          'سيتم أرشفة ${bookingsSnapshot.docs.length} حجز (بما فيها حجوزات اليوم).\n\nهل أنت متأكد؟',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // أرشفة جميع الحجوزات الحالية
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final appointmentTimestamp = data['appointmentDate'] as Timestamp?;
        final archiveDate = appointmentTimestamp?.toDate() ?? DateTime.now();

        batch.update(doc.reference, {
          'archivedDate': Timestamp.fromDate(archiveDate),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت أرشفة الحجوزات المنتهية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clinicId', isEqualTo: widget.clinic.id)
          .where('archivedDate', isNull: true)
          .snapshots(),
      builder: (context, snapshot) {
        // حساب العدادات من الـ stream
        int pendingCount = 0;
        int confirmedCount = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final status = doc.get('status') as String?;
            if (status == 'pending') {
              pendingCount++;
            } else if (status == 'confirmed') {
              confirmedCount++;
            }
          }
        }

        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            toolbarHeight: 80,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: Material(
                color: Colors.white.withValues(alpha: 0.22),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            title: null,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 8,
                ),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggleBookingLock,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _isBookingLocked()
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _showCalendarView(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _endDay,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.task_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD7E7F1)),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                      ),
                    ),
                    indicatorPadding: const EdgeInsets.all(6),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF5D7183),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    tabs: [
                      _buildTabLabel('مؤكد', confirmedCount),
                      _buildTabLabel('في الانتظار', pendingCount),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEFF8FB), Color(0xFFF7FBFD)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _BookingsListTab(
                  clinic: widget.clinic,
                  status: BookingStatus.confirmed,
                ),
                _BookingsListTab(
                  clinic: widget.clinic,
                  status: BookingStatus.pending,
                ),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.history_rounded,
                  label: 'الأرشيف',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF64748B), Color(0xFF334155)],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BookingsHistoryScreen(clinicId: widget.clinic.id),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.add_rounded,
                  label: 'حجز جديد',
                  gradient: const LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                  ),
                  onPressed: _showAddBookingDialog,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Tab _buildTabLabel(String title, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCalendarView(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _CalendarViewWidget(clinicId: widget.clinic.id),
        ),
      ),
    );
  }

  Future<void> _showAddBookingDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookingScreen(clinic: widget.clinic),
      ),
    );
  }
}

class _BookingsListTab extends StatefulWidget {
  final ClinicModel clinic;
  final BookingStatus status;

  const _BookingsListTab({required this.clinic, required this.status});

  @override
  State<_BookingsListTab> createState() => _BookingsListTabState();
}

class _BookingsListTabState extends State<_BookingsListTab> {
  final ScrollController _scrollController = ScrollController();
  final List<BookingModel> _allBookings = [];
  final int _pageSize = 10;
  int _displayCount = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_displayCount < _allBookings.length && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      // تأخير بسيط لإظهار الـ loading
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _displayCount = (_displayCount + _pageSize).clamp(
              0,
              _allBookings.length,
            );
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  // دالة لترتيب الحجوزات: المؤكدة أولاً ثم المكتملة
  List<BookingModel> _sortBookings(List<BookingModel> bookings) {
    final sorted = List<BookingModel>.from(bookings);
    sorted.sort((a, b) {
      // الحجوزات المكتملة في الأخير
      if (a.status == BookingStatus.completed &&
          b.status != BookingStatus.completed) {
        return 1;
      }
      if (b.status == BookingStatus.completed &&
          a.status != BookingStatus.completed) {
        return -1;
      }
      // إذا كانت نفس الحالة، رتب حسب التاريخ (الأقدم أولاً)
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clinicId', isEqualTo: widget.clinic.id)
          .where('archivedDate', isNull: true)
          .orderBy('appointmentDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل الحجوزات',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // عرض loading فقط إذا لم تكن هناك بيانات بعد
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: SpinKitPulsingGrid(color: const Color(0xFF06B6D4), size: 50),
          );
        }

        // إذا لم تكن هناك بيانات، عرض قائمة فارغة
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        // فلترة الحجوزات حسب الحالة
        _allBookings.clear();
        _allBookings.addAll(
          snapshot.data!.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .where((booking) {
                if (widget.status == BookingStatus.pending) {
                  return booking.status == BookingStatus.pending;
                } else {
                  return booking.status == BookingStatus.confirmed ||
                      booking.status == BookingStatus.completed;
                }
              })
              .toList(),
        );

        // ترتيب الحجوزات
        final sortedBookings = _sortBookings(_allBookings);

        // الحجوزات المعروضة (pagination)
        final displayedBookings = sortedBookings.take(_displayCount).toList();
        final hasMore = _displayCount < sortedBookings.length;

        if (sortedBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد حجوزات ${widget.status == BookingStatus.pending ? "في الانتظار" : "مؤكدة"}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey('bookings_list'),
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              displayedBookings.length + ((hasMore || _isLoadingMore) ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == displayedBookings.length) {
              // مؤشر "تحميل المزيد" - بسيط
              return _isLoadingMore
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: AppLoadingIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF06B6D4),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }

            final booking = displayedBookings[index];
            return _BookingCard(booking: booking, key: ValueKey(booking.id));
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({super.key, required this.booking});

  // التحقق من أن المستخدم دكتور وليس سكرتيرة
  Future<bool> _isDoctorUser(BuildContext context) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) return false;

      final userEmail = authState.user.email;

      // الحصول على بيانات العيادة للتحقق
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .where('authEmails', arrayContains: userEmail)
          .limit(1)
          .get();

      if (clinicDoc.docs.isEmpty) return false;

      final clinicData = clinicDoc.docs.first.data();

      // التحقق من أن المستخدم ليس سكرتير
      final secretaryEmails = clinicData['secretaryEmails'] != null
          ? List<String>.from(clinicData['secretaryEmails'])
          : <String>[];

      // إذا كان في قائمة السكرتيرة، فهو ليس دكتور
      if (secretaryEmails.contains(userEmail)) {
        return false;
      }

      // إذا كان لديه صلاحية الدخول وليس سكرتير، فهو دكتور
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == BookingStatus.pending;
    final isCompleted = booking.status == BookingStatus.completed;
    final isCancelled = booking.status == BookingStatus.cancelled;
    final isNoShow = booking.status == BookingStatus.noShow;
    final isArchived = booking.archivedDate != null;

    final Color statusColor = isCancelled
        ? const Color(0xFFDC2626)
        : isCompleted
        ? const Color(0xFFE5E7EB)
        : isNoShow
        ? const Color(0xFFDC2626)
        : isPending
        ? const Color(0xFFF59E0B)
        : const Color(0xFF059669);

    final IconData statusIcon = isCancelled
        ? Icons.cancel_rounded
        : isCompleted
        ? Icons.task_alt_rounded
        : isNoShow
        ? Icons.person_off_rounded
        : isPending
        ? Icons.pending_rounded
        : Icons.check_circle_rounded;

    final bool showOnlyConfirmedDate =
        booking.confirmedAt != null &&
        _isSameDateTimeMinute(booking.createdAt, booking.confirmedAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isCompleted ? const Color(0xFFE5E7EB) : Colors.white,
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFCBD5E1)
              : const Color(0xFFDDE7EF),
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? const Color(0xFF475569).withValues(alpha: 0.22)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: isCompleted ? 10 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isNoShow
                    ? const Color(0xFFFFF5F5)
                    : isCompleted
                    ? const Color(0xFFE5E7EB)
                    : Colors.white,
                border: Border.all(
                  color: isNoShow
                      ? const Color(0xFFDC2626).withValues(alpha: 0.3)
                      : isCompleted
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFDDE7EF),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'رقم الحجز #${booking.bookingNumber}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildTag(
                                  icon: statusIcon,
                                  text: booking.statusArabic,
                                  color: statusColor,
                                ),
                                _buildTag(
                                  icon:
                                      booking.visitType == VisitType.examination
                                      ? Icons.medical_services_rounded
                                      : Icons.replay_circle_filled_rounded,
                                  text: booking.visitTypeArabic,
                                  color:
                                      booking.visitType == VisitType.examination
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF7C3AED),
                                ),
                                if (isArchived)
                                  _buildTag(
                                    icon: Icons.archive_rounded,
                                    text: 'مؤرشف',
                                    color: const Color(0xFF0D9488),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          if (isPending)
                            IconButton(
                              icon: const Icon(
                                Icons.task_alt_rounded,
                                color: Color(0xFF059669),
                              ),
                              onPressed: () => _confirmBooking(context),
                            ),
                          const SizedBox(height: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              color: Color(0xFF334155),
                            ),
                            onPressed: () => _showOptions(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: _isDoctorUser(context),
                    builder: (context, snapshot) {
                      final isDoctor = snapshot.data ?? false;

                      return InkWell(
                        onTap: isDoctor
                            ? () => _searchAndOpenPatient(context)
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDE7EF)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF0B8293),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'اسم المريض',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      booking.patientName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDoctor
                                            ? const Color(0xFF0B8293)
                                            : const Color(0xFF0F172A),
                                        decoration: isDoctor
                                            ? TextDecoration.underline
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isDoctor)
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (showOnlyConfirmedDate)
                    _buildInfoRow(
                      Icons.verified_rounded,
                      'تاريخ التأكيد',
                      _formatDateTime(booking.confirmedAt!),
                    )
                  else
                    _buildInfoRow(
                      Icons.access_time_filled_rounded,
                      'تاريخ الحجز',
                      _formatDateTime(booking.createdAt),
                    ),
                  if (!showOnlyConfirmedDate &&
                      booking.confirmedAt != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.verified_rounded,
                      'تاريخ التأكيد',
                      _formatDateTime(booking.confirmedAt!),
                    ),
                  ],
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.sticky_note_2_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.notes!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isCompleted)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(painter: _CompletedCardStrikePainter()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2ECF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF0B8293)),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDateTimeMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // دالة للبحث عن المريض بشكل ذكي وفتح صفحته
  void _searchAndOpenPatient(BuildContext context) async {
    // إظهار loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLoadingIndicator(),
                SizedBox(height: 16),
                Text('جاري البحث عن المريض...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      List<QueryDocumentSnapshot> foundPatients = [];

      // 1. البحث برقم الهاتف أولاً (إذا كان موجود وليس "غير محدد")
      if (booking.patientPhone.isNotEmpty &&
          booking.patientPhone != 'غير محدد' &&
          booking.patientPhone != 'لا يوجد') {
        String cleanPhone = booking.patientPhone.replaceAll(
          RegExp(r'[^0-9+]'),
          '',
        );

        final phoneQuery = await FirebaseFirestore.instance
            .collection('patients')
            .where('clinicId', isEqualTo: booking.clinicId)
            .where('phoneNumber', isEqualTo: cleanPhone)
            .get();

        foundPatients.addAll(phoneQuery.docs);
      }

      // 2. إذا لم نجد برقم الهاتف، نبحث بالاسم
      if (foundPatients.isEmpty) {
        // تنظيف الاسم من المسافات الزائدة
        String cleanName = booking.patientName.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );

        // البحث بالاسم الكامل
        final exactNameQuery = await FirebaseFirestore.instance
            .collection('patients')
            .where('clinicId', isEqualTo: booking.clinicId)
            .where('name', isEqualTo: cleanName)
            .get();

        foundPatients.addAll(exactNameQuery.docs);

        // 3. إذا لم نجد بالاسم الكامل، نبحث بالتشابه
        if (foundPatients.isEmpty) {
          // جلب كل المرضى في العيادة للبحث المتقدم
          final allPatientsQuery = await FirebaseFirestore.instance
              .collection('patients')
              .where('clinicId', isEqualTo: booking.clinicId)
              .get();

          // البحث بالتشابه
          for (var doc in allPatientsQuery.docs) {
            String patientName = doc.get('name') as String;
            if (_areNamesSimilar(cleanName, patientName)) {
              foundPatients.add(doc);
            }
          }
        }
      }

      if (context.mounted) {
        Navigator.pop(context); // إغلاق loading

        if (foundPatients.isEmpty) {
          // لم يتم العثور على أي مريض
          _showCreatePatientDialog(context);
        } else if (foundPatients.length == 1) {
          // وجدنا مريض واحد فقط
          _navigateToPatientDetails(context, foundPatients.first.id);
        } else {
          // وجدنا عدة مرضى - نعرض قائمة للاختيار
          _showPatientsSelectionDialog(context, foundPatients);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // إغلاق loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // دالة للمقارنة بين اسمين بذكاء
  bool _areNamesSimilar(String name1, String name2) {
    // تنظيف الأسماء
    name1 = _normalizeName(name1);
    name2 = _normalizeName(name2);

    // إذا كانا متطابقين تماماً
    if (name1 == name2) return true;

    // تقسيم الأسماء إلى كلمات
    List<String> words1 = name1.split(' ');
    List<String> words2 = name2.split(' ');

    // حالة خاصة: أحد الاسمين يحتوي على الآخر بالكامل
    // مثال: "محمد أحمد" و "محمد أحمد علي"
    // نتحقق إن الاسم الأقصر موجود بالكامل في بداية الاسم الأطول
    if (words1.length != words2.length) {
      List<String> shorterWords = words1.length < words2.length
          ? words1
          : words2;
      List<String> longerWords = words1.length < words2.length
          ? words2
          : words1;

      bool allMatch = true;
      for (int i = 0; i < shorterWords.length; i++) {
        if (i >= longerWords.length || shorterWords[i] != longerWords[i]) {
          allMatch = false;
          break;
        }
      }

      // إذا كل كلمات الاسم الأقصر موجودة في بداية الاسم الأطول
      if (allMatch) return true;
    }

    // حساب نسبة التطابق لكل الكلمات (ليس فقط الأولى)
    int matchCount = 0;
    int maxWords = words1.length > words2.length
        ? words1.length
        : words2.length;

    for (int i = 0; i < words1.length && i < words2.length; i++) {
      if (words1[i] == words2[i]) {
        matchCount++;
      }
    }

    // نسبة التطابق يجب تكون 100% (كل الكلمات متطابقة)
    // أو على الأقل 80% وأول اسمين متطابقين
    double similarity = matchCount / maxWords;

    // تشابه كامل أو شبه كامل
    if (similarity == 1.0) return true;

    // تشابه 80% + أول اسمين متطابقين
    if (similarity >= 0.8 &&
        matchCount >= 2 &&
        words1.isNotEmpty &&
        words2.isNotEmpty &&
        words1[0] == words2[0] &&
        (words1.length < 2 || words2.length < 2 || words1[1] == words2[1])) {
      return true;
    }

    return false;
  }

  // دالة لتوحيد صيغة الاسم
  String _normalizeName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll('ى', 'ي') // توحيد الياء
        .replaceAll('ة', 'ه') // توحيد التاء المربوطة
        .replaceAll('أ', 'ا') // توحيد الهمزة
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll(RegExp(r'\s+'), ' '); // توحيد المسافات
  }

  // عرض dialog لاختيار المريض من قائمة
  void _showPatientsSelectionDialog(
    BuildContext context,
    List<QueryDocumentSnapshot> patients,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people_alt, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('اختر المريض', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تم العثور على عدة مرضى متشابهين. اختر المريض المطلوب:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient =
                        patients[index].data() as Map<String, dynamic>;
                    final patientId = patients[index].id;
                    final name = patient['name'] ?? '';
                    final phone = patient['phoneNumber'] ?? 'لا يوجد';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF06B6D4),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '؟',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'رقم الهاتف: $phone',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToPatientDetails(context, patientId);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCreatePatientDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('مريض جديد'),
          ),
        ],
      ),
    );
  }

  // عرض dialog لإنشاء مريض جديد
  void _showCreatePatientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('مريض غير مسجل'),
          ],
        ),
        content: Text(
          'لم يتم العثور على المريض "${booking.patientName}"\n\nهل تريد إضافته إلى قائمة المرضى؟',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addPatientFromBooking(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة مريض'),
          ),
        ],
      ),
    );
  }

  // الانتقال لصفحة تفاصيل المريض
  void _navigateToPatientDetails(BuildContext context, String patientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<PatientCubit>(),
          child: PatientDetailsScreen(
            patientId: patientId,
            clinicId: booking.clinicId,
          ),
        ),
      ),
    );
  }

  // دالة لإضافة مريض من بيانات الحجز
  void _addPatientFromBooking(BuildContext context) async {
    try {
      // إضافة المريض مباشرة من بيانات الحجز
      await context.read<PatientCubit>().addPatient(
        clinicId: booking.clinicId,
        name: booking.patientName,
        phoneNumber: booking.patientPhone,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المريض بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إضافة المريض: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmBooking(BuildContext context) async {
    if (booking.id == null || booking.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id!)
          .update({'status': 'confirmed', 'confirmedAt': Timestamp.now()});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تأكيد الحجز بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOptions(BuildContext context) {
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final isCompleted = booking.status == BookingStatus.completed;
    final isCancelled = booking.status == BookingStatus.cancelled;

    // حفظ الـ context الأصلي
    final originalContext = context;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // تعديل الحجز (يظهر للحجوزات غير المكتملة والملغية)
            // "تم الكشف" يظهر فقط للحجوزات المؤكدة
            if (isConfirmed)
              ListTile(
                leading: const Icon(Icons.task_alt_rounded, color: Colors.blue),
                title: const Text('تم الكشف'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsCompleted(originalContext);
                },
              ),
            // "لم يحضر" يظهر للحجوزات المؤكدة وفي الانتظار
            if (isConfirmed || !isCancelled)
              ListTile(
                leading: const Icon(
                  Icons.person_off_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text('لم يحضر'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsNoShow(originalContext);
                },
              ),
            // "لم يتم الكشف" يظهر فقط للحجوزات المكتملة
            if (isCompleted)
              ListTile(
                leading: const Icon(Icons.undo_rounded, color: Colors.orange),
                title: const Text('لم يتم الكشف'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsNotCompleted(originalContext);
                },
              ),
            // "إلغاء الحجز" يظهر للحجوزات غير الملغية
            if (!isCancelled)
              ListTile(
                leading: const Icon(Icons.cancel_rounded, color: Colors.red),
                title: const Text('إلغاء الحجز'),
                onTap: () {
                  Navigator.pop(context);
                  _cancelBooking(originalContext);
                },
              ),

            if (!isCompleted && !isCancelled)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('تعديل الحجز'),
                onTap: () {
                  Navigator.pop(context);
                  _editBooking(originalContext);
                },
              ),

            const Divider(),
            // زر الاتصال
            if (booking.patientPhone.isNotEmpty &&
                booking.patientPhone != 'غير محدد' &&
                booking.patientPhone != 'لا يوجد')
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.blue),
                title: const Text('اتصال'),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(originalContext);
                },
              ),
            // زر الواتساب
            if (booking.patientPhone.isNotEmpty &&
                booking.patientPhone != 'غير محدد' &&
                booking.patientPhone != 'لا يوجد')
              ListTile(
                leading: Icon(Icons.chat, color: Colors.green),
                title: const Text('واتساب'),
                onTap: () {
                  Navigator.pop(context);
                  _openWhatsApp(originalContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _markAsNotCompleted(BuildContext context) async {
    if (booking.id == null || booking.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id!)
          .update({'status': 'confirmed'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرجاع الحجز لحالة مؤكد'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelBooking(BuildContext context) async {
    if (booking.id == null || booking.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // تأكيد الإلغاء
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('تأكيد الإلغاء'),
          ],
        ),
        content: Text(
          'هل تريد إلغاء الحجز رقم ${booking.bookingNumber}؟\n\nسيتم تحويل الحجز إلى حالة ملغي.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('إلغاء الحجز'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id!)
          .update({'status': 'cancelled', 'cancelledAt': Timestamp.now()});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الحجز'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _markAsCompleted(BuildContext context) async {
    if (booking.id == null || booking.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id!)
          .update({'status': 'completed'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الكشف بنجاح'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _markAsNoShow(BuildContext context) async {
    if (booking.id == null || booking.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: معرف الحجز غير موجود'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل عدم الحضور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد تسجيل "${booking.patientName}" كـ لم يحضر؟'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                '⚠️ في حالة تكرار عدم الحضور 3 مرات سيتم منع المريض من الحجز لمدة 30 يوم',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(booking.id!)
                    .update({'status': 'noShow'});

                await BookingBlockService().recordNoShow(
                  patientPhone: booking.patientPhone,
                  patientName: booking.patientName,
                  clinicId: booking.clinicId,
                  bookingId: booking.id!,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تسجيل عدم الحضور'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: booking.patientPhone);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن إجراء المكالمة')));
      }
    }
  }

  String _formatWhatsAppNumber(String phoneNumber) {
    String n = phoneNumber.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return n;
    // ضيف 20 قدام الرقم
    return '20$n';
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final String formattedNumber = _formatWhatsAppNumber(booking.patientPhone);
    final String message =
        '''مرحباً،

نحن عيادة دكتور ${booking.doctorName}
نحب نبلغك بتأكيد الحجز

''';

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$formattedNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب')));
      }
    }
  }

  void _editBooking(BuildContext context) async {
    // الحصول على بيانات العيادة
    final clinicDoc = await FirebaseFirestore.instance
        .collection('clinics')
        .doc(booking.clinicId)
        .get();

    if (!clinicDoc.exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: لم يتم العثور على بيانات العيادة'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final clinic = ClinicModel.fromFirestore(clinicDoc);

    if (context.mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AddBookingScreen(clinic: clinic, booking: booking),
        ),
      );

      if (result == true && context.mounted) {
        // تم التعديل بنجاح
      }
    }
  }
}

class _CompletedCardStrikePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mainStrike = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.45)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final softStrike = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final start = Offset(size.width * 0.05, size.height * 0.18);
    final end = Offset(size.width * 0.95, size.height * 0.82);

    canvas.drawLine(start, end, mainStrike);
    canvas.drawLine(
      Offset(start.dx, start.dy + 4),
      Offset(end.dx, end.dy + 4),
      softStrike,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// صفحة عرض حجوزات يوم معين
class _DayBookingsScreen extends StatefulWidget {
  final DateTime date;
  final List<BookingModel> bookings;

  const _DayBookingsScreen({required this.date, required this.bookings});

  @override
  State<_DayBookingsScreen> createState() => _DayBookingsScreenState();
}

class _DayBookingsScreenState extends State<_DayBookingsScreen> {
  late List<BookingModel> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = List.from(widget.bookings);
  }

  /// Check if booking can be edited/deleted (today or future dates only)
  bool _isBookingEditable(BookingModel booking) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(
      booking.appointmentDate.year,
      booking.appointmentDate.month,
      booking.appointmentDate.day,
    );
    return bookingDate.isAfter(today) || bookingDate.isAtSameMomentAs(today);
  }

  /// Format date for notification (today or date string)
  String _formatDateForNotification(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(date.year, date.month, date.day);

    if (bookingDate.isAtSameMomentAs(today)) {
      return 'اليوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Send notification to doctor when secretary deletes booking
  Future<void> _sendDeletionNotification(BookingModel booking) async {
    try {
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(booking.clinicId)
          .get();

      if (!clinicDoc.exists) return;

      final clinicData = clinicDoc.data()!;
      final doctorEmails = clinicData['doctorEmails'] != null
          ? List<String>.from(clinicData['doctorEmails'])
          : <String>[];

      if (doctorEmails.isEmpty) return;

      final dateStr = _formatDateForNotification(booking.appointmentDate);
      final timeStr =
          '${booking.appointmentDate.hour.toString().padLeft(2, '0')}:${booking.appointmentDate.minute.toString().padLeft(2, '0')}';
      final visitTypeArabic = booking.visitType == VisitType.examination
          ? 'كشف'
          : 'إعادة';

      // Create notification document
      await FirebaseFirestore.instance.collection('clinic_notifications').add({
        'clinicId': booking.clinicId,
        'title': 'تم حذف حجز 🗑️',
        'message':
            'السكرتيرة حذفت حجز ${booking.patientName}\n$visitTypeArabic - $dateStr الساعة $timeStr',
        'type': 'booking_deleted',
        'bookingNumber': booking.bookingNumber,
        'patientName': booking.patientName,
        'visitType': visitTypeArabic,
        'appointmentDate': dateStr,
        'appointmentTime': timeStr,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      print('✅ Deletion notification sent to doctors');
    } catch (e) {
      print('❌ Error sending deletion notification: $e');
    }
  }

  Future<void> _deleteBooking(BookingModel booking) async {
    // تأكيد الحذف
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('حذف الحجز', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد من حذف هذا الحجز؟',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'رقم الحجز: ${booking.bookingNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.patientName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'لن يمكن التراجع عن هذا الإجراء.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // حذف من Firestore مباشرة
      if (booking.id != null && booking.id!.isNotEmpty) {
        // Send notification to doctor first
        await _sendDeletionNotification(booking);

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id!)
            .delete();

        // تحديث القائمة المحلية
        setState(() {
          _bookings.removeWhere((b) => b.id == booking.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الحجز بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // إذا لم يتبقى حجوزات، الرجوع للصفحة السابقة
          if (_bookings.isEmpty) {
            Navigator.pop(context);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطأ: معرف الحجز غير صالح'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الحجز: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في فتح تطبيق الهاتف')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'حجوزات ${widget.date.day}/${widget.date.month}/${widget.date.year}',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Container(
        color: const Color(0xFFF3F8FB),
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B8293), Color(0xFF179AAC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B8293).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_note,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إجمالي الحجوزات',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_bookings.length} حجز',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bookings List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  final statusColor = booking.status == BookingStatus.confirmed
                      ? Colors.green
                      : booking.status == BookingStatus.pending
                      ? Colors.orange
                      : booking.status == BookingStatus.completed
                      ? Colors.blue
                      : Colors.red;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _makePhoneCall(booking.patientPhone);
                          // يمكن إضافة عرض تفاصيل الحجز هنا
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // رقم الحجز
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statusColor,
                                      statusColor.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${booking.bookingNumber}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // تفاصيل المريض
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.patientName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      booking.patientPhone,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    // عرض اسم العيادة للحجوزات الأونلاين
                                    if (booking.isOnlineBooking == true &&
                                        booking.doctorName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.medical_services_rounded,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'عيادة د. ${booking.doctorName}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // الحالة
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: statusColor.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            booking.statusArabic,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // الوقت
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF06B6D4,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: Color(0xFF06B6D4),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${booking.appointmentDate.hour.toString().padLeft(2, '0')}:${booking.appointmentDate.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF06B6D4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // زر الحذف - يظهر فقط للحجوزات اليوم والأيام القادمة
                              if (_isBookingEditable(booking))
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => _deleteBooking(booking),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete_rounded,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                    ),
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
          ],
        ),
      ),
    );
  }
}

// Widget للتقويم
class _CalendarViewWidget extends StatefulWidget {
  final String clinicId;

  const _CalendarViewWidget({required this.clinicId});

  @override
  State<_CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<_CalendarViewWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<BookingModel>> _bookingsByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    // تحميل الحجوزات للشهر الحالي والشهر التالي
    final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final endDate = DateTime(
      _focusedDay.year,
      _focusedDay.month + 2,
      0,
      23,
      59,
      59,
    );

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinicId)
        .where(
          'appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          'appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        )
        .get();

    final bookings = snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();

    // تجميع الحجوزات حسب التاريخ
    final Map<DateTime, List<BookingModel>> groupedBookings = {};
    for (var booking in bookings) {
      final date = DateTime(
        booking.appointmentDate.year,
        booking.appointmentDate.month,
        booking.appointmentDate.day,
      );
      if (groupedBookings[date] == null) {
        groupedBookings[date] = [];
      }
      groupedBookings[date]!.add(booking);
    }

    setState(() {
      _bookingsByDate = groupedBookings;
    });
  }

  List<BookingModel> _getBookingsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _bookingsByDate[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            const Icon(
              Icons.calendar_month,
              color: Color(0xFF0B8293),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'التقويم',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B8293),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),

        // التقويم
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: TableCalendar<BookingModel>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            locale: 'ar',
            startingDayOfWeek: StartingDayOfWeek.saturday,
            daysOfWeekHeight: 40,
            rowHeight: 56,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B8293),
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, size: 28),
              rightChevronIcon: const Icon(Icons.chevron_right, size: 28),
              headerPadding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              weekendStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(4),
              defaultTextStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              weekendTextStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                // color: Colors.red[400],
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF0B8293).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFF0B8293),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF0B8293),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              markerSize: 10,
              markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
              markersMaxCount: 1,
              markersAlignment: Alignment.center,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              final bookings = _getBookingsForDay(selectedDay);
              if (bookings.isNotEmpty) {
                _showBookingsScreen(selectedDay, bookings);
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadBookings();
            },
            eventLoader: _getBookingsForDay,
          ),
        ),

        // const SizedBox(height: 16),

        // // مفتاح التوضيح
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //   decoration: BoxDecoration(
        //     color: Colors.red[50],
        //     borderRadius: BorderRadius.circular(10),
        //     border: Border.all(color: Colors.red[200]!, width: 1),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Container(
        //         width: 8,
        //         height: 8,
        //         decoration: const BoxDecoration(
        //           color: Colors.red,
        //           shape: BoxShape.circle,
        //         ),
        //       ),
        //       // const SizedBox(width: 10),
        //       // const Text(
        //       //   'يوم فيه حجوزات',
        //       //   style: TextStyle(
        //       //     fontSize: 14,
        //       //     fontWeight: FontWeight.w500,
        //       //     color: Colors.red,
        //       //   ),
        //       // ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  void _showBookingsScreen(DateTime date, List<BookingModel> bookings) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _DayBookingsScreen(date: date, bookings: bookings),
      ),
    );
  }
}
