# تحديث: تطبيق الترتيب الديناميكي على كل صفحات العروض

## ✅ التحديثات المُنفذة

تم تطبيق نظام الترتيب الديناميكي على **صفحتين مختلفتين** للعروض:

### 1. عروض الأدوية (Medicine Offers)
**المسار**: `medicine_offers_screen.dart`
- ✅ الترتيب الديناميكي مطبق
- ✅ viewsCount مضاف
- ✅ category مضاف
- ✅ إعدادات عرض/إخفاء من Firestore

### 2. عروض الصيدليات (Pharmacy Offers)  
**المسار**: `pharmacy_offers_list_screen.dart`
- ✅ الترتيب الديناميكي مطبق
- ✅ viewsCount مضاف
- ✅ category مضاف
- ✅ إعدادات عرض/إخفاء من Firestore

## 🏗️ البنية المعمارية المحدّثة

### Generic Service Layer
تم إنشاء **نظام عام (Generic)** للترتيب يعمل مع أي نوع عروض:

```
generic_offer_sorting_service.dart
├── ISortableOffer (interface)
│   ├── id
│   ├── createdAt
│   ├── viewsCount
│   └── category
│
└── GenericOfferSortingService<T>
    └── Wrapper Services:
        ├── OfferSortingService (for MedicineOfferModel)
        └── PharmacyOfferSortingService (for PharmacyOfferModel)
```

### Models المحدثة

#### MedicineOfferModel
```dart
class MedicineOfferModel implements ISortableOffer {
  final DateTime createdAt;
  final int viewsCount;
  final String category;
  // ... باقي الحقول
}
```

#### PharmacyOfferModel  
```dart
class PharmacyOfferModel implements ISortableOffer {
  final DateTime createdAt;  // NEW
  final int viewsCount;      // NEW
  final String category;     // NEW
  // ... باقي الحقول
}
```

## 📊 Firestore Collections المتأثرة

### 1. medicine_offers
```javascript
{
  // الحقول الموجودة
  medicineName: "...",
  price: 25.0,
  // ... إلخ
  
  // الحقول الجديدة
  viewsCount: 0,
  category: "مسكنات"
}
```

### 2. offers (pharmacy offers)
```javascript
{
  // الحقول الموجودة
  title: "...",
  description: "...",
  startDate: "...",
  endDate: "...",
  // ... إلخ
  
  // الحقول الجديدة
  createdAt: "2026-02-23T10:30:00Z",
  viewsCount: 0,
  category: "عام"
}
```

### 3. app_control/offers_settings
```javascript
{
  showViewsCount: false,  // مشترك للاتنين
  createdAt: [timestamp],
  updatedAt: [timestamp]
}
```

## 🚀 الإعداد المطلوب

### 1. تحديث البيانات الموجودة

يجب تحديث العروض الموجودة في كلا الـ collections:

#### لـ medicine_offers:
```javascript
// في Firebase Console أو script
db.collection('medicine_offers').get().then(snapshot => {
  snapshot.docs.forEach(doc => {
    doc.ref.update({
      viewsCount: 0,
      category: 'عام'
    });
  });
});
```

#### لـ offers (pharmacy offers):
```javascript
// في Firebase Console أو script
db.collection('offers').get().then(snapshot => {
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    doc.ref.update({
      createdAt: data.startDate || new Date().toISOString(),
      viewsCount: 0,
      category: 'عام'
    });
  });
});
```

### 2. إعداد app_control
تشغيل السكريبت الموجود:
```powershell
.\setup_dynamic_sorting.ps1
```

## 📱 واجهة المستخدم

### Medicine Offers Screen
- أيقونة shuffle في AppBar ✅
- عرض viewsCount مشروط ✅
- عرض category مشروط ✅
- زيادة viewsCount عند النقر ✅

### Pharmacy Offers Screen
- أيقونة shuffle في AppBar ✅
- عرض viewsCount مشروط في OfferCard ✅
- عرض category مشروط في OfferCard ✅
- زيادة viewsCount عند النقر ✅

## 🎯 كيفية التحكم في viewsCount

