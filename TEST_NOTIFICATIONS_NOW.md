# 🧪 اختبار الإشعارات الآن - خطوة بخطوة

## المشكلة
عند إضافة **عرض صيدلية** أو **حجز أونلاين** → الإشعار لا يصل على iOS (لكن يصل على Android)

---

## 🎯 خطة الاختبار

### الإعداد المطلوب:
1. **جهازين/إيميوليتور**:
   - **جهاز 1**: صاحب صيدلية/عيادة (هيستقبل الإشعار)
   - **جهاز 2**: مريض (هيبعت طلب/حجز)

2. **أو اختبار العروض**:
   - **جهاز 1**: صاحب صيدلية (هيضيف عرض)
   - **جهاز 2**: أي مستخدم (المفروض يستقبل الإشعار)

---

## 📱 السيناريو 1: اختبار إشعار الحجز الأونلاين

### على Xcode (للتشخيص):

#### الخطوة 1: شغل التطبيق على جهاز حقيقي (iPhone)
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
open ios/Runner.xcworkspace
```
- اختر جهازك الحقيقي من القائمة (ليس Simulator)
- اضغط Run (▶️)

#### الخطوة 2: سجل دخول كصاحب عيادة
- افتح الـ Console في Xcode (أسفل الشاشة)
- راقب الـ logs

**لازم تشوف:**
```
🔧 [DEBUG] Starting notification initialization...
✅ [DEBUG] Local notifications initialized
✅ User granted notification permission
✅ [DEBUG] FCM Token obtained successfully!
📱 FCM Token: [TOKEN هنا]
```

**وبعدين لما تدخل للعيادة:**
```
🔧 [DEBUG] Subscribing clinic [CLINIC_ID] to topic: clinic_[CLINIC_ID]
✅ Subscribed to clinic topic: clinic_[CLINIC_ID]
📱 FCM Token for clinic: [TOKEN]
✅ [DEBUG] Clinic subscription saved to Firestore
```

#### الخطوة 3: من جهاز تاني (Android أو iOS)
- سجل دخول كمريض
- احجز موعد أونلاين في العيادة

#### الخطوة 4: راقب Console في Xcode
**المفروض يظهر:**
```
═══════════════════════════════════════════════════════════
📩 Got a message whilst in the foreground!
📊 Message data: {type: new_booking, clinicId: xxx, ...}
📊 Message ID: xxx
📬 Message notification:
   Title: حجز جديد - عيادة د. [اسم الدكتور]
   Body: [اسم المريض] حجز موعد...
✅ Local notification displayed
═══════════════════════════════════════════════════════════
```

---

## 📱 السيناريو 2: اختبار إشعار عرض الصيدلية

#### الخطوة 1: شغل على جهاز حقيقي كمستخدم عادي
```bash
open ios/Runner.xcworkspace
```

#### الخطوة 2: راقب Console عند تسجيل الدخول
```
🔧 [DEBUG] Subscribing user [USER_ID] to all_users topic...
✅ Subscribed to all_users topic
📱 [DEBUG] FCM Token for all_users subscription: [TOKEN]
```

#### الخطوة 3: من جهاز تاني (Android أو iOS)
- سجل دخول كصاحب صيدلية
- أضف عرض جديد

#### الخطوة 4: راقب Console
**المفروض يظهر:**
```
═══════════════════════════════════════════════════════════
📩 Got a message whilst in the foreground!
📊 Message data: {type: new_pharmacy_offer, pharmacyId: xxx, ...}
📬 Message notification:
   Title: عرض جديد من [اسم الصيدلية]
   Body: [وصف العرض]
