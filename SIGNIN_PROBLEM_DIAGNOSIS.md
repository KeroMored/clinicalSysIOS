# 🔍 تشخيص مشاكل تسجيل الدخول

## 🔴 المشاكل الحالية

### 1. Google Sign-In يتعطل (Crash) فوراً ❌
**الأعراض**: عند الضغط على زر Google Sign-In، التطبيق يتعطل مباشرة

### 2. Apple Sign-In يظهر "بيانات غير صالحة" 🍎
**الأعراض**: عند محاولة تسجيل الدخول بـ Apple، تظهر رسالة خطأ "بيانات الاعتماد غير صالحة"

---

## 🔎 السبب الجذري

عندما غيّرنا Bundle ID من `com.mallawy.clinicalsystem` إلى `com.mored.mallawycare`، لم نحدّث إعدادات Firebase بشكل كامل:

### ❌ ما لم يتم تحديثه:

1. **Android**: ملف `google-services.json` لا يزال يحتوي على Bundle IDs القديمة فقط:
   - ❌ `com.example.clinicalsystem` (قديم)
   - ❌ `com.mored.MallawyHealthCare` (قديم)
   - ⚠️ **لا يوجد** `com.mored.mallawycare` (الجديد المطلوب)

2. **iOS**: ملف `GoogleService-Info.plist` يبدو صحيح، لكن يجب التحقق من Firebase Console

3. **Apple Sign-In**: قد لا يكون Service ID محدّث للـ Bundle ID الجديد

---

## ✅ الحل الكامل (خطوة بخطوة)

### 🎯 الهدف النهائي
إضافة Bundle ID الجديد `com.mored.mallawycare` في Firebase Console لكل من Android و iOS، وتحديث إعدادات Apple Sign-In.

---

## 📱 **الجزء 1: إصلاح Android (Google Sign-In Crash)**

### الخطوة 1: افتح Firebase Console
```
https://console.firebase.google.com/project/clinicalsystem-4da35/settings/general
```

### الخطوة 2: تحقق من Android Apps
في قسم **"Your apps"**، ابحث عن:
- App بـ Package name: `com.mored.mallawycare`

### الخطوة 3a: إذا **لم تجد** التطبيق (الأغلب)

**يجب إضافته**:

1. **اضغط "Add app"** أو زر **➕**
2. **اختر Android** (أيقونة الروبوت الأخضر)
3. **املأ البيانات**:
   ```
   Android package name: com.mored.mallawycare
   App nickname (optional): Mallawy Care Android
   Debug signing certificate SHA-1 (optional): [اتركه فارغ الآن]
   ```
4. **اضغط "Register app"**
5. **نزّل ملف `google-services.json`** الجديد
6. **انسخه** واستبدل الملف القديم في مشروعك:
   ```
   android/app/google-services.json
   ```
7. **تحقق** من الملف الجديد يحتوي على:
   ```json
   "package_name": "com.mored.mallawycare"
   ```

### الخطوة 3b: إذا **وجدت** التطبيق

1. **اضغط** على التطبيق (com.mored.mallawycare)
2. **اضغط** على زر **"google-services.json"** في الأسفل
3. **اضغط "Download google-services.json"**
4. **استبدل** الملف في `android/app/google-services.json`

### ✅ نتيجة: Google Sign-In سيعمل على Android بدون crash

---

## 🍎 **الجزء 2: إصلاح iOS (Google & Apple Sign-In)**

### الخطوة 1: تحقق من iOS App في Firebase

في نفس الصفحة:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/settings/general
```

ابحث عن iOS app بـ Bundle ID: `com.mored.mallawycare`

### الخطوة 2a: إذا **لم تجد** التطبيق

**أضف التطبيق**:

1. **اضغط "Add app"**
2. **اختر iOS** (أيقونة Apple)
3. **املأ البيانات**:
   ```
   iOS bundle ID: com.mored.mallawycare
   App nickname (optional): Mallawy Care iOS
   App Store ID (optional): 6779004261
   ```
4. **اضغط "Register app"**
5. **نزّل `GoogleService-Info.plist`**
6. **استبدل** الملف في:
   ```
   ios/Runner/GoogleService-Info.plist
   ```
7. **تحقق** من الملف يحتوي على:
   ```xml
   <key>BUNDLE_ID</key>
   <string>com.mored.mallawycare</string>
   ```

### الخطوة 2b: إذا **وجدت** التطبيق

1. **اضغط** على التطبيق
2. **نزّل `GoogleService-Info.plist`** مرة أخرى
3. **استبدل** الملف القديم

---

## 🔐 **الجزء 3: إصلاح Apple Sign-In**

### الخطوة 1: تحقق من Firebase Authentication

افتح:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/authentication/providers
```

