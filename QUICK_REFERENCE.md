# مرجع سريع - التطبيق القديم vs الجديد 🔄

## 🆚 المقارنة السريعة

### هوية التطبيق

| العنصر | القديم ❌ | الجديد ✅ |
|--------|----------|----------|
| **اسم التطبيق** | Mallawy Health Care | ملوي كير - MallawyC are |
| **Flutter Package** | clinicalsystem | mallawycare |
| **iOS Bundle ID** | com.mallawy.clinicalsystem | com.mored.mallawycare |
| **Android Package** | com.mored.MallawyHealthCare | com.mored.mallawycare |
| **Version** | 1.0.0+49 | 1.0.0+1 |

### Firebase

| العنصر | القديم ❌ | الجديد ✅ |
|--------|----------|----------|
| **Project ID** | clinicalsystem-4da35 | mallawycare-XXXXX (جديد) |
| **Project Number** | 718616577077 | سيتم إنشاؤه |
| **Storage Bucket** | clinicalsystem-4da35.firebasestorage.app | mallawycare-XXXXX... |

---

## 📋 قائمة التحقق السريعة

### ✅ تم إنجازه
- [x] تحديث `pubspec.yaml`
- [x] تحديث `android/app/build.gradle.kts`
- [x] تحديث `ios/Runner/Info.plist` (اسم التطبيق)
- [x] إنشاء دليل Rebranding كامل
- [x] إنشاء قائمة Firebase Setup
- [x] إنشاء سكريبت التنظيف

### ⏳ ما زال مطلوباً
- [ ] إنشاء Firebase Project جديد
- [ ] استبدال `android/app/google-services.json`
- [ ] استبدال `ios/Runner/GoogleService-Info.plist`
- [ ] تحديث `ios/Runner/Info.plist` (Google Client IDs)
- [ ] تحديث Bundle ID في Xcode (`com.mored.mallawycare`)
- [ ] إنشاء App ID في Apple Developer
- [ ] إنشاء Service ID للـ Apple Sign-In
- [ ] تحديث Signing Keys
- [ ] تنظيف وإعادة البناء
- [ ] اختبار شامل

---

## 🚀 الخطوات التالية (بالترتيب)

### 1. إنشاء Firebase (20 دقيقة)
```
📍 https://console.firebase.google.com/
→ Create Project: "mallawycare"
→ Add iOS App: com.mored.mallawycare
→ Add Android App: com.mored.mallawycare
→ Enable Authentication (Email, Google, Apple)
→ Create Firestore Database
→ Enable Cloud Storage
→ Enable Cloud Messaging
```

### 2. استبدال ملفات Firebase (5 دقائق)
```bash
# حمّل الملفات من Firebase Console:
# - GoogleService-Info.plist → ios/Runner/
# - google-services.json → android/app/
```

### 3. تحديث Info.plist (5 دقائق)
```bash
# افتح: ios/Runner/GoogleService-Info.plist
# انسخ CLIENT_ID و REVERSED_CLIENT_ID
# حدّث: ios/Runner/Info.plist
```

### 4. تحديث Xcode (5 دقائق)
```bash
open ios/Runner.xcworkspace
# غيّر Bundle Identifier → com.mored.mallawycare
```

### 5. تنظيف وإعادة البناء (10 دقائق)
```bash
./rebrand_cleanup.sh
cd ios && pod install && cd ..
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### 6. اختبار (15 دقيقة)
```bash
flutter run -d ios
flutter run -d android
# اختبر: Login, Firebase, Notifications
```

### 7. Apple Developer Setup (20 دقيقة)
```
📍 https://developer.apple.com/account/
→ Create App ID: com.mored.mallawycare
→ Enable Sign In with Apple
→ Enable Push Notifications
→ Create Service ID for Sign In with Apple
→ Create APNs Key
```

### 8. Build للنشر (10 دقيقة)
```bash
flutter build ios --release
flutter build appbundle --release
```

**⏱️ الوقت الإجمالي المتوقع:** ~1.5 ساعة

---

## 🔗 روابط مهمة

### Firebase
- Console: https://console.firebase.google.com/
- Documentation: https://firebase.google.com/docs

### Apple Developer
- Account: https://developer.apple.com/account/
- App Store Connect: https://appstoreconnect.apple.com/

### Google Play
- Console: https://play.google.com/console/

---

## 📞 ملفات المساعدة

| الملف | الغرض |
|------|-------|
| `REBRAND_GUIDE.md` | 📘 الدليل الكامل المفصّل |
| `FIREBASE_SETUP_CHECKLIST.md` | ✅ قائمة تحقق Firebase خطوة بخطوة |
| `CHANGES_MADE.md` | 📝 توثيق كل التعديلات |
| `rebrand_cleanup.sh` | 🔧 سكريبت تنظيف تلقائي |
| `QUICK_REFERENCE.md` | ⚡ هذا الملف - مرجع سريع |

---

## 🆘 حل سريع للمشاكل الشائعة

### ❌ Build failed
```bash
flutter clean && flutter pub get
cd ios && pod install && cd ..
```

### ❌ Google Sign-In لا يعمل
- تحقق من `GIDClientID` في `Info.plist`
- أضف SHA-1 في Firebase Console

### ❌ Bundle ID لا يتغير
```bash
# استخدم Xcode:
open ios/Runner.xcworkspace
# General > Identity > Bundle Identifier
```

### ❌ Pods خطأ
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

---

## 💾 معلومات للحفظ

بعد الانتهاء من كل الخطوات، احفظ:

- ✅ Firebase Project ID: `_________________`
- ✅ iOS Bundle ID: `com.mored.mallawycare`
- ✅ Android Package: `com.mored.mallawycare`
- ✅ FCM Server Key: `_________________`
- ✅ Apple Team ID: `_________________`
- ✅ Apple Service ID: `com.mored.mallawycare.signin`
- ✅ Android Release Key: `~/mallawycare-release-key.jks`
- ✅ Key Password: `_________________`

---

## ✅ نهاية النجاح

عند الانتهاء، يجب أن يكون لديك:
- ✅ تطبيق جديد باسم "ملوي كير"
- ✅ Firebase project جديد
- ✅ Bundle IDs جديدة تماماً
- ✅ Apple App IDs جديدة
- ✅ جاهز للرفع على App Store & Play Store

---

**بالتوفيق! 🚀**
