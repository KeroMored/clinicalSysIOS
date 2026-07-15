import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/pharmacy_model.dart';
import 'edit_pharmacy_screen.dart';
import 'pharmacy_details_screen.dart';
import 'pharmacy_offers_management_screen.dart';
import 'near_expire_items_management_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class PharmacyControlPage extends StatefulWidget {
  const PharmacyControlPage({super.key});

  @override
  State<PharmacyControlPage> createState() => _PharmacyControlPageState();
}

class _PharmacyControlPageState extends State<PharmacyControlPage> {
  PharmacyModel? _pharmacy;
  bool _isLoading = true;
  int _offersCount = 0;

  // Theme colors aligned with the refreshed app style
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _secondaryColor = Color(0xFF179AAC);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0B8293), Color(0xFF179AAC)],
  );

  @override
  void initState() {
    super.initState();
    _loadPharmacyData();
  }

  Future<void> _loadOffersCount() async {
    if (_pharmacy == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('pharmacyId', isEqualTo: _pharmacy!.id)
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

  Future<void> _loadPharmacyData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated && authState.user.pharmacyId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(authState.user.pharmacyId)
            .get();

        if (doc.exists) {
          // Add the document ID to the data before parsing
          final data = doc.data()!;
          data['id'] = doc.id; // ⭐ Important: Add ID from document

          if (mounted) {
            setState(() {
              _pharmacy = PharmacyModel.fromJson(data);
              _isLoading = false;
            });
            // Load offers count after pharmacy data is loaded
            _loadOffersCount();
          }

          print('✅ تم تحميل بيانات الصيدلية - ID: ${doc.id}');
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('لم يتم العثور على بيانات الصيدلية'),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('خطأ في تحميل البيانات: $e')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const AppLoadingIndicator(
                        color: _primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'جاري تحميل بيانات الصيدلية...',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _pharmacy == null
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _loadPharmacyData,
                color: _primaryColor,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // App Bar
                    _buildAppBar(),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Pharmacy Name Container
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: _primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.local_pharmacy_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'صيدلية',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _pharmacy!.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
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
                                    value: '${_pharmacy!.profileViewsCount}',
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.star_rounded,
                                    title: 'التقييم',
                                    value: _pharmacy!.averageRating.toStringAsFixed(1),
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
                                    value: '${_pharmacy!.totalLikes}',
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            
                            // Edit Pharmacy Button
                            _buildEditPharmacyButton(),
                            
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.local_pharmacy_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لم يتم العثور على بيانات الصيدلية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'من فضلك أعد تشغيل التطبيق',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
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
          color: Color(0xFF0F172A),
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'إدارة الصيدلية',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: _loadPharmacyData,
          tooltip: 'تحديث',
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
      ),
    );
  }

  Widget _buildPharmacyInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7EF)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: _primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'معلومات الصيدلية',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditPharmacyScreen(pharmacy: _pharmacy!),
                        ),
                      );
                      if (result == true) {
                        _loadPharmacyData();
                      }
                    },
                    icon: const Icon(Icons.edit_rounded, size: 22),
                    color: _primaryColor,
                    tooltip: 'تعديل البيانات',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pharmacy Name
            _buildInfoRow(
              icon: Icons.local_pharmacy_rounded,
              label: 'اسم الصيدلية',
              value: _pharmacy!.name,
              color: _primaryColor,
            ),
            const SizedBox(height: 18),

            // Address
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              label: 'العنوان',
              value: _pharmacy!.address,
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 18),

            // Phone
            _buildInfoRow(
              icon: Icons.phone_rounded,
              label: 'رقم الهاتف',
              value: _pharmacy!.phones.isNotEmpty
                  ? _pharmacy!.phones.join(', ')
                  : 'غير متوفر',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 18),

            // Owner Email
            _buildInfoRow(
              icon: Icons.email_rounded,
              label: 'البريد الإلكتروني',
              value: _pharmacy!.authEmails.isNotEmpty
                  ? _pharmacy!.authEmails.first
                  : 'غير متوفر',
              color: const Color(0xFF8B5CF6),
            ),

            // Working Hours
            if (_pharmacy!.workingHours.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildInfoRow(
                icon: Icons.access_time_rounded,
                label: 'ساعات العمل',
                value: _pharmacy!.workingHours,
                color: const Color(0xFFF59E0B),
              ),
            ],

            const SizedBox(height: 24),

            // View Details Button
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PharmacyDetailsScreen(pharmacyId: _pharmacy!.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.3),
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  color: _primaryColor.withOpacity(0.05),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      color: _primaryColor,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'عرض صفحة الصيدلية',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.local_offer_outlined,
          title: 'إدارة العروض',
          subtitle: 'عرض وإدارة جميع العروض',
          iconColor: _primaryColor,
          titleColor: _textPrimary,
          subtitleColor: _textSecondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PharmacyOffersManagementScreen(
                  pharmacy: _pharmacy!,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          icon: Icons.warning_amber_rounded,
          title: 'منتجات قرب تنتهي',
          subtitle: 'عرض وإدارة المنتجات القريبة من الانتهاء',
          iconColor: const Color(0xFFD97706),
          titleColor: _textPrimary,
          subtitleColor: _textSecondary,
          onTap: () async {
            final authState = context.read<AuthCubit>().state;
            if (authState is! Authenticated || _pharmacy == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NearExpireItemsManagementScreen(
                  pharmacy: _pharmacy!,
                  userId: authState.user.uid,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color titleColor,
    required Color subtitleColor,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    final hasGradient = gradient != null;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: hasGradient ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: hasGradient
            ? null
            : Border.all(color: const Color(0xFFDBE5EE), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: hasGradient
                ? _primaryColor.withOpacity(0.22)
                : _primaryColor.withOpacity(0.08),
            blurRadius: hasGradient ? 14 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasGradient
                        ? Colors.white.withOpacity(0.2)
                        : iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: hasGradient
                      ? Colors.white.withOpacity(0.95)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildEditPharmacyButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPharmacyScreen(pharmacy: _pharmacy!),
          ),
        ).then((_) => _loadPharmacyData());
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: _primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تعديل بيانات الصيدلية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تحديث المعلومات والمواعيد والإعدادات',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
