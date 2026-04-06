import 'package:cloud_firestore/cloud_firestore.dart';

enum PlaceType {
  clinic,
  pharmacy,
  laboratory,
  radiology,
  nursing,
  delivery,
  rehabilitation,
  gym,
}

extension PlaceTypeExtension on PlaceType {
  String get arabicName {
    switch (this) {
      case PlaceType.clinic:
        return 'عيادة';
      case PlaceType.pharmacy:
        return 'صيدلية';
      case PlaceType.laboratory:
        return 'معمل تحاليل';
      case PlaceType.radiology:
        return 'مركز أشعة';
      case PlaceType.nursing:
        return 'تمريض منزلي';
      case PlaceType.delivery:
        return 'ديليفري';
      case PlaceType.rehabilitation:
        return 'مركز تأهيل';
      case PlaceType.gym:
        return 'صالة رياضية';
    }
  }

  String get collectionName {
    switch (this) {
      case PlaceType.clinic:
        return 'clinics';
      case PlaceType.pharmacy:
        return 'pharmacies';
      case PlaceType.laboratory:
        return 'laboratories';
      case PlaceType.radiology:
        return 'radiology_centers';
      case PlaceType.nursing:
        return 'nurses';
      case PlaceType.delivery:
        return 'deliveries';
      case PlaceType.rehabilitation:
        return 'rehabilitation_centers';
      case PlaceType.gym:
        return 'gyms';
    }
  }

  String get englishName => name;

  static PlaceType fromString(String value) {
    return PlaceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PlaceType.clinic,
    );
  }
}

class SubscribedPlaceModel {
  final String id;
  final String placeId;
  final PlaceType placeType;
  final String placeName;
  final String ownerName;
  final String phone;
  final String? email;
  final String? address;
  final String? governorate;
  final String? city;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastPaymentDate;
  final DateTime? subscriptionEndDate;
  final String notes;
  final double totalPaid;
  final int paymentCount;

  SubscribedPlaceModel({
    required this.id,
    required this.placeId,
    required this.placeType,
    required this.placeName,
    required this.ownerName,
    required this.phone,
    this.email,
    this.address,
    this.governorate,
    this.city,
    this.isActive = true,
    required this.createdAt,
    this.lastPaymentDate,
    this.subscriptionEndDate,
    this.notes = '',
    this.totalPaid = 0,
    this.paymentCount = 0,
  });

  factory SubscribedPlaceModel.fromMap(Map<String, dynamic> map, String docId) {
    return SubscribedPlaceModel(
      id: docId,
      placeId: map['placeId'] ?? '',
      placeType: PlaceTypeExtension.fromString(map['placeType'] ?? 'clinic'),
      placeName: map['placeName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'],
      governorate: map['governorate'],
      city: map['city'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPaymentDate: (map['lastPaymentDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate: (map['subscriptionEndDate'] as Timestamp?)?.toDate(),
      notes: map['notes'] ?? '',
      totalPaid: (map['totalPaid'] ?? 0).toDouble(),
      paymentCount: map['paymentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'placeType': placeType.englishName,
      'placeName': placeName,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'governorate': governorate,
      'city': city,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastPaymentDate': lastPaymentDate != null
          ? Timestamp.fromDate(lastPaymentDate!)
          : null,
      'subscriptionEndDate': subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null,
      'notes': notes,
      'totalPaid': totalPaid,
      'paymentCount': paymentCount,
    };
  }

  SubscribedPlaceModel copyWith({
    String? id,
    String? placeId,
    PlaceType? placeType,
    String? placeName,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? governorate,
    String? city,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastPaymentDate,
    DateTime? subscriptionEndDate,
    String? notes,
    double? totalPaid,
    int? paymentCount,
  }) {
    return SubscribedPlaceModel(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      placeType: placeType ?? this.placeType,
      placeName: placeName ?? this.placeName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      notes: notes ?? this.notes,
      totalPaid: totalPaid ?? this.totalPaid,
      paymentCount: paymentCount ?? this.paymentCount,
    );
  }

  // Check if subscription is expired
  bool get isSubscriptionExpired {
    if (subscriptionEndDate == null) return true;
    return DateTime.now().isAfter(subscriptionEndDate!);
  }

  // Get subscription status
  String get subscriptionStatus {
    if (subscriptionEndDate == null) return 'غير مشترك';
    if (isSubscriptionExpired) return 'منتهي';
    final daysLeft = subscriptionEndDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 7) return 'ينتهي قريباً';
    return 'فعال';
  }
}
