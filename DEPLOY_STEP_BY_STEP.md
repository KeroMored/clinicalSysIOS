# خطوات رفع Cloud Functions من الويندوز

## 📋 قبل ما تبدأ - جهز الملفات:

### الملفات المطلوبة:
انسخ المجلدات والملفات دي من الماك للويندوز (كلها موجودة في مجلد `clinicalSys-main`):

```
📁 clinicalSys-deploy/          ← اعمل المجلد ده على الويندوز
├── 📁 functions/               ← انسخ المجلد كله بكل محتوياته
│   ├── index.js
│   ├── package.json
│   └── package-lock.json
├── .firebaserc                ← انسخ الملف ده
└── firebase.json              ← انسخ الملف ده
```

---

## 🪟 الخطوات على الويندوز:

### الخطوة 1: ثبت Node.js

1. روح على: https://nodejs.org/
2. حمل **LTS Version** (النسخة الموصى بها)
3. ثبته عادي (Next → Next → Install)
4. افتح **Command Prompt** وتأكد بالأمر ده:
```bash
node --version
npm --version
```
لازم يطلع أرقام الإصدار

---

### الخطوة 2: ثبت Firebase CLI

افتح **Command Prompt** كـ **Administrator** واكتب:
```bash
npm install -g firebase-tools
```

انتظر لحد ما التثبيت يخلص (ممكن ياخد 2-3 دقايق)

تأكد إنه اتثبت:
```bash
firebase --version
```

---

### الخطوة 3: سجل دخول Firebase

```bash
firebase login
```
هيفتح المتصفح - سجل دخول بحساب Firebase بتاعك

---

### الخطوة 4: ارفع الـ Functions

1. افتح **Command Prompt** 
2. روح للمجلد اللي نسخت فيه الملفات:
```bash
cd C:\Users\YourName\Desktop\clinicalSys-deploy
```
(غير المسار حسب مكان المجلد عندك)

3. تأكد من المشروع:
```bash
firebase use clinicalsystem-4da35
```

4. ارفع الـ Functions:
```bash
firebase deploy --only functions
```

---

### الخطوة 5: انتظر الرفع

هتشوف رسائل زي دي:
```
⚙️  functions: preparing functions for deployment...
✔  functions: functions deployed successfully!

Functions:
  notifyClinicOnNewBooking(us-central1)
  notifyUsersOnNewOffer(us-central1)
  notifyPharmaciesOnNewRequest(us-central1)
  ...
```

---

## ✅ التأكد من النجاح:

### 1. افتح Firebase Console:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/functions
```

### 2. لازم تشوف الـ Functions دي:
- ✅ `notifyClinicOnNewBooking` - إشعار للعيادة عند حجز جديد
- ✅ `notifyUsersOnNewOffer` - إشعار للمستخدمين عند عرض جديد
- ✅ `notifyPharmaciesOnNewRequest` - إشعار للصيدليات عند طلب دواء
- ✅ `notifyLabOnNewBooking` - إشعار للمعمل عند حجز جديد
- ✅ `notifyUserOnBookingStatusChange` - إشعار للمستخدم عند تغيير حالة الحجز
- ✅ `notifyUserOnOfferExpiry` - إشعار للمستخدم عند انتهاء عرض
- ✅ `notifyAdminOnNewPharmacyRequest` - إشعار للأدمن عند طلب صيدلية جديد

---

## 🎯 بعد الرفع الناجح:

### الإشعارات هتشتغل تلقائياً:

1. **حجز أونلاين** → العيادة تستلم إشعار فوراً
2. **عرض جديد من صيدلية** → كل المستخدمين يستلموا إشعار
3. **طلب دواء** → الصيدليات تستلم إشعار
4. **حجز معمل** → المعمل يستلم إشعار

---

## ⚠️ مشاكل شائعة:

### مشكلة: "firebase: command not found"
**الحل**: اقفل Command Prompt وافتحه تاني بعد تثبيت Firebase CLI

### مشكلة: "Permission denied"
**الحل**: افتح Command Prompt كـ Administrator

### مشكلة: "Project not found"
**الحل**: تأكد إنك مسجل دخول بالحساب الصح:
```bash
firebase logout
firebase login
```

### مشكلة: "Functions deployment failed"
**الحل**: تأكد إن ملف `package.json` موجود في مجلد `functions`

---

## 📞 اختبار الإشعارات:

بعد الرفع الناجح:

1. **افتح التطبيق على iOS**
2. **احجز موعد أونلاين** في عيادة
3. **تأكد إن العيادة استلمت إشعار**
4. **انزل عرض من صيدلية**
5. **تأكد إن المستخدمين استلموا إشعار**

---

## ✨ ملخص:

| الخطوة | الأمر | الحالة |
|--------|-------|--------|
| 1 | ثبت Node.js | ⬜ |
| 2 | `npm install -g firebase-tools` | ⬜ |
| 3 | `firebase login` | ⬜ |
| 4 | `firebase use clinicalsystem-4da35` | ⬜ |
| 5 | `firebase deploy --only functions` | ⬜ |
| 6 | افتح Firebase Console للتأكد | ⬜ |

---

**بعد ما تخلص، ارجع قولي: "الـ Functions اترفعت" عشان نختبر الإشعارات!**
