import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/pharmacy_model.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class EditNearExpireItemScreen extends StatefulWidget {
  final PharmacyModel pharmacy;
  final String userId;
  final String itemId;
  final Map<String, dynamic> itemData;

  const EditNearExpireItemScreen({
    super.key,
    required this.pharmacy,
    required this.userId,
    required this.itemId,
    required this.itemData,
  });

  @override
  State<EditNearExpireItemScreen> createState() =>
      _EditNearExpireItemScreenState();
}

class _EditNearExpireItemScreenState extends State<EditNearExpireItemScreen> {
  static const Color _primary = Color(0xFF0B8293);
  static const Color _bg = Color(0xFFF4F6F8);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _medicineNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _customTypeController;

  File? _selectedImage;
  String? _existingImageUrl;
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
    
    // Pre-fill data
    _medicineNameController = TextEditingController(
      text: widget.itemData['medicineName'] as String? ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.itemData['description'] as String? ?? '',
    );
    _quantityController = TextEditingController(
      text: (widget.itemData['quantity'] as int? ?? 0).toString(),
    );
    _totalPriceController = TextEditingController(
      text: (widget.itemData['totalPrice'] as num? ?? 0).toString(),
    );
    _customTypeController = TextEditingController();
    
    _existingImageUrl = widget.itemData['imageUrl'] as String?;
    _selectedType = widget.itemData['medicineType'] as String?;
    _selectedYear = widget.itemData['expiryYear'] as int?;
    _selectedMonth = widget.itemData['expiryMonth'] as int?;
    
    // Check if custom type
    if (_selectedType != null && !_medicineTypes.contains(_selectedType)) {
      _isCustomType = true;
      _customTypeController.text = _selectedType!;
      _selectedType = 'أخرى';
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

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: Icon(icon, color: _primary, size: 20),
      suffixText: suffixText,
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
    if (_selectedImage == null) return _existingImageUrl;

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
      return _existingImageUrl;
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedYear == null || _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اختر تاريخ الانتهاء'),
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

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImage();
      
      final finalType = _isCustomType
          ? _customTypeController.text.trim()
          : _selectedType!;

      final totalPrice = _totalPriceController.text.trim().isEmpty
          ? null
          : double.parse(_totalPriceController.text.trim());

      await FirebaseFirestore.instance
          .collection('near_expire_items')
          .doc(widget.itemId)
          .update({
        'medicineName': _medicineNameController.text.trim(),
        'medicineType': finalType,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'expiryYear': _selectedYear,
        'expiryMonth': _selectedMonth,
        'quantity': int.parse(_quantityController.text.trim()),
        'totalPrice': totalPrice,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'تعديل منتج قرب ينتهي',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 40, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('اضغط لتغيير الصورة',
                                    style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),

              // Medicine Name
              TextFormField(
                controller: _medicineNameController,
                decoration: _fieldDecoration(
                  label: 'اسم الدواء',
                  icon: Icons.medication_rounded,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 14),

              // Medicine Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: _fieldDecoration(
                  label: 'نوع الدواء',
                  icon: Icons.category_rounded,
                ),
                items: _medicineTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _isCustomType = value == 'أخرى';
                  });
                },
                validator: (v) => v == null ? 'اختر نوع الدواء' : null,
              ),
              const SizedBox(height: 14),

              if (_isCustomType)
                TextFormField(
                  controller: _customTypeController,
                  decoration: _fieldDecoration(
                    label: 'حدد النوع',
                    icon: Icons.edit,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              if (_isCustomType) const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: _fieldDecoration(
                  label: 'الوصف (اختياري)',
                  icon: Icons.description_rounded,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: _fieldDecoration(
                  label: 'الكمية',
                  icon: Icons.inventory_2_outlined,
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  if (int.tryParse(v) == null) return 'رقم غير صحيح';
                  if (int.parse(v) <= 0) return 'يجب أن يكون أكبر من صفر';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Total Price
              TextFormField(
                controller: _totalPriceController,
                decoration: _fieldDecoration(
                  label: 'السعر الإجمالي (اختياري)',
                  icon: Icons.payments_outlined,
                  suffixText: 'ج.م',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),

              // Expiry Year
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: _fieldDecoration(
                  label: 'سنة الانتهاء',
                  icon: Icons.calendar_today,
                ),
                items: List.generate(5, (i) {
                  final year = DateTime.now().year + i;
                  return DropdownMenuItem(value: year, child: Text('$year'));
                }).toList(),
                onChanged: (value) => setState(() => _selectedYear = value),
                validator: (v) => v == null ? 'اختر السنة' : null,
              ),
              const SizedBox(height: 14),

              // Expiry Month
              DropdownButtonFormField<int>(
                value: _selectedMonth,
                decoration: _fieldDecoration(
                  label: 'شهر الانتهاء',
                  icon: Icons.calendar_month,
                ),
                items: List.generate(12, (i) {
                  final monthNames = [
                    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
                    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
                  ];
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(monthNames[i]),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedMonth = value),
                validator: (v) => v == null ? 'اختر الشهر' : null,
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateItem,
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
                          'حفظ التعديلات',
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
      ),
    );
  }
}
