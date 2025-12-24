import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RateAppDialog extends StatelessWidget {
  const RateAppDialog({super.key});

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
              Icons.star_rounded,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text('تقييم التطبيق'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'هل أعجبك التطبيق؟',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'نسعد بتقييمك وملاحظاتك لتحسين الخدمة المقدمة',
            style: TextStyle(fontSize: 15, height: 1.6),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 32),
              Icon(Icons.star_rounded, color: Colors.amber, size: 32),
              Icon(Icons.star_rounded, color: Colors.amber, size: 32),
              Icon(Icons.star_rounded, color: Colors.amber, size: 32),
              Icon(Icons.star_rounded, color: Colors.amber, size: 32),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لاحقاً'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('شكراً لتقييمك! ⭐'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: const Text('تقييم الآن'),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: RateAppDialog(),
      ),
    );
  }
}
