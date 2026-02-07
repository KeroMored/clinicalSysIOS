import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/clinic_model.dart';
import '../../data/models/booking_model.dart';

class BookAppointmentScreen extends StatefulWidget {
  final ClinicModel clinic;

  const BookAppointmentScreen({super.key, required this.clinic});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  DateTime _selectedAppointmentDate = DateTime.now(); // الافتراضي: الآن

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          final userData = userDoc.data();
          if (userData != null) {
            if (userData['displayName'] != null) {
              _nameController.text = userData['displayName'];
            }
            if (userData['phoneNumber'] != null && userData['phoneNumber'].toString().isNotEmpty) {
              _phoneController.text = userData['phoneNumber'];
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - not critical
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
    final startOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
    final endOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day, 23, 59, 59);

    // جلب كل الحجوزات في نفس يوم الموعد
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinic.id)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (snapshot.docs.isEmpty) {
      return 1;
    }

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

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final bookingNumber = await _getNextBookingNumber(_selectedAppointmentDate);
      
      final booking = BookingModel(
        id: '',
        patientName: _nameController.text.trim(),
        patientPhone: _phoneController.text.trim(),
        clinicId: widget.clinic.id,
        doctorName: widget.clinic.doctorName,
        bookingNumber: bookingNumber,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        appointmentDate: _selectedAppointmentDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        isOnlineBooking: true, // حجز أونلاين من المريض
      );

      await FirebaseFirestore.instance
          .collection('bookings')
          .add(booking.toFirestore());

      // Save phone number to user profile if not already saved
      final user = FirebaseAuth.instance.currentUser;
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
                (userData?['phoneNumber'] == null || userData!['phoneNumber'].toString() != phoneNumber)) {
              updates['phoneNumber'] = phoneNumber;
            }
            
            if (userName.isNotEmpty && 
                (userData?['displayName'] == null || userData!['displayName'].toString() != userName)) {
              updates['displayName'] = userName;
            }
            
            if (updates.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update(updates);
            }
          }
        } catch (e) {
          // Silently fail - not critical
        }
      }

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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF3B82F6),
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
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // const Text(
              //   'سيتم التواصل معك قريباً لتأكيد موعدك',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     fontSize: 14,
              //     color: Colors.grey,
              //   ),
              // ),
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
                  backgroundColor: const Color(0xFF3B82F6),
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
        title: const Text('احجز موعد'),
        elevation: 0,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
          children: [
            // Header with clinic info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
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
                      Icons.medical_services_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.clinic.doctorName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.clinic.specialization,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.clinic.address,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات المريض',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        hintText: 'أدخل اسمك الكامل',
                        prefixIcon: const Icon(Icons.person_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
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
                    const SizedBox(height: 16),
                    
                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        hintText: '01xxxxxxxxx',
                        prefixIcon: const Icon(Icons.phone_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
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
                    const SizedBox(height: 16),
                    
                    // اختيار موعد الكشف
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'موعد الكشف',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedAppointmentDate,
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
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range, color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${_selectedAppointmentDate.day}/${_selectedAppointmentDate.month}/${_selectedAppointmentDate.year}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Notes field
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        hintText: 'أي ملاحظات إضافية...',
                        prefixIcon: const Icon(Icons.note_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // // Info box
                    // Container(
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: Colors.blue[50],
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(color: Colors.blue[200]!),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Icon(Icons.info_rounded, color: Colors.blue[700]),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: Text(
                    //           'سيتم تأكيد حجزك من قبل العيادة وإرسال رقم الحجز لك',
                    //           style: TextStyle(
                    //             fontSize: 13,
                    //             color: Colors.blue[900],
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'تأكيد الحجز',
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
          ],
        ),
      ),
      ),
    );
  }
}
