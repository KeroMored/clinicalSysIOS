import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة إدارة إعدادات التطبيق من Firestore
///
/// تدير مجموعة app_control التي تحتوي على:
/// - offers_settings: إعدادات خاصة بالعروض
///   - showViewsCount: إظهار/إخفاء عدد المشاهدات
class AppControlService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // مسارات المجموعة والوثيقة
  static const String _controlCollection = 'app_control';
  static const String _offersSettingsDoc = 'offers_settings';

  /// جلب إعدادات العروض من Firestore كـ Stream
  /// يتيح التحديث الفوري عند تغيير الإعدادات
  Stream<OffersSettings> getOffersSettingsStream() {
    return _firestore
        .collection(_controlCollection)
        .doc(_offersSettingsDoc)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            // إذا الوثيقة غير موجودة، إرجاع الإعدادات الافتراضية
            return OffersSettings.defaultSettings();
          }

          final data = doc.data() as Map<String, dynamic>;
          return OffersSettings.fromMap(data);
        });
  }

  /// جلب إعدادات العروض من Firestore كـ Future (مرة واحدة)
  Future<OffersSettings> getOffersSettings() async {
    try {
      final doc = await _firestore
          .collection(_controlCollection)
          .doc(_offersSettingsDoc)
          .get();

      if (!doc.exists) {
        // إذا الوثيقة غير موجودة، إرجاع الإعدادات الافتراضية
        return OffersSettings.defaultSettings();
      }

      final data = doc.data() as Map<String, dynamic>;
      return OffersSettings.fromMap(data);
    } catch (e) {
      // في حالة الخطأ، إرجاع الإعدادات الافتراضية
      return OffersSettings.defaultSettings();
    }
  }

  /// تحديث إعداد showViewsCount
  /// [show] - true لإظهار عدد المشاهدات، false لإخفائها
  Future<void> updateShowViewsCount(bool show) async {
    try {
      await _firestore
          .collection(_controlCollection)
          .doc(_offersSettingsDoc)
          .set({
            'showViewsCount': show,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('فشل في تحديث إعدادات العروض: $e');
    }
  }

  /// إنشاء الوثيقة مع القيم الافتراضية (للمرة الأولى)
  Future<void> initializeOffersSettings() async {
    try {
      final doc = await _firestore
          .collection(_controlCollection)
          .doc(_offersSettingsDoc)
          .get();

      if (!doc.exists) {
        await _firestore
            .collection(_controlCollection)
            .doc(_offersSettingsDoc)
            .set({
              'showViewsCount': false, // القيمة الافتراضية
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      throw Exception('فشل في تهيئة إعدادات العروض: $e');
    }
  }
}

/// فئة إعدادات العروض
class OffersSettings {
  /// إظهار عدد المشاهدات في واجهة المستخدم
  final bool showViewsCount;

  const OffersSettings({required this.showViewsCount});

  /// الإعدادات الافتراضية
  factory OffersSettings.defaultSettings() {
    return const OffersSettings(
      showViewsCount: false, // مخفي بشكل افتراضي
    );
  }

  /// تحويل من Map (Firestore)
  factory OffersSettings.fromMap(Map<String, dynamic> map) {
    return OffersSettings(showViewsCount: map['showViewsCount'] ?? false);
  }

  /// تحويل إلى Map (Firestore)
  Map<String, dynamic> toMap() {
    return {'showViewsCount': showViewsCount};
  }

  /// نسخ مع تعديل بعض القيم
  OffersSettings copyWith({bool? showViewsCount}) {
    return OffersSettings(
      showViewsCount: showViewsCount ?? this.showViewsCount,
    );
  }
}
