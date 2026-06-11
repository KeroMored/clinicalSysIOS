# 🚨 إصلاح عاجل - مشاكل Google Sign-In و Apple Sign-In

## 🔴 المشاكل المكتشفة

### مشكلة 1: Google Sign-In يتعطل (Crash) فوراً ❌
**السبب**: 
- ملف `android/app/google-services.json` **لا يحتوي** على Bundle ID الجديد `com.mored.mallawycare`
- الملف يحتوي فقط على:
  - ❌ `com.example.clinicalsystem` (قديم)
  - ❌ `com.mored.MallawyHealthCare` (قديم)
- Bundle ID الحالي في التطبيق: ✅ `com.mored.mallawycare`
- **النتيجة**: Google Sign-In لا يجد الإعدادات الصحيحة → **Crash**

### مشكلة 2: Apple Sign-In يظهر "بيانات غير صالحة" 🍎
**السبب المحتمل**:
- Bundle ID في Apple Developer Console لا يطابق التطبيق
- أو Apple Sign-In غير مفعّل بشكل صحيح في Firebase
- أو Service ID في Apple غير مضاف للـ Bundle ID الجديد

---

## ✅ الحل الكامل (خطوة بخطوة)

### 🔥 **خطوة 1: تحديث google-services.json (عاجل جداً)**

يجب تنزيل ملف جديد من Firebase Console:

#### 1.1 افتح Firebase Console
```
https://console.firebase.google.com/project/clinicalsystem-4da35/settings/general
```

#### 1.2 اذهب لـ Android App
- في قسم "Your apps"
- ابحث عن Android app بـ Bundle ID: `com.mored.mallawycare`

#### 1.3 إذا لم تجد التطبيق:
**يجب إضافة التطبيق أولاً**:

1. اضغط **"Add app"** أو **"إضافة تطبيق"**
2. اختر **Android**
3. **Android package name**: `com.mored.mallawycare`
4. **App nickname** (اختياري): "Mallawy Care Android"
5. **Debug signing certificate SHA-1** (اختياري - يمكن تركه فارغاً الآن)
6. اضغط **"Register app"**
7. **نزّل `google-services.json`** الجديد
8. **استبدل** الملف القديم في `android/app/google-services.json`

#### 1.4 إذا وجدت التطبيق:
1. اضغط على التطبيق (com.mored.mallawycare)
2. اضغط **"google-services.json"** في الأسفل
3. اضغط **"Download google-services.json"**
4. **استبدل** الملف في `android/app/google-services.json`

---

### 🍎 **خطوة 2: إصلاح Apple Sign-In**

#### 2.1 تحقق من Firebase Console

**افتح**:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/authentication/providers
```

**تحقق من Apple Sign-In**:
1. هل Apple مفعّل؟ يجب أن يكون **Enabled** ✅
2. **Service ID** يجب أن يكون مثل: `com.mored.mallawycare.signin` أو شيء مشابه
3. **OAuth code flow configuration**:
   - Team ID: `84M47YB8XR` ✅
   - Key ID: (يجب أن يكون موجود)
   - Private Key: (يجب أن تكون مضافة)

#### 2.2 تحقق من Apple Developer Console

**افتح**:
```
https://developer.apple.com/account/resources/identifiers/list
```

**تحقق من App ID** (`com.mored.mallawycare`):
1. افتح App ID
2. تأكد من تفعيل **"Sign In with Apple"** ✅
3. إذا لم يكن مفعّل:
   - اضغط **Edit**
   - فعّل **Sign In with Apple**
   - اضغط **Save**

**تحقق من Service ID**:
1. اذهب لـ **Service IDs**
2. ابحث عن Service ID المستخدم في Firebase
3. افتح Service ID
4. تأكد من:
   - **Sign In with Apple** مفعّل ✅
   - **Domains and Subdomains**: `clinicalsystem-4da35.firebaseapp.com`
   - **Return URLs**: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
   - **App IDs**: يحتوي على `com.mored.mallawycare`

#### 2.3 إذا لم يكن Service ID موجود:
**أنشئ واحد جديد**:

1. اضغط **+** (Add)
2. اختر **Services IDs**
3. **Description**: "Mallawy Care Sign In"
4. **Identifier**: `com.mored.mallawycare.signin`
5. اضغط **Continue** → **Register**
6. بعد التسجيل، اضغط **Configure** بجانب Sign In with Apple
7. **Primary App ID**: اختر `com.mored.mallawycare`
8. **Website URLs**:
   - **Domains and Subdomains**: `clinicalsystem-4da35.firebaseapp.com`
   - **Return URLs**: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
9. اضغط **Save** → **Continue** → **Register**

#### 2.4 أضف Service ID الجديد في Firebase:
1. ارجع لـ Firebase Console → Authentication → Sign-in method → Apple
2. **Service ID**: `com.mored.mallawycare.signin` (أو الـ ID الذي أنشأته)
3. اضغط **Save**

---

### 🔥 **خطوة 3: تحديث GoogleService-Info.plist (iOS) - مهم جداً**

ملف iOS يبدو صحيح، لكن تأكد:

#### 3.1 افتح Firebase Console
```
https://console.firebase.google.com/project/clinicalsystem-4da35/settings/general
```

#### 3.2 اذهب لـ iOS App
- ابحث عن iOS app بـ Bundle ID: `com.mored.mallawycare`

#### 3.3 إذا لم تجده:
**أضف التطبيق**:
1. اضغط **"Add app"**
2. اختر **iOS**
3. **Bundle ID**: `com.mored.mallawycare`
4. **App nickname**: "Mallawy Care iOS"
5. **App Store ID** (اختياري): `6779004261`
6. اضغط **Register app**
7. **نزّل `GoogleService-Info.plist`**
8. **استبدل** الملف في `ios/Runner/GoogleService-Info.plist`

#### 3.4 إذا وجدته:
1. اضغط على التطبيق
2. نزّل `GoogleService-Info.plist` مرة أخرى
3. استبدل الملف الحالي

---

## 📋 Checklist سريع

```
Android:
□ أضفت/وجدت com.mored.mallawycare في Firebase (Android)
□ نزّلت google-services.json الجديد
□ استبدلت android/app/google-services.json
□ الملف الجديد يحتوي على "package_name": "com.mored.mallawycare"

