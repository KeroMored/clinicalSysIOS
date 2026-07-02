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
import 'send_clinic_notification_screen.dart';
import '../cubit/patient_cubit.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class ClinicControlPage extends StatefulWidget {
  const ClinicControlPage({super.key});

  @override
  State<ClinicControlPage> createState() => _ClinicControlPageState();
}

class _ClinicControlPageState extends State<ClinicControlPage> {
  ClinicModel? _clinic;
  bool _isLoading = true;
  final NotificationService _notificationService = NotificationService();

  // Theme colors aligned with the refreshed app style
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [_primaryColor, _secondaryColor],
  );

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  Future<void> _loadClinicData() async {
    if (!mounted) return;
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
          if (mounted) {
            setState(() {
              _clinic = ClinicModel.fromFirestore(doc);
              _isLoading = false;
            });
          }

          print('✅ تم تحميل بيانات العيادة - ID: ${doc.id}');
          print('   hasNursery: ${_clinic!.hasNursery}');
          print('   onlineBookingEnabled: ${_clinic!.onlineBookingEnabled}');
          print('   doctorEmails: ${_clinic!.doctorEmails}');
          print('   secretaryEmails: ${_clinic!.secretaryEmails}');
          print('   authEmails: ${_clinic!.authEmails}');

          // Subscribe to clinic notifications for online bookings
          await _notificationService.subscribeToClinicTopic(
            _clinic!.id,
            authState.user.uid,
          );
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('لم يتم العثور على بيانات العيادة'),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error loading clinic: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('خطأ في تحميل البيانات: $e')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const AppLoadingIndicator(
                        color: _primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'جاري تحميل بيانات العيادة...',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _clinic == null
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _loadClinicData,
                color: _primaryColor,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Premium App Bar
                    _buildAppBar(),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeaderSummaryCard(),
                            const SizedBox(height: 14),
                            const Text(
                              'إجراءات الإدارة',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Action Buttons
                            _buildActionButtons(),
                            const SizedBox(height: 24),
                            const Text(
                              'معلومات العيادة',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Clinic Info Card
                            _buildClinicInfoCard(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد عيادة مرتبطة بحسابك',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى التواصل مع الإدارة لربط عيادتك',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: false,
      pinned: true,
      toolbarHeight: 62,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textPrimary,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'إدارة العيادة',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: _textPrimary,
            size: 20,
          ),
          onPressed: _loadClinicData,
          tooltip: 'تحديث',
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildHeaderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.24),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _clinic != null
                      ? 'د. ${_clinic!.doctorName}'
                      : 'إدارة العيادة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'إدارة الحجوزات والمرضى والإشعارات من مكان واحد',
                  style: TextStyle(
                    color: Color(0xFFE7F6FA),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicInfoCard() {
    final authState = context.read<AuthCubit>().state;
    String? currentUserEmail;
    if (authState is Authenticated) {
      currentUserEmail = authState.user.email;
    }

    // التحقق: هل المستخدم الحالي هو الدكتور؟
    final bool isDoctor =
        currentUserEmail != null &&
        _clinic!.authEmails.any(
          (email) => email.toLowerCase() == currentUserEmail!.toLowerCase(),
        );

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7EF), width: 1),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor.withOpacity(0.15),
                            _secondaryColor.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: _primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'معلومات العيادة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                if (isDoctor)
                  Container(
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditClinicScreen(clinic: _clinic!),
                          ),
                        );
                        if (result == true) {
                          _loadClinicData();
                        }
                      },
                      icon: const Icon(Icons.edit_rounded, size: 22),
                      color: _primaryColor,
                      tooltip: 'تعديل البيانات',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Doctor Name
            _buildInfoRow(
              icon: Icons.person_rounded,
              label: 'اسم الطبيب',
              value: 'د. ${_clinic!.doctorName}',
              color: _primaryColor,
            ),
            const SizedBox(height: 18),

            // Specialization (Clinic Services)
            _buildInfoRow(
              icon: Icons.medical_services_rounded,
              label: 'خدمات العيادة',
              value: _clinic!.specialization.join(' • '),
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 18),

            // Address
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              label: 'العنوان',
              value: _clinic!.address,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 18),

            // Phone
            _buildInfoRow(
              icon: Icons.phone_rounded,
              label: 'رقم الهاتف',
              value: _clinic!.phones.join(', '),
              color: const Color(0xFF8B5CF6),
            ),

            // Consultation Fee
            const SizedBox(height: 18),
            _buildInfoRow(
              icon: Icons.attach_money_rounded,
              label: 'سعر الكشف',
              value: '${_clinic!.consultationFee} جنيه',
              color: const Color(0xFFF59E0B),
            ),

            const SizedBox(height: 24),

            // View Details Button
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClinicDetailsScreen(clinic: _clinic!),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.3),
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  color: _primaryColor.withOpacity(0.05),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      color: _primaryColor,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'عرض صفحة العيادة',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final authState = context.read<AuthCubit>().state;
    String? currentUserEmail;
    if (authState is Authenticated) {
      currentUserEmail = authState.user.email;
    }

    final bool isDoctor =
        currentUserEmail != null &&
        _clinic!.authEmails.any(
          (email) => email.toLowerCase() == currentUserEmail!.toLowerCase(),
        );

    return Column(
      children: [
        // Manage Bookings Button
        _buildControlButton(
          icon: Icons.calendar_month_rounded,
          title: 'إدارة الحجوزات',
          subtitle: 'عرض وتأكيد الحجوزات الأونلاين',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BookingsManagementScreen(clinic: _clinic!),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Send Notifications Button

        // Patient Management - للدكتور فقط
        if (isDoctor) ...[
          _buildControlButton(
            icon: Icons.people_rounded,
            title: 'متابعة المرضى',
            subtitle: 'إدارة المرضى وتسجيل الكشوفات الطبية',
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
          const SizedBox(height: 16),
        ],

        // Bookings History
        _buildControlButton(
          icon: Icons.history_rounded,
          title: 'الأرشيف',
          subtitle: 'عرض سجل الحجوزات السابقة حسب التاريخ',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BookingsHistoryScreen(clinicId: _clinic!.id),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildControlButton(
          icon: Icons.notifications_active,
          title: 'إرسال إشعارات',
          subtitle: 'إرسال إشعار لجميع مستخدمي التطبيق',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SendClinicNotificationScreen(clinic: _clinic!),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Toggle Active Status
        _buildControlButton(
          icon: _clinic!.isActive
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          title: _clinic!.isActive ? 'إخفاء العيادة' : 'إظهار العيادة',
          subtitle: _clinic!.isActive
              ? 'إخفاء العيادة من التطبيق مؤقتاً'
              : 'إظهار العيادة في التطبيق',
          onTap: () => _toggleClinicActiveStatus(),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _cardColor,
        border: Border.all(color: const Color(0xFFDCE6EF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.15),
                        _secondaryColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleClinicActiveStatus() async {
    final willShow = !_clinic!.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(
              willShow
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: willShow ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(willShow ? 'إظهار العيادة' : 'إخفاء العيادة'),
          ],
        ),
        content: Text(
          willShow
              ? 'هل تريد إظهار العيادة في التطبيق الآن؟'
              : 'هل تريد إخفاء العيادة من التطبيق الآن؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: willShow ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(willShow ? 'إظهار' : 'إخفاء'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
          doctorImageUrl: _clinic!.doctorImageUrl,
          isActive: !_clinic!.isActive,
          createdAt: _clinic!.createdAt,
          ownerId: _clinic!.ownerId,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _clinic!.isActive
                  ? 'تم إظهار العيادة بنجاح'
                  : 'تم إخفاء العيادة بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
