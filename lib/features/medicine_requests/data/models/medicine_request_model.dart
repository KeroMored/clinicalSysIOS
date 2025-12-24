import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineMini {
  final String medicineName;
  final String? medicineType;
  final String? quantityUnit;
  final int quantity;
  final String? imageUrl;

  MedicineMini({
    required this.medicineName,
    this.medicineType,
    this.quantityUnit,
    required this.quantity,
    this.imageUrl,
  });

  factory MedicineMini.fromJson(Map<String, dynamic> json) {
    return MedicineMini(
      medicineName: json['medicineName'] ?? '',
      medicineType: json['medicineType'],
      quantityUnit: json['quantityUnit'],
      quantity: json['quantity'] ?? 1,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'medicineType': medicineType,
      'quantityUnit': quantityUnit,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }
}

class MedicineRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  
  // New: support multiple medicines
  final List<MedicineMini> medicines;
  
  // Legacy fields for backward compatibility
  final String? medicineName;
  final String? imageUrl;
  final int? quantity;
  
  final String phoneNumber;
  final String? whatsappNumber;
  final String? notes;
  final DateTime createdAt;
  final String status; // pending, completed, cancelled

  MedicineRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    List<MedicineMini>? medicines,
    this.medicineName,
    this.imageUrl,
    this.quantity,
    required this.phoneNumber,
    this.whatsappNumber,
    this.notes,
    required this.createdAt,
    this.status = 'pending',
  }) : medicines = medicines ?? [];

  // Helper to check if this is old format (single medicine)
  bool get isLegacyFormat => medicineName != null && medicines.isEmpty;
  
  // Helper to get all medicines (handles both old and new format)
  List<MedicineMini> get allMedicines {
    if (medicines.isNotEmpty) return medicines;
    if (medicineName != null) {
      return [
        MedicineMini(
          medicineName: medicineName!,
          quantity: quantity ?? 1,
          imageUrl: imageUrl,
        )
      ];
    }
    return [];
  }

  factory MedicineRequestModel.fromJson(Map<String, dynamic> json) {
    List<MedicineMini> medicinesList = [];
    
    // Check if new format (medicines array)
    if (json['medicines'] != null && json['medicines'] is List) {
      medicinesList = (json['medicines'] as List)
          .map((m) => MedicineMini.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    
    return MedicineRequestModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      medicines: medicinesList,
      medicineName: json['medicineName'],
      imageUrl: json['imageUrl'],
      quantity: json['quantity'],
      phoneNumber: json['phoneNumber'] ?? '',
      whatsappNumber: json['whatsappNumber'],
      notes: json['notes'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
    
    // Add medicines array if present
    if (medicines.isNotEmpty) {
      map['medicines'] = medicines.map((m) => m.toJson()).toList();
    } else {
      // Legacy format
      map['medicineName'] = medicineName;
      map['imageUrl'] = imageUrl;
      map['quantity'] = quantity;
    }
    
    return map;
  }

  MedicineRequestModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? medicineName,
    String? imageUrl,
    int? quantity,
    String? phoneNumber,
    String? whatsappNumber,
    String? notes,
    DateTime? createdAt,
    String? status,
  }) {
    return MedicineRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      medicineName: medicineName ?? this.medicineName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
