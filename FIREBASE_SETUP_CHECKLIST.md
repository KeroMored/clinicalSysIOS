# قائمة خطوات إعداد Firebase الجديد 🔥

## 📝 المعلومات المطلوبة

بعد إنشاء مشروع Firebase الجديد، ستحتاج إلى هذه المعلومات:

---

## ✅ المرحلة 1: إنشاء المشروع

### الخطوة 1: إنشاء مشروع Firebase
🔗 **رابط:** https://console.firebase.google.com/

- [ ] اضغط "Add project" / "إضافة مشروع"
- [ ] اسم المشروع: `mallawycare` أو `mallawy-care`
- [ ] Project ID: سيتم إنشاؤه تلقائياً (احفظه!)
- [ ] Google Analytics: اختياري
- [ ] اضغط "Create project"

📋 **Project ID الجديد**: `____________________`

---

## ✅ المرحلة 2: إضافة تطبيق iOS

### الخطوة 1: إضافة iOS App
- [ ] اضغط على أيقونة iOS في لوحة Firebase
- [ ] **iOS bundle ID**: `com.mored.mallawycare`
- [ ] **App nickname**: `MallawyC are iOS`
- [ ] **App Store ID**: (اتركه فارغ الآن)
- [ ] اضغط "Register app"

### الخطوة 2: تحميل GoogleService-Info.plist
- [ ] حمّل ملف `GoogleService-Info.plist`
- [ ] ضعه في: `ios/Runner/GoogleService-Info.plist`
- [ ] استبدل الملف القديم تماماً

### الخطوة 3: استخراج معلومات Google Sign-In
افتح ملف `GoogleService-Info.plist` واستخرج:

```xml
<key>CLIENT_ID</key>
<string>YOUR_CLIENT_ID_HERE</string>

<key>REVERSED_CLIENT_ID</key>
<string>YOUR_REVERSED_CLIENT_ID_HERE</string>
```

📋 **iOS CLIENT_ID**: `____________________`
📋 **REVERSED_CLIENT_ID**: `____________________`

### الخطوة 4: تحديث Info.plist
افتح ملف `ios/Runner/Info.plist` وحدّث:

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID_HERE</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID_HERE</string>
        </array>
    </dict>
</array>
```

- [ ] تم تحديث `GIDClientID`
- [ ] تم تحديث `CFBundleURLSchemes`

---

## ✅ المرحلة 3: إضافة تطبيق Android

### الخطوة 1: إضافة Android App
- [ ] اضغط على أيقونة Android في لوحة Firebase
- [ ] **Android package name**: `com.mored.mallawycare`
- [ ] **App nickname**: `MallawyC are Android`
- [ ] **Debug signing certificate SHA-1**: (اختياري)

### الخطوة 2: الحصول على SHA-1 للـ Debug
افتح Terminal واكتب:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

📋 **Debug SHA-1**: `____________________`

### الخطوة 3: الحصول على SHA-1 للـ Release
```bash
keytool -list -v -keystore ~/mallawycare-release-key.jks -alias mallawycare-release
```

📋 **Release SHA-1**: `____________________`

### الخطوة 4: إضافة SHA-1 في Firebase
- [ ] اذهب إلى: Project Settings > Your apps > Android app
- [ ] اضغط "Add fingerprint"
- [ ] أضف Debug SHA-1
- [ ] أضف Release SHA-1

### الخطوة 5: تحميل google-services.json
- [ ] حمّل ملف `google-services.json`
- [ ] ضعه في: `android/app/google-services.json`
- [ ] استبدل الملف القديم تماماً

---

## ✅ المرحلة 4: إعداد Authentication

### 1. تفعيل Email/Password
- [ ] اذهب إلى: Authentication > Sign-in method
- [ ] فعّل **Email/Password**
- [ ] احفظ

### 2. تفعيل Google Sign-In
- [ ] فعّل **Google**
- [ ] أضف **Project support email**: `your-email@example.com`
- [ ] احفظ

📋 **Web Client ID** (للـ Google Sign-In):
- اذهب لـ: Project Settings > OAuth 2.0 Client IDs
- ابحث عن "Web client (auto created by Google Service)"

📋 **Web Client ID**: `____________________`

### 3. تفعيل Apple Sign-In
- [ ] فعّل **Apple**
- [ ] **Service ID**: من Apple Developer Console
- [ ] **Team ID**: من Apple Developer Console
- [ ] **Key ID**: من Apple Developer Console
- [ ] **Private Key**: من Apple Developer Console
- [ ] احفظ

---

## ✅ المرحلة 5: إعداد Firestore Database

### الخطوة 1: إنشاء Database
- [ ] اذهب إلى: Firestore Database
- [ ] اضغط "Create database"
- [ ] اختر **Production mode**
- [ ] اختر المنطقة: `eur3 (europe-west)` أو الأقرب لك
- [ ] اضغط "Enable"

### الخطوة 2: إعداد Security Rules
انسخ القواعد من المشروع القديم أو استخدم:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public collections (مثل الأطباء، الصيدليات، إلخ)
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

- [ ] تم نسخ القواعد
- [ ] تم نشر القواعد

---

## ✅ المرحلة 6: إعداد Cloud Storage

### الخطوة 1: إنشاء Storage
- [ ] اذهب إلى: Storage
- [ ] اضغط "Get started"
- [ ] اختر **Production mode**
- [ ] احفظ

### الخطوة 2: إعداد Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

- [ ] تم نسخ القواعد
- [ ] تم نشر القواعد

---

## ✅ المرحلة 7: إعداد Cloud Messaging (FCM)

### الخطوة 1: الحصول على Server Key
- [ ] اذهب إلى: Project Settings > Cloud Messaging
- [ ] انسخ **Server key**

📋 **FCM Server Key**: `____________________`

### الخطوة 2: تحميل APNs Authentication Key (للـ iOS)
- [ ] اذهب إلى: Apple Developer > Certificates, IDs & Profiles
- [ ] اذهب إلى: Keys > اضغط **+**
- [ ] اسم المفتاح: `MallawyC are APNs Key`
- [ ] فعّل **Apple Push Notifications service (APNs)**
- [ ] اضغط Continue > Register
- [ ] حمّل الملف `.p8`

📋 **Key ID**: `____________________`
📋 **Team ID**: `____________________`

### الخطوة 3: رفع APNs Key لـ Firebase
- [ ] اذهب إلى: Project Settings > Cloud Messaging > iOS app configuration
- [ ] اضغط "Upload"
- [ ] ارفع ملف `.p8`
- [ ] أدخل **Key ID** و **Team ID**
- [ ] احفظ

---

## ✅ المرحلة 8: إعداد Apple Developer

### الخطوة 1: إنشاء App ID جديد
🔗 **رابط:** https://developer.apple.com/account/resources/identifiers/list

- [ ] اضغط **+** (زر جديد)
- [ ] اختر **App IDs**
- [ ] اختر **App**
- [ ] **Description**: `MallawyC are`
- [ ] **Bundle ID**: `com.mored.mallawycare` (Explicit)
- [ ] فعّل الـ Capabilities:
  - [ ] Sign In with Apple
  - [ ] Push Notifications
  - [ ] Associated Domains (إذا لزم)
- [ ] اضغط Continue > Register

### الخطوة 2: إنشاء Service ID للـ Apple Sign-In
- [ ] اذهب إلى: Identifiers > اضغط **+**
- [ ] اختر **Services IDs**
- [ ] **Description**: `MallawyC are Sign In`
- [ ] **Identifier**: `com.mored.mallawycare.signin`
- [ ] اضغط Continue > Register
- [ ] اختر Service ID الذي أنشأته
- [ ] فعّل **Sign In with Apple**
- [ ] اضغط Configure
- [ ] **Primary App ID**: اختر `com.mored.mallawycare`
- [ ] **Domains and Subdomains**: أضف `mallawycare.page.link` (أو دومينك)
- [ ] **Return URLs**: أضف رابط Firebase Auth callback
  - مثال: `https://clinicalsystem-XXXXX.firebaseapp.com/__/auth/handler`
