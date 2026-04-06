import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionSettingsModel {
  final String id;
  final double monthlyPrice;
  final double yearlyPrice;
  final DateTime updatedAt;

  SubscriptionSettingsModel({
    required this.id,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.updatedAt,
  });

  factory SubscriptionSettingsModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionSettingsModel(
      id: map['id'] ?? 'settings',
      monthlyPrice: (map['monthlyPrice'] ?? 0).toDouble(),
      yearlyPrice: (map['yearlyPrice'] ?? 0).toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SubscriptionSettingsModel copyWith({
    String? id,
    double? monthlyPrice,
    double? yearlyPrice,
    DateTime? updatedAt,
  }) {
    return SubscriptionSettingsModel(
      id: id ?? this.id,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Default settings
  static SubscriptionSettingsModel get defaultSettings =>
      SubscriptionSettingsModel(
        id: 'settings',
        monthlyPrice: 100.0,
        yearlyPrice: 1000.0,
        updatedAt: DateTime.now(),
      );
}
