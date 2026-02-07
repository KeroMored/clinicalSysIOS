import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyRequestModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String whatsapp;
  final double latitude;
  final double longitude;
  final String workingHours;
  final String holidays;
  final List<String> images;
  final bool hasHomeDelivery;
  final double? deliveryFee;
  final double? minimumOrderForDelivery;
  final List<String> services;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestDate;
  final String? rejectionReason;
  
  // معلومات مقدم الطلب
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail; // البريد الإلكتروني للمصادقة
  
  // Insurance
  final bool hasInsurance;
  final List<String> insuranceCompanies;
  
  final String? description;

  PharmacyRequestModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.latitude,
    required this.longitude,
    required this.workingHours,
    required this.holidays,
    required this.images,
    required this.hasHomeDelivery,
    this.deliveryFee,
    this.minimumOrderForDelivery,
    this.services = const [],
    this.status = 'pending',
    required this.requestDate,
    this.rejectionReason,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    this.hasInsurance = false,
    this.insuranceCompanies = const [],
    this.description,
  });

  factory PharmacyRequestModel.fromJson(Map<String, dynamic> json) {
    return PharmacyRequestModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      workingHours: json['workingHours'] ?? '',
      holidays: json['holidays'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      hasHomeDelivery: json['hasHomeDelivery'] ?? false,
      deliveryFee: json['deliveryFee']?.toDouble(),
      minimumOrderForDelivery: json['minimumOrderForDelivery']?.toDouble(),
      services: List<String>.from(json['services'] ?? []),
      status: json['status'] ?? 'pending',
      requestDate: json['requestDate'] is Timestamp
          ? (json['requestDate'] as Timestamp).toDate()
          : DateTime.parse(json['requestDate']),
      rejectionReason: json['rejectionReason'],
      ownerName: json['ownerName'] ?? '',
      ownerPhone: json['ownerPhone'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      hasInsurance: json['hasInsurance'] ?? false,
      insuranceCompanies: json['insuranceCompanies'] != null
          ? List<String>.from(json['insuranceCompanies'])
          : [],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'latitude': latitude,
      'longitude': longitude,
      'workingHours': workingHours,
      'holidays': holidays,
      'images': images,
      'hasHomeDelivery': hasHomeDelivery,
      'deliveryFee': deliveryFee,
      'minimumOrderForDelivery': minimumOrderForDelivery,
      'services': services,
      'status': status,
      'requestDate': Timestamp.fromDate(requestDate),
      'rejectionReason': rejectionReason,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerEmail': ownerEmail,
      'hasInsurance': hasInsurance,
      'insuranceCompanies': insuranceCompanies,
      'description': description,
    };
  }

  PharmacyRequestModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? whatsapp,
    double? latitude,
    double? longitude,
    String? workingHours,
    String? holidays,
    List<String>? images,
    bool? hasHomeDelivery,
    double? deliveryFee,
    double? minimumOrderForDelivery,
    List<String>? services,
    String? status,
    DateTime? requestDate,
    String? rejectionReason,
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    bool? hasInsurance,
    List<String>? insuranceCompanies,
    String? description,
  }) {
    return PharmacyRequestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      workingHours: workingHours ?? this.workingHours,
      holidays: holidays ?? this.holidays,
      images: images ?? this.images,
      hasHomeDelivery: hasHomeDelivery ?? this.hasHomeDelivery,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrderForDelivery:
          minimumOrderForDelivery ?? this.minimumOrderForDelivery,
      services: services ?? this.services,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      hasInsurance: hasInsurance ?? this.hasInsurance,
      insuranceCompanies: insuranceCompanies ?? this.insuranceCompanies,
      description: description ?? this.description,
    );
  }
}
