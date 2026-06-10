# التعديلات التي تمت على المشروع ✅

## 📝 ملخص التعديلات

تم تعديل المشروع لتحويله من **Mallawy Health Care** إلى **ملوي كير - MallawyC are** كتطبيق جديد تماماً.

---

## 🔧 الملفات المُعدّلة

### 1. ✅ `pubspec.yaml`
**التعديلات:**
- تغيير اسم Package من `clinicalsystem` إلى `mallawycare`
- تغيير الوصف إلى `"تطبيق ملوي كير الصحي الشامل - MallawyC are"`
- إعادة Build Number إلى `1.0.0+1` (بداية جديدة)

**قبل:**
```yaml
name: clinicalsystem
description: "نظام إدارة صحي شامل - Clinical System"
version: 1.0.0+49
```

**بعد:**
```yaml
name: mallawycare
description: "تطبيق ملوي كير الصحي الشامل - MallawyC are"
version: 1.0.0+1
```

---

### 2. ✅ `android/app/build.gradle.kts`
**التعديلات:**
- تغيير `namespace` من `com.mored.MallawyHealthCare` إلى `com.mored.mallawycare`
- تغيير `applicationId` من `com.mored.MallawyHealthCare` إلى `com.mored.mallawycare`

**قبل:**
```kotlin
android {
    namespace = "com.mored.MallawyHealthCare"
    defaultConfig {
        applicationId = "com.mored.MallawyHealthCare"
```

**بعد:**
```kotlin
android {
    namespace = "com.mored.mallawycare"
    defaultConfig {
        applicationId = "com.mored.mallawycare"
```

---

### 3. ✅ `ios/Runner/Info.plist`
**التعديلات:**
- تغيير `CFBundleDisplayName` من `Mallawy Health Care` إلى `ملوي كير`
- تغيير `CFBundleName` من `clinicalsystem` إلى `mallawycare`

**قبل:**
```xml
<key>CFBundleDisplayName</key>
<string>Mallawy Health Care</string>

<key>CFBundleName</key>
<string>clinicalsystem</string>
```

**بعد:**
```xml
<key>CFBundleDisplayName</key>
<string>ملوي كير</string>

<key>CFBundleName</key>
<string>mallawycare</string>
```

**⚠️ مهم:** لازم تحدّث `GIDClientID` و `CFBundleURLSchemes` بعد إنشاء Firebase الجديد!

---

## 📂 الملفات الجديدة المُضافة

### 1. 📘 `REBRAND_GUIDE.md`
دليل شامل خطوة بخطوة لتحويل التطبيق إلى هوية جديدة، يشمل:
- إنشاء Firebase Project جديد
- إعداد iOS و Android Apps
- تحديث كل الملفات
- إعداد Apple Developer
- خطوات النشر

### 2. ✅ `FIREBASE_SETUP_CHECKLIST.md`
قائمة تحقق تفصيلية مع خانات للتأشير عند إتمام كل خطوة:
- إنشاء المشروع
- إضافة التطبيقات
- إعداد Authentication
- إعداد Firestore & Storage
- إعداد FCM
- إعداد Apple Developer
- الاختبار والبناء

### 3. 🔧 `rebrand_cleanup.sh`
سكريبت تلقائي لتنظيف المشروع قبل إعادة البناء:
```bash
chmod +x rebrand_cleanup.sh
./rebrand_cleanup.sh
```

### 4. 📝 `CHANGES_MADE.md` (هذا الملف)
توثيق لكل التعديلات التي تمت

---

## ⚠️ الملفات التي تحتاج تحديث يدوي

### ❗ `android/app/google-services.json`
**الحالة:** يحتاج استبدال كامل

**الخطوات:**
1. أنشئ Firebase Project جديد
2. أضف Android App بـ package name: `com.mored.mallawycare`
3. حمّل `google-services.json` الجديد
4. استبدل الملف الموجود في: `android/app/google-services.json`

**الملف الحالي:** يحتوي على:
- Package: `com.mored.MallawyHealthCare`
- Project: `clinicalsystem-4da35`

**المطلوب:** ملف جديد يحتوي على:
- Package: `com.mored.mallawycare`
- Project: `mallawycare-XXXXX` (المشروع الجديد)

---

### ❗ `ios/Runner/GoogleService-Info.plist`
**الحالة:** يحتاج استبدال كامل

**الخطوات:**
1. في نفس Firebase Project الجديد
2. أضف iOS App بـ Bundle ID: `com.mored.mallawycare`
3. حمّل `GoogleService-Info.plist` الجديد
4. استبدل الملف الموجود في: `ios/Runner/GoogleService-Info.plist`
5. **مهم:** استخرج `CLIENT_ID` و `REVERSED_CLIENT_ID` من الملف الجديد
6. حدّث `ios/Runner/Info.plist` بالقيم الجديدة

**الملف الحالي:** يحتوي على:
- Bundle ID: `com.mallawy.clinicalsystem`
- Project: `clinicalsystem-4da35`

**المطلوب:** ملف جديد يحتوي على:
- Bundle ID: `com.mored.mallawycare`
- Project: `mallawycare-XXXXX`

---

### ❗ `ios/Runner.xcodeproj/project.pbxproj`
**الحالة:** يحتاج تحديث Bundle Identifier

**الخيار 1 - استخدام Xcode (الأسهل):**
1. افتح: `ios/Runner.xcworkspace` في Xcode
2. اختر **Runner** من القائمة اليسرى
3. اذهب لـ **General** > **Identity**
4. غيّر **Bundle Identifier** من `com.mallawy.clinicalsystem` إلى `com.mored.mallawycare`
5. احفظ

