# 🔔 دليل نظام الإشعارات للحجوزات الأونلاين

## ✅ تم التنفيذ بنجاح!

تم إعداد نظام إشعارات متكامل للحجوزات الأونلاين. عندما يقوم مريض بحجز موعد أونلاين من عيادة معينة، يتم **تلقائياً** إرسال إشعار للجهاز المسجل دخول بإيميل العيادة.

---

## 📋 كيف يعمل النظام؟

### 1️⃣ عند تسجيل دخول صاحب العيادة:
- يتم الاشتراك تلقائياً في **Topic خاص بالعيادة** (`clinic_<clinicId>`)
- يتم حفظ **FCM Token** في Firestore
- التطبيق جاهز لاستقبال الإشعارات

### 2️⃣ عند إنشاء حجز جديد:
- يقوم المريض بملء استمارة الحجز
- يتم حفظ الحجز في Firestore collection `bookings`
- **Cloud Function** يكتشف الحجز الجديد تلقائياً
- يتم إرسال إشعار FCM إلى:
  - ✅ Topic العيادة (`clinic_<clinicId>`)
  - ✅ FCM Token الخاص بصاحب العيادة (كـ backup)

### 3️⃣ استقبال الإشعار:
- **في Foreground**: يظهر إشعار محلي (Local Notification)
- **في Background**: يظهر إشعار النظام
- **التطبيق مغلق**: يظهر إشعار النظام

---

## 🗂️ الملفات المُعدلة/المُضافة

### ✅ Firebase Cloud Functions
**الملف**: `functions/index.js`

**الدالة**: `notifyClinicOnNewBooking`
```javascript
exports.notifyClinicOnNewBooking = onDocumentCreated(
  'bookings/{bookingId}',
  async (event) => {
    // إرسال إشعار للعيادة عند إنشاء حجز جديد
  }
);
```

**تم النشر بنجاح**: ✅

---

### ✅ NotificationService
**الملف**: `lib/core/services/notification_service.dart`

**التحسينات**:
- ✅ إضافة `flutter_local_notifications` للإشعارات المحلية
- ✅ إنشاء قنوات إشعارات (Notification Channels):
  - `high_importance_channel` - عامة
  - `medicine_requests` - طلبات الأدوية
  - `clinic_bookings` - حجوزات العيادات
- ✅ عرض إشعارات محلية عندما يكون التطبيق مفتوح
- ✅ دالة `subscribeToClinicTopic()` للاشتراك في topic العيادة
- ✅ دالة `unsubscribeFromClinicTopic()` لإلغاء الاشتراك

---

### ✅ Clinic Control Page
**الملف**: `lib/features/clinic/presentation/screens/clinic_control_page.dart`

**التعديلات**:
- عند تحميل بيانات العيادة، يتم الاشتراك تلقائياً في topic العيادة
```dart
await _notificationService.subscribeToClinicTopic(
  _clinic!.id,
  authState.user.uid,
);
```

---

### ✅ Android Configuration
**الملفات المُعدلة**:
1. `android/app/src/main/AndroidManifest.xml`
   - ✅ إضافة meta-data للـ notification channels
   - ✅ إضافة default notification icon وcolor

