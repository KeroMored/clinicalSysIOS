import 'package:mallawicure/features/clinic/data/models/clinic_model.dart';
import 'package:mallawicure/features/clinic/data/models/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class AddBookingScreen extends StatefulWidget {
  final ClinicModel clinic;
  final BookingModel? booking; // للتعديل

  const AddBookingScreen({Key? key, required this.clinic, this.booking})
    : super(key: key);

  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPaid = true; // الافتراضي: تم الدفع (مؤكد)
  VisitType _visitType = VisitType.examination; // الافتراضي: كشف
  DateTime _selectedAppointmentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // إذا كان في وضع التعديل، املأ الحقول
    if (widget.booking != null) {
      _nameController.text = widget.booking!.patientName;
      _phoneController.text = widget.booking!.patientPhone == 'غير محدد'
          ? ''
          : widget.booking!.patientPhone;
      _notesController.text = widget.booking!.notes ?? '';
      _isPaid = widget.booking!.status == BookingStatus.confirmed;
      _visitType = widget.booking!.visitType;
      _selectedAppointmentDate = widget.booking!.appointmentDate;
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

    int maxBookingNumber = 0;
    for (var doc in snapshot.docs) {
      final booking = BookingModel.fromFirestore(doc);
      if (booking.bookingNumber > maxBookingNumber) {
        maxBookingNumber = booking.bookingNumber;
      }
    }

    return maxBookingNumber + 1;
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

  /// Send notification to doctor when secretary adds new booking
  Future<void> _sendNewBookingNotification(BookingModel booking) async {
    try {
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinic.id)
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
        'clinicId': widget.clinic.id,
        'title': 'حجز جديد من السكرتيرة 📋',
        'message':
            'تم إضافة حجز ${booking.patientName}\n$visitTypeArabic - $dateStr الساعة $timeStr',
        'type': 'booking_added_by_secretary',
        'bookingNumber': booking.bookingNumber,
        'patientName': booking.patientName,
        'visitType': visitTypeArabic,
        'appointmentDate': dateStr,
        'appointmentTime': timeStr,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      print('✅ New booking notification sent to doctors');
    } catch (e) {
      print('❌ Error sending new booking notification: $e');
    }
  }

  Future<void> _addBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // في وضع التعديل، استخدم نفس رقم الحجز
      final bookingNumber =
          widget.booking?.bookingNumber ??
          await _getNextBookingNumber(_selectedAppointmentDate);

      final booking = BookingModel(
        id: widget.booking?.id ?? '',
        patientName: _nameController.text.trim(),
        patientPhone: _phoneController.text.trim().isEmpty
            ? 'غير محدد'
            : _phoneController.text.trim(),
        clinicId: widget.clinic.id,
        doctorName: widget.clinic.doctorName,
        bookingNumber: bookingNumber,
        status: _isPaid ? BookingStatus.confirmed : BookingStatus.pending,
        createdAt: widget.booking?.createdAt ?? DateTime.now(),
        confirmedAt: _isPaid ? DateTime.now() : null,
        appointmentDate: _selectedAppointmentDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isOnlineBooking: widget.booking?.isOnlineBooking ?? false,
        visitType: _visitType,
      );

      if (widget.booking != null) {
        // وضع التعديل
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.booking!.id)
            .update(booking.toFirestore());
      } else {
        // وضع الإضافة
        await FirebaseFirestore.instance
            .collection('bookings')
            .add(booking.toFirestore());

        // Send notification to doctor about new booking by secretary
        await _sendNewBookingNotification(booking);
      }

      if (mounted) {
        // عرض رسالة النجاح أولاً
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.booking != null
                  ? 'تم تعديل الحجز رقم $bookingNumber بنجاح ✓'
                  : 'تم إضافة الحجز برقم $bookingNumber بنجاح ✓',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // انتظار قليلاً ثم الرجوع
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة الحجز: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.booking != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F8FB),
        appBar: AppBar(
          toolbarHeight: 62,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: true,
          title: Text(
            isEdit ? 'تعديل الحجز' : 'إضافة حجز جديد',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF334155),
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _addBooking,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B8293),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text(
                  'حفظ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
            children: [
              _buildSectionCard(
                title: 'بيانات المريض',
                icon: Icons.person_rounded,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        label: 'اسم المريض',
                        hint: 'أدخل الاسم الكامل',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'الاسم مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        label: 'رقم الهاتف (اختياري)',
                        hint: '01001234567',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildSectionCard(
                title: 'تفاصيل الحجز',
                icon: Icons.event_note_rounded,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerButton(
                            icon: Icons.date_range_rounded,
                            label:
                                '${_selectedAppointmentDate.day}/${_selectedAppointmentDate.month}/${_selectedAppointmentDate.year}',
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedAppointmentDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedAppointmentDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    _selectedAppointmentDate.hour,
                                    _selectedAppointmentDate.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPickerButton(
                            icon: Icons.schedule_rounded,
                            label:
                                '${_selectedAppointmentDate.hour.toString().padLeft(2, '0')}:${_selectedAppointmentDate.minute.toString().padLeft(2, '0')}',
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  _selectedAppointmentDate,
                                ),
                              );
                              if (time != null) {
                                setState(() {
                                  _selectedAppointmentDate = DateTime(
                                    _selectedAppointmentDate.year,
                                    _selectedAppointmentDate.month,
                                    _selectedAppointmentDate.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildVisitTypeButton(
                            title: 'كشف',
                            icon: Icons.medical_services_rounded,
                            selected: _visitType == VisitType.examination,
                            selectedColor: const Color(0xFF2563EB),
                            onTap: () => setState(
                              () => _visitType = VisitType.examination,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildVisitTypeButton(
                            title: 'إعادة',
                            icon: Icons.replay_circle_filled_rounded,
                            selected: _visitType == VisitType.followUp,
                            selectedColor: const Color(0xFF7C3AED),
                            onTap: () =>
                                setState(() => _visitType = VisitType.followUp),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isPaid
                            ? const Color(0xFFECFDF3)
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isPaid
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFFED7AA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPaid
                                ? Icons.check_circle_rounded
                                : Icons.hourglass_empty_rounded,
                            size: 18,
                            color: _isPaid
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isPaid
                                  ? 'مدفوع - مؤكد'
                                  : 'غير مدفوع - في الانتظار',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _isPaid
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF9A3412),
                              ),
                            ),
                          ),
                          Switch(
                            value: _isPaid,
                            onChanged: (value) =>
                                setState(() => _isPaid = value),
                            activeColor: const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      minLines: 1,
                      decoration: _inputDecoration(
                        label: 'ملاحظات (اختياري)',
                        hint: 'اكتب ملاحظة قصيرة...',
                        icon: Icons.notes_rounded,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B8293),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B8293).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B8293),
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: AppLoadingIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEdit ? 'حفظ التعديل' : 'تأكيد الحجز',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF0B8293), size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool dense = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: dense,
      contentPadding: dense
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : null,
      prefixIcon: Icon(icon, color: const Color(0xFF0B8293)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE7EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE7EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0B8293), width: 1.5),
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE7EF)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0B8293)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitTypeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? selectedColor : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? selectedColor : const Color(0xFFDDE7EF),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : selectedColor,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
