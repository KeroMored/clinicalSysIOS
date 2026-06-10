# ✅ إعداد Apple Sign-In الكامل - دليل التشخيص والإصلاح

## 📋 الحالة الحالية

### ✅ ما تم التحقق منه في الكود:

#### 1. Entitlements ✅
**الملف:** `ios/Runner/Runner.entitlements`
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```
**الحالة:** ✅ موجود وصحيح

#### 2. Bundle ID ✅
```
com.mored.mallawycare
```
**الحالة:** ✅ متسق في جميع الملفات

#### 3. الكود (auth_repository.dart) ✅
- ✅ استخدام Nonce صحيح
- ✅ SHA256 hashing
- ✅ OAuth credential creation
- ✅ معالجة الأخطاء شاملة
- ✅ التحقق من توفر Apple Sign-In

---

## ⚠️ الأشياء التي يجب التحقق منها

### 1️⃣ Apple Developer Console

#### A. App ID
🔗 **رابط:** https://developer.apple.com/account/resources/identifiers/list

**التحقق المطلوب:**
- [ ] يوجد App ID باسم: `com.mored.mallawycare`
- [ ] Capability "Sign In with Apple" **مُفعّلة** ✅
- [ ] Configure Capability: تأكد من الإعدادات

**كيفية التحقق:**
1. اذهب للرابط أعلاه
2. ابحث عن `com.mored.mallawycare`
3. افتح الـ App ID
4. تأكد من وجود ✅ بجانب "Sign In with Apple"
5. إذا كانت غير مُفعّلة، فعّلها واحفظ

---

#### B. Service ID (مهم جداً!)
🔗 **رابط:** https://developer.apple.com/account/resources/identifiers/list/serviceId

**المطلوب:**
```
Service ID: com.mored.mallawycare.signin
```

**خطوات الإنشاء (إذا لم يكن موجود):**

1. **إنشاء Service ID:**
   - اضغط **+ (زر جديد)**
   - اختر **Services IDs**
   - اضغط Continue

2. **التسمية:**
   - **Description:** MallawyC are Sign In
   - **Identifier:** `com.mored.mallawycare.signin`
   - فعّل ✅ **Sign In with Apple**
   - اضغط Continue ثم Register

3. **Configure Sign In with Apple:**
   - اختر Service ID الذي أنشأته
   - اضغط **Configure** بجانب Sign In with Apple
   
   **Primary App ID:**
   - اختر: `com.mored.mallawycare`
   
   **Domains and Subdomains:**
   - أضف: `clinicalsystem-4da35.firebaseapp.com`
   - **ملاحظة:** استخدم Firebase Project ID الخاص بك
   
   **Return URLs:**
   - أضف: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
   - **مهم:** استبدل `clinicalsystem-4da35` بـ Project ID من Firebase

4. **حفظ:**
   - اضغط Save
   - اضغط Continue
   - اضغط Save مرة أخرى

---

### 2️⃣ Firebase Console

🔗 **رابط:** https://console.firebase.google.com/project/clinicalsystem-4da35/authentication/providers

**التحقق المطلوب:**

#### A. تفعيل Apple Sign-In
- [ ] Apple provider **مُفعّل** ✅

#### B. OAuth redirect domain
- [ ] تأكد من إضافة: `mallawy.com` (إذا كنت تستخدمه)

#### C. Service ID Configuration في Firebase
في صفحة Apple provider في Firebase:

**يجب إدخال:**

1. **OAuth client ID (من Apple Developer):**
   ```
   com.mored.mallawycare.signin
   ```

2. **Team ID:**
   - اذهب إلى: https://developer.apple.com/account/#/membership/
   - انسخ **Team ID** (مكون من 10 أحرف)
   - مثال: `A1B2C3D4E5`

3. **Key ID و Private Key:**
   
   **إذا لم تكن أنشأتهم بعد:**
   
   أ. إنشاء Key:
   - اذهب: https://developer.apple.com/account/resources/authkeys/list
   - اضغط **+** (زر جديد)
   - **Key Name:** MallawyC are Apple Sign In Key
   - فعّل ✅ **Sign in with Apple**
   - اضغط Configure
   - **Primary App ID:** اختر `com.mored.mallawycare`
   - اضغط Save
   - اضغط Continue
   - اضغط Register
   
   ب. تحميل Key:
   - **احفظ Key ID** (مكون من 10 أحرف، مثل: `AB12CD34EF`)
   - اضغط **Download**
   - احفظ ملف `.p8` في مكان آمن
   - **تحذير:** لا يمكن تحميله مرة أخرى!
   
   ج. إضافة Key في Firebase:
   - افتح Firebase Console → Authentication → Apple
   - **Key ID:** الصق الـ Key ID
   - **Private Key:** افتح ملف `.p8` بـ Notepad وانسخ كل المحتوى والصقه

---

### 3️⃣ Xcode Configuration

#### A. فتح المشروع:
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
open ios/Runner.xcworkspace
```

#### B. التحقق من الإعدادات:

