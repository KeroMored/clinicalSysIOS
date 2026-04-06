import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../data/models/rehabilitation_center_model.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class EditRehabilitationCenterScreen extends StatefulWidget {
  final RehabilitationCenterModel center;

  const EditRehabilitationCenterScreen({super.key, required this.center});

  @override
  State<EditRehabilitationCenterScreen> createState() =>
      _EditRehabilitationCenterScreenState();
}

class _EditRehabilitationCenterScreenState
    extends State<EditRehabilitationCenterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _centerNameController;
  late TextEditingController _directorNameController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;

  File? _profileImage;
  bool _isLoading = false;
  late bool _hasHomeService;
  late List<String> _selectedServiceTypes;

  // Auth Emails
  late List<TextEditingController> _authEmailControllers;

  // Working Days
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
    _centerNameController = TextEditingController(
      text: widget.center.centerName,
    );
    _directorNameController = TextEditingController(
      text: widget.center.directorName,
    );
    _phoneController = TextEditingController(text: widget.center.phone);
    _whatsappController = TextEditingController(
      text: widget.center.whatsapp ?? '',
    );
    _addressController = TextEditingController(text: widget.center.address);
    _descriptionController = TextEditingController(
      text: widget.center.description,
    );

    _hasHomeService = widget.center.hasHomeService;
    _selectedServiceTypes = List.from(widget.center.serviceTypes);

    // Initialize auth emails
    _authEmailControllers = widget.center.authEmails.isNotEmpty
        ? widget.center.authEmails
              .map((email) => TextEditingController(text: email))
              .toList()
        : [TextEditingController()];

    // Initialize working hours from existing center data
    for (var i = 0; i < _englishDays.length; i++) {
      final day = _englishDays[i];
      final hours = widget.center.workingDays[day];

      if (hours != null) {
        _isClosedDays[day] = hours.isClosed;
        if (!hours.isClosed) {
          _workingHoursFrom[day] = _parseTimeOfDay(hours.from);
          _workingHoursTo[day] = _parseTimeOfDay(hours.to);
        }
      } else {
        _isClosedDays[day] = false;
      }
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void dispose() {
    _centerNameController.dispose();
    _directorNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    for (var controller in _authEmailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'rehabilitation/profiles/${widget.center.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
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

  Future<void> _updateCenter() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServiceTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار نوع واحد على الأقل من الخدمات'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? profileImageUrl = widget.center.profileImageUrl;

      if (_profileImage != null) {
        profileImageUrl = await _uploadImage(_profileImage!);
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

      // Convert working hours to Map
      Map<String, dynamic> workingDaysMap = {};
      workingDays.forEach((day, hours) {
        workingDaysMap[day] = hours.toMap();
      });

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('rehabilitation_centers')
          .doc(widget.center.id)
          .update({
            'centerName': _centerNameController.text.trim(),
            'directorName': _directorNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'whatsapp': _whatsappController.text.trim().isEmpty
                ? null
                : _whatsappController.text.trim(),
            'address': _addressController.text.trim(),
            'description': _descriptionController.text.trim(),
            'workingDays': workingDaysMap,
            'serviceTypes': _selectedServiceTypes,
            'hasHomeService': _hasHomeService,
            'authEmails': _authEmailControllers
                .map((c) => c.text.trim())
                .where((email) => email.isNotEmpty)
                .toList(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
            if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات المركز بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
            'تعديل بيانات المركز',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile Image
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: _profileImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : widget.center.profileImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.center.profileImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'صورة المركز',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Center Name
                    TextFormField(
                      controller: _centerNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المركز *',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اسم المركز مطلوب';
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
                        if (value == null || value.trim().isEmpty) {
                          return 'اسم المدير مطلوب';
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
                      decoration: InputDecoration(
                        labelText: 'واتساب (اختياري)',
                        prefixIcon: Icon(MdiIcons.whatsapp),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'العنوان *',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'العنوان مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'وصف المركز *',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الوصف مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Auth Emails Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.email_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'إيميلات المصادقة',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'الإيميلات المسموح لها بالدخول',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._authEmailControllers.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: controller,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'إيميل ${index + 1}',
                                    prefixIcon: const Icon(Icons.email),
                                    suffixIcon: _authEmailControllers.length > 1
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                controller.dispose();
                                                _authEmailControllers.removeAt(
                                                  index,
                                                );
                                              });
                                            },
                                          )
                                        : null,
                                    border: const OutlineInputBorder(),
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
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _authEmailControllers.add(
                                      TextEditingController(),
                                    );
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة إيميل جديد'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Service Types
                    const Text(
                      'أنواع الخدمات *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RehabilitationTypes.allTypes.map((type) {
                        return FilterChip(
                          label: Text(
                            type,
                            style: TextStyle(color: Colors.black),
                          ),
                          selected: _selectedServiceTypes.contains(type),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServiceTypes.add(type);
                              } else {
                                _selectedServiceTypes.remove(type);
                              }
                            });
                          },
                          selectedColor: Colors.purple.shade100,
                          checkmarkColor: Colors.purple,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Working Hours Section
                    const Text(
                      'مواعيد العمل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

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
                                        activeColor: Colors.purple,
                                        onChanged: (value) {
                                          setState(() {
                                            _isClosedDays[englishDay] = value;
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
                                        icon: const Icon(Icons.access_time),
                                        label: Text(
                                          _workingHoursFrom[englishDay] != null
                                              ? 'من: ${_formatTimeOfDay(_workingHoursFrom[englishDay]!)}'
                                              : 'من: مغلق',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.purple,
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
                                        icon: const Icon(Icons.access_time),
                                        label: Text(
                                          _workingHoursTo[englishDay] != null
                                              ? 'إلى: ${_formatTimeOfDay(_workingHoursTo[englishDay]!)}'
                                              : 'إلى: مغلق',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.purple,
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
                    const SizedBox(height: 24),

                    // Home Service
                    SwitchListTile(
                      title: const Text('يوجد خدمة منزلية'),
                      value: _hasHomeService,
                      activeColor: Colors.purple,
                      onChanged: (value) {
                        setState(() {
                          _hasHomeService = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Update Button
                    ElevatedButton(
                      onPressed: _updateCenter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('حفظ التعديلات'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
