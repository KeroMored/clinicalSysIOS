# 🔍 فحص الإشعارات على iOS - دليل تفصيلي

## ✅ تم بالفعل:
1. ✅ Cloud Functions اترفعت على Firebase
2. ✅ Local Notifications (تذكير الدواء) شغالة
3. ✅ APNs Key موجود على Firebase (9QY3DKL5BG)

## ❌ المشكلة الحالية:
Push Notifications مش بتوصل (حجز أونلاين، عروض صيدليات)

---

## 🎯 خطة الفحص:

### الخطوة 1: تأكد من الـ FCM Token
لما تفتح التطبيق على iOS، شوف الـ logs في Xcode:

```bash
# المفروض تشوف في logs:
🔔 Initializing notifications...
🔐 Requesting notification permissions...
✅ User granted notification permission
📱 FCM Token: [طويل جداً مثل: dABC123...]
✅ Subscribed to all_users topic
✅ Subscribed to clinic_XXXXX topic (لو عيادة)
```

**لو FCM Token = null:**
- ده معناه APNs مش متصل صح
- لازم نتأكد من Bundle ID على Firebase

---

### الخطوة 2: تأكد من Bundle ID على Firebase

1. افتح Firebase Console:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/settings/general/ios:dc5fe68a823452fc189d7c
```

2. **تأكد إن Bundle ID = `com.mored.mallawicure`**

3. لو مش كده، لازم تعمل Update:
   - غير Bundle ID في Firebase
   - أو حمل `GoogleService-Info.plist` الجديد
   - حطه مكان القديم في `ios/Runner/`

---

### الخطوة 3: تأكد من الـ APNs Key على Firebase

1. افتح:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/settings/cloudmessaging/ios:dc5fe68a823452fc189d7c
```

2. **تأكد من:**
   - ✅ APNs Authentication Key موجود
   - ✅ Key ID: `9QY3DKL5BG`
   - ✅ Team ID: `YRJ4DLXDZ2`

3. لو مش موجود:
   - ارفع الـ APNs key تاني
   - استخدم نفس الـ .p8 file من Apple Developer

---

### الخطوة 4: اختبر Cloud Function يدوياً

افتح Firebase Console Logs:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/logs
```

**جرب تعمل:**
1. حجز أونلاين في عيادة
2. شوف الـ logs - لازم تشوف:
```
✅ notifyClinicOnNewBooking executed
📱 Notification sent to topic: clinic_XXXXX
📊 Message ID: projects/clinicalsystem-4da35/messages/XXXXX
```

**لو مفيش logs:**
- الـ Function مش بتتنفذ
- ممكن الـ trigger مش متكونفج صح

**لو فيه error في logs:**
- اكتب الـ error هنا عشان نحله

---

### الخطوة 5: تأكد من Topic Subscription

#### للعيادات:
لما تسجل دخول كـ **عيادة**، شوف الـ Firestore:
```
Collection: clinic_subscriptions
Document ID: [clinicId]

لازم يكون فيه:
{
  "subscribedAt": timestamp,
  "topic": "clinic_XXXXX",
  "isActive": true,
  "fcmToken": "dABC123...",
  "userId": "user123"
}
```

#### للمستخدمين العاديين:
```
Collection: users
Document ID: [userId]

لازم يكون فيه:
{
  "fcmToken": "dABC123...",
  "subscribedToAllUsers": true,
  "allUsersTopicSubscribedAt": timestamp
}
```

#### للصيدليات:
```
Collection: pharmacy_subscriptions
Document ID: [userId]

