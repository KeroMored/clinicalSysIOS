import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType { monthly, yearly, custom }

extension PaymentTypeExtension on PaymentType {
  String get arabicName {
    switch (this) {
      case PaymentType.monthly:
        return 'شهري';
      case PaymentType.yearly:
        return 'سنوي';
      case PaymentType.custom:
        return 'مخصص';
    }
  }

  static PaymentType fromString(String value) {
    return PaymentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PaymentType.monthly,
    );
  }
}

class PaymentRecordModel {
  final String id;
  final String subscribedPlaceId;
  final double amount;
  final PaymentType paymentType;
  final DateTime paymentDate;
  final DateTime subscriptionStartDate;
  final DateTime subscriptionEndDate;
  final String? notes;
  final String recordedBy;
  final DateTime createdAt;

  PaymentRecordModel({
    required this.id,
    required this.subscribedPlaceId,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
    this.notes,
    required this.recordedBy,
    required this.createdAt,
  });

  factory PaymentRecordModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentRecordModel(
      id: docId,
      subscribedPlaceId: map['subscribedPlaceId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentType: PaymentTypeExtension.fromString(
        map['paymentType'] ?? 'monthly',
      ),
      paymentDate:
          (map['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subscriptionStartDate:
          (map['subscriptionStartDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      subscriptionEndDate:
          (map['subscriptionEndDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      notes: map['notes'],
      recordedBy: map['recordedBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscribedPlaceId': subscribedPlaceId,
      'amount': amount,
      'paymentType': paymentType.name,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'subscriptionStartDate': Timestamp.fromDate(subscriptionStartDate),
      'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate),
      'notes': notes,
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PaymentRecordModel copyWith({
    String? id,
    String? subscribedPlaceId,
    double? amount,
    PaymentType? paymentType,
    DateTime? paymentDate,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    String? notes,
    String? recordedBy,
    DateTime? createdAt,
  }) {
    return PaymentRecordModel(
      id: id ?? this.id,
      subscribedPlaceId: subscribedPlaceId ?? this.subscribedPlaceId,
      amount: amount ?? this.amount,
      paymentType: paymentType ?? this.paymentType,
      paymentDate: paymentDate ?? this.paymentDate,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get duration text
  String get durationText {
    switch (paymentType) {
      case PaymentType.monthly:
        return 'شهر واحد';
      case PaymentType.yearly:
        return 'سنة كاملة';
      case PaymentType.custom:
        final days = subscriptionEndDate
            .difference(subscriptionStartDate)
            .inDays;
        return '$days يوم';
    }
  }
}
