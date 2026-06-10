import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/models/clinic_model.dart';
import '../../data/models/clinic_department.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class EditClinicScreen extends StatefulWidget {
  final ClinicModel clinic;

  const EditClinicScreen({super.key, required this.clinic});

  @override
  State<EditClinicScreen> createState() => _EditClinicScreenState();
}

class _EditClinicScreenState extends State<EditClinicScreen> {
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _doctorNameController;
  late List<TextEditingController> _servicesControllers; // خدمات العيادة كنقاط
  late TextEditingController _aboutController;
  late TextEditingController _consultationFeeController;
  late List<TextEditingController> _phoneControllers; // أرقام متعددة
  late TextEditingController _whatsappController;
  late TextEditingController _addressController;

  File? _doctorImage;
  bool _isLoading = false;
  late bool _hasNursery;
  late bool _onlineBookingEnabled;

  // Doctor & Secretary Emails
  late List<TextEditingController> _doctorEmailControllers;
  late List<TextEditingController> _secretaryEmailControllers;

  // Working Hours
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

    // Debug: Print initial values من الداتابيز
    print('🔍 EditClinicScreen - Initial Data:');
    print('   hasNursery: ${widget.clinic.hasNursery}');
    print('   onlineBookingEnabled: ${widget.clinic.onlineBookingEnabled}');
    print('   doctorEmails: ${widget.clinic.doctorEmails}');
    print('   secretaryEmails: ${widget.clinic.secretaryEmails}');

    _doctorNameController = TextEditingController(
      text: widget.clinic.doctorName,
    );
    _servicesControllers = widget.clinic.specialization.isNotEmpty
        ? widget.clinic.specialization
              .map((service) => TextEditingController(text: service))
              .toList()
        : [TextEditingController()]; // خدمة واحدة على الأقل
    _aboutController = TextEditingController(text: widget.clinic.about);
    _consultationFeeController = TextEditingController(
      text: widget.clinic.consultationFee.toString(),
    );
    _phoneControllers = widget.clinic.phones.isNotEmpty
        ? widget.clinic.phones
              .map((phone) => TextEditingController(text: phone))
              .toList()
        : [TextEditingController()]; // رقم واحد على الأقل
    _whatsappController = TextEditingController(
      text: widget.clinic.whatsapp ?? '',
    );
    _addressController = TextEditingController(text: widget.clinic.address);
    _hasNursery = widget.clinic.hasNursery;
    _onlineBookingEnabled = widget.clinic.onlineBookingEnabled;

    // Initialize doctor emails
    _doctorEmailControllers = widget.clinic.doctorEmails.isNotEmpty
        ? widget.clinic.doctorEmails
              .map((email) => TextEditingController(text: email))
              .toList()
        : [TextEditingController()];

    // Initialize secretary emails
    _secretaryEmailControllers = widget.clinic.secretaryEmails.isNotEmpty
        ? widget.clinic.secretaryEmails
              .map((email) => TextEditingController(text: email))
              .toList()
        : [];

    // Debug: Print initialized controllers
    print('   Initialized _hasNursery: $_hasNursery');
    print('   Initialized _onlineBookingEnabled: $_onlineBookingEnabled');
    print(
      '   Initialized doctor email controllers: ${_doctorEmailControllers.length}',
    );
    print(
      '   Initialized secretary email controllers: ${_secretaryEmailControllers.length}',
    );

