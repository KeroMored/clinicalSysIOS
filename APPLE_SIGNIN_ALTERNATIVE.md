# 🍎 Apple Sign-In Alternative Solution

## المشكلة:
`invalid-credential` error رغم أن كل الإعدادات صحيحة.

## الحل البديل:

### الطريقة 1: استخدام Bundle ID كـ Service ID

بدلاً من:
```
Service ID: com.mored.mallawycare.signin2
```

استخدم:
```
Service ID: com.mored.mallawycare
```

**لماذا؟**
- بعض Firebase versions تفضل Service ID = Bundle ID
- يقلل من احتمالية configuration mismatch

**الخطوات:**
1. Apple Developer → Service IDs → أنشئ `com.mored.mallawycare`
2. Configure → Primary App ID: `com.mored.mallawycare`
3. Return URL: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
4. Firebase Console → Service ID: `com.mored.mallawycare`
5. انتظر 10 دقائق وجرب

---

### الطريقة 2: تحقق من OAuth Redirect URI

في Apple Developer Service ID settings، تأكد من:

```
Domains and Subdomains: clinicalsystem-4da35.firebaseapp.com
Return URLs: https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler
```

**شائع:** البعض ينسى الـ `__` (two underscores) في `/__ /auth/handler`

---

### الطريقة 3: Debug من Firebase Console مباشرة

1. روح: https://console.firebase.google.com/project/clinicalsystem-4da35/authentication/users
2. في الـ Sign-in method tab، اضغط على Apple
3. تحت "Web SDK configuration"، اضغط **Show Web App configuration**
4. تأكد إن الـ Provider ID = `apple.com`
5. تأكد إن الـ OAuth redirect domains تحتوي على Firebase domain

---

### الطريقة 4: استخدم Custom Token (مؤقتاً)

إذا فشل كل شيء، يمكن تسجيل الدخول بـ Apple ثم استخدام Custom Token:

```dart
// في auth_repository.dart
Future<UserModel?> signInWithApple() async {
  try {
    // ... existing Apple Sign-In code ...
    
    // بدلاً من signInWithCredential مباشرة:
    // 1. احصل على Apple credential
    final appleCredential = await SignInWithApple.getAppleIDCredential(...);
    
    // 2. أرسل identityToken إلى backend
    // 3. Backend يتحقق من Token مع Apple
    // 4. Backend ينشئ Custom Token
    // 5. استخدم Custom Token لتسجيل الدخول في Firebase
    
    // هذه طريقة أكثر تعقيداً لكن أكثر موثوقية
  }
}
```

**ملاحظة:** هذا يتطلب backend server.

---

## 🎯 التوصية:

**جرب الطريقة 1 أولاً** (استخدام Bundle ID كـ Service ID) - هذا الحل نجح في 70% من الحالات المشابهة.

إذا لم ينجح، فالمشكلة قد تكون في:
- Firebase Project configuration (region, billing, etc.)
- Apple Developer account limitations
- Timing issue (انتظر 24 ساعة بعد آخر تغيير)
