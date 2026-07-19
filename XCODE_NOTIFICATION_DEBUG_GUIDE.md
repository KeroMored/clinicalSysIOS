# 🔍 دليل تشخيص إشعارات iOS على Xcode

## المشكلة الحالية
- ✅ **الإشعارات المحلية (Medicine Reminders)** تعمل بشكل صحيح
- ✅ **Android Push Notifications** تعمل بشكل صحيح
- ❌ **iOS Push Notifications** لا تعمل (Clinic Bookings, Pharmacy Offers)
- ✅ **Cloud Functions** مرفوعة وتعمل (Android يثبت ذلك)
- ✅ **APNs Keys** موجودة على Firebase
- ✅ **Bundle ID و App ID** صحيحين
- ✅ **Xcode Team** تم تغييره للـ Organization الصحيح
- ✅ **Provisioning Profile** يدعم Push Notifications الآن

---

## 📋 خطوات التشخيص على Xcode

### الخطوة 1️⃣: فتح المشروع على Xcode
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
open ios/Runner.xcworkspace
```

⚠️ **مهم**: افتح `.xcworkspace` وليس `.xcodeproj`

---

### الخطوة 2️⃣: تأكد من إعدادات المشروع

#### في Xcode، اذهب إلى:
1. **Project Navigator** → `Runner`
2. **Signing & Capabilities** tab
3. تأكد من:
   - ✅ Team: **Apple Distribution: George Sadek** (YRJ4DLXDZ2)
   - ✅ Bundle Identifier: `com.mored.mallawicure`
   - ✅ Provisioning Profile: **Automatic** أو profile يدعم Push Notifications

#### تحقق من Capabilities:
- ✅ **Push Notifications** موجود
- ✅ **Background Modes** → Remote notifications مفعّل
- ✅ **Sign in with Apple** موجود

---

### الخطوة 3️⃣: شغل التطبيق من Xcode

#### A. اختر جهازك الحقيقي (ليس Simulator):
- من القائمة العلوية → اختر جهازك الـ iPhone
- ⚠️ **Simulator لا يدعم Push Notifications**

#### B. اضغط **Run** (▶️) أو `Cmd + R`

---

### الخطوة 4️⃣: راقب Console Logs في Xcode

بعد فتح التطبيق، ابحث في **Console** (أسفل Xcode) عن:

#### ✅ نجاح تسجيل APNs:
```
✅ User granted notification permission
📱 FCM Token: [token هنا - احفظه!]
```

#### ❌ فشل تسجيل APNs:
```
❌ User declined or has not accepted permission
📱 FCM Token: null
```

أو:
```
Error Domain=NSCocoaErrorDomain Code=3000
```

---

### الخطوة 5️⃣: اختبر FCM Token

#### إذا ظهر FCM Token:

1. **انسخ الـ Token** من Console
2. **افتح Firebase Console**: https://console.firebase.google.com
3. اذهب إلى **Messaging** → **Send your first message**
4. املأ:
   - **Title**: اختبار iOS
   - **Text**: رسالة تجريبية
5. اضغط **Send test message**
6. الصق الـ **FCM Token** واضغط **Test**

**النتيجة المتوقعة**:
- ✅ إذا وصل الإشعار → APNs يعمل، المشكلة في Topic Subscription
- ❌ إذا لم يصل → مشكلة في APNs Configuration

---

### الخطوة 6️⃣: اختبر Topic Subscription

#### افتح التطبيق وسجل دخول:

##### A. كـ **صاحب صيدلية**:
في Console لازم يظهر:
```
✅ Subscribed to pharmacy topic: pharmacy_requests
📱 FCM Token: xxx
```

##### B. كـ **صاحب عيادة**:
في Console لازم يظهر:
```
✅ Subscribed to clinic topic: clinic_[CLINIC_ID]
📱 FCM Token for clinic: xxx
```

##### C. كـ **مستخدم عادي**:
في Console لازم يظهر:
```
✅ Subscribed to all_users topic
```

---

### الخطوة 7️⃣: اختبر إرسال إشعار حقيقي

#### A. للصيدلية:
1. سجل دخول كـ **مريض** على Android أو iOS آخر
2. اعمل **طلب دواء جديد**
3. راقب Console في Xcode لجهاز صاحب الصيدلية
4. يجب أن يظهر:
```
📩 Got a message whilst in the foreground!
📊 Message data: {type: new_medicine_request, ...}
```

#### B. للعيادة:
1. سجل دخول كـ **مريض** على جهاز آخر
2. احجز **موعد أونلاين** في العيادة
3. راقب Console في Xcode لجهاز صاحب العيادة
4. يجب أن يظهر:
```
📩 Got a message whilst in the foreground!
📊 Message data: {type: new_booking, ...}
```

#### C. للعروض:
1. سجل دخول كـ **صيدلية**
2. أضف **عرض جديد**
3. راقب Console في Xcode لأي مستخدم مسجل
4. يجب أن يظهر:
```
📩 Got a message whilst in the foreground!
📊 Message data: {type: new_pharmacy_offer, ...}
```

---

## 🔍 تشخيص المشاكل المحتملة

### Problem 1: FCM Token = null

**السبب**: APNs لم يتم تفعيله بشكل صحيح

**الحل**:
1. تأكد من **Push Notifications** capability موجود في Xcode
2. تأكد من **Background Modes** → Remote notifications مفعّل
3. تأكد من **Provisioning Profile** يدعم Push Notifications
4. حاول **Clean Build Folder** (`Cmd + Shift + K`)
5. احذف التطبيق من الجهاز وأعد التثبيت

### Problem 2: FCM Token موجود لكن الإشعار لا يصل من Firebase Console

**السبب**: مشكلة في APNs Keys على Firebase

**الحل**:
1. افتح Firebase Console → **Project Settings** → **Cloud Messaging**
2. في **Apple app configuration** → تأكد من:
   - **APNs Authentication Key** مرفوع
   - **Key ID**: `9QY3DKL5BG`
   - **Team ID**: `YRJ4DLXDZ2`
3. جرب **رفع Key جديد**:
   - اذهب إلى https://developer.apple.com/account/resources/authkeys/list
   - أنشئ **APNs Key** جديد
   - حمّله على Firebase

### Problem 3: إشعار Test من Firebase يصل، لكن إشعار من Cloud Functions لا يصل

**السبب**: مشكلة في Topic Subscription

**الحل**:

#### تحقق من Firestore:

1. **للصيدلية** → `pharmacy_subscriptions` collection:
```javascript
{
  subscribedAt: timestamp,
  topic: "pharmacy_requests",
  isActive: true,
  fcmToken: "xxx"
}
```

2. **للعيادة** → `clinic_subscriptions` collection:
```javascript
{
  subscribedAt: timestamp,
  topic: "clinic_[CLINIC_ID]",
  isActive: true,
  fcmToken: "xxx"
}
```

3. **للمستخدمين** → `users` collection → document لـ user:
```javascript
{
  fcmToken: "xxx",
  subscribedToAllUsers: true,
  allUsersTopicSubscribedAt: timestamp
}
```

#### إذا البيانات غير موجودة:
- المشكلة: `subscribeToTopic()` لم تعمل
- الحل: أضف log إضافي في `notification_service.dart`

### Problem 4: Topic Subscription تمت بنجاح لكن الإشعار لا يصل

**السبب**: Cloud Function لم ترسل للـ Topic بشكل صحيح

**الحل**:

#### تحقق من Cloud Function Logs:
```bash
# على Windows (حيث الـ Firebase CLI):
firebase functions:log --only notifyClinicOnNewBooking
firebase functions:log --only notifyUsersOnNewOffer
firebase functions:log --only notifyPharmaciesOnNewRequest
```

**ابحث عن**:
- ✅ "Notification sent to clinic topic"
- ✅ "Notification sent to pharmacy topic"
- ✅ "Offer notification sent to all_users topic"

**إذا وجدت Error**:
- **"PERMISSION_DENIED"**: Cloud Function لا تملك صلاحيات إرسال
- **"INVALID_ARGUMENT"**: Topic name خطأ
- **"UNREGISTERED"**: FCM Token منتهي الصلاحية

---

## 🧪 اختبار سريع: Send Test Notification

### من Terminal على Mac:

```bash
# Get FCM Token من Console في Xcode
FCM_TOKEN="YOUR_FCM_TOKEN_HERE"

