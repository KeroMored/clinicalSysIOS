import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../data/models/clinic_model.dart';
import '../../data/models/booking_model.dart';

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
    // التأكد من وجود حجوزات قبل إنهاء اليوم
    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinic.id)
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
          appBar: AppBar(
            leading:  IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('إدارة الحجوزات',style: TextStyle( color: Colors.white),),
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            actions: [
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

  void _showAddBookingDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

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
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;

                setDialogState(() {
                  isLoading = true;
                });

                try {
                  final bookingNumber = await _getNextBookingNumber();
                  
                  final booking = BookingModel(
                    id: '',
                    patientName: nameController.text.trim(),
                    patientPhone: phoneController.text.trim().isEmpty 
                        ? 'غير محدد' 
                        : phoneController.text.trim(),
                    clinicId: widget.clinic.id,
                    doctorName: widget.clinic.doctorName,
                    bookingNumber: bookingNumber,
                    status: BookingStatus.confirmed,
                    createdAt: DateTime.now(),
                    confirmedAt: DateTime.now(),
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
              child: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
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
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinic.id)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clinicId', isEqualTo: widget.clinic.id)
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
            _buildInfoRow(Icons.person, 'المريض', booking.patientName),
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
