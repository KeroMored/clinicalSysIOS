import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class AddDeliveryScreen extends StatefulWidget {
  const AddDeliveryScreen({super.key});

  @override
  State<AddDeliveryScreen> createState() => _AddDeliveryScreenState();
}

class _AddDeliveryScreenState extends State<AddDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _deliveryNameController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [
    TextEditingController(),
  ];
  final _deliveryWhatsappController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _deliveryNameController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _deliveryWhatsappController.dispose();
    super.dispose();
  }

  void _addPhoneField() {
    setState(() {
      _phoneControllers.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    if (_phoneControllers.length > 1) {
      setState(() {
        _phoneControllers[index].dispose();
        _phoneControllers.removeAt(index);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create delivery document directly in Firestore
      final deliveryRef = FirebaseFirestore.instance
          .collection('deliveries')
          .doc();

      final deliveryData = {
        'id': deliveryRef.id,
        'deliveryName': _deliveryNameController.text.trim(),
        'deliveryPhones': _phoneControllers
            .map((controller) => controller.text.trim())
            .where((phone) => phone.isNotEmpty)
            .toList(),
        'deliveryWhatsApp': _deliveryWhatsappController.text.trim(),
        'governorate': 'المنيا',
        'city': 'ملوي',
        'center': 'ملوي',
        'availableNow': false,
        'isApproved': false,
        'isActive': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'reviewCount': 0,
        'completedDeliveries': 0,
        'notes': 'تمت الإضافة من قبل الأدمن - في انتظار الموافقة',
        'averageRating': 0.0,
        'totalRatings': 0,
        'likesCount': 0,
      };

      await deliveryRef.set(deliveryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة الديليفري بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة الديليفري: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
        title: const Text(
          'إضافة ديليفري جديد',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF06B6D4),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المعلومات الأساسية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                      const Divider(height: 24),

                      // Delivery Name
                      TextFormField(
                        controller: _deliveryNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الديليفري',
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Color(0xFF06B6D4),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال اسم الديليفري';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Numbers (Multiple)
                      ...List.generate(_phoneControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'رقم الهاتف ${index + 1}',
                                    prefixIcon: const Icon(
                                      Icons.phone,
                                      color: Color(0xFF06B6D4),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (index == 0 &&
                                        (value == null || value.isEmpty)) {
                                      return 'يرجى إدخال رقم هاتف واحد على الأقل';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (index == _phoneControllers.length - 1)
                                IconButton(
                                  onPressed: _addPhoneField,
                                  icon: const Icon(Icons.add_circle),
                                  color: const Color(0xFF06B6D4),
                                  tooltip: 'إضافة رقم آخر',
                                ),
                              if (index > 0)
                                IconButton(
                                  onPressed: () => _removePhoneField(index),
                                  icon: const Icon(Icons.remove_circle),
                                  color: Colors.red,
                                  tooltip: 'حذف',
                                ),
                            ],
                          ),
                        );
                      }),

                      // WhatsApp Number
                      TextFormField(
                        controller: _deliveryWhatsappController,
                        decoration: InputDecoration(
                          labelText: 'رقم الواتساب',
                          prefixIcon: Icon(
                            Icons.chat,
                            color: Color(0xFF25D366),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال رقم الواتساب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Note about location
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF06B6D4).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF06B6D4),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'الموقع: المنيا - ملوي',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: AppLoadingIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'إضافة الديليفري',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
