import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/patient_model.dart';
import '../cubit/patient_cubit.dart';
import '../cubit/patient_state.dart';
import '../widgets/visit_card.dart';
import 'add_visit_screen.dart';
import 'add_patient_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;
  final String clinicId;

  const PatientDetailsScreen({
    super.key,
    required this.patientId,
    required this.clinicId,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    context.read<PatientCubit>().loadPatientDetails(widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop || !context.mounted) {
          return;
        }

        context.read<PatientCubit>().restoreClinicPatientsFromCache(
          widget.clinicId,
        );
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _backgroundColor,
          body: BlocConsumer<PatientCubit, PatientState>(
            listener: (context, state) {
              if (state is PatientActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                context.read<PatientCubit>().loadPatientDetails(
                  widget.patientId,
                );
              } else if (state is PatientError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is PatientLoading) {
                return const Center(
                  child: AppLoadingIndicator(color: _primaryColor),
                );
              }

              if (state is PatientDetailsLoaded) {
                return _buildContent(
                  state.patient,
                  state.visits,
                  state.visitsCount,
                );
              }

              return const Center(
                child: Text(
                  'فشل في تحميل البيانات',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PatientModel patient, List visits, int visitsCount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEAF7FB), Color(0xFFF4FAFD), Color(0xFFF8FCFE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            children: [
              _buildAppBar(patient),
              const SizedBox(height: 14),
              _buildPatientInfo(patient, visitsCount),
              const SizedBox(height: 16),
              _buildVisitsList(visits),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(PatientModel patient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFE9F6FA),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _primaryColor,
                  size: 18,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'تفاصيل المريض',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF334155)),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _editPatient(patient);
              } else if (value == 'delete') {
                _deletePatient(patient.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('تعديل البيانات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('حذف المريض', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(PatientModel patient, int visitsCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7EAF3)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0] : 'م',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ملف المريض',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildContactButton(
                icon: Icons.phone_rounded,
                color: const Color(0xFF2563EB),
                onTap: () => _makePhoneCall(patient.phoneNumber),
              ),
              const SizedBox(width: 6),
              _buildContactButton(
                icon: MdiIcons.whatsapp,
                color: const Color(0xFF16A34A),
                onTap: () => _openWhatsApp(
                  patient.whatsappNumber ?? patient.phoneNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE7EF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.call_rounded,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    patient.phoneNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                ),
                Container(width: 1, height: 16, color: const Color(0xFFD1DCE5)),
                const SizedBox(width: 8),
                const Icon(
                  Icons.medical_services_rounded,
                  size: 16,
                  color: _primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '$visitsCount كشف',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsList(List visits) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDEAF2)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل الكشوفات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: context.read<PatientCubit>(),
                              child: AddVisitScreen(
                                patientId: widget.patientId,
                                clinicId: widget.clinicId,
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'إضافة كشف',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          visits.isEmpty
              ? _buildEmptyVisits()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    final visit = visits[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: VisitCard(
                        visit: visit,
                        onLongPress: () => _confirmDeleteVisit(visit.id),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEmptyVisits() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.16),
                  _secondaryColor.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.medical_information_outlined,
              size: 40,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد كشوفات مسجلة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ بإضافة أول كشف للمريض',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  void _editPatient(PatientModel patient) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<PatientCubit>(),
          child: AddPatientScreen(clinicId: widget.clinicId, patient: patient),
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<PatientCubit>().loadPatientDetails(widget.patientId);
    }
  }

  void _deletePatient(String patientId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من حذف هذا المريض؟\nسيتم حذف جميع كشوفاته أيضاً',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<PatientCubit>().deletePatient(patientId);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVisit(String visitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الكشف'),
        content: const Text(
          'هل تريد حذف هذا الكشف؟ لا يمكن التراجع بعد الحذف.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<PatientCubit>().deleteVisit(visitId);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatWhatsAppNumber(String phoneNumber) {
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = phoneNumber.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return '20$n';
    // ضيف +20 قدام الرقم
    return '20$n';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في فتح تطبيق الهاتف')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final String formattedNumber = _formatWhatsAppNumber(phoneNumber);
    final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNumber');
    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل في فتح واتساب')));
      }
    }
  }
}
