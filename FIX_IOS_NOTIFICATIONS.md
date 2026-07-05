# 🔔 إصلاح iOS Notifications - خطوات إلزامية

## المشكلة
الإشعارات مش شغالة على iOS لأن **APNs (Apple Push Notification service)** مش مُعد على Firebase.

---

## ✅ الحل - 3 خطوات إلزامية

### 📱 الخطوة 1: إنشاء APNs Key من Apple Developer

1. **افتح:** https://developer.apple.com/account/resources/authkeys/list
2. **اضغط:** زر (+) لإنشاء Key جديد
3. **سمّي الـ Key:** `Mallawi Cure APNs Key`
4. **فعّل:** Apple Push Notifications service (APNs) ✅
5. **اضغط:** Continue → Register
6. **حمّل الملف:** `.p8` file (هتحمله مرة واحدة فقط!)
7. **احفظ:**
   - **Key ID** (مثال: `AB12CD34EF`)
   - **Team ID** (موجود فوق: `YRJ4DLXDZ2`)
   - **ملف .p8** (احفظه في مكان آمن!)

---

### 🔥 الخطوة 2: رفع APNs Key على Firebase

1. **افتح Firebase Console:** https://console.firebase.google.com
2. **اختر المشروع:** Mallawi Cure
3. **اضغط:** ⚙️ (Settings) → Project settings
4. **اختار:** Cloud Messaging tab
5. **في قسم Apple app configuration:**
   - اضغط على **Upload** تحت APNs Authentication Key
   - ارفع الملف `.p8`
   - احط **Key ID** (من الخطوة 1)
   - احط **Team ID**: `YRJ4DLXDZ2`
6. **اضغط:** Upload

---

### 📲 الخطوة 3: اختبار الإشعارات

#### A. Push Notifications (من Firebase):
```
1. افتح Firebase Console → Cloud Messaging
2. اختار "Send test message"
3. احط FCM Token (هيظهر في Xcode console لما تفتح التطبيق)
4. اكتب عنوان ونص الإشعار
5. اضغط Test
```

#### B. Local Notifications (من التطبيق):
```
1. افتح التطبيق
2. روح Medicine Reminders
3. اضف تذكير دواء
4. انتظر الوقت المحدد
5. الإشعار المحلي هيظهر
```

---

## 🔍 التأكد إن كل حاجة شغالة

### في Xcode Console (لما تشغل التطبيق):

```swift
✅ يجب تشوف الرسائل دي:
- "Firebase registration token: abc123..."
- "APNs token: abc123..."
- "User granted notification permission"
```

### لو شفت الرسائل دي = المشكلة:

```swift
❌ "Failed to register for remote notifications"
→ معناها: مفيش APNs Key على Firebase

❌ "User declined or has not accepted permission"
→ معناها: المستخدم رفض الإشعارات - اطلبها تاني من Settings

❌ مفيش APNs token
→ معناها: الـ APNs Key مش موجود أو غلط
```

---

## 📋 Checklist

### على Apple Developer:
- [ ] APNs Key تم إنشاءه
- [ ] ملف .p8 تم تحميله
- [ ] Key ID تم حفظه
- [ ] Team ID = YRJ4DLXDZ2

### على Firebase Console:
- [ ] ملف .p8 تم رفعه
- [ ] Key ID تم إدخاله
- [ ] Team ID تم إدخاله (YRJ4DLXDZ2)
- [ ] Bundle ID = com.mored.mallawicure

### في التطبيق:
- [ ] التطبيق يطلب Permission عند أول فتح
- [ ] FCM Token يظهر في Console
- [ ] APNs Token يظهر في Console
- [ ] Test message من Firebase يوصل

---

## 🎯 بعد كده الإشعارات هتشتغل لـ:

### 1. Push Notifications ✅
- ✅ لما حد يحجز موعد في العيادة
- ✅ لما حد يطلب دواء من الصيدلية
- ✅ لما في معمل booking جديد
- ✅ أي إشعار من Firebase

### 2. Local Notifications ✅
- ✅ تذكيرات الأدوية
- ✅ تنبيهات المواعيد
- ✅ إشعارات محلية

---

## ⚠️ ملحوظات مهمة

### 1. الـ APNs Key:
- ✅ **مهم جداً:** احفظ ملف `.p8` في مكان آمن
- ✅ Apple مبتديكش تحمله مرة تانية
- ✅ لو ضاع، هتحتاج تعمل Key جديد

### 2. Bundle ID:
- ✅ لازم يكون نفسه على Apple و Firebase: `com.mored.mallawicure`
- ✅ لو مختلف، الإشعارات مش هتشتغل

### 3. Team ID:
- ✅ لازم يكون: `YRJ4DLXDZ2`
- ✅ موجود في Apple Developer Account

### 4. Environment:
- ✅ استخدم Production APNs Key (مش Development)
- ✅ TestFlight و App Store بيستخدموا Production

---

## 🚨 مشاكل شائعة وحلولها

### المشكلة 1: Notifications مش بتوصل
**الحل:**
```
1. تأكد APNs Key موجود على Firebase
2. تأكد Bundle ID صح
3. تأكد Team ID صح (YRJ4DLXDZ2)
4. امسح التطبيق ونزله تاني
5. جرب Test message من Firebase
```

### المشكلة 2: "No APNs token"
**الحل:**
```
1. ارفع APNs Key على Firebase
2. تأكد الملف .p8 صحيح
3. تأكد Key ID صحيح
4. أعد تشغيل التطبيق
```

### المشكلة 3: Local Notifications مش شغالة
**الحل:**
```
1. افتح Settings → التطبيق → Notifications
2. تأكد Notifications مفعّلة
3. تأكد Allow Notifications = ON
4. جرب تاني
```

---

## 📞 للتأكد من الإعداد

### جرب Test Notification من Firebase:

1. افتح Firebase Console
2. Cloud Messaging → Send test message
3. احط FCM Token من Console
4. اكتب: 
   - Title: "Test"
   - Body: "This is a test notification"
5. اضغط Test

**لو وصل = كل حاجة شغالة! ✅**  
**لو مجاش = شوف الخطوات فوق تاني**

---

## ✅ الخلاصة

**الكود جاهز 100%!** ✅  
**بس محتاج APNs Key على Firebase** 🔑

بعد ما تعمل الخطوات فوق:
1. Push Notifications هتشتغل من Firebase ✅
2. Local Notifications هتشتغل من التطبيق ✅
3. كل الإشعارات هتوصل للمستخدمين ✅

---

**الكود جاهز - فقط APNs Key مطلوب!** 🚀
