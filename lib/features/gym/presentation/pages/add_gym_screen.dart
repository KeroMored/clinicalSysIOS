import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/gym_model.dart';
import '../cubit/gym_cubit.dart';
import '../cubit/gym_state.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';
import '../../../home/data/home_fab_cache_helper.dart';

class AddGymScreen extends StatefulWidget {
  const AddGymScreen({super.key});

  @override
  State<AddGymScreen> createState() => _AddGymScreenState();
}

class _AddGymScreenState extends State<AddGymScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [TextEditingController()];
  final _whatsappController = TextEditingController();

  // Location
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Images
  File? _logoImage;
  String? _uploadedLogoUrl;
  final List<File> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  final ImagePicker _imagePicker = ImagePicker();

  // Pricing
  final _monthlyController = TextEditingController();
  final _yearlyController = TextEditingController();
  final _singleSessionController = TextEditingController();

  // Owner Info
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  // Gender Sections
  bool _hasMaleSection = false;
  bool _hasFemaleSection = false;

  // Working Hours
  final Map<String, GymWorkingHours> _maleWorkingHours = {};
  final Map<String, GymWorkingHours> _femaleWorkingHours = {};

  // Days of week
  final List<String> _daysOfWeek = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  final Map<String, String> _dayNamesArabic = {
    'saturday': 'السبت',
    'sunday': 'الأحد',
    'monday': 'الاثنين',
    'tuesday': 'الثلاثاء',
    'wednesday': 'الأربعاء',
    'thursday': 'الخميس',
    'friday': 'الجمعة',
  };

  // Working hours controllers for each day - now supports multiple slots
  final Map<String, List<Map<String, TextEditingController>>> _maleTimeControllers = {};
  final Map<String, List<Map<String, TextEditingController>>> _femaleTimeControllers = {};
  final Map<String, bool> _maleDayClosed = {};
  final Map<String, bool> _femaleDayClosed = {};

  // Features - Dynamic list
  final List<String> _features = [];
  final List<TextEditingController> _featureControllers = [TextEditingController()];

  // Lists
  final List<String> _equipment = [];
  final List<String> _facilities = [];
  final List<String> _classes = [];
  final _equipmentController = TextEditingController();
  final _facilitiesController = TextEditingController();
  final _classesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeTimeControllers();
  }

  void _initializeTimeControllers() {
    for (var day in _daysOfWeek) {
      // Initialize with one slot for each day
      _maleTimeControllers[day] = [
        {
          'start': TextEditingController(text: '08:00'),
          'end': TextEditingController(text: '22:00'),
        }
      ];
      _maleDayClosed[day] = false;

      _femaleTimeControllers[day] = [
        {
          'start': TextEditingController(text: '08:00'),
          'end': TextEditingController(text: '14:00'),
        }
      ];
      _femaleDayClosed[day] = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _whatsappController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    _singleSessionController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _equipmentController.dispose();
    _facilitiesController.dispose();
    _classesController.dispose();

    // Dispose phone controllers
    for (var controller in _phoneControllers) {
      controller.dispose();
    }

    // Dispose feature controllers
    for (var controller in _featureControllers) {
      controller.dispose();
    }

    // Dispose time controllers
    for (var dayControllers in _maleTimeControllers.values) {
      for (var slotControllers in dayControllers) {
        slotControllers['start']?.dispose();
        slotControllers['end']?.dispose();
      }
    }
    for (var dayControllers in _femaleTimeControllers.values) {
      for (var slotControllers in dayControllers) {
        slotControllers['start']?.dispose();
        slotControllers['end']?.dispose();
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GradientAppBar(
        title: 'إضافة جيم جديد',
        gradient: AppTheme.gymGradient,
      ),
      body: BlocListener<GymCubit, GymState>(
        listener: (context, state) async {
          if (state is GymAdded) {
            // Clear FAB cache so it updates on home screen
            await HomeFABCacheHelper.clearCache();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم إضافة الجيم بنجاح ✓\nسيتم مراجعته من قبل الإدارة قبل النشر',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
              Navigator.pop(context);
            }
          } else if (state is GymError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('المعلومات الأساسية'),
                _buildCard([
                  _buildTextField(
                    controller: _nameController,
                    label: 'اسم الجيم',
                    icon: Icons.fitness_center_rounded,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'الوصف',
                    icon: Icons.description_rounded,
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'العنوان التفصيلي',
                    icon: Icons.location_on_rounded,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  // Location Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _latitude != null ? Colors.green : Colors.black,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_latitude == null)
                          ElevatedButton.icon(
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
                                : const Icon(Icons.touch_app),
                            label: Text(
                              _isLoadingLocation
                                  ? 'جاري تحديد الموقع...'
                                  : 'تحديد موقع الجيم الحالي *',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'تم تحديد الموقع بنجاح',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lat: ${_latitude!.toStringAsFixed(6)}, Long: ${_longitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('إعادة تحديد الموقع'),
                              ),
                            ],
                          ),
                        if (_latitude == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              '⚠️ يجب تحديد الموقع التلقائي للمتابعة',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('أرقام الهاتف'),
                _buildCard([
                  ..._buildDynamicTextFields(
                    controllers: _phoneControllers,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    onAdd: () {
                      if (mounted) {
                        setState(() {
                          _phoneControllers.add(TextEditingController());
                        });
                      }
                    },
                    onRemove: (index) {
                      if (mounted && _phoneControllers.length > 1) {
                        setState(() {
                          _phoneControllers[index].dispose();
                          _phoneControllers.removeAt(index);
                        });
                      }
                    },
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _whatsappController,
                    label: 'واتساب',
                    icon: Icons.chat,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('صورة اللوجو'),
                _buildCard([
                  Text(
                    'أضف صورة اللوجو',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  if (_logoImage != null)
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_logoImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () {
                              if (mounted) {
                                setState(() {
                                  _logoImage = null;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_logoImage != null) const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.image_rounded),
                          label: Text(
                            _logoImage == null
                                ? 'اختر صورة اللوجو'
                                : 'تغيير صورة اللوجو',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.gymGradient.colors[0],
                            side: BorderSide(
                              color: AppTheme.gymGradient.colors[0],
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('صور الجيم'),
                _buildCard([
                  Text(
                    'أضف صور للجيم والأجهزة والمرافق(اختياري)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: InkWell(
                                  onTap: () {
                                    if (mounted) {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  if (_selectedImages.isNotEmpty) const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                          label: Text('إضافة صور (${_selectedImages.length})'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.gymGradient.colors[0],
                            side: BorderSide(
                              color: AppTheme.gymGradient.colors[0],
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('الأقسام المتاحة'),
                _buildCard([
                  CheckboxListTile(
                    value: _hasMaleSection,
                    onChanged: (value) {
                      if (mounted) {
                        setState(() => _hasMaleSection = value ?? false);
                      }
                    },
                    title: const Text('قسم رجالي'),
                    secondary: const Icon(
                      Icons.male_rounded,
                      color: Color(0xFF06B6D4),
                    ),
                    activeColor: const Color(0xFF06B6D4),
                  ),
                  if (_hasMaleSection) ...[
                    const Divider(),
                    _buildWorkingHoursSection(
                      'مواعيد القسم الرجالي',
                      _maleTimeControllers,
                      _maleDayClosed,
                      const Color(0xFF06B6D4),
                      true, // isMale
                    ),
                  ],
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _hasFemaleSection,
                    onChanged: (value) {
                      if (mounted) {
                        setState(() => _hasFemaleSection = value ?? false);
                      }
                    },
                    title: const Text('قسم نسائي'),
                    secondary: const Icon(
                      Icons.female_rounded,
                      color: Color(0xFFEC4899),
                    ),
                    activeColor: const Color(0xFFEC4899),
                  ),
                  if (_hasFemaleSection) ...[
                    const Divider(),
                    _buildWorkingHoursSection(
                      'مواعيد القسم النسائي',
                      _femaleTimeControllers,
                      _femaleDayClosed,
                      const Color(0xFFEC4899),
                      false, // isMale
                    ),
                  ],
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('الأسعار (اختياري)'),
                _buildCard([
                  _buildTextField(
                    controller: _monthlyController,
                    label: 'الاشتراك الشهري (جنيه)',
                    icon: Icons.credit_card_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _yearlyController,
                    label: 'الاشتراك السنوي (جنيه)',
                    icon: Icons.credit_card_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _singleSessionController,
                    label: 'سعر الجلسة الواحدة (جنيه)',
                    icon: Icons.credit_card_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('المميزات'),
                _buildCard([
                  ..._buildDynamicTextFields(
                    controllers: _featureControllers,
                    label: 'الميزة',
                    icon: Icons.star_rounded,
                    onAdd: () {
                      if (mounted) {
                        setState(() {
                          _featureControllers.add(TextEditingController());
                        });
                      }
                    },
                    onRemove: (index) {
                      if (mounted && _featureControllers.length > 1) {
                        setState(() {
                          _featureControllers[index].dispose();
                          _featureControllers.removeAt(index);
                        });
                      }
                    },
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('بيانات المالك'),
                _buildCard([
                  _buildTextField(
                    controller: _ownerNameController,
                    label: 'اسم المالك',
                    icon: Icons.person_rounded,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ownerEmailController,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ownerPhoneController,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                ]),

                const SizedBox(height: 30),
                BlocBuilder<GymCubit, GymState>(
                  builder: (context, state) {
                    if (state is GymLoading) {
                      return const Center(child: AppLoadingIndicator());
                    }
                    return GradientButton(
                      text: 'إضافة الجيم',
                      icon: Icons.add_rounded,
                      gradient: AppTheme.gymGradient,
                      onPressed: _submitForm,
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkColor,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children, {String? title}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const Divider(),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection(
    String title,
    Map<String, List<Map<String, TextEditingController>>> controllers,
    Map<String, bool> dayClosed,
    Color themeColor,
    bool isMale,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyToAllDays(isMale),
                icon: const Icon(Icons.content_copy, size: 18),
                label: const Text('نسخ السبت للكل'),
                style: TextButton.styleFrom(
                  foregroundColor: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._daysOfWeek.map((day) {
            return _buildDayRow(
              _dayNamesArabic[day]!,
              day,
              controllers[day]!,
              dayClosed[day]!,
              themeColor,
              (isClosed) {
                if (mounted) {
                  setState(() {
                    dayClosed[day] = isClosed;
                  });
                }
              },
              isMale,
            );
          }),
        ],
      ),
    );
  }

  // Add time slot to a day
  void _addTimeSlot(String day, bool isMale) {
    setState(() {
      final controllers = isMale ? _maleTimeControllers : _femaleTimeControllers;
      controllers[day]!.add({
        'start': TextEditingController(text: '12:00'),
        'end': TextEditingController(text: '14:00'),
      });
    });
  }

  // Remove time slot from a day
  void _removeTimeSlot(String day, int index, bool isMale) {
    setState(() {
      final controllers = isMale ? _maleTimeControllers : _femaleTimeControllers;
      if (controllers[day]!.length > 1) {
        controllers[day]![index]['start']?.dispose();
        controllers[day]![index]['end']?.dispose();
        controllers[day]!.removeAt(index);
      }
    });
  }

  // Copy first day's slots to all days
  void _copyToAllDays(bool isMale) {
    setState(() {
      final controllers = isMale ? _maleTimeControllers : _femaleTimeControllers;
      final closedMap = isMale ? _maleDayClosed : _femaleDayClosed;
      
      final firstDay = _daysOfWeek.first;
      final firstDaySlots = controllers[firstDay]!;
      final firstDayClosed = closedMap[firstDay]!;
      
      for (var day in _daysOfWeek.skip(1)) {
        // Dispose old controllers
        for (var slot in controllers[day]!) {
          slot['start']?.dispose();
          slot['end']?.dispose();
        }
        
        // Copy slots from first day
        controllers[day] = firstDaySlots.map((slot) {
          return {
            'start': TextEditingController(text: slot['start']!.text),
            'end': TextEditingController(text: slot['end']!.text),
          };
        }).toList();
        
        closedMap[day] = firstDayClosed;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ المواعيد لجميع الأيام'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDayRow(
    String dayName,
    String dayKey,
    List<Map<String, TextEditingController>> slotControllers,
    bool isClosed,
    Color themeColor,
    Function(bool) onClosedChanged,
    bool isMale,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: isClosed,
                      activeColor: themeColor,
                      onChanged: (value) => onClosedChanged(value!),
                    ),
                    const Text('مفتوح'),
                    const SizedBox(width: 8),
                    Radio<bool>(
                      value: true,
                      groupValue: isClosed,
                      activeColor: Colors.grey,
                      onChanged: (value) => onClosedChanged(value!),
                    ),
                    const Text('مغلق'),
                  ],
                ),
              ],
            ),
            if (!isClosed) ...[
              const SizedBox(height: 8),
              // Display all time slots
              ...List.generate(slotControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(slotControllers[index]['start']!),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'من',
                              prefixIcon: Icon(
                                Icons.access_time,
                                color: themeColor,
                                size: 20,
                              ),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              slotControllers[index]['start']!.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(slotControllers[index]['end']!),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'إلى',
                              prefixIcon: Icon(
                                Icons.access_time,
                                color: themeColor,
                                size: 20,
                              ),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              slotControllers[index]['end']!.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      if (slotControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeTimeSlot(dayKey, index, isMale),
                          tooltip: 'حذف الفترة',
                        ),
                    ],
                  ),
                );
              }),
              // Add slot button
              Center(
                child: TextButton.icon(
                  onPressed: () => _addTimeSlot(dayKey, isMale),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('إضافة فترة ثانية'),
                  style: TextButton.styleFrom(
                    foregroundColor: themeColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final currentTime = TimeOfDay(
      hour: int.parse(controller.text.split(':')[0]),
      minute: int.parse(controller.text.split(':')[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );

    if (picked != null && mounted) {
      setState(() {
        controller.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.gymGradient.colors[0]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.gymGradient.colors[0],
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildFeatureCheckbox(
    String title,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: (val) => onChanged(val ?? false),
      title: Text(title),
      secondary: Icon(icon, color: AppTheme.gymGradient.colors[0]),
      activeColor: AppTheme.gymGradient.colors[0],
      contentPadding: EdgeInsets.zero,
    );
  }

  List<Widget> _buildDynamicTextFields({
    required List<TextEditingController> controllers,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    String? Function(String?)? validator,
  }) {
    List<Widget> widgets = [];

    for (int i = 0; i < controllers.length; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers[i],
                  keyboardType: keyboardType,
                  validator: validator,
                  decoration: InputDecoration(
                    labelText: '$label ${i + 1}',
                    prefixIcon: Icon(icon, color: AppTheme.gymGradient.colors[0]),
                    suffixIcon: controllers.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => onRemove(i),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.gymGradient.colors[0],
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add button
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text('إضافة $label آخر'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.gymGradient.colors[0],
            side: BorderSide(color: AppTheme.gymGradient.colors[0]),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
    );

    return widgets;
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض أذونات الموقع');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'أذونات الموقع مغلقة بشكل دائم. افتح الإعدادات لتفعيلها.',
        );
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLoadingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد الموقع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديد الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Pick images from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty && mounted) {
        setState(() {
          for (var image in images) {
            if (_selectedImages.length < 10) {
              _selectedImages.add(File(image.path));
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل اختيار الصور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Pick logo image
  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _logoImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل اختيار صورة اللوجو: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    try {
      if (!mounted) return imageUrls;

      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final fileName = 'gyms/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      if (mounted) {
        setState(() {
          _uploadedImageUrls.addAll(imageUrls);
        });
      }

      return imageUrls;
    } catch (e) {
      // Error already handled in catch
      throw Exception('فشل رفع الصور: $e');
    }
  }

  // Upload logo to Firebase Storage
  Future<String?> _uploadLogo() async {
    if (_logoImage == null) return null;

    try {
      final fileName =
          'gyms/logos/${DateTime.now().millisecondsSinceEpoch}_logo.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(_logoImage!);
      final url = await ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _uploadedLogoUrl = url;
        });
      }

      return url;
    } catch (e) {
      throw Exception('فشل رفع صورة اللوجو: $e');
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تحديد الموقع التلقائي'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_hasMaleSection && !_hasFemaleSection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار قسم واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Collect working hours for male section
    if (_hasMaleSection) {
      _maleWorkingHours.clear();
      for (var day in _daysOfWeek) {
        if (!_maleDayClosed[day]!) {
          final slots = _maleTimeControllers[day]!.map((slotControllers) {
            return TimeSlot(
              from: slotControllers['start']!.text,
              to: slotControllers['end']!.text,
            );
          }).toList();
          
          _maleWorkingHours[day] = GymWorkingHours(
            slots: slots,
            isClosed: false,
          );
        }
      }

      if (_maleWorkingHours.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب فتح يوم واحد على الأقل للقسم الرجالي'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Collect working hours for female section
    if (_hasFemaleSection) {
      _femaleWorkingHours.clear();
      for (var day in _daysOfWeek) {
        if (!_femaleDayClosed[day]!) {
          final slots = _femaleTimeControllers[day]!.map((slotControllers) {
            return TimeSlot(
              from: slotControllers['start']!.text,
              to: slotControllers['end']!.text,
            );
          }).toList();
          
          _femaleWorkingHours[day] = GymWorkingHours(
            slots: slots,
            isClosed: false,
          );
        }
      }

      if (_femaleWorkingHours.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب فتح يوم واحد على الأقل للقسم النسائي'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: AppLoadingIndicator()),
        );
      }

      // Upload logo first
      String? logoUrl;
      if (_logoImage != null) {
        logoUrl = await _uploadLogo();
      }

      // Upload images
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Collect features
      final features = _featureControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // Collect phones
      final phones = _phoneControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (phones.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب إضافة رقم هاتف واحد على الأقل'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final gym = GymModel(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        city: _addressController.text.split(',').first.trim(),
        governorate: _addressController.text.split(',').last.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        phones: phones,
        whatsapp: _whatsappController.text,
        logoUrl: logoUrl,
        images: imageUrls,
        hasMaleSection: _hasMaleSection,
        hasFemaleSection: _hasFemaleSection,
        features: features,
        trainingTypes: [], // Empty list since we removed training types section
        // Keep old boolean fields as false for backward compatibility
        hasPersonalTraining: false,
        hasNutritionConsultation: false,
        hasSwimmingPool: false,
        hasSauna: false,
        hasSteamRoom: false,
        hasYogaClasses: false,
        hasCrossFit: false,
        hasMartialArts: false,
        hasCardio: false,
        hasWeightLifting: false,
        hasBodybuilding: false,
        hasFunctionalTraining: false,
        hasGroupClasses: false,
        maleWorkingHours: _maleWorkingHours,
        femaleWorkingHours: _femaleWorkingHours,
        monthlySubscription: double.tryParse(_monthlyController.text),
        yearlySubscription: double.tryParse(_yearlyController.text),
        singleSessionPrice: double.tryParse(_singleSessionController.text),

        rating: 0.0,
        reviewsCount: 0,
        ownerId: '',
        ownerName: _ownerNameController.text,
        authEmails: [_ownerEmailController.text],
        isApproved: false,
        isActive: true,
        createdAt: DateTime.now(),
      );

      context.read<GymCubit>().addGym(gym);
    } catch (e) {
      // Close loading if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
