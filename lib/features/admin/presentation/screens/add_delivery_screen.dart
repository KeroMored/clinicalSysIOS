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
  final _deliveryPhoneController = TextEditingController();
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
    _deliveryPhoneController.dispose();
    _deliveryWhatsappController.dispose();
    _deliveryFeeController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    super.dispose();
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
        deliveryPhone: _deliveryPhoneController.text.trim(),
        deliveryWhatsApp: _deliveryWhatsappController.text.trim(),
        profileImageUrl: profileImageUrl,
        vehicleType: _selectedVehicleType,
        vehiclePlateNumber: '',
        deliveryFee: double.parse(_deliveryFeeController.text.trim()),
        address: _addressController.text.trim(),
        governorate: '',
        city: '',
        latitude: _latitude,
        longitude: _longitude,
        about: _aboutController.text.trim(),
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
                
                // Phone Number
                TextFormField(
                  controller: _deliveryPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
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
                const SizedBox(height: 16),
                
                // Location Coordinates
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(_latitude),
                        initialValue: _latitude.toString(),
                        decoration: const InputDecoration(
                          labelText: 'خط العرض (Latitude)',
                          prefixIcon: Icon(Icons.my_location),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null) {
                            _latitude = parsed;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(_longitude),
                        initialValue: _longitude.toString(),
                        decoration: const InputDecoration(
                          labelText: 'خط الطول (Longitude)',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null) {
                            _longitude = parsed;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _isLoadingLocation
                          ? 'جاري تحديد الموقع...'
                          : (_latitude == 0.0 || _longitude == 0.0)
                              ? 'تحديد الموقع التلقائي *'
                              : 'تحديد الموقع التلقائي ✓',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_latitude == 0.0 || _longitude == 0.0) ? Colors.red : const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_locationStatus.isNotEmpty && !_isLoadingLocation)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _locationStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: _locationStatus.contains('بنجاح')
                            ? Colors.green
                            : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_latitude == 0.0 || _longitude == 0.0)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ يجب تحديد الموقع التلقائي للمتابعة',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'يمكنك تحديد الموقع تلقائياً أو كتابة الإحداثيات يدوياً',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                        // About
                        TextFormField(
                  controller: _aboutController,
                  decoration: const InputDecoration(
                    labelText: 'نبذة عن الديليفري',
                    prefixIcon: Icon(Icons.info),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال نبذة عن الديليفري';
                    }
                    return null;
                  },
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