لازم يكون فيه:
{
  "subscribedAt": timestamp,
  "topic": "pharmacy_requests",
  "isActive": true,
  "fcmToken": "dABC123..."
}
```

---

### الخطوة 6: اختبر بـ Test Notification

#### من Firebase Console:
1. روح: https://console.firebase.google.com/project/clinicalsystem-4da35/notification
2. اضغط "New notification"
3. اكتب:
   - Title: "اختبار"
   - Text: "هذا اختبار"
4. Target: **Topic**
5. Topic name: `all_users`
6. اضغط "Test" أو "Send"

**لو وصل الإشعار:**
✅ Firebase + APNs شغالين
❌ المشكلة في الـ Code

**لو مش واصل:**
❌ المشكلة في APNs setup

---

### الخطوة 7: شوف الـ Capabilities في Xcode

افتح المشروع في Xcode:
```bash
open ios/Runner.xcworkspace
```

تأكد من:
1. **Signing & Capabilities** tab
2. **Background Modes** enabled:
   - ✅ Remote notifications
3. **Push Notifications** enabled

---

## 🔧 الحلول المحتملة:

### الحل 1: FCM Token = null

**السبب:** APNs مش متصل

**الحل:**
1. تأكد Bundle ID صح: `com.mored.mallawicure`
2. حمل `GoogleService-Info.plist` جديد من Firebase
3. حطه في `ios/Runner/`
4. Clean build:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

---

### الحل 2: Notification بتوصل لكن مش بتظهر

**السبب:** Foreground notifications مش متفعلة

**الحل:** التطبيق بالفعل بيعمل handle للـ foreground notifications في `notification_service.dart`

---

### الحل 3: Cloud Function بتنفذ لكن مفيش notification

**السبب:** المستخدم مش subscribed للـ topic

**الحل:**
1. امسح التطبيق من الجهاز
2. ثبته تاني
3. سجل دخول تاني
4. شوف الـ Firestore - لازم الـ subscription يتسجل

---

### الحل 4: Error في Cloud Function logs

**شوف الـ errors الشائعة:**

#### Error: "Requested entity was not found"
```
السبب: App مش موجود على Firebase أو Bundle ID غلط
الحل: تأكد من Bundle ID في Firebase Console
```

#### Error: "APNs certificate or auth key not valid"
```
السبب: APNs key غلط أو منتهي
الحل: ارفع APNs key تاني من Apple Developer
```

#### Error: "Topic name is invalid"
```
السبب: Topic name فيه مسافات أو رموز غريبة
الحل: تأكد إن clinic ID أو lab ID مفيهوش مسافات
```

---

## 🧪 اختبار شامل:

### السيناريو 1: حجز أونلاين
1. سجل دخول كـ **مستخدم عادي**
2. احجز موعد في **عيادة** (اختار "حجز أونلاين")
3. **المتوقع:**
   - العيادة تستلم إشعار خلال **5 ثواني**
   - الإشعار يظهر حتى لو التطبيق مفتوح (foreground)

### السيناريو 2: عرض صيدلية
1. سجل دخول كـ **صيدلية**
2. أضف **عرض جديد** (صورة + وصف)
3. **المتوقع:**
   - كل المستخدمين يستلموا إشعار خلال **5 ثواني**
   - الإشعار يظهر لكل اللي عندهم التطبيق

### السيناريو 3: طلب دواء
1. سجل دخول كـ **مستخدم عادي**
2. اطلب **دواء**
3. **المتوقع:**
   - كل الصيدليات تستلم إشعار خلال **5 ثواني**

---

## 📋 Checklist للفحص:

اعمل الخطوات دي بالترتيب وقولي عند أي خطوة المشكلة:

- [ ] **1. افتح التطبيق وشوف الـ logs** - فيه FCM Token؟
- [ ] **2. تأكد من Bundle ID** - `com.mored.mallawicure`؟
- [ ] **3. تأكد من APNs Key** - Key ID: `9QY3DKL5BG`؟
- [ ] **4. اعمل حجز أونلاين** - شوف logs في Firebase
- [ ] **5. افتح Firestore** - فيه `clinic_subscriptions`؟
- [ ] **6. جرب Test Notification** - وصل؟
- [ ] **7. شوف Cloud Function logs** - فيه errors؟

---

## 🚨 أسئلة مهمة:

عشان أقدر أساعدك، قولي:

1. **لما بتفتح التطبيق، بيطلع FCM Token في الـ logs؟**
   - لو آه، ابعتلي أول 10 أحرف منه
   - لو لا، يبقى المشكلة في APNs setup

2. **Bundle ID على Firebase = `com.mored.mallawicure`؟**
   - تأكد من الرابط: https://console.firebase.google.com/project/clinicalsystem-4da35/settings/general

3. **لما بتعمل حجز أونلاين، بيتسجل في Firestore؟**
   - شوف Collection: `bookings`
   - لازم يكون فيه field: `isOnlineBooking: true`

4. **جربت تبعت Test Notification من Firebase Console؟**
   - لو آه، وصل؟
   - لو لا، يبقى المشكلة مش في الـ Code

5. **شفت logs في Firebase Console؟**
   - فيه أي errors؟
   - الـ Functions بتتنفذ؟

---

**قولي إجابات الأسئلة دي وهقدر أحدد المشكلة بالظبط! 🎯**
