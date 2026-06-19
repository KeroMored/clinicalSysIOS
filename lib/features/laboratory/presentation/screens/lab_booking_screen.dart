import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/laboratory_model.dart';
import '../../data/models/lab_booking_model.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class LabBookingScreen extends StatefulWidget {
  final LaboratoryModel laboratory;

  const LabBookingScreen({super.key, required this.laboratory});

  @override
  State<LabBookingScreen> createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends State<LabBookingScreen> {
  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _primaryDark = Color(0xFF115E59);

  final GlobalKey _screenCaptureKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _customTestController = TextEditingController();

  String? _selectedTest;
  final List<String> _selectedTests = [];
  String _serviceType = 'lab'; // القيمة الافتراضية: في المعمل
  bool _isSubmitting = false;
  bool _isCustomTest = false;

  void _addSelectedTest(String testName) {
    final normalized = testName.trim();
    if (normalized.isEmpty) return;

    if (_selectedTests.contains(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا التحليل مضاف بالفعل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedTests.add(normalized);
      _selectedTest = null;
      _customTestController.clear();
      _isCustomTest = false;
    });
  }

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

      if (!mounted || !userDoc.exists) return;

      final userData = userDoc.data();
      if (userData == null) return;

      final displayName = (userData['displayName'] ?? user.displayName ?? '')
          .toString()
          .trim();
      final phoneNumber =
          (userData['phoneNumber'] ??
                  userData['phone'] ??
                  user.phoneNumber ??
                  '')
              .toString()
              .trim();

      if (displayName.isNotEmpty) {
        _nameController.text = displayName;
      }
      if (phoneNumber.isNotEmpty) {
        _phoneController.text = phoneNumber;
      }
    } catch (_) {
      // Non-blocking: booking can continue without prefilled profile.
    }
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final updates = <String, dynamic>{};

    if (name.isNotEmpty) {
      updates['displayName'] = name;
    }
    if (phone.isNotEmpty) {
      updates['phoneNumber'] = phone;
    }

    if (updates.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));

      if (mounted) {
        try {
          context.read<AuthCubit>().refreshUser();
        } catch (_) {
          // Safe fallback when auth cubit is not available in tree.
        }
      }
    } catch (_) {
      // Non-blocking: booking should succeed even if profile sync fails.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _customTestController.dispose();
    super.dispose();
  }

  Future<int> _getNextBookingNumber() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    // جلب كل الحجوزات اليوم (مسترجعة وغير مسترجعة)
    final snapshot = await FirebaseFirestore.instance
        .collection('lab_bookings')
        .where('laboratoryId', isEqualTo: widget.laboratory.id)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (snapshot.docs.isEmpty) {
      return 1;
    }

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

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من اختيار التحاليل
    if (_selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك أضف تحليل واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bookingNumber = await _getNextBookingNumber();

      final booking = LabBookingModel(
        id: '',
        patientName: _nameController.text.trim(),
        patientPhone: _phoneController.text.trim(),
        laboratoryId: widget.laboratory.id,
        laboratoryName: widget.laboratory.name,
        bookingNumber: bookingNumber,
        status: LabBookingStatus.pending,
        createdAt: DateTime.now(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isOnlineBooking: true, // حجز أونلاين من المريض
        testTypes: List<String>.from(_selectedTests),
        serviceType: _serviceType,
      );

      // حفظ الحجز
      final docRef = await FirebaseFirestore.instance
          .collection('lab_bookings')
          .add(booking.toFirestore());

      await _saveUserData();

      // إرسال إشعار للمعمل عبر Firebase Topic
      await _sendLabNotification(bookingNumber, docRef.id);

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

  Future<void> _sendLabNotification(int bookingNumber, String bookingId) async {
    try {
      final labTopic = 'lab_${widget.laboratory.id}';
      final testsSummary = _selectedTests.join(' - ');

      // حفظ الإشعار في Firestore ليتم إرساله عبر Cloud Functions
      await FirebaseFirestore.instance.collection('topic_notifications').add({
        'topic': labTopic,
        'title': 'حجز جديد',
        'body':
            'تم استلام حجز جديد رقم $bookingNumber من ${_nameController.text.trim()}\nالتحاليل: $testsSummary',
        'data': {
          'type': 'new_lab_booking',
          'laboratoryId': widget.laboratory.id,
          'bookingId': bookingId,
          'bookingNumber': bookingNumber,
          'testTypes': _selectedTests,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      print('✅ Notification queued for lab topic: $labTopic');
    } catch (e) {
      print('❌ Error sending notification: $e');
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
                  width: 82,
                  height: 82,
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
                    size: 48,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'تم الحجز بنجاح',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF134E4A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'احتفظ برقم الحجز لاستخدامه عند المتابعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$bookingNumber',
                          style: const TextStyle(
                            fontSize: 34,
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
          'lab_booking_${bookingNumber}_${DateTime.now().millisecondsSinceEpoch}';

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

  InputDecoration _inputDecoration({
    required String hint,
    IconData? suffixIcon,
    String? label,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
      ),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
        borderSide: const BorderSide(color: _primaryColor, width: 1.3),
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
            color: _primaryColor,
          ),
        ),
        title: const Text(
          'حجز موعد التحاليل',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F5F4), Color(0xFFEDF4F3)],
          ),
        ),
        child: RepaintBoundary(
          key: _screenCaptureKey,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                              gradient: const LinearGradient(
                                colors: [_primaryColor, _primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.science_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'المعمل المختار',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.laboratory.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'بيانات المريض',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name field
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _inputDecoration(
                                label: 'الاسم',
                                hint: 'الاسم كما هو في البطاقة',
                                suffixIcon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'من فضلك أدخل الاسم';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _inputDecoration(
                                label: 'رقم الهاتف',
                                hint: '+20 1X XXX XXXX',
                                suffixIcon: Icons.call_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'من فضلك أدخل رقم الهاتف';
                                }
                                if (value.trim().length < 11) {
                                  return 'رقم الهاتف يجب أن يكون 11 رقماً على الأقل';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Test Type Dropdown
                            const Text(
                              'التحاليل المطلوبة *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_selectedTests.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedTests
                                    .map(
                                      (test) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6FFFA),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF99F6E4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.science_outlined,
                                              size: 14,
                                              color: _primaryColor,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              test,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: _primaryColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedTests.remove(test);
                                                });
                                              },
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Color(0xFF0F766E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (!_isCustomTest)
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedTest,
                                        decoration: const InputDecoration(
                                          suffixIcon: Icon(
                                            Icons.science,
                                            size: 18,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 13,
                                          ),
                                          hintText: 'اختر تحليل لإضافته',
                                          hintStyle: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF111827),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        items: [
                                          ...widget.laboratory.availableTests
                                              .map((test) {
                                                return DropdownMenuItem(
                                                  value: test,
                                                  child: Text(test),
                                                );
                                              }),
                                          const DropdownMenuItem(
                                            value: '__custom__',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                  color: Colors.orange,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'أخرى (كتابة يدوية)',
                                                  style: TextStyle(
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value == '__custom__') {
                                            setState(() {
                                              _isCustomTest = true;
                                              _selectedTest = null;
                                            });
                                          } else {
                                            setState(
                                              () => _selectedTest = value,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: _selectedTest == null
                                          ? null
                                          : () => _addSelectedTest(
                                              _selectedTest!,
                                            ),
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.add,
                                          color: _selectedTest == null
                                              ? Colors.white54
                                              : Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  TextFormField(
                                    controller: _customTestController,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'نوع التحليل',
                                      hint:
                                          'مثل: تحليل هرمونات، فيتامينات، إلخ',
                                      suffixIcon: Icons.science,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            final custom = _customTestController
                                                .text
                                                .trim();
                                            if (custom.isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'من فضلك أدخل نوع التحليل',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                              return;
                                            }
                                            _addSelectedTest(custom);
                                          },
                                          icon: const Icon(Icons.add, size: 17),
                                          label: const Text('إضافة التحليل'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _primaryColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _isCustomTest = false;
                                            _customTestController.clear();
                                          });
                                        },
                                        icon: const Icon(Icons.arrow_back),
                                        label: const Text('العودة'),
                                      ),
                                    ],
                                  ),
                                  if (_selectedTests.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'يمكنك إضافة أكثر من تحليل ثم تأكيد الحجز',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            const SizedBox(height: 16),

                            // Service Type selector
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'نوع الخدمة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setState(
                                            () => _serviceType = 'lab',
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _serviceType == 'lab'
                                                  ? _primaryColor
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _serviceType == 'lab'
                                                    ? _primaryColor
                                                    : const Color(0xFFD1D5DB),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.location_city,
                                                  color: _serviceType == 'lab'
                                                      ? Colors.white
                                                      : const Color(0xFF475569),
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'في المعمل',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: _serviceType == 'lab'
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF475569,
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setState(
                                            () => _serviceType = 'home',
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _serviceType == 'home'
                                                  ? _primaryColor
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _serviceType == 'home'
                                                    ? _primaryColor
                                                    : const Color(0xFFD1D5DB),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.home,
                                                  color: _serviceType == 'home'
                                                      ? Colors.white
                                                      : const Color(0xFF475569),
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'من البيت',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        _serviceType == 'home'
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF475569,
                                                          ),
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
                            const SizedBox(height: 16),

                            // Notes field
                            TextFormField(
                              controller: _notesController,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _inputDecoration(
                                label: 'ملاحظات (اختياري)',
                                hint: 'اكتب أي تفاصيل أو استفسار تحب تضيفه...',
                                suffixIcon: Icons.note_outlined,
                              ),
                              maxLines: 3,
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
                                border: Border.all(
                                  color: const Color(0xFFFCD9BD),
                                ),
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

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _submitBooking,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: AppLoadingIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'تأكيد الحجز',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
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
          ),
        ),
      ),
    );
  }
}
