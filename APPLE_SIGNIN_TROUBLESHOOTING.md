# 🍎 Apple Sign-In Troubleshooting Guide

## ❌ المشكلة الحالية
عند تسجيل الدخول بـ Apple Sign-In، يظهر الخطأ:
```
بيانات الاعتماد غير صالحة، يرجى المحاولة مرة أخرى
```

الخطأ التقني: `FirebaseAuthException: invalid-credential`

---

## ✅ الإعدادات الصحيحة (تم التأكد منها)

### 1. Bundle ID
- ✅ `com.mored.mallawycare`

### 2. Apple Developer - Service ID
- ✅ Service ID: `com.mored.mallawycare.signin`
- ✅ Team ID: `84M47YB8XR`
- ✅ App Store ID: `6779004261`

### 3. Firebase Console - Apple Sign-In
- Location: https://console.firebase.google.com/project/clinicalsystem-4da35/authentication/providers
- ✅ Service ID: `com.mored.mallawycare.signin`
- ✅ Team ID: `84M47YB8XR`
- ⚠️ Key ID: [تحقق من أنه صحيح]
- ⚠️ Private Key: [تحقق من محتوى ملف .p8]

---

## 🔍 السبب الأساسي للمشكلة

الخطأ `invalid-credential` في Apple Sign-In يحدث عندما:

1. **Private Key (.p8) غير صحيح أو لا يتطابق مع Key ID**
2. **Key ID مختلف عن الموجود في Apple Developer Console**
3. **الـ Key منتهي الصلاحية أو تم حذفه**
4. **محتوى الـ .p8 file مكتوب بشكل خاطئ عند النسخ واللصق**

---

## 🔧 خطوات الحل (بالترتيب)

### الخطوة 1: التحقق من Private Key Format

الـ Private Key في Firebase Console لازم يكون بالشكل ده **بالظبط**:

```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
(عدة أسطر من الـ base64 encoded key)
...xQrG2wJCAQE=
-----END PRIVATE KEY-----
```

**تأكد من:**
- ✅ السطر الأول: `-----BEGIN PRIVATE KEY-----`
- ✅ السطر الأخير: `-----END PRIVATE KEY-----`
- ✅ كل الأسطر بينهم موجودة
- ❌ **مفيش مسافات زيادة قبل أو بعد**
- ❌ **مفيش أسطر فاضية**

---

### الخطوة 2: التحقق من Key ID

1. روح Apple Developer Console:
   https://developer.apple.com/account/resources/authkeys/list

2. افتح الـ Key المستخدم في Sign in with Apple

3. انسخ الـ **Key ID** (مثال: `ABC123XYZ4`)

4. تأكد إنه **متطابق تماماً** في Firebase Console

---

### الخطوة 3: إنشاء Key جديد (لو لازم)

إذا كان الـ Key قديم أو فيه مشكلة:

1. **في Apple Developer Console:**
   - Create new Key
   - اختار: **Sign in with Apple**
   - Download الـ `.p8` file
   - ⚠️ **مهم جداً:** الملف ده بينزل مرة واحدة فقط!

2. **افتح الملف في Text Editor:**
   ```bash
   cat AuthKey_ABC123XYZ4.p8
   ```

3. **انسخ المحتوى بالكامل** (من `-----BEGIN` لـ `-----END`)

4. **في Firebase Console:**
   - حط الـ Key ID الجديد
   - الصق المحتوى في Private Key field
   - اضغط Save

5. **انتظر 5-10 دقايق** قبل التجربة

---

### الخطوة 4: التحقق من Service ID Configuration

في Apple Developer Console:
https://developer.apple.com/account/resources/identifiers/list/serviceId

افتح: `com.mored.mallawycare.signin`

**تأكد من:**
- ✅ **Sign In with Apple**: Enabled
- ✅ **Primary App ID**: `com.mored.mallawycare`
- ✅ **Website URLs - Domains**: `clinicalsystem-4da35.firebaseapp.com`
- ✅ **Website URLs - Return URLs**: 
  ```
  https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler
  ```

