import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../data/models/clinic_department.dart';
import 'clinics_list_screen.dart';

class ClinicHomePage extends StatelessWidget {
  const ClinicHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),
        appBar: AppBar(
          backgroundColor: Color(0xFF0891B2),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'العيادات الطبية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Header Card
              Container(

                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
              

                ),
                child: Row(
                  children: [
                
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختر التخصص المناسب',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أفضل الأطباء في جميع التخصصات',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                
                  ],
                ),
              ),

              // Departments List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ClinicDepartment.values.length - 1,
                  itemBuilder: (context, index) {
                    final department = ClinicDepartment.values[index];
                    return _buildDepartmentCard(context, department, index);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(BuildContext context, ClinicDepartment department, int index) {
    final icons = {
      ClinicDepartment.pediatrics: MdiIcons.baby,
      ClinicDepartment.dentistry: MdiIcons.toothOutline,
      ClinicDepartment.internalMedicine: MdiIcons.stethoscope,
      ClinicDepartment.dermatology: MdiIcons.faceWoman,
      ClinicDepartment.orthopedics: MdiIcons.bone,
      ClinicDepartment.cardiology: MdiIcons.heartPulse,
      ClinicDepartment.ophthalmology: MdiIcons.eye,
      ClinicDepartment.ent: MdiIcons.earHearing,
      ClinicDepartment.obstetrics: MdiIcons.humanFemale,
      ClinicDepartment.urology: MdiIcons.waterCheck,
      ClinicDepartment.psychiatry: MdiIcons.brain,
      ClinicDepartment.generalSurgery: MdiIcons.hospitalBox,
      ClinicDepartment.physiotherapy: MdiIcons.walk,
      ClinicDepartment.other: MdiIcons.hospital,
    };

    final colors = {
      ClinicDepartment.pediatrics: const Color(0xFFEC4899),
      ClinicDepartment.dentistry: const Color(0xFF3B82F6),
      ClinicDepartment.internalMedicine: const Color(0xFFEF4444),
      ClinicDepartment.dermatology: const Color(0xFFF59E0B),
      ClinicDepartment.orthopedics: const Color(0xFF06B6D4),
      ClinicDepartment.cardiology: const Color(0xFFDC2626),
      ClinicDepartment.ophthalmology: const Color(0xFF8B5CF6),
      ClinicDepartment.ent: const Color(0xFF92400E),
      ClinicDepartment.obstetrics: const Color(0xFFFB7185),
      ClinicDepartment.urology: const Color(0xFF14B8A6),
      ClinicDepartment.psychiatry: const Color(0xFFA855F7),
      ClinicDepartment.generalSurgery: const Color(0xFF10B981),
      ClinicDepartment.physiotherapy: const Color(0xFF84CC16),
      ClinicDepartment.other: const Color(0xFF64748B),
    };

    final icon = icons[department] ?? MdiIcons.hospital;
    final color = colors[department] ?? const Color(0xFF0891B2);

    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ClinicsListScreen(department: department),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.3, 0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon Container with Gradient
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Department Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          department.arabicName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'متاح الآن',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
