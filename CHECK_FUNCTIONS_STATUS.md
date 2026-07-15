# إزاي تتأكد إن الـ Cloud Functions اترفعت

## 📍 الخطوة 1: افتح Firebase Console

روح على الرابط ده:
```
https://console.firebase.google.com/project/clinicalsystem-4da35/functions
```

---

## ✅ لو الـ Functions اترفعت بنجاح:

هتشوف **7 Functions** في القايمة:

| رقم | اسم الـ Function | الوظيفة |
|-----|-----------------|---------|
| 1️⃣ | `notifyClinicOnNewBooking` | إشعار العيادة عند حجز أونلاين جديد |
| 2️⃣ | `notifyUsersOnNewOffer` | إشعار المستخدمين عند عرض صيدلية جديد |
| 3️⃣ | `notifyPharmaciesOnNewRequest` | إشعار الصيدليات عند طلب دواء |
| 4️⃣ | `notifyLabOnNewBooking` | إشعار المعمل عند حجز تحليل أونلاين |
| 5️⃣ | `sendLabNotificationToUsers` | إشعارات المعامل للمستخدمين |
| 6️⃣ | `sendClinicNotificationToUsers` | إشعارات العيادات للمستخدمين |
| 7️⃣ | `sendGymNotificationToUsers` | إشعارات الجيمات للمستخدمين |

**وممكن تلاقي functions إضافية:**
- `notifyDoctorOnSecretaryAction` - إشعار الدكتور عند إضافة/حذف حجز من السكرتارية
- `notifyPharmaciesOnNearExpireItem` - إشعار الصيدليات بأدوية قاربت تنتهي
- `processPendingNotifications` - معالجة الإشعارات المعلقة
- `sendTestNotification` - إرسال إشعار تجريبي
- `cleanupOldRequests` - تنظيف الطلبات القديمة

**كل function** هيكون عليها:
- ✅ علامة خضراء (Active)
- 📍 Region: `us-central1`
- ⚡ Trigger: `Firestore Document Created`

---

## ❌ لو الـ Functions **مترفعتش**:

هتلاقي واحدة من دي:

### 1. الصفحة فاضية تماماً
```
No functions deployed yet
Get started by deploying your first function
```
**معنى ده:** مفيش أي functions اترفعت خالص

### 2. مفيش الـ Functions اللي فوق
لو لقيت functions تانية بس مش الـ 7 اللي فوق، يبقى الرفع مكملش

---

## 🎯 لو مترفعتش - ارفعها من الويندوز:

### الملفات اللي تنقلها:

انسخ المجلدات دي من الماك للويندوز (USB أو Google Drive أو AirDrop):

```
من مجلد: /Users/georgesadek/Downloads/clinicalSys-main/

انسخ:
├── 📁 functions/              ← المجلد الكامل (بكل الملفات جواه)
├── 📄 .firebaserc            ← ملف التكوين
└── 📄 firebase.json          ← ملف الإعدادات
```

**مهم جداً:** 
- انسخ مجلد `functions` **كامل** مع كل الملفات اللي جواه
- لا تنسخ فقط ملف `index.js`، انسخ **المجلد كله**

---

## 🪟 على الويندوز:

### 1. اعمل مجلد جديد:
```
C:\Users\YourName\Desktop\clinicalSys-deploy\
```

### 2. حط فيه الـ 3 حاجات اللي نسختهم:
```
C:\Users\YourName\Desktop\clinicalSys-deploy\
├── functions/        ← المجلد
├── .firebaserc      ← الملف
└── firebase.json    ← الملف
```

### 3. ثبت Node.js:
- حمل من: https://nodejs.org/
- اختار **LTS Version** (مثلاً: 20.x.x)
- ثبته عادي

### 4. ثبت Firebase CLI:
افتح **Command Prompt** كـ **Administrator**:
```bash
npm install -g firebase-tools
```

### 5. سجل دخول:
```bash
firebase login
```

### 6. روح للمجلد:
```bash
cd C:\Users\YourName\Desktop\clinicalSys-deploy
```

### 7. تأكد من المشروع:
```bash
firebase use clinicalsystem-4da35
```

### 8. ارفع:
```bash
firebase deploy --only functions
```

انتظر من **5-10 دقايق**، هتشوف:
```
✔  functions: functions deployed successfully!

Functions:
  notifyClinicOnNewBooking(us-central1)
  notifyUsersOnNewOffer(us-central1)
  notifyPharmaciesOnNewRequest(us-central1)
  notifyLabOnNewBooking(us-central1)
  ...
```

---

## 📱 بعد الرفع - اختبر الإشعارات:

### اختبار 1: حجز أونلاين في عيادة
1. افتح التطبيق على iOS
2. احجز موعد في أي عيادة (اختار "حجز أونلاين")
3. **المفروض:** العيادة تستلم إشعار خلال **ثواني**
4. **شوف الإشعار في:** جهاز الدكتور أو الموظف المسجل في العيادة

### اختبار 2: عرض من صيدلية
1. سجل دخول كـ **صيدلية** في التطبيق
2. انزل **عرض جديد** (أضف صورة + وصف)
3. **المفروض:** كل المستخدمين يستلموا إشعار
4. **شوف الإشعار في:** أي جهاز مستخدم عادي

### اختبار 3: طلب دواء
1. سجل دخول كـ **مستخدم عادي**
2. اطلب **دواء** من الصيدليات
3. **المفروض:** كل الصيدليات تستلم إشعار
4. **شوف الإشعار في:** جهاز صيدلية

---

## 🔧 حل المشاكل:

### المشكلة: "firebase: command not found"
**الحل:**
1. اقفل Command Prompt
2. افتحه تاني
3. جرب: `firebase --version`

### المشكلة: "Permission denied"
**الحل:**
- افتح Command Prompt كـ **Administrator**
- (كليك يمين → Run as Administrator)

### المشكلة: "Project not found"
**الحل:**
```bash
firebase logout
firebase login
firebase use clinicalsystem-4da35
```

### المشكلة: "Functions deployment failed"
**الحل:**
1. تأكد إن مجلد `functions` موجود
2. تأكد إن جوا `functions` فيه:
   - `index.js`
   - `package.json`
   - `package-lock.json`

---

## 📊 ملخص سريع:

| الخطوة | الحالة |
|--------|--------|
| نسخت مجلد `functions` للويندوز | ⬜ |
| نسخت `.firebaserc` للويندوز | ⬜ |
| نسخت `firebase.json` للويندوز | ⬜ |
| ثبت Node.js | ⬜ |
| ثبت Firebase CLI | ⬜ |
| عملت `firebase login` | ⬜ |
| رفعت الـ Functions | ⬜ |
| شفت الـ Functions في Console | ⬜ |
| جربت الإشعارات | ⬜ |

---

## 🎉 لما تخلص:

ارجع قولي: **"الـ Functions اترفعت"** وابعتلي screenshot من صفحة Functions في Firebase Console عشان أتأكد معاك!
