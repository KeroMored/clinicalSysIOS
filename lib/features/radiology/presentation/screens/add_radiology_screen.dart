import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/radiology_model.dart';
import '../../data/models/working_hours.dart';
import '../cubit/radiology_cubit.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class AddRadiologyScreen extends StatefulWidget {
  const AddRadiologyScreen({super.key});

  @override
  State<AddRadiologyScreen> createState() => _AddRadiologyScreenState();
}

class _AddRadiologyScreenState extends State<AddRadiologyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _centerNameController = TextEditingController();
  final _centerPhoneController = TextEditingController();
  final _centerWhatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Location
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLoadingLocation = false;
  String _locationStatus = '';

  // Services
  final Set<String> _selectedServices = {};

  // Working Hours
  final Map<String, TimeOfDay?> _workingHoursFrom = {};
  final Map<String, TimeOfDay?> _workingHoursTo = {};
  final Map<String, bool> _isHolidayDays = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize working hours
    final days = [
      'saturday',
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
    ];
    for (var day in days) {
      _workingHoursFrom[day] = const TimeOfDay(hour: 8, minute: 0);
      _workingHoursTo[day] = const TimeOfDay(hour: 20, minute: 0);
      _isHolidayDays[day] = false;
    }
  }

  @override
  void dispose() {
    _centerNameController.dispose();
    _centerPhoneController.dispose();
    _centerWhatsappController.dispose();
    _emailController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'إضافة مركز أشعة',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF06B6D4),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildCenterInfoSection(),
            const SizedBox(height: 20),
            _buildOwnerInfoSection(),
            const SizedBox(height: 20),
            _buildLocationSection(),
            const SizedBox(height: 20),
            _buildServicesSection(),
            const SizedBox(height: 20),
            _buildWorkingHoursSection(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات المركز',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF06B6D4),
              ),
            ),
            const Divider(),
            SizedBox(height: 8),
            TextFormField(
              controller: _centerNameController,
              decoration: const InputDecoration(
                labelText: 'اسم مركز الأشعة *',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _centerPhoneController,
              decoration: const InputDecoration(
                labelText: 'رقم هاتف المركز *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _centerWhatsappController,
              decoration: InputDecoration(
                labelText: 'رقم واتساب المركز *',
                prefixIcon: Icon(FontAwesomeIcons.whatsapp),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني للمصادقة *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                helperText: 'سيتم استخدامه لتسجيل الدخول',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'مطلوب';
                if (!value!.contains('@')) return 'بريد إلكتروني غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'وصف المركز (اختياري)',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
                helperText: 'وصف مختصر عن مركز الأشعة وخدماته',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات صاحب المركز',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF06B6D4),
              ),
            ),
            const Divider(),
            SizedBox(height: 8),

            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'اسم المالك *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerPhoneController,
              decoration: const InputDecoration(
                labelText: 'رقم هاتف المالك *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الموقع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF06B6D4),
              ),
            ),
            const Divider(),
            SizedBox(height: 8),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'العنوان التفصيلي *',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: AppLoadingIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.touch_app),
                    label: Text(
                      _isLoadingLocation
                          ? 'جاري التحديد...'
                          : (_latitude == 0.0 || _longitude == 0.0)
                          ? 'تحديد الموقع '
                          : 'تحديد الموقع ✓',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_latitude == 0.0 || _longitude == 0.0)
                          ? const Color(0xFF06B6D4)
                          : const Color(0xFF06B6D4),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_locationStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _locationStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: _locationStatus.contains('✓')
                        ? Colors.green
                        : const Color(0xFF06B6D4),
                  ),
                ),
              ),
            if (_latitude == 0.0 || _longitude == 0.0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ يجب تحديد الموقع التلقائي للمتابعة',
                  style: TextStyle(
                    color: Color(0xFF06B6D4),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            if (_latitude != 0.0 && _longitude != 0.0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'الإحداثيات: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الخدمات المتاحة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF06B6D4),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showServicesDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة خدمات'),
                ),
              ],
            ),
            const Divider(),
            if (_selectedServices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('لم يتم اختيار خدمات بعد'),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedServices.map((service) {
                  return Chip(
                    label: Text(service),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _selectedServices.remove(service));
                    },
                    backgroundColor: const Color(0xFF06B6D4).withOpacity(0.1),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection() {
    final daysInArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مواعيد العمل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF06B6D4),
              ),
            ),
            const Divider(),
            ...daysInArabic.entries.map((entry) {
              return _buildWorkingHourRow(entry.key, entry.value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHourRow(String day, String dayArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              dayArabic,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(day, true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isHolidayDays[day] == true
                            ? 'مغلق'
                            : _formatTimeOfDay(_workingHoursFrom[day]!),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(day, false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isHolidayDays[day] == true
                            ? 'مغلق'
                            : _formatTimeOfDay(_workingHoursTo[day]!),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: _isHolidayDays[day] ?? false,
            onChanged: (value) {
              setState(() {
                _isHolidayDays[day] = value ?? false;
              });
            },
            activeColor: Colors.red,
          ),
          const Text('مغلق', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF06B6D4),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isSubmitting
            ? const AppLoadingIndicator(color: Colors.white)
            : const Text(
                'إضافة مركز الأشعة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _showServicesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('اختر الخدمات'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: RadiologyServices.getAllServices().map((service) {
                    return CheckboxListTile(
                      title: Text(service),
                      value: _selectedServices.contains(service),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedServices.add(service);
                          } else {
                            _selectedServices.remove(service);
                          }
                        });
                        setState(() {});
                      },
                      activeColor: const Color(0xFF06B6D4),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('تم'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectTime(String day, bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isFrom
          ? (_workingHoursFrom[day] ?? const TimeOfDay(hour: 8, minute: 0))
          : (_workingHoursTo[day] ?? const TimeOfDay(hour: 20, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _workingHoursFrom[day] = picked;
        } else {
          _workingHoursTo[day] = picked;
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'جاري تحديد الموقع...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'خدمة تحديد الموقع غير مفعلة';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'تم رفض إذن الموقع';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus = 'تم تحديد الموقع بنجاح ✓';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'خطأ في تحديد الموقع';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    if (_latitude == 0.0 || _longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تحديد الموقع التلقائي'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار خدمة واحدة على الأقل')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare working hours
      final Map<String, WorkingHours> workingHours = {};
      _workingHoursFrom.forEach((day, from) {
        final to = _workingHoursTo[day];
        final isHoliday = _isHolidayDays[day] ?? false;
        workingHours[day] = WorkingHours(
          openTime: isHoliday
              ? '00:00 AM'
              : (from != null ? _formatTimeOfDay(from) : '00:00 AM'),
          closeTime: isHoliday
              ? '00:00 AM'
              : (to != null ? _formatTimeOfDay(to) : '00:00 AM'),
          isHoliday: isHoliday,
        );
      });

      // Create radiology model
      final radiology = RadiologyModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        centerName: _centerNameController.text.trim(),
        centerPhone: _centerPhoneController.text.trim(),
        centerWhatsApp: _centerWhatsappController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        authEmails: [_emailController.text.trim()],
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        governorate: '',
        city: '',
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        services: _selectedServices.toList(),
        homeVisit: false,
        licenseNumber: null,
        licenseImageUrl: null,
        workingHours: workingHours,
        isApproved: false,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Add to Firestore
      if (!mounted) return;
      await context.read<RadiologyCubit>().addRadiologyCenter(radiology);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة مركز الأشعة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
