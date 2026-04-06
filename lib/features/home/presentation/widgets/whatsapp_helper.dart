import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<void> launch(BuildContext context, String phoneNumber) async {
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = phoneNumber.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص، لو لا ضيف 20
    if (!n.startsWith('20')) n = '20$n';

    final url = Uri.parse('https://wa.me/$n');

    try {
      final canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن فتح الواتساب. تأكد من تثبيت التطبيق'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تطبيق الواتساب غير موجود على جهازك'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
