# إعداد Google Sign In - دليل الإصلاح

## 🔴 المشكلة الحالية

تسجيل الدخول بـ Google لا يعمل لأن التطبيق غير مسجل في Firebase Console بشكل صحيح.

## ✅ الحل: إضافة SHA-1 Certificate Fingerprint

### الخطوة 1️⃣: الحصول على SHA-1 Fingerprint

✅ **تم الحصول على SHA-1 بالفعل!**

**SHA-1 لهذا التطبيق:**

```
B4:79:86:0C:A8:86:B8:88:5C:62:67:2D:67:8D:EA:C4:AC:83:D9:2A
```

**انسخ هذا الـ SHA-1 واستخدمه في الخطوة التالية ⬇️**

---

<details>
<summary>📚 كيف حصلنا على SHA-1؟ (للمعرفة فقط)</summary>

تم استخدام الأمر التالي:

```powershell
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

</details>

---

### الخطوة 2️⃣: إضافة SHA-1 إلى Firebase Console

1. افتح [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك: **clinicalsystem-4da35**
3. اضغط على ⚙️ (Settings) بجانب "Project Overview"
4. اختر **Project settings**
5. انزل للأسفل إلى قسم **Your apps**
6. ستجد التطبيق Android بـ package name: `com.example.clinicalsystem`
7. اضغط على التطبيق
8. ستجد قسم **SHA certificate fingerprints**
9. اضغط **Add fingerprint**
10. الصق قيمة SHA-1 التي نسختها من Terminal
11. اضغط **Save**

---

### الخطوة 3️⃣: تفعيل Google Sign-In Provider

1. في Firebase Console، اذهب إلى **Authentication**
2. اضغط على **Sign-in method** (طرق تسجيل الدخول)
3. ستجد قائمة بالـ Providers
4. ابحث عن **Google**
5. اضغط عليه
6. فعّل زر **Enable** (تفعيل)
7. اختر **Support email** (بريدك الإلكتروني)
8. اضغط **Save**

---

### الخطوة 4️⃣: تحميل google-services.json الجديد

بعد إضافة SHA-1 وتفعيل Google Sign-In:

1. في Firebase Console → Project settings → Your apps
2. اضغط على زر **Download google-services.json**
3. استبدل الملف القديم بالجديد في المسار:

   ```
   android/app/google-services.json
   ```

الملف الجديد سيحتوي على:

```json
{
  "oauth_client": [
    {
      "client_id": "718616577077-xxxxxxxxxx.apps.googleusercontent.com",
      "client_type": 1,
      "android_info": {
        "package_name": "com.example.clinicalsystem",
        "certificate_hash": "xxxxxxxxxxxxxxxx"
      }
    },
    {
      "client_id": "718616577077-xxxxxxxxxx.apps.googleusercontent.com",
      "client_type": 3
    }
  ]
}
```

**⚠️ ملاحظة مهمة:** الملف الحالي فيه `"oauth_client": []` فارغ، وهذا سبب المشكلة!

---

### الخطوة 5️⃣: إعادة بناء التطبيق

بعد استبدال google-services.json:

```powershell
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

---

## 🎯 اختبار تسجيل الدخول

1. افتح التطبيق
2. اضغط على **تسجيل الدخول**
3. اضغط **تسجيل الدخول بواسطة Google**
4. ستفتح نافذة اختيار حساب Google
5. اختر حسابك
6. سيتم تسجيل دخولك بنجاح ✅

---

## 🐛 استكشاف الأخطاء الشائعة

### مشكلة: "PlatformException: sign_in_failed"

**الحل:** SHA-1 غير مضاف أو خاطئ

- تأكد من إضافة SHA-1 الصحيح في Firebase
- تأكد من تحميل google-services.json الجديد

### مشكلة: "GoogleSignIn 10: Developer Error"

**الحل:** oauth_client فارغ في google-services.json

- قم بتحميل الملف الجديد من Firebase Console بعد إضافة SHA-1

### مشكلة: التطبيق يفتح متصفح بدل نافذة اختيار الحساب

**الحل:** تأكد من تثبيت Google Play Services على المحاكي/الجهاز

### مشكلة: "Network error"

**الحل:** تأكد من الاتصال بالإنترنت وأن Firebase API مفعلة

---

## 📝 ملاحظات إضافية

### للنشر (Production)

عند نشر التطبيق، ستحتاج أيضاً إلى:

1. الحصول على SHA-1 للـ Release keystore
2. إضافته في Firebase Console
3. تحميل google-services.json جديد

للحصول على Release SHA-1:

```powershell
keytool -list -v -keystore your_release.keystore -alias your_key_alias
```

### لـ iOS

إذا كنت ستدعم iOS لاحقاً:

1. أضف GoogleService-Info.plist في `ios/Runner/`
2. أضف URL Scheme في Info.plist
3. أضف OAuth client ID في Firebase

---

## ✨ خلاصة سريعة

1. ✅ احصل على SHA-1: `cd android && ./gradlew signingReport`
2. ✅ أضف SHA-1 في Firebase Console → Project Settings → Your apps
3. ✅ فعّل Google Sign-In في Authentication → Sign-in method
4. ✅ حمّل google-services.json الجديد واستبدله
5. ✅ نظف المشروع: `flutter clean && flutter pub get`
6. ✅ شغّل التطبيق: `flutter run`

بعد هذه الخطوات، تسجيل الدخول بـ Google سيعمل بشكل مثالي! 🎉