    // Initialize working hours from existing clinic data
    for (var i = 0; i < _englishDays.length; i++) {
      final day = _englishDays[i];
      final hours = widget.clinic.workingHours[day];

      if (hours != null) {
        _isClosedDays[day] = hours.isClosed;
        // Only parse times if day is open and times are not "مغلق"
        if (!hours.isClosed && hours.from != 'مغلق' && hours.to != 'مغلق') {
          _workingHoursFrom[day] = _parseTimeOfDay(hours.from);
          _workingHoursTo[day] = _parseTimeOfDay(hours.to);
        }
      } else {
        _isClosedDays[day] = false;
      }
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      // Remove AM/PM and other non-numeric characters except colon
      final cleanTime = time.replaceAll(RegExp(r'[^\d:]'), '').trim();
      final parts = cleanTime.split(':');

      if (parts.isEmpty) return const TimeOfDay(hour: 9, minute: 0);

      int hour = int.parse(parts[0]);

      // Handle AM/PM conversion
      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(
        hour: hour,
        minute: parts.length > 1 ? int.parse(parts[1]) : 0,
      );
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    for (var controller in _servicesControllers) {
      controller.dispose();
    }
    _aboutController.dispose();
    _consultationFeeController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _whatsappController.dispose();
    _addressController.dispose();
    for (var controller in _doctorEmailControllers) {
      controller.dispose();
    }
    for (var controller in _secretaryEmailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
        _doctorImage = File(image.path);
      });
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

  /// 🔓 فصل المستخدمين المحذوفين من العيادة
  /// عند حذف إيميل من authEmails، يجب:
  /// 1. تغيير role من 'clinic' أو 'secretary' إلى 'user'
  /// 2. حذف clinicId من المستخدم
  /// 3. حذف clinic_subscription document
  Future<void> _unlinkRemovedUsersFromClinic(
    List<String> oldEmails,
    List<String> newEmails,
    String clinicId,
  ) async {
    try {
      // العثور على الإيميلات المحذوفة
      final removedEmails = oldEmails
          .where((email) => !newEmails.contains(email))
          .toList();

      if (removedEmails.isEmpty) {
        print('✅ لا يوجد مستخدمين محذوفين');
        return;
      }

      print('🔓 جاري فصل ${removedEmails.length} من العيادة...');

      for (final email in removedEmails) {
        try {
          // البحث عن المستخدم بالإيميل
          final userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

          if (userQuery.docs.isEmpty) {
            print('⚠️ لم يتم العثور على مستخدم بالإيميل: $email');
            continue;
          }

          final userId = userQuery.docs.first.id;
          print('📧 معالجة المستخدم: $email (ID: $userId)');

          // تحديث بيانات المستخدم - إرجاعه لمستخدم عادي
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
                'role': 'user', // إعادة الدور للمستخدم العادي
                'clinicId': FieldValue.delete(), // حذف رابط العيادة
              });
          print('✅ تم تحديث دور المستخدم إلى "user" وحذف clinicId');

          // حذف clinic_subscription document
          await FirebaseFirestore.instance
              .collection('clinic_subscriptions')
              .doc('${clinicId}_$userId')
              .delete();
          print('✅ تم حذف clinic_subscription');

          print('✅ تم فصل المستخدم بنجاح: $email');
        } catch (e) {
          print('❌ خطأ في فصل المستخدم $email: $e');
        }
      }

