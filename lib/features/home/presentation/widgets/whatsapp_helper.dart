import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<void> launch(BuildContext context, String phoneNumber) async {
    // Remove leading zero and add country code
    final cleanNumber = phoneNumber.startsWith('0') 
        ? phoneNumber.substring(1) 
        : phoneNumber;
    
    final url = Uri.parse('https://wa.me/+20$cleanNumber');
    
    try {
      final canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
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
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
