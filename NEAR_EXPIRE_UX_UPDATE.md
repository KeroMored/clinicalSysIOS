# تحديث تجربة المستخدم - نظام الأدوية قاربت على الانتهاء

## ملخص التحديثات

تم إعادة تصميم شاشة إضافة المنتجات وتحسين نموذج البيانات بناءً على احتياجات المستخدمين العرب.

## التغييرات الرئيسية

### 1. اختيار تاريخ الانتهاء ✨

#### قبل التحديث:
- استخدام Date Picker تقليدي (يوم/شهر/سنة)
- يتطلب اختيار تاريخ محدد بالأيام

#### بعد التحديث:
```dart
Row(
  children: [
    Expanded(
      child: DropdownButtonFormField<int>(
        // اختيار السنة (السنة الحالية + سنتين)
        items: [2024, 2025, 2026, ...]
      ),
    ),
    Expanded(
      child: DropdownButtonFormField<int>(
        // اختيار الشهر (بالأسماء العربية)
        items: [يناير، فبراير، مارس، ...]
      ),
    ),
  ],
)
```

**الفوائد:**
- ✅ أسهل وأسرع في الاستخدام
- ✅ مناسب أكثر لطبيعة بيانات الأدوية (تنتهي بنهاية الشهر)
- ✅ واجهة عربية بالكامل (أسماء الأشهر بالعربية)
- ✅ تجربة مستخدم أكثر سلاسة

### 2. تصنيف الأدوية 🏷️

#### الميزة الجديدة:
إضافة حقل "نوع الدواء" مع خيارات محددة:
- أقراص
- شراب
- كبسولات
- حقن
- مرهم
- قطرة
- بخاخ
- لبوس
- **أخرى** (مع إمكانية الإدخال اليدوي)

#### التطبيق:
```dart
DropdownButtonFormField<String>(
  items: _medicineTypes.map((type) => DropdownMenuItem(
    value: type,
    child: Text(type),
  )).toList(),
  onChanged: (value) {
    if (value == 'أخرى') {
      setState(() => _isCustomType = true);
      // عرض حقل نصي لإدخال النوع يدوياً
    }
  },
)
```

**الفوائد:**
- ✅ تصنيف أفضل للأدوية
- ✅ سهولة البحث والفلترة مستقبلاً
- ✅ مرونة مع خيار "أخرى"

### 3. نظام التسعير المبسط 💰

#### قبل التحديث:
```dart
// حقلان إلزاميان
TextFormField(controller: _originalPriceController)  // السعر الأصلي
TextFormField(controller: _discountedPriceController)  // السعر المخفض
// مع تحقق من أن المخفض أقل من الأصلي
```

#### بعد التحديث:
```dart
// حقل واحد اختياري
TextFormField(
  controller: _totalPriceController,
  decoration: InputDecoration(
    labelText: 'السعر الكلي (اختياري)',
    helperText: 'إذا لم يتم تحديده سيظهر "غير محدد"',
  ),
  validator: (v) {
    if (v == null || v.trim().isEmpty) return null; // اختياري
    // تحقق فقط إذا تم الإدخال
  },
)
```

**الفوائد:**
- ✅ عدم إجبار الصيدليات على تحديد السعر
- ✅ بساطة في الإدخال (حقل واحد بدلاً من اثنين)
- ✅ مرونة أكبر للصيدليات

### 4. حساب سعر العبوة الواحدة تلقائياً 🧮

#### في Model:
```dart
class NearExpireItemModel {
  final double? totalPrice;
  final int quantity;

  // حساب تلقائي
  double? get unitPrice {
    if (totalPrice == null || quantity == 0) return null;
    return totalPrice! / quantity;
  }

  // نص جاهز للعرض
  String get unitPriceText {
    final price = unitPrice;
    if (price == null) return 'غير محدد';
    return '${price.toStringAsFixed(2)} جنيه للعبوة';
  }
}
```

#### في UI:
```dart
Container(
  child: Column(
    children: [
      Text('سعر العبوة'),
      Text(
        item.unitPrice != null 
          ? '${item.unitPrice!.toStringAsFixed(2)} ج'
          : 'غير محدد',
      ),
      if (item.totalPrice != null)
        Text('إجمالي: ${item.totalPrice!.toStringAsFixed(2)} ج'),
    ],
  ),
)
```

**الفوائد:**
- ✅ شفافية أكبر للمستخدمين
- ✅ سهولة المقارنة بين العروض
- ✅ احترافية في العرض

## التغييرات التقنية

### NearExpireItemModel
```dart
// الحقول المضافة/المعدلة
final String medicineType;      // جديد
final double? totalPrice;        // بدلاً من originalPrice/discountedPrice

// الـ Getters المضافة
double? get unitPrice            // حساب السعر للعبوة
String get unitPriceText         // نص جاهز للعرض
int get monthsUntilExpiry        // عدد الأشهر المتبقية
```

