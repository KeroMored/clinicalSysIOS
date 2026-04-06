# نظام الترتيب الديناميكي للعروض - Dynamic Offer Sorting System

## 📋 نظرة عامة

تم تنفيذ نظام ترتيب ديناميكي متقدم للعروض يجمع بين عدة عوامل لتقديم تجربة متنوعة ومتوازنة للمستخدمين في كل جلسة.

## 🎯 المميزات الرئيسية

### 1. الترتيب الديناميكي الذكي
- **الحداثة (35%)**: أولوية للعروض الأحدث
- **التفاعل (25%)**: بناءً على viewsCount مع تطبيع لوغاريتمي
- **التنوع (20%)**: تجنب تكرار نفس التصنيف
- **العشوائية المحكومة (20%)**: تنوع ثابت خلال الجلسة

### 2. التقسيم الذكي (Smart Pagination)
- جلب دفعات كبيرة (50 عرض)
- ترتيب كامل للدفعة
- عرض تدريجي (8 عروض/صفحة)
- دعم تمرير لانهائي

### 3. إدارة عدد المشاهدات
- إخفاء/إظهار viewsCount من إعدادات Firestore
- تحديث تلقائي عند النقر
- وثيقة تحكم في `app_control/offers_settings`

## 🏗️ البنية المعمارية

### 1. OfferSortingService

**الموقع**: `lib/core/services/offer_sorting_service.dart`

```dart
final sortingService = OfferSortingService();

// ترتيب العروض
final sortedOffers = sortingService.sortOffers(
  offers: allOffers,
  pageNumber: 0,
  pageSize: 50,
);
```

**المسؤوليات**:
- حساب النتيجة لكل عرض بناءً على 4 عوامل
- ضمان تنوع التصنيفات
- عشوائية مستقرة خلال الجلسة

### 2. AppControlService

**الموقع**: `lib/core/services/app_control_service.dart`

```dart
final appControlService = AppControlService();

// جلب الإعدادات
final settings = await appControlService.getOffersSettings();
bool showViews = settings.showViewsCount;

// أو استخدام Stream للتحديث الفوري
appControlService.getOffersSettingsStream().listen((settings) {
  setState(() {
    showViewsCount = settings.showViewsCount;
  });
});

// تحديث الإعداد
await appControlService.updateShowViewsCount(true);
```

**المسؤوليات**:
- جلب إعدادات العروض من Firestore
- توفير Stream للتحديثات الفورية
- تحديث إعداد showViewsCount

### 3. MedicineOfferModel

**التحديثات**:
```dart
class MedicineOfferModel {
  // ... الحقول الموجودة
  final int viewsCount;      // NEW: عدد المشاهدات
  final String category;     // NEW: تصنيف الدواء
}
```

## 📊 كيفية عمل النظام

### دورة حياة البيانات

```
1. Firestore Fetch (50 عرض)
   ↓
2. Dynamic Sorting (OfferSortingService)
   ↓
3. Display Pagination (8 عروض)
   ↓
4. User Scrolls
   ↓
5. Load More (من نفس الدفعة)
   ↓
6. عند النفاذ → العودة للخطوة 1
```

### معادلة التصنيف

```dart
score = 
  0.35 × recencyScore +          // أحدث = أفضل
  0.25 × engagementScore +       // أكثر مشاهدة = أفضل (مع تطبيع)
  0.20 × diversityBoost +        // تصنيف مختلف = أفضل
  0.20 × controlledRandomness    // عشوائية مستقرة
```

### حساب كل عامل

#### 1. Recency Score
```dart
< 24 ساعة  → 1.0
< 3 أيام   → 0.8
< 7 أيام   → 0.6
< 30 يوم   → 0.4
< 60 يوم   → 0.2
أقدم      → 0.1
```

#### 2. Engagement Score
```dart
// تطبيع لوغاريتمي لتجنب هيمنة العروض عالية المشاهدات
normalizedScore = log(viewsCount + 1) / log(1001)

1 مشاهدة    → 0.0
10 مشاهدات  → ~0.5
100 مشاهدة  → ~0.77
1000 مشاهدة → ~1.0
```

#### 3. Diversity Boost
```dart
// كلما قل استخدام التصنيف، زادت النتيجة
diversityScore = 1.0 - (currentUsage / (maxUsage + 1))
```

