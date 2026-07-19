# 🧪 اختبار iOS Push Notifications - خطوة بخطوة

## 📋 هنختبر 3 حاجات بالترتيب:

1. ✅ **FCM Token** - بيتولد؟
2. ✅ **Topic Subscription** - User بي-subscribe للـ topic؟
3. ✅ **Notification Delivery** - الإشعار بيوصل من Firebase؟

---

## 🎯 الخطوة 1: افتح المشروع في Xcode

```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
open ios/Runner.xcworkspace
```

---

## 🎯 الخطوة 2: Clean & Build

في Xcode:
1. Menu → **Product** → **Clean Build Folder** (⇧⌘K)
2. انتظر حتى ينتهي
3. **اختار جهاز iOS حقيقي** (مش simulator!)
4. Menu → **Product** → **Run** (⌘R)

---

## 🎯 الخطوة 3: شوف Console Logs

بعد ما التطبيق يفتح على الجهاز:

### في Xcode (أسفل الشاشة):
1. اضغط **Console** (أيقونة 💬 في الأسفل يمين)
2. أو: Menu → **View** → **Debug Area** → **Show Debug Area**

### في الـ Console، ابحث عن:

```
🔔 Initializing notifications...
🔐 Requesting notification permissions...
```

**انتظر من 5-10 ثواني**

---

## 📊 النتائج المحتملة:

### ✅ النتيجة 1: FCM Token موجود

```
✅ User granted notification permission
📱 FCM Token: dABC123xyz456def789ghi...
✅ Subscribed to all_users topic
```

**معنى ده:**
- ✅ APNs شغال
- ✅ Firebase متصل
- ✅ User أذن بالإشعارات

**الخطوة التالية:** Test 2 (أسفل)

---

### ❌ النتيجة 2: FCM Token = null

```
✅ User granted notification permission
📱 FCM Token: null
❌ Error: APNs token not available
```

**معنى ده:**
- ❌ APNs مش متصل بـ Firebase
- ✅ Permission موجود

**السبب:**
1. APNs Key على Firebase غلط أو مش موجود
2. أو Team ID مختلف

**الحل:**
- راجع APNs Key على Firebase (التفاصيل في Test 4 أسفل)

---

### ❌ النتيجة 3: Permission Denied

```
❌ User declined or has not accepted permission
💡 Go to Settings → Notifications to enable
```

**معنى ده:**
- User رفض الإشعارات

**الحل:**
1. Settings → (اسم التطبيق) → Notifications
2. Enable "Allow Notifications"
3. احذف التطبيق وثبته تاني
4. Run من Xcode تاني

---

## 🧪 Test 2: Send Test Notification (من Firebase)

### لو FCM Token موجود في الخطوة السابقة:

1. **انسخ الـ FCM Token كله** من Console

2. افتح Firebase Console:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/notification/compose
```

3. املا:
   - **Notification title**: اختبار iOS
   - **Notification text**: هذا اختبار من Firebase
   - **Target**: **Device** (مش Topic!)
   - **FCM registration token**: الصق الـ Token اللي نسخته

4. اضغط **"Test"** أو **"Send"**

5. **انتظر 5-10 ثواني**

---

### النتائج:

#### ✅ الإشعار ظهر على الجهاز
**يعني:**
- ✅ APNs شغال 100%
- ✅ Firebase متصل
- ✅ المشكلة مش في الـ setup

**السبب إن الإشعارات مش بتوصل للـ bookings/offers:**
- User مش بي-subscribe للـ topic الصح
- أو Cloud Function مش بيبعت للـ topic الصح

**الخطوة التالية:** Test 3 (أسفل)

---

#### ❌ الإشعار مظهرش
**يعني:**
- ❌ فيه مشكلة في Firebase → APNs connection

**الحل:**
- راجع Test 4 أسفل (APNs Configuration)

---

## 🧪 Test 3: Check Topic Subscription في Firestore

1. افتح Firestore:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/firestore
```

2. افتح Collection: **`users`**

3. ابحث عن المستخدم اللي سجلت بيه دخول

4. **شوف الـ fields:**

```json
{
  "fcmToken": "dABC123...",           ← لازم يكون موجود
  "subscribedToAllUsers": true,       ← لازم يكون true
  "allUsersTopicSubscribedAt": timestamp
}
```

**لو `fcmToken` مش موجود أو `subscribedToAllUsers` = false:**
- User مش بي-subscribe صح

**الحل:**
- امسح التطبيق من الجهاز
- Run من Xcode تاني
- سجل دخول تاني
- شوف Firestore تاني

---

### للعيادات: Check `clinic_subscriptions`

1. Collection: **`clinic_subscriptions`**
2. Document ID: **`[clinicId]`**

