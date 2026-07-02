import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/login_required_dialog.dart';
import '../../data/models/medicine_model.dart';
import '../../data/repositories/medicine_repository.dart';
import '../cubit/medicine_cubit.dart';
import '../cubit/medicine_state.dart';
import '../widgets/medicine_card.dart';
import 'add_medicine_screen.dart';
import 'edit_medicine_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class MedicinesScreen extends StatelessWidget {
  const MedicinesScreen({super.key});

  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0FA8BC);
  static const Color _titleColor = Color(0xFF1E3A5F);

  static const LinearGradient _screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5FAF9), Color(0xFFEDF4F3)],
  );

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
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    return BlocProvider(
      create: (context) =>
          MedicineCubit(MedicineRepository())..loadUserMedicines(user.uid),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'مواعيد الأدوية',
            style: TextStyle(
              color: _titleColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: _screenGradient),
          child: BlocConsumer<MedicineCubit, MedicineState>(
            listener: (context, state) {
              if (state is MedicineAdded) {
                _showMessage(context, state.message, const Color(0xFF10B981));
              } else if (state is MedicineUpdated) {
                _showMessage(context, state.message, const Color(0xFF0EA5E9));
              } else if (state is MedicineDeleted) {
                _showMessage(context, state.message, const Color(0xFFF59E0B));
              } else if (state is MedicineError) {
                _showMessage(context, state.message, const Color(0xFFEF4444));
              }
            },
            builder: (context, state) {
              if (state is MedicineLoading) {
                return const Center(child: AppLoadingIndicator());
              }

              if (state is MedicinesLoaded) {
                return _buildLoadedState(context, state.medicines, user.uid);
              }

              return _buildEmptyState(context);
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryColor, _primaryDark],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _openAddScreen(context),
            elevation: 0,
            backgroundColor: Colors.transparent,
            icon: const Icon(Icons.add_circle_rounded, size: 19),
            label: const Text(
              'إضافة موعد جديد',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    List<MedicineModel> medicines,
    String userId,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: _buildSummaryCard(medicines),
        ),
        Expanded(
          child: medicines.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
                  itemCount: medicines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];
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
                          userId,
                        );
                      },
                      onDelete: () =>
                          _showDeleteDialog(context, medicine.id, userId),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(List<MedicineModel> medicines) {
    final activeCount = medicines.where((item) => item.isActive).length;
    final stoppedCount = medicines.length - activeCount;
    final remindersCount = medicines.fold<int>(
      0,
      (sum, item) => sum + item.reminderTimes.length,
    );
    final nextReminder = _resolveNextReminder(medicines);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.alarm_on_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ملخص المواعيد',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
              ),
              Text(
                'إجمالي: ${medicines.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                label: 'نشط',
                value: activeCount.toString(),
                color: const Color(0xFF10B981),
              ),
              _buildMetricChip(
                label: 'متوقف',
                value: stoppedCount.toString(),
                color: const Color(0xFF94A3B8),
              ),
              _buildMetricChip(
                label: 'تنبيهات يومية',
                value: remindersCount.toString(),
                color: _primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: _primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nextReminder,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryColor, _primaryDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medication_liquid_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مواعيد أدوية بعد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف موعدك الأول وسيتم تنبيهك تلقائياً في الوقت المحدد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openAddScreen(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'إضافة أول موعد',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveNextReminder(List<MedicineModel> medicines) {
    final activeMedicines = medicines.where((item) => item.isActive);
    DateTime? closest;

    for (final medicine in activeMedicines) {
      final next = medicine.getNextReminderTime();
      if (next == null) continue;
      if (closest == null || next.isBefore(closest)) {
        closest = next;
      }
    }

    if (closest == null) {
      return 'لا توجد مواعيد قادمة حالياً';
    }

    final now = DateTime.now();
    final diff = closest.difference(now);
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes.clamp(1, 59);
      return 'أقرب تنبيه بعد $minutes دقيقة';
    }

    if (diff.inHours < 24) {
      return 'أقرب تنبيه بعد ${diff.inHours} ساعة';
    }

    return 'أقرب تنبيه خلال ${diff.inDays} يوم';
  }

  void _showMessage(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<MedicineCubit>(),
          child: const AddMedicineScreen(),
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String medicineId,
    String userId,
  ) {
    final medicineCubit = context.read<MedicineCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'هل تريد حذف هذا الموعد؟',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              medicineCubit.deleteMedicine(medicineId, userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('حذف', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