2. `android/app/src/main/res/values/colors.xml`
   - ✅ إضافة `colorPrimary` (#3B82F6)

3. `android/app/src/main/res/drawable/ic_notification.xml`
   - ✅ إنشاء أيقونة الإشعارات (جرس)

---

## 🧪 كيفية الاختبار

### الطريقة 1️⃣: اختبار حقيقي
1. افتح التطبيق على جهاز
2. سجل دخول بإيميل عيادة
3. من جهاز آخر (أو متصفح):
   - افتح التطبيق
   - اذهب لقائمة العيادات
   - اختر عيادة لها "حجز أونلاين" مفعّل
   - احجز موعد
4. ✅ يجب أن يصل إشعار للجهاز الأول فوراً!

### الطريقة 2️⃣: اختبار بواسطة Script
استخدم الـ PowerShell script المُرفق:

```powershell
# استبدل CLINIC_ID بمعرف العيادة الحقيقي
.\test_booking_notification.ps1 -ClinicId "YourClinicId"
```

### الطريقة 3️⃣: اختبار يدوي عبر Firebase Console
1. افتح Firebase Console
2. اذهب إلى Firestore Database
3. اذهب إلى collection `bookings`
4. أضف document جديد بالبيانات التالية:
```json
{
  "patientName": "مريض تجريبي",
  "patientPhone": "01234567890",
  "clinicId": "معرف_العيادة_هنا",
  "doctorName": "د. أحمد",
  "bookingNumber": 99,
  "status": "pending",
  "createdAt": "2025-12-13T10:00:00Z",
  "notes": "حجز تجريبي"
}
```
5. ✅ يجب أن يصل الإشعار فوراً!

---

## 🔍 التحقق من عمل النظام

### ✅ Checklist:

#### 1. Firebase Functions
```bash
firebase deploy --only functions
```
تأكد من ظهور:
```
✓ functions[notifyClinicOnNewBooking(us-central1)] Successful create operation
```

#### 2. FCM Token
افتح التطبيق وابحث في Logs عن:
```
✅ User granted notification permission
📱 FCM Token: xxxxxxxxxxxxx
✅ Subscribed to clinic topic: clinic_xxxxx
✅ Notification channels created
```

#### 3. Firestore
تحقق من وجود documents في:
- `clinic_subscriptions/<clinicId>` - يحتوي على:
  - `topic`: `clinic_<clinicId>`
  - `fcmToken`: token الجهاز
  - `isActive`: true
  - `userId`: معرف المستخدم

#### 4. Cloud Function Logs
في Firebase Console → Functions → Logs:
```
✅ Booking notification sent to clinic topic: clinic_xxx
```

---

## 🎯 محتوى الإشعار

### العنوان (Title):
```
حجز جديد أونلاين 📅
```

### الرسالة (Body):
```
[اسم المريض] حجز موعد - رقم الحجز: [رقم]
```

### البيانات الإضافية (Data):
```json
{
  "type": "new_booking",
  "bookingId": "xxx",
  "clinicId": "xxx",
  "patientName": "xxx",
  "patientPhone": "xxx",
  "bookingNumber": "1",
  "doctorName": "xxx",
  "notes": "xxx"
}
```

---

## 🚨 استكشاف الأخطاء

### المشكلة: لا يصل إشعار
✅ **الحلول**:
1. تأكد من تسجيل الدخول بإيميل العيادة الصحيح
2. تحقق من Firestore → `clinic_subscriptions`
3. تحقق من أن `onlineBookingEnabled = true` للعيادة
4. راجع Firebase Functions Logs للأخطاء
5. تأكد من صلاحيات الإشعارات (Settings → Apps → Permissions)

### المشكلة: الإشعار يصل لكن لا يظهر
✅ **الحلول**:
1. تحقق من إعدادات الإشعارات في الجهاز
2. تأكد من أن قنوات الإشعارات مُفعّلة
3. أعد تثبيت التطبيق

### المشكلة: FCM Token فارغ
✅ **الحلول**:
1. تأكد من اتصال الإنترنت
2. أعد تشغيل التطبيق
3. امسح الـ cache: `flutter clean`

---

## 📊 الإحصائيات

يمكنك متابعة الإشعارات عبر:
1. **Firebase Console** → Cloud Messaging
2. **Firestore** → `bookings` collection
   - تحقق من حقل `notificationSent: true`
   - تحقق من `notificationSentAt` timestamp

---

## 🔮 تطويرات مستقبلية محتملة

- [ ] إشعار عند تأكيد/إلغاء الحجز (للمريض)
- [ ] إشعار تذكير بالموعد قبل ساعة
- [ ] إحصائيات عن الإشعارات المُرسلة
- [ ] تخصيص نغمة الإشعار
- [ ] إشعارات push للـ iOS

---

## 📞 الدعم

في حالة وجود أي مشاكل:
1. راجع Firebase Functions Logs
2. راجع Flutter Logs (`flutter logs`)
3. تحقق من Firestore Documents
4. تأكد من أن Firebase project مُفعّل ومُهيأ بشكل صحيح

---

## ✅ الخلاصة

النظام يعمل بشكل كامل! 🎉

- ✅ Cloud Functions منشورة ونشطة
- ✅ NotificationService محسّنة
- ✅ Android Channels جاهزة
- ✅ Topic Subscription تعمل تلقائياً
- ✅ Local Notifications تظهر في Foreground
- ✅ System Notifications تظهر في Background

**الآن عندما يحجز أي مريض موعد أونلاين، سيصل إشعار فوري للسكرتيرة! 🔔**
