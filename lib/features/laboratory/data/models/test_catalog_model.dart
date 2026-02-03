import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج كتالوج التحاليل - كل تحليل وسعره ومعلوماته
class TestCatalogModel {
  final String id;
  final String laboratoryId; // معرف المعمل
  final String testName; // اسم التحليل
  final String? testNameEn; // الاسم بالإنجليزي (اختياري)
  final String category; // تصنيف التحليل (دم، بول، براز، إلخ)
  final double price; // السعر
  final double? discountedPrice; // السعر بعد الخصم (اختياري)
  final int? discountPercentage; // نسبة الخصم
  final String duration; // مدة ظهور النتيجة (مثل: "2 ساعة", "24 ساعة")
  final int durationInHours; // المدة بالساعات للحساب
  final String? requirements; // متطلبات التحليل (صيام، إلخ)
  final String? description; // وصف التحليل
  final bool isAvailable; // متاح حالياً أم لا
  final bool isPopular; // تحليل شائع/مشهور
  final int orderCount; // عدد مرات طلب التحليل (للترتيب)
  final List<String>? relatedTests; // تحاليل ذات صلة (IDs)
  final double? homeVisitFee; // رسوم الزيارة المنزلية (اختياري)
  final DateTime createdAt;
  final DateTime? updatedAt;

  TestCatalogModel({
    required this.id,
    required this.laboratoryId,
    required this.testName,
    this.testNameEn,
    required this.category,
    required this.price,
    this.discountedPrice,
    this.discountPercentage,
    required this.duration,
    required this.durationInHours,
    this.requirements,
    this.description,
    this.isAvailable = true,
    this.isPopular = false,
    this.orderCount = 0,
    this.relatedTests,
    this.homeVisitFee,
    required this.createdAt,
    this.updatedAt,
  });

  // Getter for name (alias for testName)
  String get name => testName;

  // السعر النهائي بعد الخصم
  double get finalPrice => discountedPrice ?? price;

  // هل يوجد خصم؟
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'laboratoryId': laboratoryId,
      'testName': testName,
      'testNameEn': testNameEn,
      'category': category,
      'price': price,
      'discountedPrice': discountedPrice,
      'discountPercentage': discountPercentage,
      'duration': duration,
      'durationInHours': durationInHours,
      'requirements': requirements,
      'description': description,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'orderCount': orderCount,
      'relatedTests': relatedTests,
      'homeVisitFee': homeVisitFee,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore
  factory TestCatalogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TestCatalogModel(
      id: doc.id,
      laboratoryId: data['laboratoryId'] ?? '',
      testName: data['testName'] ?? '',
      testNameEn: data['testNameEn'],
      category: data['category'] ?? 'عام',
      price: (data['price'] ?? 0.0).toDouble(),
      discountedPrice: data['discountedPrice']?.toDouble(),
      discountPercentage: data['discountPercentage'],
      duration: data['duration'] ?? '',
      durationInHours: data['durationInHours'] ?? 24,
      requirements: data['requirements'],
      description: data['description'],
      isAvailable: data['isAvailable'] ?? true,
      isPopular: data['isPopular'] ?? false,
      orderCount: data['orderCount'] ?? 0,
      relatedTests: data['relatedTests'] != null
          ? List<String>.from(data['relatedTests'])
          : null,
      homeVisitFee: data['homeVisitFee']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method
  TestCatalogModel copyWith({
    String? id,
    String? laboratoryId,
    String? testName,
    String? testNameEn,
    String? category,
    double? price,
    double? discountedPrice,
    int? discountPercentage,
    String? duration,
    int? durationInHours,
    String? requirements,
    String? description,
    bool? isAvailable,
    bool? isPopular,
    int? orderCount,
    List<String>? relatedTests,
    double? homeVisitFee,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TestCatalogModel(
      id: id ?? this.id,
      laboratoryId: laboratoryId ?? this.laboratoryId,
      testName: testName ?? this.testName,
      testNameEn: testNameEn ?? this.testNameEn,
      category: category ?? this.category,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      duration: duration ?? this.duration,
      durationInHours: durationInHours ?? this.durationInHours,
      requirements: requirements ?? this.requirements,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      isPopular: isPopular ?? this.isPopular,
      orderCount: orderCount ?? this.orderCount,
      relatedTests: relatedTests ?? this.relatedTests,
      homeVisitFee: homeVisitFee ?? this.homeVisitFee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// باقة التحاليل - مجموعة تحاليل بسعر مخفض
class TestPackageModel {
  final String id;
  final String laboratoryId;
  final String packageName; // اسم الباقة
  final String? packageNameEn;
  final String description; // وصف الباقة
  final List<String> testIds; // IDs التحاليل في الباقة
  final List<String> testNames; // أسماء التحاليل (للعرض)
  final double originalPrice; // السعر الأصلي لو اشتراهم فردي
  final double packagePrice; // سعر الباقة المخفض
  final int discountPercentage; // نسبة الخصم
  final bool isAvailable;
  final bool isFeatured; // باقة مميزة
  final String? imageUrl; // صورة الباقة
  final int orderCount; // عدد مرات الطلب
  final DateTime createdAt;
  final DateTime? updatedAt;

  TestPackageModel({
    required this.id,
    required this.laboratoryId,
    required this.packageName,
    this.packageNameEn,
    required this.description,
    required this.testIds,
    required this.testNames,
    required this.originalPrice,
    required this.packagePrice,
    required this.discountPercentage,
    this.isAvailable = true,
    this.isFeatured = false,
    this.imageUrl,
    this.orderCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // المبلغ الموفر
  double get savedAmount => originalPrice - packagePrice;

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'laboratoryId': laboratoryId,
      'packageName': packageName,
      'packageNameEn': packageNameEn,
      'description': description,
      'testIds': testIds,
      'testNames': testNames,
      'originalPrice': originalPrice,
      'packagePrice': packagePrice,
      'discountPercentage': discountPercentage,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'imageUrl': imageUrl,
      'orderCount': orderCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore
  factory TestPackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TestPackageModel(
      id: doc.id,
      laboratoryId: data['laboratoryId'] ?? '',
      packageName: data['packageName'] ?? '',
      packageNameEn: data['packageNameEn'],
      description: data['description'] ?? '',
      testIds: List<String>.from(data['testIds'] ?? []),
      testNames: List<String>.from(data['testNames'] ?? []),
      originalPrice: (data['originalPrice'] ?? 0.0).toDouble(),
      packagePrice: (data['packagePrice'] ?? 0.0).toDouble(),
      discountPercentage: data['discountPercentage'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      imageUrl: data['imageUrl'],
      orderCount: data['orderCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  TestPackageModel copyWith({
    String? id,
    String? laboratoryId,
    String? packageName,
    String? packageNameEn,
    String? description,
    List<String>? testIds,
    List<String>? testNames,
    double? originalPrice,
    double? packagePrice,
    int? discountPercentage,
    bool? isAvailable,
    bool? isFeatured,
    String? imageUrl,
    int? orderCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TestPackageModel(
      id: id ?? this.id,
      laboratoryId: laboratoryId ?? this.laboratoryId,
      packageName: packageName ?? this.packageName,
      packageNameEn: packageNameEn ?? this.packageNameEn,
      description: description ?? this.description,
      testIds: testIds ?? this.testIds,
      testNames: testNames ?? this.testNames,
      originalPrice: originalPrice ?? this.originalPrice,
      packagePrice: packagePrice ?? this.packagePrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      imageUrl: imageUrl ?? this.imageUrl,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
