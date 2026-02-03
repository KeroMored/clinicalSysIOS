import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/clinic_model.dart';
import '../../data/models/booking_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/patient_cubit.dart';
import 'patient_details_screen.dart';

class BookingsManagementScreen extends StatefulWidget {
  final ClinicModel clinic;

  const BookingsManagementScreen({super.key, required this.clinic});

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> with SingleTickerProviderStateMixin {
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
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    // التأكد من وجود حجوزات لليوم الحالي قبل إنهاء اليوم
    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinic.id)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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
              backgroundColor: const Color(0xFF3B82F6),
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
        batch.update(doc.reference, {
          'archivedDate': Timestamp.fromDate(now),
        });
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
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clinicId', isEqualTo: widget.clinic.id)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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
          appBar: AppBar(
            leading:  IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('إدارة الحجوزات',style: TextStyle( color: Colors.white),),
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            actions: [
              // زر التقويم
              IconButton(
                onPressed: () => _showCalendarView(context),
                icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                tooltip: 'عرض التقويم',
              ),
              IconButton(
                onPressed: _endDay,
                icon: const Icon(Icons.event_available_rounded, color: Colors.white),
                tooltip: 'إنهاء اليوم',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('مؤكد'),
                      if (confirmedCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$confirmedCount',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddBookingDialog(),
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('حجز جديد'),
          ),
        );
      },
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

  void _showAddBookingDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool isPaid = true; // الافتراضي: تم الدفع (مؤكد)
    DateTime selectedAppointmentDate = DateTime.now(); // الافتراضي: الآن

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'إضافة حجز جديد',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
                const Divider(height: 32),
                // Content
                Flexible(
                  child: Form(
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
                    validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // اختيار تاريخ ووقت الموعد
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF3B82F6), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'موعد الكشف',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedAppointmentDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF3B82F6),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      selectedAppointmentDate = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        selectedAppointmentDate.hour,
                                        selectedAppointmentDate.minute,
                                      );
                                    });
                                  }
                                },
                                icon: const Icon(Icons.date_range, size: 18),
                                label: Text(
                                  '${selectedAppointmentDate.day}/${selectedAppointmentDate.month}/${selectedAppointmentDate.year}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(selectedAppointmentDate),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF3B82F6),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      selectedAppointmentDate = DateTime(
                                        selectedAppointmentDate.year,
                                        selectedAppointmentDate.month,
                                        selectedAppointmentDate.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                  }
                                },
                                icon: const Icon(Icons.access_time, size: 18),
                                label: Text(
                                  '${selectedAppointmentDate.hour.toString().padLeft(2, '0')}:${selectedAppointmentDate.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // حالة الدفع
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPaid ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle : Icons.pending,
                          color: isPaid ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPaid ? 'تم الدفع - حجز مؤكد' : 'بدون دفع - حجز غير مؤكد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isPaid ? Colors.green[700] : Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPaid ? 'المريض دفع المبلغ المطلوب' : 'المريض لم يدفع بعد',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isPaid,
                          onChanged: (value) {
                            setDialogState(() {
                              isPaid = value;
                            });
                          },
                          activeColor: Colors.green,
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
                ),
                const SizedBox(height: 24),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;

                setDialogState(() {
                  isLoading = true;
                });

                try {
                  final bookingNumber = await _getNextBookingNumber(selectedAppointmentDate);
                  
                  final booking = BookingModel(
                    id: '',
                    patientName: nameController.text.trim(),
                    patientPhone: phoneController.text.trim().isEmpty 
                        ? 'غير محدد' 
                        : phoneController.text.trim(),
                    clinicId: widget.clinic.id,
                    doctorName: widget.clinic.doctorName,
                    bookingNumber: bookingNumber,
                    status: isPaid ? BookingStatus.confirmed : BookingStatus.pending,
                    createdAt: DateTime.now(),
                    confirmedAt: isPaid ? DateTime.now() : null,
                    appointmentDate: selectedAppointmentDate,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    isOnlineBooking: false, // حجز يدوي من العيادة
                  );

                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .add(booking.toFirestore());

                  if (mounted) {
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم إضافة الحجز برقم $bookingNumber'),
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
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'إضافة الحجز',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int> _getNextBookingNumber(DateTime appointmentDate) async {
    final startOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
    final endOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day, 23, 59, 59);

    // جلب كل الحجوزات في نفس يوم الموعد (مؤرشفة وغير مؤرشفة)
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinic.id)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (snapshot.docs.isEmpty) return 1;

    // إيجاد أكبر رقم حجز
    int maxBookingNumber = 0;
    for (var doc in snapshot.docs) {
      final booking = BookingModel.fromFirestore(doc);
      if (booking.bookingNumber > maxBookingNumber) {
        maxBookingNumber = booking.bookingNumber;
      }
    }

    return maxBookingNumber + 1;
  }
}

