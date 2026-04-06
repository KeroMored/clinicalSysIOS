import 'package:cloud_firestore/cloud_firestore.dart';

enum RepeatType { daily, weekly, monthly, specificDays }

extension RepeatTypeExtension on RepeatType {
  String get arabicName {
    switch (this) {
      case RepeatType.daily:
        return 'يومياً';
      case RepeatType.weekly:
        return 'أسبوعياً (يوم واحد)';
      case RepeatType.monthly:
        return 'شهرياً';
      case RepeatType.specificDays:
        return 'أيام محددة (متعددة)';
    }
  }

  String get arabicDescription {
    switch (this) {
      case RepeatType.daily:
        return 'كل يوم';
      case RepeatType.weekly:
        return 'كل أسبوع في يوم محدد (مثلاً كل سبت)';
      case RepeatType.monthly:
        return 'كل شهر في يوم محدد';
      case RepeatType.specificDays:
        return 'أيام معينة من الأسبوع';
    }
  }

  String get englishName {
    return toString().split('.').last;
  }
}

class MedicineModel {
  final String id;
  final String userId;
  final List<String> medicineNames; // Changed to list for multiple names
  final String? imageUrl;
  final RepeatType repeatType;
  final List<String> reminderTimes; // List of times like "09:00", "14:00"
  final List<int>? specificDays; // For weekly: 1=Monday, 7=Sunday
  final int? monthlyDay; // For monthly: 1-31
  final bool isActive;
  final DateTime createdAt;
  final String? notes;

  MedicineModel({
    required this.id,
    required this.userId,
    List<String>? medicineNames,
    this.imageUrl,
    required this.repeatType,
    required this.reminderTimes,
    this.specificDays,
    this.monthlyDay,
    this.isActive = true,
    required this.createdAt,
    this.notes,
  }) : medicineNames = medicineNames ?? [];

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'medicineNames': medicineNames,
      'imageUrl': imageUrl,
      'repeatType': repeatType.englishName,
      'reminderTimes': reminderTimes,
      'specificDays': specificDays,
      'monthlyDay': monthlyDay,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }

  // Create from Firestore document
  factory MedicineModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle legacy data with single medicineName
    List<String> names = [];
    try {
      if (map['medicineNames'] != null) {
        // New format - list of names
        names = List<String>.from(map['medicineNames']);
      } else if (map['medicineName'] != null &&
          map['medicineName'].toString().isNotEmpty) {
        // Legacy format - single name
        names = [map['medicineName'].toString()];
      }
    } catch (e) {
      print('Error parsing medicine names: $e');
      // If any error, keep empty list
      names = [];
    }

    return MedicineModel(
      id: id,
      userId: map['userId'] ?? '',
      medicineNames: names,
      imageUrl: map['imageUrl'],
      repeatType: RepeatType.values.firstWhere(
        (e) => e.englishName == map['repeatType'],
        orElse: () => RepeatType.daily,
      ),
      reminderTimes: map['reminderTimes'] != null
          ? List<String>.from(map['reminderTimes'])
          : [],
      specificDays: map['specificDays'] != null
          ? List<int>.from(map['specificDays'])
          : null,
      monthlyDay: map['monthlyDay'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
    );
  }

  // CopyWith for easy updates
  MedicineModel copyWith({
    String? id,
    String? userId,
    List<String>? medicineNames,
    String? imageUrl,
    RepeatType? repeatType,
    List<String>? reminderTimes,
    List<int>? specificDays,
    int? monthlyDay,
    bool? isActive,
    DateTime? createdAt,
    String? notes,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineNames: medicineNames ?? this.medicineNames,
      imageUrl: imageUrl ?? this.imageUrl,
      repeatType: repeatType ?? this.repeatType,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      specificDays: specificDays ?? this.specificDays,
      monthlyDay: monthlyDay ?? this.monthlyDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  // Display name (join all medicine names or use default)
  String get displayName {
    if (medicineNames.isEmpty) return 'الدواء';
    if (medicineNames.length == 1) return medicineNames.first;
    return medicineNames.join(' + ');
  }

  // Check if has valid data
  bool get hasValidData =>
      medicineNames.isNotEmpty || (imageUrl?.isNotEmpty ?? false);

  // Get next reminder time
  DateTime? getNextReminderTime() {
    if (reminderTimes.isEmpty) return null;

    final now = DateTime.now();
    DateTime? nextReminder;

    for (final timeStr in reminderTimes) {
      try {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        var reminderDate = DateTime(now.year, now.month, now.day, hour, minute);

        // If time passed today, schedule for next occurrence
        if (reminderDate.isBefore(now)) {
          switch (repeatType) {
            case RepeatType.daily:
              reminderDate = reminderDate.add(const Duration(days: 1));
              break;
            case RepeatType.weekly:
              reminderDate = reminderDate.add(const Duration(days: 7));
              break;
            case RepeatType.monthly:
              reminderDate = DateTime(
                reminderDate.year,
                reminderDate.month + 1,
                reminderDate.day,
                reminderDate.hour,
                reminderDate.minute,
              );
              break;
            case RepeatType.specificDays:
              // Find next matching day
              if (specificDays != null && specificDays!.isNotEmpty) {
                int daysToAdd = 1;
                while (daysToAdd < 8) {
                  final checkDate = reminderDate.add(Duration(days: daysToAdd));
                  if (specificDays!.contains(checkDate.weekday)) {
                    reminderDate = checkDate;
                    break;
                  }
                  daysToAdd++;
                }
              }
              break;
          }
        }

        if (nextReminder == null || reminderDate.isBefore(nextReminder)) {
          nextReminder = reminderDate;
        }
      } catch (e) {
        continue;
      }
    }

    return nextReminder;
  }
}
