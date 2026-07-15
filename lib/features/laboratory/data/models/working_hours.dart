class TimeSlot {
  final String from;
  final String to;

  TimeSlot({required this.from, required this.to});

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(from: map['from'] ?? '09:00', to: map['to'] ?? '17:00');
  }

  Map<String, dynamic> toMap() {
    return {'from': from, 'to': to};
  }
}

class WorkingHours {
  final List<TimeSlot> slots;
  final bool isHoliday;

  WorkingHours({
    List<TimeSlot>? slots,
    this.isHoliday = false,
  }) : slots = slots ?? [TimeSlot(from: '09:00', to: '17:00')];

  // Legacy properties for backward compatibility
  String get openTime => slots.isNotEmpty ? slots.first.from : '09:00';
  String get closeTime => slots.isNotEmpty ? slots.first.to : '17:00';

  Map<String, dynamic> toMap() {
    return {
      'slots': slots.map((s) => s.toMap()).toList(),
      'isHoliday': isHoliday,
      // Keep old format for backward compatibility
      'openTime': slots.isNotEmpty ? slots.first.from : '09:00',
      'closeTime': slots.isNotEmpty ? slots.first.to : '17:00',
    };
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    List<TimeSlot> parsedSlots = [];
    
    // Support new format with slots
    if (map['slots'] != null && map['slots'] is List) {
      for (var slotMap in map['slots']) {
        parsedSlots.add(TimeSlot.fromMap(slotMap as Map<String, dynamic>));
      }
    }
    // Support old format with openTime/closeTime
    else if (map['openTime'] != null && map['closeTime'] != null) {
      parsedSlots.add(TimeSlot(
        from: map['openTime'],
        to: map['closeTime'],
      ));
    } else {
      parsedSlots.add(TimeSlot(from: '09:00', to: '17:00'));
    }

    return WorkingHours(
      slots: parsedSlots,
      isHoliday: map['isHoliday'] ?? false,
    );
  }

  WorkingHours copyWith({
    List<TimeSlot>? slots,
    bool? isHoliday,
  }) {
    return WorkingHours(
      slots: slots ?? this.slots,
      isHoliday: isHoliday ?? this.isHoliday,
    );
  }
}
