import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../data/models/medicine_model.dart';
import '../cubit/medicine_cubit.dart';
import '../widgets/schedule_selector.dart';
import '../widgets/time_picker_widget.dart';
import '../widgets/medicine_names_widget.dart';

class EditMedicineScreen extends StatefulWidget {
  final MedicineModel medicine;

  const EditMedicineScreen({
    super.key,
    required this.medicine,
  });

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  late List<String> _medicineNames;
  late RepeatType _selectedRepeatType;
  late List<String> _selectedTimes;
  List<int>? _selectedDays;
  int? _selectedMonthDay;

  @override
  void initState() {
    super.initState();
    _medicineNames = List.from(widget.medicine.medicineNames);
    _notesController = TextEditingController(text: widget.medicine.notes);
    _selectedRepeatType = widget.medicine.repeatType;
    _selectedTimes = List.from(widget.medicine.reminderTimes);
    _selectedDays = widget.medicine.specificDays != null 
        ? List.from(widget.medicine.specificDays!) 
        : null;
    _selectedMonthDay = widget.medicine.monthlyDay;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'تعديل الدواء',
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Section
              _buildImageSection(),
              const SizedBox(height: 24),

              // Medicine Names Widget
              MedicineNamesWidget(
                medicineNames: _medicineNames,
                onNamesChanged: (names) {
                  setState(() {
                    _medicineNames = names;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Notes
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    hintText: 'مثال: بعد الأكل',
                    prefixIcon: const Icon(Icons.note, color: Color(0xFF06B6D4)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 24),

              // Schedule Selector
              ScheduleSelector(
                selectedType: _selectedRepeatType,
                selectedDays: _selectedDays,
                selectedMonthDay: _selectedMonthDay,
                onTypeChanged: (type) {
                  setState(() => _selectedRepeatType = type);
                },
                onDaysChanged: (days) {
                  setState(() => _selectedDays = days);
                },
                onMonthDayChanged: (day) {
                  setState(() => _selectedMonthDay = day);
                },
              ),
              const SizedBox(height: 24),

              // Time Picker
              TimePickerWidget(
                selectedTimes: _selectedTimes,
                onTimesChanged: (times) {
                  setState(() => _selectedTimes = times);
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'حفظ التعديلات',
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
    );
  }

  Widget _buildImageSection() {
    final hasExistingImage = widget.medicine.imageUrl != null && _selectedImage == null;
    final hasImage = _selectedImage != null || hasExistingImage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Preview (only if image exists)
        if (hasImage)
          Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF06B6D4).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          widget.medicine.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() => _selectedImage = null);
                      },
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Camera Button
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _pickImageFromCamera,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.camera_alt, size: 26),
            label: const Text(
              'تصوير الدواء',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في التصوير: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveMedicine() {
    // Validation
    if (_medicineNames.isEmpty && 
        _selectedImage == null && 
        widget.medicine.imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة اسم دواء واحد أو صورة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة موعد تذكير واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if ((_selectedRepeatType == RepeatType.weekly || 
         _selectedRepeatType == RepeatType.specificDays) && 
        (_selectedDays == null || _selectedDays!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار يوم واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedRepeatType == RepeatType.monthly && _selectedMonthDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار يوم من الشهر'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final updatedMedicine = widget.medicine.copyWith(
      medicineNames: _medicineNames,
      repeatType: _selectedRepeatType,
      reminderTimes: _selectedTimes,
      specificDays: _selectedDays,
      monthlyDay: _selectedMonthDay,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
    );

    context.read<MedicineCubit>().updateMedicine(
          widget.medicine.id,
          updatedMedicine,
          newImageFile: _selectedImage,
        );

    Navigator.pop(context);
  }
}
