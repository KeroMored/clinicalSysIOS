# 🍎 Apple Sign-In Quick Fix Guide

## 🔍 المشكلة الأساسية (Root Cause)
Apple Sign-In على iOS يحتاج تكوين خاص:
1. ✅ Package مثبت (`sign_in_with_apple`)
2. ✅ Entitlements صحيحة
3. ⚠️ **Firebase App Check قد تحجبها** ← هذا هو المشكل الأكثر شيوعاً
4. ❓ Team ID و Provisioning Profile قد لا تكون صحيحة

---

## 🚀 الحل السريع (Immediate Fix)

### 1️⃣ تعطيل App Check مؤقتاً (للاختبار)

**File:** `lib/main.dart` (lines ~69-82)

البحث عن هذا الكود:
```dart
if (Platform.isAndroid || Platform.isIOS) {
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttestWithDeviceCheckFallback,
  );
}
```

**استبدله بـ:**
```dart
if (Platform.isAndroid) {
  // Only enable App Check on Android for now
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
  );
}
// Disable on iOS temporarily to debug Apple Sign-In
// TODO: Re-enable after configuring proper AppleProvider settings
```

**Save and run:**
```bash
flutter clean
flutter pub get
flutter run -d ios
```

---

### 2️⃣ دقق على Xcode Settings

**اتبع هذه الخطوات:**

1. اذهب إلى `ios/Runner.xcworkspace` (ليس `.xcodeproj`)
   ```bash
   open ios/Runner.xcworkspace
   ```

2. اختر `Runner` → `Signing & Capabilities`

3. تأكد من:
   - ✅ Team مختار (مثل "Your Name")
   - ✅ Bundle ID = `com.mallawy.clinicalsystem`
   - ✅ Signing Certificate valid

4. في الجزء السفلي: `+ Capability` → ابحث عن `Sign in with Apple`
   - اختره (سيضيف capability تلقائياً)

5. **حفظ:**
   ```bash
   Cmd + S
   ```

---

### 3️⃣ إصلاح Apple Developer Portal

**في https://developer.apple.com:**

1. اذهب إلى **Certificates, IDs & Profiles** → **Identifiers**
2. ابحث عن `com.mallawy.clinicalsystem`
3. تأكد من تفعيل: **Sign in with Apple** capability
4. حفظ
5. اذهب إلى **Profiles** → حذف القديم وأنشئ واحد جديد
6. حمّل الـ `.mobileprovision` file الجديد

---

### 4️⃣ تنظيف وإعادة بناء

```bash
cd /path/to/clinicalSys-main

# تنظيف كامل
flutter clean
rm -rf ios/Pods ios/Podfile.lock

# إعادة بناء
flutter pub get
cd ios
pod install
cd ..

# تشغيل
flutter run -d ios -v
```

**ستظهر debug logs الآن:**
```
🍎 [Apple Sign-In] Checking availability...
🍎 [Apple Sign-In] Generating nonce...
🍎 [Apple Sign-In] Requesting Apple ID credential...
```

---

## ✅ اختبار السريع

### على Device (الأفضل):
```bash
flutter run -d ios
# ثم اضغط على زر Apple في التطبيق
```

### على Simulator:
```bash
flutter run -d "iPhone 15 Pro"
# قد لا يعمل إذا لم يكن مسجل فيه iCloud account
```

---

## 🆘 إذا استمرت المشكلة

### تحقق من الأخطاء:

```bash
# شغّل مع verbose logging
flutter run -d ios -v 2>&1 | grep -i apple
```

**الأخطاء الشائعة:**

| الخطأ | الحل |
|------|------|
| `Apple Sign-In not available` | استخدم physical device (ليس simulator) |
| `Missing identity token` | تأكد من Bundle ID صحيح |
| `Firebase auth failed` | تحقق من credentials في Firebase console |
| `Blocked by policy` | عطّل App Check مؤقتاً |

---

## 📋 Checklist قبل الإطلاق

- [ ] Bundle ID = `com.mallawy.clinicalsystem` ✓
- [ ] Team ID مختار في Xcode ✓
- [ ] Apple ID capability موجود (في Xcode و Apple Developer) ✓
- [ ] `Runner.entitlements` يحتوي عليه ✓
- [ ] Firebase settings صحيحة ✓
- [ ] `flutter clean` و `pod install` نفذت ✓
- [ ] اختبرت على iOS device ✓

---

## ⚠️ قبل الإطلاق للـ App Store

**أعد تفعيل App Check:**

في `lib/main.dart`:

```dart
if (Platform.isAndroid || Platform.isIOS) {
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttestWithDeviceCheckFallback,
  );
}
```

---

**تم إضافة debug logging تلقائياً:**
- AuthRepository.signInWithApple() ← detailed steps
- AuthCubit.signInWithApple() ← cubit flow

**شغّل الآن:**
```bash
flutter run -d ios -v
```

شوف الـ console logs وأبلغني عن أي أخطاء! 📱
