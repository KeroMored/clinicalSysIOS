import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/laboratory_model.dart';
import '../cubit/lab_tests_cubit.dart';
import 'lab_bookings_management_screen.dart';
import 'lab_bookings_history_screen.dart';
import 'edit_laboratory_screen.dart';
import 'send_lab_notification_screen.dart';

/// صفحة التحكم الرئيسية لمعمل التحاليل
class LaboratoryControlPage extends StatefulWidget {
  final LaboratoryModel laboratory;

  const LaboratoryControlPage({Key? key, required this.laboratory})
    : super(key: key);

  @override
  State<LaboratoryControlPage> createState() => _LaboratoryControlPageState();
}

class _LaboratoryControlPageState extends State<LaboratoryControlPage> {
  // Theme colors aligned with clinic control page
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [_primaryColor, _secondaryColor],
  );

  late LabTestsCubit _cubit;
  final NotificationService _notificationService = NotificationService();
  int _offersCount = 0;

  @override
  void initState() {
    super.initState();
    _cubit = LabTestsCubit();
    _subscribeToNotifications();
    _loadOffersCount();
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

  Future<void> _loadOffersCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('laboratory_offers')
          .where('laboratoryId', isEqualTo: widget.laboratory.id)
          .where('isActive', isEqualTo: true)
          .get();

      if (mounted) {
        setState(() {
          _offersCount = snapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading offers count: $e');
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider.value(
        value: _cubit,
        child: Scaffold(
          backgroundColor: _backgroundColor,
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Premium App Bar
              _buildAppBar(),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderSummaryCard(),
                      const SizedBox(height: 20),
                      
                      // Statistics
                      const Text(
                        'الإحصائيات',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.remove_red_eye_rounded,
                              title: 'المشاهدات',
                              value: '0',
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.star_rounded,
                              title: 'التقييم',
                              value: widget.laboratory.averageRating.toStringAsFixed(1),
                              color: const Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.local_offer_rounded,
                              title: 'العروض',
                              value: '$_offersCount',
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.favorite_rounded,
                              title: 'الإعجابات',
                              value: '${widget.laboratory.totalLikes}',
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      
                      const Text(
                        'إجراءات الإدارة',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: false,
      pinned: true,
      toolbarHeight: 62,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textPrimary,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'إدارة المعمل',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: _textPrimary,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _loadOffersCount();
            });
          },
          tooltip: 'تحديث',
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildHeaderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.24),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.science_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.laboratory.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'إدارة الحجوزات والإشعارات من مكان واحد',
                  style: TextStyle(
                    color: Color(0xFFE7F6FA),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Manage Bookings Button
        _buildControlButton(
          icon: Icons.calendar_month_rounded,
          title: 'إدارة الحجوزات',
          subtitle: 'عرض وتأكيد الحجوزات الأونلاين',
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
        const SizedBox(height: 16),

        // Bookings History
        _buildControlButton(
          icon: Icons.history_rounded,
          title: 'الأرشيف',
          subtitle: 'عرض سجل الحجوزات السابقة حسب التاريخ',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LabBookingsHistoryScreen(laboratoryId: widget.laboratory.id),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Send Notifications Button
        _buildControlButton(
          icon: Icons.notifications_active,
          title: 'إرسال إشعارات',
          subtitle: 'إرسال إشعار لجميع مستخدمي التطبيق',
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
        const SizedBox(height: 16),

        // Edit Laboratory Button
        _buildControlButton(
          icon: Icons.edit_rounded,
          title: 'تعديل بيانات المعمل',
          subtitle: 'تحديث المعلومات والمواعيد والإعدادات',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EditLaboratoryScreen(laboratory: widget.laboratory),
              ),
            ).then((_) {
              // Refresh data after edit
              setState(() {
                _loadOffersCount();
              });
            });
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _cardColor,
        border: Border.all(color: const Color(0xFFDCE6EF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.15),
                        _secondaryColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
