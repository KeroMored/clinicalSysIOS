import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../../../rehabilitation/data/models/rehabilitation_center_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class AddRehabilitationCenterScreen extends StatefulWidget {
  const AddRehabilitationCenterScreen({super.key});

  @override
  State<AddRehabilitationCenterScreen> createState() =>
      _AddRehabilitationCenterScreenState();
}

class _AddRehabilitationCenterScreenState
    extends State<AddRehabilitationCenterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _centerNameController = TextEditingController();
  final _directorNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<String> _selectedServiceTypes = [];
  bool _hasHomeService = false;
  bool _isLoadingLocation = false;
  String _locationStatus = '';
  double? _latitude;
  double? _longitude;

  XFile? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;

  // Working Days - نفس نظام العيادات
  final Map<String, TimeOfDay?> _workingHoursFrom = {};
  final Map<String, TimeOfDay?> _workingHoursTo = {};
  final Map<String, bool> _isClosedDays = {};

  final List<String> _arabicDays = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  final List<String> _englishDays = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize all days as open by default
    for (var day in _englishDays) {
      _isClosedDays[day] = false;
      _workingHoursFrom[day] = const TimeOfDay(hour: 9, minute: 0);
      _workingHoursTo[day] = const TimeOfDay(hour: 17, minute: 0);
    }
  }

  @override
  void dispose() {
    _centerNameController.dispose();
    _directorNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في اختيار الصورة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage(XFile image, String folder) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'rehabilitation/$folder/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
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
          _isLoadingLocation = false;
          _locationStatus = 'خدمات الموقع غير مفعلة';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatus = 'تم رفض أذونات الموقع';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = 'أذونات الموقع مرفوضة نهائياً';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
        _locationStatus = 'تم تحديد الموقع بنجاح';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديد الموقع: ${position.latitude}, ${position.longitude}',
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
    }
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

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // التحقق من وجود الإحداثيات
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تحديد الموقع التلقائي أولاً'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // طباعة القيم للتحقق
    print('Saving Rehabilitation Center with:');
    print('Latitude: $_latitude');
    print('Longitude: $_longitude');

    if (_selectedServiceTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار نوع واحد على الأقل من الخدمات'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? profileImageUrl;

      if (_profileImage != null) {
        profileImageUrl = await _uploadImage(_profileImage!, 'profiles');
      }

      // Prepare working hours
      Map<String, WorkingHours> workingDays = {};
      for (var day in _englishDays) {
        final from = _workingHoursFrom[day];
        final to = _workingHoursTo[day];
        final isClosed = _isClosedDays[day] ?? false;

        if (from != null && to != null) {
          workingDays[day] = WorkingHours(
            from: _formatTimeOfDay(from),
            to: _formatTimeOfDay(to),
            isClosed: isClosed,
          );
        }
      }

      final center = RehabilitationCenterModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        centerName: _centerNameController.text.trim(),
        directorName: _directorNameController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        authEmails: [_emailController.text.trim()],
        serviceTypes: _selectedServiceTypes,
        address: _addressController.text.trim(),
        profileImageUrl: profileImageUrl,
        description: _descriptionController.text.trim(),
        workingDays: workingDays,
        hasHomeService: _hasHomeService,
        latitude: _latitude!, // استخدام القيم الفعلية بدون ?? 0.0
        longitude: _longitude!, // استخدام القيم الفعلية بدون ?? 0.0
        isApproved: false,
        isActive: false,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        context.read<AdminCubit>().addRehabilitationCenter(center);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'إضافة مركز تأهيل',
        gradient: AppTheme.rehabilitationGradient,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: BlocListener<AdminCubit, AdminState>(
          listener: (context, state) {
            if (state is RehabilitationCenterAdded) {
              setState(() {
                _isSubmitting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إضافة المركز بنجاح وفي انتظار الموافقة'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is AdminError) {
              setState(() {
                _isSubmitting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          // Center Name
                          TextFormField(
                            controller: _centerNameController,
                            decoration: const InputDecoration(
                              labelText: 'اسم المركز *',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال اسم المركز';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Director Name
                          TextFormField(
                            controller: _directorNameController,
                            decoration: const InputDecoration(
                              labelText: 'اسم المدير *',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال اسم المدير';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف *',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال رقم الهاتف';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // WhatsApp
                          TextFormField(
                            controller: _whatsappController,
                            decoration: InputDecoration(
                              labelText: 'واتساب (اختياري)',
                              prefixIcon: Icon(Icons.chat),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // Email - إجباري للمصادقة
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText:
                                  'البريد الإلكتروني * (للمصادقة والتحكم)',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                              helperText: 'سيستخدم هذا البريد للتحكم في المركز',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'البريد الإلكتروني مطلوب';
                              }
                              if (!value.contains('@')) {
                                return 'البريد الإلكتروني غير صحيح';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'أنواع الخدمات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                          const Divider(),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: RehabilitationTypes.allTypes.map((type) {
                              final isSelected = _selectedServiceTypes.contains(
                                type,
                              );
                              return FilterChip(
                                label: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF06B6D4)
                                        : const Color(0xFF0F172A),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedServiceTypes.add(type);
                                    } else {
                                      _selectedServiceTypes.remove(type);
                                    }
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor: const Color(
                                  0xFF06B6D4,
                                ).withOpacity(0.1),
                                checkmarkColor: const Color(0xFF06B6D4),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF06B6D4)
                                      : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'العنوان والموقع',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                          const Divider(),
                          // Address
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'العنوان التفصيلي *',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال العنوان';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // GPS Auto Location
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
                                    : (_latitude != null && _longitude != null)
                                    ? 'تحديد الموقع التلقائي ✓'
                                    : 'تحديد الموقع التلقائي',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06B6D4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          if (_locationStatus.isNotEmpty && !_isLoadingLocation)
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
                          // عرض الإحداثيات المحفوظة
                          if (_latitude != null && _longitude != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF06B6D4,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF06B6D4,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'الإحداثيات المحفوظة:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF06B6D4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'خط العرض: ${_latitude!.toStringAsFixed(6)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'خط الطول: ${_longitude!.toStringAsFixed(6)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_latitude == null || _longitude == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                '⚠️ يجب تحديد الموقع التلقائي للمتابعة',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

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
                          // Working Days - نفس نظام العيادات
                          ...List.generate(_englishDays.length, (index) {
                            final englishDay = _englishDays[index];
                            final arabicDay = _arabicDays[index];
                            final isClosed = _isClosedDays[englishDay] ?? false;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          arabicDay,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Text('إجازة'),
                                            Switch(
                                              value: isClosed,
                                              activeColor: const Color(
                                                0xFF06B6D4,
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _isClosedDays[englishDay] =
                                                      value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (!isClosed) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _selectTime(
                                                context,
                                                true,
                                                englishDay,
                                              ),
                                              icon: const Icon(
                                                Icons.access_time,
                                              ),
                                              label: Text(
                                                _workingHoursFrom[englishDay] !=
                                                        null
                                                    ? 'من: ${_formatTimeOfDay(_workingHoursFrom[englishDay]!)}'
                                                    : 'من: مغلق',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF06B6D4,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _selectTime(
                                                context,
                                                false,
                                                englishDay,
                                              ),
                                              icon: const Icon(
                                                Icons.access_time,
                                              ),
                                              label: Text(
                                                _workingHoursTo[englishDay] !=
                                                        null
                                                    ? 'إلى: ${_formatTimeOfDay(_workingHoursTo[englishDay]!)}'
                                                    : 'إلى: مغلق',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF06B6D4,
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
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'معلومات إضافية',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                          const Divider(),
                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'وصف المركز *',
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال وصف المركز';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          SwitchListTile(
                            title: const Text('يوجد خدمة منزلية'),
                            value: _hasHomeService,
                            onChanged: (value) {
                              setState(() {
                                _hasHomeService = value;
                              });
                            },
                            activeColor: const Color(0xFF06B6D4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'صورة المركز',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Divider(),
                          const SizedBox(height: 12),
                          // Profile Image
                          OutlinedButton.icon(
                            onPressed: _pickProfileImage,
                            icon: const Icon(Icons.image),
                            label: Text(
                              _profileImage == null
                                  ? 'اختر صورة المركز'
                                  : 'تم اختيار الصورة',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.rehabilitationGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: AppLoadingIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('إضافة المركز'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF06B6D4),
      ),
    );
  }
}
