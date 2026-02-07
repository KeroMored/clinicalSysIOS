# نظام شركات التأمين للصيدليات

## نظرة عامة
تم إضافة ميزة جديدة تتيح للصيدليات تحديد ما إذا كانت متعاقدة مع شركات تأمين وإدراج أسماء هذه الشركات.

## التحديثات المنفذة

### 1. تحديث نموذج البيانات (PharmacyModel)
**الملف:** `lib/features/pharmacy/data/models/pharmacy_model.dart`

تم إضافة الحقول التالية:
```dart
final bool hasInsurance;              // متعاقد مع شركات تأمين؟
final List<String> insuranceCompanies; // أسماء شركات التأمين
```

- تم تحديث جميع الـ constructors (fromJson, fromFirestore, toJson, copyWith)
- القيم الافتراضية: `hasInsurance = false`, `insuranceCompanies = []`

### 2. تحديث نموذج طلب الصيدلية (PharmacyRequestModel)
**الملف:** `lib/features/admin/data/models/pharmacy_request_model.dart`

تم إضافة نفس الحقول مع تحديث جميع الدوال المطلوبة.

### 3. شاشة إضافة صيدلية جديدة
**الملف:** `lib/features/admin/presentation/screens/add_pharmacy_screen.dart`

#### الميزات المضافة:
- **قسم جديد**: "شركات التأمين" يظهر بعد قسم "خيارات الخدمة"
- **سؤال تفاعلي**: "متعاقد مع شركات تأمين؟" (SwitchListTile)
- **حقول ديناميكية**: 
  - عند تفعيل السؤال، تظهر واجهة لإضافة أسماء الشركات
  - زر + لإضافة شركات إضافية
  - زر حذف لكل شركة
  - حقل نصي لكل شركة مع validation

#### الكود المضاف:
```dart
bool _hasInsurance = false;
final List<TextEditingController> _insuranceCompanyControllers = [];
```

### 4. شاشة تفاصيل الصيدلية
**الملف:** `lib/features/pharmacy/presentation/screens/pharmacy_details_screen.dart`

#### التصميم الجديد:
- **موقع العرض**: فوق قسم "تواصل معنا" مباشرةً
- **شرط الظهور**: يظهر فقط إذا `hasInsurance = true` وهناك شركات مسجلة
- **التصميم**: 
  - بطاقة بتدرج لوني أزرق
  - أيقونة `health_and_safety`
  - قائمة بأسماء الشركات (كل شركة في سطر منفصل)
  - نقاط زرقاء صغيرة قبل كل اسم شركة

#### مثال على الكود:
```dart
if (pharmacy.hasInsurance && pharmacy.insuranceCompanies.isNotEmpty) ...[
  Container(
    // تصميم البطاقة
    child: Column(
      children: [
        // عنوان "متعاقد مع شركات التأمين"
        // قائمة الشركات
      ],
    ),
  ),
]
```

### 5. شاشة تعديل بيانات الصيدلية
**الملف:** `lib/features/pharmacy/presentation/screens/edit_pharmacy_screen.dart`

#### الميزات المضافة:
- **قسم جديد**: يظهر بعد قسم "أيام العطلة" وقبل "صور الصيدلية"
- **نفس الوظائف**: مثل شاشة الإضافة تماماً
- **التهيئة**: يتم تحميل البيانات الحالية من الصيدلية:
  ```dart
  _hasInsurance = widget.pharmacy.hasInsurance;
  _insuranceCompanyControllers = widget.pharmacy.insuranceCompanies
      .map((company) => TextEditingController(text: company))
      .toList();
  ```
- **الحفظ**: يتم تضمين البيانات في updatedData:
  ```dart
  'hasInsurance': _hasInsurance,
  'insuranceCompanies': insuranceCompanies,
  ```

### 6. تحديث AdminRepository
**الملف:** `lib/features/admin/data/repositories/admin_repository.dart`

تم تحديث دالة `addPharmacyDirectly` لتتضمن حقول التأمين عند إنشاء PharmacyModel.

