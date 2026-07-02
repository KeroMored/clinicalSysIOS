import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/models/pharmacy_model.dart';

class EditPharmacyScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const EditPharmacyScreen({super.key, required this.pharmacy});

  @override
  State<EditPharmacyScreen> createState() => _EditPharmacyScreenState();
}

class _EditPharmacyScreenState extends State<EditPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late List<TextEditingController> _phoneControllers;
  late TextEditingController _workingHoursController;
  late TextEditingController _descriptionController;
  late TextEditingController _whatsappController;

  // Theme colors
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0B8293), Color(0xFF179AAC)],
  );

  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;

  // Auth Emails
  late List<TextEditingController> _authEmailControllers;

  // Insurance
  bool _hasInsurance = false;
  List<TextEditingController> _insuranceCompanyControllers = [];

  // Home Delivery
  bool _hasHomeDelivery = false;
  double? _deliveryFee;
  double? _minimumOrderForDelivery;

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
    _nameController = TextEditingController(text: widget.pharmacy.name);
    _addressController = TextEditingController(text: widget.pharmacy.address);
    _phoneControllers = widget.pharmacy.phones.isNotEmpty
        ? widget.pharmacy.phones
              .map((phone) => TextEditingController(text: phone))
              .toList()
        : [TextEditingController()];
    _workingHoursController = TextEditingController(
      text: widget.pharmacy.workingHours,
    );
    _descriptionController = TextEditingController(
      text: widget.pharmacy.description ?? '',
    );
    _whatsappController = TextEditingController(text: widget.pharmacy.whatsapp);
    _existingImageUrls = List.from(widget.pharmacy.images);

    // Initialize auth emails
    _authEmailControllers = widget.pharmacy.authEmails.isNotEmpty
        ? widget.pharmacy.authEmails
              .map((email) => TextEditingController(text: email))
              .toList()
        : [TextEditingController()];

    // Initialize insurance
    _hasInsurance = widget.pharmacy.hasInsurance;
    _insuranceCompanyControllers = widget.pharmacy.insuranceCompanies.isNotEmpty
        ? widget.pharmacy.insuranceCompanies
              .map((company) => TextEditingController(text: company))
              .toList()
        : [];

    // Initialize home delivery
    _hasHomeDelivery = widget.pharmacy.hasHomeDelivery;
    _deliveryFee = widget.pharmacy.deliveryFee;
    _minimumOrderForDelivery = widget.pharmacy.minimumOrderForDelivery;

    // Parse existing working hours
    _parseWorkingHours(widget.pharmacy.workingHours);

    // Parse existing holidays (comma-separated string)
    if (widget.pharmacy.holidays.isNotEmpty) {
      final holidaysList = widget.pharmacy.holidays
          .split(',')
          .map((e) => e.trim())
          .toList();
      for (var holiday in holidaysList) {
        if (_selectedHolidays.containsKey(holiday)) {
          _selectedHolidays[holiday] = true;
        }
      }
    }
  }

  void _parseWorkingHours(String workingHours) {
    if (workingHours.isEmpty) return;

    // Expected format: "09:00-22:00"
    final parts = workingHours.split('-');
    if (parts.length == 2) {
      try {
        final openParts = parts[0].split(':');
        final closeParts = parts[1].split(':');

        if (openParts.length == 2 && closeParts.length == 2) {
          _openTime = TimeOfDay(
            hour: int.parse(openParts[0]),
            minute: int.parse(openParts[1]),
          );
          _closeTime = TimeOfDay(
            hour: int.parse(closeParts[0]),
            minute: int.parse(closeParts[1]),
          );
        }
      } catch (e) {
        // Invalid format, ignore
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _workingHoursController.dispose();
    _descriptionController.dispose();
    _whatsappController.dispose();
    for (var controller in _authEmailControllers) {
      controller.dispose();
    }
    for (var controller in _insuranceCompanyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<void> _selectOpenTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _openTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
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

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<String> _uploadImage(File image) async {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child('pharmacies')
        .child(widget.pharmacy.id)
        .child('$fileName.jpg');

    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // ✅ فصل المستخدمين المحذوفين من الصيدلية وإرجاعهم لمستخدمين عاديين
  Future<void> _unlinkRemovedUsersFromPharmacy(
    List<String> oldEmails,
    List<String> newEmails,
    String pharmacyId,
  ) async {
    try {
      // المستخدمين اللي اتشالو = موجودين في القديم، مش موجودين في الجديد
      final removedEmails = oldEmails
          .where((email) => email.isNotEmpty && !newEmails.contains(email))
          .toList();

      if (removedEmails.isEmpty) {
        print('ℹ️ لا يوجد مستخدمين محذوفين');
        return;
      }

      print('🔓 جاري فصل ${removedEmails.length} مستخدم من الصيدلية...');

      for (final email in removedEmails) {
        // البحث عن المستخدمين بهذा الإيميل
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .where(
              'pharmacyId',
              isEqualTo: pharmacyId,
            ) // التأكد أنه تابع لهذه الصيدلية
            .get();

        if (usersSnapshot.docs.isEmpty) {
          print('⚠️ لم يتم العثور على مستخدم بالإيميل: $email');
          continue;
        }

        // فصل جميع المستخدمين المطابقين
        for (final userDoc in usersSnapshot.docs) {
          // حذف pharmacyId وإرجاع role إلى user
          await userDoc.reference.update({
            'role': 'user',
            'pharmacyId': FieldValue.delete(), // حذف الحقل تماماً
          });

          print('✅ تم فصل المستخدم ${userDoc.id} من الصيدلية');

          // حذف pharmacy_subscription
          await FirebaseFirestore.instance
              .collection('pharmacy_subscriptions')
              .doc(userDoc.id)
              .delete();

          print('✅ تم حذف pharmacy_subscription للمستخدم ${userDoc.id}');

          // إلغاء الاشتراك في pharmacy_requests topic (FCM)
          // ملاحظة: هذا يحتاج FCM token من المستخدم، سيتم التعامل معه عند تسجيل الدخول القادم
        }
      }

      print('✅ تم فصل جميع المستخدمين المحذوفين بنجاح');
    } catch (e) {
      print('❌ خطأ في فصل المستخدمين: $e');
      rethrow;
    }
  }

  // ✅ NEW: ربط المستخدمين الموجودين بالصيدلية
  Future<void> _linkUsersToPharmacy(
    List<String> emails,
    String pharmacyId,
  ) async {
    try {
      for (final email in emails) {
        if (email.isEmpty) continue;

        // البحث عن المستخدمين بهذا الإيميل
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (usersSnapshot.docs.isEmpty) {
          print('⚠️ No users found with email: $email');
          continue;
        }

        // تحديث جميع المستخدمين المطابقين
        for (final userDoc in usersSnapshot.docs) {
          await userDoc.reference.update({
            'role': 'pharmacy',
            'pharmacyId': pharmacyId,
          });

          print(
            '✅ Updated user ${userDoc.id} with pharmacy role and ID: $pharmacyId',
          );

          // إنشاء pharmacy_subscription للمستخدم
          await FirebaseFirestore.instance
              .collection('pharmacy_subscriptions')
              .doc(userDoc.id)
              .set({
                'subscribedAt': FieldValue.serverTimestamp(),
                'topic': 'pharmacy_requests',
                'isActive': true,
                'pharmacyId': pharmacyId,
              }, SetOptions(merge: true));

          print('✅ Created pharmacy_subscription for user ${userDoc.id}');
        }
      }
    } catch (e) {
      print('❌ Error linking users to pharmacy: $e');
      // لا نرمي exception هنا لأننا لا نريد فشل عملية التحديث
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate pharmacy ID
    if (widget.pharmacy.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('خطأ: معرف الصيدلية غير موجود'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📝 بدء التحديث - ID: ${widget.pharmacy.id}');

      // Upload new images
      List<String> newImageUrls = [];
      for (var image in _selectedImages) {
        String url = await _uploadImage(image);
        newImageUrls.add(url);
      }

      // Combine existing and new images
      final allImages = [..._existingImageUrls, ...newImageUrls];

      // Get selected holidays as comma-separated string
      final selectedHolidaysList = _selectedHolidays.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      final holidaysString = selectedHolidaysList.isEmpty
          ? PharmacyModel.noHolidaysText
          : selectedHolidaysList.join(', ');

      // Get insurance companies list
      final insuranceCompanies = _hasInsurance
          ? _insuranceCompanyControllers
                .map((controller) => controller.text.trim())
                .where((name) => name.isNotEmpty)
                .toList()
          : <String>[];

      // Update pharmacy data
      final authEmails = _authEmailControllers
          .map((c) => c.text.trim())
          .where((email) => email.isNotEmpty)
          .toList();

      final updatedData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phones': _phoneControllers
            .map((c) => c.text.trim())
            .where((phone) => phone.isNotEmpty)
            .toList(),
        'whatsapp': _whatsappController.text.trim(),
        'workingHours': _workingHoursController.text.trim(),
        'images': allImages,
        'holidays': holidaysString,
        'authEmails': authEmails,
        'hasInsurance': _hasInsurance,
        'insuranceCompanies': insuranceCompanies,
        'hasHomeDelivery': _hasHomeDelivery,
        'deliveryFee': _hasHomeDelivery ? (_deliveryFee ?? 0.0) : null,
        'minimumOrderForDelivery': _hasHomeDelivery
            ? (_minimumOrderForDelivery ?? 0.0)
            : null,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      };

      print('📤 جاري التحديث في Firestore...');

      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(widget.pharmacy.id)
          .update(updatedData);

      print('✅ تم التحديث بنجاح');

      // ✅ STEP 1: فصل المستخدمين المحذوفين أولاً
      print('🔓 جاري فصل المستخدمين المحذوفين...');
      await _unlinkRemovedUsersFromPharmacy(
        widget.pharmacy.authEmails, // الإيميلات القديمة
        authEmails, // الإيميلات الجديدة
        widget.pharmacy.id,
      );
      print('✅ تم فصل المستخدمين المحذوفين بنجاح');

      // ✅ STEP 2: ربط المستخدمين الجدد/الموجودين
      print('🔗 جاري ربط المستخدمين بالصيدلية...');
      await _linkUsersToPharmacy(authEmails, widget.pharmacy.id);
      print('✅ تم ربط المستخدمين بنجاح');

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('تم تحديث البيانات بنجاح'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في التحديث: $e');
      print('📋 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('خطأ في التحديث: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'تفاصيل',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Text('تفاصيل الخطأ'),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Text(
                        'الخطأ: $e\n\n'
                        'معرف الصيدلية: ${widget.pharmacy.id}\n'
                        'اسم الصيدلية: ${widget.pharmacy.name}',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('حسناً'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Premium Input Decoration
  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    Color iconColor = _primaryColor,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      labelStyle: const TextStyle(
        color: _textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: _textSecondary.withOpacity(0.6),
        fontSize: 12.5,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE6EF), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE6EF), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryColor, width: 1.6),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        color: _primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'جاري حفظ التعديلات...',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: false,
                    pinned: true,
                    toolbarHeight: 62,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _textPrimary,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    centerTitle: true,
                    title: const Text(
                      'تعديل بيانات الصيدلية',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    actions: [
                      TextButton.icon(
                        onPressed: _isLoading ? null : _saveChanges,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'حفظ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryColor,
                        ),
                      ),
                    ],
                    bottom: const PreferredSize(
                      preferredSize: Size.fromHeight(1),
                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),
                  ),

                  // Form Content
                  SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 16),
                            // Basic Info Section
                            _buildSectionCard(
                              title: 'المعلومات الأساسية',
                              icon: Icons.info_outline_rounded,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _buildInputDecoration(
                                    label: 'اسم الصيدلية',
                                    icon: Icons.local_pharmacy_rounded,
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'يرجى إدخال اسم الصيدلية';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: _buildInputDecoration(
                                    label: 'العنوان',
                                    icon: Icons.location_on_rounded,
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'يرجى إدخال العنوان';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // عن الصيدلية (اختياري)
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: _buildInputDecoration(
                                    label: 'عن الصيدلية (اختياري)',
                                    icon: Icons.description,
                                    hint:
                                        'مثال:\n'
                                        'قياس السكر مجانى\n'
                                        'قياس الضغط مجانى\n'
                                        'متاح لدينا عمل انبودى\n'
                                        'متاح قياس الوزن بسعر رمزى',
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 20),

                                // أرقام الهاتف (Multiple)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _backgroundColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _secondaryColor.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'أرقام الهاتف',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: _textPrimary,
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
                                              style: TextButton.styleFrom(
                                                foregroundColor: _primaryColor,
                                              ),
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
                                                  keyboardType:
                                                      TextInputType.phone,
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  textAlign: TextAlign.left,
                                                  decoration: _buildInputDecoration(
                                                    label: index == 0
                                                        ? 'رقم الهاتف الأساسي *'
                                                        : 'رقم ${index + 1}',
                                                    icon: Icons.phone_rounded,
                                                  ),
                                                  style: const TextStyle(
                                                    color: _textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  validator: index == 0
                                                      ? (value) {
                                                          if (value == null ||
                                                              value.isEmpty) {
                                                            return 'يرجى إدخال رقم الهاتف الأساسي';
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
                                                      _phoneControllers
                                                          .removeAt(index);
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
                                const SizedBox(height: 20),

                                // رقم الواتساب
                                TextFormField(
                                  controller: _whatsappController,
                                  keyboardType: TextInputType.phone,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.left,
                                  decoration: _buildInputDecoration(
                                    label: 'رقم الواتساب',
                                    icon: FontAwesomeIcons.whatsapp,
                                    iconColor: const Color(0xFF25D366),
                                  ),
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'يرجى إدخال رقم الواتساب';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Working Hours Section
                            _buildSectionCard(
                              title: 'ساعات العمل',
                              icon: Icons.access_time_rounded,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeButton(
                                        label: 'وقت الافتتاح',
                                        time: _openTime,
                                        onPressed: _selectOpenTime,
                                        icon: Icons.login_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTimeButton(
                                        label: 'وقت الإغلاق',
                                        time: _closeTime,
                                        onPressed: _selectCloseTime,
                                        icon: Icons.logout_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Auth Emails Section
                            _buildSectionCard(
                              title: 'إيميلات المصادقة',
                              icon: Icons.email_rounded,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _primaryColor.withOpacity(0.24),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: _primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'الإيميلات المسموح لها بالدخول إلى لوحة التحكم',
                                          style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                                            decoration: InputDecoration(
                                              labelText: 'إيميل ${index + 1}',
                                              prefixIcon: const Icon(
                                                Icons.email,
                                                color: _primaryColor,
                                              ),
                                              suffixIcon:
                                                  _authEmailControllers.length >
                                                      1
                                                  ? IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          controller.dispose();
                                                          _authEmailControllers
                                                              .removeAt(index);
                                                        });
                                                      },
                                                    )
                                                  : null,
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                  width: 2,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                  width: 2,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: _primaryColor,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'الإيميل مطلوب';
                                              }
                                              if (!value.contains('@')) {
                                                return 'صيغة الإيميل غير صحيحة';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 12),
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
                                      backgroundColor: _primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Holidays Section
                            _buildSectionCard(
                              title: 'أيام العطلة',
                              icon: Icons.event_busy_rounded,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFCD34D),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFFD97706),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'اختر أيام العطلة الأسبوعية للصيدلية',
                                          style: TextStyle(
                                            color: Colors.amber.shade900,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _selectedHolidays.keys.map((day) {
                                    final isSelected = _selectedHolidays[day]!;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedHolidays[day] = !isSelected;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color(0xFFEF4444),
                                                    Color(0xFFF87171),
                                                  ],
                                                )
                                              : null,
                                          color: isSelected
                                              ? null
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.transparent
                                                : const Color(0xFFE2E8F0),
                                            width: 2,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFFEF4444,
                                                    ).withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.03),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isSelected) ...[
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            Text(
                                              day,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : _textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Home Delivery Section
                            _buildSectionCard(
                              title: 'خدمة التوصيل للمنزل',
                              icon: Icons.delivery_dining,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.09),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _primaryColor.withOpacity(0.28),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: _primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'هل خدمة التوصيل للمنازل متاحة؟',
                                          style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  value: _hasHomeDelivery,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasHomeDelivery = value;
                                    });
                                  },
                                  title: Text(
                                    _hasHomeDelivery
                                        ? 'خدمة التوصيل متاحة'
                                        : 'خدمة التوصيل غير متاحة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _hasHomeDelivery
                                          ? _primaryColor
                                          : _textSecondary,
                                    ),
                                  ),
                                  activeColor: _primaryColor,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (_hasHomeDelivery) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue:
                                        _deliveryFee?.toString() ?? '',
                                    decoration: InputDecoration(
                                      labelText: 'رسوم التوصيل (اختياري)',
                                      hintText: 'مثال: 10',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.money,
                                          color: _primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      suffixText: 'جنيه',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: _primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: _cardColor,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _deliveryFee = double.tryParse(value);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue:
                                        _minimumOrderForDelivery?.toString() ??
                                        '',
                                    decoration: InputDecoration(
                                      labelText: 'الحد الأدنى للطلب (اختياري)',
                                      hintText: 'مثال: 50',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_cart,
                                          color: _primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      suffixText: 'جنيه',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: _primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: _cardColor,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _minimumOrderForDelivery =
                                          double.tryParse(value);
                                    },
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Insurance Section
                            _buildSectionCard(
                              title: 'شركات التأمين',
                              icon: Icons.health_and_safety,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _primaryColor.withOpacity(0.24),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: _primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'هل الصيدلية متعاقدة مع شركات تأمين؟',
                                          style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  value: _hasInsurance,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasInsurance = value;
                                      if (!value) {
                                        // Clear insurance companies when disabled
                                        for (var controller
                                            in _insuranceCompanyControllers) {
                                          controller.dispose();
                                        }
                                        _insuranceCompanyControllers.clear();
                                      }
                                    });
                                  },
                                  title: const Text(
                                    'متعاقد مع شركات تأمين',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  activeColor: _primaryColor,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (_hasInsurance) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'أسماء الشركات',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _insuranceCompanyControllers.add(
                                              TextEditingController(),
                                            );
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.add_circle,
                                          size: 20,
                                        ),
                                        label: const Text('إضافة شركة'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: _primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_insuranceCompanyControllers.isNotEmpty)
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
                                                    if (_hasInsurance &&
                                                        (value == null ||
                                                            value
                                                                .trim()
                                                                .isEmpty)) {
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
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Images Section
                            _buildSectionCard(
                              title: 'صور الصيدلية',
                              icon: Icons.photo_library_rounded,
                              children: [
                                if (_existingImageUrls.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'الصور الحالية (${_existingImageUrls.length})',
                                          style: const TextStyle(
                                            color: _primaryColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 110,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _existingImageUrls.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        return _buildImageCard(
                                          imageUrl: _existingImageUrls[index],
                                          onRemove: () =>
                                              _removeExistingImage(index),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                if (_selectedImages.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'صور جديدة (${_selectedImages.length})',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 110,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedImages.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        return _buildImageCard(
                                          file: _selectedImages[index],
                                          onRemove: () =>
                                              _removeNewImage(index),
                                          isNew: true,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                // Add Images Button
                                InkWell(
                                  onTap: _pickImages,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _primaryColor.withOpacity(0.3),
                                        width: 2,
                                        style: BorderStyle.solid,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      color: _primaryColor.withOpacity(0.05),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _primaryColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add_photo_alternate_rounded,
                                            color: _primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'إضافة صور',
                                              style: TextStyle(
                                                color: _primaryColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'اضغط لاختيار صور من المعرض',
                                              style: TextStyle(
                                                color: _textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Save Button
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: _primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.28),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _saveChanges,
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
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'حفظ التعديلات',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),
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

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pharmacy.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'حدّث البيانات الأساسية وبيانات التواصل',
                  style: TextStyle(
                    color: Color(0xFFE8F7FB),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section Card Builder
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7EF), width: 1),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // Time Button Builder
  Widget _buildTimeButton({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: time != null
                  ? _primaryColor.withOpacity(0.1)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: time != null
                    ? _primaryColor.withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: time != null ? _primaryColor : _textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  time != null ? _formatTimeOfDay(time) : 'اختر الوقت',
                  style: TextStyle(
                    color: time != null ? _primaryColor : _textSecondary,
                    fontSize: 13,
                    fontWeight: time != null
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Image Card Builder
  Widget _buildImageCard({
    String? imageUrl,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: _primaryColor,
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  )
                : Image.file(file!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -4,
          left: -4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        if (isNew)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'جديد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
