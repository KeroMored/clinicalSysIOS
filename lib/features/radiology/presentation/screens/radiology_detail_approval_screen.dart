import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/radiology_model.dart';
import '../cubit/radiology_cubit.dart';
import '../cubit/radiology_state.dart';
import '../widgets/widgets.dart';

class RadiologyDetailApprovalScreen extends StatelessWidget {
  final RadiologyModel radiology;

  const RadiologyDetailApprovalScreen({super.key, required this.radiology});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل مركز الأشعة'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<RadiologyCubit, RadiologyState>(
        listener: (context, state) {
          if (state is RadiologyActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else if (state is RadiologyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadiologyStatusCard(radiology: radiology),
              const SizedBox(height: 16),
              RadiologyBasicInfoCard(radiology: radiology),
              const SizedBox(height: 16),
              RadiologyLocationCard(radiology: radiology),
              const SizedBox(height: 16),
              RadiologyServicesCard(radiology: radiology),
              const SizedBox(height: 16),
              RadiologyWorkingHoursCard(radiology: radiology),
              const SizedBox(height: 16),
              RadiologyLicenseCard(radiology: radiology),
              const SizedBox(height: 16),
              if (!radiology.isApproved) RadiologyApprovalButtons(radiology: radiology),
            ],
          ),
        ),
      ),
    );
  }
}
