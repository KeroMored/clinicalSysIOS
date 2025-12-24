import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../clinic/data/models/clinic_model.dart';
import '../../../clinic/data/models/clinic_department.dart';
import '../../../clinic/data/repositories/clinic_repository.dart';

class AddClinicScreen extends StatefulWidget {
  const AddClinicScreen({super.key});

  @override
  State<AddClinicScreen> createState() => _AddClinicScreenState();
}

class _AddClinicScreenState extends State<AddClinicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clinicRepo = ClinicRepository();
  
  // Controllers
  final _doctorNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _aboutController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Doctor Account Controllers
  final List<TextEditingController> _authEmailControllers = [TextEditingController()];
  final _doctorPhoneController = TextEditingController();
  
  ClinicDepartment? _selectedDepartment;
  File? _clinicImage;
  File? _doctorImage;
  bool _isSubmitting = false;
  bool _hasNursery = false;
  bool _onlineBookingEnabled = false;
  
  // Location
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLoadingLocation = false;
  String _locationStatus = '';
  
  // Working Hours
  final Map<String, TimeOfDay?> _workingHoursFrom = {};
  final Map<String, TimeOfDay?> _workingHoursTo = {};
  final Map<String, bool> _isClosedDays = {};

  @override
  void initState() {
    super.initState();
    // Initialize working hours with default values (all days OPEN by default)
    final days = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    for (var day in days) {
      _workingHoursFrom[day] = const TimeOfDay(hour: 9, minute: 0);
      _workingHoursTo[day] = const TimeOfDay(hour: 17, minute: 0);
      _isClosedDays[day] = false; // All days open by default
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specializationController.dispose();
    _aboutController.dispose();
    _consultationFeeController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    for (var controller in _authEmailControllers) {
      controller.dispose();
    }
    _doctorPhoneController.dispose();
    super.dispose();
  }

  // Get hint text based on selected department
  String _getSpecializationHint() {
    if (_selectedDepartment == null) {
      return 'اختر التخصص أولاً';
    }
    
    switch (_selectedDepartment!) {
      case ClinicDepartment.pediatrics:
        return 'مثل: حديثي الولادة، تطعيمات، تغذية أطفال';
      case ClinicDepartment.dentistry:
        return 'مثل: تجميل وتقويم، زراعة أسنان، جراحة فم';
      case ClinicDepartment.internalMedicine:
        return 'مثل: سكر وغدد صماء، جهاز هضمي، كبد';
      case ClinicDepartment.dermatology:
        return 'مثل: تجميل وليزر، حساسية، أمراض جلدية';
      case ClinicDepartment.orthopedics:
        return 'مثل: جراحة عظام، إصابات ملاعب، عمود فقري';
      case ClinicDepartment.cardiology:
        return 'مثل: قلب وأوعية دموية، قسطرة، ضغط';
      case ClinicDepartment.ophthalmology:
        return 'مثل: جراحة عيون، ليزك، شبكية';
      case ClinicDepartment.ent:
        return 'مثل: أذن، أنف، حنجرة وحبال صوتية';
      case ClinicDepartment.obstetrics:
        return 'مثل: نساء وتوليد، حقن مجهري، متابعة حمل';
      case ClinicDepartment.urology:
        return 'مثل: مسالك بولية، كلى، عقم رجال';
      case ClinicDepartment.psychiatry:
        return 'مثل: طب نفسي، أعصاب، إدمان';
      case ClinicDepartment.generalSurgery:
        return 'مثل: جراحة عامة، مناظير، سمنة';
      case ClinicDepartment.physiotherapy:
        return 'مثل: علاج طبيعي، تأهيل حركي، آلام مفاصل';
      case ClinicDepartment.other:
        return 'حدد التخصص الدقيق';
    }
  }

  Future<void> _pickImage(bool isClinicImage) async {
    try {
      final picker = ImagePicker();
      
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('اختر مصدر الصورة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('المعرض'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('الكاميرا'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      
      if (source == null) return;
      
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isClinicImage) {
            _clinicImage = File(image.path);
          } else {
            _doctorImage = File(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في اختيار الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage(File image, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // التأكد من تحديد الموقع
    if (_latitude == 0.0 || _longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تحديد الموقع التلقائي للعيادة'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر التخصص')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload images
      String? clinicImageUrl;
      String? doctorImageUrl;

      if (_clinicImage != null) {
        clinicImageUrl = await _uploadImage(
          _clinicImage!,
          'clinics/${DateTime.now().millisecondsSinceEpoch}_clinic.jpg',
        );
      }

      if (_doctorImage != null) {
        doctorImageUrl = await _uploadImage(
          _doctorImage!,
          'clinics/${DateTime.now().millisecondsSinceEpoch}_doctor.jpg',
        );
      }

      // Create doctor account in Firebase Auth
      String? doctorUserId;
      // Note: The doctor will sign in with Google Sign-In later
      // We create a placeholder user record that will be linked when they first sign in
      // For now, we'll use the email as a temporary identifier
      doctorUserId = null; // Will be set when doctor signs in with Google

      // Prepare working hours
      Map<String, WorkingHours> workingHours = {};
      _workingHoursFrom.forEach((day, from) {
        final to = _workingHoursTo[day];
        final isClosed = _isClosedDays[day] ?? false;
        
        if (from != null && to != null) {
          workingHours[day] = WorkingHours(
            from: _formatTimeOfDay(from),
            to: _formatTimeOfDay(to),
            isClosed: isClosed,
          );
        }
      });

      // Collect auth emails (filter out empty ones)
      final authEmails = _authEmailControllers
          .map((controller) => controller.text.trim())
          .where((email) => email.isNotEmpty)
          .toList();

      // Create clinic model
      final clinic = ClinicModel(
        id: '',
        doctorName: _doctorNameController.text.trim(),
        department: _selectedDepartment!,
        specialization: _specializationController.text.trim(),
        about: _aboutController.text.trim(),
        consultationFee: _consultationFeeController.text.trim().isEmpty 
            ? 0.0 
            : double.parse(_consultationFeeController.text.trim()),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty 
            ? null 
            : _whatsappController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        authEmails: authEmails,
        doctorPhone: _doctorPhoneController.text.trim(),
        workingHours: workingHours,
        holidays: [],
        hasNursery: _hasNursery,
        onlineBookingEnabled: _onlineBookingEnabled,
        clinicImageUrl: clinicImageUrl,
        doctorImageUrl: doctorImageUrl,
        ownerId: doctorUserId, // Link clinic to doctor
        createdAt: DateTime.now(),
      );

      // Add to Firestore
      await _clinicRepo.addClinic(clinic);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة العيادة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'إضافة عيادة جديدة',
            style: TextStyle(fontWeight: FontWeight.bold , color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Doctor Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.teal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'معلومات الدكتور',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),
                        TextFormField(
                  controller: _doctorNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الدكتور *',
                    prefixIcon: const Icon(Icons.person, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اسم الدكتور مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Department Dropdown
                DropdownButtonFormField<ClinicDepartment>(
                  value: _selectedDepartment,
                  decoration: InputDecoration(
                    labelText: 'التخصص *',
                    prefixIcon: const Icon(Icons.medical_services, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                  items: ClinicDepartment.values
                      .where((dept) => dept != ClinicDepartment.other)
                      .map((dept) {
                    return DropdownMenuItem(
                      value: dept,
                      child: Text(dept.arabicName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'التخصص مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Specialization
                TextFormField(
                  controller: _specializationController,
                  decoration: InputDecoration(
                    labelText: 'التخصص الدقيق *',
                    hintText: _getSpecializationHint(),
                    prefixIcon: const Icon(Icons.local_hospital, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    helperText: 'يساعد المرضى في العثور على التخصص المناسب',
                    helperStyle: const TextStyle(fontSize: 12),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'التخصص الدقيق مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nursery availability (only for pediatrics)
                if (_selectedDepartment == ClinicDepartment.pediatrics) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.child_care, color: Colors.teal, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'يوجد حضانة بالعيادة؟',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('نعم'),
                                value: true,
                                groupValue: _hasNursery,
                                onChanged: (value) {
                                  setState(() {
                                    _hasNursery = value ?? false;
                                  });
                                },
                                activeColor: Colors.teal,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('لا'),
                                value: false,
                                groupValue: _hasNursery,
                                onChanged: (value) {
                                  setState(() {
                                    _hasNursery = value ?? false;
                                  });
                                },
                                activeColor: Colors.teal,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Online Booking Enabled
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'متاح الحجز أونلاين؟',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('نعم'),
                              value: true,
                              groupValue: _onlineBookingEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _onlineBookingEnabled = value ?? false;
                                });
                              },
                              activeColor: Colors.teal,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('لا'),
                              value: false,
                              groupValue: _onlineBookingEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _onlineBookingEnabled = value ?? false;
                                });
                              },
                              activeColor: Colors.teal,
                              contentPadding: EdgeInsets.zero,
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
                const SizedBox(height: 16),

                // About Doctor Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.teal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'نبذة وبيانات إضافية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),
                        TextFormField(
                  controller: _aboutController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'نبذة عن الدكتور',
                    hintText: 'المؤهلات والخبرات',
                    prefixIcon: const Icon(Icons.description, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Consultation Fee
                TextFormField(
                  controller: _consultationFeeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'سعر الكشف (جنيه) - اختياري',
                    hintText: 'اترك فارغاً إذا لم يتم تحديده',
                    prefixIcon: const Icon(Icons.payments, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (double.tryParse(value.trim()) == null) {
                        return 'أدخل رقم صحيح';
                      }
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
                    prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'رقم الهاتف مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // WhatsApp
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم واتساب (اختياري)',
                    prefixIcon:  Icon(MdiIcons.whatsapp, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Doctor Account Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_circle_outlined,
                                color: Colors.teal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'بيانات حساب الدكتور',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Doctor Phone
                        TextFormField(
                  controller: _doctorPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم تليفون الدكتور *',
                    prefixIcon: const Icon(Icons.phone_android, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    helperText: 'رقم الدكتور الشخصي (لن يظهر للمرضى)',
                    helperStyle: const TextStyle(fontSize: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'رقم تليفون الدكتور مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Auth Emails Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'إيميلات المصادقة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'يمكن إضافة أكثر من إيميل للدخول إلى لوحة التحكم',
                          child: Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_authEmailControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _authEmailControllers[index],
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'إيميل المصادقة ${index + 1} ${index == 0 ? '*' : ''}',
                                  prefixIcon: const Icon(Icons.email, color: Colors.teal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                                  ),
                                  helperText: index == 0 ? 'سيستخدم لتسجيل الدخول' : null,
                                  helperStyle: const TextStyle(fontSize: 12),
                                ),
                                validator: (value) {
                                  if (index == 0 && (value == null || value.trim().isEmpty)) {
                                    return 'يجب إدخال إيميل واحد على الأقل';
                                  }
                                  if (value != null && value.trim().isNotEmpty && !value.contains('@')) {
                                    return 'إيميل غير صحيح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (_authEmailControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _authEmailControllers[index].dispose();
                                    _authEmailControllers.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('إضافة إيميل آخر للمصادقة'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.teal,
                      ),
                      onPressed: () {
                        setState(() {
                          _authEmailControllers.add(TextEditingController());
                        });
                      },
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Address Section Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.teal,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'الموقع والعنوان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    labelText: 'العنوان *',
                    prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'العنوان مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Location Section
                if (_latitude != 0.0 && _longitude != 0.0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'تم تحديد الموقع',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'خط العرض: ${_latitude.toStringAsFixed(6)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          'خط الطول: ${_longitude.toStringAsFixed(6)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.touch_app, size: 22),
                    label: Text(
                      _isLoadingLocation
                          ? 'جاري تحديد الموقع...'
                          : (_latitude != 0.0 && _longitude != 0.0)
                              ? 'تحديث الموقع'
                              : 'تحديد الموقع التلقائي',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (_latitude == 0.0 && _longitude == 0.0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 16),
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
                const SizedBox(height: 24),

                // Images Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library, color: Colors.teal, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'الصور',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildImagePicker(
                        'صورة العيادة',
                        _clinicImage,
                        () => _pickImage(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildImagePicker(
                        'صورة الدكتور',
                        _doctorImage,
                        () => _pickImage(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Working Hours
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.teal, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'مواعيد العمل',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildWorkingHoursSection(),
                const SizedBox(height: 32),

                // Submit Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.teal,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle, size: 24),
                    label: Text(
                      _isSubmitting ? 'جاري الإضافة...' : 'إضافة العيادة',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, File? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: image == null ? Colors.teal.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: image == null
                ? Colors.teal.withOpacity(0.4)
                : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (image != null)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      size: 36,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.teal,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اضغط للاختيار',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWorkingHoursSection() {
    final daysArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: daysArabic.entries.map((entry) {
            final day = entry.key;
            final dayArabic = entry.value;
            final isClosed = _isClosedDays[day] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isClosed
                    ? Colors.red.withOpacity(0.05)
                    : Colors.teal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isClosed
                      ? Colors.red.withOpacity(0.2)
                      : Colors.teal.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isClosed
                              ? Colors.red.withOpacity(0.1)
                              : Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isClosed ? Icons.event_busy : Icons.event_available,
                          size: 18,
                          color: isClosed ? Colors.red : Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dayArabic,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isClosed
                              ? Colors.red.withOpacity(0.15)
                              : Colors.teal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isClosed ? 'إجازة' : 'متاح',
                          style: TextStyle(
                            fontSize: 12,
                            color: isClosed ? Colors.red : Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: !isClosed,
                        onChanged: (value) {
                          setState(() {
                            _isClosedDays[day] = !value;
                          });
                        },
                        activeColor: Colors.teal,
                      ),
                    ],
                  ),
                  if (!isClosed) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _workingHoursFrom[day] ?? 
                                    const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (time != null) {
                                setState(() {
                                  _workingHoursFrom[day] = time;
                                });
                              }
                            },
                            icon: const Icon(Icons.access_time, size: 18),
                            label: Text(
                              'من: ${_formatTimeOfDay(_workingHoursFrom[day] ?? const TimeOfDay(hour: 9, minute: 0))}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B).withOpacity(0.1),
                              foregroundColor: const Color(0xFFF59E0B),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _workingHoursTo[day] ?? 
                                    const TimeOfDay(hour: 17, minute: 0),
                              );
                              if (time != null) {
                                setState(() {
                                  _workingHoursTo[day] = time;
                                });
                              }
                            },
                            icon: const Icon(Icons.access_time, size: 18),
                            label: Text(
                              'إلى: ${_formatTimeOfDay(_workingHoursTo[day] ?? const TimeOfDay(hour: 17, minute: 0))}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B).withOpacity(0.1),
                              foregroundColor: const Color(0xFFF59E0B),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
