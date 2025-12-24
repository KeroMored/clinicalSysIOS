import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text('من نحن'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'النظام الطبي المتكامل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF26A69A),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'منصة شاملة تجمع كافة الخدمات الطبية في مكان واحد، لتسهيل الوصول إلى العيادات والصيدليات والمعامل ومراكز الأشعة والممرضين والتأهيل والجيم.',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            SizedBox(height: 16),
            Text(
              '📍 خدماتنا تشمل:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('• العيادات الطبية المتخصصة', style: TextStyle(fontSize: 14)),
            Text('• الصيدليات', style: TextStyle(fontSize: 14)),
            Text('• المعامل الطبية', style: TextStyle(fontSize: 14)),
            Text('• مراكز الأشعة', style: TextStyle(fontSize: 14)),
            Text('• خدمات التمريض المنزلي', style: TextStyle(fontSize: 14)),
            Text('• خدمات التوصيل الطبي', style: TextStyle(fontSize: 14)),
            Text('• مراكز التأهيل', style: TextStyle(fontSize: 14)),
            Text('• الصالات الرياضية', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: AboutAppDialog(),
      ),
    );
  }
}
