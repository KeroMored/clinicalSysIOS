import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../cubit/medicine_offer_cubit.dart';
import '../../data/models/medicine_offer_model.dart';
import '../../../pharmacy/data/repositories/pharmacy_repository.dart';
import '../../../pharmacy/data/models/pharmacy_model.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class AddMedicineOfferScreen extends StatefulWidget {
  const AddMedicineOfferScreen({super.key});

  @override
  State<AddMedicineOfferScreen> createState() => _AddMedicineOfferScreenState();
}

class _AddMedicineOfferScreenState extends State<AddMedicineOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  PharmacyModel? _selectedPharmacy;
  List<PharmacyModel> _pharmacies = [];
  bool _isLoadingPharmacies = true;
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  // تحميل الصيدليات المتاحة
  Future<void> _loadPharmacies() async {
    try {
      final pharmacyRepo = PharmacyRepository();
      final pharmacies = await pharmacyRepo.getAllPharmacies();
      setState(() {
        _pharmacies = pharmacies;
        _isLoadingPharmacies = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPharmacies = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في تحميل الصيدليات: $e')));
      }
    }
  }

  // اختيار صورة
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في اختيار الصورة: $e')));
      }
    }
  }

  // رفع الصورة إلى Firebase Storage
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('medicine_offers')
          .child('$fileName.jpg');

      await ref.putFile(_selectedImage!);
      final url = await ref.getDownloadURL();

      setState(() {
        _isUploading = false;
      });

      return url;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في رفع الصورة: $e')));
      }
      return null;
    }
  }

  // حفظ العرض
  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPharmacy == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الصيدلية')));
      return;
    }

    // رفع الصورة إذا كانت موجودة
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) {
        // فشل رفع الصورة
        return;
      }
    }

    // إنشاء العرض
    final offer = MedicineOfferModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pharmacyId: _selectedPharmacy!.id,
      pharmacyName: _selectedPharmacy!.name,
      medicineName: _medicineNameController.text.trim(),
      quantity: int.parse(_quantityController.text),
      price: double.parse(_priceController.text),
      description: _descriptionController.text.trim(),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      isActive: true,
    );

    // حفظ العرض
    await context.read<MedicineOfferCubit>().addOffer(offer);
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إضافة عرض جديد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1A5F7A),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocListener<MedicineOfferCubit, MedicineOfferState>(
          listener: (context, state) {
            if (state is MedicineOfferAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is MedicineOfferError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: _isLoadingPharmacies
              ? const Center(
                  child: AppLoadingIndicator(color: Color(0xFF1A5F7A)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اختيار الصيدلية
                        const Text(
                          'الصيدلية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<PharmacyModel>(
                          value: _selectedPharmacy,
                          decoration: InputDecoration(
                            hintText: 'اختر الصيدلية',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          items: _pharmacies.map((pharmacy) {
                            return DropdownMenuItem(
                              value: pharmacy,
                              child: Text(pharmacy.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPharmacy = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'يرجى اختيار الصيدلية';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // اسم الدواء
                        const Text(
                          'اسم الدواء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _medicineNameController,
                          decoration: InputDecoration(
                            hintText: 'مثل: Cetal Syrup',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال اسم الدواء';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // الكمية والسعر
                        Row(
                          children: [
                            // الكمية
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الكمية المتاحة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '3',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'مطلوب';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'رقم غير صحيح';
                                      }
                                      if (int.parse(value) <= 0) {
                                        return 'يجب أن يكون أكبر من 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // السعر
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'السعر (جنيه)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _priceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      hintText: '13',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'مطلوب';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'رقم غير صحيح';
                                      }
                                      if (double.parse(value) <= 0) {
                                        return 'يجب أن يكون أكبر من 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // الوصف
                        const Text(
                          'الوصف (اختياري)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'أي تفاصيل إضافية عن العرض...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // الصورة
                        const Text(
                          'صورة الدواء (اختياري)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 60,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'اضغط لإضافة صورة',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // زر الحفظ
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _saveOffer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF57CC99),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: AppLoadingIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'نشر العرض',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
