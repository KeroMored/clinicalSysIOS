# 📱 تشغيل التطبيق على جهاز حقيقي للاختبار

## ⚠️ مهم جداً
**iOS Simulator لا يدعم Push Notifications إطلاقاً!**

لاختبار الإشعارات، لازم تشغل على **iPhone حقيقي**.

---

## 🚀 خطوات التشغيل على جهاز حقيقي

### الطريقة 1: من Xcode (الأفضل للتشخيص)

#### 1. وصّل الـ iPhone بالكمبيوتر
- استخدم كابل USB

#### 2. افتح المشروع في Xcode
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
open ios/Runner.xcworkspace
```

#### 3. اختر جهازك
- من القائمة العلوية في Xcode
- اختر اسم جهازك (مثلاً "George's iPhone")
- **لا تختار** Simulator

#### 4. اضغط Run (▶️)
- أو اضغط `Cmd + R`

#### 5. إذا ظهرت مشاكل Trust:
- على الـ iPhone: Settings → General → Device Management
- اضغط على اسم الـ Developer
- اضغط Trust

#### 6. افتح Console في Xcode
- من القائمة: View → Debug Area → Show Debug Area
- أو اضغط `Cmd + Shift + Y`

---

### الطريقة 2: من VS Code أو Terminal

#### 1. وصّل الـ iPhone

#### 2. تحقق من الأجهزة المتصلة:
```bash
flutter devices
```

**المفروض يظهر**:
```
George's iPhone • xxx • ios • iOS 17.x
```

#### 3. شغل التطبيق:
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
flutter run -d [DEVICE_ID]
```

#### 4. راقب الـ logs:
```bash
# الـ logs هتظهر في Terminal
# ابحث عن:
# 📱 FCM Token:
# ✅ Subscribed to
```

---

## 🔍 ما تبحث عنه في Console/Logs

### عند فتح التطبيق:
```
🔧 [DEBUG] Starting notification initialization...
✅ [DEBUG] Local notifications initialized
✅ [DEBUG] Notification channels created
🔧 [DEBUG] Requesting notification permissions...
🔧 [DEBUG] Permission status: AuthorizationStatus.authorized
✅ User granted notification permission
🔧 [DEBUG] Getting FCM Token...
✅ [DEBUG] FCM Token obtained successfully!
📱 FCM Token: dxxx...xxx
📱 Token length: 163 characters
✅ [DEBUG] Notification initialization complete
```

### عند تسجيل الدخول كصاحب عيادة:
```
🔧 [DEBUG] Subscribing clinic abc123 to topic: clinic_abc123
✅ Subscribed to clinic topic: clinic_abc123
📱 FCM Token for clinic: dxxx...xxx
✅ [DEBUG] Clinic FCM Token is valid (163 chars)
✅ [DEBUG] Clinic subscription saved to Firestore
✅ [DEBUG] User document updated with FCM token
```

### عند تسجيل الدخول كصاحب صيدلية:
```
🔧 [DEBUG] Subscribing pharmacy xyz789 to topic...
✅ Subscribed to pharmacy topic: pharmacy_requests
📱 FCM Token: dxxx...xxx
✅ [DEBUG] FCM Token is valid (163 chars)
✅ [DEBUG] Pharmacy subscription saved to Firestore
```

### عند استقبال إشعار:
```
═══════════════════════════════════════════════════════════
📩 Got a message whilst in the foreground!
📊 Message data: {type: new_booking, clinicId: abc123, ...}
📊 Message ID: 0:1234567890%abc123
📊 Sent time: 2024-01-15 12:34:56
📬 Message notification:
   Title: حجز جديد - عيادة د. أحمد
   Body: محمد علي حجز موعد كشف - اليوم الساعة 14:30
   Android channel: clinic_bookings
✅ Local notification displayed
═══════════════════════════════════════════════════════════
```

---

## 🧪 سيناريوهات الاختبار

### Test 1: اختبار FCM Token

**الهدف**: التأكد من أن APNs يعمل

**الخطوات**:
1. شغل التطبيق على iPhone حقيقي
2. افتح التطبيق
3. انظر Console/Logs
4. ابحث عن: `📱 FCM Token:`

**النتيجة المتوقعة**:
- ✅ FCM Token يظهر (163 حرف تقريباً)
- ❌ FCM Token = null → APNs مش شغال

