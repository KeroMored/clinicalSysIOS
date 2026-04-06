class DailyActivityModel {
  final String dateKey; // yyyy-MM-dd
  final int steps;
  final double meters;
  final DateTime updatedAt;

  const DailyActivityModel({
    required this.dateKey,
    required this.steps,
    required this.meters,
    required this.updatedAt,
  });

  DailyActivityModel copyWith({
    String? dateKey,
    int? steps,
    double? meters,
    DateTime? updatedAt,
  }) {
    return DailyActivityModel(
      dateKey: dateKey ?? this.dateKey,
      steps: steps ?? this.steps,
      meters: meters ?? this.meters,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'steps': steps,
      'meters': meters,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
      'performanceLabel': performanceLabel,
    };
  }

  factory DailyActivityModel.fromJson(Map<String, dynamic> json) {
    return DailyActivityModel(
      dateKey: json['dateKey'] as String? ?? '',
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      meters: (json['meters'] as num?)?.toDouble() ?? 0.0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAtMs'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  String get performanceLabel {
    if (steps < 2000) return 'اداء سيء جدا';
    if (steps < 5000) return 'اداء ضعيف';
    if (steps < 8000) return 'اداء متوسط';
    if (steps < 12000) return 'اداء جيد جدا';
    return 'اداء ممتاز';
  }

  bool get isTopPerformanceLevel => steps >= 12000;

  int get currentLevelFloor {
    if (steps < 2000) return 0;
    if (steps < 5000) return 2000;
    if (steps < 8000) return 5000;
    if (steps < 12000) return 8000;
    return 12000;
  }

  int? get nextLevelTarget {
    if (steps < 2000) return 2000;
    if (steps < 5000) return 5000;
    if (steps < 8000) return 8000;
    if (steps < 12000) return 12000;
    return null;
  }

  String get nextPerformanceLabel {
    if (steps < 2000) return 'اداء ضعيف';
    if (steps < 5000) return 'اداء متوسط';
    if (steps < 8000) return 'اداء جيد جدا';
    return 'اداء ممتاز';
  }

  int get remainingStepsToNextLevel {
    final target = nextLevelTarget;
    if (target == null) return 0;
    return (target - steps).clamp(0, 999999);
  }

  double get progressToNextLevel {
    if (isTopPerformanceLevel) return 1.0;

    final start = currentLevelFloor;
    final target = nextLevelTarget;
    if (target == null || target <= start) return 1.0;

    return ((steps - start) / (target - start)).clamp(0.0, 1.0).toDouble();
  }

  static String buildDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
