# ⚠️ تحقق من Firebase - المشكلة ما زالت موجودة!

## 🔴 المشكلة

الملف الذي أضفته (`GoogleService-Info.plist`) **ما زال يحتوي على نفس CLIENT_ID القديم**!

### ما الموجود الآن:
```xml
<key>CLIENT_ID</key>
<string>718616577077-1q7n6ub417t7naj1ufo1cb1ji3i88g5d.apps.googleusercontent.com</string>

<key>BUNDLE_ID</key>
<string>com.mored.mallawycare</string>  ✅ صح
```

**المشكلة**: هذا الـ CLIENT_ID **للـ Bundle ID القديم**!

---

## 🔍 التحقق من Firebase

### الخطوة 1: افتح Firebase Console
```
https://console.firebase.google.com/project/clinicalsystem-4da35/settings/general
```

### الخطوة 2: شوف في قسم "Your apps"

**يجب أن تجد** iOS apps بهذا الشكل:

```
📱 iOS
Bundle ID: com.example.clinicalsystem
Client ID: 718616577077-xxxxx... (قديم)
Status: Active

📱 iOS  
Bundle ID: com.mored.mallawycare
Client ID: 718616577077-yyyyy... (جديد - مختلف!)
Status: Active
```

---

## ❓ ماذا تجد في Firebase؟

### السيناريو 1: لا يوجد iOS app بـ `com.mored.mallawycare`

**المطلوب**: يجب إضافة التطبيق!

1. **اضغط "Add app"** أو زر **➕**
2. **اختر iOS**
3. **املأ**:
   ```
   iOS bundle ID: com.mored.mallawycare
   App nickname: Mallawy Care iOS
   App Store ID: 6779004261
   ```
4. **اضغط Register app**
5. **نزّل `GoogleService-Info.plist`** الجديد
6. **استبدل** الملف في `ios/Runner/GoogleService-Info.plist`
7. **CLIENT_ID الجديد سيكون مختلف!**

---

### السيناريو 2: يوجد iOS app بـ `com.mored.mallawycare` لكن CLIENT_ID نفسه

**هذا غريب!** عادةً كل Bundle ID له CLIENT_ID مختلف.

**جرّب**:
1. اضغط على التطبيق في Firebase
2. اضغط على زر "GoogleService-Info.plist" مرة أخرى
3. نزّل الملف
4. افتحه وشوف الـ CLIENT_ID

---

### السيناريو 3: يوجد iOS app لكن نزّلت ملف التطبيق الخطأ

**المشكلة**: ربما نزّلت ملف التطبيق القديم (`com.example.clinicalsystem`) بدلاً من الجديد!

**الحل**:
1. في Firebase Console، تأكد إنك ضاغط على التطبيق الصحيح
2. Bundle ID يجب أن يكون: `com.mored.mallawycare`
3. نزّل `GoogleService-Info.plist` من **هذا التطبيق بالضبط**

---

## 🧪 كيف تتأكد؟

### في Firebase Console:

افتح التطبيق iOS بـ `com.mored.mallawycare` وشوف:

```
iOS Client ID: 
718616577077-[هنا يجب أن يكون شيء مختلف عن 1q7n6ub417t7naj1ufo1cb1ji3i88g5d]
```

**إذا كان نفس الشيء**: هذا غير طبيعي!

---

## 💡 الحل البديل (مؤقت)

إذا Firebase ما أعطاك CLIENT_ID جديد، **ممكن** نجرب حل مؤقت:

### في Firebase Console → Authentication → Sign-in method → Google:

تأكد من:
1. Google provider **مفعّل** ✅
2. **iOS Client IDs** يحتوي على:
   ```
   718616577077-1q7n6ub417t7naj1ufo1cb1ji3i88g5d
   ```
3. جرّب إضافة iOS app في قسم **"Web SDK configuration"** أسفل الصفحة

---

## 📸 أرسل لي Screenshots

لو ممكن، أرسل Screenshots من:

1. **Firebase Console → Your apps** (قسم iOS apps)
2. **التطبيق iOS بـ Bundle ID: com.mored.mallawycare**
3. **محتوى GoogleService-Info.plist** (خصوصاً CLIENT_ID)

هذا سيساعدني أحدد المشكلة بالضبط!

---

## ⚠️ ملاحظة مهمة

الـ CLIENT_ID الحالي (`718616577077-1q7n6ub417t7naj1ufo1cb1ji3i88g5d`) هو **نفسه** اللي كان موجود قبل ما تضيف الملف الجديد!

**هذا يعني**:
- إما لم يتم إضافة iOS app جديد في Firebase
- أو تم تنزيل ملف التطبيق الخطأ
- أو Firebase Console به مشكلة (نادر جداً)

---

## 🔧 في الوقت الحالي

الملفات الحالية **متطابقة** - Info.plist و GoogleService-Info.plist يحتويان على نفس CLIENT_ID.

**لكن** هذا لن يحل مشكلة Google Sign-In crash لأن الـ CLIENT_ID ما زال للـ Bundle ID القديم!

---

## 🎯 الخطوات التالية

1. **راجع Firebase Console** - تأكد من وجود iOS app بـ `com.mored.mallawycare`
2. **نزّل الملف الصحيح** من التطبيق الصحيح
3. **تحقق من CLIENT_ID** - يجب أن يكون مختلف!
4. **أرسل Screenshots** إذا ما زالت المشكلة

---

**التاريخ**: 12 يونيو 2026  
**الحالة**: ⏳ ينتظر التحقق من Firebase  
**المشكلة**: CLIENT_ID لم يتغير