### الخطوة 2: تحقق من Apple Provider

ابحث عن **Apple** في القائمة:

**يجب أن تجد**:
- ✅ **Status**: Enabled (مفعّل)
- ✅ **Service ID**: مثل `com.mored.mallawycare.signin`
- ✅ **Team ID**: `84M47YB8XR`
- ✅ **Key ID**: موجود
- ✅ **Private Key**: مضافة

**إذا لم تجد أو غير مكتمل**، اتبع الخطوات التالية ⬇️

### الخطوة 3: تحديث Apple Developer Console

#### 3.1 افتح Apple Developer
```
https://developer.apple.com/account/resources/identifiers/list
```

#### 3.2 تحقق من App ID

1. **ابحث** عن `com.mored.mallawycare`
2. **افتحه**
3. **تأكد** من تفعيل **"Sign In with Apple"** ✅
4. **إذا لم يكن مفعّل**:
   - اضغط **Edit**
   - ✅ فعّل **Sign In with Apple**
   - اضغط **Save**

#### 3.3 تحقق من Service ID

1. **اذهب** لـ **Service IDs** (من القائمة الجانبية)
2. **ابحث** عن Service ID مثل `com.mored.mallawycare.signin`

**إذا لم تجده، أنشئ واحد جديد**:

1. **اضغط ➕** (Add)
2. **اختر Services IDs**
3. **املأ**:
   ```
   Description: Mallawy Care Sign In
   Identifier: com.mored.mallawycare.signin
   ```
4. **اضغط Continue** → **Register**
5. **الآن عدّله**:
   - اضغط على Service ID الجديد
   - ✅ فعّل **Sign In with Apple**
   - اضغط **Configure**
6. **في نافذة Configure**:
   ```
   Primary App ID: com.mored.mallawycare
   
   Website URLs:
   Domains and Subdomains: clinicalsystem-4da35.firebaseapp.com
   Return URLs: https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler
   ```
7. **اضغط Save** → **Continue** → **Done**

#### 3.4 أضف Service ID في Firebase

1. **ارجع** لـ Firebase Authentication → Apple
2. **إذا Apple غير مفعّل**:
   - اضغط **Add new provider** → **Apple**
3. **في إعدادات Apple**:
   ```
   Service ID: com.mored.mallawycare.signin
   Team ID: 84M47YB8XR
   Key ID: [من Apple Developer - Keys]
   Private Key: [من Apple Developer - Keys]
   ```
4. **اضغط Save**

**ملاحظة عن Key**: إذا لم يكن عندك Key:
1. في Apple Developer → **Keys**
2. اضغط **➕** (Create a key)
3. **Key Name**: "Mallawy Care Sign In Key"
4. ✅ فعّل **Sign In with Apple**
5. اضغط **Configure** → اختر **Primary App ID**
6. اضغط **Save** → **Continue** → **Register**
7. **نزّل الـ .p8 file** (مرة واحدة فقط!)
8. **انسخ Key ID** (يظهر في الصفحة)
9. **استخدمهما** في Firebase

---

## 🧪 الاختبار

بعد تحديث الملفات:

### 1. نظف وابني المشروع
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

### 2. اختبر على iOS
```bash
flutter run --release
```

**جرب**:
- ✅ Google Sign-In (يجب أن يعمل بدون crash)
- ✅ Apple Sign-In (يجب أن يعمل بدون "بيانات غير صالحة")

### 3. اختبر على Android (إذا عندك جهاز)
```bash
flutter run --release
```

**جرب**:
- ✅ Google Sign-In (يجب أن يعمل بدون crash)

---

## 📋 Checklist النهائي

