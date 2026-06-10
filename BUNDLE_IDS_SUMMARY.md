# ملخص معرفات التطبيق - Bundle IDs Summary 🆔

## 📱 المعرفات الجديدة للتطبيق

### التطبيق الجديد: ملوي كير - MallawyC are

---

## ✅ المعرفات الحالية (بعد التحديث)

| المنصة | النوع | القيمة |
|--------|------|--------|
| **Flutter** | Package Name | `mallawycare` |
| **iOS** | Bundle Identifier | `com.mored.mallawycare` |
| **Android** | Package Name | `com.mored.mallawycare` |
| **App Display Name** | اسم العرض | `ملوي كير` |
| **Version** | الإصدار | `1.0.0+1` |

---

## 📊 مقارنة التطبيق القديم والجديد

### Bundle IDs:

| العنصر | القديم ❌ | الجديد ✅ |
|--------|----------|----------|
| **Flutter Package** | clinicalsystem | mallawycare |
| **iOS Bundle ID** | com.mallawy.clinicalsystem | **com.mored.mallawycare** |
| **Android Package** | com.mored.MallawyHealthCare | **com.mored.mallawycare** |
| **App Name** | Mallawy Health Care | ملوي كير - MallawyC are |

---

## 🔧 الملفات المحدثة

### ✅ تم تحديث Bundle IDs في:

1. **`android/app/build.gradle.kts`**
   ```kotlin
   namespace = "com.mored.mallawycare"
   applicationId = "com.mored.mallawycare"
   ```

2. **`android/app/src/main/AndroidManifest.xml`**
   ```xml
   <manifest package="com.mored.mallawycare">
   <application android:label="ملوي كير">
   ```

3. **`pubspec.yaml`**
   ```yaml
   name: mallawycare
   description: "تطبيق ملوي كير الصحي الشامل - MallawyC are"
   version: 1.0.0+1
   ```

4. **`ios/Runner/Info.plist`**
   ```xml
   <key>CFBundleDisplayName</key>
   <string>ملوي كير</string>
   <key>CFBundleName</key>
   <string>mallawycare</string>
   ```

5. **`lib/main.dart`**
   ```dart
   title: "ملوي كير - MallawyC are",
   ```

---

## ⚠️ ما يجب تحديثه يدوياً

### 🔴 مطلوب: تحديث في Xcode

**الملف:** `ios/Runner.xcodeproj/project.pbxproj`

**الخطوات:**
1. افتح: `ios/Runner.xcworkspace` في Xcode
2. اختر **Runner** من القائمة اليسرى
3. اذهب إلى **General** > **Identity**
4. غيّر **Bundle Identifier** إلى: `com.mored.mallawycare`
5. احفظ التغييرات

أو ابحث يدوياً في الملف عن:
```
PRODUCT_BUNDLE_IDENTIFIER = com.mallawy.clinicalsystem;
```
وغيّره إلى:
```
PRODUCT_BUNDLE_IDENTIFIER = com.mored.mallawycare;
```

---

### 🔴 مطلوب: إنشاء Firebase Project جديد

عند إنشاء Firebase project جديد، استخدم هذه المعرفات:

#### للـ iOS App:
- **iOS bundle ID:** `com.mored.mallawycare`
- **App nickname:** MallawyC are iOS

#### للـ Android App:
- **Android package name:** `com.mored.mallawycare`
- **App nickname:** MallawyC are Android

---

### 🔴 مطلوب: Apple Developer Setup

#### 1. إنشاء App ID:
- **Description:** MallawyC are
- **Bundle ID:** `com.mored.mallawycare` (Explicit)
- **Capabilities:**
  - ✅ Sign In with Apple
  - ✅ Push Notifications
  - ✅ Associated Domains (إن لزم)

#### 2. إنشاء Service ID (للـ Apple Sign-In):
- **Description:** MallawyC are Sign In
- **Identifier:** `com.mored.mallawycare.signin`
- **Primary App ID:** `com.mored.mallawycare`

---

## 🎯 خطوات التحقق

### تأكد من تطابق المعرفات في جميع الأماكن:

- [ ] `pubspec.yaml` → name: `mallawycare`
- [ ] `android/app/build.gradle.kts` → applicationId: `com.mored.mallawycare`
- [ ] `android/app/src/main/AndroidManifest.xml` → package: `com.mored.mallawycare`
- [ ] Xcode → Bundle Identifier: `com.mored.mallawycare`
- [ ] Firebase iOS App → Bundle ID: `com.mored.mallawycare`
- [ ] Firebase Android App → Package: `com.mored.mallawycare`
- [ ] Apple Developer App ID → Bundle ID: `com.mored.mallawycare`

---

## 📝 ملاحظات مهمة

### لماذا `com.mored` بدلاً من `com.mallawy`؟

تم اختيار `com.mored` للحفاظ على اتساق مع التطبيق السابق وتجنب أي تعارضات محتملة.

### الفرق بين القديم والجديد:

```
القديم: com.mored.MallawyHealthCare  ← حروف كبيرة وصغيرة
الجديد: com.mored.mallawycare         ← كل الحروف صغيرة (best practice)
```

---

## 🚀 الخطوة التالية

بعد التحقق من كل المعرفات:

1. **نظّف المشروع:**
   ```bash
   ./rebrand_cleanup.sh
   ```

2. **حدّث Bundle ID في Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **أنشئ Firebase Project جديد:**
   - iOS Bundle ID: `com.mored.mallawycare`
   - Android Package: `com.mored.mallawycare`

4. **استبدل ملفات Firebase:**
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

5. **اختبر التطبيق:**
   ```bash
   flutter run -d ios
   flutter run -d android
   ```

---

## ✅ قائمة التحقق النهائية

قبل النشر، تأكد من:

- [ ] جميع الملفات تستخدم `com.mored.mallawycare`
- [ ] Xcode Bundle Identifier محدّث
- [ ] Firebase project جديد بالـ Bundle IDs الصحيحة
- [ ] Apple Developer App ID جديد
- [ ] Google Sign-In يعمل
- [ ] Apple Sign-In يعمل
- [ ] FCM Notifications تعمل
- [ ] التطبيق يُبنى بدون أخطاء

---

**تاريخ التحديث:** 11 يونيو 2026  
**الحالة:** ✅ جاهز للتطبيق

**Bundle ID النهائي المعتمد:** `com.mored.mallawycare`
