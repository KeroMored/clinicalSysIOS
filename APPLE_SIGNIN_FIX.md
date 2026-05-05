# Apple Sign-In Troubleshooting & Fix Guide

## المشاكل المكتشفة (Issues Found)

### ✅ ما هو موجود (Working):
- `sign_in_with_apple` package مثبت (^7.0.1)
- `Runner.entitlements` يحتوي على `com.apple.developer.applesignin` capability
- AuthRepository و AuthCubit تطبيق صحيح للـ nonce و hashing
- iOS deployment target = 14.0 (يدعم Apple Sign-In ✓)

### ❌ المشاكل المحتملة (Potential Issues):

1. **Firebase App Check Configuration** ⚠️ 
   - قد تحجب Apple Sign-In requests
   - الحل: تعطيل مؤقت أو تكوين صحيح

2. **Apple Requirements في iOS Bundle**
   - قد تحتاج إلى تحديث معرف الفريق (Team ID)
   - التحقق من provisioning profile

3. **Firestore Rules**
   - قد تحظر طلبات غير مصرح بها
   - التحقق من الوصول

---

## ✅ Step-by-Step Fix Checklist

### خطوة 1: تعطيل Firebase App Check مؤقتاً للاختبار

**File:** `lib/main.dart`

جد هذا الكود:
```dart
await FirebaseAppCheck.instance.activate(
  ...
);
```

استبدله بـ:
```dart
// Temporarily disable for Apple Sign-In debugging
// await FirebaseAppCheck.instance.activate(
//   webRecaptchaSiteKeyForWeb: '',
//   androidProvider: AndroidUserAgentProvider(),
// );
```

**Why:** قد تمنع App Check بعض authentication methods في الاختبار الأول.

---

### خطوة 2: التحقق من iOS Bundle ID و Team ID

**في Xcode:**
1. اذهب إلى `Runner.xcworkspace` (ليس `Runner.xcodeproj`)
2. اختر `Runner` project
3. اختر `Runner` target
4. اذهب إلى `Signing & Capabilities`
5. تأكد من:
   - Team مختار صحيح ✓
   - Bundle ID = `com.mallawy.clinicalsystem`
   - Signing Certificate انتقيت

**في Apple Developer Portal:**
1. اذهب إلى https://developer.apple.com/account/resources/identifiers
2. ابحث عن `com.mallawy.clinicalsystem`
3. تأكد من تفعيل capability: **Sign in with Apple**
4. حفظ وحدّث provisioning profile

---

### خطوة 3: تحديث Firebase Configuration

**File:** `lib/features/auth/data/repositories/auth_repository.dart`

أضف استثناء Firebase App Check للـ Apple Sign-In:

```dart
import 'package:firebase_app_check/firebase_app_check.dart';

// في داخل signInWithApple():

try {
  // Disable App Check temporarily for Apple Sign-In
  FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
  
  final isAvailable = await SignInWithApple.isAvailable();
  // ... rest of code ...
  
  // Re-enable after success
  FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
} catch (e) {
  FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  // ...
}
```

---

### خطوة 4: تحديث Firestore Rules

**File:** `firestore.rules`

أضف قاعدة للسماح بـ Apple Sign-In users:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      // Allow users to read their own document
      allow read, write: if request.auth.uid == uid;
      
      // Allow creation of new user documents during signup
      allow create: if request.auth.uid == uid;
    }
    
    match /pharmacy_subscriptions/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```

---

### خطوة 5: تنظيف وإعادة بناء

نفذ هذه الأوامر:

```bash
# تنظيف كامل
flutter clean
rm -rf ios/Pods ios/Podfile.lock

# إعادة بناء من الصفر
flutter pub get
cd ios
pod deintegrate
pod install
cd ..

# تشغيل
flutter run -d ios
```

---

## 🔍 Testing Apple Sign-In

### Desktop Testing (macOS):
```bash
flutter run -d macos
# Apple Sign-In يعمل على macOS أيضاً
```

### Device Testing:
1. استخدم physical iPhone (simulator قد لا يعمل في بعض الحالات)
2. تأكد من تسجيل دخول Apple account على الجهاز
3. جرّب مع Apple Test Account إذا كنت in development

---

## 🐛 Debug Tips

### تحقق من الأخطاء:

```dart
// في AuthCubit، أضف logging:

Future<void> signInWithApple() async {
  try {
    print('🍎 Starting Apple Sign-In...');
    emit(AuthLoading());

    final user = await _authRepository.signInWithApple();
    print('🍎 Apple Sign-In success: ${user?.email}');

    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  } catch (e) {
    print('🍎 Apple Sign-In failed: $e');
    emit(AuthError('فشل تسجيل الدخول بواسطة Apple: ${e.toString()}'));
  }
}
```

### Common Errors:

| خطأ | السبب | الحل |
|-----|------|------|
| `Apple Sign-In not available` | Device/Simulator doesn't support | استخدم iOS device أو macOS |
| `Missing identity token` | Nonce not matching | تأكد من hashing صحيح |
| `Failed to sign in: null` | Firebase auth fail | تحقق من credentials و Team ID |
| `User document not created` | Firestore rules blocked | حدّث firestore.rules |

---

## ✅ Final Verification Checklist

- [ ] Team ID مختار في Xcode
- [ ] Bundle ID = `com.mallawy.clinicalsystem`
- [ ] Apple ID capability موجود في App ID settings
- [ ] `Runner.entitlements` يحتوي على `com.apple.developer.applesignin`
- [ ] Firebase credentials صحيحة
- [ ] Firestore rules تسمح بـ user creation
- [ ] `flutter clean` و `pod install` نفذت
- [ ] Testing على device أو macOS (ليس simulator فقط)

---

## 📞 If Still Not Working:

1. **Check Console Output:**
   ```bash
   flutter run -v  # Verbose mode
   ```

2. **Check Firebase Console:**
   - اذهب إلى Firebase Project
   - غيّر Authentication providers
   - تأكد من Apple Provider مفعّل

3. **Regenerate Provisioning Profile:**
   - في Apple Developer Portal
   - حذف القديم
   - أنشئ profile جديد
   - حمّله في Xcode

---

## 🎯 Next Steps

بعد إصلاح Apple Sign-In:

1. **تفعيل Firebase App Check مرة أخرى:**
   ```dart
   // في main.dart، أعد تفعيل App Check
   await FirebaseAppCheck.instance.activate(...);
   ```

2. **Test Google Sign-In:** تأكد من عمل Google أيضاً

3. **Deploy:** تجهيز للـ App Store release

---

**Last Update:** May 3, 2026  
**Status:** 🟡 Pending Implementation
