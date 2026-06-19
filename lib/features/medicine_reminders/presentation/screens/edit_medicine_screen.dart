import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/medicine_model.dart';
import '../cubit/medicine_cubit.dart';
import '../cubit/medicine_state.dart';
import '../widgets/medicine_names_widget.dart';
import '../widgets/schedule_selector.dart';
import '../widgets/time_picker_widget.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class EditMedicineScreen extends StatefulWidget {
  final MedicineModel medicine;

  const EditMedicineScreen({super.key, required this.medicine});

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0FA8BC);
  static const Color _titleColor = Color(0xFF1E3A5F);

  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5FAF9), Color(0xFFEDF4F3)],
  );

  late TextEditingController _notesController;
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  late List<String> _medicineNames;
  late RepeatType _selectedRepeatType;
  late List<String> _selectedTimes;
  List<int>? _selectedDays;
  int? _selectedMonthDay;
  bool _isSaving = false;

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
    return BlocListener<MedicineCubit, MedicineState>(
      listener: (context, state) {
        if (!_isSaving) return;

        if (state is MedicineUpdated) {
          Navigator.pop(context);
          return;
        }

        if (state is MedicineError) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'تعديل الدواء',
            style: TextStyle(
              color: _titleColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: _pageGradient),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPanel(
                    icon: Icons.camera_alt_rounded,
                    title: 'صورة الدواء',
                    subtitle: 'يمكنك تحديث الصورة أو حذفها.',
                    child: _buildImageSection(),
                  ),
                  const SizedBox(height: 12),
                  _buildPanel(
                    icon: Icons.medication_rounded,
                    title: 'أسماء الأدوية',
                    subtitle: 'تأكد من صحة الأسماء قبل الحفظ.',
                    child: MedicineNamesWidget(
                      medicineNames: _medicineNames,
                      onNamesChanged: (names) {
                        setState(() {
                          _medicineNames = names;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPanel(
                    icon: Icons.sticky_note_2_outlined,
                    title: 'ملاحظات',
                    subtitle: 'اختياري: مثل قبل الأكل أو بعده.',
                    child: _buildNotesField(),
                  ),
                  const SizedBox(height: 12),
                  _buildPanel(
                    icon: Icons.repeat_rounded,
                    title: 'إعداد التكرار',
                    subtitle: 'حدد أيام وتكرار التذكير.',
                    child: ScheduleSelector(
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
                  ),
                  const SizedBox(height: 12),
                  _buildPanel(
                    icon: Icons.alarm_rounded,
                    title: 'مواعيد التذكير',
                    subtitle: 'أضف أكثر من موعد عند الحاجة.',
                    child: TimePickerWidget(
                      selectedTimes: _selectedTimes,
                      onTimesChanged: (times) {
                        setState(() => _selectedTimes = times);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomSaveBar(),
            ),
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.35),
                alignment: Alignment.center,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppLoadingIndicator(strokeWidth: 3),
                      SizedBox(height: 10),
                      Text(
                        'جاري حفظ التعديلات...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _primaryColor),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        hintText: 'مثال: بعد الأكل',
        prefixIcon: Icon(Icons.notes_rounded, color: _primaryColor, size: 18),
      ),
    );
  }

  Widget _buildImageSection() {
    final hasExistingImage =
        widget.medicine.imageUrl != null && _selectedImage == null;
    final hasImage = _selectedImage != null || hasExistingImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          Container(
            height: 190,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primaryColor.withOpacity(0.26)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(
                        minHeight: 28,
                        minWidth: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickImageFromCamera,
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: Text(
              _selectedImage == null ? 'تحديث صورة الدواء' : 'إعادة التصوير',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSaveBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveMedicine,
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text(
              'حفظ التعديلات',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              disabledBackgroundColor: const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
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
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _saveMedicine() {
    if (_medicineNames.isEmpty &&
        _selectedImage == null &&
        widget.medicine.imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة اسم دواء واحد أو صورة على الأقل'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة موعد تذكير واحد على الأقل'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
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
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedRepeatType == RepeatType.monthly &&
        _selectedMonthDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار يوم من الشهر'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
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

    setState(() => _isSaving = true);

    context.read<MedicineCubit>().updateMedicine(
      widget.medicine.id,
      updatedMedicine,
      newImageFile: _selectedImage,
    );
  }
}
