# 🔔 إرسال إشعار تجريبي من Firebase Console

## الخطوات بالتفصيل

---

## 1️⃣ أولاً: احصل على FCM Token من Xcode

### في Xcode:
1. **تأكد إن التطبيق شغال** على iPhone الحقيقي
2. **افتح Console** (أسفل Xcode):
   - اضغط `Cmd + Shift + Y`
   - أو من القائمة: View → Debug Area → Show Debug Area

3. **ابحث في Console عن**:
   ```
   📱 FCM Token: dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

4. **انسخ الـ Token كامل**:
   - حدد الـ Token (كل الحروف والأرقام)
   - انسخه (Cmd + C)
   - **مهم**: الـ Token حوالي 163 حرف

**مثال على Token**:
```
daBcDeFg123456789:APA91bHxxx_yyy-zzz...
```

---

## 2️⃣ ثانياً: افتح Firebase Console

### الخطوات:

1. **افتح المتصفح** (Chrome/Safari)

2. **اذهب إلى**:
   ```
   https://console.firebase.google.com
   ```

3. **سجل دخول** بحسابك (لو مش مسجل)

4. **اختر المشروع**: 
   - `clinicalsystem-4da35`

---

## 3️⃣ ثالثاً: اذهب إلى Messaging

### في Firebase Console:

1. **من القائمة اليسار**، ابحث عن:
   - **Engage** (أيقونة 📣)
   - اضغط على **Messaging**

2. **أو اكتب في Search**: `messaging`

3. **الصفحة هتفتح**، هتلاقي:
   - "Send your first message" 
   - أو "Create your first campaign"
   - أو "New campaign"

---

## 4️⃣ رابعاً: أنشئ Campaign جديد

### الخطوات:

1. **اضغط على**: 
   - "Create your first campaign"
   - أو "New campaign" (زرار أزرق/أخضر)

2. **اختر نوع الـ Campaign**:
   - اختر: **Firebase Notification messages** (أول اختيار)
   - اضغط **Create**

---

## 5️⃣ خامساً: املأ بيانات الإشعار

### في صفحة "Compose notification":

#### **1. Notification title** (عنوان الإشعار):
```
اختبار iOS
```

#### **2. Notification text** (نص الإشعار):
```
رسالة تجريبية من Firebase
```

#### **3. (اختياري) Notification image**:
- اتركه فاضي

---

## 6️⃣ سادساً: أرسل إشعار تجريبي

### بدلاً من المتابعة للخطوة التالية:

1. **ابحث عن زر**: 
   - "Send test message" (على اليمين فوق)
   - أو في أسفل الصفحة

2. **اضغط على**: **Send test message**

3. **نافذة هتفتح**: "Add an FCM registration token"

4. **الصق FCM Token** اللي نسخته من Xcode:
   - اضغط في الحقل
   - الصق (Cmd + V)

5. **اضغط على علامة** `+` (Plus) بجانب الحقل
   - الـ Token هيتضاف للقائمة

6. **اضغط**: **Test**

---

## 7️⃣ سابعاً: راقب النتيجة

### على iPhone:

#### ✅ **إذا التطبيق مفتوح** (Foreground):
- **الإشعار يظهر** في أعلى الشاشة (banner)
- **أو** ابحث في Xcode Console عن:
  ```
  📩 Got a message whilst in the foreground!
  ```

#### ✅ **إذا التطبيق في الخلفية** (Background):
- **الإشعار يظهر** في Notification Center
- **صوت** الإشعار يشتغل

#### ✅ **إذا التطبيق مغلق** (Terminated):
- **الإشعار يظهر** في Notification Center
- **لما تضغط عليه** → التطبيق يفتح

---

## 📊 تقييم النتيجة

### ✅ الحالة 1: الإشعار وصل بنجاح

**معنى ده**:
- ✅ APNs شغال صح
- ✅ FCM Token صحيح
- ✅ Firebase configuration صحيحة
- ✅ Provisioning Profile صحيح

**يعني المشكلة في**:
- ❌ Topic Subscription (الاشتراك في Topics)
- ❌ Cloud Function (مش بتبعت صح)

**الخطوة التالية**:
اقرأ ملف: `TEST_TOPIC_SUBSCRIPTION.md` (هنشئه دلوقتي)

---

### ❌ الحالة 2: الإشعار لم يصل

**معنى ده**:
- ❌ مشكلة في APNs Configuration

**الأسباب المحتملة**:
1. APNs Key على Firebase غلط
2. Team ID مش مطابق
3. Bundle ID مش مطابق

**الخطوة التالية**:
اقرأ ملف: `FIX_APNS_CONFIGURATION.md` (هنشئه دلوقتي)

---

## 🔍 Troubleshooting

### المشكلة 1: "لا أجد FCM Token في Console"

**الحل**:
```
1. تأكد إن التطبيق شغال على iPhone حقيقي (ليس Simulator)
2. تأكد إن Console مفتوح في Xcode
3. scroll لفوق في Console
4. ابحث عن: "FCM Token"
```

**إذا لا يوجد**:
```
❌ [DEBUG] FAILED to get FCM Token!
```
→ انظر `XCODE_NOTIFICATION_DEBUG_GUIDE.md`

---

### المشكلة 2: "Firebase Console لا يقبل Token"

**السبب**: Token غير صحيح أو منسوخ بشكل خاطئ

**الحل**:
1. تأكد إنك نسخت Token كامل (من أول حرف لآخر حرف)
2. تأكد مفيش مسافات زيادة
3. جرب انسخه من جديد

---

### المشكلة 3: "لا أجد Messaging في Firebase Console"

**الحل**:
1. من القائمة اليسار، اضغط **All products**
2. ابحث عن **Messaging**
3. اضغط عليه لإضافته للقائمة

---

## 📸 لقطات شاشة توضيحية

### 1. Xcode Console - FCM Token:
```
🔧 [DEBUG] Getting FCM Token...
✅ [DEBUG] FCM Token obtained successfully!
📱 FCM Token: daBcDeFg123456789:APA91bH...
📱 Token length: 163 characters
```
→ **انسخ من بعد "FCM Token:" إلى نهاية السطر**

### 2. Firebase Console - Messaging:
```
القائمة اليسار:
  🏠 Project Overview
  🔥 Authentication
  🗄️  Firestore Database
  📦 Storage
  📊 Analytics
  📣 Engage
     ├── 🔔 Messaging  ← اضغط هنا
     └── ...
