# تحديث Bundle ID إلى com.mored.mallawicure - الخطوات المطلوبة

## ✅ تم إنجازه:
1. ✅ تحديث Bundle ID في جميع الملفات إلى `com.mored.mallawicure`
2. ✅ تحديث App Icon من الصورة الجديدة `assets/images/LO.png`
3. ✅ تحديث Splash Screen من الصورة الجديدة `assets/images/splash.png`
4. ✅ تحديث الإصدار إلى `1.0.0+13`
5. ✅ رفع الكود على GitHub

## 🔴 مطلوب منك الآن - Firebase Configuration:

### 1️⃣ Firebase Console - ملفات التكوين الجديدة:

يجب عليك الحصول على ملفات Firebase جديدة للـ Bundle ID الجديد:

#### للـ iOS:
1. افتح Firebase Console: https://console.firebase.google.com/project/clinicalsystem-4da35
2. اذهب إلى **Project Settings** (⚙️)
3. في تبويب **General**، اضغط على **Add app** → اختر **iOS**
4. أدخل Bundle ID: `com.mored.mallawicure`
5. أدخل App nickname: `Mallawi Cure iOS`
6. اضغط **Register app**
7. حمّل ملف `GoogleService-Info.plist` الجديد
8. **استبدل** الملف القديم في: `ios/Runner/GoogleService-Info.plist`

#### للـ Android:
1. في نفس الصفحة في Firebase Console
2. اضغط على **Add app** → اختر **Android**
3. أدخل Package name: `com.mored.mallawicure`
4. أدخل App nickname: `Mallawi Cure Android`
5. اضغط **Register app**
6. حمّل ملف `google-services.json` الجديد
7. **استبدل** الملف القديم في: `android/app/google-services.json`

### 2️⃣ Apple Developer Console - التحديثات المطلوبة:

#### إنشاء App ID جديد:
1. افتح: https://developer.apple.com/account/resources/identifiers/list
2. اضغط على **+** لإنشاء App ID جديد
3. اختر **App IDs** → **App**
4. **Description**: Mallawi Cure
5. **Bundle ID**: `com.mored.mallawicure`
6. **Capabilities**: 
   - ✅ Sign in with Apple
   - ✅ Push Notifications
   - ✅ Associated Domains (إذا كنت تستخدمها)
7. اضغط **Continue** ثم **Register**

#### إنشاء Service ID جديد (لـ Apple Sign-In):
1. في نفس الصفحة، اضغط **+**
2. اختر **Services IDs**
3. **Description**: Mallawi Cure Sign In
4. **Identifier**: `com.mored.mallawicure.signin`
5. اضغط **Continue** ثم **Register**
6. بعد الإنشاء، اضغط على الـ Service ID اللي أنشأته
7. ✅ فعّل **Sign in with Apple**
8. اضغط **Configure** بجانب Sign in with Apple
9. **Primary App ID**: اختر `com.mored.mallawicure`
10. **Website URLs**: 
    - **Domains and Subdomains**: `clinicalsystem-4da35.firebaseapp.com`
    - **Return URLs**: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
11. اضغط **Save** ثم **Continue** ثم **Save**

### 3️⃣ Firebase Console - تحديث Apple Sign-In:

1. في Firebase Console → **Authentication**
2. اذهب إلى تبويب **Sign-in method**
3. اضغط على **Apple**
4. تأكد من التحديثات التالية:
   - **Service ID**: `com.mored.mallawicure.signin` ✅ تم إنشاؤه
   - **Team ID**: `84M47YB8XR` (كما هو)
   - **Key ID**: (احتفظ بنفس القيمة)
   - **Private Key**: (احتفظ بنفس الـ .p8 file)
5. اضغط **Save**

### 4️⃣ Google Cloud Console - تحديث OAuth:

1. افتح: https://console.cloud.google.com/apis/credentials?project=clinicalsystem-4da35
2. اضغط على OAuth 2.0 Client ID الخاص بـ iOS
3. حدّث **Bundle ID** إلى: `com.mored.mallawicure`
4. اضغط **Save**

## 📋 ملخص التحديثات المطلوبة:

| المنصة | التحديث المطلوب | الحالة |
|--------|-----------------|--------|
| iOS Project Files | Bundle ID → `com.mored.mallawicure` | ✅ تم |
| Android Project Files | Package → `com.mored.mallawicure` | ✅ تم |
| App Icon | صورة جديدة | ✅ تم |
| Splash Screen | صورة جديدة | ✅ تم |
| Firebase iOS | ملف `GoogleService-Info.plist` جديد | ⏳ مطلوب منك |
| Firebase Android | ملف `google-services.json` جديد | ⏳ مطلوب منك |
| Apple Developer | App ID جديد | ⏳ مطلوب منك |
| Apple Developer | Service ID جديد | ⏳ مطلوب منك |
| Firebase Auth | تحديث Service ID | ✅ تم إنشاؤه - محتاج تحديث في Firebase |
| Google Cloud | تحديث OAuth Bundle ID | ⏳ مطلوب منك |

## ⚠️ مهم جداً:

1. **لا تحذف** الـ App ID القديم (`com.mored.mallawycare`) من Apple Developer حتى تتأكد أن كل شيء شغال
2. **احتفظ** بنسخة من ملفات Firebase القديمة قبل استبدالها
3. بعد تحديث ملفات Firebase، قم بعمل:
   ```bash
   flutter clean
   cd ios
   pod install
   cd ..
   flutter run
   ```
4. اختبر Apple Sign-In و Google Sign-In على جهاز حقيقي بعد التحديثات

## 🎯 الخطوات التالية:

1. نفّذ جميع التحديثات المذكورة أعلاه
2. استبدل ملفات Firebase الجديدة
3. اعمل Flutter clean و pod install
4. اختبر على جهاز iPhone حقيقي
5. تأكد من عمل Apple Sign-In بدون أخطاء
6. ارفع التحديثات على App Store

---

**تم التحديث في**: 2026-06-19
**الإصدار الحالي**: 1.0.0+13
**Bundle ID الجديد**: com.mored.mallawicure
**Service ID**: com.mored.mallawicure.signin ✅ (تم إنشاؤه بواسطة المستخدم)

## ✅ تحديث: Service ID تم إنشاؤه

تم إنشاء Service ID بنجاح: `com.mored.mallawicure.signin`

**الخطوة التالية المطلوبة:**
1. افتح [Apple Developer Console](https://developer.apple.com/account/resources/identifiers/list/serviceId)
2. اضغط على Service ID: `com.mored.mallawicure.signin`
3. تأكد من تفعيل وإعداد **Sign in with Apple** كما موضح في القسم 2️⃣ أعلاه
4. ثم حدّث Firebase Console كما موضح في القسم 3️⃣