# أرسل إشعار تجريبي
curl -X POST https://fcm.googleapis.com/v1/projects/clinicalsystem-4da35/messages:send \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "'$FCM_TOKEN'",
      "notification": {
        "title": "اختبار iOS",
        "body": "هل وصل الإشعار؟"
      },
      "apns": {
        "payload": {
          "aps": {
            "sound": "default",
            "badge": 1
          }
        }
      }
    }
  }'
```

⚠️ **ملحوظة**: يحتاج `gcloud` CLI مثبت

---

## 📊 Checklist للتأكد من كل شيء

### Firebase Configuration:
- [ ] **GoogleService-Info.plist** موجود في `ios/Runner/`
- [ ] **BUNDLE_ID** = `com.mored.mallawicure`
- [ ] **GOOGLE_APP_ID** = `1:718616577077:ios:6593a7fcafb54348189d7c`
- [ ] **firebase_options.dart** → iosBundleId صحيح

### Xcode Configuration:
- [ ] **Bundle Identifier** = `com.mored.mallawicure`
- [ ] **Team** = Organization (YRJ4DLXDZ2)
- [ ] **Push Notifications** capability مضاف
- [ ] **Background Modes** → Remote notifications مفعّل
- [ ] **Provisioning Profile** automatic أو يدعم Push
- [ ] **Info.plist** فيه أذونات الإشعارات

### Firebase Console:
- [ ] **APNs Key** مرفوع (Key ID: 9QY3DKL5BG)
- [ ] **Team ID** = YRJ4DLXDZ2
- [ ] **Cloud Functions** deployed وشغالة

### Runtime Checks:
- [ ] **FCM Token** يظهر في Console
- [ ] **Topic Subscription** تمت بنجاح
- [ ] **Foreground notifications** تظهر في Console
- [ ] **Test notification من Firebase** يصل

---

## 💡 نصائح إضافية

### 1. امسح Cache:
```bash
cd ios
rm -rf Pods/ Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### 2. أعد تشغيل Device:
- أحيانًا APNs تحتاج restart للجهاز

