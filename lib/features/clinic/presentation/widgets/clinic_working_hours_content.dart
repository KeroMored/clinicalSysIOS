import 'package:flutter/material.dart';
import '../../data/models/clinic_model.dart';

class ClinicWorkingHoursContent extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _primaryDark = Color(0xFF115E59);

  final Map<String, WorkingHours> workingHours;
  final List<String> holidays;
  final bool isClinicOpenNow;

  const ClinicWorkingHoursContent({
    super.key,
    required this.workingHours,
    this.holidays = const [],
    this.isClinicOpenNow = false,
  });

  String _formatTimeToArabic(String time) {
    if (time == 'مغلق' || time.toLowerCase() == 'closed') return 'مغلق';

    try {
      final cleanTime = time.trim().toUpperCase().replaceAll(
        RegExp(r'[APM\s]+'),
        '',
      );
      final parts = cleanTime.split(':');
      if (parts.isEmpty) return time;

      var hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1] : '00';

      final hasPM = time.toUpperCase().contains('PM');
      final hasAM = time.toUpperCase().contains('AM');

      if (hasPM && hour != 12) {
        hour = hour + 12;
      } else if (hasAM && hour == 12) {
        hour = 0;
      }

      final isMorning = hour < 12;
      final arabicHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final period = isMorning ? 'ص' : 'م';

      return '$arabicHour:$minute $period';
    } catch (_) {
      return time;
    }
  }

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
  }

  bool _isHoliday({required String dayKey, required String arabicDay}) {
    final normalizedKey = _normalize(dayKey);
    final normalizedArabic = _normalize(arabicDay);

    for (final day in holidays) {
      final normalizedDay = _normalize(day);
      if (normalizedDay == normalizedKey || normalizedDay == normalizedArabic) {
        return true;
      }
    }

    return false;
  }

  String _todayDayKey() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
      default:
        return 'sunday';
    }
  }

  @override
  Widget build(BuildContext context) {
    const daysArabic = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };
    final todayDayKey = _todayDayKey();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: _primaryDark,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'مواعيد العمل',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...daysArabic.entries.map((entry) {
            final hours = workingHours[entry.key];
            final isToday = entry.key == todayDayKey;
            final isHoliday = _isHoliday(
              dayKey: entry.key,
              arabicDay: entry.value,
            );
            final isClosed = isHoliday || hours == null || hours.isClosed;

            final timeLabel = isHoliday
                ? 'عطلة رسمية'
                : (isClosed
                      ? 'مغلق'
                      : '${_formatTimeToArabic(hours.from)} - ${_formatTimeToArabic(hours.to)}');

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? _primaryColor.withValues(alpha: 0.35)
                      : const Color(0xFFE5E7EB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? _primaryDark
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  if (isToday && !isClosed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isClinicOpenNow
                            ? _primaryColor
                            : const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isClinicOpenNow ? 'مفتوح الآن' : 'اليوم',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isClosed
                              ? const Color(0xFF6B7280)
                              : _primaryColor,
                        ),
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
}
