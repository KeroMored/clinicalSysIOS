# 🪟 دليل Deploy من Windows - خطوة بخطوة

## 📦 الملفات المطلوبة

انقل الـ **فولدرات والملفات دي** للويندوز:

```
✅ functions/               (الفولدر بكل محتوياته)
   ├── index.js
   ├── package.json
   └── package-lock.json

✅ .firebaserc             (ملف config)
✅ firebase.json           (ملف config)
```

---

## 🔍 طريقة النقل

### الطريقة 1: USB أو External Drive
1. انسخ الفولدرات والملفات فوق
2. حطهم على USB
3. افتح USB من Windows
4. انقل للـ Desktop أو أي مكان

### الطريقة 2: Git
```bash
# على الـ Mac، commit الملفات الجديدة
git add .firebaserc
git commit -m "Add Firebase config"
git push

# على الـ Windows
git pull
```

### الطريقة 3: Cloud Storage (Google Drive / Dropbox)
1. ارفع الفولدر للـ Cloud
2. حمله من Windows

---

## 🚀 خطوات الـ Deploy على Windows

### الخطوة 1: Install Node.js ⏱ (5 دقايق)

#### 1.1 Download Node.js
افتح المتصفح وروح:
```
https://nodejs.org/
```

#### 1.2 Download
- اضغط على الزرار الأخضر **Download for Windows**
- اختار **LTS version** (النسخة الموصى بها)
- حجم الملف: حوالي 30 MB

#### 1.3 Install
- شغّل الملف `.msi` اللي حملته
- اضغط **Next → Next → Next → Install**
- انتظر التثبيت (2-3 دقايق)
- اضغط **Finish**

#### 1.4 **أعد تشغيل الكمبيوتر** (مهم جداً!)

#### 1.5 تأكد من التثبيت
- افتح **Command Prompt**  
  (Start → اكتب `cmd` → Enter)
- اكتب:
```cmd
node --version
```
**المفروض يطلع:** `v20.xx.x` أو أي رقم

```cmd
npm --version
```
**المفروض يطلع:** `10.xx.x` أو أي رقم

**لو طلع "not recognized":**
- أعد تشغيل الكمبيوتر تاني
- أو أعد فتح Command Prompt

---

### الخطوة 2: Install Firebase CLI ⏱ (2 دقيقة)

#### 2.1 افتح Command Prompt كـ Administrator
- Right-click على **Start**
- اختار **Command Prompt (Admin)** أو **Terminal (Admin)**
- لو طلب تأكيد، اضغط **Yes**

#### 2.2 Install Firebase Tools
```cmd
npm install -g firebase-tools
```

**انتظر** (1-2 دقيقة) لحد ما يخلص

#### 2.3 تأكد من التثبيت
```cmd
firebase --version
```
**المفروض يطلع:** `13.xx.x` أو أي رقم

---

### الخطوة 3: Login to Firebase ⏱ (1 دقيقة)

```cmd
firebase login
```

**هيحصل إيه:**
1. هيسألك: `Allow Firebase to collect...?`  
   **اكتب:** `Y` ثم Enter

2. هيفتح المتصفح تلقائياً
3. اختار حساب Google: **kerolesmored@gmail.com**
4. اضغط **Allow** (السماح)
5. هيقولك **Success!** في المتصفح
6. ارجع للـ Command Prompt

**لو المتصفح مفتحش:**
```cmd
firebase login --no-localhost
```
ثم اتبع الرابط اللي هيظهر

---

### الخطوة 4: Navigate to Project ⏱ (10 ثانية)

```cmd
cd Desktop\clinicalSys-main
```

**أو حسب المكان اللي حطيت فيه المشروع:**
```cmd
cd C:\Users\YourName\Desktop\clinicalSys-main
```

**للتأكد إنك في المكان الصح:**
```cmd
dir
```
**لازم تشوف:**
- `functions` folder
- `firebase.json`
- `.firebaserc`

---

### الخطوة 5: Set Firebase Project ⏱ (5 ثانية)

```cmd
firebase use clinicalsystem-4da35
```

**المفروض يقولك:**
```
Now using project clinicalsystem-4da35
```

---

### الخطوة 6: Deploy Functions ⏱ (5-10 دقايق)

```cmd
firebase deploy --only functions
```

**هيحصل إيه:**
1. هيقولك: `Deploying functions...`
2. هيرفع الكود
3. هيعمل build للـ functions
4. **انتظر 5-10 دقايق**
5. لما يخلص، هيقولك: `✔ Deploy complete!`

