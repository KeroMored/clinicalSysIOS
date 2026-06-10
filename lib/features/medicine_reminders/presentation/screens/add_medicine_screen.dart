import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/medicine_model.dart';
import '../cubit/medicine_cubit.dart';
import '../cubit/medicine_state.dart';
import '../widgets/schedule_selector.dart';
import '../widgets/time_picker_widget.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _notesController = TextEditingController();
  final List<TextEditingController> _medicineNameControllers = [
    TextEditingController(),
  ];
  final ImagePicker _imagePicker = ImagePicker();

  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0FA8BC);
  static const Color _titleColor = Color(0xFF1E3A5F);

  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5FAF9), Color(0xFFEDF4F3)],
  );

  File? _selectedImage;
  String _inputMode = 'none'; // 'text', 'image', 'none'
  RepeatType _selectedRepeatType = RepeatType.daily;
  List<String> _selectedTimes = [];
  List<int>? _selectedDays;
  int? _selectedMonthDay;
  bool _isSaving = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _notesController.dispose();
    _disposeAllNameControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MedicineCubit, MedicineState>(
      listener: (context, state) {
        if (!_isSaving) return;

        if (state is MedicineAdded) {
          final messenger = ScaffoldMessenger.of(context);
          setState(() {
            _isSaving = false;
            _uploadProgress = 1.0;
          });
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'تم إضافة الدواء بنجاح',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state is MedicineError) {
          if (!mounted) return;
          setState(() {
            _isSaving = false;
            _uploadProgress = 0.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(fontSize: 13),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'إضافة دواء جديد',
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
                  _buildIntroCard(),
                  const SizedBox(height: 12),
                  _buildInputModeSelector(),
                  if (_inputMode == 'text') ...[
                    const SizedBox(height: 12),
                    _buildPanel(
                      icon: Icons.medication_rounded,
                      title: 'أسماء الأدوية',
                      subtitle: 'يمكنك إضافة أكثر من دواء لنفس الجدول.',
                      child: _buildNameField(),
                    ),
                  ],
                  if (_inputMode == 'image') ...[
                    const SizedBox(height: 12),
                    _buildPanel(
                      icon: Icons.camera_alt_rounded,
                      title: 'صورة الدواء',
                      subtitle: 'التقط صورة واضحة لعلبة الدواء أو الروشتة.',
                      child: _buildImageSection(),
                    ),
                  ],
                  if (_inputMode != 'none') ...[
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
                ],
              ),
            ),
            if (_inputMode != 'none')
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomSaveBar(),
              ),
            if (_isSaving) _buildSavingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryColor, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'أضف دواءك وحدد أوقات التذكير بدقة لتصلك الإشعارات في الوقت المناسب.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
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

  Widget _buildInputModeSelector() {
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
          const Text(
            'طريقة إضافة الدواء',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  mode: 'image',
                  icon: Icons.camera_alt_rounded,
                  label: 'تصوير',
                  caption: 'أسرع في الإدخال',
                  isSelected: _inputMode == 'image',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModeButton(
                  mode: 'text',
                  icon: Icons.edit_note_rounded,
                  label: 'كتابة',
                  caption: 'أدق في التفاصيل',
                  isSelected: _inputMode == 'text',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String mode,
    required IconData icon,
    required String label,
    required String caption,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _inputMode = mode;
          if (mode == 'text') {
            _selectedImage = null;
          } else {
            _resetMedicineNameControllers();
          }
        });
      },
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_primaryColor, _primaryDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF6FAF9),
          border: Border.all(
            color: isSelected ? _primaryColor : const Color(0xFFD8E5E2),
            width: isSelected ? 1.3 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : _primaryColor,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _titleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Colors.white.withOpacity(0.85)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      children: [
        ...List.generate(_medicineNameControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _medicineNameControllers[index],
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'اسم الدواء ${index + 1}',
                      hintText: 'مثال: بنادول',
                      prefixIcon: const Icon(
                        Icons.medication_rounded,
                        color: _primaryColor,
                        size: 18,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (_medicineNameControllers.length > 1) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => _removeMedicineField(index),
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    tooltip: 'حذف',
                  ),
                ],
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _medicineNameControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: const Text(
              'إضافة دواء آخر',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        if (_selectedImage != null)
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
                  child: Image.file(
                    _selectedImage!,
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
              _selectedImage == null ? 'التقاط صورة للدواء' : 'إعادة التصوير',
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

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        hintText: 'مثال: بعد الأكل',
        prefixIcon: Icon(
          Icons.notes_rounded,
          color: AppTheme.primaryColor,
          size: 18,
        ),
      ),
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
              'حفظ الدواء',
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

  Widget _buildSavingOverlay() {
    final progressPercent = (_uploadProgress * 100).clamp(0, 100).round();

    return Container(
      color: Colors.black.withOpacity(0.35),
      alignment: Alignment.center,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingIndicator(strokeWidth: 3),
            const SizedBox(height: 10),
            Text(
              'جاري رفع الدواء... $progressPercent%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _uploadProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'فضلاً انتظر حتى اكتمال الرفع',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
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

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في التصوير: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _saveMedicine() {
    if (_inputMode == 'none') {
      _showWarning('يجب اختيار طريقة إضافة الدواء (تصوير أو كتابة)');
      return;
    }

    if (_inputMode == 'text') {
      final hasAtLeastOneName = _medicineNameControllers.any(
        (controller) => controller.text.trim().isNotEmpty,
      );
      if (!hasAtLeastOneName) {
        _showWarning('يجب كتابة اسم دواء واحد على الأقل');
        return;
      }
    }

    if (_inputMode == 'image' && _selectedImage == null) {
      _showWarning('يجب تصوير الدواء');
      return;
    }

    if (_selectedTimes.isEmpty) {
      _showWarning('يجب إضافة موعد تذكير واحد على الأقل');
      return;
    }

    if ((_selectedRepeatType == RepeatType.weekly ||
            _selectedRepeatType == RepeatType.specificDays) &&
        (_selectedDays == null || _selectedDays!.isEmpty)) {
      _showWarning('يجب اختيار يوم واحد على الأقل');
      return;
    }

    if (_selectedRepeatType == RepeatType.monthly &&
        _selectedMonthDay == null) {
      _showWarning('يجب اختيار يوم من الشهر');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final medicineNames = <String>[];
    if (_inputMode == 'text') {
      for (final controller in _medicineNameControllers) {
        final name = controller.text.trim();
        if (name.isNotEmpty) {
          medicineNames.add(name);
        }
      }
    }

    final medicine = MedicineModel(
      id: '',
      userId: user.uid,
      medicineNames: medicineNames,
      imageUrl: null,
      repeatType: _selectedRepeatType,
      reminderTimes: _selectedTimes,
      specificDays: _selectedDays,
      monthlyDay: _selectedMonthDay,
      isActive: true,
      createdAt: DateTime.now(),
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
    });

    context.read<MedicineCubit>().addMedicine(
      medicine,
      imageFile: _selectedImage,
      onUploadProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _uploadProgress = progress.clamp(0.0, 1.0);
        });
      },
    );
  }

  void _removeMedicineField(int index) {
    if (_medicineNameControllers.length <= 1) return;
    setState(() {
      _medicineNameControllers[index].dispose();
      _medicineNameControllers.removeAt(index);
    });
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetMedicineNameControllers() {
    _disposeAllNameControllers();
    _medicineNameControllers.add(TextEditingController());
  }

  void _disposeAllNameControllers() {
    for (final controller in _medicineNameControllers) {
      controller.dispose();
    }
    _medicineNameControllers.clear();
  }
}