**في Xcode:**

1. **اختر Runner** من القائمة اليسرى
2. **اذهب لـ Signing & Capabilities**

**يجب أن ترى:**
- ✅ **Sign In with Apple** capability موجودة
- ✅ Team مختار
- ✅ Bundle Identifier: `com.mored.mallawycare`
- ✅ Provisioning Profile صالح

**إذا لم تجد "Sign In with Apple":**
- اضغط **+ Capability**
- ابحث عن "Sign In with Apple"
- أضفها

---

### 4️⃣ Info.plist (تم التحقق منه) ✅

الملف محدّث بالفعل ولكن للمراجعة:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.718616577077-1q7n6ub417t7naj1ufo1cb1ji3i88g5d</string>
        </array>
    </dict>
</array>
```

---

## 🔍 التشخيص: الأخطاء الشائعة وحلولها

### خطأ 1: "The operation couldn't be completed"
**السبب:** Service ID غير موجود أو غير مُعد بشكل صحيح

**الحل:**
1. تأكد من إنشاء Service ID في Apple Developer
2. تأكد من Configure Sign In with Apple
3. تأكد من إضافة Return URL الصحيح

---

### خطأ 2: "Missing identity token"
**السبب:** مشكلة في Provisioning Profile

**الحل:**
1. في Xcode: اذهب لـ Signing & Capabilities
2. احذف Provisioning Profile الحالي
3. اختر Team مرة أخرى
4. دع Xcode يُنشئ profile جديد

---

### خطأ 3: Error 1000
**السبب:** Bundle ID في Xcode لا يطابق App ID في Apple Developer

**الحل:**
```bash
# تأكد من Bundle ID في Xcode
grep -r "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```
**يجب أن يكون:** `com.mored.mallawycare`

---

### خطأ 4: Firebase auth/invalid-credential
**السبب:** Firebase لم يُعد بشكل صحيح

**الحل:**
1. راجع Firebase Console → Authentication → Apple
2. تأكد من:
   - Service ID صحيح
   - Team ID صحيح
   - Key ID و Private Key صحيحين

---

## ✅ قائمة التحقق الكاملة

### Apple Developer Console:
- [ ] App ID موجود: `com.mored.mallawycare`
- [ ] Sign In with Apple capability مُفعّلة في App ID
- [ ] Service ID موجود: `com.mored.mallawycare.signin`
- [ ] Service ID مُعد بـ Domain و Return URL
- [ ] Key ID موجود وتم تحميل Private Key

### Firebase Console:
- [ ] Apple provider مُفعّل
- [ ] Service ID مضاف: `com.mored.mallawycare.signin`
- [ ] Team ID مضاف
- [ ] Key ID مضاف
- [ ] Private Key مضاف

### Xcode:
- [ ] Sign In with Apple capability موجودة
- [ ] Bundle Identifier: `com.mored.mallawycare`
- [ ] Team مختار
- [ ] Provisioning Profile صالح

### الكود:
- [x] Entitlements صحيح ✅
- [x] Info.plist محدّث ✅
- [x] Auth repository implementation صحيح ✅

---

## 🧪 الاختبار

### 1. اختبار على Simulator:
```bash
flutter run -d "iPhone 15 Pro"
```
**ملاحظة:** Apple Sign-In لا يعمل على Simulator! يظهر رسالة أنه غير متاح.

### 2. اختبار على جهاز حقيقي:
```bash
# تأكد من توصيل iPhone
flutter run -d <device_id>
```

**متطلبات الاختبار:**
- ✅ iPhone فيزيائي (ليس Simulator)
- ✅ مسجل دخول بـ Apple ID
- ✅ iOS 13 أو أحدث
- ✅ Build مع Team صحيح

---

## 📝 معلومات للحفظ

```
Bundle ID:        com.mored.mallawycare
Service ID:       com.mored.mallawycare.signin
Team ID:          _______________  (10 أحرف)
Key ID:           _______________  (10 أحرف)
Firebase Domain:  clinicalsystem-4da35.firebaseapp.com
Return URL:       https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler
```

---

## 🚨 إذا استمرت المشكلة

### خطوات إضافية:

1. **احذف التطبيق من الجهاز** وأعد تثبيته
2. **نظّف Xcode:**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter clean
   flutter pub get
   ```

3. **تأكد من Provisioning Profile:**
   - في Xcode: Product > Clean Build Folder
   - أعد Build

4. **فحص Logs:**
   ```bash
   flutter run --verbose
   ```
   ابحث عن أي رسائل خطأ من Apple Sign-In

---

## 📞 للدعم الإضافي

إذا استمرت المشكلة بعد التحقق من كل النقاط أعلاه:

1. شارك **رسالة الخطأ بالضبط**
2. شارك **logs** من `flutter run --verbose`
3. تأكد من أن **جميع** النقاط في قائمة التحقق مُكتملة ✅

---

**آخر تحديث:** 11 يونيو 2026  
**الحالة:** جاهز للتشخيص والإصلاح ✅