✅ Local notification displayed
═══════════════════════════════════════════════════════════
```

---

## 🔍 التشخيص بناءً على النتيجة

### ✅ حالة 1: FCM Token ظهر بنجاح
**معنى ده**: APNs شغال صح

**لكن الإشعار مش واصل؟** → المشكلة في:
1. **Topic Subscription** مش شغالة صح
2. **Cloud Function** مش بتبعت للـ Topic الصحيح
3. **Firestore** مش بيحفظ الـ FCM Token صح

**الحل**: 
- تحقق من Firestore Collections:
  - `clinic_subscriptions` → لازم يكون فيه document للعيادة
  - `pharmacy_subscriptions` → لازم يكون فيه document للصيدلية
  - `users` → لازم يكون فيه `fcmToken` و `subscribedToAllUsers: true`

---

### ❌ حالة 2: FCM Token = null
**معنى ده**: APNs مش شغال

**السبب المحتمل**:
1. **Push Notifications capability** مش مضاف في Xcode
2. **Provisioning Profile** مش بيدعم Push
3. **APNs Key** مش مرفوع على Firebase أو غلط
4. **Team ID** في Xcode مش بيطابق الـ APNs Key

**الحل**:
انظر `XCODE_NOTIFICATION_DEBUG_GUIDE.md` → Problem 1

---

### ⚠️ حالة 3: لا يوجد logs في Console
**معنى ده**: التطبيق مش بيعمل initialize للـ notifications

**الحل**:
تأكد من `main.dart` بينادي على:
```dart
await notificationService.initialize();
await notificationService.handleForegroundNotifications();
```

---

## 🧰 أدوات التشخيص السريع

### 1. تحقق من Firestore (Firebase Console)

#### A. للعيادة:
```
Collection: clinic_subscriptions
Document ID: [CLINIC_ID]

Expected Fields:
- subscribedAt: timestamp
- topic: "clinic_[CLINIC_ID]"
- isActive: true
- fcmToken: "xxx"
- userId: "xxx"
```

#### B. للصيدلية:
```
Collection: pharmacy_subscriptions
Document ID: [USER_ID]

Expected Fields:
- subscribedAt: timestamp
- topic: "pharmacy_requests"
- isActive: true
- fcmToken: "xxx"
```

#### C. للمستخدمين:
```
Collection: users
Document ID: [USER_ID]

Expected Fields:
- fcmToken: "xxx"
- subscribedToAllUsers: true
- allUsersTopicSubscribedAt: timestamp
```

### 2. تحقق من Cloud Function Logs

على Windows (حيث Firebase CLI):
```bash
firebase functions:log --only notifyClinicOnNewBooking
```

**ابحث عن**:
```
Booking notification sent to clinic topic: clinic_xxx
```

**إذا وجدت Error**:
- `INVALID_ARGUMENT` → Topic name غلط
- `NOT_FOUND` → Booking document مش موجود
- `PERMISSION_DENIED` → Function لا تملك صلاحيات

---

## 🚀 خطوات الاختبار السريع (الآن)

### 1. شغل Xcode وافتح Console
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
open ios/Runner.xcworkspace
```

### 2. شغل على جهاز حقيقي
- اختر iPhone من القائمة
- Run (▶️)

### 3. راقب Console وابحث عن:
- `📱 FCM Token:` → انسخه وابعته لي
- `✅ Subscribed to` → لازم يظهر

### 4. جرب إرسال:
- **حجز أونلاين** (من جهاز تاني)
- **عرض صيدلية** (من جهاز تاني)

### 5. انظر Console:
- **هل ظهر** `📩 Got a message`؟
  - ✅ نعم → APNs شغال، نكمل تشخيص
  - ❌ لا → مشكلة في APNs أو Cloud Function

---

## 📋 Checklist للإبلاغ

بعد التجربة، أخبرني بالنتيجة:

- [ ] **FCM Token ظهر؟** (نعم/لا)
- [ ] **Topic Subscription نجحت؟** (نعم/لا)
- [ ] **Cloud Function اشتغلت؟** (شوف Logs)
- [ ] **رسالة `📩 Got a message` ظهرت؟** (نعم/لا)
- [ ] **الإشعار فعلاً ظهر على الشاشة؟** (نعم/لا)

وابعت لي:
1. الـ **FCM Token** من Console
2. أي **Errors** ظهرت
3. الـ **logs** اللي ظهرت عند الاشتراك في Topic

---

**جاهز للاختبار؟ شغل Xcode واخبرني النتيجة! 🚀**
