import 'package:cloud_firestore/cloud_firestore.dart';

class NearExpireItemModel {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyAddress;
  final List<String> pharmacyPhones;
  final String pharmacyWhatsapp;
  final String medicineName;
  final String medicineType; // نوع الدواء (أقراص، شراب، إلخ)
  final String? medicineDescription;
  final DateTime expiryDate;
  final int quantity;
  final double? totalPrice; // السعر الكلي (اختياري)
  final String? imageUrl;
  final DateTime createdAt;
  final bool isActive;
  final String userId; // معرف الصيدلي الذي أضاف العنصر

  NearExpireItemModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyPhones,
    required this.pharmacyWhatsapp,
    required this.medicineName,
    required this.medicineType,
    this.medicineDescription,
    required this.expiryDate,
    required this.quantity,
    this.totalPrice,
    this.imageUrl,
    required this.createdAt,
    this.isActive = true,
    required this.userId,
  });

  factory NearExpireItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NearExpireItemModel(
      id: doc.id,
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      pharmacyAddress: data['pharmacyAddress'] ?? '',
      pharmacyPhones: List<String>.from(data['pharmacyPhones'] ?? []),
      pharmacyWhatsapp: data['pharmacyWhatsapp'] ?? '',
      medicineName: data['medicineName'] ?? '',
      medicineType: data['medicineType'] ?? 'غير محدد',
      medicineDescription: data['medicineDescription'],
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      quantity: data['quantity'] ?? 0,
      totalPrice: data['totalPrice'] != null ? (data['totalPrice'] as num).toDouble() : null,
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'pharmacyPhones': pharmacyPhones,
      'pharmacyWhatsapp': pharmacyWhatsapp,
      'medicineName': medicineName,
      'medicineType': medicineType,
      'medicineDescription': medicineDescription,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'quantity': quantity,
      'totalPrice': totalPrice,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'userId': userId,
    };
  }

  // حساب سعر العبوة الواحدة
  double? get unitPrice {
    if (totalPrice == null || quantity == 0) return null;
    return totalPrice! / quantity;
  }

  // الحصول على نص سعر العبوة الواحدة للعرض
  String get unitPriceText {
    final price = unitPrice;
    if (price == null) return 'غير محدد';
    return '${price.toStringAsFixed(2)} جنيه للعبوة';
  }

  // حساب عدد الأيام المتبقية حتى الانتهاء
  int get daysUntilExpiry {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  // التحقق من أن المنتج قريب من الانتهاء (أقل من 3 أشهر)
  bool get isNearExpiry {
    return daysUntilExpiry <= 90 && daysUntilExpiry > 0;
  }

  // حساب عدد الأشهر المتبقية
  int get monthsUntilExpiry {
    final now = DateTime.now();
    return (expiryDate.year - now.year) * 12 + (expiryDate.month - now.month);
  }
}
