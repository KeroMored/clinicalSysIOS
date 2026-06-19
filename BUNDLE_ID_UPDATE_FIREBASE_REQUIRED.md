# تحديث Bundle ID إلى com.mored.mallawicure - الخطوات المطلوبة (iOS فقط)

## ✅ تم إنجازه:
1. ✅ تحديث Bundle ID في جميع ملفات **iOS** إلى `com.mored.mallawicure`
2. ✅ تحديث App Icon من الصورة الجديدة `assets/images/LO.png`
3. ✅ تحديث Splash Screen من الصورة الجديدة `assets/images/splash.png`
4. ✅ تحديث الإصدار إلى `1.0.0+13`
5. ✅ رفع الكود على GitHub
6. ✅ الحفاظ على Android Package Name القديم: `com.mored.MallawyHealthCare`

## 📱 معلومات المنصات:

### iOS (الجديد - للـ App Store):
- **Bundle ID**: `com.mored.mallawicure`
- **App Name**: ملوي كيور | Mallawi Cure
- **Version**: 1.0.0+13

### Android (القديم - مرفوع على Google Play):
- **Package Name**: `com.mored.MallawyHealthCare` (بدون تغيير)
- **App Name**: ملوي كيور | Mallawi Cure
- **ملف Firebase**: `android/app/google-services.json` (بدون تغيير)

---

##  مطلوب منك الآن - Firebase Configuration لـ iOS فقط:

### 1️⃣ Firebase Console - ملف iOS فقط:

#### للـ iOS (مطلوب):
1. افتح Firebase Console: https://console.firebase.google.com/project/clinicalsystem-4da35
2. اذهب إلى **Project Settings** (⚙️)
3. في تبويب **General**، اضغط على **Add app** → اختر **iOS**
4. أدخل Bundle ID: `com.mored.mallawicure`
5. أدخل App nickname: `Mallawi Cure iOS`
6. اضغط **Register app**
7. حمّل ملف `GoogleService-Info.plist` الجديد
8. **استبدل** الملف القديم في: `ios/Runner/GoogleService-Info.plist`

#### للـ Android (لا تعدل):
- ✅ **اترك** ملف `android/app/google-services.json` كما هو
- ✅ Android Package Name: `com.mored.MallawyHealthCare` (بدون تغيير)
- التطبيق الموجود على Google Play يشتغل بنفس الإعدادات القديمة

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

#### Service ID (لـ Apple Sign-In):
1. في نفس الصفحة، اضغط **+**
2. اختر **Services IDs**
3. **Description**: Mallawi Cure Sign In
4. **Identifier**: `com.mored.mallawicure.signin` ✅ (تم إنشاؤه)
5. تأكد من الإعدادات:
   - ✅ فعّل **Sign in with Apple**
   - اضغط **Configure**
   - **Primary App ID**: `com.mored.mallawicure`
   - **Website URLs**: 
     - **Domains**: `clinicalsystem-4da35.firebaseapp.com`
     - **Return URLs**: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
   - اضغط **Save** → **Continue** → **Save**

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
| Android Project Files | Package → `com.mored.MallawyHealthCare` | ✅ لم يتغير (كما هو) |
| App Icon | صورة جديدة | ✅ تم |
| Splash Screen | صورة جديدة | ✅ تم |
| Firebase iOS | ملف `GoogleService-Info.plist` جديد | ⏳ مطلوب منك |
| Firebase Android | ملف `google-services.json` | ✅ لا تعدل (خليه كما هو) |
| Apple Developer | App ID جديد | ⏳ مطلوب منك |
| Apple Developer | Service ID | ✅ تم إنشاؤه - محتاج إكمال الإعداد |
| Firebase Auth | تحديث Service ID | ⏳ مطلوب منك |
| Google Cloud | تحديث OAuth Bundle ID | ⏳ مطلوب منك |

## ⚠️ مهم جداً:

1. **لا تحذف** الـ App ID القديم (`com.mored.mallawycare`) من Apple Developer حتى تتأكد أن كل شيء شغال
2. **احتفظ** بنسخة من ملف iOS Firebase القديم قبل استبداله
3. **لا تعدل** أي شيء خاص بـ Android - التطبيق على Play Store يشتغل بالإعدادات القديمة
4. بعد تحديث ملف iOS Firebase، قم بعمل:
   ```bash
   flutter clean
   cd ios
   pod install
   cd ..
   flutter run
   ```
5. اختبر Apple Sign-In و Google Sign-In على جهاز iPhone حقيقي بعد التحديثات

## 🎯 الخطوات التالية:

1. نفّذ جميع التحديثات المذكورة أعلاه لـ **iOS فقط**
2. استبدل ملف `GoogleService-Info.plist` الجديد
3. اعمل Flutter clean و pod install
4. اختبر على جهاز iPhone حقيقي
5. تأكد من عمل Apple Sign-In بدون أخطاء
6. ارفع التحديثات على App Store

---

**تم التحديث في**: 2026-06-19
**الإصدار الحالي**: 1.0.0+13
**Bundle ID الجديد (iOS)**: com.mored.mallawicure
**Package Name (Android)**: com.mored.MallawyHealthCare (بدون تغيير)
**Service ID**: com.mored.mallawicure.signin ✅ (تم إنشاؤه بواسطة المستخدم)
