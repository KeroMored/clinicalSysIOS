# 📊 دليل التحكم في عرض عدد المشاهدات

## نظرة عامة

نظام **viewsCount (عدد المشاهدات)** يعمل بشكل كامل في التطبيق مع إمكانية التحكم في عرضه أو إخفائه بضغطة زر واحدة.

## 🎯 كيف يعمل النظام

### 1. التخزين في قاعدة البيانات
```
✅ عدد المشاهدات يُخزن دائماً في Firestore
✅ يتم تحديثه تلقائياً عند فتح العرض
✅ لا يتأثر بإعدادات العرض/الإخفاء
```

### 2. التحكم في العرض
```
📍 المسار: app_control/offers_settings
📍 الحقل: showViewsCount
   • false = مخفي (الافتراضي)
   • true = ظاهر
```

### 3. الشاشات المتأثرة
- ✅ **شاشة عروض الأدوية** (medicine_offers_screen)
- ✅ **شاشة عروض الصيدلية الواحدة** (pharmacy_offers_list_screen)
- ✅ **شاشة جميع العروض** (all_offers_screen)

## 🚀 طرق التحكم

### الطريقة 1: من داخل التطبيق (الأسهل) ⭐

#### 1. استيراد الصفحة في تطبيقك

في أي مكان تريد الوصول للإعدادات (مثلاً في قائمة الإدارة):

```dart
import 'package:clinicalsystem/features/admin/presentation/screens/offers_settings_screen.dart';

// عند الضغط على زر الإعدادات
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const OffersSettingsScreen(),
  ),
);
```

#### 2. استخدام الصفحة
- افتح الصفحة من القائمة الإدارية
- اضغط على المفتاح (Switch) لتفعيل/تعطيل العرض
- التغيير يحدث **فوراً** في جميع الشاشات

### الطريقة 2: من Firebase Console

#### الخطوات:
1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك
3. اذهب إلى **Firestore Database**
4. افتح مجموعة `app_control`
5. افتح مستند `offers_settings`
6. غير قيمة `showViewsCount`:
   - `false` → لإخفاء عدد المشاهدات
   - `true` → لإظهار عدد المشاهدات
7. احفظ التغييرات

### الطريقة 3: من الكود مباشرة

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

// لإظهار عدد المشاهدات
await FirebaseFirestore.instance
    .collection('app_control')
    .doc('offers_settings')
    .update({'showViewsCount': true});

// لإخفاء عدد المشاهدات
await FirebaseFirestore.instance
    .collection('app_control')
    .doc('offers_settings')
    .update({'showViewsCount': false});
```

### الطريقة 4: باستخدام السكريبتات PowerShell

```powershell
# لإظهار عدد المشاهدات
.\show_views_count.ps1

# لإخفاء عدد المشاهدات
.\hide_views_count.ps1
```

## 📦 هيكل البيانات في Firestore

### مستند الإعدادات
```
app_control/
  └── offers_settings/
      ├── showViewsCount: false      # true/false
      ├── createdAt: Timestamp       # تاريخ الإنشاء
      └── updatedAt: Timestamp       # تاريخ آخر تحديث
```

### مستند العرض (مثال)
```
offers/
  └── {offerId}/
      ├── title: "خصم 20%"
      ├── description: "..."
      ├── viewsCount: 125            # ← يُخزن دائماً
      ├── category: "أدوية"
      ├── createdAt: Timestamp
      └── isActive: true
