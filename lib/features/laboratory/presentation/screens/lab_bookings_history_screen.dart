import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../data/models/lab_booking_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

const Color _labPrimaryColor = Color(0xFF0B8293);
const Color _labTextColor = Color(0xFF0F172A);

PreferredSizeWidget _buildLabAppBar(String title) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0.5,
    centerTitle: true,
    title: Text(
      title,
      style: const TextStyle(
        color: _labTextColor,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    ),
    iconTheme: const IconThemeData(color: _labPrimaryColor),
  );
}

/// شاشة أرشيف الحجوزات - نظام هرمي (سنة → شهر → يوم)
class LabBookingsHistoryScreen extends StatefulWidget {
  final String laboratoryId;

  const LabBookingsHistoryScreen({super.key, required this.laboratoryId});

  @override
  State<LabBookingsHistoryScreen> createState() =>
      _LabBookingsHistoryScreenState();
}

class _LabBookingsHistoryScreenState extends State<LabBookingsHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildLabAppBar('الأرشيف'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF7FB), Color(0xFFF4FAFD), Color(0xFFF8FCFE)],
          ),
        ),
        child: _YearsListView(laboratoryId: widget.laboratoryId),
      ),
    );
  }
}

/// المستوى الأول: عرض السنوات
class _YearsListView extends StatefulWidget {
  final String laboratoryId;

  const _YearsListView({required this.laboratoryId});

  @override
  State<_YearsListView> createState() => _YearsListViewState();
}