```json
{
  "subscribedAt": timestamp,
  "topic": "clinic_XXXXX",
  "isActive": true,
  "fcmToken": "dABC123...",
  "userId": "user123"
}
```

### للصيدليات: Check `pharmacy_subscriptions`

1. Collection: **`pharmacy_subscriptions`**
2. Document ID: **`[userId]`**

```json
{
  "subscribedAt": timestamp,
  "topic": "pharmacy_requests",
  "isActive": true,
  "fcmToken": "dABC123..."
}
```

---

## 🧪 Test 4: Check APNs Configuration على Firebase

افتح:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/settings/cloudmessaging/ios:6593a7fcafb54348189d7c
```

**تأكد من:**

### 1. APNs Authentication Key (Development)
```
✅ Development APNs auth key
   File: AuthKey_XXXXX.p8
   Key ID: [Key ID من Apple Developer]
   Team ID: [Team ID من Apple Developer]
```

### 2. APNs Authentication Key (Production)
```
✅ Production APNs auth key
   File: AuthKey_XXXXX.p8
   Key ID: [Key ID من Apple Developer]
   Team ID: [Team ID من Apple Developer]
```

**لو مفيش واحد منهم:**
- ده السبب! 🔴
- لازم ترفع الـ APNs Key

**الحل:**
1. روح Apple Developer:
```
https://developer.apple.com/account/resources/authkeys/list
```

2. اعمل APNs key جديد (لو مفيش)
3. حمل الـ `.p8` file
4. ارفعه على Firebase (Development + Production)

---

## 🧪 Test 5: Check Cloud Function Logs

بعد ما تعمل حجز أونلاين أو تنزل عرض:

1. افتح:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/logs
```

2. **ابحث عن:**

### للحجز:
```
✅ notifyClinicOnNewBooking executed
📊 Notification sent to topic: clinic_XXXXX
📱 Message ID: projects/.../messages/0:1234567890
```

### للعروض:
```
✅ notifyUsersOnNewOffer executed
📊 Notification sent to topic: all_users
📱 Message ID: projects/.../messages/0:1234567890
```

**لو مفيش logs:**
- Cloud Function مش بيتنفذ
- أو مفيش trigger

**لو فيه error:**
- انسخ الـ error وابعته لي

---

## 📱 Test 6: Test على الجهاز الحقيقي

### Test من Xcode Console:

بعد ما التطبيق يفتح:

1. **سجل دخول**
2. **انتظر 5 ثواني**
3. **شوف Console** - لازم تشوف: `✅ Subscribed to all_users topic`

4. **على جهاز تاني (أو نفس الجهاز):**
   - سجل دخول كـ **عيادة** أو **صيدلية**
   - **اعمل حجز أونلاين** أو **انزل عرض**

5. **ارجع للجهاز الأول:**
   - **المفروض:** الإشعار يظهر خلال 5-10 ثواني

---

## 🔍 Debug: شوف Notification في Console

في Xcode Console، بعد ما تبعت إشعار، لازم تشوف:

```
📩 Got a message whilst in the foreground!
📊 Message data: {type=new_booking, ...}
📬 Message notification: حجز جديد أونلاين
✅ Local notification shown
```

**لو مشفتش الرسائل دي:**
- الإشعار مش بيوصل للجهاز خالص
- يبقى المشكلة في FCM Token أو Topic Subscription

---

## 📊 Troubleshooting Checklist:

اعمل الخطوات دي بالترتيب وحدد عند أي نقطة المشكلة:

- [ ] 1. FCM Token بيظهر في Console؟
- [ ] 2. `subscribedToAllUsers: true` في Firestore؟
- [ ] 3. Test notification من Firebase (direct to device) بيوصل؟
- [ ] 4. APNs Keys موجودة على Firebase (Dev + Prod)؟
- [ ] 5. Cloud Function logs بتظهر عند الحجز/العرض؟
- [ ] 6. Topic subscription موجود في Firestore؟
- [ ] 7. Console بيوري "Got a message" عند إرسال إشعار؟

---

## 🎯 الخلاصة:

### لو FCM Token = null
→ المشكلة: APNs Key على Firebase

### لو FCM Token موجود + Test notification (direct) مش بيوصل
→ المشكلة: APNs configuration على Firebase

### لو Test notification (direct) بيوصل + Real notifications مش بتوصل
→ المشكلة: Topic subscription أو Cloud Function

### لو Cloud Function logs مفيهاش Message ID
→ المشكلة: Cloud Function مش بيبعت صح

---

## 🚀 Quick Test Commands:

### Test من Terminal:

```bash
# 1. Run app
cd /Users/georgesadek/Downloads/clinicalSys-main
flutter run

# 2. Watch logs
# (في terminal تاني)
flutter logs
```

---

**ابدأ من Test 1 و قولي إيه اللي ظهر في Console!** 🎯
