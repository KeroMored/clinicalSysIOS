import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/auth_helpers.dart';
import 'medicine_request_contact_info_screen.dart';

// Simple model to hold one medicine entry in the UI
class _MedicineEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  String? type;
  String? unit;
  File? image;
  String inputMode = 'none'; // 'text', 'image', or 'none'

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineName': inputMode == 'text' ? nameController.text.trim() : '',
      'medicineType': type,
      'quantityUnit': unit,
      'quantity': int.tryParse(quantityController.text.trim()) ?? 1,
      'imageUrl': null, // Will be filled during upload
      'imageFile': image, // Pass the file for later upload
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
  
  final List<String> _medicineTypes = [
    'روشتة',
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
    super.dispose();
  }

  Future<void> _pickImageForEntry(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera, // Camera only
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _medicines[index].image = File(image.path);
        _medicines[index].inputMode = 'image';
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

  String? _validateMedicine(_MedicineEntry entry) {
    // Check if user selected input mode
    if (entry.inputMode == 'none') {
      return 'يجب اختيار طريقة إضافة الدواء (تصوير أو كتابة)';
    }
    
    // If text mode, check name is not empty
    if (entry.inputMode == 'text') {
      if (entry.nameController.text.trim().isEmpty) {
        return 'يجب كتابة اسم الدواء';
      }
    }
    
    // If image mode, check image is selected
    if (entry.inputMode == 'image') {
      if (entry.image == null) {
        return 'يجب تصوير الدواء';
      }
    }
    
    return null;
  }

  Future<void> _goToContactInfo(BuildContext context) async {
    // Check authentication first
    final isAuthenticated = await AuthHelpers.requireAuth(
      context,
      message: 'يجب تسجيل الدخول لنشر طلب الدواء.\nهذا يساعدنا في التواصل معك بشكل أفضل.',
    );
    
    if (!isAuthenticated || !mounted) return;

    // Validate all medicines
    for (int i = 0; i < _medicines.length; i++) {
      final validation = _validateMedicine(_medicines[i]);
      if (validation != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('دواء ${i + 1}: $validation'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prepare medicines data
    final List<Map<String, dynamic>> medicinesData = [];
    for (final entry in _medicines) {
      medicinesData.add(entry.toMap());
    }

    // Navigate to contact info screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineRequestContactInfoScreen(
          medicinesData: medicinesData,
        ),
      ),
    );
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

                // Input Mode Selection Buttons
                if (_medicines[0].inputMode == 'none') ...[
                  const Text(
                    'كيف تريد إضافة الدواء؟',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _medicines[0].inputMode = 'text';
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('كتابة اسم الدواء'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImageForEntry(0),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('تصوير الدواء'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Text Input Mode
                if (_medicines[0].inputMode == 'text') ...[
                  TextFormField(
                    controller: _medicines[0].nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الدواء',
                      hintText: 'أدخل اسم الدواء المطلوب',
                      prefixIcon: const Icon(Icons.medication, color: Color(0xFF06B6D4)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _medicines[0].nameController.clear();
                            _medicines[0].inputMode = 'none';
                          });
                        },
                      ),
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
                  const SizedBox(height: 16),
                ],

                // Image Mode
                if (_medicines[0].inputMode == 'image' && _medicines[0].image != null) ...[
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _medicines[0].image!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _medicines[0].image = null;
                                      _medicines[0].inputMode = 'none';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: const Color(0xFF06B6D4),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  onPressed: () => _pickImageForEntry(0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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

                // Quantity field (hide if type is "روشتة")
                if (_medicines[0].type != 'روشتة')
                  TextFormField(
                    controller: _medicines[0].quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'الكمية *',
                      hintText: 'أدخل الكمية المطلوبة',
                      prefixIcon: const Icon(Icons.shopping_cart, color: Color(0xFF06B6D4)),
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
                        return 'الكمية مطلوبة';
                      }
                      final qty = int.tryParse(value.trim());
                      if (qty == null || qty <= 0) {
                        return 'الكمية يجب أن تكون رقم صحيح أكبر من 0';
                      }
                      return null;
                    },
                  ),
                if (_medicines[0].type != 'روشتة')
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

                          // Input Mode Selection Buttons
                          if (_medicines[ei].inputMode == 'none') ...[
                            const Text(
                              'كيف تريد إضافة الدواء؟',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _medicines[ei].inputMode = 'text';
                                      });
                                    },
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('كتابة اسم الدواء'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF06B6D4),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _pickImageForEntry(ei),
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('تصوير الدواء'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A5F),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Text Input Mode
                          if (_medicines[ei].inputMode == 'text') ...[
                            TextFormField(
                              controller: _medicines[ei].nameController,
                              decoration: InputDecoration(
                                labelText: 'اسم الدواء',
                                hintText: 'أدخل اسم الدواء المطلوب',
                                prefixIcon: const Icon(Icons.medication, color: Color(0xFF06B6D4)),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _medicines[ei].nameController.clear();
                                      _medicines[ei].inputMode = 'none';
                                    });
                                  },
                                ),
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
                            const SizedBox(height: 8),
                          ],

                          // Image Mode
                          if (_medicines[ei].inputMode == 'image' && _medicines[ei].image != null) ...[
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _medicines[ei].image!,
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.red,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                            onPressed: () {
                                              setState(() {
                                                _medicines[ei].image = null;
                                                _medicines[ei].inputMode = 'none';
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          backgroundColor: const Color(0xFF06B6D4),
                                          child: IconButton(
                                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                            onPressed: () => _pickImageForEntry(ei),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Medicine Type Dropdown
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
                          if (_medicines[ei].type != null && _unitsByType.containsKey(_medicines[ei].type))
                            const SizedBox(height: 8),

                          // Quantity field (hide if type is "روشتة")
                          if (_medicines[ei].type != 'روشتة')
                            TextFormField(
                              controller: _medicines[ei].quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'الكمية *',
                                hintText: 'أدخل الكمية المطلوبة',
                                prefixIcon: const Icon(Icons.shopping_cart, color: Color(0xFF06B6D4)),
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
                                if (v == null || v.trim().isEmpty) return 'الكمية مطلوبة';
                                final q = int.tryParse(v.trim());
                                if (q == null || q < 1) return 'الكمية يجب أن تكون رقم صحيح أكبر من 0';
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
                const SizedBox(height: 32),

                // Next Button
                SizedBox(
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
                      onPressed: () => _goToContactInfo(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text(
                        'التالي',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
