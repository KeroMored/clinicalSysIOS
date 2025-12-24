# نظام الصيدليات - Pharmacy System

## نظرة عامة
نظام متكامل لإدارة الصيدليات مع واجهة مستخدم عربية سهلة الاستخدام.

## الميزات

### 1. الصفحة الرئيسية للصيدليات (Pharmacy Homepage)
- عرض الصيدليات القريبة
- عرض العروض والخصومات المميزة
- خيار طلب دواء للتوصيل
- بطاقات تفاعلية لكل قسم

### 2. صفحة الصيدليات (The Pharmacies Screen)
- عرض قائمة بجميع الصيدليات
- البحث عن صيدلية بالاسم أو العنوان
- عرض حالة الصيدلية (مفتوح/مغلق)
- تقييمات وتعليقات المستخدمين
- عرض توفر خدمة التوصيل

### 3. صفحة تفاصيل الصيدلية (Pharmacy Details)
- معلومات كاملة عن الصيدلية
- العنوان ومواعيد العمل والإجازات
- معلومات الاتصال (مكالمات + واتساب)
- فتح الموقع على خرائط جوجل
- تفاصيل خدمة التوصيل (الرسوم والحد الأدنى للطلب)
- الخدمات الإضافية المتوفرة
- معرض صور للصيدلية

## البنية المعمارية (Clean Architecture)

```
lib/
├── features/
│   ├── pharmacy/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── pharmacy_model.dart
│   │   │   │   └── pharmacy_offer_model.dart
│   │   │   └── repositories/
│   │   │       └── pharmacy_repository.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── pharmacy_cubit.dart
│   │       │   └── pharmacy_state.dart
│   │       ├── screens/
│   │       │   ├── pharmacy_home_page.dart
│   │       │   ├── the_pharmacies_screen.dart
│   │       │   └── pharmacy_details_screen.dart
│   │       └── widgets/
│   │           ├── pharmacy_card.dart
│   │           ├── offer_card.dart
│   │           └── section_header.dart
│   └── home/
│       └── presentation/
│           └── home_screen.dart
```

## النماذج (Models)

### PharmacyModel
```dart
- id: معرف الصيدلية
- name: اسم الصيدلية
- address: العنوان
- phone: رقم الهاتف
- whatsapp: رقم الواتساب
- description: وصف الصيدلية
- latitude: خط العرض
- longitude: خط الطول
- workingHours: مواعيد العمل
- holidays: الإجازات
- images: صور الصيدلية
- hasHomeDelivery: توفر خدمة التوصيل
- deliveryFee: رسوم التوصيل
- minimumOrderForDelivery: الحد الأدنى للطلب
- rating: التقييم
- reviewsCount: عدد التقييمات
- isOpen: حالة الصيدلية (مفتوح/مغلق)
- closingTime: وقت الإغلاق
- services: الخدمات الإضافية
```

### PharmacyOfferModel
```dart
- id: معرف العرض
- pharmacyId: معرف الصيدلية
- pharmacyName: اسم الصيدلية
- title: عنوان العرض
- description: وصف العرض
- imageUrl: صورة العرض
- discountPercentage: نسبة الخصم
- startDate: تاريخ البداية
- endDate: تاريخ الانتهاء
- isActive: حالة العرض
```

## إدارة الحالة (State Management)
استخدام **Cubit** من مكتبة flutter_bloc:

### States:
- `PharmacyInitial`: الحالة الأولية
- `PharmacyLoading`: جاري التحميل
- `PharmacyLoaded`: تم التحميل بنجاح
- `PharmacyError`: حدث خطأ
- `PharmacyDetailsLoading`: جاري تحميل التفاصيل
- `PharmacyDetailsLoaded`: تم تحميل التفاصيل
- `PharmacySearchLoading`: جاري البحث
- `PharmacySearchLoaded`: نتائج البحث

### Methods:
- `loadPharmaciesAndOffers()`: تحميل الصيدليات والعروض
- `loadPharmacyDetails(String id)`: تحميل تفاصيل صيدلية معينة
- `searchPharmacies(String query)`: البحث عن صيدليات
- `refresh()`: تحديث البيانات

## قاعدة البيانات (Firebase Firestore)

### Collections:

#### pharmacies
```json
{
  "name": "صيدلية النهار",
  "address": "شارع الجمهورية، المنصورة",
  "phone": "+201234567890",
  "whatsapp": "+201234567890",
  "description": "صيدلية متكاملة بأحدث الأجهزة",
  "latitude": 31.0364,
  "longitude": 31.3785,
  "workingHours": "من 9 صباحاً إلى 11 مساءً",
  "holidays": "الجمعة",
  "images": ["url1", "url2"],
  "hasHomeDelivery": true,
  "deliveryFee": 15.0,
  "minimumOrderForDelivery": 50.0,
  "rating": 4.5,
  "reviewsCount": 120,
  "isOpen": true,
  "closingTime": "11:00 PM",
  "services": ["قياس الضغط", "قياس السكر", "استشارة صيدلي"]
}
```

#### pharmacy_offers
```json
{
  "pharmacyId": "pharmacy_id",
  "pharmacyName": "صيدلية النهار",
  "title": "خصم 20% على جميع المنتجات",
  "description": "عرض خاص لمدة أسبوع",
  "imageUrl": "offer_image_url",
  "discountPercentage": 20.0,
  "startDate": "2025-01-01T00:00:00.000Z",
  "endDate": "2025-01-07T23:59:59.000Z",
  "isActive": true
}
```

## الحزم المستخدمة (Packages)

### Core
- `flutter_bloc: ^8.1.3` - إدارة الحالة
- `firebase_core: ^3.6.0` - Firebase Core
- `cloud_firestore: ^5.4.4` - قاعدة البيانات

### UI & Features
- `google_fonts: ^6.1.0` - الخطوط
- `url_launcher: ^6.2.2` - فتح الروابط والمكالمات
- `geolocator: ^10.1.0` - تحديد الموقع
- `google_maps_flutter: ^2.5.0` - الخرائط

## التشغيل

1. تثبيت الحزم:
```bash
flutter pub get
```

2. تشغيل التطبيق:
```bash
flutter run
```

## الميزات المستقبلية
- [ ] نظام الحجز المسبق للأدوية
- [ ] طلب الأدوية أونلاين
- [ ] تتبع حالة الطلب
- [ ] نظام الإشعارات للعروض الجديدة
- [ ] نظام التقييم والمراجعات
- [ ] إضافة المفضلة
- [ ] مشاركة الصيدلية مع الأصدقاء

## ملاحظات التطوير
- الكود يتبع مبادئ Clean Architecture
- استخدام Cubit للحفاظ على بساطة إدارة الحالة
- الويدجيت معزولة وقابلة لإعادة الاستخدام
- جميع النصوص باللغة العربية
- التصميم متجاوب مع جميع أحجام الشاشات
