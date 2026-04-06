import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/gym_model.dart';

class GymWorkingHoursCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, WorkingHours> workingHours;

  const GymWorkingHoursCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.workingHours,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = _getSortedWorkingHoursEntries();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedEntries.map((entry) {
            final day = _getDayName(entry.key);
            final hours = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${hours.openTime} - ${hours.closeTime}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getDayName(String day) {
    const days = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };
    return days[day.toLowerCase()] ?? day;
  }

  List<MapEntry<String, WorkingHours>> _getSortedWorkingHoursEntries() {
    const weekOrder = [
      'saturday',
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
    ];

    final dayAlias = {
      'saturday': 'saturday',
      'sat': 'saturday',
      'السبت': 'saturday',
      'sunday': 'sunday',
      'sun': 'sunday',
      'الاحد': 'sunday',
      'الأحد': 'sunday',
      'monday': 'monday',
      'mon': 'monday',
      'الاثنين': 'monday',
      'الإثنين': 'monday',
      'tuesday': 'tuesday',
      'tue': 'tuesday',
      'الثلاثاء': 'tuesday',
      'wednesday': 'wednesday',
      'wed': 'wednesday',
      'الاربعاء': 'wednesday',
      'الأربعاء': 'wednesday',
      'thursday': 'thursday',
      'thu': 'thursday',
      'الخميس': 'thursday',
      'friday': 'friday',
      'fri': 'friday',
      'الجمعة': 'friday',
    };

    final entries = workingHours.entries.toList();
    entries.sort((a, b) {
      final normalizedA =
          dayAlias[a.key.trim().toLowerCase()] ?? a.key.trim().toLowerCase();
      final normalizedB =
          dayAlias[b.key.trim().toLowerCase()] ?? b.key.trim().toLowerCase();

      final indexA = weekOrder.indexOf(normalizedA);
      final indexB = weekOrder.indexOf(normalizedB);

      if (indexA == -1 && indexB == -1) {
        return normalizedA.compareTo(normalizedB);
      }
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });

    return entries;
  }
}
