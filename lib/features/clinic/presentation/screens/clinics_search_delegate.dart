import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/models/clinic_department.dart';
import '../../data/models/clinic_model.dart';
import 'clinic_details_screen.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class ClinicsSearchDelegate extends SearchDelegate<void> {
  final ClinicDepartment? department;

  ClinicsSearchDelegate({this.department});

  @override
  String get searchFieldLabel => department == null
      ? 'ابحث باسم الدكتور في كل العيادات'
      : 'ابحث باسم الدكتور داخل ${department!.arabicName}';

  @override
  TextStyle? get searchFieldStyle =>
      const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
          tooltip: 'مسح',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => close(context, null),
      tooltip: 'رجوع',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchBody(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchBody(context);
  }

  Widget _buildSearchBody(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Text(
          department == null
              ? 'اكتب اسم الدكتور للبحث في جميع العيادات'
              : 'اكتب اسم الدكتور للبحث داخل ${department!.arabicName}',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FutureBuilder<List<ClinicModel>>(
      future: _searchClinics(query.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ أثناء البحث',
              style: TextStyle(color: Colors.red[700]),
            ),
          );
        }

        final clinics = snapshot.data ?? [];
        if (clinics.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد نتائج مطابقة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: clinics.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final clinic = clinics[index];
            return Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0891B2).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Color(0xFF0891B2),
                  ),
                ),
                title: Text(
                  'د. ${clinic.doctorName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  clinic.department.arabicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClinicDetailsScreen(clinic: clinic),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<ClinicModel>> _searchClinics(String value) async {
    Query queryRef = FirebaseFirestore.instance
        .collection('clinics')
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true);

    if (department != null) {
      queryRef = queryRef.where('department', isEqualTo: department!.name);
    }

    final snapshot = await queryRef
        .orderBy('doctorName')
        .startAt([value])
        .endAt(['$value\uf8ff'])
        .limit(40)
        .get();

    return snapshot.docs.map((doc) => ClinicModel.fromFirestore(doc)).toList();
  }
}
