class PharmacyHoursHelper {
  /// Check if pharmacy is currently open based on working hours and holidays
  static bool isPharmacyOpen({
    required String workingHours,
    required String holidays,
  }) {
    try {
      final now = DateTime.now();
      final currentDay = _getArabicDayName(now.weekday);

      print('=== Pharmacy Hours Debug ===');
      print('Current time: ${now.hour}:${now.minute}');
      print('Current day: $currentDay (${now.weekday})');
      print('Working hours string: "$workingHours"');
      print('Holidays string: "$holidays"');

      // Check if today is a holiday
      if (holidays.isNotEmpty) {
        final holidayList = holidays.split(',').map((e) => e.trim()).toList();
        print('Holiday list: $holidayList');
        if (holidayList.contains(currentDay)) {
          print('Result: CLOSED (today is a holiday)');
          return false; // Closed on holidays
        }
      }

      // If no working hours specified, return false (not open)
      if (workingHours.isEmpty) {
        print('Result: CLOSED (no working hours specified)');
        return false;
      }

      // Format 1: Simple "HH:mm-HH:mm" (24-hour format) - e.g., "09:00-22:00"
      if (RegExp(r'^\d{2}:\d{2}-\d{2}:\d{2}$').hasMatch(workingHours.trim())) {
        print('Format detected: Simple 24-hour (HH:mm-HH:mm)');
        final parts = workingHours.split('-');
        final openParts = parts[0].trim().split(':');
        final closeParts = parts[1].trim().split(':');
        
        final openHour = int.parse(openParts[0]);
        final openMinute = int.parse(openParts[1]);
        final closeHour = int.parse(closeParts[0]);
        final closeMinute = int.parse(closeParts[1]);
        
        final openTime = openHour * 60 + openMinute;
        final closeTime = closeHour * 60 + closeMinute;
        final currentMinutes = now.hour * 60 + now.minute;
        
        print('Open: $openHour:$openMinute ($openTime min), Close: $closeHour:$closeMinute ($closeTime min), Current: ${now.hour}:${now.minute} ($currentMinutes min)');
        
        bool isOpen;
        if (closeTime < openTime) {
          // Crosses midnight
          isOpen = currentMinutes >= openTime || currentMinutes <= closeTime;
        } else {
          isOpen = currentMinutes >= openTime && currentMinutes <= closeTime;
        }
        
        print('Result: ${isOpen ? "OPEN" : "CLOSED"}');
        print('===========================');
        return isOpen;
      }

      // Format 2: Arabic with day range "السبت-الخميس: 9:00 ص - 10:00 م"
      print('Format detected: Arabic with day names');
      final hoursList = workingHours.split('\n').where((e) => e.trim().isNotEmpty).toList();
      print('Hours list after split: $hoursList');
      
      // Check if current day is in working days range
      bool isDayInWorkingDays = false;
      String? workingHoursLine;
      
      for (var line in hoursList) {
        print('Checking line: $line');
        
        // Check for day range format "السبت-الخميس"
        if (line.contains('-') && line.contains(':')) {
          final dayRangeMatch = RegExp(r'(السبت|الأحد|الاثنين|الثلاثاء|الأربعاء|الخميس|الجمعة)\s*-\s*(السبت|الأحد|الاثنين|الثلاثاء|الأربعاء|الخميس|الجمعة)\s*:').firstMatch(line);
          
          if (dayRangeMatch != null) {
            final startDay = dayRangeMatch.group(1)!.trim();
            final endDay = dayRangeMatch.group(2)!.trim();
            print('Found day range: $startDay to $endDay');
            
            if (_isDayInRange(currentDay, startDay, endDay)) {
              print('Current day IS in range');
              isDayInWorkingDays = true;
              workingHoursLine = line;
              break;
            } else {
              print('Current day NOT in range');
            }
          }
        } 
        // Check for single day format
        else if (line.contains(currentDay)) {
          print('Found current day in line');
          isDayInWorkingDays = true;
          workingHoursLine = line;
          break;
        }
      }
      
      if (!isDayInWorkingDays || workingHoursLine == null) {
        print('Result: CLOSED (current day not in working days)');
        return false;
      }
      
      print('Processing line: $workingHoursLine');
      
      // Extract time range using regex
      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(ص|م)\s*-\s*(\d{1,2}):(\d{2})\s*(ص|م)').firstMatch(workingHoursLine);
      
      if (timeMatch == null) {
        print('Result: CLOSED (could not parse time)');
        return false;
      }
      
      final openHour = int.parse(timeMatch.group(1)!);
      final openMinute = int.parse(timeMatch.group(2)!);
      final openPeriod = timeMatch.group(3)!;
      
      final closeHour = int.parse(timeMatch.group(4)!);
      final closeMinute = int.parse(timeMatch.group(5)!);
      final closePeriod = timeMatch.group(6)!;
      
      print('Parsed times: Open: $openHour:$openMinute $openPeriod, Close: $closeHour:$closeMinute $closePeriod');
      
      final openTime = _convertTo24Hour(openHour, openMinute, openPeriod);
      final closeTime = _convertTo24Hour(closeHour, closeMinute, closePeriod);
      final currentMinutes = now.hour * 60 + now.minute;
      
      print('Converted to minutes: Open: $openTime, Close: $closeTime, Current: $currentMinutes');
      
      bool isOpen;
      // Handle cases where closing time is after midnight
      if (closeTime < openTime) {
        // e.g., 9 PM - 2 AM
        isOpen = currentMinutes >= openTime || currentMinutes <= closeTime;
        print('Midnight crossover case: $isOpen');
      } else {
        // Normal case: e.g., 9 AM - 10 PM
        isOpen = currentMinutes >= openTime && currentMinutes <= closeTime;
        print('Normal case: $isOpen');
      }
      
      print('Result: ${isOpen ? "OPEN" : "CLOSED"}');
      print('===========================');
      return isOpen;
    } catch (e) {
      print('Error parsing pharmacy hours: $e');
      print('Result: CLOSED (error occurred)');
      return false; // Default to closed on error (safer)
    }
  }

