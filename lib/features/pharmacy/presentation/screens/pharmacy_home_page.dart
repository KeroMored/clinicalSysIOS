import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../delivery/presentation/screens/delivery_list_screen.dart';
import '../../../medicine_requests/presentation/screens/medicine_requests_list_screen.dart';
import '../../../medicine_requests/presentation/screens/request_medicine_screen.dart';
import 'package:clinicalsystem/features/medicine_requests/presentation/screens/my_medicine_requests_screen.dart';
import 'all_offers_screen.dart';
import 'near_expire_items_screen.dart';
import 'the_pharmacies_screen.dart';

class PharmacyHomePage extends StatefulWidget {
  const PharmacyHomePage({super.key});

  @override
  State<PharmacyHomePage> createState() => _PharmacyHomePageState();
}

class _PharmacyHomePageState extends State<PharmacyHomePage> {
  static const String _bookingSettingsCollection = 'app_settings';
  static const String _bookingSettingsDoc = 'booking';
  final TextEditingController _searchController = TextEditingController();
  late final Future<bool> _isBookingEnabledFuture;

  @override
  void initState() {
    super.initState();
    _isBookingEnabledFuture = _fetchIsBookingEnabled();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _fetchIsBookingEnabled() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_bookingSettingsCollection)
          .doc(_bookingSettingsDoc)
          .get();

      final data = doc.data();
      if (data == null) return true;

      final value = data['isBooking'];
      return value is bool ? value : true;
    } catch (e) {
      debugPrint('Error loading booking settings: $e');
      return true;
    }
  }

  void _openPharmaciesSearch(BuildContext context, String rawQuery) {
    final query = rawQuery.trim();
    _pushWithFade(
      context,
      ThePharmaciesScreen(initialSearchQuery: query.isEmpty ? null : query),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        surfaceTintColor: const Color(0xFFF4F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            size: 20,
            color: Color(0xFF0B8293),
          ),
        ),
        title: const Text(
          'الصيدليات',
          style: TextStyle(
            color: Color(0xFF0B8293),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          FutureBuilder<bool>(
            future: _isBookingEnabledFuture,
            builder: (context, snapshot) {
              final isBookingEnabled = snapshot.data ?? true;
              if (!isBookingEnabled) {
                return const SizedBox.shrink();
              }
              return _buildCartAction(context);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchField(context),
              const SizedBox(height: 14),
              //  _buildHeroCard(),
              //const SizedBox(height: 14),
              FutureBuilder<bool>(
                future: _isBookingEnabledFuture,
                builder: (context, snapshot) {
                  final isBookingEnabled = snapshot.data ?? true;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMainOptions(
                        context,
                        isBookingEnabled: isBookingEnabled,
                      ),
                      if (isBookingEnabled) ...[
                        const SizedBox(height: 14),
                        _buildMedicineRequestInfoCard(),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartAction(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('medicine_requests')
              .where('userId', isEqualTo: authState.user.uid)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            final requestCount = snapshot.hasData
                ? snapshot.data!.docs.length
                : 0;

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Color(0xFF0B8293),
                    size: 22,
                  ),
                  onPressed: () => _openMyRequests(context),
                ),
                if (requestCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          requestCount > 99 ? '99+' : requestCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) => _openPharmaciesSearch(context, value),
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF334155),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'ابحث عن صيدلية...',
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF94A3B8),
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: () =>
              _openPharmaciesSearch(context, _searchController.text),
          icon: const Icon(
            Icons.arrow_forward_rounded,
            color: Color(0xFF0B8293),
            size: 18,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF0B8293), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppTheme.pharmacyGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B8293).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Icon(
              Icons.local_pharmacy_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملوي كيور | Mallawi Cure',
                style: TextStyle(
                  fontSize: 21,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'رعاية صحية متكاملة بلمسة إنسانية.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'اكتشف خدمات الصيدلية الذكية.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainOptions(
    BuildContext context, {
    required bool isBookingEnabled,
  }) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isPharmacyOwner =
            authState is Authenticated && authState.user.pharmacyId != null;

        return Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildFeatureCard(
                  icon: Icons.store_rounded,
                  title: 'الصيدليات',
                  onTap: () =>
                      _pushWithFade(context, const ThePharmaciesScreen()),
                ),
                if (isBookingEnabled)
                  _buildFeatureCard(
                    icon: Icons.local_offer_rounded,
                    title: 'العروض\nوالخصومات',
                    onTap: () =>
                        _pushWithFade(context, const AllOffersScreen()),
                  ),
                if (isBookingEnabled)
                  _buildFeatureCard(
                    icon: Icons.medication_rounded,
                    title: 'طلب دواء',
                    onTap: () => _pushWithFade(
                      context,
                      BlocProvider.value(
                        value: context.read<AuthCubit>(),
                        child: const RequestMedicineScreen(),
                      ),
                    ),
                  ),
                _buildFeatureCard(
                  icon: Icons.delivery_dining_rounded,
                  title: 'الدليفري',
                  onTap: () =>
                      _pushWithFade(context, const DeliveryListScreen()),
                ),
              ],
            ),
            if (isPharmacyOwner) ...[
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildFeatureCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'طلبات\nالناس',
                    onTap: () => _pushWithFade(
                      context,
                      BlocProvider.value(
                        value: context.read<AuthCubit>(),
                        child: const MedicineRequestsListScreen(),
                      ),
                    ),
                  ),
                  _buildFeatureCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'أدوية قاربت\nعلى الانتهاء',
                    onTap: () =>
                        _pushWithFade(context, const NearExpireItemsScreen()),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.merge(
              Border(right: BorderSide(color: Colors.teal, width: 0.5)),
              Border(bottom: BorderSide(color: Colors.teal, width: 1.5)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B7285),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  size: 23,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B8293),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineRequestInfoCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.merge(
          Border(right: BorderSide(color: Colors.teal, width: 1.5)),
          Border(bottom: BorderSide(color: Colors.teal, width: 1.5)),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خدمة عملائنا',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF0B8293),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'عند طلب الدواء من التطبيق:\n -يتم إرسال طلبك لكل الصيدليات المتاحة .\n -الصيدلية التي يتوفر لديها طلبك ستتواصل معك .\n\n *مهم : بعد التواصل، ادخل على السلة (أعلى الصفحة الرئيسية) واضغط "تم التواصل" على الطلب حتى لا تتواصل معك صيدليات أخري \n\n **مهم جداً : فى حالة الطلبات الوهمية يتم قفل حسابك على التطبيق باكمله ولم تستطع الدخول مرة أخرى .',
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openMyRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const MyMedicineRequestsScreen(),
        ),
      ),
    );
  }

  void _pushWithFade(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}
