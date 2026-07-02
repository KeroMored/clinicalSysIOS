import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'approve_pharmacies_screen.dart';
import 'clinic_approval_screen.dart';
import 'add_clinic_screen.dart';
import 'add_pharmacy_screen.dart';
import 'add_laboratory_screen.dart';
import 'laboratory_approval_screen.dart';
import 'nurse_approval_screen.dart';
import 'add_delivery_screen.dart';
import 'delivery_approval_screen.dart';
import 'add_rehabilitation_center_screen.dart';
import 'rehabilitation_approval_screen.dart';
import 'send_admin_notification_screen.dart';
import 'admin_medicine_requests_screen.dart';
import '../../../radiology/presentation/screens/add_radiology_screen.dart';
import '../../../radiology/presentation/screens/radiology_approval_list_screen.dart';
import '../../../gym/presentation/pages/add_gym_screen.dart';
import '../../../gym/presentation/pages/gym_approval_screen.dart';
import '../../../gym/presentation/cubit/gym_cubit.dart';
import '../../../gym/data/repositories/gym_repository.dart';
import '../../../subscriptions/presentation/screens/subscriptions_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/screens/reports_admin_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const GradientAppBar(
          title: 'إدارة الأدمن',
          gradient: AppTheme.accentGradient,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.backgroundColor, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً بك',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'لوحة التحكم الإدارية',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Approvals Section
                Text(
                  'الموافقات',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
                const SizedBox(height: 16),

                // First Row - Clinics and Pharmacies
                Row(
                  children: [
                    Expanded(
                      child: _buildModernAdminCard(
                        context,
                        icon: Icons.local_hospital,
                        title: 'الموافقة على العيادات',
                        gradient: AppTheme.clinicGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClinicApprovalScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernAdminCard(
                        context,
                        icon: Icons.medication,
                        title: 'الموافقة على الصيدليات',
                        gradient: AppTheme.pharmacyGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ApprovePharmaciesScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Second Row - Laboratories and Radiology
                Row(
                  children: [
                    Expanded(
                      child: _buildModernAdminCard(
                        context,
                        icon: Icons.science,
                        title: 'الموافقة على المعامل',
                        gradient: AppTheme.laboratoryGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LaboratoryApprovalScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernAdminCard(
                        context,
                        icon: Icons.local_hospital_rounded,
                        title: 'الموافقة على مراكز الأشعة',
                        gradient: AppTheme.radiologyGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RadiologyApprovalListScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Third Row - Nursing and Delivery
                Row(
                  children: [
                    Expanded(
                      child: _buildModernAdminCard(
                        context,
                        icon: Icons.medical_services,
                        title: 'الموافقة على الممرضين',
                        gradient: AppTheme.nursingGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NurseApprovalScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernAdminCard(
                        context,
                        icon: Icons.local_shipping,
                        title: 'الموافقة على الديليفري',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeliveryApprovalScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fourth Row - Rehabilitation and Gym
                Row(
                  children: [
                    Expanded(
                      child: _buildModernAdminCard(
                        context,
                        icon: Icons.healing,
                        title: 'الموافقة على مراكز التأهيل',
                        gradient: AppTheme.rehabilitationGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RehabilitationApprovalScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernAdminCard(
                        context,
                        icon: Icons.fitness_center_rounded,
                        title: 'الموافقة على الجيمات',
                        gradient: AppTheme.gymGradient,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GymApprovalScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Broadcast Notifications Section
                Text(
                  'الإشعارات العامة',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SendAdminNotificationScreen(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إرسال إشعار لكل المستخدمين',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'تنبيه عام باسم التطبيق مع خيار فتح المتجر',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // زرار طلبات الأدوية (يظهر فقط للأدمن kerolesmored@gmail.com)
                Builder(
                  builder: (context) {
                    final authState = context.watch<AuthCubit>().state;
                    final userEmail = authState is Authenticated
                        ? authState.user.email
                        : '';

                    // يظهر فقط للأدمن المحدد
                    if (userEmail != 'kerolesmored@gmail.com') {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminMedicineRequestsScreen(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0B8293), Color(0xFF0A6F7C)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0B8293,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.medical_services_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'طلبات الأدوية',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'عرض ومتابعة طلبات الأدوية من المستخدمين',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Reports Management Section
                Text(
                  'إدارة البلاغات',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Reports Admin Button
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportsAdminScreen(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إدارة البلاغات والشكاوى',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'عرض ومتابعة جميع البلاغات',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Subscriptions Management Section
                Text(
                  'إدارة الاشتراكات',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Subscriptions Management Button
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionsScreen(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payment_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إدارة اشتراكات الأماكن',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'تسجيل المدفوعات ومتابعة الاشتراكات',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Add Services Section
                Text(
                  'إضافة خدمات جديدة',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Add Services Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildAddServiceCard(
                      context,
                      icon: Icons.local_hospital,
                      title: 'إضافة عيادة',
                      gradient: AppTheme.clinicGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddClinicScreen(),
                        ),
                      ),
                    ),
                    _buildAddServiceCard(
                      context,
                      icon: Icons.medication,
                      title: 'إضافة صيدلية',
                      gradient: AppTheme.pharmacyGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddPharmacyScreen(),
                        ),
                      ),
                    ),
                    _buildAddServiceCard(
                      context,
                      icon: Icons.science,
                      title: 'إضافة معمل',
                      gradient: AppTheme.laboratoryGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddLaboratoryScreen(),
                        ),
                      ),
                    ),
                    _buildAddServiceCard(
                      context,
                      icon: Icons.local_hospital_rounded,
                      title: 'إضافة مركز أشعة',
                      gradient: AppTheme.radiologyGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddRadiologyScreen(),
                        ),
                      ),
                    ),
                    // _buildAddServiceCard(
                    //   context,
                    //   icon: FontAwesomeIcons.userNurse,
                    //   title: 'إضافة ممرض',
                    //   gradient: AppTheme.nursingGradient,
                    //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNurseScreen())),
                    // ),
                    _buildAddServiceCard(
                      context,
                      icon: Icons.local_shipping,
                      title: 'إضافة ديليفري',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddDeliveryScreen(),
                        ),
                      ),
                    ),
                    _buildAddServiceCard(
                      context,
                      icon: Icons.healing,
                      title: 'إضافة مركز تأهيل',
                      gradient: AppTheme.rehabilitationGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddRehabilitationCenterScreen(),
                        ),
                      ),
                    ),
                    _buildAddServiceCard(
                      context,
                      icon: Icons.fitness_center_rounded,
                      title: 'إضافة جيم',
                      gradient: AppTheme.gymGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (context) => GymCubit(GymRepository()),
                              child: const AddGymScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
    int? pendingCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (pendingCount != null && pendingCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  child: Text(
                    '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