iOS:
□ أضفت/وجدت com.mored.mallawycare في Firebase (iOS)
□ نزّلت GoogleService-Info.plist
□ استبدلت ios/Runner/GoogleService-Info.plist
□ الملف يحتوي على BUNDLE_ID = com.mored.mallawycare

Apple Sign-In:
□ Apple مفعّل في Firebase Authentication
□ Service ID موجود ومضاف في Firebase
□ App ID في Apple Developer يحتوي على Sign In with Apple ✅
□ Service ID في Apple Developer مُعدّ بشكل صحيح
□ Team ID صحيح: 84M47YB8XR
□ Private Key مضافة في Firebase
```

---

## 🧪 الاختبار

بعد تحديث الملفات:

### 1. نظف المشروع:
```bash
flutter clean
cd ios
pod install
cd ..
flutter pub get
```

### 2. اختبر على Android (إذا كان عندك):
```bash
flutter run --release
```
- جرب Google Sign-In
- يجب أن يعمل بدون crash

### 3. اختبر على iOS:
```bash
flutter run --release
```
- جرب Apple Sign-In
- جرب Google Sign-In
- يجب أن يعملا بدون مشاكل

---

## 🎯 النتيجة المتوقعة

### بعد الإصلاح:
- ✅ **Google Sign-In**: يعمل بدون crash على iOS و Android
- ✅ **Apple Sign-In**: يعمل بدون رسالة "بيانات غير صالحة"
- ✅ **كلاهما**: تسجيل دخول ناجح أو رسائل خطأ واضحة (بدون crash)

---

## ⚠️ ملاحظة مهمة جداً

**لماذا حصلت هذه المشكلة؟**

عندما غيّرنا Bundle ID من:
- ❌ `com.mallawy.clinicalsystem` → ✅ `com.mored.mallawycare`

كان يجب تحديث Firebase Console وإضافة التطبيقات الجديدة:
1. تطبيق Android جديد بـ Bundle ID الجديد
2. تطبيق iOS جديد بـ Bundle ID الجديد
3. تنزيل ملفات الإعدادات الجديدة
4. تحديث Service ID في Apple Developer

**الآن**: يجب عمل هذا كله ✅

---

## 📞 إذا لم تعرف كيف

**أرسل لي**:
1. Screenshot من Firebase Console → Settings → Your apps
2. Screenshot من Apple Developer Console → Identifiers → App IDs
3. Screenshot من Firebase Authentication → Sign-in method → Apple

وسأساعدك في التحديد الدقيق لما يجب فعله.

---

**الأولوية**: 🔥 **عاجل جداً**  
**السبب**: بدون هذا، Google Sign-In سيظل يتعطل  
**الوقت المتوقع**: 10-15 دقيقة لكل منصة  
**التاريخ**: 12 يونيو 2026
