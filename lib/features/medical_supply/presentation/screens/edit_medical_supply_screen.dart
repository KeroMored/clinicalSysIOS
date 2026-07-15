import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';
import '../../data/models/medical_supply_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class EditMedicalSupplyScreen extends StatefulWidget {
  final MedicalSupplyModel supply;

  const EditMedicalSupplyScreen({super.key, required this.supply});

  @override
  State<EditMedicalSupplyScreen> createState() =>
      _EditMedicalSupplyScreenState();
}

class _EditMedicalSupplyScreenState extends State<EditMedicalSupplyScreen> {
  final _formKey = GlobalKey<FormState>();
  static const String _defaultHolidaysText = 'متاح طوال الإسبوع';

  // Controllers for form fields
  final _supplyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [
    TextEditingController(),
  ];
  final _whatsappController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workingHoursController = TextEditingController();

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
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    // Fill data from widget.supply
    _supplyNameController.text = widget.supply.name;
    _addressController.text = widget.supply.address;

    // Fill phone numbers
    for (int i = 0; i < widget.supply.phones.length; i++) {
      if (i < _phoneControllers.length) {
        _phoneControllers[i].text = widget.supply.phones[i];
      } else {
        final controller = TextEditingController(text: widget.supply.phones[i]);
        _phoneControllers.add(controller);
      }
    }

    _whatsappController.text = widget.supply.whatsapp;
    _descriptionController.text = widget.supply.description ?? '';
    _workingHoursController.text = widget.supply.workingHours;

    // Fill location
    _latitude = widget.supply.latitude;
    _longitude = widget.supply.longitude;

    // Fill delivery data
    _hasHomeDelivery = widget.supply.hasHomeDelivery;
    _deliveryFee = widget.supply.deliveryFee;
    _minimumOrderForDelivery = widget.supply.minimumOrderForDelivery;

    // Fill holidays
    final holidays = widget.supply.holidays;
    if (holidays != _defaultHolidaysText && holidays.isNotEmpty) {
      final holidaysList = holidays.split(',').map((e) => e.trim()).toList();
      for (var day in holidaysList) {
        if (_selectedHolidays.containsKey(day)) {
          _selectedHolidays[day] = true;
        }
      }
    }

    // Parse working hours
    if (widget.supply.workingHours.contains('-')) {
      final parts = widget.supply.workingHours.split('-');
      if (parts.length == 2) {
        final openParts = parts[0].split(':');
        final closeParts = parts[1].split(':');
        if (openParts.length == 2 && closeParts.length == 2) {
          _openTime = TimeOfDay(
            hour: int.tryParse(openParts[0]) ?? 9,
            minute: int.tryParse(openParts[1]) ?? 0,
          );
          _closeTime = TimeOfDay(
            hour: int.tryParse(closeParts[0]) ?? 22,
            minute: int.tryParse(closeParts[1]) ?? 0,
          );
        }
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _supplyNameController.dispose();
    _addressController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _whatsappController.dispose();
    _descriptionController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
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
            'medical_supply_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('medical_supply_images')
            .child(fileName);

        final uploadTask = await storageRef.putFile(file);
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
    if (_formKey.currentState!.validate()) {
      // Validate location
      if (_latitude == 0.0 || _longitude == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب تحديد الموقع التلقائي للمستلزمات طبية'),
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

      // Upload new images if any
      List<String> finalImages = List.from(widget.supply.images);
      if (_selectedImages.isNotEmpty) {
        final newImageUrls = await _uploadImages();
        finalImages.addAll(newImageUrls);
      }

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

      // Collect all non-empty phone numbers
      final phonesList = _phoneControllers
          .map((controller) => controller.text.trim())
          .where((phone) => phone.isNotEmpty)
          .toList();

      try {
        // Update directly in Firestore
        await FirebaseFirestore.instance
            .collection('medical_supplies')
            .doc(widget.supply.id)
            .update({
          'name': _supplyNameController.text.trim(),
          'address': _addressController.text.trim(),
          'phones': phonesList,
          'whatsapp': _whatsappController.text.trim().isNotEmpty
              ? _whatsappController.text.trim()
              : (phonesList.isNotEmpty ? phonesList[0] : ''),
          'latitude': _latitude,
          'longitude': _longitude,
          'workingHours': _workingHoursController.text.trim(),
          'holidays': holidaysString,
          'images': finalImages,
          'hasHomeDelivery': _hasHomeDelivery,
          'deliveryFee': _hasHomeDelivery ? (_deliveryFee ?? 0.0) : null,
          'minimumOrderForDelivery': _hasHomeDelivery
              ? (_minimumOrderForDelivery ?? 0.0)
              : null,
          'description': _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث بيانات المكان بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في التحديث: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'تعديل بيانات المكان',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // قسم بيانات المستلزمات الطبية
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بيانات مكان المستلزمات الطبية',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _supplyNameController,
                          label: 'اسم المكان',
                          icon: Icons.medical_services_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال اسم المكان';
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

                        // عن المستلزمات الطبية
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'نبذة عن مكان المستلزمات الطبية',
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
                            color: Color(0xFFE91E63),
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
                                        0xFFE91E63,
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
                                        0xFFE91E63,
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
                              color: Colors.pink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFE91E63),
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
                            color: Color(0xFFE91E63),
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
                                0xFFE91E63,
                              ).withOpacity(0.3),
                              checkmarkColor: const Color(0xFFE91E63),
                              backgroundColor: Colors.grey.shade100,
                              labelStyle: TextStyle(
                                color: _selectedHolidays[day]!
                                    ? const Color(0xFFE91E63)
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
                          'صور المكان',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إضافة صور جديدة'),
                            ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('اختر صور'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E63),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_selectedImages.isEmpty)
                          const Center(
                            child: Text(
                              'لم يتم اختيار صور جديدة',
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
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFFE91E63),
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
                                    : 'تحديث الموقع',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E63),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
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
                            color: Color(0xFFE91E63),
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
                const SizedBox(height: 32),

                // زر الحفظ
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'حفظ التعديلات',
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
        prefixIcon: Icon(icon, color: const Color(0xFFE91E63)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}
