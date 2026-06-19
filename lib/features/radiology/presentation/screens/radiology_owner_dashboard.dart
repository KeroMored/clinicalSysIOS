import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../data/models/radiology_model.dart';
import '../cubit/radiology_cubit.dart';
import '../cubit/radiology_state.dart';
import 'edit_radiology_screen.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class RadiologyOwnerDashboard extends StatefulWidget {
  const RadiologyOwnerDashboard({super.key});

  @override
  State<RadiologyOwnerDashboard> createState() =>
      _RadiologyOwnerDashboardState();
}

class _RadiologyOwnerDashboardState extends State<RadiologyOwnerDashboard> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<RadiologyCubit>().loadRadiologyCenterByOwner(user.email!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'إدارة مركز الأشعة',
        gradient: AppTheme.radiologyGradient,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                context.read<RadiologyCubit>().loadRadiologyCenterByOwner(
                  user.email!,
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: BlocConsumer<RadiologyCubit, RadiologyState>(
          listener: (context, state) {
            if (state is RadiologyActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                context.read<RadiologyCubit>().loadRadiologyCenterByOwner(
                  user.email!,
                );
              }
            } else if (state is RadiologyError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is RadiologyLoading) {
              return const Center(
                child: AppLoadingIndicator(color: AppTheme.secondaryColor),
              );
            }

            if (state is RadiologyError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          context
                              .read<RadiologyCubit>()
                              .loadRadiologyCenterByOwner(user.email!);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is RadiologyCenterDetailLoaded) {
              return _buildDashboardContent(state.radiologyCenter);
            }

            return const Center(child: Text('لم يتم العثور على بيانات المركز'));
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(RadiologyModel radiology) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(radiology),
          const SizedBox(height: 16),
          _buildInfoCard(radiology),
          const SizedBox(height: 16),
          _buildQuickActionsCard(radiology),
          const SizedBox(height: 16),
          _buildStatsCard(radiology),
          const SizedBox(height: 16),
          _buildServicesCard(radiology),
        ],
      ),
    );
  }

  Widget _buildStatusCard(RadiologyModel radiology) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: radiology.isApproved
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                radiology.isApproved ? Icons.check_circle : Icons.pending,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    radiology.isApproved ? 'مركز معتمد' : 'في انتظار الموافقة',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    radiology.isApproved
                        ? 'المركز معتمد ومتاح للمستخدمين'
                        : 'سيتم مراجعة طلبك من قبل الإدارة',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(RadiologyModel radiology) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'معلومات المركز',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () => _navigateToEditScreen(radiology),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(Icons.business, 'اسم المركز', radiology.centerName),
            _buildInfoRow(Icons.person, 'اسم المالك', radiology.ownerName),
            _buildInfoRow(Icons.phone, 'رقم الهاتف', radiology.ownerPhone),
            _buildInfoRow(Icons.location_on, 'العنوان', radiology.address),
            _buildInfoRow(
              Icons.location_city,
              'المدينة',
              '${radiology.city}, ${radiology.governorate}',
            ),
            if (radiology.licenseNumber != null)
              _buildInfoRow(
                Icons.card_membership,
                'رقم الترخيص',
                radiology.licenseNumber!,
              ),
            _buildInfoRow(
              Icons.calendar_today,
              'تاريخ التسجيل',
              DateFormat('yyyy-MM-dd').format(radiology.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(RadiologyModel radiology) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2,
              children: [
                _buildActionButton(
                  icon: Icons.schedule,
                  label: 'مواعيد العمل',
                  color: Colors.blue,
                  onTap: () => _showWorkingHoursDialog(radiology),
                ),
                _buildActionButton(
                  icon: Icons.medical_services,
                  label: 'الخدمات',
                  color: Colors.green,
                  onTap: () => _showServicesDialog(radiology),
                ),
                _buildActionButton(
                  icon: radiology.isActive
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  label: radiology.isActive ? 'إيقاف مؤقت' : 'تفعيل',
                  color: radiology.isActive ? Colors.red : Colors.green,
                  onTap: () => _toggleActiveStatus(radiology),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(RadiologyModel radiology) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.star,
                    label: 'التقييم',
                    value: radiology.rating?.toStringAsFixed(1) ?? 'لا يوجد',
                    color: Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.reviews,
                    label: 'التقييمات',
                    value: '${radiology.reviewCount ?? 0}',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              icon: Icons.medical_services,
              label: 'الخدمات',
              value: '${radiology.services.length}',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(RadiologyModel radiology) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الخدمات المتاحة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                if (radiology.homeVisit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.home, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'زيارة منزلية',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(),
            if (radiology.services.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('لا توجد خدمات مضافة'),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: radiology.services.map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    child: Text(
                      service,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditScreen(RadiologyModel radiology) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRadiologyScreen(radiology: radiology),
      ),
    );

    // Reload data if changes were saved
    if (result == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<RadiologyCubit>().loadRadiologyCenterByOwner(user.email!);
      }
    }
  }

  void _showWorkingHoursDialog(RadiologyModel radiology) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('مواعيد العمل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildWorkingHoursList(radiology),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildWorkingHoursList(RadiologyModel radiology) {
    final daysInArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    return daysInArabic.entries.map((entry) {
      final hours = radiology.workingHours[entry.key];
      return ListTile(
        title: Text(entry.value),
        trailing: Text(
          hours?.isHoliday ?? true
              ? 'مغلق'
              : '${hours!.openTime} - ${hours.closeTime}',
          style: TextStyle(
            color: hours?.isHoliday ?? true ? Colors.red : Colors.green,
          ),
        ),
      );
    }).toList();
  }

  void _showServicesDialog(RadiologyModel radiology) {
    List<String> selectedServices = List.from(radiology.services);
    bool homeVisit = radiology.homeVisit;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إدارة الخدمات'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: const Text('زيارة منزلية'),
                      value: homeVisit,
                      onChanged: (value) {
                        setDialogState(() => homeVisit = value ?? false);
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    const Divider(),
                    const Text(
                      'الخدمات المتاحة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...RadiologyServices.getAllServices().map((service) {
                      return CheckboxListTile(
                        title: Text(service),
                        value: selectedServices.contains(service),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedServices.add(service);
                            } else {
                              selectedServices.remove(service);
                            }
                          });
                        },
                        activeColor: Colors.deepPurple,
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedRadiology = radiology.copyWith(
                      services: selectedServices,
                      homeVisit: homeVisit,
                      updatedAt: DateTime.now(),
                    );
                    context.read<RadiologyCubit>().updateRadiologyCenter(
                      updatedRadiology,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleActiveStatus(RadiologyModel radiology) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            radiology.isActive ? 'إيقاف المركز مؤقتاً' : 'تفعيل المركز',
          ),
          content: Text(
            radiology.isActive
                ? 'هل أنت متأكد من إيقاف المركز مؤقتاً؟ لن يظهر المركز للمستخدمين.'
                : 'هل تريد تفعيل المركز؟ سيظهر المركز للمستخدمين.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<RadiologyCubit>().toggleActiveStatus(
                  radiology.id,
                  !radiology.isActive,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: radiology.isActive ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(radiology.isActive ? 'إيقاف' : 'تفعيل'),
            ),
          ],
        );
      },
    );
  }
}