## كيفية الاستخدام

### للأدمن (إضافة صيدلية):
1. افتح شاشة "إضافة صيدلية جديدة"
2. اذهب إلى قسم "شركات التأمين"
3. فعّل السؤال "متعاقد مع شركات تأمين؟"
4. اضغط على زر "إضافة شركة تأمين" أو أيقونة +
5. أدخل اسم الشركة
6. كرر الخطوات لإضافة المزيد من الشركات
7. احفظ البيانات

### لصاحب الصيدلية (التعديل):
1. من لوحة التحكم، اختر "تعديل بيانات الصيدلية"
2. اذهب إلى قسم "شركات التأمين"
3. فعّل/عطّل السؤال حسب الحاجة
4. أضف أو احذف الشركات
5. احفظ التعديلات

### للمستخدمين (العرض):
- عند فتح تفاصيل صيدلية متعاقدة مع شركات تأمين
- ستظهر بطاقة جميلة فوق معلومات التواصل
- تحتوي على قائمة بجميع الشركات المتعاقد معها

## البنية في Firebase

### مثال على البيانات:
```json
{
  "name": "صيدلية النور",
  "address": "شارع الهرم",
  "hasInsurance": true,
  "insuranceCompanies": [
    "شركة مصر للتأمين",
    "التأمين الصحي الشامل",
    "شركة المهندس للتأمين"
  ],
  // ... باقي البيانات
}
```

## Validation والتحقق

### في النماذج:
- يتم التحقق من أن اسم الشركة ليس فارغاً
- يتم تنظيف القيم الفارغة قبل الحفظ
- التحقق من وجود قيم صالحة في القائمة

### في العرض:
- يتم التحقق من `hasInsurance && insuranceCompanies.isNotEmpty` قبل العرض
- تجنب عرض قسم التأمين إذا لم تكن هناك بيانات

## التصميم والألوان

### شاشة التفاصيل:
- **اللون الأساسي**: أزرق (#2196F3)
- **الخلفية**: تدرج لوني من الأزرق الفاتح إلى السماوي الفاتح
- **الأيقونة**: `health_and_safety` بيضاء على خلفية زرقاء
- **النقاط**: دوائر زرقاء صغيرة

### شاشات الإضافة والتعديل:
- **اللون الأساسي**: تركواز (#06B6D4)
- **الخلفية**: أزرق فاتح جداً
- **الحدود**: أزرق شفاف

## ملاحظات تقنية

1. **إدارة الذاكرة**: يتم التخلص من جميع TextEditingController عند dispose
2. **الحالة الديناميكية**: يتم إعادة بناء الواجهة عند التغيير
3. **التوافقية**: متوافق مع جميع الصيدليات الحالية (القيم الافتراضية)
4. **الأمان**: لا يوجد كود مباشر للواجهة، كل شيء من خلال النماذج

## الملفات المعدلة

1. `lib/features/pharmacy/data/models/pharmacy_model.dart`
2. `lib/features/admin/data/models/pharmacy_request_model.dart`
3. `lib/features/admin/presentation/screens/add_pharmacy_screen.dart`
4. `lib/features/pharmacy/presentation/screens/pharmacy_details_screen.dart`
5. `lib/features/pharmacy/presentation/screens/edit_pharmacy_screen.dart`
6. `lib/features/admin/data/repositories/admin_repository.dart`

## الاختبار

تم التحقق من:
- ✅ عدم وجود أخطاء في الكود
- ✅ التوافق مع النماذج الحالية
- ✅ عمل flutter pub get بنجاح
- ✅ جميع الـ validations تعمل بشكل صحيح

## التطوير المستقبلي (اختياري)

- إضافة بحث عن شركات التأمين من قائمة معدة مسبقاً
- إضافة تصفية الصيدليات حسب شركة التأمين
- إضافة إحصائيات عن عدد الصيدليات المتعاقدة
- ربط مع نظام التأمين الصحي المصري