### AddNearExpireItemScreen
```dart
// Controllers المعدلة
final _totalPriceController      // بدلاً من original + discounted
final _customTypeController      // للنوع المخصص

// State المضاف
int? _selectedYear;
int? _selectedMonth;
String? _selectedType;
bool _isCustomType = false;

// UI Components الجديدة
- DropdownButtonFormField للسنة
- DropdownButtonFormField للشهر
- DropdownButtonFormField لنوع الدواء
- TextFormField شرطي للنوع المخصص
```

### NearExpireItemsScreen
```dart
// التغييرات في Card العرض:
- عرض نوع الدواء كـ Badge
- عرض التاريخ بصيغة (سنة/شهر) فقط
- عرض عدد الأشهر المتبقية بدلاً من الأيام
- عرض سعر العبوة مع الإجمالي
- عرض "غير محدد" للأسعار غير المحددة
```

## Firestore Schema

### near_expire_items Collection
```javascript
{
  pharmacyId: string,
  pharmacyName: string,
  pharmacyAddress: string,
  pharmacyPhones: string[],
  pharmacyWhatsapp: string,
  medicineName: string,
  medicineType: string,              // ← جديد
  medicineDescription: string?,
  expiryDate: Timestamp,              // أول يوم من الشهر المحدد
  quantity: number,
  totalPrice: number?,                // ← جديد (nullable)
  // originalPrice: REMOVED
  // discountedPrice: REMOVED
  imageUrl: string?,
  createdAt: Timestamp,
  isActive: boolean,
  userId: string
}
```

## مثال على البيانات

### قبل:
```json
{
  "medicineName": "أسبرين",
  "expiryDate": "2024-03-15T00:00:00Z",
  "quantity": 100,
  "originalPrice": 500.0,
  "discountedPrice": 350.0
}
```

### بعد:
```json
{
  "medicineName": "أسبرين",
  "medicineType": "أقراص",
  "expiryDate": "2024-03-01T00:00:00Z",
  "quantity": 100,
  "totalPrice": 350.0
}
```
سيتم حساب: `unitPrice = 350 / 100 = 3.5 جنيه للعبوة`

## تحسينات تجربة المستخدم

### 1. السلاسة 🎯
- اختيار من القوائم أسرع من الكتابة
- لا حاجة للتحقق من صحة التواريخ (dropdowns فقط)
- تقليل الأخطاء البشرية

### 2. الوضوح 📊
- عرض سعر العبوة مباشرة
- تصنيف واضح للأدوية
- معلومات شفافة للمشترين

### 3. المرونة 💪
- السعر اختياري (للعروض غير المسعرة)
- خيار "أخرى" في الأنواع
- سهولة التعديل لاحقاً

## الملفات المعدلة

1. ✅ `lib/features/pharmacy/data/models/near_expire_item_model.dart`
   - إضافة medicineType
   - تغيير originalPrice/discountedPrice → totalPrice
   - إضافة unitPrice getter
   - إضافة monthsUntilExpiry getter

2. ✅ `lib/features/pharmacy/presentation/screens/add_near_expire_item_screen.dart`
   - استبدال Date Picker بـ Dropdowns
   - إضافة Medicine Type Selector
   - تبسيط حقول السعر
   - تحديث المنطق في _submitItem

3. ✅ `lib/features/pharmacy/presentation/screens/near_expire_items_screen.dart`
   - عرض نوع الدواء
   - عرض سعر العبوة الواحدة
   - تعديل عرض التاريخ (شهر/سنة فقط)
   - عرض "غير محدد" للأسعار

## ملاحظات مهمة

### للمطورين:
- ⚠️ البيانات القديمة في Firestore لا تحتوي على `medicineType` - سيعرض "غير محدد" افتراضياً
- ⚠️ البيانات القديمة تحتوي على `originalPrice/discountedPrice` - يجب migration إذا لزم الأمر
- ✅ الـ model يتعامل مع null safety بشكل صحيح

### للمستخدمين:
- ✨ الواجهة الجديدة أسهل وأسرع
- 💡 يمكن ترك السعر فارغاً إذا كان العرض "حسب الطلب"
- 🔍 سيتم إضافة البحث بالنوع لاحقاً

## التوافق مع النظام

✅ **الإشعارات:** لا تغيير - تعمل كما هي  
✅ **الصلاحيات:** pharmacy role فقط - لم تتغير  
✅ **Firebase Storage:** الصور تعمل بنفس الطريقة  
✅ **Real-time Updates:** StreamBuilder يعمل تلقائياً  

## الخطوات القادمة (اختياري)

1. 🔄 **Data Migration Script** لتحديث البيانات القديمة
2. 🔍 **Search & Filter** بحسب نوع الدواء
3. 📊 **Analytics** لأكثر الأنواع طلباً
4. 📱 **Push Notifications** بحسب نوع الدواء المفضل

## الخلاصة

تحديث شامل يركز على:
- ✨ بساطة الاستخدام
- 🇸🇦 تجربة عربية أصيلة
- 💰 شفافية في الأسعار
- 🏷️ تصنيف احترافي

**النتيجة:** نظام أسهل وأوضح وأكثر مرونة لجميع المستخدمين.