### 3. تحقق من Internet:
- APNs تحتاج internet connection
- جرب WiFi و Cellular

### 4. تحقق من Date & Time:
- تأكد من Date & Time صحيحين على الجهاز
- APNs certificates حساسة للوقت

---

## ⚠️ إذا لم ينجح أي شيء

### آخر حل: أعد إنشاء APNs Key

1. **على Apple Developer**:
   - اذهب إلى https://developer.apple.com/account/resources/authkeys/list
   - احذف الـ Key القديم (9QY3DKL5BG)
   - أنشئ Key جديد لـ **APNs**
   - حمّل الملف `.p8`

2. **على Firebase Console**:
   - Project Settings → Cloud Messaging → Apple
   - Upload الـ APNs Key الجديد
   - أدخل **Key ID** و **Team ID** الجديدين

3. **أعد Deploy Cloud Functions**:
   ```bash
   firebase deploy --only functions
   ```

4. **أعد تثبيت التطبيق** على الجهاز

---

## 📞 اتصل بي بعد التجربة

بعد تجربة الخطوات، أخبرني:

1. **هل FCM Token ظهر في Console؟**
   - نعم/لا
   - إذا نعم، أرسله لي

2. **هل Topic Subscription نجحت؟**
   - ظهرت رسالة "Subscribed to..."؟

3. **هل Test Notification من Firebase وصل؟**
   - نعم/لا

4. **هل Cloud Function بعتت الإشعار؟**
   - شوف Logs واخبرني النتيجة

5. **أي Errors ظهرت في Console؟**
   - انسخ الـ Error كامل

---

**Good Luck! 🍀**
