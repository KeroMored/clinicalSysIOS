import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/booking_model.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class BookingsHistoryScreen extends StatefulWidget {
  final String clinicId;

  const BookingsHistoryScreen({super.key, required this.clinicId});

  @override
  State<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);

  DateTime? _selectedMonth;
  DateTime? _selectedDate;

  // Pagination variables with ValueNotifier (no page rebuild)
  final ValueNotifier<int> _displayCountMonths = ValueNotifier<int>(10);
  final ValueNotifier<int> _displayCountDays = ValueNotifier<int>(10);
  final ValueNotifier<int> _displayCountBookings = ValueNotifier<int>(10);
  bool _isLoadingMonths = false;
  bool _isLoadingDays = false;
  bool _isLoadingBookings = false;

  // Scroll controllers
  final ScrollController _monthsScrollController = ScrollController();
  final ScrollController _daysScrollController = ScrollController();
  final ScrollController _bookingsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _monthsScrollController.addListener(_onMonthsScroll);
    _daysScrollController.addListener(_onDaysScroll);
    _bookingsScrollController.addListener(_onBookingsScroll);
  }

  @override
  void dispose() {
    _monthsScrollController.dispose();
    _daysScrollController.dispose();
    _bookingsScrollController.dispose();
    _displayCountMonths.dispose();
    _displayCountDays.dispose();
    _displayCountBookings.dispose();
    super.dispose();
  }

  void _onMonthsScroll() {
    if (_monthsScrollController.position.pixels >=
            _monthsScrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMonths) {
      _loadMoreMonths();
    }
  }

  void _onDaysScroll() {
    if (_daysScrollController.position.pixels >=
            _daysScrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingDays) {
      _loadMoreDays();
    }
  }

  void _onBookingsScroll() {
    if (_bookingsScrollController.position.pixels >=
            _bookingsScrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingBookings) {
      _loadMoreBookings();
    }
  }

  Future<void> _loadMoreMonths() async {
    if (_isLoadingMonths) return;
    _isLoadingMonths = true;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _displayCountMonths.value += 10;
      _isLoadingMonths = false;
    }
  }

  Future<void> _loadMoreDays() async {
    if (_isLoadingDays) return;
    _isLoadingDays = true;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _displayCountDays.value += 10;
      _isLoadingDays = false;
    }
  }

  Future<void> _loadMoreBookings() async {
    if (_isLoadingBookings) return;
    _isLoadingBookings = true;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _displayCountBookings.value += 10;
      _isLoadingBookings = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedDate == null && _selectedMonth == null,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (_selectedDate != null) {
            setState(() {
              _selectedDate = null;
            });
          } else if (_selectedMonth != null) {
            setState(() {
              _selectedMonth = null;
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'الأرشيف',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textPrimary,
              size: 18,
            ),
            onPressed: () {
              if (_selectedDate != null) {
                setState(() {
                  _selectedDate = null;
                });
              } else if (_selectedMonth != null) {
                setState(() {
                  _selectedMonth = null;
                });
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: Container(
          color: _backgroundColor,
          child: _selectedDate != null
              ? _buildDayDetailsView()
              : _selectedMonth != null
              ? _buildMonthDaysView()
              : _buildMonthsListView(),
        ),
      ),
    );
  }

  // المستوى 1: عرض الأشهر
  Widget _buildMonthsListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clinicId', isEqualTo: widget.clinicId)
          .where('archivedDate', isNull: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitPulsingGrid(color: _primaryColor, size: 42),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 100, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'لا يوجد سجل حجوزات',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // تجميع الحجوزات حسب الشهر
        final Map<String, List<BookingModel>> bookingsByMonth = {};
        for (var doc in snapshot.data!.docs) {
          final booking = BookingModel.fromFirestore(doc);
          if (booking.archivedDate != null) {
            final monthKey = DateFormat(
              'yyyy-MM',
            ).format(booking.archivedDate!);
            bookingsByMonth.putIfAbsent(monthKey, () => []);
            bookingsByMonth[monthKey]!.add(booking);
          }
        }

        final sortedMonths = bookingsByMonth.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ValueListenableBuilder<int>(
          valueListenable: _displayCountMonths,
          builder: (context, displayCount, child) {
            final displayedMonths = sortedMonths.take(displayCount).toList();
            final hasMore = sortedMonths.length > displayCount;

            return ListView.builder(
              controller: _monthsScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: displayedMonths.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == displayedMonths.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const AppLoadingIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _primaryColor,
                        ),
                      ),
                    ),
                  );
                }

                final monthKey = displayedMonths[index];
                final bookings = bookingsByMonth[monthKey]!;
                final date = DateTime.parse('$monthKey-01');

                return _MonthCard(
                  date: date,
                  bookings: bookings,
                  onTap: () {
                    setState(() {
                      _selectedMonth = date;
                      _displayCountDays.value = 10;
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // المستوى 2: عرض أيام الشهر المحدد + تحليلات الشهر
  Widget _buildMonthDaysView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clinicId', isEqualTo: widget.clinicId)
          .where(
            'archivedDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(_selectedMonth!.year, _selectedMonth!.month, 1),
            ),
          )
          .where(
            'archivedDate',
            isLessThan: Timestamp.fromDate(
              DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 1),
            ),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitPulsingGrid(color: _primaryColor, size: 42),
          );
        }

        final bookings = snapshot.hasData
            ? snapshot.data!.docs
                  .map((doc) => BookingModel.fromFirestore(doc))
                  .toList()
            : <BookingModel>[];

        // تجميع الحجوزات حسب اليوم
        final Map<String, List<BookingModel>> bookingsByDay = {};
        for (var booking in bookings) {
          if (booking.archivedDate != null) {
            final dayKey = DateFormat(
              'yyyy-MM-dd',
            ).format(booking.archivedDate!);
            bookingsByDay.putIfAbsent(dayKey, () => []);
            bookingsByDay[dayKey]!.add(booking);
          }
        }

        final sortedDays = bookingsByDay.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ValueListenableBuilder<int>(
          valueListenable: _displayCountDays,
          builder: (context, displayCount, child) {
            final displayedDays = sortedDays.take(displayCount).toList();
            final hasMoreDays = sortedDays.length > displayCount;

            return CustomScrollView(
              controller: _daysScrollController,
              slivers: [
                // تحليلات الشهر
                SliverToBoxAdapter(
                  child: _MonthAnalytics(
                    bookings: bookings,
                    selectedMonth: _selectedMonth!,
                  ),
                ),

                // قائمة الأيام
                sortedDays.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد حجوزات في هذا الشهر',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == displayedDays.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: const AppLoadingIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _primaryColor,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final dayKey = displayedDays[index];
                              final dayBookings = bookingsByDay[dayKey]!;
                              final date = DateTime.parse(dayKey);

                              return _DayCard(
                                date: date,
                                bookings: dayBookings,
                                onTap: () => setState(() {
                                  _selectedDate = date;
                                  _displayCountBookings.value = 10;
                                }),
                              );
                            },
                            childCount:
                                displayedDays.length + (hasMoreDays ? 1 : 0),
                          ),
                        ),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  // المستوى 3: عرض حجوزات اليوم + تحليلات اليوم
  Widget _buildDayDetailsView() {
    final startOfDay = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    final endOfDay = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      23,
      59,
      59,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clinicId', isEqualTo: widget.clinicId)
          .where(
            'archivedDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'archivedDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .orderBy('archivedDate')
          .orderBy('bookingNumber')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitPulsingGrid(color: _primaryColor, size: 42),
          );
        }

        final bookings = snapshot.hasData
            ? snapshot.data!.docs
                  .map((doc) => BookingModel.fromFirestore(doc))
                  .toList()
            : <BookingModel>[];

        return ValueListenableBuilder<int>(
          valueListenable: _displayCountBookings,
          builder: (context, displayCount, child) {
            final displayedBookings = bookings.take(displayCount).toList();
            final hasMoreBookings = bookings.length > displayCount;

            return CustomScrollView(
              controller: _bookingsScrollController,
              slivers: [
                // تحليلات اليوم
                SliverToBoxAdapter(
                  child: _DayAnalytics(
                    bookings: bookings,
                    selectedDate: _selectedDate!,
                  ),
                ),

                // قائمة الحجوزات
                bookings.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد حجوزات في هذا اليوم',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == displayedBookings.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: const AppLoadingIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _primaryColor,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return _BookingCard(
                                booking: displayedBookings[index],
                              );
                            },
                            childCount:
                                displayedBookings.length +
                                (hasMoreBookings ? 1 : 0),
                          ),
                        ),
                      ),
              ],
            );
          },
        );
      },
    );
  }
}

