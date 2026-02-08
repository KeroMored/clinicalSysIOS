import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/clinic_model.dart';
import 'edit_clinic_screen.dart';
import 'clinic_details_screen.dart';
import 'bookings_management_screen.dart';
import 'bookings_history_screen.dart';
import 'patients_management_screen.dart';
import '../cubit/patient_cubit.dart';

class ClinicControlPage extends StatefulWidget {
  const ClinicControlPage({super.key});

  @override
  State<ClinicControlPage> createState() => _ClinicControlPageState();
}

class _ClinicControlPageState extends State<ClinicControlPage> {
  ClinicModel? _clinic;
  bool _isLoading = true;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  Future<void> _loadClinicData() async {
    setState(() => _isLoading = true);

    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      try {
        // Get clinic by authEmails (using array-contains)
        final querySnapshot = await FirebaseFirestore.instance
            .collection('clinics')
            .where('authEmails', arrayContains: authState.user.email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          setState(() {
            _clinic = ClinicModel.fromFirestore(doc);
            _isLoading = false;
          });
          
          // Subscribe to clinic notifications for online bookings
          await _notificationService.subscribeToClinicTopic(
            _clinic!.id,
            authState.user.uid,
          );
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        print('Error loading clinic: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم العيادة',style: TextStyle(color: Colors.white),),
          centerTitle: true,
          leading:  IconButton( 
            icon: const Icon(Icons.arrow_back, color: Colors.white), 
            onPressed: () => Navigator.of(context).pop(), 
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _clinic == null
                ? _buildNoClinicView()
                : _buildClinicControlPanel(),
      ),
    );
  }

  Widget _buildNoClinicView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد عيادة مرتبطة بحسابك',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'يرجى التواصل مع الإدارة لربط عيادتك بحسابك',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicControlPanel() {
    final authState = context.read<AuthCubit>().state;
    String? currentUserEmail;
    if (authState is Authenticated) {
      currentUserEmail = authState.user.email;
    }

    // التحقق: هل المستخدم الحالي هو الدكتور؟
    // نتحقق من authEmails بدلاً من doctorEmails لأن كل من يملك صلاحية الدخول يستطيع رؤية المرضى
    final bool isDoctor = currentUserEmail != null &&
                          _clinic!.authEmails.any((email) => 
                              email.toLowerCase() == currentUserEmail!.toLowerCase());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic Info Card
          // Card(
          //   elevation: 4,
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Row(
          //           children: [
          //             CircleAvatar(
          //               radius: 35,
          //               backgroundImage: _clinic!.clinicImageUrl != null
          //                   ? NetworkImage(_clinic!.clinicImageUrl!)
          //                   : null,
          //               child: _clinic!.clinicImageUrl == null
          //                   ? const Icon(Icons.local_hospital, size: 35)
          //                   : null,
          //             ),
          //             const SizedBox(width: 16),
          //             Expanded(
          //               child: Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   Text(
          //                     'د. ${_clinic!.doctorName}',
          //                     style: const TextStyle(
          //                       fontSize: 20,
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                   const SizedBox(height: 4),
          //                   Text(
          //                     _clinic!.department.arabicName,
          //                     style: TextStyle(
          //                       fontSize: 14,
          //                       color: Colors.grey[600],
          //                     ),
          //                   ),
          //                   Text(
          //                     _clinic!.specialization,
          //                     style: TextStyle(
          //                       fontSize: 13,
          //                       color: Colors.grey[600],
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ],
          //         ),
          //         const Divider(height: 24),
          //         _buildInfoRow(Icons.location_on, _clinic!.address),
          //         const SizedBox(height: 8),
          //         _buildInfoRow(Icons.phone, _clinic!.phone),
          //         if (_clinic!.whatsapp != null) ...[
          //           const SizedBox(height: 8),
          //           _buildInfoRow(MdiIcons.whatsapp, _clinic!.whatsapp!),
          //         ],
          //         const SizedBox(height: 8),
          //         _buildInfoRow(
          //           Icons.attach_money,
          //           'سعر الكشف: ${_clinic!.consultationFee} جنيه',
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 16),