---

### Test 2: اختبار Topic Subscription

**الهدف**: التأكد من الاشتراك في Topics

**الخطوات**:
1. سجل دخول كصاحب عيادة/صيدلية
2. انظر Console
3. ابحث عن: `✅ Subscribed to`

**النتيجة المتوقعة**:
- ✅ يظهر رسالة Subscription
- ✅ FCM Token يُحفظ في Firestore

---

### Test 3: اختبار استقبال الإشعارات

**الهدف**: التأكد من وصول الإشعارات

**الإعداد**:
- **iPhone 1** (Xcode): صاحب عيادة/صيدلية
- **iPhone 2** أو **Android**: مريض/مستخدم

**الخطوات**:
1. على iPhone 1: افتح التطبيق كصاحب عيادة
2. انتظر حتى يكتمل Subscription
3. على iPhone 2: احجز موعد أونلاين في العيادة
4. انظر Console في Xcode على iPhone 1
5. ابحث عن: `📩 Got a message`

**النتيجة المتوقعة**:
- ✅ رسالة `📩 Got a message` تظهر في Console
- ✅ إشعار يظهر على شاشة iPhone
- ❌ لا شيء يظهر → مشكلة في Cloud Function أو Topic

---

## 🔧 إذا لم يعمل

### مشكلة 1: لا يوجد FCM Token
```
❌ [DEBUG] FAILED to get FCM Token!
```

**الحل**:
1. تأكد من **Push Notifications** capability في Xcode
2. تأكد من **Provisioning Profile** يدعم Push
3. تأكد من **Internet** متصل
4. جرب **Clean Build**: `Cmd + Shift + K`
5. امسح التطبيق من الجهاز وأعد التثبيت

---

### مشكلة 2: FCM Token موجود لكن لا إشعارات

**السبب المحتمل**:
- Cloud Function مش بتبعت
- Topic Subscription فشلت
- APNs Key غلط على Firebase

**الحل**:
1. تحقق من Cloud Function Logs:
   ```bash
   firebase functions:log --only notifyClinicOnNewBooking
   ```

2. تحقق من Firestore:
   - `clinic_subscriptions/[CLINIC_ID]` → يحتوي fcmToken؟
   - `users/[USER_ID]` → يحتوي fcmToken؟

3. تحقق من Firebase Console → Cloud Messaging:
   - APNs Key مرفوع؟
   - Team ID صحيح؟

---

### مشكلة 3: رسالة تصل في Console لكن لا تظهر على الشاشة

**السبب**: Notification permissions مش ممنوحة

**الحل**:
1. على iPhone: Settings → [اسم التطبيق] → Notifications
2. تأكد من **Allow Notifications** مفعّل
3. تأكد من **Alerts** مفعّل

---

## 📊 Quick Test: أرسل إشعار من Firebase Console

### الخطوات:

1. **احصل على FCM Token** من Xcode Console:
   ```
   📱 FCM Token: dxxx...xxx
   ```

2. **افتح Firebase Console**:
   - https://console.firebase.google.com
   - اختر Project: `clinicalsystem-4da35`

3. **اذهب إلى Messaging**:
   - Cloud Messaging → Create your first campaign
   - أو: Cloud Messaging → Send test message

4. **أرسل Test Notification**:
   - Title: `اختبار iOS`
   - Text: `هل وصل؟`
   - Add device token → الصق FCM Token
   - Send

5. **انظر النتيجة**:
   - ✅ وصل → APNs يعمل، المشكلة في Topic Subscription
   - ❌ لم يصل → مشكلة في APNs Configuration

---

## 📞 بعد التجربة أخبرني بـ:

1. **هل FCM Token ظهر؟**
   - [ ] نعم (الصق Token)
   - [ ] لا

2. **هل Topic Subscription نجحت؟**
   - [ ] نعم
   - [ ] لا

3. **هل Test Notification من Firebase وصل؟**
   - [ ] نعم
   - [ ] لا

4. **هل رسالة `📩 Got a message` ظهرت عند إرسال حجز/عرض؟**
   - [ ] نعم
   - [ ] لا

5. **أي Errors ظهرت؟**
   - الصق الـ Error هنا

---

**الخلاصة**: لازم جهاز iPhone حقيقي للاختبار. وصّله وشغل من Xcode! 📱