  /// Get closing time string if pharmacy is currently open
  static String? getClosingTime({
    required String workingHours,
    required String holidays,
  }) {
    try {
      final now = DateTime.now();
      final currentDay = _getArabicDayName(now.weekday);

      // Check if today is a holiday
      if (holidays.isNotEmpty) {
        final holidayList = holidays.split(',').map((e) => e.trim()).toList();
        if (holidayList.contains(currentDay)) {
          return null;
        }
      }

      if (workingHours.isEmpty) return null;

      final hoursList = workingHours.split('\n').where((e) => e.trim().isNotEmpty).toList();
      
      for (var line in hoursList) {
        if (line.contains(currentDay)) {
          final timeMatch = RegExp(r'-\s*(\d{1,2}):(\d{2})\s*(ص|م)').firstMatch(line);
          if (timeMatch != null) {
            return '${timeMatch.group(1)}:${timeMatch.group(2)} ${timeMatch.group(3)}';
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting closing time: $e');
      return null;
    }
  }

  /// Get Arabic day name from weekday number (1 = Monday, 7 = Sunday)
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
        return '';
    }
  }

  /// Convert 12-hour format to minutes since midnight
  static int _convertTo24Hour(int hour, int minute, String period) {
    int hour24 = hour;
    
    if (period == 'م' && hour != 12) {
      hour24 = hour + 12;
    } else if (period == 'ص' && hour == 12) {
      hour24 = 0;
    }
    
    return hour24 * 60 + minute;
  }

  /// Check if a day is within a day range (e.g., Saturday to Thursday)
  static bool _isDayInRange(String currentDay, String startDay, String endDay) {
    final daysOrder = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    
    final currentIndex = daysOrder.indexOf(currentDay);
    final startIndex = daysOrder.indexOf(startDay);
    final endIndex = daysOrder.indexOf(endDay);
    
    if (currentIndex == -1 || startIndex == -1 || endIndex == -1) {
      return false;
    }
    
    // Handle wrap-around (e.g., Thursday-Saturday means Thursday, Friday, Saturday)
    if (startIndex <= endIndex) {
      return currentIndex >= startIndex && currentIndex <= endIndex;
    } else {
      // Wrap around (e.g., Friday-Monday)
      return currentIndex >= startIndex || currentIndex <= endIndex;
    }
  }
}
