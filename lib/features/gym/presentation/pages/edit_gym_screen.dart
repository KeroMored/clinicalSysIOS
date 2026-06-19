import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/gym_model.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

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
  late TextEditingController _phoneController;
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

  // Features
  bool _hasPersonalTraining = false;
  bool _hasNutritionConsultation = false;
  bool _hasSwimmingPool = false;
  bool _hasSauna = false;
  bool _hasSteamRoom = false;
  bool _hasYogaClasses = false;
  bool _hasCrossFit = false;
  bool _hasMartialArts = false;

  // Training types
  bool _hasCardio = false;
  bool _hasWeightLifting = false;
  bool _hasBodybuilding = false;
  bool _hasFunctionalTraining = false;
  bool _hasGroupClasses = false;

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

  final Map<String, Map<String, TextEditingController>> _maleTimeControllers =
      {};
  final Map<String, Map<String, TextEditingController>> _femaleTimeControllers =
      {};
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
    _phoneController = TextEditingController(text: gym.phone);
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

    _hasPersonalTraining = gym.hasPersonalTraining;
    _hasNutritionConsultation = gym.hasNutritionConsultation;
    _hasSwimmingPool = gym.hasSwimmingPool;
    _hasSauna = gym.hasSauna;
    _hasSteamRoom = gym.hasSteamRoom;
    _hasYogaClasses = gym.hasYogaClasses;
    _hasCrossFit = gym.hasCrossFit;
    _hasMartialArts = gym.hasMartialArts;

    _hasCardio = gym.hasCardio;
    _hasWeightLifting = gym.hasWeightLifting;
    _hasBodybuilding = gym.hasBodybuilding;
    _hasFunctionalTraining = gym.hasFunctionalTraining;
    _hasGroupClasses = gym.hasGroupClasses;
  }

  void _initTimeControllers() {
    for (final day in _daysOfWeek) {
      final male = widget.gym.maleWorkingHours[day];
      final female = widget.gym.femaleWorkingHours[day];

      _maleTimeControllers[day] = {
        'start': TextEditingController(text: male?.openTime ?? '08:00'),
        'end': TextEditingController(text: male?.closeTime ?? '22:00'),
      };
      _femaleTimeControllers[day] = {
        'start': TextEditingController(text: female?.openTime ?? '08:00'),
        'end': TextEditingController(text: female?.closeTime ?? '14:00'),
      };

      _maleDayClosed[day] = male == null || male.isHoliday;
      _femaleDayClosed[day] = female == null || female.isHoliday;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _ownerNameController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    _singleSessionController.dispose();

    for (final c in _authEmailControllers) {
      c.dispose();
    }

    for (final dayMap in _maleTimeControllers.values) {
      dayMap['start']?.dispose();
      dayMap['end']?.dispose();
    }
    for (final dayMap in _femaleTimeControllers.values) {
      dayMap['start']?.dispose();
      dayMap['end']?.dispose();
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
    required Map<String, TextEditingController> controllers,
    required bool isClosed,
    required ValueChanged<bool> onClosedChanged,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(controllers['start']!),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'من',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(controllers['start']!.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(controllers['end']!),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'إلى',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(controllers['end']!.text),
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
  }

  Map<String, WorkingHours> _collectWorkingHours(
    bool enabled,
    Map<String, Map<String, TextEditingController>> controllers,
    Map<String, bool> closedMap,
  ) {
    if (!enabled) return {};

    final result = <String, WorkingHours>{};
    for (final day in _daysOfWeek) {
      final isClosed = closedMap[day] ?? true;
      if (!isClosed) {
        result[day] = WorkingHours(
          openTime: controllers[day]!['start']!.text,
          closeTime: controllers[day]!['end']!.text,
          isHoliday: false,
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

      final updateData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': _latitude ?? widget.gym.latitude,
        'longitude': _longitude ?? widget.gym.longitude,
        'phone': _phoneController.text.trim(),
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
        'hasPersonalTraining': _hasPersonalTraining,
        'hasNutritionConsultation': _hasNutritionConsultation,
        'hasSwimmingPool': _hasSwimmingPool,
        'hasSauna': _hasSauna,
        'hasSteamRoom': _hasSteamRoom,
        'hasYogaClasses': _hasYogaClasses,
        'hasCrossFit': _hasCrossFit,
        'hasMartialArts': _hasMartialArts,
        'hasCardio': _hasCardio,
        'hasWeightLifting': _hasWeightLifting,
        'hasBodybuilding': _hasBodybuilding,
        'hasFunctionalTraining': _hasFunctionalTraining,
        'hasGroupClasses': _hasGroupClasses,
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
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration(
                                    label: 'رقم الهاتف',
                                    icon: Icons.phone_rounded,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'مطلوب'
                                      : null,
                                ),
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
                                  ..._daysOfWeek.map(
                                    (day) => _buildDayRow(
                                      dayKey: day,
                                      dayName: _dayNamesArabic[day]!,
                                      controllers: _maleTimeControllers[day]!,
                                      isClosed: _maleDayClosed[day] ?? true,
                                      onClosedChanged: (val) {
                                        setState(() {
                                          _maleDayClosed[day] = val;
                                        });
                                      },
                                      color: const Color(0xFF06B6D4),
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
                                  ..._daysOfWeek.map(
                                    (day) => _buildDayRow(
                                      dayKey: day,
                                      dayName: _dayNamesArabic[day]!,
                                      controllers: _femaleTimeControllers[day]!,
                                      isClosed: _femaleDayClosed[day] ?? true,
                                      onClosedChanged: (val) {
                                        setState(() {
                                          _femaleDayClosed[day] = val;
                                        });
                                      },
                                      color: const Color(0xFFEC4899),
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
                              title: 'أنواع التدريب',
                              icon: Icons.sports_gymnastics,
                              children: [
                                _buildFeatureSwitch(
                                  title: 'كارديو',
                                  value: _hasCardio,
                                  onChanged: (v) =>
                                      setState(() => _hasCardio = v),
                                  icon: Icons.directions_run,
                                ),
                                _buildFeatureSwitch(
                                  title: 'رفع الأثقال',
                                  value: _hasWeightLifting,
                                  onChanged: (v) =>
                                      setState(() => _hasWeightLifting = v),
                                  icon: Icons.fitness_center,
                                ),
                                _buildFeatureSwitch(
                                  title: 'كمال أجسام',
                                  value: _hasBodybuilding,
                                  onChanged: (v) =>
                                      setState(() => _hasBodybuilding = v),
                                  icon: Icons.sports_gymnastics,
                                ),
                                _buildFeatureSwitch(
                                  title: 'تدريب وظيفي',
                                  value: _hasFunctionalTraining,
                                  onChanged: (v) => setState(
                                    () => _hasFunctionalTraining = v,
                                  ),
                                  icon: Icons.sports,
                                ),
                                _buildFeatureSwitch(
                                  title: 'حصص جماعية',
                                  value: _hasGroupClasses,
                                  onChanged: (v) =>
                                      setState(() => _hasGroupClasses = v),
                                  icon: Icons.groups,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionCard(
                              title: 'مميزات الجيم',
                              icon: Icons.workspace_premium,
                              children: [
                                _buildFeatureSwitch(
                                  title: 'تدريب شخصي',
                                  value: _hasPersonalTraining,
                                  onChanged: (v) =>
                                      setState(() => _hasPersonalTraining = v),
                                  icon: Icons.person,
                                ),
                                _buildFeatureSwitch(
                                  title: 'استشارات تغذية',
                                  value: _hasNutritionConsultation,
                                  onChanged: (v) => setState(
                                    () => _hasNutritionConsultation = v,
                                  ),
                                  icon: Icons.restaurant,
                                ),
                                _buildFeatureSwitch(
                                  title: 'حمام سباحة',
                                  value: _hasSwimmingPool,
                                  onChanged: (v) =>
                                      setState(() => _hasSwimmingPool = v),
                                  icon: Icons.pool,
                                ),
                                _buildFeatureSwitch(
                                  title: 'ساونا',
                                  value: _hasSauna,
                                  onChanged: (v) =>
                                      setState(() => _hasSauna = v),
                                  icon: Icons.hot_tub,
                                ),
                                _buildFeatureSwitch(
                                  title: 'غرفة بخار',
                                  value: _hasSteamRoom,
                                  onChanged: (v) =>
                                      setState(() => _hasSteamRoom = v),
                                  icon: Icons.cloud,
                                ),
                                _buildFeatureSwitch(
                                  title: 'حصص يوجا',
                                  value: _hasYogaClasses,
                                  onChanged: (v) =>
                                      setState(() => _hasYogaClasses = v),
                                  icon: Icons.self_improvement,
                                ),
                                _buildFeatureSwitch(
                                  title: 'كروس فيت',
                                  value: _hasCrossFit,
                                  onChanged: (v) =>
                                      setState(() => _hasCrossFit = v),
                                  icon: Icons.sports_mma,
                                ),
                                _buildFeatureSwitch(
                                  title: 'فنون قتالية',
                                  value: _hasMartialArts,
                                  onChanged: (v) =>
                                      setState(() => _hasMartialArts = v),
                                  icon: Icons.sports_kabaddi,
                                ),
                              ],
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
}