```

## 🎨 كيف يظهر في التطبيق

### عندما `showViewsCount = false` (مخفي)
```
┌─────────────────────────┐
│ 📦 خصم 20% على الأدوية │
│ 🏪 صيدلية النور         │
│ 📅 منذ يومين             │  ← فقط التاريخ
└─────────────────────────┘
```

### عندما `showViewsCount = true` (ظاهر)
```
┌─────────────────────────┐
│ 📦 خصم 20% على الأدوية │
│ 🏪 صيدلية النور         │
│ 📅 منذ يومين             │
│ 👁️ 125 مشاهدة  📁 أدوية │  ← يظهر مع الفئة
└─────────────────────────┘
```

## ⚙️ إنشاء الإعدادات للمرة الأولى

إذا لم يكن المستند موجوداً في Firestore:

### من التطبيق:
1. افتح صفحة `OffersSettingsScreen`
2. اضغط على زر **"إعادة تهيئة الإعدادات"**
3. سيتم إنشاء المستند تلقائياً

### من الكود:
```dart
final controlService = AppControlService();
await controlService.initializeOffersSettings();
```

### من PowerShell:
```powershell
.\initialize_offers_settings.ps1
```

## 🔍 التحقق من عمل النظام

### 1. تحقق من وجود المستند:
```dart
final doc = await FirebaseFirestore.instance
    .collection('app_control')
    .doc('offers_settings')
    .get();

if (doc.exists) {
  print('✅ المستند موجود');
  print('showViewsCount = ${doc.data()?['showViewsCount']}');
} else {
  print('❌ المستند غير موجود - قم بإنشائه');
}
```

### 2. اختبر التغيير:
1. افتح شاشة العروض
2. لاحظ وجود/عدم وجود عدد المشاهدات
3. غير الإعداد في Firebase
4. أعد فتح الشاشة (Pull to Refresh)
5. لاحظ التغيير الفوري

## 📝 ملاحظات مهمة

### ✅ مزايا النظام
- 🎯 **بسيط:** تغيير قيمة واحدة فقط
- ⚡ **فوري:** التغيير يحدث مباشرة
- 🔒 **آمن:** البيانات محفوظة دائماً
- 🌍 **شامل:** يؤثر على جميع الشاشات معاً

### ⚠️ تحذيرات
- لا تحذف مجموعة `app_control` من Firestore
- القيمة الافتراضية هي `false` (مخفي)
- عدد المشاهدات **يُحفظ دائماً** حتى لو كان مخفياً

### 💡 نصائح
- استخدم الصفحة الإدارية للتحكم السريع
- راقب عدد المشاهدات للتحليلات
- يمكنك إضافة إعدادات أخرى لاحقاً

## 🎓 أمثلة عملية

### مثال 1: تفعيل العرض مؤقتاً
```dart
// تفعيل لمدة أسبوع
await controlService.updateShowViewsCount(true);

// بعد أسبوع (باستخدام Cloud Functions)
await Future.delayed(Duration(days: 7));
await controlService.updateShowViewsCount(false);
```

### مثال 2: عرض حسب دور المستخدم
```dart
// للمسؤولين فقط
if (currentUser.isAdmin) {
  settings = OffersSettings(showViewsCount: true);
} else {
  settings = await controlService.getOffersSettings();
}
```

### مثال 3: إشعار عند التغيير
```dart
// الاستماع للتغييرات في الوقت الفعلي
controlService.getOffersSettingsStream().listen((settings) {
  if (settings.showViewsCount) {
    showNotification('تم تفعيل عرض المشاهدات');
  } else {
    showNotification('تم إخفاء المشاهدات');
  }
});
```

## 🔧 استكشاف الأخطاء

### المشكلة: المستند غير موجود
**الحل:** استخدم `initializeOffersSettings()` لإنشائه

### المشكلة: التغيير لا يظهر
**الحل:** 
1. تأكد من حفظ التغيير في Firestore
2. أعد تحميل الشاشة (Pull to Refresh)
3. تأكد من `_loadSettings()` يعمل في `initState()`

### المشكلة: عدد المشاهدات لا يزيد
**الحل:** 
1. تأكد من وجود `_incrementViewsCount()` في `onTap`
2. تحقق من صلاحيات Firestore Rules

## 📞 الدعم

إذا واجهت أي مشكلة:
1. تحقق من logs في Firebase Console
2. استخدم `debugPrint()` لتتبع القيم
3. راجع ملف `app_control_service.dart`

---

**آخر تحديث:** فبراير 2026
**الإصدار:** 1.0
**الحالة:** جاهز للإنتاج ✅