**لو في أي errors:**
```cmd
firebase deploy --only functions --debug
```

---

### الخطوة 7: تأكد من النجاح ✅

```cmd
firebase functions:list
```

**لازم تشوف القائمة دي:**
```
✔ notifyClinicOnNewBooking
✔ notifyUsersOnNewOffer  
✔ notifyPharmaciesOnNewRequest
✔ notifyLabOnNewBooking
✔ notifyDoctorOnSecretaryAction
✔ sendGymNotificationToUsers
... (والباقي)
```

**لو شفت القائمة = تمام! Deploy نجح!** 🎉

---

## 🧪 اختبار الإشعارات

### Test 1: شوف الـ Logs
```cmd
firebase functions:log
```
هيظهر آخر 20 log entry

### Test 2: حجز عيادة
1. من التطبيق، احجز موعد أونلاين
2. شوف لو الدكتور وصله notification
3. لو وصل = شغال ✅

### Test 3: عرض صيدلية
1. من التطبيق، انزل عرض
2. شوف لو المستخدمين وصلهم
3. لو وصل = شغال ✅

---

## 🚨 مشاكل محتملة وحلولها

### ❌ Problem: "node is not recognized"
**الحل:**
1. أعد تشغيل Command Prompt
2. أعد تشغيل الكمبيوتر
3. تأكد إن Node.js installed

### ❌ Problem: "firebase is not recognized"
**الحل:**
```cmd
npm install -g firebase-tools
```

### ❌ Problem: "Permission denied"
**الحل:**
- افتح Command Prompt كـ **Administrator**
- Right-click على Start → Terminal (Admin)

### ❌ Problem: "Firebase project not found"
**الحل:**
```cmd
firebase use --add
```
اختار: `clinicalsystem-4da35`

### ❌ Problem: "Functions deploy failed"
**الحل:**
1. تأكد من internet connection
2. جرب تاني:
```cmd
firebase deploy --only functions --force
```

### ❌ Problem: ".firebaserc not found"
**الحل:**
تأكد إن الملف `.firebaserc` موجود في الفولدر

---

## 📋 Quick Commands Reference

```cmd
REM Check installations
node --version
npm --version
firebase --version

REM Login
firebase login

REM Navigate to project
cd Desktop\clinicalSys-main

REM Set project
firebase use clinicalsystem-4da35

REM Deploy
firebase deploy --only functions

REM Check deployed functions
firebase functions:list

REM View logs
firebase functions:log

REM Logout (if needed)
firebase logout
```

---

## 🎯 بعد Deploy الناجح

### الإشعارات هتشتغل تلقائياً لـ:
- ✅ **حجز عيادة أونلاين** → الدكتور يوصله notification
- ✅ **عرض صيدلية** → كل المستخدمين يوصلهم
- ✅ **طلب دواء** → كل الصيدليات يوصلهم
- ✅ **حجز معمل** → المعمل يوصله
- ✅ **إضافة/حذف حجز من السكرتيرة** → الدكتور يوصله

**مفيش حاجة تانية محتاج تعملها!** 🚀

---

## 📞 للمساعدة

إذا واجهت أي مشكلة:
1. تأكد من **internet connection**
2. **أعد تشغيل** Command Prompt
3. جرب الأوامر تاني
4. ابعت الـ **error message** بالضبط

---

## ⏱ الوقت المتوقع

| الخطوة | الوقت |
|--------|-------|
| Install Node.js | 5 دقايق |
| Install Firebase CLI | 2 دقيقة |
| Login | 1 دقيقة |
| Deploy Functions | 5-10 دقايق |
| **المجموع** | **13-18 دقيقة** |

---

## ✅ Checklist

قبل ما تبدأ، تأكد من:
- [ ] الملفات (functions/, .firebaserc, firebase.json) منقولة للويندوز
- [ ] Internet connection شغال
- [ ] عندك حساب Google (kerolesmored@gmail.com)

أثناء الـ Deploy:
- [ ] Node.js installed
- [ ] Firebase CLI installed
- [ ] Logged in to Firebase
- [ ] In correct project folder
- [ ] Project set to clinicalsystem-4da35
- [ ] Deploy command running

بعد الـ Deploy:
- [ ] `firebase functions:list` بيظهر الـ functions
- [ ] Test notification وصل
- [ ] Logs بتظهر في `firebase functions:log`

---

**ابدأ دلوقتي! كل الخطوات سهلة ومباشرة!** 🪟🚀
