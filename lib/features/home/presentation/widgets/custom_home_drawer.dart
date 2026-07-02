import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            Container(
              height: 210,
              decoration: BoxDecoration(color: Color(0xFF0E7787)),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            size: 34,
                            color: Color(0xFF0E7787),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ملوي كيور | Mallawi Cure',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                     // const SizedBox(height: 4),
                      // const Text(
                      //   'خدماتك الصحية في مكان واحد',
                      //   style: TextStyle(
                      //     color: Color.fromRGBO(255, 255, 255, 1),
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // HomeDrawerItem(
            //   icon: Icons.info_outline_rounded,
            //   title: 'من نحن',
            //   onTap: () {
            //     Navigator.pop(context);
            //     AboutAppDialog.show(context);
            //   },
            // ),

            // const Divider(height: 1, indent: 22, endIndent: 22),

            HomeDrawerItem(
              icon: FontAwesomeIcons.whatsapp,
              title: 'تواصل معنا',
              onTap: () async {
                Navigator.pop(context);
                await WhatsAppHelper.launch(context, '01222703436');
              },
            ),

            // const Divider(height: 1, indent: 22, endIndent: 22),

            // HomeDrawerItem(
            //   icon: Icons.share_rounded,
            //   title: 'مشاركة التطبيق',
            //   onTap: () {
            //     Navigator.pop(context);
            //     ShareAppDialog.show(context);
            //   },
            // ),

            const SizedBox(height: 4),
            const Divider(height: 1, indent: 22, endIndent: 22),
            const SizedBox(height: 4),

            HomeDrawerItem(
              icon: Icons.privacy_tip_outlined,
              title: 'سياسة الخصوصية',
              onTap: () {
                Navigator.pop(context);
                PrivacyPolicyDialog.show(context);
              },
            ),

            // const Divider(height: 1, indent: 22, endIndent: 22),

            // HomeDrawerItem(
            //   icon: Icons.description_outlined,
            //   title: 'الشروط والأحكام',
            //   onTap: () {
            //     Navigator.pop(context);
            //     TermsAndConditionsDialog.show(context);
            //   },
            // ),

            const Divider(height: 1, indent: 22, endIndent: 22),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
