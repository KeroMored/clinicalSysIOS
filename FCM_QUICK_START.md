# FCM Notification - Quick Start 🚀

## ✅ ما تم عمله

### 1. **NotificationService** ✅

- اشتراك تلقائي في Topic عند تسجيل دخول صاحب صيدلية
- إلغاء اشتراك عند تسجيل الخروج
- إرسال إشعار عند كل طلب دواء جديد

### 2. **Cloud Functions** ✅

- Function تُنفّذ تلقائياً عند إنشاء طلب
- إرسال الإشعار لكل الصيدليات المشتركة
- معالجة الإشعارات في الخلفية

### 3. **Android Setup** ✅

- إضافة صلاحية POST_NOTIFICATIONS
- إعداد notification channel

---

## 📝 الخطوات المتبقية

### الخطوة 1: نشر Cloud Functions

```powershell
# تثبيت Firebase CLI
npm install -g firebase-tools

# تسجيل الدخول
firebase login

# في مجلد المشروع
cd w:\projects\clinicalsystem

# الانتقال لمجلد functions
cd functions

# تثبيت dependencies
npm install

# العودة للمجلد الرئيسي
cd ..

# نشر Functions
firebase deploy --only functions
```

---

### الخطوة 2: اختبار النظام

#### اختبار 1: تسجيل دخول صاحب صيدلية

1. شغل التطبيق
2. سجل دخول بإيميل صاحب صيدلية
3. تحقق من Console:

   ```
   Subscribed to pharmacy topic: pharmacy_requests
   ```

#### اختبار 2: إنشاء طلب دواء

1. سجل دخول كمستخدم عادي
2. اذهب لـ "طلب دواء"
3. املأ البيانات واضغط "نشر الطلب"
4. يجب أن يصل إشعار للصيدليات

#### اختبار 3: إشعار تجريبي من Firebase Console

1. اذهب لـ: Firebase Console > Cloud Messaging
2. اضغط "Send your first message"
3. Title: `اختبار 🔔`
4. Body: `هذا إشعار تجريبي`
5. Target: **Topic** → `pharmacy_requests`
6. اضغط "Review" ثم "Publish"

---

## 🎯 كيف يعمل النظام

```
1. صاحب صيدلية يسجل دخول
   ↓
2. يشترك تلقائياً في Topic "pharmacy_requests"
   ↓
3. مستخدم ينشئ طلب دواء
   ↓
4. يُحفظ في Firestore → medicine_requests
   ↓
5. Cloud Function تُنفّذ تلقائياً
   ↓
6. تُرسل إشعار لـ Topic "pharmacy_requests"
   ↓
7. كل الصيدليات المشتركة تستلم الإشعار
```

---

## 📱 الإشعار يحتوي على

```json
{
  "title": "طلب دواء جديد 💊",
  "body": "أحمد يطلب باراسيتامول - الكمية: 2 علبة",
  "data": {
    "requestId": "abc123",
    "medicineName": "باراسيتامول",
    "quantity": "2",
    "userName": "أحمد",
    "phoneNumber": "01234567890",
    "whatsappNumber": "",
    "imageUrl": "",
    "notes": ""
  }
}
```

---

## ⚠️ ملاحظات مهمة

1. **للاختبار على Android**:
   - تأكد من منح صلاحية Notifications للتطبيق
   - Android 13+ يطلب صلاحية POST_NOTIFICATIONS

2. **Firebase Console**:
   - تأكد من تفعيل Firebase Cloud Messaging
   - تأكد من Cloud Functions مُفعّلة

3. **Testing**:
   - يمكنك اختبار من Firebase Console قبل Cloud Functions
   - استخدم Topic name: `pharmacy_requests`

---

## 🐛 حل المشاكل

### المشكلة: الإشعارات لا تصل

**الحل**:

```dart
// في أي مكان، تحقق من Token:
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');

// إذا كان null، تحقق من:
// 1. google-services.json محدث
// 2. Internet permission في AndroidManifest
// 3. Firebase Cloud Messaging مُفعّل
```

### المشكلة: Cloud Function تفشل

**الحل**:

```powershell
# تحقق من logs:
firebase functions:log

# تحقق من النشر:
firebase deploy --only functions
```

---

## ✅ التالي (اختياري)

- [ ] إضافة local notifications للعرض في Foreground
- [ ] إضافة navigation عند الضغط على الإشعار
- [ ] إضافة badge count
- [ ] إضافة topics حسب المنطقة (القاهرة، الإسكندرية...)

---

**تم بحمد الله ✅**

شغل التطبيق وابدأ الاختبار! 🚀
