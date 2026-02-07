import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/widgets/login_required_dialog.dart';
import '../../data/repositories/medicine_repository.dart';
import '../cubit/medicine_cubit.dart';
import '../cubit/medicine_state.dart';
import '../widgets/medicine_card.dart';
import 'add_medicine_screen.dart';
import 'edit_medicine_screen.dart';

class MedicinesScreen extends StatelessWidget {
  const MedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is logged in
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LoginRequiredDialog.show(context).then((_) {
          // After dialog is closed, go back
          Navigator.of(context).pop();
        });
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (context) => MedicineCubit(MedicineRepository())..loadUserMedicines(user.uid),
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'مواعيد الأدوية',
          gradient: const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
          ),
        ),
        body: BlocConsumer<MedicineCubit, MedicineState>(
          listener: (context, state) {
            if (state is MedicineAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              // Reload medicines
              context.read<MedicineCubit>().loadUserMedicines(user.uid);
            } else if (state is MedicineUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.blue,
                ),
              );
              // Reload medicines
              context.read<MedicineCubit>().loadUserMedicines(user.uid);
            } else if (state is MedicineDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.orange,
                ),
              );
              // Reload medicines after deletion
              context.read<MedicineCubit>().loadUserMedicines(user.uid);
            } else if (state is MedicineError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is MedicineLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MedicinesLoaded) {
              if (state.medicines.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: state.medicines.length,
                itemBuilder: (context, index) {
                  final medicine = state.medicines[index];
                  return MedicineCard(
                    medicine: medicine,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<MedicineCubit>(),
                            child: EditMedicineScreen(medicine: medicine),
                          ),
                        ),
                      );
                    },
                    onToggle: () {
                      context.read<MedicineCubit>().toggleMedicineStatus(
                            medicine.id,
                            !medicine.isActive,
                            user.uid,
                          );
                    },
                    onDelete: () {
                      _showDeleteDialog(context, medicine.id, user.uid);
                    },
                  );
                },
              );
            }

            // Initial or error state
            return _buildEmptyState(context);
          },
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<MedicineCubit>(),
                    child: const AddMedicineScreen(),
                  ),
                ),
              );
            },
            elevation: 0,
            backgroundColor: Colors.transparent,
            icon: const Icon(Icons.add_circle, size: 26),
            label: const Text(
              'إضافة موعد جديد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.medication,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ابدأ بإضافة أدويتك',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A5F),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String medicineId, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الدواء؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<MedicineCubit>().deleteMedicine(medicineId, userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
