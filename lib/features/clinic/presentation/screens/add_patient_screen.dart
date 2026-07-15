import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/patient_model.dart';
import '../cubit/patient_cubit.dart';
import '../cubit/patient_state.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class AddPatientScreen extends StatefulWidget {
  final String clinicId;
  final PatientModel? patient;

  const AddPatientScreen({super.key, required this.clinicId, this.patient});

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
        backgroundColor: const Color(0xFFF1F7FB),
        appBar: _buildAppBar(isEdit),
        body: BlocListener<PatientCubit, PatientState>(
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
          child: _buildForm(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isEdit) {
    return AppBar(
      toolbarHeight: 68,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      centerTitle: true,
      title: Text(
        isEdit ? 'تعديل بيانات المريض' : 'إضافة مريض جديد',
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF334155),
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _submitForm,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B8293),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'حفظ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0F2F8), Color(0xFFEAF7FB)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCFE7F3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.health_and_safety_rounded,
                  color: Color(0xFF0B8293),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أدخل بيانات المريض بدقة لتسهيل البحث والتواصل من شاشة الحجوزات.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1E3A5F).withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            title: 'البيانات الأساسية',
            icon: Icons.person_rounded,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'اسم المريض',
                  icon: Icons.badge_rounded,
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
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم التليفون',
                  icon: Icons.phone_rounded,
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
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            title: 'بيانات واتساب',
            icon: Icons.chat,
            child: _buildWhatsappSection(),
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF0B8293)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildWhatsappSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE7EF)),
          ),
          child: CheckboxListTile(
            value: _sameAsPhone,
            onChanged: (value) {
              setState(() {
                _sameAsPhone = value ?? true;
                if (_sameAsPhone) {
                  _whatsappController.clear();
                }
              });
            },
            title: const Text(
              'رقم الواتساب نفس رقم المكالمات',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.primaryColor,
          ),
        ),
        if (!_sameAsPhone) ...[
          const SizedBox(height: 10),
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
            decoration: _inputDecoration(
              label: 'رقم الواتساب',
              hint: '01xxxxxxxxx',
              icon: Icons.chat,
              iconColor: const Color(0xFF16A34A),
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Color iconColor = AppTheme.primaryColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: iconColor),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE7EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE7EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEdit = widget.patient != null;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const AppLoadingIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'تحديث البيانات' : 'إضافة المريض',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
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
