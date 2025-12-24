import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import 'the_pharmacies_screen.dart';
import 'all_offers_screen.dart';
import '../../../medicine_requests/presentation/screens/request_medicine_screen.dart';
import '../../../medicine_requests/presentation/screens/medicine_requests_list_screen.dart';
import '../../../medicine_requests/presentation/screens/my_medicine_requests_screen.dart';
import '../../../delivery/presentation/screens/delivery_list_screen.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class PharmacyHomePage extends StatelessWidget {
  const PharmacyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: GradientAppBar(
        title: 'الصيدليات',
        
        gradient: AppTheme.pharmacyGradient,
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
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
                  final requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: context.read<AuthCubit>(),
                              child: const MyMedicineRequestsScreen(),
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_cart_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider.value(
                                    value: context.read<AuthCubit>(),
                                    child: const MyMedicineRequestsScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (requestCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IgnorePointer(
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      requestCount > 99 ? '99+' : requestCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خدمات الصيدلية',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   'اختر الخدمة التي تحتاجها',
                  //   style: TextStyle(
                  //     fontSize: 15,
                  //     fontWeight: FontWeight.w400,
                  //     color: const Color(0xFF64748B),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height:10),
              // Welcome Header
              // Container(
              //   padding: const EdgeInsets.all(24),
              //   decoration: BoxDecoration(
              //     gradient: AppTheme.pharmacyGradient,
              //     borderRadius: BorderRadius.circular(20),
              //     boxShadow: [
              //       BoxShadow(
              //         color: AppTheme.secondaryColor.withValues(alpha: 0.3),
              //         blurRadius: 20,
              //         offset: const Offset(0, 10),
              //       ),
              //     ],
              //   ),
              //   child: Row(
              //     children: [
              //       Container(
              //         padding: const EdgeInsets.all(16),
              //         decoration: BoxDecoration(
              //           color: Colors.white.withValues(alpha: 0.2),
              //           shape: BoxShape.circle,
              //         ),
              //         child: SvgPicture.asset(
              //           'assets/images/pharmacy.svg',
              //           width: 40,
              //           height: 40,
              //           colorFilter: const ColorFilter.mode(
              //             Colors.white,
              //             BlendMode.srcIn,
              //           ),
              //         ),
              //       ),
              //       const SizedBox(width: 16),
              //       Expanded(
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               'خدمات الصيدليات',
              //               style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              //                 color: Colors.white,
              //                 fontWeight: FontWeight.bold,
              //               ),
              //             ),
              //             const SizedBox(height: 4),
              //             Text(
              //               'جميع احتياجاتك الدوائية في مكان واحد',
              //               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //                 color: Colors.white.withValues(alpha: 0.9),
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),
              
              // Main Options
              _buildMainOptions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainOptions(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isPharmacyOwner = authState is Authenticated && 
                                 authState.user.pharmacyId != null;
        
        return Column(
          children: [
            _buildPremiumCard(
              context: context,
              icon: Icons.store_rounded,
              title: 'الصيدليات',
              description: 'تصفح جميع الصيدليات القريبة',
              isPrimary: true,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const ThePharmaciesScreen(),
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
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            _buildPremiumCard(
              context: context,
              icon: Icons.local_offer_rounded,
              title: 'العروض والخصومات',
              description: 'اكتشف أحدث العروض',
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const AllOffersScreen(),
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
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            _buildPremiumCard(
              context: context,
              icon: Icons.delivery_dining_rounded,
              title: 'الديليفري المتاحين',
              description: 'خدمات التوصيل السريع',
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const DeliveryListScreen(),
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
                  ),
                );
              },
            ),
            
            if (isPharmacyOwner) ...[
              const SizedBox(height: 12),
              _buildPremiumCard(
                context: context,
                icon: Icons.receipt_long_rounded,
                title: 'طلبات الناس',
                description: 'طلبات الأدوية من المستخدمين',
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => BlocProvider.value(
                        value: context.read<AuthCubit>(),
                        child: const MedicineRequestsListScreen(),
                      ),
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
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 12),
            _buildPremiumCard(
              context: context,
              icon: Icons.medication_rounded,
              title: 'طلب دواء',
              description: 'اطلب دوائك بسهولة',
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => BlocProvider.value(
                      value: context.read<AuthCubit>(),
                      child: const RequestMedicineScreen(),
                    ),
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
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildPremiumCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isPrimary ? 24 : 20),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: isPrimary ? 56 : 48,
                  height: isPrimary ? 56 : 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF06B6D4),
                        Color(0xFF0891B2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isPrimary ? 14 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: isPrimary ? 28 : 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isPrimary ? 18 : 17,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ), 
    );
  }
}
