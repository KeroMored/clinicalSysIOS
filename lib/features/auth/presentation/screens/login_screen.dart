import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF0EA5E9),
                const Color(0xFF06B6D4),
                const Color(0xFF0891B2),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
                if (state is Authenticated) {
                  Navigator.pop(context);
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -100,
                      right: -100,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -150,
                      left: -150,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    
                    // Main content
                    Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: 24,
                        ),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Premium Logo Design
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                     borderRadius: BorderRadius.all(Radius.circular(20)),
                                  //  shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 20,
                                        offset: const Offset(-5, -5),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/LO.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF06B6D4),
                                                Color(0xFF0891B2),
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.local_hospital_rounded,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // Elegant Welcome Section
                                Column(
                                  children: [
                                    const Text(
                                      'أهلاً وسهلاً',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color: Color(0x40000000),
                                            offset: Offset(0, 2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'في منصتك الصحية الشاملة',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.95),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                           ],
                                ),
                                const SizedBox(height: 48),

                                // Google Sign In Button with premium design
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 25,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap: isLoading
                                          ? null
                                          : () {
                                              context.read<AuthCubit>().signInWithGoogle();
                                            },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        height: 65,
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (isLoading)
                                              const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF06B6D4),
                                                  ),
                                                ),
                                              )
                                            else
                                            //   Container(
                                            //     width: 28,
                                            //     height: 28,
                                            //     decoration: BoxDecoration(
                                            //       color: Colors.white,
                                            //       shape: BoxShape.circle,
                                            //       boxShadow: [
                                            //         BoxShadow(
                                            //           color: Colors.black.withValues(alpha: 0.1),
                                            //           blurRadius: 4,
                                            //           offset: const Offset(0, 2),
                                            //         ),
                                            //       ],
                                            //     ),
                                            //     child: const Icon(
                                            //       Icons.g_mobiledata_rounded,
                                            //       color: Color(0xFF06B6D4),
                                            //       size: 24,
                                            //     ),
                                            //   ),
                                            // const SizedBox(width: 16),
                                            Text(
                                              isLoading
                                                  ? 'جاري تسجيل الدخول...'
                                                  : 'تسجيل الدخول بواسطة Google',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF06B6D4),
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Skip Button with elegant design
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'تخطي والدخول كضيف',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white.withOpacity(0.95),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // Benefits Card with glassmorphism
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.workspace_premium_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          const Text(
                                            'مميزات تسجيل الدخول',
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      _buildBenefitItem(
                                        Icons.store_rounded,
                                        'إدارة مكانك بسهولة',
                                      ),
                                       _buildBenefitItem(
                                        Icons.shopping_bag_rounded,
                                        "طلب الدواء من الصيدليات المتاحة",
                                      ),
                                      
                                      _buildBenefitItem(
                                        Icons.local_shipping_rounded,
                                        'طلب خدمات التوصيل الطبي',
                                      ),
                                         _buildBenefitItem(
                                        Icons.date_range_outlined,
                                        "حجز ميعاد للكشف",
                                      ),
                                      _buildBenefitItem(
                                        Icons.star_rounded,
                                        'الوصول لجميع الميزات المتقدمة',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