class _BookingsListTab extends StatefulWidget {
  final ClinicModel clinic;
  final BookingStatus status;

  const _BookingsListTab({
    required this.clinic,
    required this.status,
  });

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
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
            _displayCount = (_displayCount + _pageSize).clamp(0, _allBookings.length);
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
      if (a.status == BookingStatus.completed && b.status != BookingStatus.completed) {
        return 1;
      }
      if (b.status == BookingStatus.completed && a.status != BookingStatus.completed) {
        return -1;
      }
      // إذا كانت نفس الحالة، رتب حسب التاريخ (الأقدم أولاً)
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clinicId', isEqualTo: widget.clinic.id)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(
            child: SpinKitPulsingGrid(
              color: const Color(0xFF3B82F6),
              size: 50,
            ),
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
          itemCount: displayedBookings.length + ((hasMore || _isLoadingMore) ? 1 : 0),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }
            
            final booking = displayedBookings[index];
            return _BookingCard(
              booking: booking,
              key: ValueKey(booking.id),
            );
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({
    super.key,
    required this.booking,
  });

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

      // إذا كان لديه صلاحية الدخول (موجود في authEmails) فهو يستطيع رؤية المرضى
      // لا نحتاج التحقق من doctorEmails لأن authEmails تكفي
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isCancelled ? Colors.red[50] : (isCompleted ? Colors.grey[200] : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.red.withValues(alpha: 0.1)
                        : isCompleted
                            ? Colors.grey.withValues(alpha: 0.3)
                            : isPending 
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCancelled
                        ? Icons.cancel_rounded
                        : isCompleted 
                            ? Icons.task_alt_rounded
                            : isPending ? Icons.pending_rounded : Icons.check_circle_rounded,
                    color: isCancelled ? Colors.red : (isCompleted ? Colors.grey : (isPending ? Colors.orange : Colors.green)),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'رقم الحجز: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: (isCompleted || isCancelled) ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Text(
                            '${booking.bookingNumber}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.grey : const Color(0xFF3B82F6),
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        booking.statusArabic,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.grey : (isPending ? Colors.orange : Colors.green),
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
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
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
            const Divider(height: 24),
            // اسم المريض - قابل للضغط للبحث عنه (للدكتور فقط)
            InkWell(
              onTap: () async {
                // التحقق من أن المستخدم دكتور
                final isDoctor = await _isDoctorUser(context);
                if (!isDoctor) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('هذه الميزة متاحة للدكتور فقط'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }
                if (context.mounted) {
                  _searchAndOpenPatient(context);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'المريض: ',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    Expanded(
                      child: Text(
                        booking.patientName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3B82F6),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'الهاتف', booking.patientPhone),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'تاريخ الحجز',
              _formatDateTime(booking.createdAt),
            ),
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
                    const Icon(Icons.note, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.notes!,
                        style: const TextStyle(fontSize: 13),
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
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
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
                CircularProgressIndicator(),
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
        String cleanPhone = booking.patientPhone.replaceAll(RegExp(r'[^0-9+]'), '');
        
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
        String cleanName = booking.patientName.trim().replaceAll(RegExp(r'\s+'), ' ');
        
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
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
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
      List<String> shorterWords = words1.length < words2.length ? words1 : words2;
      List<String> longerWords = words1.length < words2.length ? words2 : words1;
      
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
    int maxWords = words1.length > words2.length ? words1.length : words2.length;
    
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
    if (similarity >= 0.8 && matchCount >= 2 && 
        words1.isNotEmpty && words2.isNotEmpty &&
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
        .replaceAll('ى', 'ي')  // توحيد الياء
        .replaceAll('ة', 'ه')  // توحيد التاء المربوطة
        .replaceAll('أ', 'ا')  // توحيد الهمزة
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll(RegExp(r'\s+'), ' ');  // توحيد المسافات
  }

  // عرض dialog لاختيار المريض من قائمة
  void _showPatientsSelectionDialog(BuildContext context, List<QueryDocumentSnapshot> patients) {
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
              child: Text(
                'اختر المريض',
                style: TextStyle(fontSize: 20),
              ),
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
                    final patient = patients[index].data() as Map<String, dynamic>;
                    final patientId = patients[index].id;
                    final name = patient['name'] ?? '';
                    final phone = patient['phoneNumber'] ?? 'لا يوجد';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF3B82F6),
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
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
              backgroundColor: const Color(0xFF3B82F6),
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
              backgroundColor: const Color(0xFF3B82F6),
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
          .update({
        'status': 'confirmed',
        'confirmedAt': Timestamp.now(),
      });

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
            // "تم الكشف" يظهر فقط للحجوزات المؤكدة
            if (isConfirmed)
              ListTile(
                leading: const Icon(Icons.task_alt_rounded, color: Colors.blue),
                title: const Text('تم الكشف'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsCompleted(context);
                },
              ),
            // "لم يتم الكشف" يظهر فقط للحجوزات المكتملة
            if (isCompleted)
              ListTile(
                leading: const Icon(Icons.undo_rounded, color: Colors.orange),
                title: const Text('لم يتم الكشف'),
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
          .collection('bookings')
          .doc(booking.id!)
          .update({
        'status': 'confirmed',
      });

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
          .update({
        'status': 'cancelled',
        'cancelledAt': Timestamp.now(),
      });

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
          .update({
        'status': 'completed',
      });

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
}

// صفحة عرض حجوزات يوم معين
class _DayBookingsScreen extends StatefulWidget {
  final DateTime date;
  final List<BookingModel> bookings;

  const _DayBookingsScreen({
    required this.date,
    required this.bookings,
  });

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
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'حذف الحجز',
                style: TextStyle(fontSize: 20),
              ),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'حجوزات ${widget.date.day}/${widget.date.month}/${widget.date.year}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF3B82F6).withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_bookings.length} حجز',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
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
                                    colors: [statusColor, statusColor.withOpacity(0.7)],
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
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: statusColor.withOpacity(0.3),
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
                                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: Color(0xFF3B82F6),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${booking.appointmentDate.hour.toString().padLeft(2, '0')}:${booking.appointmentDate.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF3B82F6),
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
                              
                              // زر الحذف
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
                                        borderRadius: BorderRadius.circular(10),
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
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinicId)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('archivedDate', isNull: true)
        .get();

    final bookings = snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();

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
            const Icon(Icons.calendar_month, color: Color(0xFF3B82F6), size: 28),
            const SizedBox(width: 12),
            const Text(
              'التقويم',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, size: 28),
              rightChevronIcon: const Icon(Icons.chevron_right, size: 28),
              headerPadding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
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
        builder: (context) => _DayBookingsScreen(
          date: date,
          bookings: bookings,
        ),
      ),
    );
  }

}