#### 4. Controlled Randomness
```dart
// عشوائية ثابتة لكل جلسة
sessionSeed = DateTime.now().millisecondsSinceEpoch
pageRandom = Random(sessionSeed + pageNumber)
randomness = pageRandom.nextDouble() // 0.0 - 1.0
```

## 🔧 إعداد Firestore

### 1. إنشاء المجموعة والوثيقة

يدوياً في Firebase Console:

```
app_control (collection)
  └── offers_settings (document)
      ├── showViewsCount: false  (boolean)
      ├── createdAt: [timestamp]
      └── updatedAt: [timestamp]
```

أو برمجياً:

```dart
final appControlService = AppControlService();
await appControlService.initializeOffersSettings();
```

### 2. تحديث العروض الموجودة

إذا كانت العروض موجودة بدون `viewsCount` و `category`:

```javascript
// في Firebase Console > Cloud Firestore
// اختر medicine_offers collection
// ثم Run Query:

// إضافة viewsCount و category للعروض الحالية
const admin = require('firebase-admin');
const db = admin.firestore();

async function updateExistingOffers() {
  const offersRef = db.collection('medicine_offers');
  const snapshot = await offersRef.get();
  
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      viewsCount: 0,
      category: 'عام'
    });
  });
  
  await batch.commit();
  console.log('تم تحديث جميع العروض');
}
```

أو PowerShell Script:

```powershell
# update_offers.ps1
# استخدم Firebase Admin SDK أو REST API
```

## 📱 استخدام الواجهة

### للمستخدمين

1. **عرض العروض**: افتح شاشة عروض الأدوية
   - الترتيب ديناميكي تلقائياً
   - أيقونة shuffle في AppBar توضح الترتيب الديناميكي

2. **زيادة المشاهدات**: انقر على أي عرض
   - يزيد viewsCount تلقائياً
   - يساعد في تحسين الترتيب

3. **التمرير**: اسحب للأسفل لعرض المزيد
   - تحميل تدريجي
   - مؤشر تحميل واضح

### للمطورين/المسؤولين

#### إظهار/إخفاء عدد المشاهدات

```dart
// في أي screen أو admin panel
final appControlService = AppControlService();

// إظهار
await appControlService.updateShowViewsCount(true);

// إخفاء
await appControlService.updateShowViewsCount(false);
```

أو يدوياً في Firestore:
```
app_control/offers_settings
showViewsCount: true  ← أضف/عدل هذا الحقل
```

## 🧪 اختبار النظام

### 1. اختبار الترتيب الديناميكي

```dart
void testDynamicSorting() {
  final service = OfferSortingService();
  
  // إنشاء عروض تجريبية
  final offers = [
    MedicineOfferModel(
      id: '1',
      medicineName: 'دواء 1',
      createdAt: DateTime.now().subtract(Duration(hours: 1)),
      viewsCount: 10,
      category: 'مسكنات',
      // ... باقي الحقول
    ),
    MedicineOfferModel(
      id: '2',
      medicineName: 'دواء 2',
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      viewsCount: 100,
      category: 'مضادات حيوية',
      // ... باقي الحقول
    ),
  ];
  
  // ترتيب
  final sorted = service.sortOffers(
    offers: offers,
    pageNumber: 0,
    pageSize: offers.length,
  );
  
  // التحقق من النتائج
  print('الترتيب:');
  for (var offer in sorted) {
    print('${offer.medicineName} - ${offer.viewsCount} مشاهدة');
  }
}
```

### 2. اختبار AppControlService

```dart
void testAppControl() async {
  final service = AppControlService();
  
  // اختبار الجلب
  final settings = await service.getOffersSettings();
  print('showViewsCount: ${settings.showViewsCount}');
  
  // اختبار التحديث
  await service.updateShowViewsCount(true);
  
  // التحقق
  final updatedSettings = await service.getOffersSettings();
  assert(updatedSettings.showViewsCount == true);
  print('✅ الاختبار نجح');
}
```

## 🎨 UI Components

### MedicineOfferCard مع viewsCount

```dart
MedicineOfferCard(
  offer: offer,
  showViewsCount: true, // أو false حسب الإعدادات
)
```

**العرض الشرطي**:
- إذا `showViewsCount = true`:
  ```
  👁️ 25 مشاهدة  | 🏷️ مسكنات
  ```

