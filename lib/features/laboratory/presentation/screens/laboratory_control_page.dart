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
import 'lab_bookings_management_screen.dart';
import 'lab_bookings_history_screen.dart';
import 'edit_laboratory_screen.dart';
import 'send_lab_notification_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

/// صفحة التحكم الرئيسية لمعمل التحاليل
class LaboratoryControlPage extends StatefulWidget {
  final LaboratoryModel laboratory;

  const LaboratoryControlPage({Key? key, required this.laboratory})
    : super(key: key);

  @override
  State<LaboratoryControlPage> createState() => _LaboratoryControlPageState();
}

class _LaboratoryControlPageState extends State<LaboratoryControlPage> {
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _surfaceColor = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);

  late LabTestsCubit _cubit;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _cubit = LabTestsCubit();
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
        backgroundColor: _surfaceColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              elevation: 0,
              title: Text(
                widget.laboratory.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              centerTitle: true,
              backgroundColor: _primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'إدارة المعمل اليومية',
                        style: TextStyle(
                          color: Color(0xFFE2F7FB),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 16),

                  _buildRecentActivitySection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// شبكة الإجراءات (بدون عنوان)
  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _buildActionCard(
          icon: Icons.calendar_today,
          title: 'إدارة الحجوزات',
          gradient: AppTheme.laboratoryGradient,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LabBookingsManagementScreen(laboratory: widget.laboratory),
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
          icon: Icons.notifications_active,
          title: 'إرسال إشعارات',
          gradient: LinearGradient(
            colors: [Colors.purple[600]!, Colors.purple[400]!],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SendLabNotificationScreen(laboratory: widget.laboratory),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.24),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
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
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                    child: AppLoadingIndicator(),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (booking.testTypes.isNotEmpty)
                          Text(
                            booking.testTypes.join('، '),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