class _YearsListViewState extends State<_YearsListView> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _displayCount = ValueNotifier<int>(10);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _displayCount.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _displayCount.value += 10;
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lab_bookings')
          .where('laboratoryId', isEqualTo: widget.laboratoryId)
          .where('archivedDate', isNull: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا يوجد أرشيف',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // تجميع الحجوزات حسب السنة (تاريخ الحجز الأصلي)
        final Map<int, List<LabBookingModel>> bookingsByYear = {};
        for (var doc in snapshot.data!.docs) {
          final booking = LabBookingModel.fromFirestore(doc);
          if (booking.archivedDate != null) {
            final year = booking.createdAt.year;
            bookingsByYear.putIfAbsent(year, () => []);
            bookingsByYear[year]!.add(booking);
          }
        }

        final sortedYears = bookingsByYear.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        if (sortedYears.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا يوجد أرشيف',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: _displayCount,
          builder: (context, displayCount, _) {
            final displayedYears = sortedYears.take(displayCount).toList();
            final hasMore = sortedYears.length > displayCount;

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  displayedYears.length + (hasMore && _isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == displayedYears.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: AppLoadingIndicator(),
                    ),
                  );
                }

                final year = displayedYears[index];
                final bookings = bookingsByYear[year]!;

                return _YearCard(
                  year: year,
                  bookingsCount: bookings.length,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _MonthsScreen(
                          laboratoryId: widget.laboratoryId,
                          year: year,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// بطاقة السنة
class _YearCard extends StatelessWidget {
  final int year;
  final int bookingsCount;
  final VoidCallback onTap;

  const _YearCard({
    required this.year,
    required this.bookingsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.laboratoryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$year',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عام $year',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$bookingsCount حجز',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

/// المستوى الثاني: عرض الشهور لسنة معينة
class _MonthsScreen extends StatefulWidget {
  final String laboratoryId;
  final int year;

  const _MonthsScreen({required this.laboratoryId, required this.year});

  @override
  State<_MonthsScreen> createState() => _MonthsScreenState();
}

class _MonthsScreenState extends State<_MonthsScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _displayCount = ValueNotifier<int>(12);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _displayCount.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _displayCount.value += 12;
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startOfYear = DateTime(widget.year, 1, 1);
    final endOfYear = DateTime(widget.year + 1, 1, 1);

    return Scaffold(
      appBar: _buildLabAppBar('عام ${widget.year}'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF7FB), Color(0xFFF4FAFD), Color(0xFFF8FCFE)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lab_bookings')
              .where('laboratoryId', isEqualTo: widget.laboratoryId)
              .where(
                'archivedDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
              )
              .where('archivedDate', isLessThan: Timestamp.fromDate(endOfYear))
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoadingIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد حجوزات في هذا العام',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // تجميع الحجوزات حسب الشهر (تاريخ الحجز الأصلي)
            final Map<int, List<LabBookingModel>> bookingsByMonth = {};
            for (var doc in snapshot.data!.docs) {
              final booking = LabBookingModel.fromFirestore(doc);
              if (booking.archivedDate != null) {
                final month = booking.createdAt.month;
                bookingsByMonth.putIfAbsent(month, () => []);
                bookingsByMonth[month]!.add(booking);
              }
            }

            final sortedMonths = bookingsByMonth.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            if (sortedMonths.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد حجوزات في هذا العام',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ValueListenableBuilder<int>(
              valueListenable: _displayCount,
              builder: (context, displayCount, _) {
                final displayedMonths = sortedMonths
                    .take(displayCount)
                    .toList();
                final hasMore = sortedMonths.length > displayCount;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      displayedMonths.length + (hasMore && _isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayedMonths.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: AppLoadingIndicator(),
                        ),
                      );
                    }

                    final month = displayedMonths[index];
                    final bookings = bookingsByMonth[month]!;
                    final date = DateTime(widget.year, month, 1);

                    return _MonthCard(
                      date: date,
                      bookingsCount: bookings.length,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _DaysScreen(
                              laboratoryId: widget.laboratoryId,
                              year: widget.year,
                              month: month,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// بطاقة الشهر
class _MonthCard extends StatelessWidget {
  final DateTime date;
  final int bookingsCount;
  final VoidCallback onTap;

  const _MonthCard({
    required this.date,
    required this.bookingsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM', 'ar').format(date);

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.clinicGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${date.month}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$bookingsCount حجز',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

/// المستوى الثالث: عرض الأيام لشهر معين
class _DaysScreen extends StatefulWidget {
  final String laboratoryId;
  final int year;
  final int month;

  const _DaysScreen({
    required this.laboratoryId,
    required this.year,
    required this.month,
  });

  @override
  State<_DaysScreen> createState() => _DaysScreenState();
}

class _DaysScreenState extends State<_DaysScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _displayCount = ValueNotifier<int>(15);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _displayCount.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _displayCount.value += 15;
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startOfMonth = DateTime(widget.year, widget.month, 1);
    final endOfMonth = DateTime(widget.year, widget.month + 1, 1);
    final monthName = DateFormat('MMMM yyyy', 'ar').format(startOfMonth);

    return Scaffold(
      appBar: _buildLabAppBar(monthName),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF7FB), Color(0xFFF4FAFD), Color(0xFFF8FCFE)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lab_bookings')
              .where('laboratoryId', isEqualTo: widget.laboratoryId)
              .where(
                'archivedDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where('archivedDate', isLessThan: Timestamp.fromDate(endOfMonth))
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoadingIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد حجوزات في هذا الشهر',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // تجميع الحجوزات حسب اليوم (تاريخ الحجز الأصلي)
            final Map<int, List<LabBookingModel>> bookingsByDay = {};
            for (var doc in snapshot.data!.docs) {
              final booking = LabBookingModel.fromFirestore(doc);
              if (booking.archivedDate != null) {
                final day = booking.createdAt.day;
                bookingsByDay.putIfAbsent(day, () => []);
                bookingsByDay[day]!.add(booking);
              }
            }

            final sortedDays = bookingsByDay.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            if (sortedDays.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد حجوزات في هذا الشهر',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ValueListenableBuilder<int>(
              valueListenable: _displayCount,
              builder: (context, displayCount, _) {
                final displayedDays = sortedDays.take(displayCount).toList();
                final hasMore = sortedDays.length > displayCount;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      displayedDays.length + (hasMore && _isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayedDays.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: AppLoadingIndicator(),
                        ),
                      );
                    }

                    final day = displayedDays[index];
                    final bookings = bookingsByDay[day]!;
                    final date = DateTime(widget.year, widget.month, day);

                    return _DayCard(
                      date: date,
                      bookingsCount: bookings.length,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _DayBookingsScreen(
                              laboratoryId: widget.laboratoryId,
                              date: date,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// بطاقة اليوم
class _DayCard extends StatelessWidget {
  final DateTime date;
  final int bookingsCount;
  final VoidCallback onTap;

  const _DayCard({
    required this.date,
    required this.bookingsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE', 'ar').format(date);
    final dayDate = DateFormat('d MMMM', 'ar').format(date);

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayDate,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$bookingsCount حجز',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

/// المستوى الرابع: عرض حجوزات يوم معين
class _DayBookingsScreen extends StatefulWidget {
  final String laboratoryId;
  final DateTime date;

  const _DayBookingsScreen({required this.laboratoryId, required this.date});

  @override
  State<_DayBookingsScreen> createState() => _DayBookingsScreenState();
}

class _DayBookingsScreenState extends State<_DayBookingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _displayCount = ValueNotifier<int>(15);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _displayCount.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _displayCount.value += 15;
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startOfDay = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    final endOfDay = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      23,
      59,
      59,
    );
    final dayName = DateFormat('EEEE، d MMMM yyyy', 'ar').format(widget.date);

    return Scaffold(
      appBar: _buildLabAppBar(dayName),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF7FB), Color(0xFFF4FAFD), Color(0xFFF8FCFE)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lab_bookings')
              .where('laboratoryId', isEqualTo: widget.laboratoryId)
              .where('archivedDate', isNull: false)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where(
                'createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
              )
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoadingIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 100, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد حجوزات في هذا اليوم',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final allBookings = snapshot.data!.docs
                .map((doc) => LabBookingModel.fromFirestore(doc))
                .toList();

            return ValueListenableBuilder<int>(
              valueListenable: _displayCount,
              builder: (context, displayCount, _) {
                final displayedBookings = allBookings
                    .take(displayCount)
                    .toList();
                final hasMore = allBookings.length > displayCount;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      displayedBookings.length +
                      (hasMore && _isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayedBookings.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: AppLoadingIndicator(),
                        ),
                      );
                    }

                    final booking = displayedBookings[index];
                    return _BookingCard(booking: booking);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// بطاقة الحجز
class _BookingCard extends StatelessWidget {
  final LabBookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (booking.status) {
      case LabBookingStatus.pending:
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        statusIcon = Icons.pending;
        break;
      case LabBookingStatus.confirmed:
        statusColor = Colors.blue;
        statusText = 'مؤكد';
        statusIcon = Icons.check_circle;
        break;
      case LabBookingStatus.completed:
        statusColor = Colors.green;
        statusText = 'مكتمل';
        statusIcon = Icons.task_alt;
        break;
      case LabBookingStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'ملغي';
        statusIcon = Icons.cancel;
        break;
    }

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '#${booking.bookingNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // اسم المريض
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // التحاليل المطلوبة
            if (booking.testTypes.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.science, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.testTypes.join('، '),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // نوع الخدمة
            if (booking.serviceType != null) ...[
              Row(
                children: [
                  Icon(
                    booking.serviceType == 'lab'
                        ? Icons.local_hospital
                        : Icons.home,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.serviceTypeArabic,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // رقم الهاتف وأزرار الاتصال
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.patientPhone,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                // زر الاتصال
                IconButton(
                  icon: const Icon(Icons.call, color: Color(0xFF00BCD4)),
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final uri = Uri.parse('tel:${booking.patientPhone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                const SizedBox(width: 8),
                // زر الواتساب
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Color(0xFF25D366),
                  ),
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final phone = booking.patientPhone.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    final message = Uri.encodeComponent(
                      'أهلاً بحضرتك 👋\n'
                      'نحن ${booking.laboratoryName}\n'
                      'نتشرف بخدمتك دائماً\n\n',
                    );
                    final uri = Uri.parse(
                      'https://wa.me/+2$phone?text=$message',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // التاريخ والوقت
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat(
                    'd MMM yyyy - h:mm a',
                    'ar',
                  ).format(booking.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // زر تم انتهاء التحليل
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final phone = booking.patientPhone.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final message = Uri.encodeComponent(
                    'أهلاً بحضرتك 👋\n'
                    'نحن ${booking.laboratoryName}\n\n'
                    'نفيدكم بإنه تم انتهاء تحليلكم ✅\n'
                    'يمكنكم استلام النتيجة في أي وقت\n\n'
                    'نتمنى لكم الصحة والعافية 💚',
                  );
                  final uri = Uri.parse('https://wa.me/+2$phone?text=$message');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                label: const Text('تم انتهاء التحليل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // الملاحظات
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
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