- إذا `showViewsCount = false`:
  لا يظهر شيء

## ⚙️ الضبط والتخصيص

### تعديل الأوزان

في `OfferSortingService._calculateScore()`:

```dart
// الأوزان الحالية
const double recencyWeight = 0.35;      // ↑ لأولوية أعلى للحداثة
const double engagementWeight = 0.25;   // ↑ لأولوية أعلى للتفاعل
const double diversityWeight = 0.20;    // ↑ لأولوية أعلى للتنوع
const double randomnessWeight = 0.20;   // ↑ لمزيد من العشوائية

// مثال: زيادة أهمية التفاعل
const double recencyWeight = 0.30;
const double engagementWeight = 0.35;
const double diversityWeight = 0.20;
const double randomnessWeight = 0.15;
```

### تعديل أحجام الدفعات

في `MedicineOffersScreen`:

```dart
static const int _fetchBatchSize = 50;  // العدد المجلوب من Firestore
static const int _displayPageSize = 8;  // العدد المعروض في كل مرة

// مثال: جلب أكثر، عرض أقل
static const int _fetchBatchSize = 100;
static const int _displayPageSize = 10;
```

### تعديل معادلة الحداثة

في `OfferSortingService._calculateRecencyScore()`:

```dart
// الحالي
if (age.inHours <= 24) return 1.0;
if (age.inDays <= 3) return 0.8;

// أكثر صرامة (أولوية أكبر للجديد)
if (age.inHours <= 12) return 1.0;
if (age.inDays <= 2) return 0.7;
```

## 📈 الأداء

### المقاييس المتوقعة

- **التحميل الأولي**: ~1-2 ثانية (50 عرض)
- **التمرير**: فوري (من الذاكرة)
- **إعادة التحميل**: ~0.5-1 ثانية
- **استهلاك الذاكرة**: ~2-5 MB (50 عرض)

### التحسينات المطبقة

✅ Firestore pagination (limit 50)
✅ Local sorting (لا نعيد استعلام Firestore)
✅ Batch fetching (تقليل عدد الاستعلامات)
✅ Stream disposal (تجنب تسريب الذاكرة)
✅ Efficient rebuilds (setState محدود)

## 🐛 استكشاف الأخطاء

### المشكلة: العروض لا تظهر

**الحل**:
1. تأكد من `isActive = true` في Firestore
2. تحقق من وجود عروض في `medicine_offers` collection
3. افحص console للأخطاء

### المشكلة: viewsCount لا يظهر

**الحل**:
1. تحقق من `app_control/offers_settings/showViewsCount = true`
2. تأكد من `AppControlService` يعمل بشكل صحيح
3. أعد تشغيل التطبيق

### المشكلة: الترتيب لا يتغير

**الحل**:
1. هذا طبيعي - الترتيب ثابت خلال الجلسة
2. لتغيير الترتيب: pull-to-refresh
3. أو أغلق وأعد فتح التطبيق

### المشكلة: بطء في التحميل

**الحل**:
1. قلل `_fetchBatchSize` إلى 30
2. تحقق من سرعة الإنترنت
3. ضع index في Firestore على `createdAt`

## 🚀 التطوير المستقبلي

### اقتراحات للتحسين

1. **Machine Learning Personalization**
   ```dart
   // تخصيص الترتيب لكل مستخدم
   userPreferenceScore = MLModel.predictUserPreference(offer, user)
   ```

2. **A/B Testing**
   ```dart
   // اختبار صيغ ترتيب مختلفة
   final variant = ABTest.getVariant(userId);
   final weights = variant == 'A' ? weightsA : weightsB;
   ```

3. **Real-time Analytics**
   ```dart
   // تتبع أداء كل عرض
   Analytics.trackOfferPerformance(offerId, impressions, clicks, conversions);
   ```

4. **Geo-based Boosting**
   ```dart
   // أولوية للصيدليات القريبة
   locationBoost = calculateDistanceBoost(offer.location, userLocation);
   ```

## 📞 الدعم

للمشاكل أو الاقتراحات:
- افحص documentation هذا أولاً
- راجع الكود المصدري في `lib/core/services/`
- تواصل مع فريق التطوير

---

**آخر تحديث**: ${DateTime.now().toString().split(' ')[0]}
**الإصدار**: 1.0.0
**الحالة**: ✅ جاهز للإنتاج
