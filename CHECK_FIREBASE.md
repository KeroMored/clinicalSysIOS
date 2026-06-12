# 🔍 Firebase Console Verification Checklist

## افتح Firebase Console الآن

### URL: https://console.firebase.google.com/project/clinicalsystem-4da35/authentication/providers

---

## ✅ Checklist - طبّق على كل نقطة

### 1️⃣ Google Sign-In Provider

```
[ ] Provider Status: ✅ Enabled (مفعّل)
[ ] Web Client ID: موجود (مش فاضي)
[ ] iOS Client ID in dropdown: 718616577077-1q7n6ub417t7naj1ufo1cb1ji3i88g5d
[ ] Bundle ID shown: com.mored.mallawycare
```

**إذا أي نقطة ❌ مش صح**:
- اضغط Edit على Google provider
- تأكد Status = Enabled
- احفظ (Save)

---

### 2️⃣ Apple Sign-In Provider

```
[ ] Provider Status: ✅ Enabled (مفعّل)
[ ] Service ID: com.mored.mallawycare.signin
[ ] Team ID: 84M47YB8XR
[ ] Key ID: موجود (أرقام وحروف مثل: ABC123XYZ9)
[ ] Private Key: موجود (يبدأ بـ -----BEGIN PRIVATE KEY-----)
```

**إذا أي نقطة ❌ مش صح**:

#### 🔧 إصلاح Service ID:
1. اذهب لـ https://developer.apple.com/account/resources/identifiers
2. اضغط **+** → **Services IDs**
3. Description: `Mallawy Care Sign In`
4. Identifier: `com.mored.mallawycare.signin`
5. فعّل **Sign In with Apple** → Configure:
   - Primary App ID: اختر `com.mored.mallawycare`
   - Domain: `clinicalsystem-4da35.firebaseapp.com`
   - Return URL: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`
6. Save → Continue → Register

#### 🔧 إصلاح Key:
1. اذهب لـ https://developer.apple.com/account/resources/authkeys
2. اضغط **+** لإنشاء Key جديد
3. Key Name: `Apple Sign In Key`
4. فعّل **Sign In with Apple** → Configure:
   - Primary App ID: اختر `com.mored.mallawycare`
5. Continue → Register
6. **حمّل الملف `.p8`** (مهم جداً!)
7. انسخ **Key ID** (مثال: ABC123XYZ9)
8. افتح ملف `.p8` بـ TextEdit وانسخ كل محتواه

#### 🔧 تحديث Firebase:
1. ارجع لـ Firebase Console
2. Authentication → Sign-in method → Apple → Edit
3. Service ID: `com.mored.mallawycare.signin`
4. Team ID: `84M47YB8XR`
5. Key ID: [الصق Key ID من Apple Developer]
6. Private Key: [الصق محتوى ملف .p8 كامل]
7. Save

---

## 3️⃣ App Registration في Firebase

اذهب لـ: Project Settings → Your Apps

```
[ ] iOS App Bundle ID: com.mored.mallawycare
[ ] App Nickname: أي اسم (مثال: Mallawy Care iOS)
[ ] GoogleService-Info.plist: Downloaded ✅
```

---

## ⚡ After Verification

إذا عملت أي تغيير في Firebase Console:

1. انتظر **1-2 دقيقة** (Firebase ياخد وقت للتحديث)
2. احذف التطبيق من الجهاز نهائياً
3. أعد بناء التطبيق:
```bash
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run --release
```

---

## 🚨 Common Issues

### "Service ID not found"
❌ Service ID في Firebase مختلف عن Apple Developer
✅ يجب يكون: `com.mored.mallawycare.signin`

### "Invalid Key"
❌ Private Key مش منسوخ صح أو Key مش مفعّل لـ App ID الصحيح
✅ حمّل Key جديد من Apple Developer وانسخه كامل (مع BEGIN و END)

### "Domain not verified"
❌ Domain في Service ID Configuration مش صحيح
✅ يجب يكون: `clinicalsystem-4da35.firebaseapp.com`

### "Redirect URI mismatch"
❌ Return URL مش صحيح
✅ يجب يكون: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`

---

## 📸 Screenshot Required

إذا لم تحل المشكلة بعد كل ده، خذ screenshots لـ:

1. Firebase Console → Authentication → Sign-in method (الصفحة الرئيسية اللي فيها كل Providers)
2. Firebase Console → Authentication → Sign-in method → Apple (فتح إعدادات Apple)
3. Firebase Console → Authentication → Sign-in method → Google (فتح إعدادات Google)
4. Apple Developer → Identifiers → Services IDs → com.mored.mallawycare.signin
5. Apple Developer → Keys → Apple Sign In Key

وابعتهم لي.
