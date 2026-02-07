import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:io';
import '../../../delivery/data/models/delivery_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AddDeliveryScreen extends StatefulWidget {
  const AddDeliveryScreen({super.key});

  @override
  State<AddDeliveryScreen> createState() => _AddDeliveryScreenState();
}

class _AddDeliveryScreenState extends State<AddDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _deliveryNameController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [TextEditingController()]; // Multiple phones
  final _deliveryWhatsappController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _addressController = TextEditingController();
  final _aboutController = TextEditingController();
  
  String _selectedVehicleType = VehicleTypes.motorcycle;
  double _latitude = 30.0444;
  double _longitude = 31.2357;
  
  bool _isLoadingLocation = false;
  String _locationStatus = '';
  
  XFile? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _deliveryNameController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _deliveryWhatsappController.dispose();
    _deliveryFeeController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    super.dispose();
  }
  
  void _addPhoneField() {
    setState(() {
      _phoneControllers.add(TextEditingController());
    });
  }
  
  void _removePhoneField(int index) {
    if (_phoneControllers.length > 1) {
      setState(() {
        _phoneControllers[index].dispose();
        _phoneControllers.removeAt(index);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في اختيار الصورة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('deliveries/profiles/$fileName');
      
      final File file = File(image.path);
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'جاري الحصول على الموقع...';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = 'خدمة الموقع غير مفعلة';
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('خدمة الموقع'),
              content: const Text('الرجاء تفعيل خدمة الموقع للمتابعة'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatus = 'تم رفض إذن الموقع';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم رفض إذن الوصول للموقع'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = 'إذن الموقع مرفوض نهائياً';
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('إذن الموقع'),
              content: const Text(
                'تم رفض إذن الموقع نهائياً. يرجى تفعيله من إعدادات التطبيق.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
        _locationStatus = 'تم الحصول على الموقع بنجاح';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديد الموقع: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationStatus = 'فشل في الحصول على الموقع';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }


    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload profile image if selected
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadImage(_profileImage!);
      }

      final delivery = DeliveryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deliveryName: _deliveryNameController.text.trim(),
        deliveryPhones: _phoneControllers
            .map((controller) => controller.text.trim())
            .where((phone) => phone.isNotEmpty)
            .toList(),
        deliveryWhatsApp: _deliveryWhatsappController.text.trim(),
        profileImageUrl: profileImageUrl,
        vehicleType: _selectedVehicleType,
        vehiclePlateNumber: '',
        deliveryFee: double.parse(_deliveryFeeController.text.trim()),
        address: _addressController.text.trim(),
        governorate: '',
        city: '',
        latitude: null,
        longitude: null,
        about: _aboutController.text.trim().isNotEmpty 
            ? _aboutController.text.trim() 
            : null, // Now optional
        availableNow: false,
        isApproved: false,
        isActive: false,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rating: 0.0,
        reviewCount: 0,
        completedDeliveries: 0,
        notes: 'تمت الإضافة من قبل الأدمن - في انتظار الموافقة',
      );

      if (mounted) {
        context.read<AdminCubit>().addDelivery(delivery);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة الديليفري: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة ديليفري جديد'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is DeliveryAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المعلومات الأساسية',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),
                        // Profile Image
                        Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImage != null
                            ? FileImage(File(_profileImage!.path))
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Delivery Name
                TextFormField(
                  controller: _deliveryNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الديليفري',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم الديليفري';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone Numbers (Multiple)
                ...List.generate(_phoneControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneControllers[index],
                            decoration: InputDecoration(
                              labelText: 'رقم الهاتف ${index + 1}',
                              prefixIcon: const Icon(Icons.phone),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (index == 0 && (value == null || value.isEmpty)) {
                                return 'يرجى إدخال رقم هاتف واحد على الأقل';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (index == _phoneControllers.length - 1)
                          IconButton(
                            onPressed: _addPhoneField,
                            icon: const Icon(Icons.add_circle),
                            color: const Color(0xFF06B6D4),
                            tooltip: 'إضافة رقم آخر',
                          ),
                        if (index > 0)
                          IconButton(
                            onPressed: () => _removePhoneField(index),
                            icon: const Icon(Icons.remove_circle),
                            color: Colors.red,
                            tooltip: 'حذف',
                          ),
                      ],
                    ),
                  );
                }),
                
                // WhatsApp Number
                TextFormField(
                  controller: _deliveryWhatsappController,
                  decoration:  InputDecoration(
                    labelText: 'رقم الواتساب',
                    prefixIcon: Icon(MdiIcons.whatsapp),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم الواتساب';
                    }
                    return null;
                  },
                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // معلومات المركبة
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معلومات المركبة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),
                        // Vehicle Type
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'نوع المركبة',
                    prefixIcon: Icon(Icons.two_wheeler),
                    border: OutlineInputBorder(),
                  ),
                  items: VehicleTypes.getAllTypes().map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Delivery Fee
                TextFormField(
                  controller: _deliveryFeeController,
                  decoration: const InputDecoration(
                    labelText: 'رسوم التوصيل (جنيه)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رسوم التوصيل';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // العنوان والموقع
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'العنوان والموقع',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),
                        // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان التفصيلي',
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال العنوان';
                    }
                    return null;
                  },
                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // معلومات إضافية
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معلومات إضافية',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 12),
                        // About (Optional)
                        TextFormField(
                  controller: _aboutController,
                  decoration: const InputDecoration(
                    labelText: 'نبذة عن الديليفري (اختياري)',
                    prefixIcon: Icon(Icons.info),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إضافة الديليفري',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}
