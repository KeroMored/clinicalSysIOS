import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/pharmacy_model.dart';

class AddNearExpireItemScreen extends StatefulWidget {
  final PharmacyModel pharmacy;
  final String userId;

  const AddNearExpireItemScreen({
    super.key,
    required this.pharmacy,
    required this.userId,
  });

  @override
  State<AddNearExpireItemScreen> createState() => _AddNearExpireItemScreenState();
}

class _AddNearExpireItemScreenState extends State<AddNearExpireItemScreen> {
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
      final fileName = 'near_expire_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      final docRef = await FirebaseFirestore.instance.collection('near_expire_items').add({
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

      // إرسال إشعار لجميع الصيدليات
      await _sendNotificationToPharmacies(docRef.id);

      if (mounted) {
        Navigator.pop(context);
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
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendNotificationToPharmacies(String itemId) async {
    try {
      // إرسال إشعار عبر topic للصيدليات
      await FirebaseFirestore.instance.collection('topic_notifications').add({
        'topic': 'all_pharmacies',
        'title': 'منتج قارب على الانتهاء',
        'body': '${widget.pharmacy.name} عرضت ${_medicineNameController.text.trim()} قارب على الانتهاء',
        'data': {
          'type': 'near_expire_item',
          'itemId': itemId,
          'pharmacyId': widget.pharmacy.id,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'إضافة منتج قارب على الانتهاء',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00BCD4),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // معلومات المنتج
            const Text(
              'معلومات المنتج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // صورة المنتج
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط لإضافة صورة المنتج (اختياري)',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // اسم الدواء
            TextFormField(
              controller: _medicineNameController,
              decoration: const InputDecoration(
                labelText: 'اسم الدواء *',
                prefixIcon: Icon(Icons.medical_services),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),

            // الوصف
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // نوع الدواء
            if (!_isCustomType)
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'نوع الدواء *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
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
                    decoration: const InputDecoration(
                      labelText: 'اكتب نوع الدواء *',
                      prefixIcon: Icon(Icons.edit),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isCustomType = false;
                        _customTypeController.clear();
                      });
                    },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('العودة للقائمة'),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // تاريخ الانتهاء - السنة والشهر
            const Text(
              'تاريخ الانتهاء *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // السنة
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'السنة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: List.generate(4, (index) {
                      final year = DateTime.now().year + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }),
                    onChanged: (value) => setState(() => _selectedYear = value),
                  ),
                ),
                const SizedBox(width: 12),
                // الشهر
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'الشهر',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event),
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
                      DropdownMenuItem(value: 10, child: Text('أكتوبر')),
                      DropdownMenuItem(value: 11, child: Text('نوفمبر')),
                      DropdownMenuItem(value: 12, child: Text('ديسمبر')),
                    ],
                    onChanged: (value) => setState(() => _selectedMonth = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // الكمية
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'الكمية المتاحة *',
                prefixIcon: Icon(Icons.inventory),
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),

            // السعر الكلي (اختياري)
            TextFormField(
              controller: _totalPriceController,
              decoration: const InputDecoration(
                labelText: 'السعر الكلي (اختياري)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                suffixText: 'جنيه',
                helperText: 'إذا لم يتم تحديده سيظهر "غير محدد"',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v) == null) return 'أدخل رقم صحيح';
                if (double.parse(v) <= 0) return 'يجب أن يكون أكبر من صفر';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // زر الإرسال
            SizedBox(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'نشر المنتج',
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
    );
  }
}
