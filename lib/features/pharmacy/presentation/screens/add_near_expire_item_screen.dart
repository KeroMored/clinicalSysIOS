import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/pharmacy_model.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class AddNearExpireItemScreen extends StatefulWidget {
  final PharmacyModel pharmacy;
  final String userId;

  const AddNearExpireItemScreen({
    super.key,
    required this.pharmacy,
    required this.userId,
  });

  @override
  State<AddNearExpireItemScreen> createState() =>
      _AddNearExpireItemScreenState();
}

class _AddNearExpireItemScreenState extends State<AddNearExpireItemScreen> {
  static const Color _primary = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0A6F7C);
  static const Color _bg = Color(0xFFF4F6F8);

  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _customTypeController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  int? _selectedYear;
  int? _selectedMonth;
  String? _selectedType;
  bool _isCustomType = false;

  // قائمة أنواع الأدوية
  final List<String> _medicineTypes = [
    'أقراص',
    'شراب',
    'كبسولات',
    'حقن',
    'مرهم',
    'قطرة',
    'بخاخ',
    'لبوس',
    'أخرى',
  ];

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? suffixText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: Icon(icon, color: _primary, size: 20),
      suffixText: suffixText,
      helperText: helperText,
      helperStyle: const TextStyle(fontSize: 11),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primary, width: 1.6),
      ),
    );
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _totalPriceController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final fileName =
          'near_expire_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('near_expire_items')
          .child(fileName);

      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedYear == null || _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اختر تاريخ الانتهاء (السنة والشهر)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اختر نوع الدواء'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isCustomType && _customTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك أدخل نوع الدواء'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // رفع الصورة إن وجدت
      final imageUrl = await _uploadImage();

      // تحديد تاريخ الانتهاء (أول يوم من الشهر المحدد)
      final expiryDate = DateTime(_selectedYear!, _selectedMonth!, 1);

      // تحديد النوع النهائي
      final finalType = _isCustomType
          ? _customTypeController.text.trim()
          : _selectedType!;

      // حساب السعر (null إذا لم يتم إدخاله)
      final totalPrice = _totalPriceController.text.trim().isEmpty
          ? null
          : double.parse(_totalPriceController.text.trim());

      // إنشاء المستند
      final docRef = await FirebaseFirestore.instance
          .collection('near_expire_items')
          .add({
            'pharmacyId': widget.pharmacy.id,
            'pharmacyName': widget.pharmacy.name,
            'pharmacyAddress': widget.pharmacy.address,
            'pharmacyPhones': widget.pharmacy.phones,
            'pharmacyWhatsapp': widget.pharmacy.whatsapp,
            'medicineName': _medicineNameController.text.trim(),
            'medicineType': finalType,
            'medicineDescription': _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            'expiryDate': Timestamp.fromDate(expiryDate),
            'quantity': int.parse(_quantityController.text.trim()),
            'totalPrice': totalPrice,
            'imageUrl': imageUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'userId': widget.userId,
          });

      // ✅ إرسال notification للصيدليات (نفس طريقة طلبات الأدوية)
      await _sendNotificationToPharmacies(docRef.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المنتج بنجاح'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ إرسال notification للصيدليات (نفس طريقة medicine_requests)
  Future<void> _sendNotificationToPharmacies(String itemId) async {
    try {
      // استخدام نفس topic الصيدليات (pharmacy_requests)
      await FirebaseFirestore.instance.collection('pending_notifications').add({
        'topic': 'pharmacy_requests', // نفس topic طلبات الأدوية
        'title': '💊 دواء قارب على الانتهاء',
        'body':
            '${widget.pharmacy.name} عرضت ${_medicineNameController.text.trim()} قارب على الانتهاء',
        'data': {
          'type': 'near_expire_item',
          'itemId': itemId,
          'pharmacyId': widget.pharmacy.id,
          'pharmacyName': widget.pharmacy.name,
          'medicineName': _medicineNameController.text.trim(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      print('خطأ في إرسال الإشعار: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primary, size: 20),
        title: const Text(
          'إضافة منتج قارب على الانتهاء',
          style: TextStyle(
            color: _primary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F6F8), Color(0xFFF1F5F9)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات المنتج',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 170,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: _selectedImage == null
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      _primary.withOpacity(0.08),
                                      _primary.withOpacity(0.03),
                                    ],
                                  )
                                : null,
                            color: _selectedImage == null ? null : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _primary.withOpacity(0.25),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _selectedImage != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.45),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_rounded,
                                              color: Colors.white,
                                              size: 13,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'تغيير الصورة',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: _primary.withOpacity(0.14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo_rounded,
                                        size: 28,
                                        color: _primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'إضافة صورة المنتج (اختياري)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'اضغط للاختيار من المعرض',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _medicineNameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _fieldDecoration(
                        label: 'اسم الدواء *',
                        icon: Icons.medical_services,
                      ),
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _fieldDecoration(
                        label: 'الوصف (اختياري)',
                        icon: Icons.description,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    if (!_isCustomType)
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _primaryDark,
                        ),
                        decoration: _fieldDecoration(
                          label: 'نوع الدواء *',
                          icon: Icons.category,
                        ),
                        items: _medicineTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == 'أخرى') {
                            setState(() {
                              _isCustomType = true;
                              _selectedType = null;
                            });
                          } else {
                            setState(() => _selectedType = value);
                          }
                        },
                      )
                    else
                      Column(
                        children: [
                          TextFormField(
                            controller: _customTypeController,
                            style: const TextStyle(fontSize: 13),
                            decoration: _fieldDecoration(
                              label: 'اكتب نوع الدواء *',
                              icon: Icons.edit,
                            ),
                            validator: (v) =>
                                v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isCustomType = false;
                                  _customTypeController.clear();
                                });
                              },
                              icon: const Icon(Icons.arrow_back, size: 15),
                              label: const Text(
                                'العودة للقائمة',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تفاصيل الانتهاء والكمية',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _primaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _primaryDark,
                            ),
                            decoration: _fieldDecoration(
                              label: 'السنة',
                              icon: Icons.calendar_today,
                            ),
                            items: List.generate(4, (index) {
                              final year = DateTime.now().year + index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              );
                            }),
                            onChanged: (value) =>
                                setState(() => _selectedYear = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _primaryDark,
                            ),
                            decoration: _fieldDecoration(
                              label: 'الشهر',
                              icon: Icons.event,
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('يناير')),
                              DropdownMenuItem(value: 2, child: Text('فبراير')),
                              DropdownMenuItem(value: 3, child: Text('مارس')),
                              DropdownMenuItem(value: 4, child: Text('أبريل')),
                              DropdownMenuItem(value: 5, child: Text('مايو')),
                              DropdownMenuItem(value: 6, child: Text('يونيو')),
                              DropdownMenuItem(value: 7, child: Text('يوليو')),
                              DropdownMenuItem(value: 8, child: Text('أغسطس')),
                              DropdownMenuItem(value: 9, child: Text('سبتمبر')),
                              DropdownMenuItem(
                                value: 10,
                                child: Text('أكتوبر'),
                              ),
                              DropdownMenuItem(
                                value: 11,
                                child: Text('نوفمبر'),
                              ),
                              DropdownMenuItem(
                                value: 12,
                                child: Text('ديسمبر'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedMonth = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _fieldDecoration(
                        label: 'الكمية المتاحة *',
                        icon: Icons.inventory,
                        suffixText: 'عبوة',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true) return 'مطلوب';
                        if (int.tryParse(v!) == null) return 'أدخل رقم صحيح';
                        if (int.parse(v) <= 0) return 'يجب أن يكون أكبر من صفر';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _totalPriceController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _fieldDecoration(
                        label: 'السعر الكلي (اختياري)',
                        icon: Icons.attach_money,
                        suffixText: 'جنيه',
                        helperText: 'إذا لم يتم تحديده سيظهر "غير محدد"',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (double.tryParse(v) == null) return 'أدخل رقم صحيح';
                        if (double.parse(v) <= 0) {
                          return 'يجب أن يكون أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: AppLoadingIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'نشر المنتج',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
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
    );
  }
}
