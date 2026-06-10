# دليل تحويل التطبيق إلى MallawyC are - ملوي كير 🏥

## نظرة عامة
هذا الدليل يشرح خطوة بخطوة كيفية تحويل التطبيق الحالي إلى تطبيق جديد تماماً باسم **MallawyC are - ملوي كير**

---

## 📋 المعلومات الحالية (التطبيق القديم)

### معلومات التطبيق:
- **Bundle ID (iOS)**: `com.mallawy.clinicalsystem`
- **Package Name (Android)**: `com.mored.MallawyHealthCare`
- **App Name**: `Mallawy Health Care`
- **Firebase Project**: `clinicalsystem-4da35`
- **Project Number**: `718616577077`

---

## 🎯 المعلومات الجديدة (التطبيق الجديد)

### ما سنغيره:
- **Bundle ID الجديد (iOS)**: `com.mored.mallawycare`
- **Package Name الجديد (Android)**: `com.mored.mallawycare`
- **App Name الجديد**: `MallawyC are - ملوي كير`
- **Package Name (Flutter)**: `mallawycare`
- **Firebase Project**: مشروع جديد تماماً

---

## 🔧 الخطوات التفصيلية

### المرحلة 1️⃣: إنشاء مشروع Firebase جديد

#### 1. إنشاء المشروع:
1. اذهب إلى: https://console.firebase.google.com/
2. اضغط على **"Add project"** أو **"إضافة مشروع"**
3. أدخل اسم المشروع: `mallawycare` أو `mallawy-care`
4. اختر **تعطيل Google Analytics** (أو فعله حسب حاجتك)
5. اضغط **"Create project"**

#### 2. إضافة تطبيق iOS:
1. في لوحة Firebase، اضغط على أيقونة iOS
2. **iOS bundle ID**: أدخل `com.mored.mallawycare`
3. **App nickname**: أدخل `MallawyC are iOS`
4. **App Store ID**: اتركه فارغ الآن (ستضيفه بعد الرفع)
5. اضغط **"Register app"**
6. **حمّل ملف `GoogleService-Info.plist`** ← احفظه جانباً

#### 3. إضافة تطبيق Android:
1. في لوحة Firebase، اضغط على أيقونة Android
2. **Android package name**: أدخل `com.mored.mallawycare`
3. **App nickname**: أدخل `MallawyC are Android`
4. **Debug signing certificate SHA-1**: (اختياري - للـ Google Sign-In)
   - للحصول عليه: افتح Terminal واكتب:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
5. اضغط **"Register app"**
6. **حمّل ملف `google-services.json`** ← احفظه جانباً

#### 4. تفعيل الخدمات في Firebase:
- **Authentication**:
  - اذهب لقسم Authentication
  - فعّل: Email/Password, Google Sign-In, Apple Sign-In
  
- **Firestore Database**:
  - اذهب لقسم Firestore
  - أنشئ قاعدة بيانات جديدة (Start in production mode)
  - انسخ القواعد من المشروع القديم إذا لزم

- **Storage**:
  - اذهب لقسم Storage
  - فعّل Storage
  - انسخ القواعد من المشروع القديم

- **Cloud Messaging (FCM)**:
  - مفعل تلقائياً
  - احفظ **Server Key** من: Project Settings > Cloud Messaging

---

### المرحلة 2️⃣: تحديث ملفات التطبيق

#### ✅ الملف 1: `pubspec.yaml`
```yaml
# غيّر السطر الأول:
name: mallawycare  # بدلاً من: clinicalsystem

description: "تطبيق ملوي كير - MallawyC are"

# غيّر الإصدار لبداية جديدة:
version: 1.0.0+1
```

#### ✅ الملف 2: `android/app/build.gradle.kts`
```kotlin
android {
    namespace = "com.mored.mallawycare"  # غيّر من: com.mored.MallawyHealthCare
    
    defaultConfig {
        applicationId = "com.mored.mallawycare"  # غيّر من: com.mored.MallawyHealthCare
        // ... باقي الإعدادات
    }
}
```

