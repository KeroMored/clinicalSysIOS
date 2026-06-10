import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/models/laboratory_model.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

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
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _homeServiceFeeController;
  late TextEditingController _whatsappController;
  late TextEditingController _estimatedResultTimeController;
  late List<TextEditingController> _phoneControllers;
  late List<TextEditingController> _authEmailControllers;
  late List<TextEditingController> _testsControllers;

  // Working Hours
  final List<String> _englishDays = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];
  final List<String> _arabicDays = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];
  final Map<String, TimeOfDay?> _workingHoursFrom = {};
  final Map<String, TimeOfDay?> _workingHoursTo = {};
  final Map<String, bool> _isClosedDays = {};

  // Theme colors - matching laboratory gradient
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  late bool _hasHomeService;
  late bool _isVisible;
  bool _isSaving = false;

  File? _selectedLogo;
  String? _existingLogoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.laboratory.name);
    _ownerNameController = TextEditingController(
      text: widget.laboratory.ownerName,
    );
    _addressController = TextEditingController(text: widget.laboratory.address);
    _descriptionController = TextEditingController(
      text: widget.laboratory.description ?? '',
    );
    _homeServiceFeeController = TextEditingController(
      text: widget.laboratory.homeServiceFee?.toString() ?? '',
    );
    _whatsappController = TextEditingController(
      text: widget.laboratory.whatsapp ?? '',
    );
    _estimatedResultTimeController = TextEditingController(
      text: widget.laboratory.estimatedResultTime?.toString() ?? '',
    );
    _hasHomeService = widget.laboratory.hasHomeService;
    _isVisible = widget.laboratory.isVisible;
    _existingLogoUrl = widget.laboratory.logoUrl;

    // Initialize phone controllers - دعم أرقام متعددة
    _phoneControllers = widget.laboratory.phones.isNotEmpty
        ? widget.laboratory.phones
              .map((phone) => TextEditingController(text: phone))
              .toList()
        : [TextEditingController(text: widget.laboratory.ownerPhone)];

    // Initialize auth emails
    _authEmailControllers = widget.laboratory.authEmails.isNotEmpty
        ? widget.laboratory.authEmails
              .map((email) => TextEditingController(text: email))
              .toList()
        : [TextEditingController()];

    // Initialize tests
    _testsControllers = widget.laboratory.availableTests.isNotEmpty
        ? widget.laboratory.availableTests
              .map((test) => TextEditingController(text: test))
              .toList()
        : [TextEditingController()];

    // Initialize working hours
    for (var i = 0; i < _englishDays.length; i++) {
      final day = _englishDays[i];
      final hours = widget.laboratory.workingHours[day];

      if (hours != null) {
        _isClosedDays[day] = hours.isHoliday;
        if (!hours.isHoliday &&
            hours.openTime != 'مغلق' &&
            hours.closeTime != 'مغلق') {
          _workingHoursFrom[day] = _parseTimeOfDay(hours.openTime);
          _workingHoursTo[day] = _parseTimeOfDay(hours.closeTime);
        }
      } else {
        _isClosedDays[day] = false;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _homeServiceFeeController.dispose();
    _whatsappController.dispose();
    _estimatedResultTimeController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    for (var controller in _authEmailControllers) {
      controller.dispose();
    }
    for (var controller in _testsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedLogo = File(image.path);
      });
    }
  }

  Future<String?> _uploadLogo() async {
    if (_selectedLogo == null) return null;

    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('laboratories')
          .child(widget.laboratory.id)
          .child('logo_$fileName.jpg');

      await ref.putFile(_selectedLogo!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading logo: $e');
      return null;
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final cleanTime = time.replaceAll(RegExp(r'[^\d:]'), '').trim();
      final parts = cleanTime.split(':');

      if (parts.isEmpty) return const TimeOfDay(hour: 9, minute: 0);

      int hour = int.parse(parts[0]);

      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(
        hour: hour,
        minute: parts.length > 1 ? int.parse(parts[1]) : 0,
      );
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _selectTime(
    BuildContext context,
    bool isFrom,
    String day,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isFrom
          ? (_workingHoursFrom[day] ?? const TimeOfDay(hour: 9, minute: 0))
          : (_workingHoursTo[day] ?? const TimeOfDay(hour: 17, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _workingHoursFrom[day] = picked;
        } else {
          _workingHoursTo[day] = picked;
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload new logo if selected
      String? logoUrl = _existingLogoUrl;
      if (_selectedLogo != null) {
        final uploadedUrl = await _uploadLogo();
        if (uploadedUrl != null) {
          logoUrl = uploadedUrl;
        }
      }

      // Prepare working hours
      Map<String, dynamic> workingHoursMap = {};
      for (var day in _englishDays) {
        final from = _workingHoursFrom[day];
        final to = _workingHoursTo[day];
        final isHoliday = _isClosedDays[day] ?? false;

        if (isHoliday) {
          workingHoursMap[day] = {
            'openTime': 'مغلق',
            'closeTime': 'مغلق',
            'isHoliday': true,
          };
        } else if (from != null && to != null) {
          workingHoursMap[day] = {
            'openTime': _formatTimeOfDay(from),
            'closeTime': _formatTimeOfDay(to),
            'isHoliday': false,
          };
        }
      }

      final updates = {
        'name': _nameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'ownerPhone': _phoneControllers.first.text.trim(), // للتوافق
        'phones': _phoneControllers
            .map((c) => c.text.trim())
            .where((phone) => phone.isNotEmpty)
            .toList(),
        'whatsapp': _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'hasHomeService': _hasHomeService,
        'homeServiceFee':
            _hasHomeService && _homeServiceFeeController.text.isNotEmpty
            ? double.tryParse(_homeServiceFeeController.text)
            : null,
        'estimatedResultTime': _estimatedResultTimeController.text.isNotEmpty
            ? int.tryParse(_estimatedResultTimeController.text)
            : null,
        'availableTests': _testsControllers
            .map((c) => c.text.trim())
            .where((test) => test.isNotEmpty)
            .toList(),
        'workingHours': workingHoursMap,
        'isVisible': _isVisible,
        'logoUrl': logoUrl,
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
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ تم حفظ التعديلات بنجاح'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('خطأ في الحفظ: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Premium Input Decoration
  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _primaryColor, size: 22),
      ),
      labelStyle: const TextStyle(
        color: _textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: _textSecondary.withOpacity(0.6),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: _isSaving
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const AppLoadingIndicator(
                        color: _primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'جاري حفظ التعديلات...',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Premium App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: _primaryColor,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.check, color: Colors.white),
                          onPressed: _isSaving ? null : _saveChanges,
                          tooltip: 'حفظ التعديلات',
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_primaryColor, _secondaryColor],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: -20,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                56,
                                20,
                                16,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_note_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'تعديل بيانات المعمل',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'قم بتحديث معلومات المعمل',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Form Content
                  SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo Section
                            _buildSectionCard(
                              title: 'شعار المعمل',
                              icon: Icons.image_rounded,
                              children: [
                                GestureDetector(
                                  onTap: _pickLogo,
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: _backgroundColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 2,
                                      ),
                                    ),
                                    child: _selectedLogo != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              _selectedLogo!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : _existingLogoUrl != null &&
                                              _existingLogoUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              _existingLogoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .add_photo_alternate,
                                                            size: 48,
                                                            color:
                                                                _textSecondary,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            'اضغط لتحميل صورة',
                                                            style: TextStyle(
                                                              color:
                                                                  _textSecondary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                            ),
                                          )
                                        : const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 48,
                                                  color: _textSecondary,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'اضغط لتحميل صورة',
                                                  style: TextStyle(
                                                    color: _textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Basic Info Section
                            _buildSectionCard(
                              title: 'المعلومات الأساسية',
                              icon: Icons.info_outline_rounded,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _buildInputDecoration(
                                    label: 'اسم المعمل',
                                    icon: Icons.science,
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'مطلوب';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _ownerNameController,
                                  decoration: _buildInputDecoration(
                                    label: 'اسم المالك',
                                    icon: Icons.person,
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'مطلوب';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // أرقام التليفون (دعم أرقام متعددة)
                                const Text(
                                  'أرقام التليفون',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(_phoneControllers.length, (
                                  index,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                _phoneControllers[index],
                                            keyboardType: TextInputType.phone,
                                            decoration: _buildInputDecoration(
                                              label: index == 0
                                                  ? 'رقم التليفون الأساسي *'
                                                  : 'رقم تليفون ${index + 1}',
                                              icon: Icons.phone,
                                            ),
                                            style: const TextStyle(
                                              color: _textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            validator: (value) {
                                              if (index == 0 &&
                                                  (value == null ||
                                                      value.trim().isEmpty)) {
                                                return 'رقم التليفون الأساسي مطلوب';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        if (index > 0) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _phoneControllers[index]
                                                    .dispose();
                                                _phoneControllers.removeAt(
                                                  index,
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                                TextButton.icon(
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('إضافة رقم تليفون آخر'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _primaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _phoneControllers.add(
                                        TextEditingController(),
                                      );
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _addressController,
                                  maxLines: 2,
                                  decoration: _buildInputDecoration(
                                    label: 'العنوان',
                                    icon: Icons.location_on,
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'مطلوب';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: _buildInputDecoration(
                                    label: 'الوصف (اختياري)',
                                    icon: Icons.description,
                                    hint: 'اكتب وصفاً مختصراً عن المعمل...',
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _whatsappController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _buildInputDecoration(
                                    label: 'رقم الواتساب (اختياري)',
                                    icon: Icons.chat,
                                    hint: 'مثال: 01234567890',
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _estimatedResultTimeController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    label:
                                        'وقت ظهور النتيجة (بالساعات - اختياري)',
                                    icon: Icons.timer,
                                    hint: 'مثال: 24',
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Available Tests Section
                            _buildSectionCard(
                              title: 'التحاليل المتوفرة',
                              icon: Icons.science_outlined,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'أضف قائمة التحاليل المتاحة في المعمل',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...List.generate(_testsControllers.length, (
                                  index,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                _testsControllers[index],
                                            decoration: _buildInputDecoration(
                                              label: 'تحليل ${index + 1}',
                                              icon: Icons.medical_services,
                                              hint:
                                                  'مثال: تحليل صورة دم كاملة CBC',
                                            ),
                                            style: const TextStyle(
                                              color: _textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (index > 0)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _testsControllers[index]
                                                    .dispose();
                                                _testsControllers.removeAt(
                                                  index,
                                                );
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _testsControllers.add(
                                        TextEditingController(),
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('إضافة تحليل'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Working Hours Section
                            _buildSectionCard(
                              title: 'مواعيد العمل',
                              icon: Icons.access_time_rounded,
                              children: [
                                ...List.generate(_englishDays.length, (index) {
                                  final englishDay = _englishDays[index];
                                  final arabicDay = _arabicDays[index];
                                  final isClosed =
                                      _isClosedDays[englishDay] ?? false;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isClosed
                                            ? Colors.grey.shade300
                                            : _primaryColor.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: isClosed
                                                          ? Colors.grey
                                                          : _primaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.calendar_today,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    arabicDay,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isClosed
                                                          ? Colors.grey
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isClosed
                                                      ? Colors.red.shade50
                                                      : Colors.green.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isClosed
                                                        ? Colors.red.shade200
                                                        : Colors.green.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      isClosed
                                                          ? 'إجازة'
                                                          : 'عمل',
                                                      style: TextStyle(
                                                        color: isClosed
                                                            ? Colors
                                                                  .red
                                                                  .shade700
                                                            : Colors
                                                                  .green
                                                                  .shade700,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Switch(
                                                      value: isClosed,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _isClosedDays[englishDay] =
                                                              value;
                                                        });
                                                      },
                                                      activeColor: Colors.red,
                                                      inactiveThumbColor:
                                                          Colors.green,
                                                      inactiveTrackColor:
                                                          Colors.green.shade100,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (!isClosed) ...[
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: _primaryColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: _primaryColor
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: OutlinedButton.icon(
                                                      onPressed: () =>
                                                          _selectTime(
                                                            context,
                                                            true,
                                                            englishDay,
                                                          ),
                                                      icon: null,
                                                      label: Text(
                                                        _workingHoursFrom[englishDay] !=
                                                                null
                                                            ? 'من: ${_formatTimeOfDay(_workingHoursFrom[englishDay]!)}'
                                                            : 'من: مغلق',
                                                        style: TextStyle(
                                                          color: _primaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide.none,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 12,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: _primaryColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: _primaryColor
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: OutlinedButton.icon(
                                                      onPressed: () =>
                                                          _selectTime(
                                                            context,
                                                            false,
                                                            englishDay,
                                                          ),
                                                      icon: null,
                                                      label: Text(
                                                        _workingHoursTo[englishDay] !=
                                                                null
                                                            ? 'إلى: ${_formatTimeOfDay(_workingHoursTo[englishDay]!)}'
                                                            : 'إلى: مغلق',
                                                        style: TextStyle(
                                                          color: _primaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide.none,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 12,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Home Service Section
                            _buildSectionCard(
                              title: 'خدمة التحاليل المنزلية',
                              icon: Icons.home_work_rounded,
                              children: [
                                SwitchListTile(
                                  title: const Text('توفير خدمة تحاليل منزلية'),
                                  subtitle: const Text(
                                    'هل يوجد خدمة زيارة المنزل؟',
                                  ),
                                  value: _hasHomeService,
                                  onChanged: (value) {
                                    setState(() => _hasHomeService = value);
                                  },
                                  activeColor: _primaryColor,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (_hasHomeService) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _homeServiceFeeController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration(
                                      label: 'رسوم الخدمة المنزلية (جنيه)',
                                      icon: Icons.attach_money,
                                      hint: 'مثال: 50',
                                    ),
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Auth Emails Section
                            _buildSectionCard(
                              title: 'إيميلات المصادقة',
                              icon: Icons.email_rounded,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'الإيميلات التي يمكنها الوصول لإدارة المعمل',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...List.generate(_authEmailControllers.length, (
                                  index,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                _authEmailControllers[index],
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: _buildInputDecoration(
                                              label: index == 0
                                                  ? 'الإيميل الأساسي *'
                                                  : 'إيميل ${index + 1}',
                                              icon: Icons.email,
                                            ),
                                            style: const TextStyle(
                                              color: _textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            validator: index == 0
                                                ? (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'يرجى إدخال الإيميل الأساسي';
                                                    }
                                                    if (!value.contains('@')) {
                                                      return 'إيميل غير صحيح';
                                                    }
                                                    return null;
                                                  }
                                                : null,
                                          ),
                                        ),
                                        if (index > 0)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _authEmailControllers[index]
                                                    .dispose();
                                                _authEmailControllers.removeAt(
                                                  index,
                                                );
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                if (_authEmailControllers.length < 5)
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _authEmailControllers.add(
                                          TextEditingController(),
                                        );
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('إضافة إيميل'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Visibility Setting
                            _buildSectionCard(
                              title: 'إعدادات الظهور',
                              icon: Icons.visibility_rounded,
                              children: [
                                SwitchListTile(
                                  title: const Text('إظهار المعمل للعملاء'),
                                  subtitle: Text(
                                    _isVisible
                                        ? 'المعمل ظاهر في التطبيق'
                                        : 'المعمل مخفي عن العملاء',
                                  ),
                                  value: _isVisible,
                                  onChanged: (value) {
                                    setState(() => _isVisible = value);
                                  },
                                  activeColor: _primaryColor,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
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
