import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ShareAppDialog extends StatelessWidget {
  const ShareAppDialog({super.key});

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
              Icons.share_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text('مشاركة التطبيق'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'شارك التطبيق مع أصدقائك وعائلتك للاستفادة من جميع الخدمات الطبية في مكان واحد!',
            style: TextStyle(fontSize: 15, height: 1.6),
          ),
          SizedBox(height: 16),
          Text(
            '📱 النظام الطبي المتكامل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF26A69A),
            ),
          ),
        ],
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
        child: ShareAppDialog(),
      ),
    );
  }
}
