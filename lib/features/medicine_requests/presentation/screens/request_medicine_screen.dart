import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../core/utils/auth_helpers.dart';

// Simple model to hold one medicine entry in the UI
class _MedicineEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  String? type;
  String? unit;
  File? image;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineName': nameController.text.trim(),
      'medicineType': type,
      'quantityUnit': unit,
      'quantity': int.tryParse(quantityController.text.trim()) ?? 1,
      'imageUrl': null, // filled during upload
    };
  }
}

class RequestMedicineScreen extends StatefulWidget {
  const RequestMedicineScreen({super.key});

  @override
  State<RequestMedicineScreen> createState() => _RequestMedicineScreenState();
}

class _RequestMedicineScreenState extends State<RequestMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  // Support multiple medicines in one request
  final List<_MedicineEntry> _medicines = [];
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _notesController = TextEditingController();
  
  // per-entry images are stored inside each _MedicineEntry
  bool _isSubmitting = false;
  
  final List<String> _medicineTypes = [
    'أقراص',
    'كبسولات',
    'شراب',
    'حقن',
    'لبوس',
    'مرهم/كريم',
    'قطرة',
    'بخاخ',
    'ألبان',
  ];
  
  final Map<String, List<String>> _unitsByType = {
    'أقراص': ['علب', 'شرائط'],
    'كبسولات': ['علب', 'شرائط'],
    'حقن': ['علب', 'أمبولات'],
    'لبوس': ['علب', 'شرائط'],
  };

  @override
  void initState() {
    super.initState();
    // Start with one empty medicine entry
    _addMedicineEntry();
  }

  @override
  void dispose() {
    for (final entry in _medicines) {
      entry.dispose();
    }
    _phoneController.dispose();
    _whatsappController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImageForEntry(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _medicines[index].image = File(image.path);
      });
    }
  }

  void _addMedicineEntry() {
    setState(() {
      _medicines.add(_MedicineEntry());
    });
  }

  void _removeMedicineEntry(int index) {
    if (index <= 0 || index >= _medicines.length) return;
    setState(() {
      _medicines[index].dispose();
      _medicines.removeAt(index);
    });
  }

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      final String fileName = 'medicine_requests/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitRequest(BuildContext context, dynamic user) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload images for each medicine entry and build medicines array
      final List<Map<String, dynamic>> medicinesData = [];
      for (int i = 0; i < _medicines.length; i++) {
        final entry = _medicines[i];
        String? entryImageUrl;
        if (entry.image != null) {
          entryImageUrl = await _uploadImage(entry.image!, user.uid);
        }
        final map = entry.toMap();
        map['imageUrl'] = entryImageUrl;
        medicinesData.add(map);
      }

      final requestData = {
        'userId': user.uid,
        'userName': user.displayName,
        'userEmail': user.email,
        'medicines': medicinesData,
        'phoneNumber': _phoneController.text.trim(),
        'whatsappNumber': _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      await FirebaseFirestore.instance.collection('medicine_requests').add(requestData);

      // Cloud Function will automatically send notification
      // No need to call NotificationService here

      if (mounted) {
        // Show alert dialog instead of snackbar
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF06B6D4), size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تم نشر الطلب بنجاح!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ ستتواصل معك الصيدليات قريباً',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[900], size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'مهم جداً:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                                fontSize: 14,
                              ),
                            ),
                          ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'في حالة تواصل إحدى الصيدليات معك:',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. ', style: TextStyle(color: Colors.orange[900], fontSize: 13)),
                          Expanded(
                            child: Text(
                              'ادخل على "طلباتي"',
                              style: TextStyle(color: Colors.orange[900], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('2. ', style: TextStyle(color: Colors.orange[900], fontSize: 13)),
                          Expanded(
                            child: Text(
                              'اضغط على "تم التواصل" أو "حذف الطلب"',
                              style: TextStyle(color: Colors.orange[900], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '⚠️ هذا سيمنع باقي الصيدليات من التواصل معك',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.pop(context); // Close request screen
                },
                child: const Text(
                  'فهمت',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
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
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleSubmit(BuildContext context) async {
    // Check authentication first
    final isAuthenticated = await AuthHelpers.requireAuth(
      context,
      message: 'يجب تسجيل الدخول لنشر طلب الدواء.\nهذا يساعدنا في التواصل معك بشكل أفضل.',
    );
    
    if (!isAuthenticated || !mounted) return;
    
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _submitRequest(context, authState.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),
        appBar: AppBar(
          title: const Text(
            'طلب دواء',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'املأ البيانات وسنقوم بإرسال طلبك للصيدليات المتاحة',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Medicine Name (main entry)
                TextFormField(
                  controller: _medicines[0].nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الدواء *',
                    hintText: 'أدخل اسم الدواء المطلوب',
                    prefixIcon: const Icon(Icons.medication, color: Color(0xFF06B6D4)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اسم الدواء مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Medicine Type Dropdown
                DropdownButtonFormField<String>(
                  value: _medicines[0].type,
                  decoration: InputDecoration(
                    labelText: 'نوع الدواء *',
                    hintText: 'اختر نوع الدواء',
                    prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF06B6D4)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                    ),
                  ),
                  items: _medicineTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _medicines[0].type = value;
                      // Reset unit when type changes
                      if (_unitsByType.containsKey(value)) {
                        _medicines[0].unit = null;
                      } else {
                        _medicines[0].unit = 'علب';
                      }
                    });
                  },
                  validator: (value) {
                    if (_medicines[0].type == null || _medicines[0].type!.isEmpty) {
                      return 'نوع الدواء مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantity Unit Dropdown (only if type is selected AND has units)
                if (_medicines[0].type != null && _unitsByType.containsKey(_medicines[0].type))
                  DropdownButtonFormField<String>(
                    value: _medicines[0].unit,
                    decoration: InputDecoration(
                      labelText: 'الوحدة *',
                      hintText: 'اختر الوحدة',
                      prefixIcon: const Icon(Icons.category, color: Color(0xFF06B6D4)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                      ),
                    ),
                    items: _unitsByType[_medicines[0].type]!.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _medicines[0].unit = value;
                      });
                    },
                    validator: (value) {
                      if (_medicines[0].unit == null || _medicines[0].unit!.isEmpty) {
                        return 'الوحدة مطلوبة';
                      }
                      return null;
                    },
                  ),
                if (_medicines[0].type != null && _unitsByType.containsKey(_medicines[0].type))
                  const SizedBox(height: 16),

                // Image Picker for main entry (moved here, replacing quantity field)
                GestureDetector(
                  onTap: () => _pickImageForEntry(0),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: _medicines[0].image != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _medicines[0].image!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _medicines[0].image = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 48, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text(
                                'إضافة صورة الدواء (اختياري)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Extra medicine entries (if any)
                for (int ei = 1; ei < _medicines.length; ei++) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text('دواء ${ei + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => setState(() => _removeMedicineEntry(ei)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _medicines[ei].nameController,
                            decoration: InputDecoration(
                              labelText: 'اسم الدواء *',
                              prefixIcon: const Icon(Icons.medication, color: Color(0xFF06B6D4)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'اسم الدواء مطلوب';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _medicines[ei].type,
                            decoration: InputDecoration(
                              labelText: 'نوع الدواء *',
                              prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF06B6D4)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                              ),
                            ),
                            items: _medicineTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setState(() => _medicines[ei].type = v),
                            validator: (v) => (v == null || v.isEmpty) ? 'نوع الدواء مطلوب' : null,
                          ),
                          const SizedBox(height: 8),
                          if (_medicines[ei].type != null && _unitsByType.containsKey(_medicines[ei].type))
                            DropdownButtonFormField<String>(
                              value: _medicines[ei].unit,
                              decoration: InputDecoration(
                                labelText: 'الوحدة *',
                                prefixIcon: const Icon(Icons.category, color: Color(0xFF06B6D4)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                                ),
                              ),
                              items: _unitsByType[_medicines[ei].type]!.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (v) => setState(() => _medicines[ei].unit = v),
                              validator: (v) => (v == null || v.isEmpty) ? 'الوحدة مطلوبة' : null,
                            ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickImageForEntry(ei),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: _medicines[ei].image != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_medicines[ei].image!, fit: BoxFit.cover, width: double.infinity))
                                  : Center(child: Text('إضافة صورة (اختياري)', style: TextStyle(color: Colors.grey[600]))),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _medicines[ei].quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'العدد *',
                              prefixIcon: const Icon(Icons.numbers, color: Color(0xFF06B6D4)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'العدد مطلوب';
                              final q = int.tryParse(v.trim());
                              if (q == null || q < 1) return 'أدخل عدد صحيح أكبر من 0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _addMedicineEntry()),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة دواء آخر'),
                ),
                const SizedBox(height: 24),

                // Contact Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.contact_phone,
                                color: Color(0xFF06B6D4),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'معلومات التواصل',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف *',
                            hintText: '01xxxxxxxxx',
                            prefixIcon: const Icon(Icons.phone, color: Color(0xFF06B6D4)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'رقم الهاتف مطلوب';
                            }
                            if (value.trim().length < 11) {
                              return 'أدخل رقم هاتف صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // WhatsApp Number
                        TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'رقم واتساب (اختياري)',
                            hintText: '01xxxxxxxxx',
                            prefixIcon: Icon(MdiIcons.whatsapp, color: const Color(0xFF25D366)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                            ),
                            helperText: 'إذا كان مختلف عن رقم الهاتف',
                            helperStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'ملاحظات (اختياري)',
                            hintText: 'أي معلومات إضافية عن الطلب',
                            prefixIcon: const Icon(Icons.note, color: Color(0xFF06B6D4)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                //  height: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _handleSubmit(context),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isSubmitting ? 'جاري النشر...' : 'نشر الطلب',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