// Widget لكارد الشهر
class _MonthCard extends StatelessWidget {
  final DateTime date;
  final List<BookingModel> bookings;
  final VoidCallback onTap;

  const _MonthCard({
    required this.date,
    required this.bookings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDDE7EF)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // أيقونة الشهر
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B8293), Color(0xFF179AAC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B8293).withOpacity(0.24),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // معلومات الشهر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'ar').format(date),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark_rounded,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${bookings.length} حجز',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // سهم للإشارة للنقر
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget لعرض إحصائية صغيرة
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

// Widget لكارد اليوم
class _DayCard extends StatelessWidget {
  final DateTime date;
  final List<BookingModel> bookings;
  final VoidCallback onTap;

  const _DayCard({
    required this.date,
    required this.bookings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = bookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final cancelled = bookings
        .where((b) => b.status == BookingStatus.cancelled)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDDE7EF)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B8293).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF0B8293),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE', 'ar').format(date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('d MMMM', 'ar').format(date),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${bookings.length} حجز',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0B8293),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (completed > 0) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$completed',
                            style: TextStyle(fontSize: 13, color: Colors.green),
                          ),
                        ],
                        if (cancelled > 0) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Icon(Icons.cancel, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '$cancelled',
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// تحليلات الشهر - مبهرة وشاملة
class _MonthAnalytics extends StatelessWidget {
  final List<BookingModel> bookings;
  final DateTime selectedMonth;

  const _MonthAnalytics({required this.bookings, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final total = bookings.length;
    final completed = bookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final cancelled = bookings
        .where((b) => b.status == BookingStatus.cancelled)
        .length;

    // حساب عدد الكشف والإعادة
    final examination = bookings
        .where((b) => b.visitType == VisitType.examination)
        .length;
    final followUp = bookings
        .where((b) => b.visitType == VisitType.followUp)
        .length;

    // حساب عدد أيام العمل
    final uniqueDays = bookings
        .where((b) => b.archivedDate != null)
        .map((b) => DateFormat('yyyy-MM-dd').format(b.archivedDate!))
        .toSet()
        .length;

    // متوسط الحجوزات المكتملة (تم الكشف) لكل يوم عمل
    final avgPerDay = uniqueDays > 0
        ? (completed / uniqueDays).toStringAsFixed(1)
        : '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B8293), Color(0xFF179AAC)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'تحليلات شهر ${DateFormat('MMMM yyyy', 'ar').format(selectedMonth)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // الصف الأول: إجمالي الحجوزات
                _AnalyticsCard(
                  icon: Icons.bookmark_rounded,
                  title: 'إجمالي الحجوزات',

                  value: total.toString(),
                  color: const Color(0xFF0B8293),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B8293), Color(0xFF179AAC)],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.medical_services,
                        title: 'كشف',
                        value: examination.toString(),
                        color: Colors.blue,
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blue.shade700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.history,
                        title: 'إعادة',
                        value: followUp.toString(),
                        color: Colors.purple,
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.purple.shade700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // الصف الثاني: الإحصائيات الرئيسية
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.task_alt_rounded,
                        title: 'تم',
                        value: completed.toString(),
                        // subtitle: '$completionRate%',
                        color: Colors.green,
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.cancel_rounded,
                        title: 'ملغي',
                        value: cancelled.toString(),
                        // subtitle: '$cancellationRate%',
                        color: Colors.red,
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.red.shade700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // الصف الثالث: أنواع الزيارات

                // الصف الرابع: متوسطات
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'أيام العمل',
                        value: uniqueDays.toString(),
                        color: Colors.teal,
                        gradient: LinearGradient(
                          colors: [Colors.teal, Colors.teal.shade700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.trending_up_rounded,
                        title: 'متوسط/يوم',
                        value: avgPerDay,
                        color: Colors.teal,
                        gradient: LinearGradient(
                          colors: [Colors.teal, Colors.teal.shade700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// تحليلات اليوم - مفصلة ومفيدة
class _DayAnalytics extends StatelessWidget {
  final List<BookingModel> bookings;
  final DateTime selectedDate;

  const _DayAnalytics({required this.bookings, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final total = bookings.length;
    final completed = bookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final cancelled = bookings
        .where((b) => b.status == BookingStatus.cancelled)
        .length;

    // حساب عدد الكشف والإعادة
    final examination = bookings
        .where((b) => b.visitType == VisitType.examination)
        .length;
    final followUp = bookings
        .where((b) => b.visitType == VisitType.followUp)
        .length;

    final completionRate = total > 0
        ? (completed / total * 100).toStringAsFixed(1)
        : '0';
    final cancellationRate = total > 0
        ? (cancelled / total * 100).toStringAsFixed(1)
        : '0';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B8293), Color(0xFF179AAC)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assessment_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'ملخص يوم ${DateFormat('d MMMM yyyy', 'ar').format(selectedDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CompactStatCard(
                        icon: Icons.bookmark,
                        label: 'الإجمالي',
                        value: total.toString(),
                        color: const Color(0xFF0B8293),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CompactStatCard(
                        icon: Icons.task_alt,
                        label: 'تم الكشف',
                        value: completed.toString(),
                        color: Colors.green,
                        percentage: completionRate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CompactStatCard(
                        icon: Icons.cancel,
                        label: 'ملغي',
                        value: cancelled.toString(),
                        color: Colors.red,
                        percentage: cancellationRate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CompactStatCard(
                        icon: Icons.medical_services,
                        label: 'كشف',
                        value: examination.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CompactStatCard(
                        icon: Icons.history,
                        label: 'إعادة',
                        value: followUp.toString(),
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// كارد تحليلات مع تدرج لوني
class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Gradient gradient;

  const _AnalyticsCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// كارد إحصائيات مدمج
class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? percentage;

  const _CompactStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          if (percentage != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// كارد الحجز
class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  String _formatWhatsAppNumber(String phoneNumber) {
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = phoneNumber.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return '20$n';
    // ضيف +20 قدام الرقم
    return '20$n';
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
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

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final String formattedNumber = _formatWhatsAppNumber(phoneNumber);
    final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNumber');
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

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (booking.status) {
      case BookingStatus.confirmed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case BookingStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case BookingStatus.completed:
        statusColor = Colors.blue;
        statusIcon = Icons.task_alt_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDDE7EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B8293).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0B8293),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'رقم ${booking.bookingNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B8293),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        booking.statusArabic,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: booking.visitType == VisitType.examination
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: booking.visitType == VisitType.examination
                          ? Colors.blue
                          : Colors.purple,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        booking.visitType == VisitType.examination
                            ? Icons.medical_services
                            : Icons.history,
                        size: 14,
                        color: booking.visitType == VisitType.examination
                            ? Colors.blue
                            : Colors.purple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.visitTypeArabic,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: booking.visitType == VisitType.examination
                              ? Colors.blue
                              : Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.person_rounded, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.patientName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_rounded, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.patientPhone,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                if (booking.patientPhone != 'غير محدد') ...[
                  IconButton(
                    onPressed: () =>
                        _makePhoneCall(context, booking.patientPhone),
                    icon: const Icon(
                      Icons.phone,
                      color: Colors.indigoAccent,
                      size: 20,
                    ),
                    tooltip: 'اتصال',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () =>
                        _openWhatsApp(context, booking.patientPhone),
                    icon: Icon(
                      Icons.chat,
                      color: Colors.green,
                      size: 20,
                    ),
                    tooltip: 'واتساب',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
