import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../laboratory/data/models/laboratory_model.dart';
import '../../../laboratory/data/models/working_hours.dart';
import '../../../laboratory/data/models/lab_tests.dart';
import '../../../laboratory/data/repositories/laboratory_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/widgets/login_required_dialog.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';
import '../../../home/data/home_fab_cache_helper.dart';

class AddLaboratoryScreen extends StatefulWidget {
  const AddLaboratoryScreen({super.key});

  @override
  State<AddLaboratoryScreen> createState() => _AddLaboratoryScreenState();
}

class _AddLaboratoryScreenState extends State<AddLaboratoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labRepo = LaboratoryRepository();

  // Controllers
  final _labNameController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [TextEditingController()]; // Support multiple phones
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _homeServiceFeeController = TextEditingController();

  File? _labLogo;
  bool _isSubmitting = false;
  bool _hasHomeService = false;

  // Location
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLoadingLocation = false;
  String _locationStatus = '';

  // Working Hours - Support for multiple time slots per day
  final Map<String, List<Map<String, TextEditingController>>> _workingHoursControllers = {};
  final Map<String, bool> _isHolidayDays = {};

  // Available Tests
  final Set<String> _selectedTests = {};

  // Certifications
  final List<String> _certifications = [];
  final _certificationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize working hours (all days available by default with one slot)
    final days = [
      'saturday',
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
    ];
    for (var day in days) {
      _workingHoursControllers[day] = [
        {
          'from': TextEditingController(text: '08:00'),
          'to': TextEditingController(text: '20:00'),
        }
      ];
      _isHolidayDays[day] = false; // All days available by default
    }
  }

  @override
  void dispose() {
    _labNameController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _whatsappController.dispose();
    _emailController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _homeServiceFeeController.dispose();
    _certificationController.dispose();
    // Dispose working hours controllers
    for (var dayControllers in _workingHoursControllers.values) {
      for (var slotControllers in dayControllers) {
        slotControllers['from']?.dispose();
        slotControllers['to']?.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _labLogo = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage(File image, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'جاري تحديد الموقع...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'خدمة تحديد الموقع غير مفعلة';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'تم رفض إذن الموقع';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'إذن الموقع مرفوض نهائياً';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus = 'تم تحديد الموقع بنجاح ✓';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'خطأ في تحديد الموقع: $e';
        _isLoadingLocation = false;
      });
    }
  }

  void _addTimeSlot(String day) {
    setState(() {
      _workingHoursControllers[day]!.add({
        'from': TextEditingController(text: '12:00'),
        'to': TextEditingController(text: '14:00'),
      });
    });
  }

  void _removeTimeSlot(String day, int index) {
    setState(() {
      if (_workingHoursControllers[day]!.length > 1) {
        _workingHoursControllers[day]![index]['from']?.dispose();
        _workingHoursControllers[day]![index]['to']?.dispose();
        _workingHoursControllers[day]!.removeAt(index);
      }
    });
  }

  void _copyToAllDays(String sourceDay) {
    final sourceSlots = _workingHoursControllers[sourceDay]!;
    final sourceIsClosed = _isHolidayDays[sourceDay] ?? false;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('نسخ السبت للكل'),
          content: const Text('هل تريد نسخ مواعيد السبت لباقي الأيام؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  for (var day in _workingHoursControllers.keys) {
                    if (day != sourceDay) {
                      // Dispose old controllers
                      for (var slot in _workingHoursControllers[day]!) {
                        slot['from']?.dispose();
                        slot['to']?.dispose();
                      }
                      // Create new controllers with copied values
                      _workingHoursControllers[day] = sourceSlots.map((slot) {
                        return {
                          'from': TextEditingController(text: slot['from']!.text),
                          'to': TextEditingController(text: slot['to']!.text),
                        };
                      }).toList();
                      _isHolidayDays[day] = sourceIsClosed;
                    }
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ المواعيد لجميع الأيام')),
                );
              },
              child: const Text('نعم'),
            ),
          ],
        ),
      ),
    );
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

  void _showTestSelectionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('اختر التحاليل المتاحة'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AvailableLabTests.allCategories.length,
                  itemBuilder: (context, index) {
                    final category = AvailableLabTests.allCategories[index];
                    final tests = AvailableLabTests.getTestsByCategory(
                      category,
                    );

                    return ExpansionTile(
                      title: Text(category),
                      children: tests.map((test) {
                        return CheckboxListTile(
                          title: Text(test),
                          value: _selectedTests.contains(test),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                _selectedTests.add(test);
                              } else {
                                _selectedTests.remove(test);
                              }
                            });
                            setState(() {}); // Update parent widget too
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('تم'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    // التحقق من تسجيل الدخول أولاً
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        await LoginRequiredDialog.show(context);
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == 0.0 || _longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تحديد الموقع التلقائي'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار تحليل واحد على الأقل')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload logo if exists
      String? logoUrl;
      if (_labLogo != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        logoUrl = await _uploadImage(
          _labLogo!,
          'laboratories/logos/$timestamp.jpg',
        );
      }

      // Prepare working hours with multiple slots support
      final Map<String, WorkingHours> workingHours = {};
      _workingHoursControllers.forEach((day, slotControllers) {
        final isHoliday = _isHolidayDays[day] ?? false;
        
        final slots = slotControllers.map((controllers) {
          return TimeSlot(
            from: controllers['from']!.text,
            to: controllers['to']!.text,
          );
        }).toList();

        workingHours[day] = WorkingHours(
          slots: slots,
          isHoliday: isHoliday,
        );
      });

      // Create laboratory model
      final laboratory = LaboratoryModel(
        id: '',
        name: _labNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        authEmails: [_emailController.text.trim()],
        ownerPhone: _phoneControllers.first.text.trim(),
        phones: _phoneControllers
            .map((c) => c.text.trim())
            .where((phone) => phone.isNotEmpty)
            .toList(),
        whatsapp: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        address: _addressController.text.trim(),
        city: '', // Empty for now
        governorate: '', // Empty for now
        latitude: _latitude,
        longitude: _longitude,
        logoUrl: logoUrl,
        availableTests: _selectedTests.toList(),
        workingHours: workingHours,
        isVisible: true,
        status: 'pending', // Needs admin approval
        createdAt: DateTime.now(),
        hasHomeService: _hasHomeService,
        homeServiceFee:
            _hasHomeService && _homeServiceFeeController.text.isNotEmpty
            ? double.tryParse(_homeServiceFeeController.text)
            : null,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        estimatedResultTime: null, // Removed field
      );

      await _labRepo.addLaboratory(laboratory);

      // Clear FAB cache so it updates on home screen
      await HomeFABCacheHelper.clearCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المعمل بنجاح! في انتظار موافقة الإدارة'),
            backgroundColor: Color(0xFF06B6D4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'إضافة معمل تحاليل',
          gradient: AppTheme.laboratoryGradient,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Laboratory Logo
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF06B6D4),
                              width: 2,
                            ),
                          ),
                          child: _labLogo != null
                              ? ClipOval(
                                  child: Image.file(
                                    _labLogo!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                  color: Color(0xFF06B6D4),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('شعار المعمل (اختياري)'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // المعلومات الأساسية
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                        const Divider(),
                        TextFormField(
                          controller: _labNameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المعمل',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        // Contact Information - Multiple Phone Numbers
                        ...List.generate(_phoneControllers.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneControllers[index],
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: index == 0
                                          ? 'رقم للتواصل'
                                          : 'رقم إضافي ${index}',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.phone),
                                    ),
                                    validator: (value) {
                                      if (index == 0 && (value?.isEmpty ?? true)) {
                                        return 'مطلوب';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (_phoneControllers.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () => _removePhoneField(index),
                                    tooltip: 'حذف الرقم',
                                  ),
                              ],
                            ),
                          );
                        }),
                        
                        TextButton.icon(
                          onPressed: _addPhoneField,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('إضافة رقم آخر'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF06B6D4),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'رقم واتساب (اختياري)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.chat),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني للمصادقة',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                            hintText: 'للدخول بحساب Google',
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'مطلوب';
                            if (!value!.contains('@'))
                              return 'بريد إلكتروني غير صحيح';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Owner Information Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بيانات المالك',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _ownerNameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المالك',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _ownerPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم هاتف المالك',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'مطلوب' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Laboratory Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معلومات المعمل والموقع',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'وصف المعمل (اختياري)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Location Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingLocation
                                ? null
                                : _getCurrentLocation,
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: AppLoadingIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.touch_app, size: 22),
                            label: Text(
                              _isLoadingLocation
                                  ? 'جاري تحديد الموقع...'
                                  : (_latitude == 0.0 || _longitude == 0.0)
                                  ? 'تحديد الموقع تلقائي *'
                                  : 'تم تحديد الموقع ✓',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                        if (_locationStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _locationStatus,
                              style: TextStyle(
                                color: _locationStatus.contains('✓')
                                    ? const Color(0xFF06B6D4)
                                    : Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (_latitude == 0.0 || _longitude == 0.0)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              '⚠️ يجب تحديد الموقع التلقائي للمتابعة',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Available Tests Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التحاليل المتاحة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showTestSelectionDialog,
                            icon: const Icon(Icons.science),
                            label: Text(
                              _selectedTests.isEmpty
                                  ? 'اختر التحاليل المتاحة'
                                  : 'تم اختيار ${_selectedTests.length} تحليل',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                        if (_selectedTests.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedTests.map((test) {
                                return Chip(
                                  label: Text(
                                    test,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: const Color(
                                    0xFF06B6D4,
                                  ).withOpacity(0.1),
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Color(0xFF06B6D4),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF06B6D4),
                                    width: 1,
                                  ),
                                  onDeleted: () {
                                    setState(() => _selectedTests.remove(test));
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Home Service
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'خدمة التحاليل المنزلية',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('خدمة التحاليل المنزلية'),
                          subtitle: const Text(
                            'هل يقدم المعمل خدمة التحاليل في المنزل؟',
                          ),
                          value: _hasHomeService,
                          onChanged: (value) {
                            setState(() => _hasHomeService = value);
                          },
                        ),
                        if (_hasHomeService)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            child: TextFormField(
                              controller: _homeServiceFeeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'رسوم الخدمة المنزلية (جنيه)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Working Hours
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مواعيد العمل',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),

                        ..._buildWorkingHoursList(),
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
                  ),
                  child: _isSubmitting
                      ? const AppLoadingIndicator(color: Colors.white)
                      : const Text(
                          'إضافة المعمل',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWorkingHoursList() {
    final dayNames = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    final widgets = <Widget>[];

    // Add "Copy to All" button for Saturday
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ElevatedButton.icon(
          onPressed: () => _copyToAllDays('saturday'),
          icon: const Icon(Icons.copy_all),
          label: const Text('نسخ مواعيد السبت للكل'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06B6D4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 12),
          ),
        ),
      ),
    );

    widgets.addAll(dayNames.entries.map((entry) {
      final day = entry.key;
      final dayName = entry.value;
      final isHoliday = _isHolidayDays[day] ?? false;
      final slotControllers = _workingHoursControllers[day] ?? [];

      return Card(
        shape: Border.all(),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(isHoliday ? 'إجازة' : 'متاح'),
                      Switch(
                        value: !isHoliday,
                        onChanged: (value) {
                          setState(() {
                            _isHolidayDays[day] = !value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (!isHoliday) ...[
                const SizedBox(height: 12),
                ...List.generate(slotControllers.length, (index) {
                  final controllers = slotControllers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controllers['from'],
                            decoration: InputDecoration(
                              labelText: 'من ${index + 1}',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 8, minute: 0),
                              );
                              if (time != null) {
                                controllers['from']!.text =
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: controllers['to'],
                            decoration: InputDecoration(
                              labelText: 'إلى ${index + 1}',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 20, minute: 0),
                              );
                              if (time != null) {
                                controllers['to']!.text =
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                              }
                            },
                          ),
                        ),
                        if (slotControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeTimeSlot(day, index),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _addTimeSlot(day),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('إضافة فترة أخرى'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF06B6D4),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList());

    return widgets;
  }
}