اضغط **Save** إذا كان في تغييرات

---

### الخطوة 5: اختبار مع Enhanced Logging

التغييرات الأخيرة في الكود بتطبع معلومات مفصلة عند تسجيل الدخول:

عند تجربة Apple Sign-In على iPhone، راقب Console logs في Xcode:

```
🍎 [Apple Sign-In] Checking availability...
🍎 [Apple Sign-In] Generating nonce...
🍎 [Apple Sign-In] Requesting Apple ID credential...
🍎 [Apple Sign-In] Got credential, extracting identity token...
🍎 [Apple Sign-In] User ID: 001234.abc123...
🍎 [Apple Sign-In] Email: user@privaterelay.appleid.com
🍎 [Apple Sign-In] Identity token length: 987
🍎 [Apple Sign-In] Creating OAuth credential...
🍎 [Apple Sign-In] Signing in to Firebase...
```

**إذا ظهر خطأ:**
```
❌ [Apple Sign-In] Firebase auth exception: invalid-credential
```

ده يعني المشكلة في **Firebase Console configuration** (Private Key أو Key ID)

---

## 📋 Checklist قبل التجربة

قبل ما تجرب Apple Sign-In على iPhone الحقيقي:

- [ ] تأكدت إن Private Key في Firebase Console مكتوب صح (مع BEGIN و END)
- [ ] تأكدت إن Key ID متطابق بين Apple Developer و Firebase Console
- [ ] تأكدت إن Service ID = `com.mored.mallawycare.signin`
- [ ] تأكدت إن Team ID = `84M47YB8XR`
- [ ] تأكدت إن Return URL = `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
- [ ] انتظرت 5-10 دقايق بعد أي تغييرات في Firebase Console
- [ ] التطبيق مبني من أحدث كود على GitHub (commit: latest)

---

## 🎯 الحل الأكثر احتمالاً

بناءً على الأعراض الحالية، **المشكلة الأساسية غالباً** هي:

**الـ Private Key (.p8) مكتوب بشكل غير صحيح في Firebase Console**

### الحل:

1. روح Apple Developer Console
2. اعمل **Key جديد** تماماً لـ Sign in with Apple
3. نزّل الـ `.p8` file
4. افتحه في text editor (Notepad++, VS Code, إلخ)
5. انسخ المحتوى **بالكامل** (كل حرف من أول `-----BEGIN` لآخر `-----END`)
6. في Firebase Console → Apple Sign-In:
   - حط الـ Key ID الجديد
   - امسح الـ Private Key القديم تماماً
   - الصق الـ Private Key الجديد
   - **تأكد مفيش مسافات زيادة قبل أو بعد**
   - Save
7. انتظر 5 دقايق
8. جرب Apple Sign-In

---

## 🔗 روابط مهمة

- **Firebase Console - Authentication**: https://console.firebase.google.com/project/clinicalsystem-4da35/authentication/providers
- **Apple Developer - Keys**: https://developer.apple.com/account/resources/authkeys/list
- **Apple Developer - Service IDs**: https://developer.apple.com/account/resources/identifiers/list/serviceId
- **Apple Developer - App IDs**: https://developer.apple.com/account/resources/identifiers/list

---

## 📱 متى تجرب مرة تانية؟

1. **بعد تحديث Private Key في Firebase**: انتظر 5-10 دقايق
2. **بعد تغييرات في Apple Developer Console**: انتظر 2-3 دقايق
3. **على iPhone حقيقي**: أفضل من Simulator (بعض الـ Simulators مش معاهم Apple ID)
4. **احذف التطبيق وأعد تثبيته**: علشان تمسح أي cache قديم

---

## ✅ ملاحظات إضافية

- Google Sign-In حالياً **يعاني من مشكلة Network connectivity** على Simulator - لازم اتصال إنترنت حقيقي
- Apple Sign-In **أسهل في الاختبار** على iPhone حقيقي
- الـ logging المحسّن هيساعدك تعرف بالظبط فين المشكلة

---

**آخر تحديث:** 13 يونيو 2026
