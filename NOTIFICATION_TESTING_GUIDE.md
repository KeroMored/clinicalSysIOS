# Test Notifications

## اختبار إشعارات طلب الأدوية

### الخطوات:
1. فتح التطبيق على جهازين (مستخدم + صيدلية)
2. تسجيل دخول الصيدلية أولاً (ليتم الاشتراك في pharmacy_requests topic)
3. من حساب المستخدم: إضافة طلب دواء جديد
4. الانتظار 3-5 ثواني
5. التحقق من وصول إشعار للصيدلية

### المتوقع:
- ✅ إشعار للصيدلية: "طلب دواء جديد 💊"
- ✅ محتوى الإشعار: "{userName} يطلب {عدد الأدوية} أدوية" أو "{اسم الدواء}"

## اختبار إشعارات العروض

### الخطوات:
1. تسجيل دخول مستخدم عادي أولاً (ليتم الاشتراك في all_users topic)
2. من حساب صيدلية: إضافة عرض جديد
3. الانتظار 3-5 ثواني
4. التحقق من وصول إشعار للمستخدم

### المتوقع:
- ✅ إشعار للمستخدم: "عرض جديد من {اسم الصيدلية} 🎉"
- ✅ محتوى الإشعار: {عنوان العرض} أو {وصف العرض}

## في حالة عدم وصول الإشعارات

### 1. التأكد من topic subscription
```dart
// يجب أن يظهر في logs عند تسجيل الدخول:
✅ Subscribed to all_users topic
✅ Subscribed to pharmacy topic: pharmacy_requests
```

### 2. التأكد من Cloud Functions
```powershell
firebase functions:log --only notifyPharmaciesOnNewRequest
# يجب ظهور:
# ✅ Notification sent to pharmacy topic
```

### 3. التحقق من FCM Token
- افتح Firestore Console
- ادخل على users collection
- تأكد من وجود fcmToken و subscribedToAllUsers: true

### 4. إعادة تسجيل الدخول
- تسجيل الخروج من التطبيق
- إعادة تسجيل الدخول
- سيتم إعادة subscription تلقائياً

## اختبار يدوي عبر HTTP

### اختبار topic notification:
```powershell
Invoke-RestMethod -Uri "https://sendtestnotification-7fj456gn6q-uc.a.run.app" -Method Get
```

**المتوقع**: إشعار اختبار لكل الصيدليات المشتركة في pharmacy_requests

## ملاحظات هامة

1. **المستخدمون الحاليون**: يجب إعادة تسجيل الدخول ليتم الاشتراك في topics
2. **المستخدمون الجدد**: يتم الاشتراك تلقائياً
3. **إشعارات الخلفية**: تعمل حتى لو التطبيق مغلق
4. **إشعارات Foreground**: تظهر كـ local notification

## التوقيت المتوقع

- **Medicine Request** → Pharmacy: 2-5 ثواني
- **Offer Added** → All Users: 2-5 ثواني
- **Clinic Booking** → Clinic Owners: 2-5 ثواني

## الإشعارات في الخلفية vs Foreground

### Foreground (التطبيق مفتوح):
- يتم عرض notification عبر `flutter_local_notifications`
- يظهر banner في أعلى الشاشة

### Background/Terminated (التطبيق مغلق):
- يتم عرض notification من نظام التشغيل مباشرة
- يظهر في notification tray

## استكشاف الأخطاء

### الإشعار لا يظهر:
1. تأكد من أذونات الإشعارات (Settings → App → Notifications)
2. تأكد من تسجيل دخول المستخدم
3. تأكد من Cloud Function تم تشغيلها (logs)
4. تأكد من topic subscription (Firestore users collection)

### الإشعار يظهر متأخر:
- طبيعي - FCM قد يأخذ حتى 30 ثانية أحياناً
- في الإنتاج عادة أسرع (2-5 ثواني)

### الإشعار يظهر باللغة الإنجليزية:
- تحقق من index.js - يجب أن يكون النص بالعربية
- تأكد من deployment الأخير تم بنجاح
