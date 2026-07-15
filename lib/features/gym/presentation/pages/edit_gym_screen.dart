import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/gym_model.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class EditGymScreen extends StatefulWidget {
  final GymModel gym;

  const EditGymScreen({super.key, required this.gym});

  @override
  State<EditGymScreen> createState() => _EditGymScreenState();
}

class _EditGymScreenState extends State<EditGymScreen> {
  final _formKey = GlobalKey<FormState>();

  static const Color _primaryColor = Color(0xFF0891B2);
  static const Color _secondaryColor = Color(0xFF06B6D4);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  final ImagePicker _imagePicker = ImagePicker();

  // Basic
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late List<TextEditingController> _phoneControllers;
  late TextEditingController _whatsappController;
  late TextEditingController _ownerNameController;

  // Location
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Pricing
  late TextEditingController _monthlyController;
  late TextEditingController _yearlyController;
  late TextEditingController _singleSessionController;

  // Auth Emails
  late List<TextEditingController> _authEmailControllers;

  // Images
  File? _newLogoFile;
  String? _existingLogoUrl;
  final List<File> _newImages = [];
  List<String> _existingImages = [];

  // Sections
  bool _hasMaleSection = false;
  bool _hasFemaleSection = false;

  // Features - Dynamic list
  final List<TextEditingController> _featureControllers = [];

  bool _isSaving = false;

  final List<String> _daysOfWeek = const [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  final Map<String, String> _dayNamesArabic = const {
    'saturday': 'السبت',
    'sunday': 'الأحد',
    'monday': 'الاثنين',
    'tuesday': 'الثلاثاء',
    'wednesday': 'الأربعاء',
    'thursday': 'الخميس',
    'friday': 'الجمعة',
  };

  final Map<String, List<Map<String, TextEditingController>>> _maleTimeControllers = {};
  final Map<String, List<Map<String, TextEditingController>>> _femaleTimeControllers = {};
  final Map<String, bool> _maleDayClosed = {};
  final Map<String, bool> _femaleDayClosed = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initTimeControllers();
  }

  void _initControllers() {
    final gym = widget.gym;

    _nameController = TextEditingController(text: gym.name);
    _descriptionController = TextEditingController(text: gym.description);
    _addressController = TextEditingController(text: gym.address);
    _phoneControllers = gym.phones.isNotEmpty
        ? gym.phones.map((p) => TextEditingController(text: p)).toList()
        : [TextEditingController()];
    _whatsappController = TextEditingController(text: gym.whatsapp);
    _ownerNameController = TextEditingController(text: gym.ownerName);

    _latitude = gym.latitude;
    _longitude = gym.longitude;

    _monthlyController = TextEditingController(
      text: gym.monthlySubscription?.toString() ?? '',
    );
    _yearlyController = TextEditingController(
      text: gym.yearlySubscription?.toString() ?? '',
    );
    _singleSessionController = TextEditingController(
      text: gym.singleSessionPrice?.toString() ?? '',
    );

    _authEmailControllers = gym.authEmails.isNotEmpty
        ? gym.authEmails.map((e) => TextEditingController(text: e)).toList()
        : [TextEditingController()];

    _existingLogoUrl = gym.logoUrl;
    _existingImages = List<String>.from(gym.images);

    _hasMaleSection = gym.hasMaleSection;
    _hasFemaleSection = gym.hasFemaleSection;

    // Initialize feature controllers from gym data
    if (gym.features.isNotEmpty) {
      _featureControllers.addAll(
        gym.features.map((f) => TextEditingController(text: f)),
      );
    } else {
      // Initialize with at least one empty controller
      _featureControllers.add(TextEditingController());
    }
  }