- [ ] احفظ

📋 **Service ID**: `com.mored.mallawycare.signin`

---

## ✅ المرحلة 9: إعداد Xcode

### تحديث Bundle Identifier
- [ ] افتح: `ios/Runner.xcworkspace` في Xcode
- [ ] اختر **Runner** من القائمة اليسرى
- [ ] اذهب لـ **General** > **Identity**
- [ ] **Bundle Identifier**: `com.mored.mallawycare`
- [ ] **Display Name**: `ملوي كير`

### تحديث Signing & Capabilities
- [ ] اذهب لـ **Signing & Capabilities**
- [ ] اختر Team الخاص بك
- [ ] تأكد من تفعيل:
  - [ ] **Sign In with Apple**
  - [ ] **Push Notifications**
  - [ ] **Background Modes** > Remote notifications

---

## ✅ المرحلة 10: الاختبار

### اختبار iOS
```bash
flutter clean
cd ios && pod install && cd ..
flutter run -d ios
```

- [ ] التطبيق يشتغل
- [ ] Google Sign-In يعمل
- [ ] Apple Sign-In يعمل
- [ ] Notifications تصل
- [ ] Firebase يحفظ البيانات

### اختبار Android
```bash
flutter clean
flutter run -d android
```

- [ ] التطبيق يشتغل
- [ ] Google Sign-In يعمل
- [ ] Notifications تصل
- [ ] Firebase يحفظ البيانات

---

## ✅ المرحلة 11: البناء للنشر

### بناء iOS
```bash
flutter build ios --release
```

- [ ] Build نجح بدون أخطاء
- [ ] حجم التطبيق معقول

### بناء Android
```bash
# إنشاء Release Key جديد
keytool -genkey -v -keystore ~/mallawycare-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mallawycare-release

# بناء AAB
flutter build appbundle --release
```

- [ ] Build نجح بدون أخطاء
- [ ] حجم التطبيق معقول

---

## 🎉 تم الانتهاء!

بعد إتمام كل الخطوات أعلاه، تطبيقك جاهز للرفع على:
- ✅ App Store (iOS)
- ✅ Google Play Store (Android)

---

## 📌 معلومات مهمة للحفظ

| العنصر | القيمة |
|--------|--------|
| **Firebase Project ID** | ________________ |
| **iOS Bundle ID** | com.mored.mallawycare |
| **Android Package** | com.mored.mallawycare |
| **App Name** | ملوي كير - MallawyC are |
| **Web Client ID** | ________________ |
| **FCM Server Key** | ________________ |
| **Apple Team ID** | ________________ |
| **Apple Service ID** | com.mored.mallawycare.signin |

---

**ملاحظة:** احفظ نسخة من هذا الملف مع البيانات المعبأة في مكان آمن! 🔐
