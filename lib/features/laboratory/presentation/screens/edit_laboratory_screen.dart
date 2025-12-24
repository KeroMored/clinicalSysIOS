import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/laboratory_model.dart';

class EditLaboratoryScreen extends StatefulWidget {
  final LaboratoryModel laboratory;

  const EditLaboratoryScreen({super.key, required this.laboratory});

  @override
  State<EditLaboratoryScreen> createState() => _EditLaboratoryScreenState();
}

class _EditLaboratoryScreenState extends State<EditLaboratoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _homeServiceFeeController;
  late List<TextEditingController> _authEmailControllers;
  late bool _hasHomeService;
  late bool _isVisible;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.laboratory.name);
    _ownerNameController = TextEditingController(text: widget.laboratory.ownerName);
    _phoneController = TextEditingController(text: widget.laboratory.ownerPhone);
    _addressController = TextEditingController(text: widget.laboratory.address);
    _descriptionController = TextEditingController(text: widget.laboratory.description ?? '');
    _homeServiceFeeController = TextEditingController(
      text: widget.laboratory.homeServiceFee?.toString() ?? '',
    );
    _hasHomeService = widget.laboratory.hasHomeService;
    _isVisible = widget.laboratory.isVisible;
    _authEmailControllers = widget.laboratory.authEmails.isNotEmpty
        ? widget.laboratory.authEmails.map((email) => TextEditingController(text: email)).toList()
        : [TextEditingController()];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _homeServiceFeeController.dispose();
    for (var controller in _authEmailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'ownerPhone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'hasHomeService': _hasHomeService,
        'homeServiceFee': _hasHomeService && _homeServiceFeeController.text.isNotEmpty
            ? double.tryParse(_homeServiceFeeController.text)
            : null,
        'isVisible': _isVisible,
        'authEmails': _authEmailControllers
            .map((c) => c.text.trim())
            .where((email) => email.isNotEmpty)
            .toList(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('laboratories')
          .doc(widget.laboratory.id)
          .update(updates);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ التعديلات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل بيانات المعمل'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              )
            else
              IconButton(
                onPressed: _saveChanges,
                icon: const Icon(Icons.check),
                tooltip: 'حفظ التعديلات',
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Laboratory Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم المعمل *',
                  prefixIcon: const Icon(Icons.science),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Owner Name
              TextFormField(
                controller: _ownerNameController,
                decoration: InputDecoration(
                  labelText: 'اسم المالك *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف *',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'العنوان *',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'اكتب وصفاً مختصراً عن المعمل...',
                ),
              ),
              const SizedBox(height: 24),

              // Home Service Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'خدمة التحاليل المنزلية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('توفير خدمة تحاليل منزلية'),
                        subtitle: const Text('هل يوجد خدمة زيارة المنزل؟'),
                        value: _hasHomeService,
                        onChanged: (value) {
                          setState(() => _hasHomeService = value);
                        },
                        activeColor: Colors.green,
                      ),
                      if (_hasHomeService) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _homeServiceFeeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'رسوم الخدمة المنزلية (جنيه)',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'مثال: 50',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Visibility Setting
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('إظهار المعمل للعملاء'),
                  subtitle: Text(
                    _isVisible
                        ? 'المعمل ظاهر في التطبيق'
                        : 'المعمل مخفي من التطبيق',
                  ),
                  value: _isVisible,
                  onChanged: (value) {
                    setState(() => _isVisible = value);
                  },
                  activeColor: Colors.green,
                  secondary: Icon(
                    _isVisible ? Icons.visibility : Icons.visibility_off,
                    color: _isVisible ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Auth Emails Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.email_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إيميلات المصادقة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'الإيميلات المسموح لها بالدخول إلى لوحة التحكم',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ..._authEmailControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'إيميل ${index + 1}',
                            prefixIcon: const Icon(Icons.email, color: Colors.blue),
                            suffixIcon: _authEmailControllers.length > 1
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        controller.dispose();
                                        _authEmailControllers.removeAt(index);
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'الإيميل مطلوب';
                            }
                            if (!value.contains('@')) {
                              return 'صيغة الإيميل غير صحيحة';
                            }
                            return null;
                          },
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _authEmailControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة إيميل جديد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