  void _initTimeControllers() {
    for (final day in _daysOfWeek) {
      final male = widget.gym.maleWorkingHours[day];
      final female = widget.gym.femaleWorkingHours[day];

      // Initialize male slots
      if (male != null && male.slots.isNotEmpty) {
        _maleTimeControllers[day] = male.slots.map((slot) {
          return {
            'start': TextEditingController(text: slot.from),
            'end': TextEditingController(text: slot.to),
          };
        }).toList();
      } else {
        _maleTimeControllers[day] = [
          {
            'start': TextEditingController(text: '08:00'),
            'end': TextEditingController(text: '22:00'),
          }
        ];
      }

      // Initialize female slots
      if (female != null && female.slots.isNotEmpty) {
        _femaleTimeControllers[day] = female.slots.map((slot) {
          return {
            'start': TextEditingController(text: slot.from),
            'end': TextEditingController(text: slot.to),
          };
        }).toList();
      } else {
        _femaleTimeControllers[day] = [
          {
            'start': TextEditingController(text: '08:00'),
            'end': TextEditingController(text: '14:00'),
          }
        ];
      }

      _maleDayClosed[day] = male == null || male.isClosed;
      _femaleDayClosed[day] = female == null || female.isClosed;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _whatsappController.dispose();
    _ownerNameController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    _singleSessionController.dispose();

    for (final c in _phoneControllers) {
      c.dispose();
    }

    for (final c in _authEmailControllers) {
      c.dispose();
    }

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

    // Dispose feature controllers
    for (var controller in _featureControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض إذن الموقع');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('إذن الموقع مرفوض نهائيا. فعله من إعدادات الجهاز');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الإحداثيات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحديد الموقع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.15),
                        _secondaryColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    setState(() {
      _newLogoFile = File(image.path);
    });
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage();
    if (images.isEmpty || !mounted) return;
    setState(() {
      for (final img in images) {
        _newImages.add(File(img.path));
      }
    });
  }

  Future<String> _uploadSingleFile(File file, String folder) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance
        .ref()
        .child('gyms')
        .child(widget.gym.id)
        .child(folder)
        .child('$fileName.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
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

  Future<void> _selectTime(TextEditingController controller) async {
    final parts = controller.text.split(':');
    TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0);
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        initial = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
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

  Widget _buildDayRow({
    required String dayKey,
    required String dayName,
    required List<Map<String, TextEditingController>> slotControllers,
    required bool isClosed,
    required ValueChanged<bool> onClosedChanged,
    required Color color,
    required bool isMale,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: isClosed,
                      activeColor: color,
                      onChanged: (v) => onClosedChanged(v ?? false),
                    ),
                    const Text('مفتوح'),
                    Radio<bool>(
                      value: true,
                      groupValue: isClosed,
                      activeColor: Colors.grey,
                      onChanged: (v) => onClosedChanged(v ?? true),
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
                            decoration: const InputDecoration(
                              labelText: 'من',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(slotControllers[index]['start']!.text),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(slotControllers[index]['end']!),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'إلى',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(slotControllers[index]['end']!.text),
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
                    foregroundColor: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, GymWorkingHours> _collectWorkingHours(
    bool enabled,
    Map<String, List<Map<String, TextEditingController>>> controllers,
    Map<String, bool> closedMap,
  ) {
    if (!enabled) return {};

    final result = <String, GymWorkingHours>{};
    for (final day in _daysOfWeek) {
      final isClosed = closedMap[day] ?? true;
      if (!isClosed) {
        final slots = controllers[day]!.map((slotControllers) {
          return TimeSlot(
            from: slotControllers['start']!.text,
            to: slotControllers['end']!.text,
          );
        }).toList();
        
        result[day] = GymWorkingHours(
          slots: slots,
          isClosed: false,
        );
      }
    }
    return result;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasMaleSection && !_hasFemaleSection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار قسم واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final maleWorking = _collectWorkingHours(
      _hasMaleSection,
      _maleTimeControllers,
      _maleDayClosed,
    );
    final femaleWorking = _collectWorkingHours(
      _hasFemaleSection,
      _femaleTimeControllers,
      _femaleDayClosed,
    );

    if (_hasMaleSection && maleWorking.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدد يومًا مفتوحًا على الأقل للقسم الرجالي'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hasFemaleSection && femaleWorking.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدد يومًا مفتوحًا على الأقل للقسم النسائي'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? finalLogoUrl = _existingLogoUrl;
      if (_newLogoFile != null) {
        finalLogoUrl = await _uploadSingleFile(_newLogoFile!, 'logo');
      }

      final uploadedNewImages = <String>[];
      for (final image in _newImages) {
        uploadedNewImages.add(await _uploadSingleFile(image, 'images'));
      }
      final allImages = [..._existingImages, ...uploadedNewImages];

      final authEmails = _authEmailControllers
          .map((c) => c.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final phones = _phoneControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (phones.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب إضافة رقم هاتف واحد على الأقل'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final updateData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': _latitude ?? widget.gym.latitude,
        'longitude': _longitude ?? widget.gym.longitude,
        'phones': phones,
        'whatsapp': _whatsappController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'authEmails': authEmails,
        'logoUrl': finalLogoUrl,
        'images': allImages,
        'hasMaleSection': _hasMaleSection,
        'hasFemaleSection': _hasFemaleSection,
        'maleWorkingHours': maleWorking.map((k, v) => MapEntry(k, v.toMap())),
        'femaleWorkingHours': femaleWorking.map(
          (k, v) => MapEntry(k, v.toMap()),
        ),
        'monthlySubscription': double.tryParse(_monthlyController.text.trim()),
        'yearlySubscription': double.tryParse(_yearlyController.text.trim()),
        'singleSessionPrice': double.tryParse(
          _singleSessionController.text.trim(),
        ),
        'features': _featureControllers
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
        'trainingTypes': [], // Empty since we removed training types section
        // Keep old boolean fields for backward compatibility
        'hasPersonalTraining': false,
        'hasNutritionConsultation': false,
        'hasSwimmingPool': false,
        'hasSauna': false,
        'hasSteamRoom': false,
        'hasYogaClasses': false,
        'hasCrossFit': false,
        'hasMartialArts': false,
        'hasCardio': false,
        'hasWeightLifting': false,
        'hasBodybuilding': false,
        'hasFunctionalTraining': false,
        'hasGroupClasses': false,
      };

      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gym.id)
          .update(updateData);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث بيانات الجيم بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildFeatureSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
      ),
      secondary: Icon(icon, color: _primaryColor),
      activeColor: _primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  List<Widget> _buildDynamicTextFields({
    required List<TextEditingController> controllers,
    required String label,
    required IconData icon,
    required VoidCallback onAdd,
    required Function(int) onRemove,
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
                  decoration: _inputDecoration(
                    label: '$label ${i + 1}',
                    icon: icon,
                  ).copyWith(
                    suffixIcon: controllers.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => onRemove(i),
                          )
                        : null,
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
            foregroundColor: _primaryColor,
            side: const BorderSide(color: _primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
    );

    return widgets;
  }

  Widget _buildImageTile({
    String? url,
    File? file,
    required VoidCallback onRemove,
    bool isNew = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isNew
                  ? Colors.green.withOpacity(0.3)
                  : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url != null
                ? Image.network(url, fit: BoxFit.cover)
                : Image.file(file!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          left: -2,
          top: -2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 15),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: _isSaving
            ? const Center(child: AppLoadingIndicator(color: _primaryColor))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 140,
                    pinned: true,
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
                          onPressed: _save,
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
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              'تعديل بيانات الجيم',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _sectionCard(
                              title: 'المعلومات الأساسية',
                              icon: Icons.info_outline_rounded,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _inputDecoration(
                                    label: 'اسم الجيم',
                                    icon: Icons.fitness_center_rounded,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'مطلوب'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: _inputDecoration(
                                    label: 'الوصف',
                                    icon: Icons.description_rounded,
                                  ),
                                  maxLines: 3,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'مطلوب'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: _inputDecoration(
                                    label: 'العنوان',
                                    icon: Icons.location_on_rounded,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'مطلوب'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                          (_latitude != null &&
                                              _longitude != null)
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFE2E8F0),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            (_latitude != null &&
                                                    _longitude != null)
                                                ? Icons.check_circle
                                                : Icons.location_searching,
                                            color:
                                                (_latitude != null &&
                                                    _longitude != null)
                                                ? const Color(0xFF10B981)
                                                : _primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            (_latitude != null &&
                                                    _longitude != null)
                                                ? 'الإحداثيات  '
                                                : 'الإحداثيات غير متاحة',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  (_latitude != null &&
                                                      _longitude != null)
                                                  ? const Color(0xFF10B981)
                                                  : _textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (_latitude != null &&
                                          _longitude != null)
                                        Text(
                                          'Lat: ${_latitude!.toStringAsFixed(6)} | Long: ${_longitude!.toStringAsFixed(6)}',
                                          style: const TextStyle(
                                            color: _textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isLoadingLocation
                                              ? null
                                              : _getCurrentLocation,
                                          icon: _isLoadingLocation
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: AppLoadingIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.my_location),
                                          label: Text(
                                            (_latitude != null &&
                                                    _longitude != null)
                                                ? 'إعادة تحديد الإحداثيات تلقائيا'
                                                : 'تحديد الإحداثيات تلقائيا',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionCard(
                              title: 'التواصل والمالك',
                              icon: Icons.contact_phone,
                              children: [
                                // Dynamic phone fields
                                ..._buildDynamicPhoneFields(),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _whatsappController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration(
                                    label: 'رقم الواتساب',
                                    icon: Icons.chat,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'مطلوب'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _ownerNameController,
                                  decoration: _inputDecoration(
                                    label: 'اسم المالك',
                                    icon: Icons.person,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'مطلوب'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                ..._authEmailControllers.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final controller = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: controller,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: _inputDecoration(
                                              label:
                                                  'إيميل المصادقة ${index + 1}',
                                              icon: Icons.email,
                                            ),
                                            validator: (v) {
                                              if (v == null || v.trim().isEmpty)
                                                return 'مطلوب';
                                              if (!v.contains('@'))
                                                return 'صيغة غير صحيحة';
                                              return null;
                                            },
                                          ),
                                        ),
                                        if (_authEmailControllers.length > 1)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle,
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
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _authEmailControllers.add(
                                          TextEditingController(),
                                        );
                                      });
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                    label: const Text('إضافة إيميل'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionCard(
                              title: 'اللوجو والصور',
                              icon: Icons.photo_library_rounded,
                              children: [
                                if (_existingLogoUrl != null ||
                                    _newLogoFile != null)
                                  SizedBox(
                                    height: 140,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: _newLogoFile != null
                                                ? Image.file(
                                                    _newLogoFile!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.network(
                                                    _existingLogoUrl!,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          left: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'اللوجو',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _pickLogo,
                                  icon: const Icon(Icons.image_rounded),
                                  label: Text(
                                    _newLogoFile == null
                                        ? 'اختيار/تغيير اللوجو'
                                        : 'تغيير اللوجو',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_existingImages.isNotEmpty ||
                                    _newImages.isNotEmpty)
                                  SizedBox(
                                    height: 110,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        ..._existingImages.asMap().entries.map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: 10,
                                            ),
                                            child: _buildImageTile(
                                              url: e.value,
                                              onRemove: () {
                                                setState(() {
                                                  _existingImages.removeAt(
                                                    e.key,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        ..._newImages.asMap().entries.map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: 10,
                                            ),
                                            child: _buildImageTile(
                                              file: e.value,
                                              isNew: true,
                                              onRemove: () {
                                                setState(() {
                                                  _newImages.removeAt(e.key);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _pickImages,
                                  icon: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                  ),
                                  label: const Text('إضافة صور الجيم'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionCard(
                              title: 'الأقسام والمواعيد',
                              icon: Icons.access_time_rounded,
                              children: [
                                SwitchListTile(
                                  value: _hasMaleSection,
                                  onChanged: (v) =>
                                      setState(() => _hasMaleSection = v),
                                  title: const Text('قسم رجالي'),
                                  activeColor: _primaryColor,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (_hasMaleSection) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'مواعيد القسم الرجالي',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _copyToAllDays(true),
                                        icon: const Icon(Icons.content_copy, size: 18),
                                        label: const Text('نسخ السبت للكل'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF06B6D4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ..._daysOfWeek.map(
                                    (day) => _buildDayRow(
                                      dayKey: day,
                                      dayName: _dayNamesArabic[day]!,
                                      slotControllers: _maleTimeControllers[day]!,
                                      isClosed: _maleDayClosed[day] ?? true,
                                      onClosedChanged: (val) {
                                        setState(() {
                                          _maleDayClosed[day] = val;
                                        });
                                      },
                                      color: const Color(0xFF06B6D4),
                                      isMale: true,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  value: _hasFemaleSection,
                                  onChanged: (v) =>
                                      setState(() => _hasFemaleSection = v),
                                  title: const Text('قسم نسائي'),
                                  activeColor: const Color(0xFFEC4899),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (_hasFemaleSection) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'مواعيد القسم النسائي',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _copyToAllDays(false),
                                        icon: const Icon(Icons.content_copy, size: 18),
                                        label: const Text('نسخ السبت للكل'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFFEC4899),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ..._daysOfWeek.map(
                                    (day) => _buildDayRow(
                                      dayKey: day,
                                      dayName: _dayNamesArabic[day]!,
                                      slotControllers: _femaleTimeControllers[day]!,
                                      isClosed: _femaleDayClosed[day] ?? true,
                                      onClosedChanged: (val) {
                                        setState(() {
                                          _femaleDayClosed[day] = val;
                                        });
                                      },
                                      color: const Color(0xFFEC4899),
                                      isMale: false,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionCard(
                              title: 'الأسعار',
                              icon: Icons.payments,
                              children: [
                                TextFormField(
                                  controller: _monthlyController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    label: 'الاشتراك الشهري',
                                    icon: Icons.calendar_month,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _yearlyController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    label: 'الاشتراك السنوي',
                                    icon: Icons.date_range,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _singleSessionController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    label: 'سعر الجلسة الواحدة',
                                    icon: Icons.timer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionCard(
                              title: 'مميزات الجيم',
                              icon: Icons.workspace_premium,
                              children: _buildDynamicTextFields(
                                controllers: _featureControllers,
                                label: 'الميزة',
                                icon: Icons.star,
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
                            ),
                            const SizedBox(height: 30),
                            Container(
                              height: 58,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [_primaryColor, _secondaryColor],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.save_rounded,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'حفظ التعديلات',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),
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

  List<Widget> _buildDynamicPhoneFields() {
    List<Widget> widgets = [];

    for (int i = 0; i < _phoneControllers.length; i++) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: i < _phoneControllers.length - 1 ? 12 : 0),
          child: TextFormField(
            controller: _phoneControllers[i],
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              label: 'رقم الهاتف ${i + 1}',
              icon: Icons.phone_rounded,
            ).copyWith(
              suffixIcon: _phoneControllers.length > 1
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        if (mounted && _phoneControllers.length > 1) {
                          setState(() {
                            _phoneControllers[i].dispose();
                            _phoneControllers.removeAt(i);
                          });
                        }
                      },
                    )
                  : null,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
        ),
      );
    }

    // Add button
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: OutlinedButton.icon(
          onPressed: () {
            if (mounted) {
              setState(() {
                _phoneControllers.add(TextEditingController());
              });
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة رقم آخر'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryColor,
            side: const BorderSide(color: _primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
    );

    return widgets;
  }
}
