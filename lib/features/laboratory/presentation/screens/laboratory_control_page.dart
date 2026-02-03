import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/laboratory_model.dart';
import '../../data/models/lab_booking_model.dart';
import '../cubit/lab_tests_cubit.dart';
import '../cubit/lab_tests_state.dart';
import 'lab_bookings_management_screen.dart';
import 'lab_bookings_history_screen.dart';
import 'edit_laboratory_screen.dart';

/// صفحة التحكم الرئيسية لمعمل التحاليل
class LaboratoryControlPage extends StatefulWidget {
  final LaboratoryModel laboratory;

  const LaboratoryControlPage({Key? key, required this.laboratory})
    : super(key: key);

  @override
  State<LaboratoryControlPage> createState() => _LaboratoryControlPageState();
}

class _LaboratoryControlPageState extends State<LaboratoryControlPage> {
  late LabTestsCubit _cubit;
  Map<String, dynamic>? _stats;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _cubit = LabTestsCubit();
    _loadStatistics();
    _subscribeToNotifications();
  }

  Future<void> _subscribeToNotifications() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      await _notificationService.subscribeToLabTopic(
        widget.laboratory.id,
        authState.user.uid,
      );
    }
  }

  Future<void> _loadStatistics() async {
    await _cubit.loadStatistics(widget.laboratory.id);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // App Bar مع Gradient - تصميم محسن
            SliverAppBar(
              title: Text(
                widget.laboratory.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              floating: true,
              snap: true,
              elevation: 2,
              backgroundColor: const Color(0xFF00BCD4),
              iconTheme: const IconThemeData(color: Colors.white),
            ),

            // المحتوى
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Statistics Dashboard
                  _buildStatisticsSection(),
                  const SizedBox(height: 20),

                  // Quick Actions
                  _buildQuickActionsSection(),
                  const SizedBox(height: 20),

                  // Recent Activity
                  _buildRecentActivitySection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// قسم الإحصائيات
  Widget _buildStatisticsSection() {
    return BlocBuilder<LabTestsCubit, LabTestsState>(
      builder: (context, state) {
        if (state is StatisticsLoaded) {
          _stats = state.stats;
        }

        if (_stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات المعمل',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.event_note,
                    title: 'الحجوزات اليوم',
                    value: '${_stats!['todayBookings'] ?? 0}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_month,
                    title: 'الشهر الحالي',
                    value: '${_stats!['monthBookings'] ?? 0}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// قسم الإجراءات السريعة
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإجراءات السريعة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              icon: Icons.calendar_today,
              title: 'إدارة الحجوزات',
              gradient: AppTheme.laboratoryGradient,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LabBookingsManagementScreen(
                      laboratory: widget.laboratory,
                    ),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.archive,
              title: 'الأرشيف',
              gradient: AppTheme.primaryGradient,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LabBookingsHistoryScreen(
                      laboratoryId: widget.laboratory.id,
                    ),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.edit,
              title: 'تعديل بيانات المعمل',
              gradient: LinearGradient(
                colors: [Colors.orange[600]!, Colors.orange[400]!],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditLaboratoryScreen(laboratory: widget.laboratory),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// قسم النشاطات الأخيرة
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'النشاطات الأخيرة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LabBookingsManagementScreen(
                      laboratory: widget.laboratory,
                    ),
                  ),
                );
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lab_bookings')
              .where('laboratoryId', isEqualTo: widget.laboratory.id)
              .where('archivedDate', isNull: true)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ModernCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('حدث خطأ: ${snapshot.error}'),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد حجوزات حديثة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final bookings = snapshot.data!.docs
                .map((doc) => LabBookingModel.fromFirestore(doc))
                .toList();

            return ModernCard(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final isPending = booking.status == LabBookingStatus.pending;
                  final isConfirmed =
                      booking.status == LabBookingStatus.confirmed;

                  Color statusColor = isPending
                      ? Colors.orange
                      : isConfirmed
                      ? Colors.green
                      : Colors.grey;

                  IconData statusIcon = isPending
                      ? Icons.pending_rounded
                      : isConfirmed
                      ? Icons.check_circle_rounded
                      : Icons.task_alt_rounded;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Text(
                      booking.patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (booking.testType != null &&
                            booking.testType!.isNotEmpty)
                          Text(
                            booking.testType!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        Text(
                          DateFormat(
                            'd MMM yyyy - h:mm a',
                            'ar',
                          ).format(booking.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${booking.bookingNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
