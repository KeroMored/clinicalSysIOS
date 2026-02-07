import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../pharmacy/presentation/screens/pharmacy_home_page.dart';
import '../../pharmacy/presentation/screens/pharmacy_control_page.dart';
import '../../clinic/presentation/screens/clinic_home_page.dart';
import '../../clinic/presentation/screens/clinic_control_page.dart';
import '../../clinic/presentation/widgets/doctor_of_day_banner.dart';
import '../../laboratory/presentation/screens/laboratory_home_page.dart';
import '../../laboratory/presentation/screens/laboratory_owner_dashboard.dart';
import '../../radiology/presentation/screens/radiology_home_page.dart';
import '../../radiology/presentation/screens/radiology_owner_dashboard.dart';
import '../../rehabilitation/presentation/screens/rehabilitation_centers_list_screen.dart';
import '../../rehabilitation/presentation/screens/rehabilitation_center_control_page.dart';
import '../../rehabilitation/presentation/cubit/rehabilitation_cubit.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import '../../rehabilitation/data/repositories/rehabilitation_repository.dart';
import '../../gym/presentation/pages/gyms_list_screen.dart';
import '../../gym/presentation/pages/gym_control_page.dart';
import '../../gym/presentation/cubit/gym_cubit.dart';
import '../../gym/data/repositories/gym_repository.dart';
import '../../admin/presentation/screens/admin_home_page.dart';
import '../../admin/presentation/screens/additions_screen.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../medicine_reminders/presentation/screens/medicines_screen.dart';
import '../../emergency_numbers/presentation/screens/emergency_numbers_screen.dart';
import 'widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              
            "Mallawy Care",
            maxLines: 2,
           // textScaleFactor: 0.9,
