class WorkingHours {
  final String openTime;
  final String closeTime;
  final bool isHoliday;

  WorkingHours({
    required this.openTime,
    required this.closeTime,
    this.isHoliday = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'openTime': openTime,
      'closeTime': closeTime,
      'isHoliday': isHoliday,
    };
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      openTime: map['openTime'] ?? '09:00',
      closeTime: map['closeTime'] ?? '17:00',
      isHoliday: map['isHoliday'] ?? false,
    );
  }

  WorkingHours copyWith({
    String? openTime,
    String? closeTime,
    bool? isHoliday,
  }) {
    return WorkingHours(
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isHoliday: isHoliday ?? this.isHoliday,
    );
  }
}
