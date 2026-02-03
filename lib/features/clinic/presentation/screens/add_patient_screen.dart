import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/patient_model.dart';
import '../cubit/patient_cubit.dart';
import '../cubit/patient_state.dart';

class AddPatientScreen extends StatefulWidget {
  final String clinicId;
  final PatientModel? patient;

  const AddPatientScreen({
    super.key,
    required this.clinicId,
    this.patient,
  });

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _isLoading = false;
  bool _sameAsPhone = true; // رقم الواتساب نفس رقم المكالمات

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _nameController.text = widget.patient!.name;
      _phoneController.text = widget.patient!.phoneNumber;
      if (widget.patient!.whatsappNumber != null && 
          widget.patient!.whatsappNumber != widget.patient!.phoneNumber) {
        _sameAsPhone = false;
        _whatsappController.text = widget.patient!.whatsappNumber!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patient != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.clinicGradient),
          child: SafeArea(
            child: BlocListener<PatientCubit, PatientState>(
              listener: (context, state) {
                if (state is PatientActionLoading) {
                  setState(() => _isLoading = true);
                } else {
                  setState(() => _isLoading = false);
                  if (state is PatientActionSuccess) {
                    Navigator.pop(context, true);
                  } else if (state is PatientError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Column(
                children: [
                  _buildAppBar(isEdit),
                  Expanded(child: _buildForm()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isEdit) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEdit ? 'تعديل بيانات المريض' : 'إضافة مريض جديد',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'اسم المريض',
              icon: Icons.person,
              hint: 'أدخل الاسم الكامل',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسم المريض';
                }
                if (value.length < 3) {
                  return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              label: 'رقم التليفون',
              icon: Icons.phone,
              hint: '01xxxxxxxxx',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رقم التليفون';
                }
                if (value.length != 11 || !value.startsWith('01')) {
                  return 'رقم التليفون غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildWhatsappSection(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsappSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'رقم الواتساب',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _sameAsPhone,
          onChanged: (value) {
            setState(() {
              _sameAsPhone = value ?? true;
              if (_sameAsPhone) {
                _whatsappController.clear();
              }
            });
          },
          title: const Text('رقم الواتساب نفس رقم المكالمات'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppTheme.primaryColor,
        ),
        if (!_sameAsPhone) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (!_sameAsPhone && (value == null || value.isEmpty)) {
                return 'يرجى إدخال رقم الواتساب';
              }
              if (!_sameAsPhone && value != null && value.isNotEmpty) {
                if (value.length != 11 || !value.startsWith('01')) {
                  return 'رقم الواتساب غير صحيح';
                }
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: '01xxxxxxxxx',
              prefixIcon: Icon(MdiIcons.whatsapp, color: Colors.green),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isEdit = widget.patient != null;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isEdit ? 'تحديث البيانات' : 'إضافة المريض',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final whatsappNumber = _sameAsPhone 
        ? phoneNumber 
        : _whatsappController.text.trim();

    if (widget.patient != null) {
      // Update existing patient
      final updatedPatient = widget.patient!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        whatsappNumber: whatsappNumber,
      );
      context.read<PatientCubit>().updatePatient(updatedPatient);
    } else {
      // Add new patient
      context.read<PatientCubit>().addPatient(
            clinicId: widget.clinicId,
            name: name,
            phoneNumber: phoneNumber,
            whatsappNumber: whatsappNumber,
          );
    }
  }
}
