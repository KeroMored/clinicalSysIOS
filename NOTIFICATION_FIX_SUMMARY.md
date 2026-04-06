# إصلاح نظام الإشعارات

## المشكلة الأساسية
الإشعارات لا تعمل نهائياً:
- ❌ إضافة عروض الصيدليات → لا تصل للمستخدمين
- ❌ طلبات الأدوية → لا تصل للصيدليات

## التشخيص

### 1. فحص Cloud Functions
```powershell
firebase functions:list
# ✅ Functions موجودة ومنشورة
```

### 2. فحص Logs
```powershell
firebase functions:log --only notifyPharmaciesOnNewRequest
```

**النتيجة**: 
```
Error sending notification: TypeError: Cannot read properties of undefined (reading 'toString')
at /workspace/index.js:48:42
```

### 3. تحليل المشكلة

**Cloud Function كانت تتوقع**:
```javascript
{
  medicineName: string,
  quantity: number,
  phoneNumber: string,
  ...
}
```

**لكن App يرسل**:
```dart
{
  medicines: [
    { medicineName: '...', quantity: '...', imageUrl: '...' },
    { medicineName: '...', quantity: '...', imageUrl: '...' }
  ],
  phoneNumber: string,
  ...
}
```

## الحل المطبق

### 1. تعديل Cloud Function
**ملف**: `functions/index.js` - السطر 32-60

**التغيير**:
```javascript
// ❌ القديم - خطأ
body: `${requestData.userName} يطلب ${requestData.medicineName} - الكمية: ${requestData.quantity} علبة`,
quantity: requestData.quantity.toString(), // undefined!

// ✅ الجديد - صحيح
const firstMedicine = requestData.medicines && requestData.medicines.length > 0 
  ? requestData.medicines[0] 
  : null;
const medicineNames = requestData.medicines && requestData.medicines.length > 0
  ? requestData.medicines.map(m => m.medicineName || m.medicine_name || 'دواء').join(', ')
  : 'أدوية';
const totalMedicines = requestData.medicines ? requestData.medicines.length : 0;

body: totalMedicines > 1 
  ? `${requestData.userName} يطلب ${totalMedicines} أدوية`
  : `${requestData.userName} يطلب ${medicineNames}`,
totalMedicines: totalMedicines.toString(),
medicineNames: medicineNames,
```

### 2. نشر التحديثات
```powershell
cd functions
firebase deploy --only functions
```

**الحالة**: ✅ اكتمل النشر بنجاح!

**النتيجة**:
```
✅ functions[notifyPharmaciesOnNewRequest(us-central1)] Successful update operation.
✅ functions[notifyUsersOnNewOffer(us-central1)] Successful update operation.
✅ functions[notifyClinicOnNewBooking(us-central1)] Successful update operation.
✅ functions[sendTestNotification(us-central1)] Successful update operation.
✅ functions[processPendingNotifications(us-central1)] Successful update operation.
✅ functions[cleanupOldRequests(us-central1)] Successful update operation.
```

## التحقق من الحل

### 1. بعد اكتمال النشر
```powershell
# اختبار طلب دواء جديد من التطبيق
# يجب أن تصل إشعارات للصيدليات
```

### 2. بعد إضافة عرض
```powershell
# اختبار إضافة عرض من صيدلية
# يجب أن تصل إشعارات لكل المستخدمين
```

### 3. فحص Logs الجديدة
```powershell
firebase functions:log --only notifyPharmaciesOnNewRequest
# يجب عدم ظهور أخطاء
# يجب ظهور: "Notification sent to pharmacy topic"
```

## التأكد من Topic Subscription

### المستخدمون الحاليون
الكود الموجود في `auth_repository.dart` يقوم بـ:
- ✅ Subscribe لكل المستخدمين في `all_users` topic (للعروض)
- ✅ Subscribe للصيدليات في `pharmacy_requests` topic (لطلبات الأدوية)

### المستخدمون الجدد
- ✅ يتم subscription تلقائياً عند تسجيل الدخول
- ✅ يتم حفظ FCM token في Firestore

## Cloud Functions المتوفرة

1. **notifyPharmaciesOnNewRequest** - إشعارات طلبات الأدوية
   - Trigger: `medicine_requests/{requestId}` onCreate
   - Topic: `pharmacy_requests`
   - Status: ✅ محدثة

2. **notifyUsersOnNewOffer** - إشعارات العروض
   - Trigger: `offers/{offerId}` onCreate
   - Topic: `all_users`
   - Status: ✅ محدثة

3. **notifyClinicOnNewBooking** - إشعارات الحجوزات
   - Trigger: `bookings/{bookingId}` onCreate
   - Topic: `clinic_{clinicId}`
   - Status: ✅ تعمل

## الخطوات التالية

1. ✅ انتظار اكتمال النشر
2. 🔄 اختبار طلب دواء جديد
3. 🔄 اختبار إضافة عرض جديد
4. 🔄 فحص وصول الإشعارات
5. 🔄 فحص Logs للتأكد من عدم وجود أخطاء

## ملاحظات

- Firebase Cloud Messaging يتطلب أن يكون المستخدم subscribed في topic
- Subscription يحدث تلقائياً عند تسجيل الدخول
- FCM Tokens تُخزن في Firestore في `users` collection
- Cloud Functions تعمل فقط في Production (ليس في Emulator)
