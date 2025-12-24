import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'the_pharmacies_screen.dart';
import 'all_offers_screen.dart';
import '../../../medicine_requests/presentation/screens/request_medicine_screen.dart';
import '../../../medicine_requests/presentation/screens/medicine_requests_list_screen.dart';
import '../../../medicine_requests/presentation/screens/my_medicine_requests_screen.dart';
import '../../../delivery/presentation/screens/delivery_list_screen.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// 📱 Responsive Pharmacy Home Page
/// يدعم جميع أحجام الشاشات: Mobile, Tablet, Desktop
class PharmacyHomePageResponsive extends StatelessWidget {
  const PharmacyHomePageResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'الصيدليات',
        gradient: AppTheme.pharmacyGradient,
      ),
      body: Container(
        color: const Color(0xFFFAFBFC),
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  /// 📱 Mobile Layout
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(context.padding(mobile: 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: context.hp(3)),
            _buildServicesGrid(context, columns: 1),
          ],
        ),
      ),
    );
  }

  /// 📱 Tablet Layout
  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(context.padding(tablet: 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: context.hp(4)),
            _buildServicesGrid(context, columns: 2),
          ],
        ),
      ),
    );
  }

  /// 💻 Desktop Layout
  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(context.padding(desktop: 32)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: context.hp(5)),
                _buildServicesGrid(context, columns: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// رأس الصفحة
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خدمات الصيدلية',
          style: TextStyle(
            fontSize: context.sp(24),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        // SizedBox(height: context.hp(1)),
        // Text(
        //   'اختر الخدمة التي تحتاجها',
        //   style: TextStyle(
        //     fontSize: context.sp(14),
        //     fontWeight: FontWeight.w400,
        //     color: const Color(0xFF64748B),
        //   ),
        // ),
      ],
    );
  }

  /// شبكة الخدمات
  Widget _buildServicesGrid(BuildContext context, {required int columns}) {
    final authState = context.watch<AuthCubit>().state;
    final isPharmacyOwner = authState is Authenticated && authState.user.isPharmacyOwner;

    final services = [
      _ServiceItem(
        icon: Icons.local_pharmacy_rounded,
        title: 'جميع الصيدليات',
        description: 'تصفح الصيدليات القريبة منك',
        onTap: () => Navigator.push(
          context,
          _createRoute(const ThePharmaciesScreen()),
        ),
      ),
      _ServiceItem(
        icon: Icons.local_offer_rounded,
        title: 'العروض والخصومات',
        description: 'اكتشف أحدث العروض',
        onTap: () => Navigator.push(
          context,
          _createRoute(const AllOffersScreen()),
        ),
      ),
      _ServiceItem(
        icon: Icons.delivery_dining_rounded,
        title: 'الديليفري المتاحين',
        description: 'خدمات التوصيل السريع',
        onTap: () => Navigator.push(
          context,
          _createRoute(const DeliveryListScreen()),
        ),
      ),
      if (!isPharmacyOwner) ...[
        _ServiceItem(
          icon: Icons.medical_services_rounded,
          title: 'اطلب دواء',
          description: 'اطلب الدواء الذي تحتاجه',
          onTap: () => Navigator.push(
            context,
            _createRoute(const RequestMedicineScreen()),
          ),
        ),
        _ServiceItem(
          icon: Icons.history_rounded,
          title: 'طلباتي',
          description: 'عرض طلبات الأدوية الخاصة بي',
          onTap: () => Navigator.push(
            context,
            _createRoute(BlocProvider.value(
              value: context.read<AuthCubit>(),
              child: const MyMedicineRequestsScreen(),
            )),
          ),
        ),
      ],
      if (isPharmacyOwner) ...[
        _ServiceItem(
          icon: Icons.receipt_long_rounded,
          title: 'طلبات الناس',
          description: 'طلبات الأدوية من المستخدمين',
          onTap: () => Navigator.push(
            context,
            _createRoute(BlocProvider.value(
              value: context.read<AuthCubit>(),
              child: const MedicineRequestsListScreen(),
            )),
          ),
        ),
      ],
    ];

    // استخدام GridView بدلاً من Column
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: context.padding(mobile: 12, tablet: 16, desktop: 20),
        mainAxisSpacing: context.padding(mobile: 12, tablet: 16, desktop: 20),
        childAspectRatio: context.responsiveValue(
          mobile: 1.1,
          tablet: 1.3,
          desktop: 1.4,
        ),
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(context, services[index]);
      },
    );
  }

  /// بطاقة الخدمة
  Widget _buildServiceCard(BuildContext context, _ServiceItem service) {
    return GestureDetector(
      onTap: service.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            context.responsiveValue(mobile: 16.0, tablet: 20.0, desktop: 24.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(
            context.padding(mobile: 16, tablet: 20, desktop: 24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة
              Container(
                padding: EdgeInsets.all(
                  context.padding(mobile: 12, tablet: 14, desktop: 16),
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.pharmacyGradient,
                  borderRadius: BorderRadius.circular(
                    context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  service.icon,
                  color: Colors.white,
                  size: context.iconSize(mobile: 28, tablet: 32, desktop: 36),
                ),
              ),
              
              SizedBox(height: context.hp(2)),
              
              // العنوان
              Text(
                service.title,
                style: TextStyle(
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: context.hp(0.5)),
              
              // الوصف
              Text(
                service.description,
                style: TextStyle(
                  fontSize: context.sp(12),
                  color: const Color(0xFF64748B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // سهم للتفاعل
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: context.iconSize(mobile: 16, tablet: 18, desktop: 20),
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// إنشاء الانتقال المتحرك
  PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

/// نموذج عنصر الخدمة
class _ServiceItem {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
}
