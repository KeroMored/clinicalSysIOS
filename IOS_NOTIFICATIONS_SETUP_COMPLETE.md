# ✅ iOS Notifications Setup - Complete

## 📱 ما تم إصلاحه

### 1. Push Notifications (FCM)
- ✅ إضافة Firebase configuration في `AppDelegate.swift`
- ✅ تفعيل `MessagingDelegate` للـ FCM token handling
- ✅ تفعيل `UNUserNotificationCenterDelegate` للـ notification handling
- ✅ معالجة الإشعارات في foreground (تظهر حتى لو التطبيق مفتوح)
- ✅ معالجة notification taps وال payload
- ✅ تسجيل الـ APNs token مع Firebase

### 2. Local Notifications (Midnight Health Tips)
- ✅ تفعيل `DailyHealthTipNotificationService` في `main.dart`
- ✅ جدولة إشعارات يومية عند منتصف الليل (12 AM)
- ✅ Request permissions للـ iOS local notifications

### 3. iOS Configuration Files
- ✅ تغيير `aps-environment` من `development` إلى `production` في:
  - `Runner.entitlements`
  - `RunnerRelease.entitlements`
- ✅ إضافة `UIBackgroundModes` في `Info.plist`:
  - `fetch`
  - `remote-notification`
- ✅ تعطيل `FirebaseAppDelegateProxyEnabled` للتحكم اليدوي في FCM

---

## 🔧 المطلوب من جانبك (Apple Developer Account)

### 1. Push Notification Certificate
تأكد من إعداد الـ Push Notification Certificate في Apple Developer:

1. **روح على**: [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. **اضغط على**: ➕ (Create a Certificate)
3. **اختار**: "Apple Push Notification service SSL (Sandbox & Production)"
4. **اختار الـ App ID**: `com.mored.mallawicure`
5. **Upload CSR File** (من Firebase أو انشئ واحد جديد)
6. **Download** الشهادة و**Upload** لـ Firebase Console

### 2. Firebase Console Setup
تأكد من رفع الـ APNs Key أو Certificate في Firebase:

1. **روح على**: [Firebase Console](https://console.firebase.google.com)
2. **اختار المشروع**: `clinicalsystem-4da35`
3. **روح على**: Project Settings → Cloud Messaging → Apple app configuration
4. **Upload**:
   - **Option 1 (Recommended)**: APNs Authentication Key (.p8 file)
   - **Option 2**: APNs Certificates (.p12 file)

### 3. Xcode Capabilities
تأكد من تفعيل الـ Capabilities في Xcode:

1. افتح المشروع في Xcode
2. اختار **Runner** target
3. روح على **Signing & Capabilities**
4. تأكد من وجود:
   - ✅ **Push Notifications** capability
   - ✅ **Background Modes** capability مع:
     - ✅ Remote notifications
     - ✅ Background fetch

---

## 🧪 اختبار الإشعارات

### Local Notifications (Midnight Health Tips)
```bash
# هتظهر الإشعارات تلقائيًا كل يوم عند الساعة 12 AM
# للاختبار الفوري، استخدم:
DailyHealthTipNotificationService.sendNowForTesting()
```

### Push Notifications (FCM)
استخدم Firebase Console لإرسال test notification:

1. روح على: Firebase Console → Cloud Messaging
2. اضغط على "Send your first message"
3. اكتب العنوان والمحتوى
4. اختار التطبيق: `com.mored.mallawicure`
5. اضغط Test → أدخل FCM token
6. اضغط Send

---

## 📋 Checklist النهائي

- [ ] رفع APNs Certificate/Key على Firebase Console
- [ ] فتح المشروع في Xcode والتأكد من Capabilities
- [ ] عمل Clean Build: `flutter clean && cd ios && pod install`
- [ ] بناء نسخة Release وتجربة Push Notification
- [ ] بناء نسخة Release وتجربة Local Notification عند منتصف الليل
- [ ] رفع على TestFlight واختبار الإشعارات
- [ ] التأكد من ظهور الإشعارات في Notification Center

---

## 🐛 Troubleshooting

### المشكلة: الإشعارات مش بتظهر على iOS

**الحلول المحتملة:**

1. **تأكد من Permissions**:
   ```swift
   // في Settings → [App Name] → Notifications
   // تأكد إن Notifications مفعلة
   ```

2. **تأكد من APNs Token**:
   ```
   // شوف الـ console logs في Xcode:
   // "APNs token: ..." و "Firebase registration token: ..."
   ```

3. **تأكد من Firebase Configuration**:
   - الـ `GoogleService-Info.plist` موجود في `ios/Runner/`
   - الـ Bundle ID صحيح: `com.mored.mallawicure`

4. **تأكد من Entitlements**:
   ```xml
   <key>aps-environment</key>
   <string>production</string>
   ```

5. **تأكد من Info.plist**:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>fetch</string>
     <string>remote-notification</string>
   </array>
   ```

---

## 📝 ملاحظات مهمة

1. **Development vs Production**:
   - استخدمنا `production` في الـ entitlements عشان يشتغل على TestFlight و App Store
   - لو عايز تجرب على debug build، ممكن تحتاج certificate منفصل

2. **Local Notifications**:
   - بتتجدول تلقائيًا كل يوم عند منتصف الليل
   - بتستخدم timezone المحلي للجهاز

3. **Push Notifications**:
   - بتظهر حتى لو التطبيق مفتوح (foreground)
   - بتظهر في Notification Center لو التطبيق مقفول

---

## 🎉 الخلاصة

تم إصلاح كل مشاكل الإشعارات على iOS! 
الكود جاهز والـ configuration كاملة.
المتبقي فقط التأكد من إعدادات Apple Developer Account و Firebase Console.

**Version**: 1.0.0+18
**Commit**: Merge main with iOS notification fixes
**Date**: 2026-07-02