      print('✅ تم فصل جميع المستخدمين المحذوفين بنجاح');
    } catch (e) {
      print('❌ خطأ في عملية فصل المستخدمين: $e');
    }
  }

  Future<void> _updateClinic() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload new doctor image if selected
      String? doctorImageUrl = widget.clinic.doctorImageUrl;

      if (_doctorImage != null) {
        doctorImageUrl = await _uploadImage(
          _doctorImage!,
          'clinics/${widget.clinic.id}_doctor_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // Prepare working hours
      Map<String, WorkingHours> workingHours = {};
      for (var day in _englishDays) {
        final from = _workingHoursFrom[day];
        final to = _workingHoursTo[day];
        final isClosed = _isClosedDays[day] ?? false;

        // Always save WorkingHours, even if closed (with default times)
        if (isClosed) {
          // Day is closed - save with default times but marked as closed
          workingHours[day] = WorkingHours(
            from: 'مغلق',
            to: 'مغلق',
            isClosed: true,
          );
        } else if (from != null && to != null) {
          // Day is open with selected times
          workingHours[day] = WorkingHours(
            from: _formatTimeOfDay(from),
            to: _formatTimeOfDay(to),
            isClosed: false,
          );
        }
      }

      // Convert working hours to Map
      Map<String, dynamic> workingHoursMap = {};
      workingHours.forEach((day, hours) {
        workingHoursMap[day] = hours.toMap();
      });

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinic.id)
          .update({
            'doctorName': _doctorNameController.text.trim(),
            'specialization': _servicesControllers
                .map((c) => c.text.trim())
                .where((text) => text.isNotEmpty)
                .toList(),
            'about': _aboutController.text.trim(),
            'consultationFee': double.parse(
              _consultationFeeController.text.trim(),
            ),
            'phones': _phoneControllers
                .map((c) => c.text.trim())
                .where((phone) => phone.isNotEmpty)
                .toList(),
            'whatsapp': _whatsappController.text.trim().isEmpty
                ? null
                : _whatsappController.text.trim(),
            'address': _addressController.text.trim(),
            'workingHours': workingHoursMap,
            'hasNursery': _hasNursery,
            'onlineBookingEnabled': _onlineBookingEnabled,
            'doctorEmails': _doctorEmailControllers
                .map((c) => c.text.trim())
                .where((email) => email.isNotEmpty)
                .toList(),
            'secretaryEmails': _secretaryEmailControllers
                .map((c) => c.text.trim())
                .where((email) => email.isNotEmpty)
                .toList(),
            // دمج إيميلات الدكاترة والسكرتيرة في authEmails للمصادقة
            'authEmails': [
              ..._doctorEmailControllers
                  .map((c) => c.text.trim())
                  .where((email) => email.isNotEmpty),
              ..._secretaryEmailControllers
                  .map((c) => c.text.trim())
                  .where((email) => email.isNotEmpty),
            ],
            if (doctorImageUrl != null) 'doctorImageUrl': doctorImageUrl,
          });

      print('✅ تم التحديث بنجاح');

      // ✅ فصل المستخدمين المحذوفين من authEmails
      print('🔓 جاري فصل المستخدمين المحذوفين...');

      // الإيميلات القديمة (دكاترة + سكرتيرة)
      final oldEmails = [
        ...widget.clinic.doctorEmails,
        ...widget.clinic.secretaryEmails,
      ];

      // الإيميلات الجديدة (دكاترة + سكرتيرة)
      final newEmails = [
        ..._doctorEmailControllers
            .map((c) => c.text.trim())
            .where((email) => email.isNotEmpty),
        ..._secretaryEmailControllers
            .map((c) => c.text.trim())
            .where((email) => email.isNotEmpty),
      ];

      await _unlinkRemovedUsersFromClinic(
        oldEmails,
        newEmails,
        widget.clinic.id,
      );
      print('✅ تم فصل المستخدمين المحذوفين بنجاح');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات العيادة بنجاح'),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: const Text(
            'تعديل بيانات العيادة',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          iconTheme: const IconThemeData(color: _textPrimary),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: AppLoadingIndicator(
                    color: _primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(
                  Icons.check_rounded,
                  color: _textPrimary,
                  size: 22,
                ),
                onPressed: _updateClinic,
                tooltip: 'حفظ التعديلات',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    // Images Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFDDE7EF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'صور العيادة',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Doctor Image Only
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.teal.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'صورة الدكتور',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => _pickImage(),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.teal,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.teal.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: _doctorImage != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(17),
                                                child: Image.file(
                                                  _doctorImage!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : widget.clinic.doctorImageUrl !=
                                                  null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(17),
                                                child: Image.network(
                                                  widget.clinic.doctorImageUrl!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.add_photo_alternate,
                                                    size: 40,
                                                    color: Colors.teal.shade300,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'اضغط لإضافة\nصورة',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.teal.shade400,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.teal,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Doctor Name
                    TextFormField(
                      controller: _doctorNameController,
                      decoration: InputDecoration(
                        labelText: 'اسم الدكتور *',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.teal,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
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

                    // Clinic Services as Bullet Points
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.teal.withOpacity(0.3),
                          width: 2,
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
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.medical_services,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'خدمات العيادة *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _servicesControllers.add(
                                      TextEditingController(),
                                    );
                                  });
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('إضافة خدمة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أضف خدمات العيادة كنقاط منفصلة',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._servicesControllers.asMap().entries.map((entry) {
                            int index = entry.key;
                            TextEditingController controller = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.teal,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        hintText: 'اكتب خدمة...',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.teal,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                      validator: (value) {
                                        if (index == 0 &&
                                            (value == null ||
                                                value.trim().isEmpty)) {
                                          return 'يجب إضافة خدمة واحدة على الأقل';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (_servicesControllers.length > 1)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          controller.dispose();
                                          _servicesControllers.removeAt(index);
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // About
                    TextFormField(
                      controller: _aboutController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'نبذة عن الدكتور *',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.info, color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.teal,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'النبذة مطلوبة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Consultation Fee
                    TextFormField(
                      controller: _consultationFeeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر الكشف *',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.white,
                          ),
                        ),
                        suffix: const Text('جنيه'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.teal,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'سعر الكشف مطلوب';
                        }
                        if (double.tryParse(value) == null) {
                          return 'أدخل رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nursery availability (only for pediatrics)
                    if (widget.clinic.department ==
                        ClinicDepartment.pediatrics) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: const Text(
                            'يوجد حضانة بالعيادة',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('للعيادات المخصصة للأطفال'),
                          value: _hasNursery,
                          onChanged: (value) {
                            setState(() {
                              _hasNursery = value ?? false;
                            });
                          },
                          activeColor: Colors.pink,
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.pink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.child_care,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Online Booking
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: CheckboxListTile(
                        title: const Text(
                          'متاح الحجز أونلاين',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        //  subtitle: const Text('يسمح للمرضى بالحجز عبر التطبيق'),
                        value: _onlineBookingEnabled,
                        onChanged: (value) {
                          setState(() {
                            _onlineBookingEnabled = value ?? false;
                          });
                        },
                        activeColor: Colors.teal,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Doctor Emails Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
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
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'إيميلات الدكاترة (صلاحيات كاملة)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الصلاحيات: متابعة المرضى، إدارة الحجوزات، تعديل بيانات العيادة + المصادقة والنوتفيكيشنز',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_doctorEmailControllers.length, (
                            index,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller:
                                          _doctorEmailControllers[index],
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: index == 0
                                            ? 'إيميل الدكتور الأساسي *'
                                            : 'إيميل دكتور إضافي ${index + 1}',
                                        hintText: 'doctor@example.com',
                                        prefixIcon: const Icon(
                                          Icons.email,
                                          color: Colors.blue,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      validator: (value) {
                                        if (index == 0) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'يجب إدخال إيميل الدكتور الأساسي';
                                          }
                                        }
                                        if (value != null &&
                                            value.trim().isNotEmpty &&
                                            !value.contains('@')) {
                                          return 'إيميل غير صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (index > 0)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _doctorEmailControllers[index]
                                              .dispose();
                                          _doctorEmailControllers.removeAt(
                                            index,
                                          );
                                        });
                                      },
                                    ),
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('إضافة إيميل دكتور إضافي'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              setState(() {
                                _doctorEmailControllers.add(
                                  TextEditingController(),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Secretary Emails Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
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
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.people,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'إيميلات السكرتيرة (صلاحيات محدودة - اختياري)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الصلاحيات: إدارة الحجوزات فقط (بدون متابعة المرضى) + المصادقة والنوتفيكيشنز',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_secretaryEmailControllers.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'لم يتم إضافة سكرتيرة بعد',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ...List.generate(_secretaryEmailControllers.length, (
                            index,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller:
                                          _secretaryEmailControllers[index],
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: 'إيميل سكرتيرة ${index + 1}',
                                        hintText: 'secretary@example.com',
                                        prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: Colors.green,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.green,
                                            width: 2,
                                          ),
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      validator: (value) {
                                        if (value != null &&
                                            value.trim().isNotEmpty &&
                                            !value.contains('@')) {
                                          return 'إيميل غير صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _secretaryEmailControllers[index]
                                            .dispose();
                                        _secretaryEmailControllers.removeAt(
                                          index,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('إضافة إيميل سكرتيرة'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                            onPressed: () {
                              setState(() {
                                _secretaryEmailControllers.add(
                                  TextEditingController(),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Numbers Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'أرقام التليفون',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'يمكنك إضافة أكثر من رقم تليفون',
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                                          ? 'رقم التليفون الأساسي *'
                                          : 'رقم تليفون ${index + 1}',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.teal,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.phone,
                                          color: Colors.white,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.teal,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (index == 0 &&
                                          (value == null ||
                                              value.trim().isEmpty)) {
                                        return 'رقم التليفون الأساسي مطلوب';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (index > 0)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _phoneControllers[index].dispose();
                                        _phoneControllers.removeAt(index);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('إضافة رقم تليفون آخر'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.teal,
                          ),
                          onPressed: () {
                            setState(() {
                              _phoneControllers.add(TextEditingController());
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // WhatsApp
                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم واتساب (اختياري)',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.chat, color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.teal,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'العنوان *',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.teal,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'العنوان مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Working Hours Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.teal.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'مواعيد العمل',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(_englishDays.length, (index) {
                            final englishDay = _englishDays[index];
                            final arabicDay = _arabicDays[index];
                            final isClosed = _isClosedDays[englishDay] ?? false;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isClosed
                                      ? Colors.grey.shade300
                                      : Colors.teal.shade200,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isClosed
                                                    ? Colors.grey
                                                    : Colors.teal,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.calendar_today,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              arabicDay,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isClosed
                                                    ? Colors.grey
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isClosed
                                                ? Colors.red.shade50
                                                : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: isClosed
                                                  ? Colors.red.shade200
                                                  : Colors.green.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isClosed ? 'إجازة' : 'عمل',
                                                style: TextStyle(
                                                  color: isClosed
                                                      ? Colors.red.shade700
                                                      : Colors.green.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Switch(
                                                value: isClosed,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _isClosedDays[englishDay] =
                                                        value;
                                                  });
                                                },
                                                activeColor: Colors.red,
                                                inactiveThumbColor:
                                                    Colors.green,
                                                inactiveTrackColor:
                                                    Colors.green.shade100,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isClosed) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.teal.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.teal.shade200,
                                                ),
                                              ),
                                              child: OutlinedButton.icon(
                                                onPressed: () => _selectTime(
                                                  context,
                                                  true,
                                                  englishDay,
                                                ),
                                                icon: null,
                                                label: Text(
                                                  _workingHoursFrom[englishDay] !=
                                                          null
                                                      ? 'من: ${_formatTimeOfDay(_workingHoursFrom[englishDay]!)}'
                                                      : 'من: مغلق',
                                                  style: const TextStyle(
                                                    color: Colors.teal,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide.none,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.teal.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.teal.shade200,
                                                ),
                                              ),
                                              child: OutlinedButton.icon(
                                                onPressed: () => _selectTime(
                                                  context,
                                                  false,
                                                  englishDay,
                                                ),
                                                icon: null,
                                                label: Text(
                                                  _workingHoursTo[englishDay] !=
                                                          null
                                                      ? 'إلى: ${_formatTimeOfDay(_workingHoursTo[englishDay]!)}'
                                                      : 'إلى: مغلق',
                                                  style: const TextStyle(
                                                    color: Colors.teal,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide.none,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
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
                    const SizedBox(height: 24),

                    // Update Button
                    Container(
                      child: ElevatedButton(
                        onPressed: _updateClinic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, size: 19),
                            SizedBox(width: 10),
                            Text(
                              'حفظ التعديلات',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }
}
