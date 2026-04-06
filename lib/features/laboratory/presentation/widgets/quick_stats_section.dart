import 'package:flutter/material.dart';
import '../../data/models/laboratory_model.dart';
import 'stat_card.dart';

class QuickStatsSection extends StatelessWidget {
  final LaboratoryModel laboratory;

  const QuickStatsSection({super.key, required this.laboratory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'إحصائيات سريعة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            StatCard(
              icon: Icons.biotech,
              value: '${laboratory.availableTests.length}',
              label: 'تحليل متاح',
              color: Colors.green,
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.home,
                value: laboratory.hasHomeService ? 'متاح' : 'غير متاح',
                label: 'خدمة منزلية',
                color: laboratory.hasHomeService ? Colors.blue : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: laboratory.isVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                value: laboratory.isVisible ? 'ظاهر' : 'مخفي',
                label: 'حالة العرض',
                color: laboratory.isVisible ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
