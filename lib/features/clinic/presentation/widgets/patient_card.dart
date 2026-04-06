import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/patient_model.dart';
import '../cubit/patient_cubit.dart';
import '../screens/patient_details_screen.dart';

class PatientCard extends StatelessWidget {
  final PatientModel patient;
  final String clinicId;

  static const Color _primaryColor = Color(0xFF0B8293);

  const PatientCard({super.key, required this.patient, required this.clinicId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDDE7EF)),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<PatientCubit>(),
                child: PatientDetailsScreen(
                  patientId: patient.id,
                  clinicId: clinicId,
                ),
              ),
            ),
          );

          // إعادة تحميل قائمة المرضى عند العودة
          if (result == true && context.mounted) {
            context.read<PatientCubit>().loadClinicPatients(clinicId);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _primaryColor.withOpacity(0.1),
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0] : '؟',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          patient.phoneNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: _primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
