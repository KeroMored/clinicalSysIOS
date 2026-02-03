import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/laboratory_model.dart';
import '../../data/models/lab_booking_model.dart';

/// شاشة إضافة حجز من المعمل نفسه (للموظفين)
class AddLabBookingScreen extends StatefulWidget {
  final LaboratoryModel laboratory;

  const AddLabBookingScreen({super.key, required this.laboratory});

  @override
  State<AddLabBookingScreen> createState() => _AddLabBookingScreenState();
}

class _AddLabBookingScreenState extends State<AddLabBookingScreen> {
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

    final snapshot = await FirebaseFirestore.instance
        .collection('lab_bookings')
        .where('laboratoryId', isEqualTo: widget.laboratory.id)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (snapshot.docs.isEmpty) {
      return 1;
    }

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
        isOnlineBooking: false, // حجز من المعمل
        testType: testType,
        serviceType: _serviceType,
      );

      await FirebaseFirestore.instance
          .collection('lab_bookings')
          .add(booking.toFirestore());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة الحجز رقم $bookingNumber بنجاح'),
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز جديد'),
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
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science, color: Colors.white, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.laboratory.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'إضافة حجز يدوي',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                    labelText: 'اسم المريض *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'من فضلك أدخل اسم المريض';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف *',
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
                const SizedBox(height: 24),

                const Text(
                  'نوع التحليل *',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Test Type Dropdown
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
                const SizedBox(height: 24),

                // Service Type selector
                const Text(
                  'نوع الخدمة *',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _serviceType = 'lab'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'في المعمل',
                                  style: TextStyle(
                                    fontSize: 15,
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _serviceType = 'home'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'من البيت',
                                  style: TextStyle(
                                    fontSize: 15,
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
                ),
                const SizedBox(height: 24),

                // Notes field
                const Text(
                  'ملاحظات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'أدخل أي ملاحظات أو تفاصيل إضافية (اختياري)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 54,
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
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'إضافة الحجز',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
  }
}
