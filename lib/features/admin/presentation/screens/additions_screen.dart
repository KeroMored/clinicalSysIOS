import 'package:flutter/material.dart';
import 'add_clinic_screen.dart';
import 'add_pharmacy_screen.dart';
import 'add_laboratory_screen.dart';
// import 'add_nurse_screen.dart';  // 🚫 تم تعطيل إضافة ممرض مؤقتاً
import 'add_delivery_screen.dart';
import 'add_rehabilitation_center_screen.dart';
import '../../../radiology/presentation/screens/add_radiology_screen.dart';
import '../../../gym/presentation/pages/add_gym_screen.dart';
import '../../../medical_supply/presentation/screens/add_medical_supply_screen.dart';

class AdditionsScreen extends StatelessWidget {
  const AdditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'الإضافات',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إضافة خدمة جديدة',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اختر نوع الخدمة التي تريد إضافتها',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Medical Services Section
                const Text(
                  'الخدمات الطبية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),

                // Clinic Card
                _buildServiceCard(
                  context,
                  icon: Icons.local_hospital_rounded,
                  title: 'إضافة عيادة',
                  subtitle: 'أضف عيادة طبية جديدة',
                  color: const Color(0xFF0891B2),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddClinicScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                // Pharmacy Card
                _buildServiceCard(
                  context,
                  icon: Icons.medication_rounded,
                  title: 'إضافة صيدلية',
                  subtitle: 'أضف صيدلية جديدة',
                  color: const Color(0xFF06B6D4),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddPharmacyScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Laboratory Card
                _buildServiceCard(
                  context,
                  icon: Icons.science_rounded,
                  title: 'إضافة معمل تحاليل',
                  subtitle: 'أضف معمل تحاليل طبية',
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddLaboratoryScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Radiology Card
                _buildServiceCard(
                  context,
                  icon: Icons.medical_services_rounded,
                  title: 'إضافة مركز أشعة',
                  subtitle: 'أضف مركز أشعة طبية',
                  color: const Color(0xFFEF4444),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddRadiologyScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // HR Services Section
                const Text(
                  'الموارد البشرية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),

                // 🚫 Nurse Card - Commented Out
                // _buildServiceCard(
                //   context,
                //   icon: Icons.medical_information_rounded,
                //   title: 'إضافة ممرض',
                //   subtitle: 'أضف ممرض أو ممرضة',
                //   color: const Color(0xFF14B8A6),
                //   onTap: () => Navigator.push(
                //     context,
                //     MaterialPageRoute(builder: (_) => const AddNurseScreen()),
                //   ),
                // ),
                // const SizedBox(height: 12),

                // Delivery Card
                _buildServiceCard(
                  context,
                  icon: Icons.delivery_dining_rounded,
                  title: 'إضافة ديليفري',
                  subtitle: 'أضف خدمة توصيل طبي',
                  color: const Color(0xFF3B82F6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddDeliveryScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Specialized Services Section
                const Text(
                  'الخدمات المتخصصة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),

                // Rehabilitation Card
                _buildServiceCard(
                  context,
                  icon: Icons.healing_rounded,
                  title: 'إضافة مركز تأهيل',
                  subtitle: 'أضف مركز تأهيل وعلاج طبيعي',
                  color: const Color(0xFFA855F7),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddRehabilitationCenterScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Gym Card
                _buildServiceCard(
                  context,
                  icon: Icons.fitness_center_rounded,
                  title: 'إضافة جيم',
                  subtitle: 'أضف صالة رياضية',
                  color: const Color(0xFFF97316),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddGymScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                // Medical Supplies Card
                _buildServiceCard(
                  context,
                  icon: Icons.medical_services_rounded,
                  title: 'إضافة مكان مستلزمات طبية',
                  subtitle: 'أضف متجر مستلزمات طبية',
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddMedicalSupplyScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