**الخيار 2 - التعديل اليدوي:**
ابحث في الملف عن كل مرة يظهر فيها:
```
PRODUCT_BUNDLE_IDENTIFIER = com.mallawy.clinicalsystem;
```
وغيّره إلى:
```
PRODUCT_BUNDLE_IDENTIFIER = com.mored.mallawycare;
```

---

### ❗ `ios/Runner/Info.plist` (تحديث إضافي)
**الحالة:** يحتاج تحديث Google Sign-In credentials

بعد الحصول على ملف `GoogleService-Info.plist` الجديد، حدّث:

```xml
<!-- استبدل هذا -->
<key>GIDClientID</key>
<string>718616577077-gh7g5l90ouvpimafmqltnnqe5vcqbms9.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.718616577077-gh7g5l90ouvpimafmqltnnqe5vcqbms9</string>
        </array>
    </dict>
</array>

<!-- بالقيم الجديدة من GoogleService-Info.plist -->
```

---

## 🔍 ملفات أخرى قد تحتاج فحص

### `android/app/src/main/AndroidManifest.xml`
**التحقق:** تأكد أن `package` محدّث
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.mored.mallawycare">
```

### `lib/main.dart`
**التحقق:** تأكد أن اسم التطبيق محدّث
```dart
MaterialApp(
  title: 'ملوي كير - MallawyC are',
  // ...
)
```

---

## 🎯 الخطوات التالية (بالترتيب)

### 1️⃣ إنشاء Firebase Project جديد
- [ ] اذهب إلى: https://console.firebase.google.com/
- [ ] أنشئ مشروع جديد باسم: `mallawycare`
- [ ] اتبع الخطوات في `FIREBASE_SETUP_CHECKLIST.md`

### 2️⃣ استبدال ملفات Firebase
- [ ] استبدل `android/app/google-services.json`
- [ ] استبدل `ios/Runner/GoogleService-Info.plist`
- [ ] حدّث `ios/Runner/Info.plist` بـ Client IDs الجديدة

### 3️⃣ تحديث Bundle ID في Xcode
- [ ] افتح `ios/Runner.xcworkspace`
- [ ] غيّر Bundle Identifier إلى `com.mored.mallawycare`
- [ ] تأكد من Signing & Capabilities

### 4️⃣ تنظيف وإعادة البناء
```bash
./rebrand_cleanup.sh
cd ios && pod install && cd ..
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### 5️⃣ اختبار التطبيق
```bash
flutter run -d ios
flutter run -d android
```

### 6️⃣ إعداد Apple Developer
- [ ] أنشئ App ID جديد: `com.mored.mallawycare`
- [ ] فعّل Sign In with Apple
- [ ] فعّل Push Notifications
- [ ] أنشئ Service ID للـ Apple Sign-In

### 7️⃣ البناء للنشر
```bash
# iOS
flutter build ios --release

# Android
flutter build appbundle --release
```

### 8️⃣ إنشاء App في Stores
- [ ] App Store Connect: أنشئ app جديد
- [ ] Google Play Console: أنشئ app جديد

---

## 📊 ملخص المعرفات (IDs)

| العنصر | القيمة القديمة | القيمة الجديدة |
|--------|----------------|----------------|
| **Flutter Package** | clinicalsystem | mallawycare |
| **iOS Bundle ID** | com.mallawy.clinicalsystem | com.mored.mallawycare |
| **Android Package** | com.mored.MallawyHealthCare | com.mored.mallawycare |
| **App Display Name** | Mallawy Health Care | ملوي كير |
| **Firebase Project** | clinicalsystem-4da35 | mallawycare-XXXXX (جديد) |
| **Version** | 1.0.0+49 | 1.0.0+1 |

---

## ✅ التحقق من النجاح

بعد تطبيق كل التعديلات، تأكد من:

- [ ] التطبيق يُبنى بدون أخطاء على iOS
- [ ] التطبيق يُبنى بدون أخطاء على Android
- [ ] اسم التطبيق يظهر "ملوي كير" على الجهاز
- [ ] الأيقونة تظهر صحيحة
- [ ] Google Sign-In يعمل
- [ ] Apple Sign-In يعمل (iOS)
- [ ] Firebase يحفظ البيانات
- [ ] Notifications تصل
- [ ] جميع الـ features تشتغل كما هو متوقع

---

## 🆘 في حالة المشاكل

### مشكلة: Build يفشل
```bash
# حاول التنظيف الكامل
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf pubspec.lock
flutter pub get
cd ios && pod install --repo-update && cd ..
```

### مشكلة: Google Sign-In لا يعمل
- تأكد من تحديث `GIDClientID` في `Info.plist`
- تأكد من إضافة SHA-1 في Firebase Console (Android)
- تأكد من تفعيل Google Sign-In في Firebase Authentication

### مشكلة: Bundle ID مش بيتغير
- استخدم Xcode لتغييره يدوياً
- تأكد من البحث في `project.pbxproj` عن كل المرات اللي ظهر فيها Bundle ID القديم

---

## 📞 للمساعدة

راجع الملفات التالية:
- 📘 `REBRAND_GUIDE.md` - الدليل الشامل
- ✅ `FIREBASE_SETUP_CHECKLIST.md` - قائمة التحقق التفصيلية
- 🔧 `rebrand_cleanup.sh` - سكريبت التنظيف

---

**تاريخ التعديل:** 11 يونيو 2026
**الحالة:** ✅ التعديلات الأساسية تمت - تحتاج Firebase جديد لإكمال العملية
