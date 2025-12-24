# 🔧 إصلاح تسجيل الدخول بـ Google - خطوات سريعة

## 🔴 المشكلة
تسجيل الدخول بـ Google لا يعمل لأن `google-services.json` فيه:
```json
"oauth_client": []  ❌ فارغ!
```

## ✅ الحل السريع (5 دقائق)

### 1️⃣ افتح Firebase Console
🔗 [https://console.firebase.google.com/](https://console.firebase.google.com/)

- اختر مشروع: **clinicalsystem-4da35**

---

### 2️⃣ أضف SHA-1 Certificate

1. اضغط ⚙️ (Settings) → **Project settings**
2. انزل لقسم **Your apps**
3. اختر التطبيق Android: `com.example.clinicalsystem`
4. في قسم **SHA certificate fingerprints**
5. اضغط **Add fingerprint**
6. الصق هذا SHA-1:

```
B4:79:86:0C:A8:86:B8:88:5C:62:67:2D:67:8D:EA:C4:AC:83:D9:2A
```

7. اضغط **Save**

---

### 3️⃣ فعّل Google Sign-In

1. في القائمة الجانبية، اختر **Authentication**
2. اضغط **Sign-in method**
3. ابحث عن **Google**
4. اضغط عليه
5. فعّل زر **Enable** ✅
6. اختر Support email (بريدك)
7. اضغط **Save**

---

### 4️⃣ حمّل google-services.json الجديد

1. ارجع لـ **Project settings** → **Your apps**
2. اضغط **Download google-services.json**
3. استبدل الملف القديم في:
   ```
   android/app/google-services.json
   ```

**⚠️ مهم جداً:** الملف الجديد لازم يكون فيه `oauth_client` مليان!

---

### 5️⃣ نظّف وشغّل التطبيق

في Terminal:
```powershell
flutter clean
flutter pub get
flutter run
```

---

## 🎉 انتهى!

الآن تسجيل الدخول بـ Google سيعمل بشكل مثالي!

---

## 📸 كيف تتأكد أن كل شيء صح؟

بعد ما تحمّل `google-services.json` الجديد:

1. افتح الملف
2. ابحث عن `"oauth_client"`
3. لازم تلاقي حاجة زي كده:

```json
"oauth_client": [
  {
    "client_id": "718616577077-xxxxxxxxxx.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.clinicalsystem",
      "certificate_hash": "b479860ca886b8885c62672d678deac4ac83d92a"
    }
  },
  {
    "client_id": "718616577077-xxxxxxxxxx.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

✅ لو فيه حاجة داخل `oauth_client` يبقى تمام!  
❌ لو فاضي `[]` يبقى ما حمّلتش الملف الجديد بعد إضافة SHA-1!

---

## 🆘 لو ما زال مش شغال

تأكد إنك:
- ✅ أضفت SHA-1 الصحيح
- ✅ فعّلت Google Sign-In في Authentication
- ✅ حمّلت google-services.json **بعد** إضافة SHA-1
- ✅ استبدلت الملف القديم بالجديد في `android/app/`
- ✅ عملت `flutter clean && flutter pub get`

---

**💡 ملحوظة:** لو عايز تفاصيل أكتر، افتح ملف `GOOGLE_SIGNIN_SETUP.md`
