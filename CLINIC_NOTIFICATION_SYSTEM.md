# نظام إرسال الإشعارات من العيادة 🔔

## الوصف
نظام إرسال إشعارات من العيادة لجميع مستخدمي التطبيق، مشابه تماماً لنظام المعمل.

## الميزات ✨

### 1. الإرسال لجميع المستخدمين
- الدكتور يقدر يبعت إشعار لكل الناس اللي عندها التطبيق
- الإشعار بيوصل فوراً بعد الإرسال

### 2. الإشعار باسم العيادة
- الإشعار يظهر باسم: **"عيادة د. [اسم الدكتور]"**
- مثال: "عيادة د. محمد أحمد"

### 3. لوجو التطبيق (مش جرس)
- الإشعار يظهر بلوجو التطبيق الرئيسي
- استخدام: `ic_launcher_foreground`

### 4. عرض النص كامل
- مهما كان النص طويل، بيتعرض كامل في الإشعار
- باستخدام `BigTextStyle` في Android

## كيفية الاستخدام 📱

1. **الدخول للميزة:**
   - افتح إدارة العيادة
   - اضغط على زر "إرسال إشعارات"

2. **كتابة الإشعار:**
   - أدخل عنوان الإشعار (مثال: "عرض خاص اليوم")
   - أدخل محتوى الإشعار (حد أقصى 200 حرف)

3. **الإرسال:**
   - اضغط "إرسال الإشعار"
   - أكّد الإرسال
   - سيصل الإشعار لجميع المستخدمين فوراً

## الملفات المتأثرة 📁

### 1. Flutter (Dart)
```
lib/features/clinic/presentation/screens/
├── send_clinic_notification_screen.dart  (جديد)
└── clinic_control_page.dart             (معدّل)
```

### 2. Backend (Cloud Functions)
```
functions/
└── index.js  (إضافة sendClinicNotificationToUsers)
```

## التفاصيل التقنية 🔧

### Collection Name
```
clinic_notifications_broadcast
```

### Document Structure
```javascript
{
  clinicId: string,
  clinicName: string,        // اسم الدكتور
  title: string,             // عنوان الإشعار
  message: string,           // محتوى الإشعار
  createdAt: Timestamp,
  topic: 'all_users',
  sent: boolean,
  sentAt: Timestamp,         // بعد الإرسال
  messageId: string          // بعد الإرسال
}
```

### Cloud Function
```javascript
exports.sendClinicNotificationToUsers = onDocumentCreated(
  'clinic_notifications_broadcast/{notificationId}',
  async (event) => {
    // ... الكود
  }
);
```

### Notification Payload
- **Title:** `عيادة د. ${doctorName}`
- **Body:** `${title}\n${message}` (النص كامل)
- **Icon:** `ic_launcher_foreground`
- **Color:** `#0891B2` (أزرق العيادة)
- **Style:** `BigTextStyle` (عرض النص كامل)
- **Topic:** `all_users`

## الألوان المستخدمة 🎨

```dart
_primaryColor = Color(0xFF0891B2)      // أزرق فاتح
_secondaryColor = Color(0xFF06B6D4)    // أزرق متوسط
_backgroundColor = Color(0xFFF8FAFC)   // رمادي فاتح جداً
_textPrimary = Color(0xFF0F172A)       // أسود داكن
_textSecondary = Color(0xFF64748B)     // رمادي
```

## نشر التحديث 🚀

```bash
# نشر Cloud Function فقط
cd functions
firebase deploy --only functions:sendClinicNotificationToUsers

# نشر كل Cloud Functions
firebase deploy --only functions
```

## ملاحظات مهمة ⚠️

1. **الصلاحية:** فقط الدكتور (أصحاب authEmails) يقدروا يبعتوا إشعارات
2. **الحد الأقصى:** 200 حرف للمحتوى
3. **التأكيد:** يطلب تأكيد قبل الإرسال لتجنب الأخطاء
4. **الإرسال الفوري:** الإشعار يوصل في ثواني

## التطابق مع المعمل 🔬

النظام مطابق 100% لنظام المعمل من حيث:
- ✅ الوظائف
- ✅ التصميم
- ✅ طريقة الإرسال
- ✅ عرض النص الكامل
- ✅ استخدام لوجو التطبيق

الفرق الوحيد:
- اسم Collection: `clinic_notifications_broadcast` بدلاً من `lab_notifications`
- الألوان: ألوان العيادة (أزرق) بدلاً من ألوان المعمل (سماوي)
- النص: "عيادة د. X" بدلاً من "اسم المعمل"

---
تاريخ الإنشاء: 2026-03-15
