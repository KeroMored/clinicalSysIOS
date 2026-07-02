import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/models/medical_visit_model.dart';
import '../cubit/patient_cubit.dart';
import '../cubit/patient_state.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class AddVisitScreen extends StatefulWidget {
  final String patientId;
  final String clinicId;
  final MedicalVisitModel? visit;

  const AddVisitScreen({
    super.key,
    required this.patientId,
    required this.clinicId,
    this.visit,
  });

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);

  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _medicationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<File> _prescriptionImages = []; // قائمة صور
  List<String> _existingImageUrls = []; // صور موجودة من قبل
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.visit != null) {
      _diagnosisController.text = widget.visit!.diagnosis ?? '';
      _selectedDate = widget.visit!.visitDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.visit!.visitDate);
      // تحويل قائمة الأدوية إلى نص متعدد الأسطر
      _medicationController.text = widget.visit!.medications.join('\n');
      _existingImageUrls = List.from(widget.visit!.prescriptionImageUrls);
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.visit != null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
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
    );
  }

  Widget _buildAppBar(bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textPrimary,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEdit ? 'تعديل الكشف' : 'إضافة كشف جديد',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
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
              onPressed: _submitForm,
              tooltip: isEdit ? 'تحديث الكشف' : 'حفظ الكشف',
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
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            //  _buildDateTimeSection(),
            //    const SizedBox(height: 24),
            _buildDiagnosisField(),
            const SizedBox(height: 24),
            _buildMedicationsSection(),
            const SizedBox(height: 24),
            _buildPrescriptionImageSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تاريخ ووقت الكشف',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: _primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('yyyy/MM/dd', 'ar').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: _primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiagnosisField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'التشخيص (اختياري)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _diagnosisController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: ' التشخيص...',
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: _primaryColor, width: 1.8),
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

  Widget _buildMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأدوية المكتوبة (اختياري)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _medicationController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'الأدوية...',
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: _primaryColor, width: 1.8),
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

  Widget _buildPrescriptionImageSection() {
    final totalImages = _prescriptionImages.length + _existingImageUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'صور الروشتة (اختياري)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            if (totalImages > 0)
              Text(
                '$totalImages صورة',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // عرض الصور الموجودة
        if (totalImages > 0) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length + _prescriptionImages.length,
              itemBuilder: (context, index) {
                final isExisting = index < _existingImageUrls.length;
                return _buildImageThumbnail(
                  index,
                  isExisting,
                  isExisting ? _existingImageUrls[index] : null,
                  isExisting
                      ? null
                      : _prescriptionImages[index - _existingImageUrls.length],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('التقاط صورة'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  side: const BorderSide(color: _primaryColor),
                  foregroundColor: _primaryColor,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('من المعرض'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  side: const BorderSide(color: _primaryColor),
                  foregroundColor: _primaryColor,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isEdit = widget.visit != null;

    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: AppLoadingIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(
              isEdit ? 'تحديث الكشف' : 'حفظ الكشف',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1280, // تقليل الحجم للسرعة
      maxHeight: 1280,
      imageQuality: 70, // تقليل الجودة قليلاً للسرعة
    );

    if (pickedFile != null) {
      setState(() {
        _prescriptionImages.add(File(pickedFile.path));
      });
    }
  }

  Widget _buildImageThumbnail(
    int index,
    bool isExisting,
    String? url,
    File? file,
  ) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isExisting
                ? Image.network(
                    url!,
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Image.file(file!, width: 100, height: 120, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              onPressed: () => setState(() {
                if (isExisting) {
                  _existingImageUrls.removeAt(index);
                } else {
                  _prescriptionImages.removeAt(
                    index - _existingImageUrls.length,
                  );
                }
              }),
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final visitDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final diagnosisText = _diagnosisController.text.trim();

    // تحويل نص الأدوية إلى قائمة بفصل السطور وإزالة الفراغات
    final medicationsText = _medicationController.text.trim();
    final medications = medicationsText.isEmpty
        ? <String>[]
        : medicationsText
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();

    if (widget.visit != null) {
      // Update existing visit
      final updatedVisit = widget.visit!.copyWith(
        visitDate: visitDateTime,
        diagnosis: diagnosisText.isEmpty ? null : diagnosisText,
        medications: medications,
        prescriptionImageUrls: _existingImageUrls,
      );
      context.read<PatientCubit>().updateVisit(
        updatedVisit,
        newPrescriptionImages: _prescriptionImages,
      );
    } else {
      // Add new visit
      context.read<PatientCubit>().addVisit(
        patientId: widget.patientId,
        clinicId: widget.clinicId,
        visitDate: visitDateTime,
        diagnosis: diagnosisText.isEmpty ? null : diagnosisText,
        medications: medications,
        prescriptionImages: _prescriptionImages,
      );
    }
  }
}
