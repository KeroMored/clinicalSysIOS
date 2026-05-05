import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../cubit/auth_cubit.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF0B8293);
  static const Color _secondary = Color(0xFF179AAC);
  static const Color _background = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [_primary, _secondary],
  );

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final showAppleButton =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            Positioned(
              top: -120,
              left: -60,
              child: Container(
                width: size.width * 0.65,
                height: size.width * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              right: -90,
              child: Container(
                width: size.width * 0.78,
                height: size.width * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _secondary.withOpacity(0.12),
                ),
              ),
            ),
            SafeArea(
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: const EdgeInsets.all(14),
                      ),
                    );
                  }
                  if (state is Authenticated) {
                    Navigator.pop(context);
                  }
                },
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildLogoCard(),
                            const SizedBox(height: 20),
                            const Text(
                              'أهلاً بك في Mallawy Care',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'تسجيل الدخول يفتح لك كل الخدمات الطبية بسهولة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFDDE7EF),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primary.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        color: _textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildGoogleButton(isLoading),
                                  if (showAppleButton) ...[
                                    const SizedBox(height: 8),
                                    _buildAppleButton(isLoading),
                                  ],
                                  const SizedBox(height: 8),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      side: const BorderSide(
                                        color: Color(0xFFD7E3EC),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'تخطي والدخول كضيف',
                                      style: TextStyle(
                                        color: _textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Container(
                            //   width: double.infinity,
                            //   padding: const EdgeInsets.all(14),
                            //   decoration: BoxDecoration(
                            //     color: Colors.white,
                            //     borderRadius: BorderRadius.circular(18),
                            //     border: Border.all(
                            //       color: const Color(0xFFDDE7EF),
                            //     ),
                            //   ),
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: const [
                            //       Text(
                            //         'مميزات تسجيل الدخول',
                            //         style: TextStyle(
                            //           color: _textPrimary,
                            //           fontSize: 13,
                            //           fontWeight: FontWeight.w800,
                            //         ),
                            //       ),
                            //       SizedBox(height: 10),
                            //       _BenefitItem(
                            //         icon: Icons.store_rounded,
                            //         text: 'إدارة مكانك الطبي بسهولة',
                            //       ),
                            //       _BenefitItem(
                            //         icon: Icons.shopping_bag_rounded,
                            //         text: 'طلب الأدوية من الصيدليات',
                            //       ),
                            //       _BenefitItem(
                            //         icon: Icons.calendar_month_rounded,
                            //         text: 'حجز المواعيد ومتابعة الخدمات',
                            //       ),
                            //       _BenefitItem(
                            //         icon: Icons.notifications_active_rounded,
                            //         text: 'تنبيهات ومتابعة أسرع للحجوزات',
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return Container(
      width: 122,
      height: 122,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.merge(
          Border(right: BorderSide(color: _primary, width: 2.5)),
          Border(bottom: BorderSide(color: _primary, width: 2.5)),
        ),
        //  gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(26),
        // boxShadow: [
        //   BoxShadow(
        //     color: _primary.withOpacity(0.24),
        //     blurRadius: 18,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Container(
        decoration: BoxDecoration(
          //  border: Border.merge(
          // Border(right: BorderSide(color: _primary, width: 0.5)),
          // Border(bottom: BorderSide(color: _primary, width: 2.5)),
          // ),
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/images/LO.png',
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.local_hospital_rounded,
                size: 54,
                color: _primary,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.26),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading
              ? null
              : () => context.read<AuthCubit>().signInWithGoogle(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: AppLoadingIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isLoading
                          ? 'جاري تسجيل الدخول...'
                          : 'تسجيل الدخول بواسطة Google',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleButton(bool isLoading) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading
              ? null
              : () => context.read<AuthCubit>().signInWithApple(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: AppLoadingIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const FaIcon(
                      FontAwesomeIcons.apple,
                      color: Colors.white,
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isLoading
                          ? 'جاري تسجيل الدخول...'
                          : 'تسجيل الدخول بواسطة Apple',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF0B8293).withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF0B8293), size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
