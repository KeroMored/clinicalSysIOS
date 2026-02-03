import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/medical_visit_model.dart';
import '../cubit/patient_cubit.dart';
import '../cubit/patient_state.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _medicationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _medications = [];
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
      _medications = List.from(widget.visit!.medications);
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
              isEdit ? 'تعديل الكشف' : 'إضافة كشف جديد',
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
            const SizedBox(height: 8),
            _buildDateTimeSection(),
            const SizedBox(height: 24),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
                      const Icon(Icons.calendar_today, 
                        color: AppTheme.primaryColor, size: 20),
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
                      const Icon(Icons.access_time, 
                        color: AppTheme.primaryColor, size: 20),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _diagnosisController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'اكتب تفاصيل التشخيص...',
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

  Widget _buildMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأدوية المكتوبة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _medicationController,
                decoration: InputDecoration(
                  hintText: 'اسم الدواء',
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
                ),
                onSubmitted: (_) => _addMedication(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addMedication,
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
              iconSize: 40,
            ),
          ],
        ),
        if (_medications.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _medications.map((med) {
              return Chip(
                label: Text(med),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => setState(() => _medications.remove(med)),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                labelStyle: const TextStyle(color: AppTheme.primaryColor),
              );
            }).toList(),
          ),
        ],
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
                  isExisting ? null : _prescriptionImages[index - _existingImageUrls.length],
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
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  foregroundColor: AppTheme.primaryColor,
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
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  foregroundColor: AppTheme.primaryColor,
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
                isEdit ? 'تحديث الكشف' : 'حفظ الكشف',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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

  void _addMedication() {
    final medication = _medicationController.text.trim();
    if (medication.isNotEmpty && !_medications.contains(medication)) {
      setState(() {
        _medications.add(medication);
        _medicationController.clear();
      });
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
  
  Widget _buildImageThumbnail(int index, bool isExisting, String? url, File? file) {
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
                : Image.file(
                    file!,
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              onPressed: () => setState(() {
                if (isExisting) {
                  _existingImageUrls.removeAt(index);
                } else {
                  _prescriptionImages.removeAt(index - _existingImageUrls.length);
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

    if (widget.visit != null) {
      // Update existing visit
      final updatedVisit = widget.visit!.copyWith(
        visitDate: visitDateTime,
        diagnosis: diagnosisText.isEmpty ? null : diagnosisText,
        medications: _medications,
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
            medications: _medications,
            prescriptionImages: _prescriptionImages,
          );
    }
  }
}