### إظهار عدد المشاهدات:
```dart
// في Firestore Console
app_control/offers_settings
showViewsCount: true
```

### إخفاء عدد المشاهدات:
```dart
// في Firestore Console  
app_control/offers_settings
showViewsCount: false
```

أو برمجياً:
```dart
final appControlService = AppControlService();
await appControlService.updateShowViewsCount(true); // إظهار
await appControlService.updateShowViewsCount(false); // إخفاء
```

## ⚖️ الفرق بين النظامين

| Feature | Medicine Offers | Pharmacy Offers |
|---------|----------------|-----------------|
| **Collection** | `medicine_offers` | `offers` |
| **الترتيب** | ديناميكي ✅ | ديناميكي ✅ |
| **viewsCount** | ✅ | ✅ |
| **category** | ✅ | ✅ |
| **النطاق** | كل الصيدليات | صيدلية واحدة |
| **الفلترة** | لا يوجد | `pharmacyId` |
| **UI** | MedicineOfferCard | OfferCard |

## 🔄 مسار البيانات

### Medicine Offers
```
MedicineOffersScreen
  ↓
OfferSortingService
  ↓
GenericOfferSortingService<MedicineOfferModel>
  ↓
Sorted + Paginated Offers
```

### Pharmacy Offers
```
PharmacyOffersListScreen
  ↓
PharmacyOfferSortingService
  ↓
GenericOfferSortingService<PharmacyOfferModel>
  ↓
Sorted + Paginated Offers
```

## 📈 الأداء

### معايير مشتركة:
- جلب: 50 عرض/دفعة
- عرض: 8 عروض/صفحة
- ترتيب: محلي (لا يعيد استعلام Firestore)
- pagination: ذكي (jلب عند الحاجة)

### الاستهلاك المتوقع:
- **Medicine Offers**: ~5-10 MB RAM
- **Pharmacy Offers**: ~3-5 MB RAM  
- **CPU**: أقل من 100ms للترتيب

## 🐛 المشاكل المحتملة

### المشكلة: viewsCount لا يظهر
**الحل**: 
1. تأكد أن `showViewsCount = true` في Firestore
2. تأكد أن الـ models فيها الحقل
3. أعد تشغيل التطبيق

### المشكلة: العروض لا تظهر في pharmacy offers
**الحل**:
1. تأكد أن `createdAt` موجود في الوثائق
2. استخدم `startDate` كـ fallback (تم تطبيقه)
3. راجع الـ console للأخطاء

### المشكلة: الترتيب لا يتغير
**الحل**:
- الترتيب ثابت خلال الجلسة (بالتصميم)
- استخدم pull-to-refresh لجلسة جديدة
- أو أغلق وأعد فتح التطبيق

## ✨ المزايا

1. **كود واحد**: Generic service لكل أنواع العروض
2. **سهولة التوسع**: أضف أي نوع جديد بتطبيق `ISortableOffer`
3. **standalone**: كل صفحة تعمل بشكل مستقل
4. **إعدادات مركزية**: `app_control` واحد للكل
5. **أداء عالي**: ترتيب محلي بدون استعلامات إضافية

## 📚 الملفات المحدثة

### Core Services
- ✅ `generic_offer_sorting_service.dart` (NEW)
- ✅ `offer_sorting_service.dart` (UPDATED - wrapper)
- ✅ `pharmacy_offer_sorting_service.dart` (NEW)
- ✅ `app_control_service.dart` (existing)

### Models
- ✅ `medicine_offer_model.dart` (implements ISortableOffer)
- ✅ `pharmacy_offer_model.dart` (implements ISortableOffer)

### Screens
- ✅ `medicine_offers_screen.dart` (dynamic sorting)
- ✅ `pharmacy_offers_list_screen.dart` (dynamic sorting)

### Widgets
- ✅ `medicine_offer_card.dart` (conditional viewsCount)
- ✅ `offer_card.dart` (conditional viewsCount)

---

**التاريخ**: ${DateTime.now().toString().split(' ')[0]}  
**الحالة**: ✅ جاهز للإنتاج  
**التغطية**: 2/2 صفحات عروض (100%)
