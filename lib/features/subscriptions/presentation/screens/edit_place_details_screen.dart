import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../data/models/subscribed_place_model.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class EditPlaceDetailsScreen extends StatefulWidget {
  final SubscribedPlaceModel place;

  const EditPlaceDetailsScreen({super.key, required this.place});

  @override
  State<EditPlaceDetailsScreen> createState() => _EditPlaceDetailsScreenState();
}

class _EditPlaceDetailsScreenState extends State<EditPlaceDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _governorateController;
  late TextEditingController _cityController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place.placeName);
    _ownerNameController = TextEditingController(text: widget.place.ownerName);
    _phoneController = TextEditingController(text: widget.place.phone);
    _emailController = TextEditingController();
    _addressController = TextEditingController(
      text: widget.place.address ?? '',
    );
    _governorateController = TextEditingController(
      text: widget.place.governorate ?? '',
    );
    _cityController = TextEditingController(text: widget.place.city ?? '');

    // Load actual data from the original collection
    _loadPlaceData();
  }

  Future<void> _loadPlaceData() async {
    try {
      final collectionName = widget.place.placeType.collectionName;
      final doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(widget.place.placeId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;

        // Get email from the correct field
        final email = data[_getEmailField()] as String?;
        _emailController.text = email ?? '';

        // Update other fields if needed
        if (data['address'] != null) {
          _addressController.text = data['address'] ?? '';
        }
        if (data['governorate'] != null) {
          _governorateController.text = data['governorate'] ?? '';
        }
        if (data['city'] != null) {
          _cityController.text = data['city'] ?? '';
        }

        setState(() {});
      }
    } catch (e) {
      print('Error loading place data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _governorateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update in the appropriate collection
      final collectionName = widget.place.placeType.collectionName;
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(widget.place.placeId)
          .update({
            _getNameField(): _nameController.text.trim(),
            _getOwnerNameField(): _ownerNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            _getEmailField(): _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            'address': _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            'governorate': _governorateController.text.trim().isEmpty
                ? null
                : _governorateController.text.trim(),
            'city': _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث البيانات بنجاح'),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getNameField() {
    switch (widget.place.placeType) {
      case PlaceType.clinic:
        return 'doctorName';
      case PlaceType.pharmacy:
        return 'pharmacyName';
      case PlaceType.laboratory:
        return 'labName';
      case PlaceType.radiology:
        return 'centerName';
      case PlaceType.nursing:
        return 'nurseName';
      case PlaceType.delivery:
        return 'deliveryName';
      case PlaceType.rehabilitation:
        return 'centerName';
      case PlaceType.gym:
        return 'gymName';
    }
  }

  String _getOwnerNameField() {
    switch (widget.place.placeType) {
      case PlaceType.clinic:
        return 'doctorName';
      case PlaceType.pharmacy:
        return 'ownerName';
      case PlaceType.laboratory:
        return 'ownerName';
      case PlaceType.radiology:
        return 'ownerName';
      case PlaceType.nursing:
        return 'nurseName';
      case PlaceType.delivery:
        return 'ownerName';
      case PlaceType.rehabilitation:
        return 'ownerName';
      case PlaceType.gym:
        return 'ownerName';
    }
  }

  String _getEmailField() {
    switch (widget.place.placeType) {
      case PlaceType.clinic:
        return 'doctorEmails'; // تغيير إلى doctorEmails
      case PlaceType.pharmacy:
        return 'ownerEmail';
      case PlaceType.laboratory:
        return 'ownerEmail';
      case PlaceType.radiology:
        return 'ownerEmail';
      case PlaceType.nursing:
        return 'nurseEmail';
      case PlaceType.delivery:
        return 'ownerEmail';
      case PlaceType.rehabilitation:
        return 'ownerEmail';
      case PlaceType.gym:
        return 'ownerEmail';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: GradientAppBar(
          title: 'تعديل بيانات ${widget.place.placeType.arabicName}',
          gradient: const LinearGradient(
            colors: [Colors.teal, Color(0xFF00897B)],
          ),
        ),
        body: _isLoading
            ? Center(child: AppLoadingIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header card with type
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade50, Colors.teal.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.teal.shade200,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getTypeIcon(),
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.place.placeType.arabicName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'تعديل جميع البيانات والمعلومات',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Info Section
                    _buildSectionTitle(
                      'المعلومات الأساسية',
                      Icons.info_rounded,
                    ),
                    const SizedBox(height: 12),

                    // Place name
                    _buildTextField(
                      controller: _nameController,
                      label: 'اسم ${widget.place.placeType.arabicName}',
                      icon: Icons.business_rounded,
                      required: true,
                    ),

                    // Owner name
                    _buildTextField(
                      controller: _ownerNameController,
                      label: 'اسم صاحب المكان',
                      icon: Icons.person_rounded,
                      required: true,
                    ),

                    const SizedBox(height: 24),

                    // Contact Info Section
                    _buildSectionTitle(
                      'معلومات التواصل',
                      Icons.contact_phone_rounded,
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      required: true,
                    ),

                    // Email (Authentication Email)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'إيميل المصادقة (Authentication)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'هذا هو الإيميل المستخدم لتسجيل الدخول. التعديل عليه قد يؤثر على قدرة المستخدم على الدخول للنظام.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _emailController,
                            label: 'البريد الإلكتروني',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            required: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Location Info Section
                    _buildSectionTitle(
                      'معلومات الموقع',
                      Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 12),

                    // Governorate
                    _buildTextField(
                      controller: _governorateController,
                      label: 'المحافظة',
                      icon: Icons.map_rounded,
                      required: false,
                    ),

                    // City
                    _buildTextField(
                      controller: _cityController,
                      label: 'المدينة',
                      icon: Icons.location_city_rounded,
                      required: false,
                    ),

                    // Address
                    _buildTextField(
                      controller: _addressController,
                      label: 'العنوان التفصيلي',
                      icon: Icons.home_rounded,
                      maxLines: 3,
                      required: false,
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.teal, Color(0xFF00897B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.save_rounded, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'حفظ التعديلات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: '$label${required ? ' *' : ''}',
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label مطلوب';
                }
                return null;
              }
            : null,
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (widget.place.placeType) {
      case PlaceType.clinic:
        return Icons.local_hospital;
      case PlaceType.pharmacy:
        return Icons.medication;
      case PlaceType.laboratory:
        return Icons.science;
      case PlaceType.radiology:
        return Icons.medical_services;
      case PlaceType.nursing:
        return Icons.health_and_safety;
      case PlaceType.delivery:
        return Icons.local_shipping;
      case PlaceType.rehabilitation:
        return Icons.accessibility_new;
      case PlaceType.gym:
        return Icons.fitness_center;
    }
  }
}
