import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/laboratory_model.dart';
import '../../data/models/lab_booking_model.dart';

class LabBookingScreen extends StatefulWidget {
  final LaboratoryModel laboratory;

  const LabBookingScreen({super.key, required this.laboratory});

  @override
  State<LabBookingScreen> createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends State<LabBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _customTestController = TextEditingController();
  
  String? _selectedTest;
  String _serviceType = 'lab'; // القيمة الافتراضية: في المعمل
  bool _isSubmitting = false;
  bool _isCustomTest = false;

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
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
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

    // التحقق من اختيار نوع التحليل
    if (!_isCustomTest && _selectedTest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اختر نوع التحليل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isCustomTest && _customTestController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك أدخل نوع التحليل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bookingNumber = await _getNextBookingNumber();
      final testType = _isCustomTest 
          ? _customTestController.text.trim() 
          : _selectedTest!;
      
      final booking = LabBookingModel(
        id: '',
        patientName: _nameController.text.trim(),
        patientPhone: _phoneController.text.trim(),
        laboratoryId: widget.laboratory.id,
        laboratoryName: widget.laboratory.name,
        bookingNumber: bookingNumber,
        status: LabBookingStatus.pending,
        createdAt: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        isOnlineBooking: true, // حجز أونلاين من المريض
        testType: testType,
        serviceType: _serviceType,
      );

      // حفظ الحجز
      final docRef = await FirebaseFirestore.instance
          .collection('lab_bookings')
          .add(booking.toFirestore());

      // إرسال إشعار للمعمل عبر Firebase Topic
      await _sendLabNotification(bookingNumber, docRef.id);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(bookingNumber);
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendLabNotification(int bookingNumber, String bookingId) async {
    try {
      final labTopic = 'lab_${widget.laboratory.id}';
      
      // حفظ الإشعار في Firestore ليتم إرساله عبر Cloud Functions
      await FirebaseFirestore.instance.collection('topic_notifications').add({
        'topic': labTopic,
        'title': 'حجز جديد',
        'body': 'تم استلام حجز جديد رقم $bookingNumber من ${_nameController.text.trim()}',
        'data': {
          'type': 'new_lab_booking',
          'laboratoryId': widget.laboratory.id,
          'bookingId': bookingId,
          'bookingNumber': bookingNumber,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تم الحجز بنجاح!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF00BCD4),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'رقم الحجز',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$bookingNumber',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00BCD4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'تم',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('احجز الآن'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              // Header with lab info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.laboratory.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.laboratory.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'بيانات المريض',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'الاسم',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
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
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.phone,
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
                        'نوع التحليل *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_isCustomTest)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedTest,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.science),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              hintText: 'اختر نوع التحليل',
                            ),
                            items: [
                              ...widget.laboratory.availableTests.map((test) {
                                return DropdownMenuItem(
                                  value: test,
                                  child: Text(test),
                                );
                              }),
                              const DropdownMenuItem(
                                value: '__custom__',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18, color: Colors.orange),
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
                                setState(() => _selectedTest = value);
                              }
                            },
                          ),
                        )
                      else
                        Column(
                          children: [
                            TextFormField(
                              controller: _customTestController,
                              decoration: InputDecoration(
                                labelText: 'اكتب نوع التحليل',
                                hintText: 'مثل: تحليل هرمونات، فيتامينات، إلخ',
                                prefixIcon: const Icon(Icons.science),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (_isCustomTest && (value == null || value.trim().isEmpty)) {
                                  return 'من فضلك أدخل نوع التحليل';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isCustomTest = false;
                                  _customTestController.clear();
                                });
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('العودة للقائمة'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Service Type selector
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'نوع الخدمة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _serviceType = 'lab'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _serviceType == 'lab' 
                                            ? const Color(0xFF00BCD4)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _serviceType == 'lab'
                                              ? const Color(0xFF00BCD4)
                                              : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.location_city,
                                            color: _serviceType == 'lab' 
                                                ? Colors.white 
                                                : Colors.grey[700],
                                            size: 30,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'في المعمل',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: _serviceType == 'lab' 
                                                  ? Colors.white 
                                                  : Colors.grey[700],
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
                                    onTap: () => setState(() => _serviceType = 'home'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _serviceType == 'home' 
                                            ? const Color(0xFF00BCD4)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _serviceType == 'home'
                                              ? const Color(0xFF00BCD4)
                                              : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.home,
                                            color: _serviceType == 'home' 
                                                ? Colors.white 
                                                : Colors.grey[700],
                                            size: 30,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'من البيت',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: _serviceType == 'home' 
                                                  ? Colors.white 
                                                  : Colors.grey[700],
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
                        decoration: InputDecoration(
                          labelText: 'ملاحظات (اختياري)',
                          hintText: 'أدخل أي ملاحظات أو تفاصيل إضافية',
                          prefixIcon: const Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'تأكيد الحجز',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
    );
  }
}
