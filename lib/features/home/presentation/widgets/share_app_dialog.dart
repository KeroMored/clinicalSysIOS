import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';

class ShareAppDialog extends StatelessWidget {
  const ShareAppDialog({super.key});

  static const String appLink =
      'https://play.google.com/store/apps/details?id=com.mored.mallawycare';

  static String get shareMessage =>
      '''
🏥 النظام الطبي المتكامل لملوي 🏥

اكتشف أفضل تطبيق طبي في ملوي!
✅ صيدليات
✅ عيادات
✅ مختبرات تحاليل
✅ مراكز أشعة
✅ صالات رياضية
✅ مراكز تأهيل
✅ تمريض منزلي
✅ خدمة توصيل

📲 حمل التطبيق الآن:
$appLink

🍎 قريباً على App Store
''';

  void _shareApp() {
    Share.share(shareMessage, subject: 'النظام الطبي المتكامل - ملوي');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text('مشاركة التطبيق'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'شارك التطبيق مع أصدقائك وعائلتك للاستفادة من جميع الخدمات الطبية في مكان واحد!',
            style: TextStyle(fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.secondaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📱 النظام الطبي المتكامل',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF26A69A),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '✅ صيدليات وعيادات\n✅ مختبرات وأشعة\n✅ صالات رياضية\n✅ تمريض منزلي',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                SizedBox(height: 8),
                Text(
                  '🍎 قريباً على App Store',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _shareApp();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.share, size: 18),
          label: const Text('مشاركة'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: ShareAppDialog(),
      ),
    );
  }
}