```
Firebase Console - Android:
□ أضفت/وجدت app بـ package name: com.mored.mallawycare
□ نزّلت google-services.json جديد
□ استبدلت android/app/google-services.json
□ الملف الجديد يحتوي على "package_name": "com.mored.mallawycare"

Firebase Console - iOS:
□ أضفت/وجدت app بـ bundle ID: com.mored.mallawycare
□ نزّلت GoogleService-Info.plist جديد
□ استبدلت ios/Runner/GoogleService-Info.plist
□ الملف يحتوي على BUNDLE_ID = com.mored.mallawycare

Apple Developer Console:
□ App ID (com.mored.mallawycare) يحتوي على Sign In with Apple ✅
□ Service ID موجود (com.mored.mallawycare.signin)
□ Service ID مُعدّ بـ Domain و Return URL صحيحين
□ Key موجود ومُنزّل

Firebase Authentication:
□ Apple provider مفعّل
□ Service ID مضاف: com.mored.mallawycare.signin
□ Team ID صحيح: 84M47YB8XR
□ Key ID و Private Key مضافين

المشروع:
□ نظفت المشروع (flutter clean)
□ شغّلت flutter pub get
□ شغّلت pod install
□ اختبرت على جهاز حقيقي
□ Google Sign-In يعمل ✅
□ Apple Sign-In يعمل ✅
```

---

## 🎯 النتيجة المتوقعة

### بعد تطبيق جميع الخطوات:

✅ **Google Sign-In**:
- يعمل على iOS بدون crash
- يعمل على Android بدون crash
- يفتح شاشة اختيار الحساب بشكل طبيعي

✅ **Apple Sign-In**:
- يعمل بدون رسالة "بيانات غير صالحة"
- يفتح شاشة Apple Sign-In الرسمية
- يسجل الدخول بنجاح

---

## ⚠️ ملاحظات مهمة

### 1. لماذا حدثت هذه المشكلة؟
عند تغيير Bundle ID، Firebase يعتبره تطبيق جديد تماماً. لذلك:
- يجب إضافة التطبيق الجديد في Firebase
- يجب تنزيل ملفات الإعدادات الجديدة
- يجب تحديث Service ID في Apple

### 2. هل الملفات القديمة ستتأثر؟
لا، Firebase يحتفظ بالتطبيقات القديمة. يمكنك الاحتفاظ بها أو حذفها.

### 3. هل يجب تحديث Android إذا كنت سأرفع iOS فقط؟
من الأفضل تحديث الاثنين للتأكد من استقرار التطبيق مستقبلاً.

### 4. ملف `google-services.json` الحالي
الملف الحالي يحتوي على:
```json
"package_name": "com.example.clinicalsystem"  ❌ قديم
"package_name": "com.mored.MallawyHealthCare" ❌ قديم
```

المطلوب:
```json
"package_name": "com.mored.mallawycare" ✅ جديد
```

---

## 📞 إذا واجهت مشاكل

### إذا Google Sign-In ما زال يتعطل:
1. تأكد من `google-services.json` محدّث
2. نظف المشروع: `flutter clean && flutter pub get`
3. احذف التطبيق من الجهاز وثبّته من جديد
4. تحقق من Logs في Xcode Console

### إذا Apple Sign-In ما زال يظهر خطأ:
1. تأكد من Service ID موجود ومضاف في Firebase
2. تأكد من Domain و Return URL صحيحين
3. تأكد من Key ID و Private Key صحيحين
4. جرب تسجيل الخروج من Apple ID وتسجيل الدخول مرة أخرى

### إذا احتجت مساعدة:
أرسل Screenshots من:
1. Firebase Console → Your apps (Android و iOS)
2. Firebase Authentication → Apple settings
3. Apple Developer → App ID
4. Apple Developer → Service ID
5. رسالة الخطأ الكاملة

---

**الأولوية**: 🔥 **عاجل جداً**  
**الوقت المتوقع**: 15-20 دقيقة  
**الصعوبة**: ⭐⭐⭐ متوسطة  
**التاريخ**: 12 يونيو 2026

**الخطوة التالية**: ابدأ بالجزء 1 (Android) ثم الجزء 2 (iOS) ثم الجزء 3 (Apple Sign-In)
