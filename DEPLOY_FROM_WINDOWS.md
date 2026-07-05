# 🪟 Deploy Firebase Functions من Windows

## الملفات المطلوبة

انقل الفولدر ده كله للويندوز:
```
functions/
├── index.js          (الـ Cloud Functions)
├── package.json      (Dependencies)
└── package-lock.json
```

وكمان انقل:
```
.firebaserc           (Project config)
firebase.json         (Firebase config)
```

---

## 🚀 الخطوات على Windows

### 1️⃣ Install Node.js

#### Download:
```
https://nodejs.org/
```
- حمّل **LTS version** (النسخة الموصى بها)
- شغّل الملف `.exe`
- اضغط Next → Next → Install
- **أعد تشغيل الكمبيوتر**

#### تأكد من التثبيت:
افتح **Command Prompt** واكتب:
```cmd
node --version
npm --version
```

---

### 2️⃣ Install Firebase CLI

افتح **Command Prompt** (كـ Administrator):
```cmd
npm install -g firebase-tools
```

**لو طلع error "permission denied":**
- Right-click على Command Prompt
- اختار **Run as administrator**
- جرب تاني

---

### 3️⃣ Login to Firebase

```cmd
firebase login
```
- هيفتح المتصفح
- سجل دخول بـ Google (kerolesmored@gmail.com)
- اضغط Allow

---

### 4️⃣ Navigate to Project

```cmd
cd C:\path\to\your\project
```

**مثال:**
```cmd
cd C:\Users\YourName\Desktop\clinicalSys-main
```

---

### 5️⃣ Set Firebase Project

```cmd
firebase use clinicalsystem-4da35
```

---

### 6️⃣ Deploy Functions

```cmd
firebase deploy --only functions
```

**هياخد 5-10 دقايق** ⏱

---

## 📁 هيكل المشروع المطلوب على Windows

```
C:\YourFolder\clinicalSys-main\
├── .firebaserc
├── firebase.json
└── functions\
    ├── index.js
    ├── package.json
    └── package-lock.json
```

---

## ✅ بعد الـ Deploy

### تأكد من النجاح:
```cmd
firebase functions:list
```

**لازم تشوف:**
- ✅ notifyClinicOnNewBooking
- ✅ notifyUsersOnNewOffer
- ✅ notifyPharmaciesOnNewRequest
- ✅ notifyLabOnNewBooking

---

## 🔍 شوف الـ Logs

```cmd
firebase functions:log
```

---

## 🚨 مشاكل شائعة وحلولها

### Problem 1: "node is not recognized"
**الحل:**
- أعد تشغيل Command Prompt
- أو أعد تشغيل الكمبيوتر

### Problem 2: "npm: command not found"
**الحل:**
- تأكد إن Node.js installed صح
- افتح Control Panel → Programs → تأكد من وجود Node.js

### Problem 3: "Permission denied"
**الحل:**
- افتح Command Prompt كـ **Administrator**
- Right-click → Run as administrator

### Problem 4: "Firebase project not found"
**الحل:**
```cmd
firebase use --add
# اختار: clinicalsystem-4da35
```

---

## 📋 الأوامر كاملة بالترتيب

```cmd
REM 1. تأكد من Node
node --version

REM 2. Install Firebase CLI
npm install -g firebase-tools

REM 3. Login
firebase login

REM 4. Navigate to project
cd C:\path\to\clinicalSys-main

REM 5. Set project
firebase use clinicalsystem-4da35

REM 6. Deploy
firebase deploy --only functions

REM 7. تأكد من Deploy
firebase functions:list

REM 8. شوف الـ logs
firebase functions:log
```

---

## 🎯 النتيجة النهائية

بعد الـ Deploy الناجح:
- ✅ حجز عيادة → الدكتور يوصله notification
- ✅ عرض صيدلية → كل الناس يوصلهم
- ✅ طلب دواء → الصيدليات يوصلهم
- ✅ حجز معمل → المعمل يوصله

**كل ده هيشتغل تلقائياً بدون أي كود إضافي!** 🚀

---

## 💾 Backup للملفات المهمة

قبل ما تنقل، تأكد من نسخ الملفات دي:

### في المشروع الرئيسي:
- `functions/index.js` ← **الأهم**
- `functions/package.json`
- `.firebaserc`
- `firebase.json`

---

## 📞 للمساعدة

إذا واجهت مشكلة أثناء الـ Deploy:
1. تأكد من internet connection
2. تأكد إنك logged in: `firebase login:list`
3. شوف الـ error message وابعته
4. جرب مرة تانية: `firebase deploy --only functions --debug`

---

**انقل الملفات دي للويندوز وابدأ Deploy!** 🪟
