import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// نموذج العرض الموسمي
class SeasonalOfferModel extends Equatable {
  final String id;
  final String laboratoryId;
  final String title; // عنوان العرض
  final String description;
  final double discountPercentage; // نسبة الخصم
  final DateTime startDate;
  final DateTime endDate;
  final List<String> applicableTestIds; // التحاليل المشمولة في العرض
  final String? bannerImageUrl;
  final bool isActive;
  final int usageCount; // عدد مرات الاستخدام
  final int? maxUsage; // الحد الأقصى للاستخدام
  final String offerType; // ramadan, eid, general, checkup
  final DateTime createdAt;

  const SeasonalOfferModel({
    required this.id,
    required this.laboratoryId,
    required this.title,
    required this.description,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    this.applicableTestIds = const [],
    this.bannerImageUrl,
    this.isActive = true,
    this.usageCount = 0,
    this.maxUsage,
    required this.offerType,
    required this.createdAt,
  });

  /// أنواع العروض
  static const String typeRamadan = 'ramadan';
  static const String typeEid = 'eid';
  static const String typeGeneral = 'general';
  static const String typeCheckup = 'checkup';

  /// هل العرض ساري؟
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        (maxUsage == null || usageCount < maxUsage!);
  }

  /// الأيام المتبقية للعرض
  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }

  factory SeasonalOfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SeasonalOfferModel(
      id: doc.id,
      laboratoryId: data['laboratoryId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      applicableTestIds: data['applicableTestIds'] != null
          ? List<String>.from(data['applicableTestIds'])
          : [],
      bannerImageUrl: data['bannerImageUrl'],
      isActive: data['isActive'] ?? true,
      usageCount: data['usageCount'] ?? 0,
      maxUsage: data['maxUsage'],
      offerType: data['offerType'] ?? typeGeneral,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'laboratoryId': laboratoryId,
      'title': title,
      'description': description,
      'discountPercentage': discountPercentage,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'applicableTestIds': applicableTestIds,
      'bannerImageUrl': bannerImageUrl,
      'isActive': isActive,
      'usageCount': usageCount,
      'maxUsage': maxUsage,
      'offerType': offerType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SeasonalOfferModel copyWith({
    String? id,
    String? laboratoryId,
    String? title,
    String? description,
    double? discountPercentage,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? applicableTestIds,
    String? bannerImageUrl,
    bool? isActive,
    int? usageCount,
    int? maxUsage,
    String? offerType,
    DateTime? createdAt,
  }) {
    return SeasonalOfferModel(
      id: id ?? this.id,
      laboratoryId: laboratoryId ?? this.laboratoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      applicableTestIds: applicableTestIds ?? this.applicableTestIds,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
      maxUsage: maxUsage ?? this.maxUsage,
      offerType: offerType ?? this.offerType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    laboratoryId,
    title,
    description,
    discountPercentage,
    startDate,
    endDate,
    applicableTestIds,
    bannerImageUrl,
    isActive,
    usageCount,
    maxUsage,
    offerType,
    createdAt,
  ];
}

/// باقة تحاليل (Package) - موجودة في test_catalog_model لكن هنا نسخة محسّنة
class EnhancedTestPackageModel extends Equatable {
  final String id;
  final String laboratoryId;
  final String name;
  final String description;
  final List<String> testIds; // قائمة التحاليل في الباقة
  final double originalPrice; // السعر الأصلي لو اشتريت التحاليل منفردة
  final double packagePrice; // سعر الباقة المخفض
  final String? imageUrl;
  final bool isActive;
  final int salesCount; // عدد مرات البيع
  final String category; // checkup, diabetes, heart, general
  final DateTime createdAt;

  const EnhancedTestPackageModel({
    required this.id,
    required this.laboratoryId,
    required this.name,
    required this.description,
    required this.testIds,
    required this.originalPrice,
    required this.packagePrice,
    this.imageUrl,
    this.isActive = true,
    this.salesCount = 0,
    required this.category,
    required this.createdAt,
  });

  /// نسبة الخصم
  double get discountPercentage {
    return ((originalPrice - packagePrice) / originalPrice) * 100;
  }

  /// المبلغ الموفر
  double get savingsAmount {
    return originalPrice - packagePrice;
  }

  factory EnhancedTestPackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnhancedTestPackageModel(
      id: doc.id,
      laboratoryId: data['laboratoryId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      testIds: data['testIds'] != null
          ? List<String>.from(data['testIds'])
          : [],
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      packagePrice: (data['packagePrice'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      salesCount: data['salesCount'] ?? 0,
      category: data['category'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'laboratoryId': laboratoryId,
      'name': name,
      'description': description,
      'testIds': testIds,
      'originalPrice': originalPrice,
      'packagePrice': packagePrice,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'salesCount': salesCount,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
    id,
    laboratoryId,
    name,
    description,
    testIds,
    originalPrice,
    packagePrice,
    imageUrl,
    isActive,
    salesCount,
    category,
    createdAt,
  ];
}
