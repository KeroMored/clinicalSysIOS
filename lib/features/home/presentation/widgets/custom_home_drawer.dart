import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'home_drawer_item.dart';
import 'about_app_dialog.dart';
import 'whatsapp_helper.dart';
import 'share_app_dialog.dart';
import 'privacy_policy_dialog.dart';
import 'terms_and_conditions_dialog.dart';

class CustomHomeDrawer extends StatelessWidget {
  const CustomHomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        size: 50,
                        color: Color(0xFF26A69A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'النظام الطبي المتكامل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'خدماتك الصحية في مكان واحد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // من نحن
            HomeDrawerItem(
              icon: Icons.info_outline_rounded,
              title: 'من نحن',
              onTap: () {
                Navigator.pop(context);
                AboutAppDialog.show(context);
              },
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // تواصل معنا
            HomeDrawerItem(
              icon: MdiIcons.whatsapp,
              title: 'تواصل معنا',
              onTap: () async {
                Navigator.pop(context);
                await WhatsAppHelper.launch(context, '01222703436');
              },
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // مشاركة التطبيق
            HomeDrawerItem(
              icon: Icons.share_rounded,
              title: 'مشاركة التطبيق',
              onTap: () {
                Navigator.pop(context);
                ShareAppDialog.show(context);
              },
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // تقييم التطبيق (commented out in original)
            // HomeDrawerItem(
            //   icon: Icons.star_outline_rounded,
            //   title: 'تقييم التطبيق',
            //   onTap: () {
            //     Navigator.pop(context);
            //     RateAppDialog.show(context);
            //   },
            // ),
            //
            // const Divider(height: 1, indent: 16, endIndent: 16),

            // سياسة الخصوصية
            HomeDrawerItem(
              icon: Icons.privacy_tip_outlined,
              title: 'سياسة الخصوصية',
              onTap: () {
                Navigator.pop(context);
                PrivacyPolicyDialog.show(context);
              },
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // الشروط والأحكام
            HomeDrawerItem(
              icon: Icons.description_outlined,
              title: 'الشروط والأحكام',
              onTap: () {
                Navigator.pop(context);
                TermsAndConditionsDialog.show(context);
              },
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ),
      ),
    );
  }
}
