# ✅ Service ID تم إنشاؤه - الخطوات التالية

## ما تم إنجازه:
- ✅ إنشاء Service ID: `com.mored.mallawicure.signin` في Apple Developer Console
- ✅ تحديث الكود ليستخدم Service ID الجديد
- ✅ رفع التحديثات على GitHub

---

## 🎯 الخطوات المتبقية (بالترتيب):

### 1️⃣ إكمال إعداد Service ID في Apple Developer:

1. افتح: https://developer.apple.com/account/resources/identifiers/list/serviceId
2. اضغط على Service ID: **com.mored.mallawicure.signin**
3. ✅ فعّل **Sign in with Apple** (إذا لم يكن مفعّل)
4. اضغط **Configure** بجانب Sign in with Apple
5. اختر **Primary App ID**: `com.mored.mallawicure`
6. في **Website URLs**:
   - **Domains and Subdomains**: `clinicalsystem-4da35.firebaseapp.com`
   - **Return URLs**: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
7. اضغط **Save** → **Continue** → **Save**

---

### 2️⃣ تحديث Firebase Console:

1. افتح: https://console.firebase.google.com/project/clinicalsystem-4da35/authentication/providers
2. اضغط على **Apple**
3. حدّث الإعدادات:
   - **OAuth code flow configuration**:
     - **Service ID**: `com.mored.mallawicure.signin` ← **مهم جداً**
     - **Team ID**: `84M47YB8XR` (كما هو)
     - **Key ID**: (احتفظ بنفس القيمة الموجودة)
     - **Private Key**: (احتفظ بنفس الـ .p8 file الموجود)
4. اضغط **Save**

---

### 3️⃣ الحصول على ملفات Firebase الجديدة:

#### للـ iOS:
1. في Firebase Console → **Project Settings** (⚙️)
2. تبويب **General**
3. اضغط **Add app** → اختر **iOS**
4. Bundle ID: `com.mored.mallawicure`
5. App nickname: `Mallawi Cure iOS`
6. اضغط **Register app**
7. حمّل `GoogleService-Info.plist`
8. **استبدل** الملف في: `ios/Runner/GoogleService-Info.plist`

#### للـ Android:
1. في نفس الصفحة
2. **Add app** → **Android**
3. Package name: `com.mored.mallawicure`
4. App nickname: `Mallawi Cure Android`
5. حمّل `google-services.json`
6. **استبدل** الملف في: `android/app/google-services.json`

---

### 4️⃣ إنشاء App ID في Apple Developer (إذا لم يكن موجود):

1. افتح: https://developer.apple.com/account/resources/identifiers/list
2. اضغط **+** → **App IDs** → **App**
3. **Description**: Mallawi Cure
4. **Bundle ID**: `com.mored.mallawicure`
5. **Capabilities**: 
   - ✅ Sign in with Apple
   - ✅ Push Notifications
6. اضغط **Continue** → **Register**

---

### 5️⃣ تحديث Google Cloud Console:

1. افتح: https://console.cloud.google.com/apis/credentials?project=clinicalsystem-4da35
2. اضغط على OAuth 2.0 Client ID الخاص بـ iOS
3. حدّث **Bundle ID** إلى: `com.mored.mallawicure`
4. اضغط **Save**

---

### 6️⃣ بعد كل التحديثات - تنظيف المشروع:

```bash
flutter clean
cd ios
pod install
cd ..
flutter run
```

---

## 📋 Checklist:

- [ ] إكمال إعداد Service ID في Apple Developer
- [ ] تحديث Service ID في Firebase Console
- [ ] تحديث ملف `GoogleService-Info.plist` للـ iOS
- [ ] تحديث ملف `google-services.json` للـ Android
- [ ] إنشاء App ID في Apple Developer
- [ ] تحديث Bundle ID في Google Cloud Console
- [ ] تشغيل `flutter clean` و `pod install`
- [ ] اختبار Apple Sign-In على جهاز iPhone حقيقي
- [ ] اختبار Google Sign-In على جهاز iPhone حقيقي

---

## ⚠️ ملاحظات مهمة:

1. **Service ID الجديد**: `com.mored.mallawicure.signin` (بدون رقم في النهاية)
2. **Bundle ID الجديد**: `com.mored.mallawicure` (تم تحديث كل الملفات)
3. **Return URL**: يجب أن يكون `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
4. **الكود جاهز**: كل شيء محدث في الكود، فقط اكمل الإعدادات في Firebase و Apple Developer

---

**آخر تحديث**: 2026-06-19 16:00
**حالة الكود**: ✅ جاهز ومرفوع على GitHub
**حالة الإعدادات**: ⏳ محتاج إكمال الخطوات أعلاه
