import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/gym_model.dart';
import '../cubit/gym_cubit.dart';
import '../cubit/gym_state.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class GymApprovalListScreen extends StatefulWidget {
  const GymApprovalListScreen({super.key});

  @override
  State<GymApprovalListScreen> createState() => _GymApprovalListScreenState();
}

class _GymApprovalListScreenState extends State<GymApprovalListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GymCubit>().loadPendingGyms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GradientAppBar(
        title: 'الموافقة على الجيمات',
        gradient: AppTheme.gymGradient,
      ),
      body: BlocConsumer<GymCubit, GymState>(
        listener: (context, state) {
          if (state is GymApproved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تمت الموافقة على الجيم بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is GymDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم رفض الجيم'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (state is GymError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GymLoading) {
            return Center(
              child: AppLoadingIndicator(color: AppTheme.gymGradient.colors[0]),
            );
          }

          if (state is GymError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            );
          }

          final gyms = state is GymPendingLoaded ? state.gyms : [];

          if (gyms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد جيمات معلقة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'جميع الجيمات تمت الموافقة عليها',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.gymGradient.colors[0],
            onRefresh: () async {
              context.read<GymCubit>().loadPendingGyms();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: gyms.length,
              itemBuilder: (context, index) {
                final gym = gyms[index];
                return _buildGymCard(context, gym);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGymCard(BuildContext context, GymModel gym) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.gymGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gym.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${gym.city}, ${gym.governorate}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gender Sections
                Row(
                  children: [
                    if (gym.hasMaleSection)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.male_rounded,
                              size: 16,
                              color: Color(0xFF3B82F6),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'رجالي',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (gym.hasMaleSection && gym.hasFemaleSection)
                      const SizedBox(width: 8),
                    if (gym.hasFemaleSection)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFFEC4899,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.female_rounded,
                              size: 16,
                              color: Color(0xFFEC4899),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'نسائي',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFEC4899),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Description
                Text(
                  gym.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Contact Info
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      gym.phone,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      gym.ownerName,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        text: 'الموافقة',
                        icon: Icons.check_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        onPressed: () {
                          _showApprovalDialog(context, gym);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showRejectDialog(context, gym);
                        },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('رفض'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, GymModel gym) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text('هل أنت متأكد من الموافقة على جيم "${gym.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<GymCubit>().approveGym(gym.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, GymModel gym) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الرفض'),
        content: Text('هل أنت متأكد من رفض جيم "${gym.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<GymCubit>().deleteGym(gym.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}
