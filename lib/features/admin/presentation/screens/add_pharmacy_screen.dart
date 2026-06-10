import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../data/models/pharmacy_request_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/widgets/login_required_dialog.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class AddPharmacyScreen extends StatefulWidget {
  const AddPharmacyScreen({super.key});

  @override
  State<AddPharmacyScreen> createState() => _AddPharmacyScreenState();
}

class _AddPharmacyScreenState extends State<AddPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  static const String _defaultHolidaysText = 'متاح طوال الإسبوع';

  // Controllers for form fields
  final _pharmacyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [
    TextEditingController(),
  ];
  final _whatsappController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();

  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  bool _hasHomeDelivery = false;
  double _latitude = 0.0;
  double _longitude = 0.0;
  double? _deliveryFee;
  double? _minimumOrderForDelivery;
  List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoadingLocation = false;
  String _locationStatus = '';

  // Insurance
  bool _hasInsurance = false;
  final List<TextEditingController> _insuranceCompanyControllers = [];

  // Days of the week for holidays selection
  final Map<String, bool> _selectedHolidays = {
    'السبت': false,
    'الأحد': false,
    'الاثنين': false,
    'الثلاثاء': false,
    'الأربعاء': false,
    'الخميس': false,
    'الجمعة': false,
  };

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _addressController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _whatsappController.dispose();
    _descriptionController.dispose();
    _workingHoursController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    for (var controller in _insuranceCompanyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      // image_picker handles permissions automatically
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في اختيار الصور: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectOpenTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _openTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _openTime = picked;
        _updateWorkingHours();
      });
    }
  }

  Future<void> _selectCloseTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _closeTime ?? const TimeOfDay(hour: 22, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _closeTime = picked;
        _updateWorkingHours();
      });
    }
  }

  void _updateWorkingHours() {
    if (_openTime != null && _closeTime != null) {
      final openStr = _formatTimeOfDay(_openTime!);
      final closeStr = _formatTimeOfDay(_closeTime!);
      _workingHoursController.text = '$openStr-$closeStr';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'جاري الحصول على الموقع...';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = 'خدمة الموقع غير مفعلة';
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('خدمة الموقع'),
              content: const Text('الرجاء تفعيل خدمة الموقع للمتابعة'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatus = 'تم رفض إذن الموقع';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم رفض إذن الوصول للموقع'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = 'إذن الموقع مرفوض نهائياً';
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('إذن الموقع'),
              content: const Text(
                'تم رفض إذن الموقع نهائياً. يرجى تفعيله من إعدادات التطبيق.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
        _locationStatus = 'تم الحصول على الموقع بنجاح';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديد الموقع: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationStatus = 'فشل في الحصول على الموقع';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في الحصول على الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    List<String> imageUrls = [];

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = File(_selectedImages[i].path);
        final fileName =
            'pharmacy_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('pharmacy_images')
            .child(fileName);

        // Upload the file
        final uploadTask = await storageRef.putFile(file);

        // Get download URL
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في رفع الصور: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  void _submitForm() async {
    // التحقق من تسجيل الدخول أولاً
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        await LoginRequiredDialog.show(context);
      }
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Validate location
      if (_latitude == 0.0 || _longitude == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب تحديد الموقع التلقائي للصيدلية'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Validate working hours
      if (_workingHoursController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تحديد ساعات العمل'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: AppLoadingIndicator()),
      );

      // Upload images first
      final imageUrls = await _uploadImages();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      // Get selected holidays as comma-separated string
      final selectedHolidaysList = _selectedHolidays.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      final holidaysString = selectedHolidaysList.isEmpty
          ? _defaultHolidaysText
          : selectedHolidaysList.join(', ');

      // Get insurance companies list
      final insuranceCompanies = _hasInsurance
          ? _insuranceCompanyControllers
                .map((controller) => controller.text.trim())
                .where((name) => name.isNotEmpty)
                .toList()
          : <String>[];

      // Collect all non-empty phone numbers
      final phonesList = _phoneControllers
          .map((controller) => controller.text.trim())
          .where((phone) => phone.isNotEmpty)
          .toList();

      final request = PharmacyRequestModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _pharmacyNameController.text,
        address: _addressController.text,
        phones: phonesList,
        whatsapp: _whatsappController.text.isNotEmpty
            ? _whatsappController.text
            : (phonesList.isNotEmpty ? phonesList[0] : ''),

        latitude: _latitude,
        longitude: _longitude,
        workingHours: _workingHoursController.text,
        holidays: holidaysString,
        images: imageUrls,
        hasHomeDelivery: _hasHomeDelivery,
        deliveryFee: _hasHomeDelivery ? (_deliveryFee ?? 0.0) : null,
        minimumOrderForDelivery: _hasHomeDelivery
            ? (_minimumOrderForDelivery ?? 0.0)
            : null,
        services: [],
        ownerName: _ownerNameController.text,
        ownerPhone: _ownerPhoneController.text,
        ownerEmail: _ownerEmailController.text,
        status: 'approved', // مباشرة معتمدة لأنها من الأدمن
        requestDate: DateTime.now(),
        hasInsurance: _hasInsurance,
        insuranceCompanies: insuranceCompanies,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      context.read<AdminCubit>().addPharmacyDirectly(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'إضافة صيدلية جديدة',
        gradient: AppTheme.pharmacyGradient,
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
        child: BlocConsumer<AdminCubit, AdminState>(
          listener: (context, state) {
            if (state is PharmacyAddedSuccessfully) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إضافة الصيدلية بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is AdminError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: AppLoadingIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // قسم بيانات الصيدلية
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'بيانات الصيدلية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF06B6D4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Divider(),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _pharmacyNameController,
                              label: 'اسم الصيدلية',
                              icon: Icons.local_pharmacy,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال اسم الصيدلية';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // العنوان
                            _buildTextField(
                              controller: _addressController,
                              label: 'العنوان',
                              icon: Icons.location_on,
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال العنوان';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // أرقام الهاتف (Multiple)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'أرقام الهاتف',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_phoneControllers.length < 5)
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _phoneControllers.add(
                                                TextEditingController(),
                                              );
                                            });
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text('إضافة رقم'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...List.generate(_phoneControllers.length, (
                                    index,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  _phoneControllers[index],
                                              keyboardType: TextInputType.phone,
                                              decoration: InputDecoration(
                                                labelText: index == 0
                                                    ? 'رقم الهاتف الأساسي *'
                                                    : 'رقم ${index + 1}',
                                                prefixIcon: const Icon(
                                                  Icons.phone,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              validator: index == 0
                                                  ? (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'الرجاء إدخال رقم الهاتف الأساسي';
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
                                                  _phoneControllers[index]
                                                      .dispose();
                                                  _phoneControllers.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // رقم الواتساب
                            _buildTextField(
                              controller: _whatsappController,
                              label: 'رقم الواتساب (اختياري)',
                              icon: Icons.chat,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),

                            // عن الصيدلية
                            _buildTextField(
                              controller: _descriptionController,
                              label: 'عن الصيدلية (اختياري)',
                              icon: Icons.description,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ساعات العمل
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ساعات العمل',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF06B6D4),
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('وقت الافتتاح'),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: _selectOpenTime,
                                        icon: const Icon(Icons.access_time),
                                        label: Text(
                                          _openTime != null
                                              ? _formatTimeOfDay(_openTime!)
                                              : 'اختر الوقت',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF06B6D4,
                                          ),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(
                                            double.infinity,
                                            48,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('وقت الإغلاق'),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: _selectCloseTime,
                                        icon: const Icon(Icons.access_time),
                                        label: Text(
                                          _closeTime != null
                                              ? _formatTimeOfDay(_closeTime!)
                                              : 'اختر الوقت',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF06B6D4,
                                          ),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(
                                            double.infinity,
                                            48,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_workingHoursController.text.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ساعات العمل: ${_workingHoursController.text}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // أيام العطلة
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'أيام العطلة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF06B6D4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'اختر أيام العطلة الأسبوعية',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedHolidays.keys.map((day) {
                                return FilterChip(
                                  label: Text(day),
                                  selected: _selectedHolidays[day]!,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      _selectedHolidays[day] = selected;
                                    });
                                  },
                                  selectedColor: const Color(
                                    0xFF4A90E2,
                                  ).withOpacity(0.3),
                                  checkmarkColor: const Color(0xFF4A90E2),
                                  backgroundColor: Colors.grey.shade100,
                                  labelStyle: TextStyle(
                                    color: _selectedHolidays[day]!
                                        ? const Color(0xFF4A90E2)
                                        : Colors.grey.shade700,
                                    fontWeight: _selectedHolidays[day]!
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // اختيار الصور
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'صور الصيدلية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF06B6D4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('اختر صور الصيدلية'),
                                ElevatedButton.icon(
                                  onPressed: _pickImages,
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: const Text('اختر صور'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF06B6D4),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_selectedImages.isEmpty)
                              const Center(
                                child: Text(
                                  'لم يتم اختيار صور بعد',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            image: DecorationImage(
                                              image: FileImage(
                                                File(
                                                  _selectedImages[index].path,
                                                ),
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // الموقع الجغرافي
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الموقع الجغرافي',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF06B6D4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF06B6D4),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'تحديد الموقع',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_latitude != 0.0 && _longitude != 0.0)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'تم تحديد الموقع',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'خط العرض: ${_latitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      'خط الطول: ${_longitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(color: Colors.white),
                              child: SizedBox(
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(Icons.touch_app),
                                  label: Text(
                                    _isLoadingLocation
                                        ? 'جاري تحديد الموقع...'
                                        : (_latitude != 0.0 &&
                                              _longitude != 0.0)
                                        ? 'تحديث الموقع'
                                        : 'تحديد الموقع التلقائي',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        (_latitude == 0.0 && _longitude == 0.0)
                                        ? const Color(0xFF06B6D4)
                                        : const Color(0xFF06B6D4),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_latitude == 0.0 && _longitude == 0.0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red.shade600,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'تحديد الموقع إجباري',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_locationStatus.isNotEmpty &&
                                !_isLoadingLocation)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _locationStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _locationStatus.contains('بنجاح')
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // خيارات الخدمة
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'خيارات الخدمة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF06B6D4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Divider(),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              value: _hasHomeDelivery,
                              onChanged: (value) {
                                setState(() {
                                  _hasHomeDelivery = value;
                                });
                              },
                              title: const Text('خدمة التوصيل للمنزل متاحة'),
                              secondary: const Icon(Icons.delivery_dining),
                            ),
                            if (_hasHomeDelivery) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: TextEditingController(
                                  text: _deliveryFee?.toString() ?? '',
                                ),
                                label: 'رسوم التوصيل (اختياري)',
                                icon: Icons.money,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _deliveryFee = double.tryParse(value);
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: TextEditingController(
                                  text:
                                      _minimumOrderForDelivery?.toString() ??
                                      '',
                                ),
                                label: 'الحد الأدنى للطلب (اختياري)',
                                icon: Icons.shopping_cart,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _minimumOrderForDelivery = double.tryParse(
                                    value,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // قسم شركات التأمين
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'شركات التأمين',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF06B6D4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Divider(),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              value: _hasInsurance,
                              onChanged: (value) {
                                setState(() {
                                  _hasInsurance = value;
                                  if (!value) {
                                    // Clear all insurance companies when disabled
                                    for (var controller
                                        in _insuranceCompanyControllers) {
                                      controller.dispose();
                                    }
                                    _insuranceCompanyControllers.clear();
                                  }
                                });
                              },
                              title: const Text('متعاقد مع شركات تأمين؟'),
                              secondary: const Icon(Icons.health_and_safety),
                            ),
                            if (_hasInsurance) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'أسماء شركات التأمين',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _insuranceCompanyControllers.add(
                                                TextEditingController(),
                                              );
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Color(0xFF06B6D4),
                                          ),
                                          tooltip: 'إضافة شركة تأمين',
                                        ),
                                      ],
                                    ),
                                    if (_insuranceCompanyControllers.isEmpty)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          child: TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _insuranceCompanyControllers
                                                    .add(
                                                      TextEditingController(),
                                                    );
                                              });
                                            },
                                            icon: const Icon(Icons.add),
                                            label: const Text(
                                              'اضغط لإضافة شركة تأمين',
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF06B6D4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            _insuranceCompanyControllers.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                    controller:
                                                        _insuranceCompanyControllers[index],
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'اسم الشركة ${index + 1}',
                                                      prefixIcon: const Icon(
                                                        Icons.business,
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                    ),
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return 'الرجاء إدخال اسم الشركة';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _insuranceCompanyControllers[index]
                                                          .dispose();
                                                      _insuranceCompanyControllers
                                                          .removeAt(index);
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.remove_circle,
                                                  ),
                                                  color: Colors.red,
                                                  tooltip: 'حذف',
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // بيانات المالك
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
                            const SizedBox(height: 4),
                            const Divider(),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _ownerNameController,
                              label: 'اسم المالك',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال اسم المالك';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // رقم هاتف المالك
                            _buildTextField(
                              controller: _ownerPhoneController,
                              label: 'رقم هاتف المالك',
                              icon: Icons.phone_android,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال رقم هاتف المالك';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // البريد الإلكتروني للمالك
                            _buildTextField(
                              controller: _ownerEmailController,
                              label: 'البريد الإلكتروني (للمصادقة)',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال البريد الإلكتروني';
                                }
                                if (!value.contains('@') ||
                                    !value.contains('.')) {
                                  return 'الرجاء إدخال بريد إلكتروني صحيح';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // زر الإضافة
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إضافة الصيدلية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}
