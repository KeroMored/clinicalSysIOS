import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../data/models/medicine_model.dart';
import '../cubit/medicine_cubit.dart';
import '../cubit/medicine_state.dart';
import '../widgets/schedule_selector.dart';
import '../widgets/time_picker_widget.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<TextEditingController> _medicineNameControllers = [TextEditingController()];
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String _inputMode = 'none'; // 'text', 'image', or 'none'
  RepeatType _selectedRepeatType = RepeatType.daily;
  List<String> _selectedTimes = [];
  List<int>? _selectedDays;
  int? _selectedMonthDay;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    for (var controller in _medicineNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MedicineCubit, MedicineState>(
      listener: (context, state) {
        if (state is MedicineAdded) {
          // Success - navigate back
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة الدواء بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state is MedicineError) {
          // Error
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'إضافة دواء جديد',
          gradient: const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input Mode Selection
                    _buildInputModeSelector(),
                    const SizedBox(height: 24),

                    // Image OR Text input based on mode
                    if (_inputMode == 'image')
                      _buildImageSection()
                    else if (_inputMode == 'text')
                      _buildNameField(),

                    if (_inputMode != 'none') ...[
                      const SizedBox(height: 24),

                      // Notes
                      _buildNotesField(),
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
                      _buildSaveButton(),
                    ],
                  ],
                ),
              ),
            ),
            
            // Loading Overlay
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'جاري حفظ الدواء...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF06B6D4).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر طريقة الإضافة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  mode: 'image',
                  icon: Icons.camera_alt,
                  label: 'تصوير الدواء',
                  isSelected: _inputMode == 'image',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeButton(
                  mode: 'text',
                  icon: Icons.edit,
                  label: 'كتابة الاسم',
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
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _inputMode = mode;
          // Reset the other mode's data
          if (mode == 'text') {
            _selectedImage = null;
          } else {
            // Clear all medicine name controllers
            for (var controller in _medicineNameControllers) {
              controller.clear();
            }
            // Reset to single controller
            _medicineNameControllers.clear();
            _medicineNameControllers.add(TextEditingController());
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF06B6D4) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // List of medicine name fields
        ...List.generate(_medicineNameControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _medicineNameControllers[index],
                      decoration: InputDecoration(
                        labelText: 'اسم الدواء ${index + 1}',
                        hintText: 'مثال: بنادول',
                        prefixIcon: const Icon(Icons.medication, color: Color(0xFF06B6D4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (_inputMode == 'text' && (value == null || value.trim().isEmpty)) {
                          return 'يجب كتابة اسم الدواء';
                        }
                        return null;
                      },
                    ),
                  ),
                  // Delete button (only show if more than 1 field)
                  if (_medicineNameControllers.length > 1)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _medicineNameControllers[index].dispose();
                          _medicineNameControllers.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      padding: const EdgeInsets.all(8),
                    ),
                ],
              ),
            ),
          );
        }),
        
        // Add more medicine button
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF06B6D4).withOpacity(0.5),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _medicineNameControllers.add(TextEditingController());
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF06B6D4)),
            label: const Text(
              'إضافة دواء آخر',
              style: TextStyle(
                color: Color(0xFF06B6D4),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Container(
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
    );
  }

  Widget _buildSaveButton() {
    return Container(
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
        onPressed: _isSaving ? null : _saveMedicine,
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
          'حفظ الدواء',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Preview (only if image exists)
        if (_selectedImage != null)
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
            label: Text(
              _selectedImage == null ? 'تصوير الدواء' : 'إعادة التصوير',
              style: const TextStyle(
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
    // Validate input mode selection
    if (_inputMode == 'none') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار طريقة إضافة الدواء (تصوير أو كتابة)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate based on input mode
    if (_inputMode == 'text') {
      bool hasAtLeastOneName = false;
      for (var controller in _medicineNameControllers) {
        if (controller.text.trim().isNotEmpty) {
          hasAtLeastOneName = true;
          break;
        }
      }
      
      if (!hasAtLeastOneName) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب كتابة اسم دواء واحد على الأقل'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else if (_inputMode == 'image') {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب تصوير الدواء'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Validate times
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة موعد تذكير واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate days for weekly/specific days
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

    // Validate month day for monthly
    if (_selectedRepeatType == RepeatType.monthly && _selectedMonthDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار يوم من الشهر'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Build medicine names list based on input mode
    final List<String> medicineNames = [];
    if (_inputMode == 'text') {
      for (var controller in _medicineNameControllers) {
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
      imageUrl: null, // Will be set in repository
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

    setState(() => _isSaving = true);

    context.read<MedicineCubit>().addMedicine(
          medicine,
          imageFile: _selectedImage,
        );
  }
}
