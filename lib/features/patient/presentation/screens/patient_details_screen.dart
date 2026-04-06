import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/visit_model.dart';
import '../cubit/visit_cubit.dart';
import 'add_edit_visit_screen.dart';
import 'visit_details_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class PatientDetailsScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailsScreen({Key? key, required this.patient})
    : super(key: key);

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VisitCubit>().loadVisitsByPatient(widget.patient.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.patient.name,
        gradient: AppTheme.clinicGradient,
      ),
      body: Column(
        children: [
          // بطاقة بيانات المريض
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.clinicGradient.scale(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ModernCard(
              child: Column(
                children: [
                  // أيقونة المريض
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.clinicGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // الاسم
                  Text(
                    widget.patient.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // رقم الهاتف
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.patient.phoneNumber,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // تاريخ التسجيل
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'مسجل منذ: ${DateFormat('dd/MM/yyyy', 'ar').format(widget.patient.createdAt)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // عنوان قسم الكشوفات
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.clinicGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'سجل الكشوفات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ),

          // قائمة الكشوفات
          Expanded(
            child: BlocConsumer<VisitCubit, VisitState>(
              listener: (context, state) {
                if (state is VisitActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.read<VisitCubit>().loadVisitsByPatient(
                    widget.patient.id,
                  );
                } else if (state is VisitError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is VisitLoading) {
                  return const Center(child: AppLoadingIndicator());
                } else if (state is VisitLoaded) {
                  if (state.visits.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 100,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'لا توجد كشوفات',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'ابدأ بإضافة كشف جديد',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.visits.length,
                    itemBuilder: (context, index) {
                      final visit = state.visits[index];
                      return _buildVisitCard(visit);
                    },
                  );
                } else if (state is VisitActionLoading) {
                  return const Center(child: AppLoadingIndicator());
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditVisitScreen(patient: widget.patient),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('إضافة كشف'),
      ),
    );
  }

  Widget _buildVisitCard(VisitModel visit) {
    return ModernCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VisitDetailsScreen(visit: visit, patient: widget.patient),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // التاريخ والوقت
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.clinicGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE، dd MMMM yyyy', 'ar').format(visit.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    Text(
                      'الوقت: ${visit.time}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ],
          ),

          const Divider(height: 24),

          // التشخيص
          if (visit.diagnosis.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.medical_services,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visit.diagnosis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // عدد الأدوية
          if (visit.medicines.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.medication,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${visit.medicines.length} دواء',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // صورة الروشتة
          if (visit.prescriptionImageUrl != null &&
              visit.prescriptionImageUrl!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.image, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'يحتوي على صورة روشتة',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
