# نظام جدولة المواعيد للعيادات - Appointment Scheduling System

## 📅 ملخص التحديث

تم إضافة نظام كامل لجدولة مواعيد الكشف في العيادات، مما يسمح بحجز المواعيد لتواريخ مستقبلية وليس فقط اليوم الحالي.

## ✨ المزايا الجديدة

### 1. حقل موعد الكشف (appointmentDate)
- تم إضافة حقل `appointmentDate` إلى `BookingModel`
- يحدد التاريخ والوقت الفعلي للكشف (وليس وقت إنشاء الحجز)
- الافتراضي: الوقت الحالي عند الحجز

### 2. اختيار الموعد من السكرتيرة
**في شاشة الحجز من العيادة:**
- Date Picker لاختيار التاريخ
- Time Picker لاختيار الوقت
- الافتراضي: التاريخ والوقت الحالي
- يمكن تغيير الموعد لأي تاريخ مستقبلي

**كيف يعمل:**
```dart
DateTime selectedAppointmentDate = DateTime.now(); // الافتراضي

// عند الحجز
final booking = BookingModel(
  // ... باقي البيانات
  appointmentDate: selectedAppointmentDate, // الموعد المحدد
  createdAt: DateTime.now(), // وقت إنشاء الحجز
);
```

### 3. اختيار الموعد للمريض (الحجز الأونلاين)
**في شاشة الحجز للمريض:**
- Date Picker جميل وسهل الاستخدام
- الافتراضي: اليوم الحالي
- يمكن اختيار أي تاريخ حتى سنة قادمة

### 4. الترقيم الذكي للحجوزات
**الترقيم يعتمد على تاريخ الموعد:**
- كل يوم له أرقام حجز مستقلة تبدأ من 1
- إذا حجزت لبعد 3 أيام، يأخذ رقم 1 في ذلك اليوم
- لا يتأثر بحجوزات الأيام الأخرى

**مثال:**
```
اليوم الحالي (الخميس):
- حجز 1: أحمد (موعد اليوم)
- حجز 2: محمد (موعد اليوم)

السبت القادم:
- حجز 1: علي (موعد السبت) ← يأخذ رقم 1 لأنه أول حجز في ذلك اليوم
- حجز 2: فاطمة (موعد السبت)
```

### 5. عرض الحجوزات حسب الموعد
**في صفحة إدارة الحجوزات:**
- تظهر فقط حجوزات اليوم الحالي
- الحجوزات المستقبلية لا تظهر حتى يأتي موعدها
- عند إنهاء اليوم، يتم أرشفة حجوزات اليوم فقط

### 6. التقويم (Calendar View) 📆
**ميزة جديدة رائعة:**
- زر تقويم في أعلى شاشة إدارة الحجوزات
- يعرض التقويم بالشهر الحالي
- **نقاط حمراء** على الأيام التي فيها حجوزات
- عند الضغط على يوم معين، يظهر dialog بكل حجوزات ذلك اليوم

**محتويات Dialog الحجوزات:**
- رقم الحجز
- اسم المريض
- حالة الحجز (مؤكد/في الانتظار/تم الكشف)
- وقت الموعد
- رقم الهاتف

## 🔧 التغييرات التقنية

### 1. BookingModel
```dart
class BookingModel {
  final DateTime appointmentDate; // جديد ✨
  final DateTime createdAt; // وقت إنشاء الحجز
  // ... باقي الحقول
}
```

### 2. Firestore Queries
**قبل:**
```dart
.where('createdAt', isGreaterThanOrEqualTo: startOfDay)
.where('createdAt', isLessThanOrEqualTo: endOfDay)
```

**بعد:**
```dart
.where('appointmentDate', isGreaterThanOrEqualTo: startOfDay)
.where('appointmentDate', isLessThanOrEqualTo: endOfDay)
```

### 3. دالة الترقيم
```dart
Future<int> _getNextBookingNumber(DateTime appointmentDate) async {
  // تحميل حجوزات نفس يوم الموعد (وليس اليوم الحالي)
  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('clinicId', isEqualTo: clinicId)
      .where('appointmentDate', isGreaterThanOrEqualTo: startOfDay)
      .where('appointmentDate', isLessThanOrEqualTo: endOfDay)
      .get();
  
  // إرجاع أكبر رقم + 1
}
```

### 4. Calendar Widget
```dart
class _CalendarViewWidget extends StatefulWidget {
  // استخدام table_calendar package
  // تحميل الحجوزات للشهر الحالي
  // عرض markers (نقاط حمراء) على الأيام التي فيها حجوزات
  // dialog عند الضغط على يوم
}
```

## 📦 Dependencies المستخدمة

```yaml
table_calendar: ^3.1.2  # للتقويم
intl: 0.20.2  # للتواريخ العربية
```

## 🚀 الإعدادات المطلوبة

### في main.dart
```dart
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale for calendar
  await initializeDateFormatting('ar', null);
  
  // ... باقي الكود
}
```

## 📱 استخدام الميزات

### للسكرتيرة
1. افتح شاشة إدارة الحجوزات
2. اضغط "حجز جديد"
3. أدخل بيانات المريض
4. **اختر موعد الكشف** (التاريخ والوقت)
5. اضغط "إضافة"

### للمريض (الحجز الأونلاين)
1. افتح شاشة حجز موعد
2. أدخل البيانات
3. **اختر موعد الكشف من التقويم**
4. اضغط "تأكيد الحجز"

### لعرض التقويم
1. افتح شاشة إدارة الحجوزات
2. اضغط على أيقونة التقويم 📅 في الأعلى
3. تصفح الأشهر
4. اضغط على أي يوم به حجوزات لرؤية التفاصيل

## ⚠️ ملاحظات مهمة

1. **التوافق مع البيانات القديمة:**
   - الحجوزات القديمة التي لا تحتوي على `appointmentDate` سيتم تعيين `createdAt` لها تلقائياً
   
2. **إنهاء اليوم:**
   - يتم أرشفة حجوزات اليوم الحالي فقط (حسب `appointmentDate`)
   
3. **الأداء:**
   - يتم تحميل حجوزات شهر واحد فقط في التقويم
   - يتم إعادة التحميل عند تغيير الشهر

## 🎨 التصميم

- استخدام ألوان النظام (الأزرق #3B82F6)
- نقاط حمراء واضحة على التقويم
- Dialog جميل ومنظم لعرض الحجوزات
- Date/Time Pickers بتصميم عصري

## 🔄 التحديثات المستقبلية المقترحة

1. **إشعارات:**
   - إرسال تذكير للمريض قبل الموعد بيوم
   
2. **تصفية:**
   - إضافة فلتر لعرض حجوزات أسبوع/شهر محدد
   
3. **إحصائيات:**
   - عدد الحجوزات المستقبلية
   - أكثر الأيام حجزاً

## ✅ الملفات المعدلة

1. `lib/features/clinic/data/models/booking_model.dart` - إضافة appointmentDate
2. `lib/features/clinic/presentation/screens/bookings_management_screen.dart` - التقويم والتحديثات
3. `lib/features/clinic/presentation/screens/book_appointment_screen.dart` - Date picker للمريض
4. `lib/main.dart` - إضافة locale للتقويم

---

**تم التنفيذ بنجاح!** ✨🎉