textAlign: TextAlign.center,
              style: TextStyle(
              
                height: 1,
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                // User is logged in
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        backgroundImage: state.user.photoUrl.isNotEmpty
                            ? NetworkImage(state.user.photoUrl)
                            : null,
                        child: state.user.photoUrl.isEmpty
                            ? const Icon(Icons.person, size: 20, color: Color(0xFF00BCD4))
                            : null,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(user: state.user),
                        ),
                      );
                    },
                  ),
                );
              } else {
                // User is not logged in
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<AuthCubit>(),
                            child: const LoginScreen(),
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.login, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'دخول',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
            ],
          ),
        ),
      ),
      drawer: const CustomHomeDrawer(),
      floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          // Show FAB for any location owner
          if (state is Authenticated) {
            // Check all location types at once
            return FutureBuilder<List<QuerySnapshot>>(
              future: Future.wait([
                FirebaseFirestore.instance
                    .collection('pharmacies')
                    .where('authEmails', arrayContains: state.user.email)
                    .where('status', isEqualTo: 'approved')
                    .limit(1)
                    .get(),
                FirebaseFirestore.instance
                    .collection('clinics')
                    .where('authEmails', arrayContains: state.user.email)
                    .limit(1)
                    .get(),
                FirebaseFirestore.instance
                    .collection('laboratories')
                    .where('authEmails', arrayContains: state.user.email)
                    .where('status', isEqualTo: 'approved')
                    .limit(1)
                    .get(),
                FirebaseFirestore.instance
                    .collection('radiology_centers')
                    .where('authEmails', arrayContains: state.user.email)
                    .where('isApproved', isEqualTo: true)
                    .limit(1)
                    .get(),
                FirebaseFirestore.instance
                    .collection('gyms')
                    .where('authEmails', arrayContains: state.user.email)
                    .where('isApproved', isEqualTo: true)
                    .limit(1)
                    .get(),
                FirebaseFirestore.instance
                    .collection('rehabilitation_centers')
                    .where('authEmails', arrayContains: state.user.email)
                    .where('isApproved', isEqualTo: true)
                    .limit(1)
                    .get(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final pharmacySnapshot = snapshot.data![0];
                  final clinicSnapshot = snapshot.data![1];
                  final labSnapshot = snapshot.data![2];
                  final radiologySnapshot = snapshot.data![3];
                  final gymSnapshot = snapshot.data![4];
                  final rehabSnapshot = snapshot.data![5];
                  
                  // Priority order: Pharmacy > Clinic > Laboratory > Radiology > Gym > Rehabilitation
                  if (pharmacySnapshot.docs.isNotEmpty) {
                    return FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PharmacyControlPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.dashboard),
                      label: const Text('لوحة تحكم الصيدلية'),
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                    );
                  } else if (clinicSnapshot.docs.isNotEmpty) {
                    return FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClinicControlPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.dashboard),
                      label: const Text('لوحة تحكم العيادة'),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    );
                  } else if (labSnapshot.docs.isNotEmpty) {
                    return FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LaboratoryOwnerDashboard(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.dashboard),
                      label: const Text('لوحة تحكم المعمل'),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    );
                  } else if (radiologySnapshot.docs.isNotEmpty) {
                    return FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RadiologyOwnerDashboard(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.dashboard),
                      label: const Text('لوحة تحكم مركز الأشعة'),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    );
                  } else if (gymSnapshot.docs.isNotEmpty) {
                    return FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GymControlPage(
                              gymEmail: state.user.email,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.dashboard),
                      label: const Text('لوحة تحكم الجيم'),
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                    );
                  } else if (rehabSnapshot.docs.isNotEmpty) {
                    return FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RehabilitationCenterControlPage(
                              centerEmail: state.user.email,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.dashboard),
                      label: const Text('لوحة تحكم مركز التأهيل'),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFAFBFC),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor of the Day Banner
                const DoctorOfTheDayBanner(),
                const SizedBox(height: 28),
                
                // Section Header with better hierarchy
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الخدمات الطبية',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر الخدمة التي تحتاجها',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
          
                // First Row: العيادات & الصيدليات
                Row(
                  children: [
                    Expanded(
                      child: ModernServiceCard(
                        icon: FontAwesomeIcons.stethoscope,
                        title: 'العيادات',
                        gradient: AppTheme.clinicGradient,
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const ClinicHomePage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(0.9, -0.5);
                                const end = Offset.zero;
                                const curve = Curves.ease;
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernPharmacyCard(
                        title: 'الصيدليات',
                        gradient: AppTheme.pharmacyGradient,
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const PharmacyHomePage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(-0.5, 0.9);
                                const end = Offset.zero;
                                const curve = Curves.ease;
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
                    ),
                  ],
              ),
              const SizedBox(height: 16),
              
              // Second Row: معامل التحاليل & مراكز الأشعة
              Row(
                children: [
                  Expanded(
                    child: ModernServiceCard(
                      icon: FontAwesomeIcons.microscope,
                      title: 'معامل التحاليل',
                      gradient: AppTheme.laboratoryGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const LaboratoryHomePage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(0.9, 0.9);
                              const end = Offset.zero;
                              const curve = Curves.ease;
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ModernServiceCard(
                      icon: FontAwesomeIcons.xRay,
                      title: 'مراكز الأشعة',
                      gradient: AppTheme.radiologyGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const RadiologyHomePage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(-0.3,- 0.3);
                              const end = Offset.zero;
                              const curve = Curves.ease;
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Third Row: التمريض & مراكز التأهيل
              Row(
                children: [


 Expanded(
                    child: ModernServiceCard(
                      icon: Icons.fitness_center_rounded,
                      title: 'الجيم',
                      gradient: AppTheme.gymGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
                              create: (context) => GymCubit(GymRepository()),
                              child: const GymsListScreen(),
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(0.5, -0.9);
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
                  ),
        






                
                  const SizedBox(width: 16),
                  Expanded(
                    child: ModernServiceCard(
                      icon: Icons.healing_rounded,
                      title: 'مراكز التأهيل',
                      gradient: AppTheme.rehabilitationGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
                              create: (context) => RehabilitationCubit(RehabilitationRepository()),
                              child: const RehabilitationCentersListScreen(),
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(-0.5, 0.9);
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Fourth Row: الإضافات ومواعيد الأدوية
              Row(
                children: [
                  Expanded(
                    child: ModernServiceCard(
                      icon: Icons.add_circle_outline,
                      title: 'الإضافات',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const AdditionsScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(0.5, -0.9);
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
                  ),
                  const SizedBox(width: 16),
                  
                  // Medicine Reminders Button
                  Expanded(
                    child: ModernServiceCard(
                      icon: Icons.medication,
                      title: 'مواعيد الأدوية',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return const MedicinesScreen();
                            },
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(0.5, -0.9);
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Fifth Row: Admin Section
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final currentUser = authState is Authenticated ? authState.user : null;
                  final isAdmin = currentUser?.email == 'kerolesmored@gmail.com';
                  
                  if (!isAdmin) {
                    return const SizedBox.shrink();
                  }
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ModernServiceCard(
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'الأدمن',
                              gradient: AppTheme.accentGradient,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const AdminHomePage(),
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
                          ),
                          const SizedBox(width: 16),
                          // Empty space to balance the row
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFBFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
              
              // Emergency Numbers Button
              Row(
                children: [
                  Expanded(
                    child: ModernServiceCard(
                      icon: Icons.emergency,
                      title: 'أرقام الطوارئ',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const EmergencyNumbersScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(0.0, 0.1);
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
                  ),
                  const SizedBox(width: 16),
                  // Empty space to balance the row
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFBFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
           
            ],
          ),
        ),
      ),
    ));
  }
}