```

### 3. Send test message:
```
┌─────────────────────────────────────────────┐
│ Send test message                       ❌   │
├─────────────────────────────────────────────┤
│                                             │
│ Add an FCM registration token              │
│                                             │
│ ┌─────────────────────────────────────┐    │
│ │ Paste FCM Token here...             │ ➕  │
│ └─────────────────────────────────────┘    │
│                                             │
│ Tokens:                                     │
│ ┌─────────────────────────────────────┐    │
│ │ daBcDeFg123...                    ❌ │    │
│ └─────────────────────────────────────┘    │
│                                             │
│                          [ Test ] ← اضغط   │
└─────────────────────────────────────────────┘
```

---

## ✅ Checklist قبل الاختبار

- [ ] iPhone موصول بالكمبيوتر
- [ ] التطبيق شغال من Xcode
- [ ] Console مفتوح في Xcode
- [ ] FCM Token ظهر في Console
- [ ] FCM Token منسوخ بالكامل
- [ ] Firebase Console مفتوح
- [ ] اخترت المشروع الصحيح (clinicalsystem-4da35)
- [ ] دخلت على Messaging
- [ ] ضغطت "Send test message"
- [ ] لصقت Token وضغطت Test

---

## 📞 بعد الاختبار

**أخبرني بالنتيجة**:
- [ ] ✅ الإشعار وصل بنجاح
- [ ] ❌ الإشعار لم يصل

**وابعت لي**:
1. FCM Token (أول 20 حرف وآخر 20 حرف)
2. أي رسالة error ظهرت
3. Screenshot من Xcode Console لو ممكن

---

**جاهز؟ ابدأ الآن! 🚀**
