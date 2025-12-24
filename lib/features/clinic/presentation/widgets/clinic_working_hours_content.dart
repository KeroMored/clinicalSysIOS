import 'package:flutter/material.dart';
import '../../data/models/clinic_model.dart';

class ClinicWorkingHoursContent extends StatelessWidget {
  final Map<String, WorkingHours> workingHours;

  const ClinicWorkingHoursContent({
    super.key,
    required this.workingHours,
  });

  String _formatTimeToArabic(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return time;
      
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      
      String period;
      if (hour == 0) {
        hour = 12;
        period = 'صباحاً';
      } else if (hour < 12) {
        period = 'صباحاً';
      } else if (hour == 12) {
        period = 'مساءً';
      } else {
        hour = hour - 12;
        period = 'مساءً';
      }
      
      if (minute == '00') {
        return '$hour $period';
      }
      return '$hour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };

    return Column(
      children: daysArabic.entries.map((entry) {
        final hours = workingHours[entry.key];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (hours != null && !hours.isClosed)
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (hours != null && !hours.isClosed)
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Text(
                  hours != null && !hours.isClosed
                      ? '${_formatTimeToArabic(hours.from)} - ${_formatTimeToArabic(hours.to)}'
                      : 'مغلق',
                  style: TextStyle(
                    fontSize: 14,
                    color: hours != null && !hours.isClosed
                        ? Colors.green[700]
                        : Colors.red[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