          // Control Buttons
          // const Text(
          //   'إدارة العيادة',
          //   style: TextStyle(
          //     fontSize: 18,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          // const SizedBox(height: 12),

          // View Clinic Details
       

          // Manage Bookings
          _buildControlButton(
            icon: Icons.calendar_month_rounded,
            title: 'إدارة الحجوزات',
            subtitle: 'عرض وتأكيد الحجوزات الأونلاين',
            color: const Color(0xFF3B82F6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingsManagementScreen(clinic: _clinic!),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Patient Management - للدكتور فقط
          if (isDoctor) ...[
            _buildControlButton(
              icon: Icons.people_rounded,
              title: 'متابعة المرضى',
              subtitle: 'إدارة المرضى وتسجيل الكشوفات الطبية',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<PatientCubit>(),
                      child: PatientsManagementScreen(clinicId: _clinic!.id),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          // Bookings History
          _buildControlButton(
            icon: Icons.history_rounded,
            title: 'سجل الحجوزات',
            subtitle: 'عرض سجل الحجوزات السابقة حسب التاريخ',
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingsHistoryScreen(clinicId: _clinic!.id),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
   _buildControlButton(
            icon: Icons.visibility,
            title: 'عرض تفاصيل العيادة',
            subtitle: 'شاهد كيف تظهر عيادتك للمرضى',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClinicDetailsScreen(
                    clinic: _clinic!,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Edit Clinic (Doctor only)
          if (isDoctor) // فقط الدكتور يمكنه تعديل بيانات العيادة
            _buildControlButton(
              icon: Icons.edit,
              title: 'تعديل بيانات العيادة',
              subtitle: 'قم بتحديث معلومات العيادة',
              color: Colors.orange,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditClinicScreen(clinic: _clinic!),
                  ),
                );
                if (result == true) {
                  _loadClinicData(); // Reload data after edit
                }
              },
            ),
          if (isDoctor)
            const SizedBox(height: 12),

          // Toggle Active Status
          _buildControlButton(
            icon: _clinic!.isActive ? Icons.visibility_off : Icons.visibility,
            title: _clinic!.isActive ? 'إخفاء العيادة' : 'إظهار العيادة',
            subtitle: _clinic!.isActive
                ? 'إخفاء العيادة من التطبيق مؤقتاً'
                : 'إظهار العيادة في التطبيق',
            color: _clinic!.isActive ? Colors.grey : Colors.green,
            onTap: () => _toggleClinicActiveStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0891B2).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleClinicActiveStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(_clinic!.id)
          .update({'isActive': !_clinic!.isActive});

      setState(() {
        _clinic = ClinicModel(
          id: _clinic!.id,
          doctorName: _clinic!.doctorName,
          department: _clinic!.department,
          specialization: _clinic!.specialization,
          about: _clinic!.about,
          consultationFee: _clinic!.consultationFee,
          phones: _clinic!.phones,
          whatsapp: _clinic!.whatsapp,
          address: _clinic!.address,
          latitude: _clinic!.latitude,
          longitude: _clinic!.longitude,
          authEmails: _clinic!.authEmails,
          doctorPhone: _clinic!.doctorPhone,
          workingHours: _clinic!.workingHours,
          holidays: _clinic!.holidays,
          clinicImageUrl: _clinic!.clinicImageUrl,
          doctorImageUrl: _clinic!.doctorImageUrl,
          isActive: !_clinic!.isActive,
          createdAt: _clinic!.createdAt,
          ownerId: _clinic!.ownerId,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_clinic!.isActive
                ? 'تم إظهار العيادة بنجاح'
                : 'تم إخفاء العيادة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
