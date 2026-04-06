import 'package:flutter/material.dart';
import '../../data/models/radiology_model.dart';

class RadiologyWorkingHoursCard extends StatelessWidget {
  final RadiologyModel radiology;

  const RadiologyWorkingHoursCard({super.key, required this.radiology});

  @override
  Widget build(BuildContext context) {
    final daysInArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مواعيد العمل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            ...daysInArabic.entries.map((entry) {
              final hours = radiology.workingHours[entry.key];
              if (hours == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      hours.isHoliday
                          ? 'مغلق'
                          : '${hours.openTime} - ${hours.closeTime}',
                      style: TextStyle(
                        fontSize: 14,
                        color: hours.isHoliday ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
