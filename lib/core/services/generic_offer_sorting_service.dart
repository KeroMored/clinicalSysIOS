import 'dart:math';

/// واجهة للعروض القابلة للترتيب الديناميكي
/// أي model يريد الاستفادة من نظام الترتيب يجب أن يطبق هذه الواجهة
abstract class ISortableOffer {
  String get id;
  DateTime get createdAt;
  int get viewsCount;
  String get category;
}

/// خدمة الترتيب الديناميكي العامة (Generic)
/// تعمل مع أي نوع من العروض يطبق ISortableOffer
///
/// 🎯 تستخدم خوارزمية تصنيف متعددة العوامل تجمع بين:
/// - **الحداثة (35%)**: أولوية للعروض الأحدث (آخر 24 ساعة = نتيجة عالية)
/// - **التفاعل (25%)**: بناءً على viewsCount (استخدام لوغاريتمي)
/// - **التنوع (20%)**: تجنب تكرار نفس التصنيف
/// - **العشوائية المحكومة (20%)**: تنوع ثابت خلال الجلسة، يتغير عند Refresh
///
/// 📊 أمثلة على النتائج:
/// - عرض عمره 12 ساعة، 50 مشاهدة → نتيجة عالية جداً
/// - عرض عمره 5 أيام، 200 مشاهدة → نتيجة متوسطة-عالية
/// - عرض عمره شهر، 10 مشاهدات → نتيجة منخفضة-متوسطة
class GenericOfferSortingService<T extends ISortableOffer> {
  // بذرة العشوائية تتغير كل جلسة لكن تبقى ثابتة أثناء التصفح
  late final int _sessionSeed;
  late final Random _random;

  // تتبع التصنيفات المستخدمة لضمان التنوع
  final Map<String, int> _categoryUsageCount = {};

  /// المُنشئ - يهيئ بذرة عشوائية جديدة لكل جلسة
  GenericOfferSortingService() {
    _sessionSeed = DateTime.now().millisecondsSinceEpoch;
    _random = Random(_sessionSeed);
  }

  /// ترتيب العروض بنظام التصنيف الديناميكي
  ///
  /// [offers] - قائمة العروض المراد ترتيبها
  /// [pageNumber] - رقم الصفحة الحالية (يبدأ من 0)
  /// [pageSize] - عدد العناصر في كل صفحة
  ///
  /// Returns: قائمة العروض المرتبة للصفحة المطلوبة
  List<T> sortOffers({
    required List<T> offers,
    required int pageNumber,
    required int pageSize,
  }) {
    if (offers.isEmpty) return [];

    // إعادة تعيين بذرة العشوائية لكل صفحة لضمان الاتساق
    final pageRandom = Random(_sessionSeed + pageNumber);

    // حساب النتيجة لكل عرض
    final scoredOffers = offers.map((offer) {
      final score = _calculateScore(offer, pageRandom);
      return _ScoredOffer<T>(offer, score);
    }).toList();

    // ترتيب حسب النتيجة (الأعلى أولاً)
    scoredOffers.sort((a, b) => b.score.compareTo(a.score));

    // حساب المدى للصفحة المطلوبة
    final startIndex = pageNumber * pageSize;
    final endIndex = min(startIndex + pageSize, scoredOffers.length);

    // التأكد من أن المدى صحيح
    if (startIndex >= scoredOffers.length) {
      return [];
    }

    // استخراج العروض للصفحة الحالية
    final pageOffers = scoredOffers
        .sublist(startIndex, endIndex)
        .map((scored) => scored.offer)
        .toList();

    return pageOffers;
  }

  /// حساب النتيجة الإجمالية لعرض واحد بناءً على عدة عوامل
  double _calculateScore(T offer, Random random) {
    // الأوزان - مجموعها = 1.0
    const double recencyWeight = 0.35; // أهمية الحداثة
    const double engagementWeight = 0.25; // أهمية التفاعل
    const double diversityWeight = 0.20; // أهمية التنوع
    const double randomnessWeight = 0.20; // أهمية العشوائية

    // 1. حساب درجة الحداثة (0.0 - 1.0)
    final recencyScore = _calculateRecencyScore(offer.createdAt);

    // 2. حساب درجة التفاعل (0.0 - 1.0)
    final engagementScore = _calculateEngagementScore(offer.viewsCount);

    // 3. حساب تعزيز التنوع (0.0 - 1.0)
    final diversityBoost = _calculateDiversityBoost(offer.category);

    // 4. إضافة عشوائية محكومة (0.0 - 1.0)
    final randomness = random.nextDouble();

    // الحساب النهائي
    final totalScore =
        (recencyScore * recencyWeight) +
        (engagementScore * engagementWeight) +
        (diversityBoost * diversityWeight) +
        (randomness * randomnessWeight);

    return totalScore;
  }

  /// حساب درجة الحداثة بناءً على عمر العرض
  /// العروض الأحدث تحصل على درجات أعلى
  double _calculateRecencyScore(DateTime createdAt) {
    final now = DateTime.now();
    final age = now.difference(createdAt);

    // العروض في آخر 24 ساعة → درجة عالية
    if (age.inHours <= 24) return 1.0;

    // العروض في آخر 3 أيام → درجة متوسطة-عالية
    if (age.inDays <= 3) return 0.8;

    // العروض في آخر أسبوع → درجة متوسطة
    if (age.inDays <= 7) return 0.6;

    // العروض في آخر شهر → درجة منخفضة-متوسطة
    if (age.inDays <= 30) return 0.4;

    // العروض في آخر شهرين → درجة منخفضة
    if (age.inDays <= 60) return 0.2;

    // العروض الأقدم من شهرين → أقل درجة
    return 0.1;
  }

  /// حساب درجة التفاعل بناءً على عدد المشاهدات
  /// استخدام تطبيع لوغاريتمي لتجنب هيمنة العروض عالية المشاهدات
  double _calculateEngagementScore(int viewsCount) {
    if (viewsCount <= 0) return 0.0;

    // استخدام log لتطبيع القيم الكبيرة
    // العروض بـ 1 مشاهدة = 0.0
    // العروض بـ 10 مشاهدات ≈ 0.5
    // العروض بـ 100 مشاهدة ≈ 0.77
    // العروض بـ 1000 مشاهدة ≈ 1.0
    final normalizedScore = log(viewsCount + 1) / log(1001);

    return normalizedScore.clamp(0.0, 1.0);
  }

  /// حساب تعزيز التنوع للتصنيف
  /// التصنيفات الأقل ظهوراً تحصل على درجات أعلى
  double _calculateDiversityBoost(String category) {
    // تحديث عداد الاستخدام
    _categoryUsageCount[category] = (_categoryUsageCount[category] ?? 0) + 1;

    // إيجاد أكثر تصنيف استخداماً
    final maxUsage = _categoryUsageCount.values.isEmpty
        ? 1
        : _categoryUsageCount.values.reduce(max);

    // التصنيف الأقل استخداماً = درجة أعلى
    final currentUsage = _categoryUsageCount[category] ?? 1;
    final diversityScore = 1.0 - (currentUsage / (maxUsage + 1));

    return diversityScore.clamp(0.0, 1.0);
  }

  /// إعادة تعيين عدادات التنوع (استخدام عند بداية جلسة جديدة)
  void resetDiversityTracking() {
    _categoryUsageCount.clear();
  }
}

/// فئة داخلية لربط العرض بنتيجته
class _ScoredOffer<T> {
  final T offer;
  final double score;

  _ScoredOffer(this.offer, this.score);
}
