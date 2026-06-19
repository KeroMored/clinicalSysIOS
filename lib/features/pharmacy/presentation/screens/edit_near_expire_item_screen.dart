import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/near_expire_item_model.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class EditNearExpireItemScreen extends StatefulWidget {
  final NearExpireItemModel item;

  const EditNearExpireItemScreen({super.key, required this.item});

  @override
  State<EditNearExpireItemScreen> createState() =>
      _EditNearExpireItemScreenState();
}

class _EditNearExpireItemScreenState extends State<EditNearExpireItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _medicineNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _customTypeController;

  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  int? _selectedYear;
  int? _selectedMonth;
  String? _selectedType;
  bool _isCustomType = false;

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
  void initState() {
    super.initState();
    _medicineNameController = TextEditingController(
      text: widget.item.medicineName,
    );
    _descriptionController = TextEditingController(
      text: widget.item.medicineDescription ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _totalPriceController = TextEditingController(
      text: widget.item.totalPrice?.toString() ?? '',
    );
    _customTypeController = TextEditingController();

    _currentImageUrl = widget.item.imageUrl;
    _selectedYear = widget.item.expiryDate.year;
    _selectedMonth = widget.item.expiryDate.month;

    if (_medicineTypes.contains(widget.item.medicineType)) {
      _selectedType = widget.item.medicineType;
    } else {
      _isCustomType = true;
      _customTypeController.text = widget.item.medicineType;
    }
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
    if (_selectedImage == null) return _currentImageUrl;

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
      return _currentImageUrl;
    }
  }

  Future<void> _updateItem() async {
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

    if (_selectedType == null && !_isCustomType) {
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
      final imageUrl = await _uploadImage();
      final expiryDate = DateTime(_selectedYear!, _selectedMonth!, 1);
      final finalType = _isCustomType
          ? _customTypeController.text.trim()
          : _selectedType!;
      final totalPrice = _totalPriceController.text.trim().isEmpty
          ? null
          : double.parse(_totalPriceController.text.trim());

      await FirebaseFirestore.instance
          .collection('near_expire_items')
          .doc(widget.item.id)
          .update({
            'medicineName': _medicineNameController.text.trim(),
            'medicineType': finalType,
            'medicineDescription': _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            'expiryDate': Timestamp.fromDate(expiryDate),
            'quantity': int.parse(_quantityController.text.trim()),
            'totalPrice': totalPrice,
            'imageUrl': imageUrl,
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المنتج بنجاح'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'تعديل المنتج',
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
            const Text(
              'معلومات المنتج',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : _currentImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط لتغيير الصورة',
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
                  return DropdownMenuItem(value: type, child: Text(type));
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
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'مطلوب' : null,
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

            // تاريخ الانتهاء
            const Text(
              'تاريخ الانتهاء *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'السنة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: List.generate(3, (index) {
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
                    onChanged: (value) =>
                        setState(() => _selectedMonth = value),
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

            // السعر الكلي
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

            // زر التحديث
            SizedBox(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateItem,
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
                        child: AppLoadingIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'تحديث المنتج',
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
