class WorkingHoursHelper {
  /// Calculate if a service is currently open based on working hours map
  ///
  /// [workingHours] Map with day names as keys (e.g., 'saturday', 'sunday')
  /// and WorkingHours objects as values
  /// [holidays] List of holiday names (e.g., ['الجمعة', 'السبت'])
  static bool isServiceOpen({
    required Map<String, dynamic> workingHours,
    List<String>? holidays,
  }) {
    try {
      final now = DateTime.now();
      final currentDayKey = _getEnglishDayKey(now.weekday);
      final currentDayArabic = _getArabicDayName(now.weekday);

      // Debug logging
      print('WorkingHoursHelper Debug:');
      print('  Now: $now');
      print('  Weekday: ${now.weekday}');
      print('  Current Day Key: $currentDayKey');
      print('  Current Day Arabic: $currentDayArabic');
      print('  Available keys in workingHours: ${workingHours.keys.toList()}');
      print('  Holidays: $holidays');

      // Check if today is a holiday
      if (holidays != null && holidays.isNotEmpty) {
        if (holidays.contains(currentDayArabic)) {
          print('  → Today is a holiday!');
          return false;
        }
      }

      // Get working hours for today
      if (!workingHours.containsKey(currentDayKey)) {
        print('  → No working hours for $currentDayKey');
        return false; // No working hours defined for today
      }

      final dayHours = workingHours[currentDayKey];

      // Check if it's a holiday in the working hours
      if (dayHours is Map) {
        // Check for different field names (isHoliday or isClosed)
        final isHoliday = dayHours['isHoliday'] ?? false;
        final isClosed = dayHours['isClosed'] ?? false;
        if (isHoliday || isClosed) return false;

        // Support both formats: openTime/closeTime and from/to
        final openTime = (dayHours['openTime'] ?? dayHours['from']) as String?;
        final closeTime = (dayHours['closeTime'] ?? dayHours['to']) as String?;

        if (openTime == null || closeTime == null) return false;

        // Parse times
        final openMinutes = _parseTime24Hour(openTime);
        final closeMinutes = _parseTime24Hour(closeTime);
        final currentMinutes = now.hour * 60 + now.minute;

        print(
          '  Open: $openTime ($openMinutes min) | Close: $closeTime ($closeMinutes min)',
        );
        print('  Current: ${now.hour}:${now.minute} ($currentMinutes min)');

        // Handle overnight hours (e.g., 22:00 to 02:00)
        if (closeMinutes < openMinutes) {
          final result =
              currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
          print('  → Overnight hours: $result');
          return result;
        }

        // Normal hours
        final result =
            currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
        print('  → Normal hours: $result');
        return result;
      }

      return false;
    } catch (e) {
      // If any error occurs, return false (closed)
      return false;
    }
  }

  /// Get closing time for the current day
  static String? getClosingTime({
    required Map<String, dynamic> workingHours,
    List<String>? holidays,
  }) {
    try {
      final now = DateTime.now();
      final currentDayKey = _getEnglishDayKey(now.weekday);
      final currentDayArabic = _getArabicDayName(now.weekday);

      // Check if today is a holiday
      if (holidays != null && holidays.contains(currentDayArabic)) {
        return null;
      }

      if (!workingHours.containsKey(currentDayKey)) {
        return null;
      }

      final dayHours = workingHours[currentDayKey];
      if (dayHours is Map) {
        final isHoliday = dayHours['isHoliday'] ?? false;
        final isClosed = dayHours['isClosed'] ?? false;
        if (isHoliday || isClosed) return null;

        // Support both formats: closeTime and to
        return (dayHours['closeTime'] ?? dayHours['to']) as String?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert DateTime weekday to English day key (lowercase)
  static String _getEnglishDayKey(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
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
      default:
        return 'saturday';
    }
  }

  /// Convert DateTime weekday to Arabic day name
  static String _getArabicDayName(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return 'السبت';
    }
  }

  /// Parse time string to minutes since midnight
  /// Supports formats: "HH:mm", "H:mm", "HH:mm AM/PM", "H:mm AM/PM"
  static int _parseTime24Hour(String timeStr) {
    try {
      // Handle special cases for closed days
      if (timeStr == 'مغلق' || timeStr.toLowerCase() == 'closed') {
        return 0;
      }

      final cleanStr = timeStr.trim().toUpperCase();
      final isAM = cleanStr.contains('AM') || cleanStr.contains('ص');
      final isPM = cleanStr.contains('PM') || cleanStr.contains('م');

      // Remove AM/PM/ص/م and extra spaces
      final timeOnly = cleanStr
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .replaceAll('ص', '')
          .replaceAll('م', '')
          .trim();

      final parts = timeOnly.split(':');
      if (parts.isEmpty) return 0;

      int hour = int.parse(parts[0].trim());
      final minute = parts.length > 1 ? int.parse(parts[1].trim()) : 0;

      // Convert 12-hour to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }

      return hour * 60 + minute;
    } catch (e) {
      print('  ERROR parsing time "$timeStr": $e');
      return 0;
    }
  }
}
