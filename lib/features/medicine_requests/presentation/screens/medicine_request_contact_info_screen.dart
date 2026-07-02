import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/medicine_reminders/services/medicine_notification_service.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class MedicineRequestContactInfoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> medicinesData;

  const MedicineRequestContactInfoScreen({
    super.key,
    required this.medicinesData,
  });

  @override
  State<MedicineRequestContactInfoScreen> createState() =>
      _MedicineRequestContactInfoScreenState();
}

class _MedicineRequestContactInfoScreenState
    extends State<MedicineRequestContactInfoScreen> {
  static const Color _brandColor = Color(0xFF0E7787);
  static const Color _brandColorDark = Color(0xFF0B6572);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        final user = authState.user;
        if (user.displayName.isNotEmpty) {
          _nameController.text = user.displayName;
        }
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          _phoneController.text = user.phoneNumber!;
        }
        if (user.whatsappNumber != null && user.whatsappNumber!.isNotEmpty) {
          _whatsappController.text = user.whatsappNumber!;
        }
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      final String fileName =
          'medicine_requests/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(
        fileName,
      );
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitRequest(BuildContext context, dynamic user) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload images and update medicines data
      final List<Map<String, dynamic>> finalMedicinesData = [];
      for (final medicine in widget.medicinesData) {
        final medicineCopy = Map<String, dynamic>.from(medicine);

        // Upload image if exists and is a File
        if (medicineCopy['imageFile'] != null) {
          final imageFile = medicineCopy['imageFile'] as File;
          final imageUrl = await _uploadImage(imageFile, user.uid);
          medicineCopy['imageUrl'] = imageUrl;
          medicineCopy.remove('imageFile'); // Remove file reference
        }

        finalMedicinesData.add(medicineCopy);
      }

      final requestData = {
        'userId': user.uid,
        'userName': user.displayName,
        'userEmail': user.email,
        'medicines': finalMedicinesData,
        'phoneNumber': _phoneController.text.trim(),
        'whatsappNumber': _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      final docRef = await FirebaseFirestore.instance
          .collection('medicine_requests')
          .add(requestData);

      // جدولة إشعار تذكير بعد 24 ساعة (مرة واحدة فقط)
     // MedicineNotificationService.scheduleMedicineRequestFollowUp(docRef.id);

      // Save contact info to user profile
      final name = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final whatsappNumber = _whatsappController.text.trim();

      if (name.isNotEmpty ||
          phoneNumber.isNotEmpty ||
          whatsappNumber.isNotEmpty) {
        try {
          final updateData = <String, dynamic>{};
          if (name.isNotEmpty) {
            updateData['displayName'] = name;
          }
          if (phoneNumber.isNotEmpty) {
            updateData['phoneNumber'] = phoneNumber;
          }
          if (whatsappNumber.isNotEmpty) {
            updateData['whatsappNumber'] = whatsappNumber;
          }

          if (updateData.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update(updateData);

            // Refresh user data in AuthCubit
            if (mounted) {
              context.read<AuthCubit>().refreshUser();
            }
          }
        } catch (e) {
          // Silently fail - not critical
        }
      }

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0E7787),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تم إرسال الطلب بنجاح!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ ستتواصل معك الصيدليات قريباً',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[900],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'مهم جداً:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'عندما تتواصل معك إحدى الصيدليات:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1. ',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'افتح صفحة الصيدليات',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2. ',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'اضغط على أيقونة السلة 🛒',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '3. ',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'اضغط "تم التواصل" على طلبك',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red[700],
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'هذا سيمنع الصيدليات الأخرى من التواصل معك',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[900],
                                    fontWeight: FontWeight.w600,
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
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to medicines screen
                  Navigator.of(
                    context,
                  ).pop(); // Go back to home/previous screen
                },
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إرسال الطلب: $e'),
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

  void _handleSubmit(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _submitRequest(context, authState.user);
    }
  }

  String _compactMedicineTitle(Map<String, dynamic> medicine) {
    final name = (medicine['medicineName'] ?? '').toString().trim();
    if (name.isNotEmpty) {
      return name;
    }
    return 'صورة الدواء';
  }

  File? _medicineImageFile(Map<String, dynamic> medicine) {
    final imageFile = medicine['imageFile'];
    if (imageFile is File) {
      return imageFile;
    }
    return null;
  }

  String? _medicineImageUrl(Map<String, dynamic> medicine) {
    final imageUrl = (medicine['imageUrl'] ?? '').toString().trim();
    if (imageUrl.isEmpty) {
      return null;
    }
    return imageUrl;
  }

  String _compactMedicineDetails(Map<String, dynamic> medicine) {
    final type = (medicine['medicineType'] ?? '').toString().trim();
    final quantity = (medicine['quantity'] ?? '').toString().trim();
    final unit = (medicine['quantityUnit'] ?? '').toString().trim();

    if (type == 'روشتة') {
      return type;
    }

    final qty = [quantity, unit].where((value) => value.isNotEmpty).join(' ');
    if (type.isEmpty) {
      return qty.isEmpty ? 'تفاصيل غير متاحة' : qty;
    }
    if (qty.isEmpty) {
      return type;
    }
    return '$type • $qty';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'معلومات التواصل',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _brandColor,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_brandColor, _brandColorDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.contact_phone_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'الخطوة 2 من 2',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'إرسال الطلب',
                              style: TextStyle(
                                color: Color(0xFF0369A1),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'أدخل معلومات التواصل ليتمكن الصيادلة من الرد على طلبك',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم *',
                    hintText: 'أدخل اسمك',
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFF0E7787),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0E7787),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف *',
                    hintText: 'أدخل رقم هاتفك',
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: Color(0xFF0E7787),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0E7787),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'رقم الهاتف مطلوب';
                    }
                    if (value.trim().length < 10) {
                      return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // WhatsApp Number Field
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الواتساب (اختياري)',
                    hintText: 'أدخل رقم الواتساب (إن وجد)',
                    prefixIcon: Icon(
                      FontAwesomeIcons.whatsapp,
                      color: Color(0xFF0E7787),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0E7787),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes Field
                TextFormField(
                  controller: _notesController,
                  minLines: 1,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    hintText: 'أي معلومات إضافية تساعد الصيادلة...',
                    prefixIcon: const Icon(
                      Icons.note_outlined,
                      color: Color(0xFF0E7787),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0E7787),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تفاصيل الطلب',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'عدد الأدوية: ${widget.medicinesData.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...widget.medicinesData.asMap().entries.map((entry) {
                        final medicine = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key + 1}) ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  color: const Color(0xFFF8FAFC),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: _medicineImageFile(medicine) != null
                                      ? Image.file(
                                          _medicineImageFile(medicine)!,
                                          fit: BoxFit.cover,
                                        )
                                      : (_medicineImageUrl(medicine) != null
                                            ? Image.network(
                                                _medicineImageUrl(medicine)!,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.medication_outlined,
                                                size: 16,
                                                color: Color(0xFF94A3B8),
                                              )),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _compactMedicineTitle(medicine),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _compactMedicineDetails(medicine),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleSubmit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: AppLoadingIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'إرسال الطلب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.send, size: 20),
                            ],
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
}
