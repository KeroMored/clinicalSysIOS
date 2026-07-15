import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../data/models/laboratory_model.dart';
import '../../data/models/lab_booking_model.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class LabBookingsManagementScreen extends StatefulWidget {
  final LaboratoryModel laboratory;

  const LabBookingsManagementScreen({super.key, required this.laboratory});

  @override
  State<LabBookingsManagementScreen> createState() =>
      _LabBookingsManagementScreenState();
}

class _LabBookingsManagementScreenState
    extends State<LabBookingsManagementScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _textPrimary = Color(0xFF0F172A);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _endDay() async {
    // التأكد من وجود حجوزات قبل إنهاء اليوم
    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('lab_bookings')
        .where('laboratoryId', isEqualTo: widget.laboratory.id)
        .where('archivedDate', isNull: true)
        .get();

    if (bookingsSnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد حجوزات لإنهاء اليوم'),
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
          'سيتم نقل ${bookingsSnapshot.docs.length} حجز إلى السجل وإنهاء اليوم الحالي.\n\nهل أنت متأكد؟',
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
              backgroundColor: const Color(0xFF00BCD4),
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
      final now = DateTime.now();

      for (var doc in bookingsSnapshot.docs) {
        batch.update(doc.reference, {'archivedDate': Timestamp.fromDate(now)});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنهاء اليوم بنجاح'),
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
          .collection('lab_bookings')
          .where('laboratoryId', isEqualTo: widget.laboratory.id)
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
            } else if (status == 'confirmed' || status == 'completed') {
              confirmedCount++;
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0.5,
            centerTitle: true,
            title: const Text(
              'إدارة الحجوزات',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _primaryColor,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                onPressed: _endDay,
                icon: const Icon(
                  Icons.check_circle,
                  color: _primaryColor,
                  size: 24,
                ),
                tooltip: 'إنهاء اليوم',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7E4EE)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF476079),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('مؤكد'),
                          if (confirmedCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.26),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$confirmedCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('في الانتظار'),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.26),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFEAF7FB),
                  Color(0xFFF4FAFD),
                  Color(0xFFF8FCFE),
                ],
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _BookingsListTab(
                  laboratory: widget.laboratory,
                  status: LabBookingStatus.confirmed,
                ),
                _BookingsListTab(
                  laboratory: widget.laboratory,
                  status: LabBookingStatus.pending,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddBookingDialog(),
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.add),
            label: const Text('حجز جديد'),
          ),
        );
      },
    );
  }

  void _showAddBookingDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();
    final customTestController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? selectedTest;
    String serviceType = 'lab'; // القيمة الافتراضية: في المعمل
    bool isCustomTest = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة حجز جديد'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المريض',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  // نوع التحليل
                  if (!isCustomTest)
                    DropdownButtonFormField<String>(
                      value: selectedTest,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'نوع التحليل',
                        prefixIcon: Icon(Icons.science),
                      ),
                      items: [
                        ...widget.laboratory.availableTests.map((test) {
                          return DropdownMenuItem(
                            value: test,
                            child: Text(
                              test,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }),
                        const DropdownMenuItem(
                          value: '__custom__',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 14, color: Colors.orange),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'أخرى (كتابة يدوية)',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == '__custom__') {
                          setDialogState(() {
                            isCustomTest = true;
                            selectedTest = null;
                          });
                        } else {
                          setDialogState(() => selectedTest = value);
                        }
                      },
                      validator: (v) =>
                          v == null && !isCustomTest ? 'مطلوب' : null,
                    )
                  else
                    Column(
                      children: [
                        TextFormField(
                          controller: customTestController,
                          decoration: const InputDecoration(
                            labelText: 'اكتب نوع التحليل',
                            prefixIcon: Icon(Icons.science),
                          ),
                          validator: (v) =>
                              v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              isCustomTest = false;
                              customTestController.clear();
                            });
                          },
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text(
                            'العودة للقائمة',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  // نوع الخدمة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'نوع الخدمة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setDialogState(() => serviceType = 'lab'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: serviceType == 'lab'
                                        ? const Color(0xFF00BCD4)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: serviceType == 'lab'
                                          ? const Color(0xFF00BCD4)
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.location_city,
                                        color: serviceType == 'lab'
                                            ? Colors.white
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'في المعمل',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: serviceType == 'lab'
                                              ? Colors.white
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setDialogState(() => serviceType = 'home'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: serviceType == 'home'
                                        ? const Color(0xFF00BCD4)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: serviceType == 'home'
                                          ? const Color(0xFF00BCD4)
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.home,
                                        color: serviceType == 'home'
                                            ? Colors.white
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'من البيت',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: serviceType == 'home'
                                              ? Colors.white
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() {
                        isLoading = true;
                      });

                      try {
                        // التحقق من اختيار نوع التحليل
                        final selectedTestType = isCustomTest
                            ? customTestController.text.trim()
                            : selectedTest;

                        if (selectedTestType == null ||
                            selectedTestType.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('من فضلك اختر أو أدخل نوع التحليل'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          setDialogState(() => isLoading = false);
                          return;
                        }

                        final bookingNumber = await _getNextBookingNumber();

                        final booking = LabBookingModel(
                          id: '',
                          patientName: nameController.text.trim(),
                          patientPhone: phoneController.text.trim(),
                          laboratoryId: widget.laboratory.id,
                          laboratoryName: widget.laboratory.name,
                          bookingNumber: bookingNumber,
                          status: LabBookingStatus.confirmed,
                          createdAt: DateTime.now(),
                          confirmedAt: DateTime.now(),
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          isOnlineBooking: false, // حجز يدوي من المعمل
                          testTypes: [selectedTestType],
                          serviceType: serviceType,
                        );

                        await FirebaseFirestore.instance
                            .collection('lab_bookings')
                            .add(booking.toFirestore());

                        if (mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم إضافة الحجز برقم $bookingNumber',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: AppLoadingIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getNextBookingNumber() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    // جلب كل الحجوزات اليوم (مؤرشفة وغير مؤرشفة)
    final snapshot = await FirebaseFirestore.instance
        .collection('lab_bookings')
        .where('laboratoryId', isEqualTo: widget.laboratory.id)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (snapshot.docs.isEmpty) return 1;

    // إيجاد أكبر رقم حجز
    int maxBookingNumber = 0;
    for (var doc in snapshot.docs) {
      final booking = LabBookingModel.fromFirestore(doc);
      if (booking.bookingNumber > maxBookingNumber) {
        maxBookingNumber = booking.bookingNumber;
      }
    }

    return maxBookingNumber + 1;
  }
}

class _BookingsListTab extends StatefulWidget {
  final LaboratoryModel laboratory;
  final LabBookingStatus status;

  const _BookingsListTab({required this.laboratory, required this.status});

  @override
  State<_BookingsListTab> createState() => _BookingsListTabState();
}

class _BookingsListTabState extends State<_BookingsListTab> {
  final ScrollController _scrollController = ScrollController();
  final List<LabBookingModel> _allBookings = [];
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
  List<LabBookingModel> _sortBookings(List<LabBookingModel> bookings) {
    final sorted = List<LabBookingModel>.from(bookings);
    sorted.sort((a, b) {
      // الحجوزات المكتملة في الأخير
      if (a.status == LabBookingStatus.completed &&
          b.status != LabBookingStatus.completed) {
        return 1;
      }
      if (b.status == LabBookingStatus.completed &&
          a.status != LabBookingStatus.completed) {
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
          .collection('lab_bookings')
          .where('laboratoryId', isEqualTo: widget.laboratory.id)
          .where('archivedDate', isNull: true)
          .orderBy('createdAt', descending: false)
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
            child: SpinKitPulsingGrid(color: const Color(0xFF00BCD4), size: 50),
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
              .map((doc) => LabBookingModel.fromFirestore(doc))
              .where((booking) {
                if (widget.status == LabBookingStatus.pending) {
                  return booking.status == LabBookingStatus.pending;
                } else {
                  return booking.status == LabBookingStatus.confirmed ||
                      booking.status == LabBookingStatus.completed;
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
                  'لا توجد حجوزات ${widget.status == LabBookingStatus.pending ? "في الانتظار" : "مؤكدة"}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey('lab_bookings_list'),
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
                            Color(0xFF00BCD4),
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
  final LabBookingModel booking;

  const _BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == LabBookingStatus.pending;
    final isCompleted = booking.status == LabBookingStatus.completed;
    final isCancelled = booking.status == LabBookingStatus.cancelled;

    final Color statusColor = isCancelled
        ? const Color(0xFFDC2626)
        : isCompleted
        ? const Color(0xFF475569)
        : isPending
        ? const Color(0xFFD97706)
        : const Color(0xFF0B8293);

    final Color cardColor = isCancelled
        ? const Color(0xFFFFF1F2)
        : isCompleted
        ? const Color(0xFFE5E7EB)
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCancelled
                        ? Icons.cancel_rounded
                        : isCompleted
                        ? Icons.task_alt_rounded
                        : isPending
                        ? Icons.pending_rounded
                        : Icons.check_circle_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.patientName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'رقم الحجز ${booking.bookingNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPending)
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _confirmBooking(context),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.statusArabic,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 18),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.phone,
                    'الهاتف',
                    booking.patientPhone,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Color(0xFF0B8293)),
                      onPressed: () =>
                          _makePhoneCall(context, booking.patientPhone),
                      tooltip: 'اتصال',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.chat, color: Color(0xFF25D366)),
                      onPressed: () =>
                          _openWhatsApp(context, booking.patientPhone),
                      tooltip: 'واتساب',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'تاريخ الحجز',
              _formatDateTime(booking.createdAt),
            ),
            if (booking.testTypes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.science,
                booking.testTypes.length > 1 ? 'التحاليل' : 'نوع التحليل',
                booking.testTypes.join('، '),
              ),
            ],
            if (booking.serviceType != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    booking.serviceType == 'home'
                        ? Icons.home
                        : Icons.location_city,
                    size: 18,
                    color: booking.serviceType == 'home'
                        ? Colors.purple
                        : const Color(0xFF00BCD4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.serviceTypeArabic,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: booking.serviceType == 'home'
                          ? Colors.purple
                          : const Color(0xFF00BCD4),
                    ),
                  ),
                ],
              ),
            ],
            if (booking.confirmedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.check_circle,
                'تاريخ التأكيد',
                _formatDateTime(booking.confirmedAt!),
              ),
            ],
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
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
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatWhatsAppNumber(String phone) {
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = phone.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return '20$n';
    // ضيف +20 قدام الرقم
    return '20$n';
  }

  void _makePhoneCall(BuildContext context, String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن إجراء المكالمة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openWhatsApp(BuildContext context, String phone) async {
    final formattedPhone = _formatWhatsAppNumber(phone);
    final Uri whatsappUri = Uri.parse('https://wa.me/$formattedPhone');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن فتح واتساب'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
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
          .collection('lab_bookings')
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
    final isConfirmed = booking.status == LabBookingStatus.confirmed;
    final isCompleted = booking.status == LabBookingStatus.completed;
    final isCancelled = booking.status == LabBookingStatus.cancelled;

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
            // "تم إجراء التحليل" يظهر فقط للحجوزات المؤكدة
            if (isConfirmed)
              ListTile(
                leading: const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFF00BCD4),
                ),
                title: const Text('تم إجراء التحليل'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsCompleted(context);
                },
              ),
            // "لم يتم إجراء التحليل" يظهر فقط للحجوزات المكتملة
            if (isCompleted)
              ListTile(
                leading: const Icon(Icons.undo_rounded, color: Colors.orange),
                title: const Text('لم يتم إجراء التحليل'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsNotCompleted(context);
                },
              ),
            // "إلغاء الحجز" يظهر للحجوزات غير الملغية
            if (!isCancelled)
              ListTile(
                leading: const Icon(Icons.cancel_rounded, color: Colors.red),
                title: const Text('إلغاء الحجز'),
                onTap: () {
                  Navigator.pop(context);
                  _cancelBooking(context);
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
          .collection('lab_bookings')
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
          .collection('lab_bookings')
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
          .collection('lab_bookings')
          .doc(booking.id!)
          .update({'status': 'completed'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل إجراء التحليل بنجاح'),
            backgroundColor: Color(0xFF00BCD4),
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
}