#### ✅ الملف 3: `android/app/src/main/AndroidManifest.xml`
ابحث عن أي إشارة لـ `package` أو `android:label` وغيّرها:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.mored.mallawycare">
    
    <application
        android:label="ملوي كير"
        ...>
```

#### ✅ الملف 4: `android/app/google-services.json`
- **احذف الملف القديم تماماً**
- **ضع الملف الجديد** الذي حمّلته من Firebase

#### ✅ الملف 5: `ios/Runner/Info.plist`
```xml
<key>CFBundleDisplayName</key>
<string>ملوي كير</string>

<key>CFBundleName</key>
<string>mallawycare</string>

<!-- احذف GIDClientID القديم واستبدله بالجديد من GoogleService-Info.plist الجديد -->
<key>GIDClientID</key>
<string>YOUR_NEW_CLIENT_ID_HERE</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_NEW_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

#### ✅ الملف 6: `ios/Runner/GoogleService-Info.plist`
- **احذف الملف القديم تماماً**
- **ضع الملف الجديد** الذي حمّلته من Firebase

#### ✅ الملف 7: `ios/Runner.xcodeproj/project.pbxproj`
افتح Xcode أو عدّل يدوياً:
- ابحث عن: `PRODUCT_BUNDLE_IDENTIFIER`
- غيّر من: `com.mallawy.clinicalsystem`
- إلى: `com.mored.mallawycare`

**أو استخدم Xcode**:
1. افتح المشروع: `ios/Runner.xcworkspace`
2. اضغط على Runner في القائمة اليسرى
3. في **General** > **Identity**
4. غيّر **Bundle Identifier** إلى: `com.mored.mallawycare`

---

### المرحلة 3️⃣: تحديث الأيقونات والـ Splash Screen

#### تغيير الأيقونة:
1. استبدل الصورة: `assets/images/LO.png` بلوجو جديد
2. استبدل الصورة: `assets/images/splash.png` بشاشة بداية جديدة
3. شغّل الأوامر:
```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

### المرحلة 4️⃣: تحديث أسماء التطبيق في الكود

#### في `lib/main.dart`:
```dart
MaterialApp(
  title: 'ملوي كير - MallawyC are',
  // ... باقي الكود
)
```

#### في أي ملف يحتوي على اسم التطبيق:
ابحث عن:
- "Mallawy Health Care"
- "Clinical System"
- "clinicalsystem"

واستبدلها بـ:
- "ملوي كير - MallawyC are"
- "mallawycare"

---

### المرحلة 5️⃣: تحديث Google Sign-In

#### في Firebase Console (المشروع الجديد):
1. اذهب إلى **Authentication** > **Sign-in method**
2. فعّل **Google**
3. اذهب إلى **Project Settings** > **OAuth**
4. أضف **Web Client ID** و **iOS Client ID**

#### في `ios/Runner/Info.plist`:
تأكد من تحديث:
```xml
<key>GIDClientID</key>
<string>YOUR_NEW_IOS_CLIENT_ID.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_NEW_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

---

### المرحلة 6️⃣: تحديث Apple Sign-In

#### في Apple Developer:
1. اذهب إلى: https://developer.apple.com/account/
2. **Identifiers** > اضغط **+** لإنشاء App ID جديد
3. **Description**: MallawyC are
4. **Bundle ID**: `com.mored.mallawycare`
5. فعّل **Sign In with Apple**
6. احفظ

#### في Firebase Console:
1. اذهب إلى **Authentication** > **Sign-in method**
2. فعّل **Apple**
3. أضف **Service ID** و **Team ID** من Apple Developer

---

### المرحلة 7️⃣: تنظيف وإعادة البناء

#### احذف الملفات المؤقتة:
```bash
# احذف build cache
rm -rf build/
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

# للـ iOS
cd ios
pod deintegrate
pod install
cd ..

# إعادة البناء
flutter clean
flutter pub get
```

#### اختبار التطبيق:
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

### المرحلة 8️⃣: إعداد للنشر

