import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/clinic_model.dart';
import '../../data/repositories/booking_tracking_repository.dart';
import '../../data/services/booking_block_service.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class BookAppointmentScreen extends StatefulWidget {
  final ClinicModel clinic;

  const BookAppointmentScreen({super.key, required this.clinic});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _primaryDark = Color(0xFF115E59);

  final GlobalKey _screenCaptureKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  DateTime _selectedAppointmentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || !mounted) return;

      final userData = userDoc.data();
      if (userData == null) return;

      if (userData['displayName'] != null) {
        _nameController.text = userData['displayName'];
      }
      if (userData['phoneNumber'] != null &&
          userData['phoneNumber'].toString().isNotEmpty) {
        _phoneController.text = userData['phoneNumber'];
      }
    } catch (_) {
      // Non-blocking: screen still works without cached profile data.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<int> _getNextBookingNumber(DateTime appointmentDate) async {
    final startOfDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );
    final endOfDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      23,
      59,
      59,
    );

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinic.id)
        .where(
          'appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .get();

    if (snapshot.docs.isEmpty) return 1;

    var maxBookingNumber = 0;
    for (final doc in snapshot.docs) {
      final booking = BookingModel.fromFirestore(doc);
      if (booking.bookingNumber > maxBookingNumber) {
        maxBookingNumber = booking.bookingNumber;
      }
    }

    return maxBookingNumber + 1;
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final patientPhone = _phoneController.text.trim();
    final isBlocked = await BookingBlockService().isPatientBlocked(
      patientPhone,
    );

    if (isBlocked) {
      final blockInfo = await BookingBlockService().getBlockInfo(patientPhone);
      if (!mounted) return;

      final blockedUntil = blockInfo?['blockedUntil'] as Timestamp?;
      final reason = blockInfo?['blockReason'] as String? ?? 'تكرار عدم الحضور';
      final noShowCount = blockInfo?['noShowCount'] ?? 0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⛔ ممنوع من الحجز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم منعك من الحجز بسبب: $reason',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('عدد مرات عدم الحضور: $noShowCount'),
              if (blockedUntil != null) ...[
                const SizedBox(height: 8),
                Text('سيُرفع المنع في: ${_formatDate(blockedUntil.toDate())}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bookingNumber = await _getNextBookingNumber(
        _selectedAppointmentDate,
      );
      final user = FirebaseAuth.instance.currentUser;

      final booking = BookingModel(
        id: '',
        patientName: _nameController.text.trim(),
        patientPhone: _phoneController.text.trim(),
        clinicId: widget.clinic.id,
        doctorName: widget.clinic.doctorName,
        clinicType: widget.clinic.clinicType, // إضافة نوع العيادة
        bookingNumber: bookingNumber,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        appointmentDate: _selectedAppointmentDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isOnlineBooking: true,
        userId: user?.uid,
      );

      await FirebaseFirestore.instance
          .collection('bookings')
          .add(booking.toFirestore());

      await BookingTrackingRepository().saveTracking(
        BookingTrackingInfo(
          clinicId: widget.clinic.id,
          doctorName: widget.clinic.doctorName,
          clinicType: widget.clinic.clinicType, // إضافة نوع العيادة
          departmentName: widget.clinic.department.arabicName,
          bookingNumber: bookingNumber,
          appointmentDate: _selectedAppointmentDate,
          userId: user?.uid,
        ),
      );

      final clinicName = widget.clinic.doctorName;
      NotificationService.showBookingStatusNotification(
        title: '⏳ في انتظار تأكيد الحجز',
        body: 'تم إرسال طلب حجزك لدى $clinicName وسيتم إشعارك عند التأكيد',
        notificationId: 70001,
      );

      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            final phoneNumber = _phoneController.text.trim();
            final userName = _nameController.text.trim();

            final updates = <String, dynamic>{};

            if (phoneNumber.isNotEmpty &&
                (userData?['phoneNumber'] == null ||
                    userData!['phoneNumber'].toString() != phoneNumber)) {
              updates['phoneNumber'] = phoneNumber;
            }

            if (userName.isNotEmpty &&
                (userData?['displayName'] == null ||
                    userData!['displayName'].toString() != userName)) {
              updates['displayName'] = userName;
            }

            if (updates.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update(updates);

              if (mounted) {
                context.read<AuthCubit>().refreshUser();
              }
            }
          }
        } catch (_) {
          // Non-blocking user profile update.
        }
      }

      if (mounted) {
        _showSuccessDialog(bookingNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(int bookingNumber) {
    final ticketCaptureKey = GlobalKey();
    bool isSavingImage = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _primaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'تم الحجز بنجاح',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF134E4A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'احتفظ برقم الحجز لاستخدامه عند المتابعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: ticketCaptureKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _primaryColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'رقم الحجز',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$bookingNumber',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: _primaryColor,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSavingImage
                            ? null
                            : () async {
                                setDialogState(() => isSavingImage = true);
                                final saved =
                                    await _saveBookingSnapshotToDevice(
                                      bookingNumber: bookingNumber,
                                      captureKey: ticketCaptureKey,
                                    );
                                if (dialogContext.mounted) {
                                  setDialogState(() => isSavingImage = false);
                                }
                                if (saved && dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                        icon: isSavingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: AppLoadingIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.image_outlined, size: 18),
                        label: Text(
                          isSavingImage ? 'جاري التحضير...' : 'الاحتفاظ بالرقم',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(
                            color: _primaryColor.withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'تم',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Future<bool> _saveBookingSnapshotToDevice({
    required int bookingNumber,
    required GlobalKey captureKey,
  }) async {
    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('capture-boundary-not-found');
      }

      if (boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('capture-bytes-null');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final fileName =
          'clinic_booking_${bookingNumber}_${DateTime.now().millisecondsSinceEpoch}';

      await Gal.putImageBytes(pngBytes, name: '$fileName.png');

      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الصورة على الجهاز بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ الصورة على الجهاز حاليا، حاول مرة أخرى'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<DateTime> _availableDates() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final lockDate = widget.clinic.bookingLockDate;
    final isLockedToday =
        lockDate != null &&
        lockDate.year == start.year &&
        lockDate.month == start.month &&
        lockDate.day == start.day;

    final dates = <DateTime>[];
    var current = start;
    final endDate = start.add(const Duration(days: 14));

    while (current.isBefore(endDate) && dates.length < 14) {
      final dayName = DateFormat('EEEE').format(current).toLowerCase();
      final hours = widget.clinic.workingHours[dayName];

      final isWorkingDay = hours != null && !hours.isClosed;
      final isHoliday = widget.clinic.holidays.any((h) {
        final holidayDate = DateTime.parse(h);
        return holidayDate.year == current.year &&
            holidayDate.month == current.month &&
            holidayDate.day == current.day;
      });

      if (isWorkingDay && !isHoliday) {
        if (current.day != start.day || !isLockedToday) {
          dates.add(current);
        }
      }

      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  String _weekdayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      default:
        return '';
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFF9CA3AF),
        fontWeight: FontWeight.w400,
      ),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, size: 18, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.3),
      ),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    final specializationText = widget.clinic.department.arabicName;
    final dates = _availableDates();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F4),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 19,
            color: Color(0xFF0F766E),
          ),
        ),
        title: const Text(
          'احجز موعد',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: RepaintBoundary(
          key: _screenCaptureKey,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              widget.clinic.doctorImageUrl != null &&
                                  widget.clinic.doctorImageUrl!.isNotEmpty
                              ? Image.network(
                                  widget.clinic.doctorImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 34,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 34,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7F5F3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  specializationText,
                                  style: const TextStyle(
                                    color: Color(0xFF0F766E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.clinic.doctorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.clinic.averageRating.toStringAsFixed(
                                      1,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF374151),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${widget.clinic.consultationFee.toStringAsFixed(0)} جنيه',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'بيانات المريض',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      hint: 'الاسم كما هو في البطاقة',
                      suffixIcon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الاسم مطلوب';
                      }
                      if (value.trim().length < 3) {
                        return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      hint: '+966 5X XXX XXXX',
                      suffixIcon: Icons.call_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'رقم الهاتف مطلوب';
                      }
                      if (value.trim().length < 11) {
                        return 'رقم الهاتف غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'تاريخ الكشف',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final date = dates[index];
                        final isSelected = _isSameDay(
                          date,
                          _selectedAppointmentDate,
                        );
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAppointmentDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                _selectedAppointmentDate.hour,
                                _selectedAppointmentDate.minute,
                              );
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 66,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F766E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFFE5E7EB),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _weekdayLabel(date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white70
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ملاحظات إضافية (اختياري)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      hint: 'اكتب أي تفاصيل أو استفسار تحب تضيفه...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD9BD)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFB45309),
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تنبيه: الحجز الوهمي أو التكرار بدون التزام قد يؤدي إلى إيقاف حسابك على التطبيق.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: AppLoadingIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'تأكيد الحجز',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
