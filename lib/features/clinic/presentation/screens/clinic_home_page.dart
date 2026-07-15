import 'package:flutter/material.dart';

import '../../data/models/clinic_department.dart';
import 'clinics_search_delegate.dart';
import 'clinics_list_screen.dart';

class ClinicHomePage extends StatelessWidget {
  const ClinicHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF0B8293),
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'العيادات الطبيه',
            style: TextStyle(
              color: Color(0xFF0B8293),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      showSearch(
                        context: context,
                        delegate: ClinicsSearchDelegate(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ابحث عن تخصص...',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'التخصصات الطبيه',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ClinicDepartment.values.length - 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 120,
                  ),
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

  Widget _buildDepartmentCard(
    BuildContext context,
    ClinicDepartment department,
    int index,
  ) {
    final icons = {
      ClinicDepartment.pediatrics: Icons.child_care,
      ClinicDepartment.dentistry: Icons.health_and_safety,
      ClinicDepartment.internalMedicine: Icons.health_and_safety,
      ClinicDepartment.dermatology: Icons.face,
      ClinicDepartment.orthopedics: Icons.healing,
      ClinicDepartment.cardiology: Icons.favorite,
      ClinicDepartment.ophthalmology: Icons.visibility,
      ClinicDepartment.ent: Icons.hearing,
      ClinicDepartment.obstetrics: Icons.pregnant_woman,
      ClinicDepartment.urology: Icons.water_drop,
      ClinicDepartment.psychiatry: Icons.psychology,
      ClinicDepartment.generalSurgery: Icons.local_hospital,
      ClinicDepartment.physiotherapy: Icons.directions_walk,
      ClinicDepartment.other: Icons.local_hospital,
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

    final icon = icons[department] ?? Icons.local_hospital;
    final color = colors[department] ?? const Color(0xFF0891B2);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.merge(
          (index % 2 == 0)
              ? Border(left: BorderSide(color: color, width: 0.5))
              : Border(right: BorderSide(color: color, width: 0.5)),

          Border(bottom: BorderSide(color: color, width: 1.5)),
        ),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClinicsListScreen(department: department),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  department.arabicName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                // const SizedBox(height: 2),
                // Text(
                //   'متاح',
                //   style: TextStyle(
                //     fontSize: 11,
                //     fontWeight: FontWeight.w600,
                //     color: Colors.grey[500],
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