#### للـ iOS (App Store):
1. **إنشاء App ID جديد في App Store Connect**:
   - اذهب إلى: https://appstoreconnect.apple.com/
   - اضغط **My Apps** > **+** > **New App**
   - **Platform**: iOS
   - **Name**: ملوي كير - MallawyC are
   - **Bundle ID**: اختر `com.mored.mallawycare`
   - **SKU**: `mallawycare-001`
   - **User Access**: Full Access

2. **تحديث Xcode للبناء**:
   ```bash
   flutter build ios --release
   ```

3. **رفع للـ App Store**:
   - افتح: `ios/Runner.xcworkspace` في Xcode
   - اختر **Product** > **Archive**
   - بعد الانتهاء، اضغط **Distribute App**

#### للـ Android (Google Play):
1. **إنشاء Signing Key جديد**:
   ```bash
   keytool -genkey -v -keystore ~/mallawycare-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias mallawycare-release
   ```

2. **تحديث `android/key.properties`**:
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=mallawycare-release
   storeFile=/Users/yourname/mallawycare-release-key.jks
   ```

3. **بناء APK/AAB**:
   ```bash
   flutter build appbundle --release
   # أو
   flutter build apk --release --split-per-abi
   ```

4. **رفع على Google Play Console**:
   - اذهب إلى: https://play.google.com/console/
   - اضغط **Create app**
   - **App name**: ملوي كير - MallawyC are
   - **Default language**: Arabic
   - **App or game**: App
   - **Free or paid**: Free

---

## ✅ قائمة التحقق النهائية

قبل النشر، تأكد من:

- [ ] اسم التطبيق تغيّر في كل مكان
- [ ] Bundle ID / Package Name جديد تماماً
- [ ] Firebase project جديد وملفاته محدّثة
- [ ] الأيقونات والـ Splash Screen جديدة
- [ ] Google Sign-In يشتغل مع المشروع الجديد
- [ ] Apple Sign-In مُعدّ صح
- [ ] FCM Notifications تشتغل
- [ ] اختبرت التطبيق على أجهزة حقيقية
- [ ] Storage و Firestore قواعدهم صحيحة
- [ ] App Store Connect / Play Console جاهزين

---

## 🚨 ملاحظات مهمة

### الفرق بين التطبيق القديم والجديد:
| العنصر | القديم | الجديد |
|--------|--------|--------|
| Bundle ID | com.mallawy.clinicalsystem | com.mored.mallawycare |
| Package (Android) | com.mored.MallawyHealthCare | com.mored.mallawycare |
| App Name | Mallawy Health Care | ملوي كير - MallawyC are |
| Firebase Project | clinicalsystem-4da35 | mallawycare-XXXXX |
| Package Name | clinicalsystem | mallawycare |

### نقل البيانات (إذا لزم):
إذا كنت تريد نقل بيانات من Firebase القديم للجديد:
```bash
# استخدم Firebase Admin SDK أو Cloud Functions
# أو صدّر البيانات يدوياً من Firestore Console
```

---

## 📞 في حالة المشاكل

### مشكلة: Google Sign-In لا يعمل
- تأكد من تحديث `GIDClientID` في `Info.plist`
- تأكد من إضافة SHA-1 في Firebase Console
- تأكد من تفعيل Google Sign-In في Firebase Authentication

### مشكلة: Apple Sign-In لا يعمل
- تأكد من تفعيل Capability في Xcode
- تأكد من إضافة Service ID في Apple Developer
- تأكد من تطابق Bundle ID

### مشكلة: FCM Notifications لا تصل
- تأكد من تحديث ملفات `google-services.json` و `GoogleService-Info.plist`
- تأكد من طلب permissions
- اختبر من Firebase Console > Cloud Messaging

---

## 🎉 بعد النشر

1. احذف Firebase Project القديم (بعد التأكد)
2. احذف App IDs القديمة من Apple Developer
3. احذف التطبيق القديم من App Store Connect (إذا لزم)
4. احفظ نسخة احتياطية من:
   - Signing Keys
   - Firebase credentials
   - App Store credentials

---

**تم إعداد هذا الدليل خصيصاً لتحويل التطبيق إلى هوية جديدة تماماً** 🚀
