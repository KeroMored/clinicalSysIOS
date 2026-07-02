import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../nursing/data/models/nurse_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class AddNurseScreen extends StatefulWidget {
  const AddNurseScreen({super.key});

  @override
  State<AddNurseScreen> createState() => _AddNurseScreenState();
}

class _AddNurseScreenState extends State<AddNurseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _nurseNameController = TextEditingController();
  final _nursePhoneController = TextEditingController();
  final _nurseWhatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _aboutController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();

  String _selectedGender = 'male';
  String _selectedSpecialization = NurseSpecializations.general;
  final Set<String> _selectedServices = {};

  String _availabilityMode = 'days'; // 'days' or '24hours'

  // Working Hours for 7 days
  final Map<String, TimeOfDay?> _workingHoursFrom = {};
  final Map<String, TimeOfDay?> _workingHoursTo = {};
  final Map<String, bool> _isClosedDays = {};

  XFile? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize working hours with default values (all days OPEN by default)
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
      _workingHoursFrom[day] = const TimeOfDay(hour: 9, minute: 0);
      _workingHoursTo[day] = const TimeOfDay(hour: 17, minute: 0);
      _isClosedDays[day] = false; // All days open by default
    }
  }

  @override
  void dispose() {
    _nurseNameController.dispose();
    _nursePhoneController.dispose();
    _nurseWhatsappController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    _yearsOfExperienceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<String?> _uploadImage(XFile image, String folder) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final Reference storageRef = FirebaseStorage.instance.ref().child(
        'nurses/$folder/$fileName',
      );

      final File file = File(image.path);
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار خدمة واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload profile image if selected
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadImage(_profileImage!, 'profiles');
      }

      // Create working hours map for all 7 days
      Map<String, WorkingHours>? workingHours;
      final bool available24Hours = _availabilityMode == '24hours';

      if (!available24Hours) {
        workingHours = {};
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
          final isClosed = _isClosedDays[day] ?? false;
          final fromTime = _workingHoursFrom[day];
          final toTime = _workingHoursTo[day];

          if (fromTime != null && toTime != null) {
            workingHours[day] = WorkingHours(
              openTime: _formatTimeOfDay(fromTime),
              closeTime: _formatTimeOfDay(toTime),
              isHoliday: isClosed,
            );
          }
        }
      }

      // Create nurse model
      final nurse = NurseModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nurseName: _nurseNameController.text.trim(),
        nursePhone: _nursePhoneController.text.trim(),
        nurseWhatsApp: _nurseWhatsappController.text.trim(),
        gender: _selectedGender,
        yearsOfExperience: int.parse(_yearsOfExperienceController.text.trim()),
        specialization: _selectedSpecialization,
        about: _aboutController.text.trim(),
        services: _selectedServices.toList(),
        hourlyRate: 0.0, // No hourly rate needed
        address: _addressController.text.trim(),
        governorate: '', // Empty as requested
        city: '', // Empty as requested
        latitude: 0.0, // Default value
        longitude: 0.0, // Default value
        email: null, // No email needed
        nationalId: null,
        licenseNumber: null,
        profileImageUrl: profileImageUrl,
        licenseImageUrl: null,
        nationalIdImageUrl: null,
        availableNow: false,
        available24Hours: available24Hours,
        workingHours: workingHours,
        isApproved: false, // Pending - needs admin approval
        isActive: false,
        status: 'pending', // Set as pending - waiting for approval
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rating: 0.0,
        reviewCount: 0,
        notes: 'تمت الإضافة من قبل الأدمن - في انتظار الموافقة',
      );

      // Add nurse using cubit
      if (mounted) {
        context.read<AdminCubit>().addNurse(nurse);
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
    return BlocListener<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state is NurseAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت إضافة الممرض بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is AdminError) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('إضافة ممرض جديد'),
            backgroundColor: const Color(0xFF06B6D4),
            foregroundColor: Colors.white,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Basic Information Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'البيانات الأساسية',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        _buildTextField(
                          controller: _nurseNameController,
                          label: 'اسم الممرض',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال اسم الممرض';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Gender Selection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'الجنس',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('ذكر'),
                                        value: 'male',
                                        groupValue: _selectedGender,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGender = value!;
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('أنثى'),
                                        value: 'female',
                                        groupValue: _selectedGender,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGender = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _yearsOfExperienceController,
                          label: 'سنوات الخبرة',
                          icon: Icons.work,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال سنوات الخبرة';
                            }
                            if (int.tryParse(value) == null) {
                              return 'رقم غير صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Specialization Dropdown
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: DropdownButtonFormField<String>(
                              value: _selectedSpecialization,
                              decoration: const InputDecoration(
                                labelText: 'التخصص',
                                prefixIcon: Icon(Icons.medical_services),
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  [
                                    NurseSpecializations.general,
                                    NurseSpecializations.pediatric,
                                    NurseSpecializations.geriatric,
                                    NurseSpecializations.surgical,
                                    NurseSpecializations.icu,
                                    NurseSpecializations.emergency,
                                    NurseSpecializations.maternity,
                                  ].map((specialization) {
                                    return DropdownMenuItem<String>(
                                      value: specialization,
                                      child: Text(specialization),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSpecialization = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _aboutController,
                          label: 'نبذة عن الممرض',
                          icon: Icons.info,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال نبذة عن الممرض';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Services Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الخدمات المقدمة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              [
                                NursingServices.injection,
                                NursingServices.bloodPressure,
                                NursingServices.bloodSugar,
                                NursingServices.woundCare,
                                NursingServices.ivDrip,
                                NursingServices.catheter,
                                NursingServices.physiotherapy,
                                NursingServices.elderCare,
                                NursingServices.postOperativeCare,
                                NursingServices.infantCare,
                                NursingServices.oxygenTherapy,
                                NursingServices.nasogastricTube,
                              ].map((service) {
                                return FilterChip(
                                  label: Text(service),
                                  selected: _selectedServices.contains(service),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedServices.add(service);
                                      } else {
                                        _selectedServices.remove(service);
                                      }
                                    });
                                  },
                                  selectedColor: const Color(
                                    0xFF06B6D4,
                                  ).withOpacity(0.3),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Contact Information Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معلومات التواصل',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        _buildTextField(
                          controller: _nursePhoneController,
                          label: 'رقم الهاتف',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال رقم الهاتف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _nurseWhatsappController,
                          label: 'رقم الواتساب',
                          icon: FontAwesomeIcons.whatsapp,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال رقم الواتساب';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Address Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'العنوان',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        _buildTextField(
                          controller: _addressController,
                          label: 'العنوان التفصيلي',
                          icon: Icons.location_on,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال العنوان';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Availability Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التوفر ومواعيد العمل',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'نظام العمل',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                RadioListTile<String>(
                                  title: const Text('متاح 24 ساعة'),
                                  value: '24hours',
                                  groupValue: _availabilityMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _availabilityMode = value!;
                                    });
                                  },
                                ),
                                RadioListTile<String>(
                                  title: const Text('متاح في أيام محددة'),
                                  value: 'days',
                                  groupValue: _availabilityMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _availabilityMode = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_availabilityMode == 'days')
                          _buildWorkingHoursSection(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Image Section (Optional)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الصورة الشخصية',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const Divider(),
                        _buildImagePicker(
                          'الصورة الشخصية',
                          _profileImage,
                          _pickImage,
                        ),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
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
                          'إضافة الممرض',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildImagePicker(String label, XFile? image, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(
          image == null ? Icons.add_photo_alternate : Icons.check_circle,
          color: image == null ? Colors.grey : Colors.green,
        ),
        title: Text(label),
        subtitle: image == null
            ? const Text('لم يتم اختيار صورة')
            : Text('تم اختيار: ${image.name}'),
        trailing: image == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _profileImage = null;
                  });
                },
              ),
        onTap: onTap,
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: daysArabic.entries.map((entry) {
            final day = entry.key;
            final dayArabic = entry.value;
            final isClosed = _isClosedDays[day] ?? false;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dayArabic,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        isClosed ? 'إجازة' : 'متاح',
                        style: TextStyle(
                          fontSize: 13,
                          color: isClosed ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: !isClosed, // Inverted: ON = متاح, OFF = إجازة
                        onChanged: (value) {
                          setState(() {
                            _isClosedDays[day] = !value; // Inverted
                          });
                        },
                      ),
                    ],
                  ),
                  if (!isClosed) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime:
                                    _workingHoursFrom[day] ??
                                    const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (time != null) {
                                setState(() {
                                  _workingHoursFrom[day] = time;
                                });
                              }
                            },
                            child: Text(
                              'من: ${_formatTimeOfDay(_workingHoursFrom[day] ?? const TimeOfDay(hour: 9, minute: 0))}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime:
                                    _workingHoursTo[day] ??
                                    const TimeOfDay(hour: 17, minute: 0),
                              );
                              if (time != null) {
                                setState(() {
                                  _workingHoursTo[day] = time;
                                });
                              }
                            },
                            child: Text(
                              'إلى: ${_formatTimeOfDay(_workingHoursTo[day] ?? const TimeOfDay(hour: 17, minute: 0))}',
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
