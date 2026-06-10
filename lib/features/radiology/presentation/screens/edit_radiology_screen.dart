import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/radiology_model.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class EditRadiologyScreen extends StatefulWidget {
  final RadiologyModel radiology;

  const EditRadiologyScreen({super.key, required this.radiology});

  @override
  State<EditRadiologyScreen> createState() => _EditRadiologyScreenState();
}

class _EditRadiologyScreenState extends State<EditRadiologyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _centerNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late List<TextEditingController> _authEmailControllers;
  late bool _homeVisit;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _centerNameController = TextEditingController(
      text: widget.radiology.centerName,
    );
    _ownerNameController = TextEditingController(
      text: widget.radiology.ownerName,
    );
    _phoneController = TextEditingController(
      text: widget.radiology.centerPhone,
    );
    _whatsappController = TextEditingController(
      text: widget.radiology.centerWhatsApp,
    );
    _addressController = TextEditingController(text: widget.radiology.address);
    _descriptionController = TextEditingController(
      text: widget.radiology.description ?? '',
    );
    _homeVisit = widget.radiology.homeVisit;
    _isActive = widget.radiology.isActive;
    _authEmailControllers = widget.radiology.authEmails.isNotEmpty
        ? widget.radiology.authEmails
              .map((email) => TextEditingController(text: email))
              .toList()
        : [TextEditingController()];
  }

  @override
  void dispose() {
    _centerNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
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
        'centerName': _centerNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'centerPhone': _phoneController.text.trim(),
        'centerWhatsApp': _whatsappController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'homeVisit': _homeVisit,
        'isActive': _isActive,
        'authEmails': _authEmailControllers
            .map((c) => c.text.trim())
            .where((email) => email.isNotEmpty)
            .toList(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('radiology_centers')
          .doc(widget.radiology.id)
          .update(updates);

      if (mounted) {
        Navigator.pop(context, true);
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
          title: const Text('تعديل بيانات مركز الأشعة'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: AppLoadingIndicator(
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
              TextFormField(
                controller: _centerNameController,
                decoration: InputDecoration(
                  labelText: 'اسم مركز الأشعة *',
                  prefixIcon: const Icon(Icons.local_hospital),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerNameController,
                decoration: InputDecoration(
                  labelText: 'اسم المالك *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

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
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'واتساب *',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

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
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'وصف المركز (اختياري)',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'وصف مختصر عن مركز الأشعة وخدماته',
                ),
              ),
              const SizedBox(height: 24),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('خدمة زيارات منزلية'),
                      subtitle: const Text('أشعة متنقلة في المنزل'),
                      value: _homeVisit,
                      onChanged: (value) => setState(() => _homeVisit = value),
                      activeColor: Colors.deepPurple,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('تفعيل المركز'),
                      subtitle: Text(_isActive ? 'المركز نشط' : 'المركز معطل'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      activeColor: Colors.green,
                      secondary: Icon(
                        _isActive ? Icons.check_circle : Icons.cancel,
                        color: _isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
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
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.blue,
                            ),
                            suffixIcon: _authEmailControllers.length > 1
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
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
                              borderSide: BorderSide(
                                color: Colors.blue.shade300,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade300,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
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

              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: AppLoadingIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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
