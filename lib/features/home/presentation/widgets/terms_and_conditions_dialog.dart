import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TermsAndConditionsDialog extends StatelessWidget {
  const TermsAndConditionsDialog({super.key});

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
              Icons.description_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text('الشروط والأحكام'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'شروط استخدام التطبيق',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF26A69A),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '1️⃣ استخدام الخدمة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'التطبيق مخصص لتسهيل الوصول للخدمات الطبية ولا يغني عن استشارة الطبيب.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              '2️⃣ دقة المعلومات:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'نسعى لتوفير معلومات دقيقة لكننا لا نتحمل مسؤولية أي أخطاء قد تحدث.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              '3️⃣ المسؤولية:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'استخدامك للتطبيق يعني موافقتك على هذه الشروط والأحكام.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
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
        child: TermsAndConditionsDialog(),
      ),
    );
  }
}
