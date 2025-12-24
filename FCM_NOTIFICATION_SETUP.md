# FCM Notification System Setup - نظام الإشعارات

## 📋 نظرة عامة

تم تطبيق نظام إشعارات **قابل للتوسع** باستخدام **FCM Topics** بدلاً من التوكينات الفردية.

### ✅ المزايا:

- **قابل للتوسع**: يعمل مع عدد غير محدود من الصيدليات
- **موثوق**: لا يتأثر بتغيير التوكينات
- **بسيط**: إرسال واحد بدلاً من Loop على التوكينات
- **سريع**: Firebase يتولى التوزيع تلقائياً

---

## 📁 الملفات المُضافة/المُعدلة

### 1. **notification_service.dart** (جديد)

**المسار**: `lib/core/services/notification_service.dart`

**الوظائف**:
```dart
// تهيئة الإشعارات وطلب الصلاحيات
await notificationService.initialize();

// اشتراك صاحب الصيدلية في Topic
await notificationService.subscribeToPharmacyTopic(userId);

// إلغاء الاشتراك عند تسجيل الخروج
await notificationService.unsubscribeFromPharmacyTopic(userId);

// إضافة طلب إشعار للقائمة
await notificationService.notifyPharmaciesAboutNewRequest(
  medicineName: 'باراسيتامول',
  quantity: 2,
  userName: 'أحمد محمد',
  phoneNumber: '01234567890',
);
```

---

### 2. **auth_repository.dart** (معدّل)

**التعديلات**:

```dart
// عند تسجيل دخول صاحب صيدلية
if (role == 'pharmacy') {
  await _notificationService.subscribeToPharmacyTopic(firebaseUser.uid);
}

// عند تسجيل الخروج
if (userModel?.role == 'pharmacy') {
  await _notificationService.unsubscribeFromPharmacyTopic(user.uid);
}
```

---

### 3. **request_medicine_screen.dart** (معدّل)

**التعديل**:

```dart
// بعد حفظ الطلب في Firestore
await FirebaseFirestore.instance
    .collection('medicine_requests')
    .add(requestData);

// إرسال إشعار للصيدليات
final notificationService = NotificationService();
await notificationService.notifyPharmaciesAboutNewRequest(
  medicineName: _medicineNameController.text.trim(),
  quantity: int.parse(_quantityController.text.trim()),
  userName: user.displayName,
  phoneNumber: _phoneController.text.trim(),
);
```

---

### 4. **main.dart** (معدّل)

**التعديلات**:

```dart
// Handler للإشعارات في الخلفية
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

void main() async {
  // ...
  
  // تهيئة النظام
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // معالجة الإشعارات
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  notificationService.handleForegroundNotifications();
  notificationService.handleNotificationTaps();
  
  runApp(const MyApp());
}
```

---

### 5. **functions/index.js** (جديد)

**Cloud Functions للإرسال الفعلي**

**الوظائف المتاحة**:

#### أ) `notifyPharmaciesOnNewRequest`

- يُنفّذ تلقائياً عند إضافة طلب في `medicine_requests`
- يُرسل إشعار لجميع المشتركين في Topic `pharmacy_requests`

#### ب) `processPendingNotifications`

- يُعالج الإشعارات من collection `pending_notifications`
- مفيد إذا أردت queue للإشعارات

#### ج) `sendTestNotification`

- HTTP endpoint لاختبار النظام
- استخدمه للتأكد من عمل الإشعارات

#### د) `cleanupOldRequests`

- يُنظّف الطلبات القديمة (أكثر من 30 يوم)
- يعمل تلقائياً يومياً منتصف الليل

---

## 🚀 خطوات التنفيذ

### **الخطوة 1: تثبيت الـ Dependencies**

```powershell
# في مجلد المشروع
flutter pub get
```

---

### **الخطوة 2: إعداد Firebase Cloud Functions**

```powershell
# تثبيت Firebase CLI
npm install -g firebase-tools

# تسجيل الدخول
firebase login

# في مجلد المشروع
cd w:\projects\clinicalsystem

# تهيئة Functions (إذا لم تكن مُعدة)
firebase init functions
# اختر:
# - Use existing project
# - JavaScript
# - Install dependencies: Yes

# الانتقال لمجلد functions
cd functions

# تثبيت الحزم
npm install
```

---

### **الخطوة 3: نشر Cloud Functions**

```powershell
# من مجلد المشروع الرئيسي
firebase deploy --only functions
```

**النتيجة**:
```
✔  functions[notifyPharmaciesOnNewRequest]: Successful create operation.
✔  functions[processPendingNotifications]: Successful create operation.
✔  functions[sendTestNotification]: Successful create operation.
✔  functions[cleanupOldRequests]: Successful create operation.
```

---

### **الخطوة 4: إعدادات Android (اختياري)**

**android/app/src/main/AndroidManifest.xml**:

```xml
<manifest>
  <application>
    <!-- إضافة notification channel -->
    <meta-data
      android:name="com.google.firebase.messaging.default_notification_channel_id"
      android:value="medicine_requests" />
    
    <!-- أيقونة الإشعار -->
    <meta-data
      android:name="com.google.firebase.messaging.default_notification_icon"
      android:resource="@drawable/ic_notification" />
    
    <!-- لون الإشعار -->
    <meta-data
      android:name="com.google.firebase.messaging.default_notification_color"
      android:resource="@color/colorPrimary" />
  </application>
</manifest>
```

---

### **الخطوة 5: إعدادات iOS (اختياري)**

**ios/Runner/AppDelegate.swift**:

```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 🧪 اختبار النظام

### **اختبار 1: الاشتراك في Topic**

```dart
// في أي مكان في التطبيق
final notificationService = NotificationService();
await notificationService.subscribeToPharmacyTopic('test_user_id');
```

تحقق من Console:
```
Subscribed to pharmacy topic: pharmacy_requests
```

---

### **اختبار 2: إرسال إشعار تجريبي**

**الطريقة 1: من Firebase Console**

1. اذهب إلى: Firebase Console > Cloud Messaging
2. اضغط "Send your first message"
3. Title: `اختبار 🔔`
4. Body: `هذا إشعار تجريبي`
5. Target: **Topic** → `pharmacy_requests`
6. اضغط "Review" ثم "Publish"

---

**الطريقة 2: من Cloud Function**

```powershell
# احصل على URL من Firebase Console
# سيكون شكله:
# https://us-central1-YOUR_PROJECT.cloudfunctions.net/sendTestNotification

curl "https://YOUR_FUNCTION_URL/sendTestNotification"
```

---

### **اختبار 3: طلب دواء حقيقي**

1. سجل دخول كمستخدم عادي
2. اذهب إلى "طلب دواء"
3. املأ البيانات واضغط "نشر الطلب"
4. يجب أن يصل إشعار لجميع الصيدليات المشتركة

---

## 📊 Firestore Collections

### **pharmacy_subscriptions** (اختياري)

يتتبع من اشترك في Topic:

```json
{
  "user_id_here": {
    "subscribedAt": Timestamp,
    "topic": "pharmacy_requests",
    "isActive": true,
    "unsubscribedAt": null
  }
}
```

---

### **pending_notifications** (اختياري)

إذا استخدمت الـ queue method:

```json
{
  "notification_id": {
    "type": "new_medicine_request",
    "topic": "pharmacy_requests",
    "title": "طلب دواء جديد 💊",
    "body": "أحمد يطلب باراسيتامول - الكمية: 2 علبة",
    "data": {
      "medicineName": "باراسيتامول",
      "quantity": 2,
      "userName": "أحمد",
      "phoneNumber": "01234567890"
    },
    "createdAt": Timestamp,
    "sent": false,
    "sentAt": null
  }
}
```

---

## ⚙️ الإعدادات المتقدمة

### **تخصيص رسالة الإشعار**

في `functions/index.js`:

```javascript
const notification = {
  notification: {
    title: '🔔 عميل جديد!',
    body: `${userName} يبحث عن ${medicineName}`,
    // أضف صورة
    imageUrl: requestData.imageUrl,
  },
  data: {
    // بيانات إضافية
    requestId: requestId,
    priority: 'urgent',
    sound: 'notification_sound.mp3',
  },
};
```

---

### **Topics متعددة**

```dart
// Topic حسب المنطقة
await FirebaseMessaging.instance.subscribeToTopic('pharmacy_cairo');
await FirebaseMessaging.instance.subscribeToTopic('pharmacy_alex');

// Topic حسب نوع الطلب
await FirebaseMessaging.instance.subscribeToTopic('urgent_requests');
await FirebaseMessaging.instance.subscribeToTopic('regular_requests');
```

---

### **جدولة الإشعارات**

```javascript
// إرسال إشعار بعد 30 دقيقة إذا لم يرد أحد
exports.reminderNotification = functions.firestore
  .document('medicine_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();
    
    // جدولة بعد 30 دقيقة
    await admin.firestore()
      .collection('scheduled_notifications')
      .add({
        requestId: context.params.requestId,
        scheduledFor: admin.firestore.Timestamp.fromMillis(
          Date.now() + 30 * 60 * 1000
        ),
        message: `لا يزال ${requestData.userName} ينتظر الرد`,
      });
  });
```

---

## 🐛 حل المشاكل

### **المشكلة 1: الإشعارات لا تصل**

**التحقق**:
```dart
// تحقق من التوكين
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');

// تحقق من الاشتراك
await FirebaseMessaging.instance.subscribeToTopic('pharmacy_requests');
```

**الحلول**:

- تأكد من `google-services.json` محدث
- تأكد من Internet permission في AndroidManifest
- تأكد من Cloud Functions مُنشورة

---

### **المشكلة 2: Cloud Function تفشل**

**التحقق من Logs**:
```powershell
firebase functions:log
```

**الحلول المحتملة**:

- تحقق من صلاحيات Firebase Admin SDK
- تحقق من Firestore indexes
- تحقق من quota limits في Firebase

---

### **المشكلة 3: الإشعارات تصل في الخلفية فقط**

**السبب**: Flutter app في Foreground

**الحل**: استخدم local notifications package

```yaml
dependencies:
  flutter_local_notifications: ^16.3.0
```

```dart
void handleForegroundNotifications() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // عرض local notification
    await _showLocalNotification(message);
  });
}
```

---

## 📈 قياس الأداء

### **من Firebase Console**:

1. اذهب إلى: **Cloud Messaging**
2. شاهد:
   - عدد الرسائل المُرسلة
   - معدل التسليم
   - معدل الفتح
   - الأخطاء

### **من Firestore**:

```dart
// تتبع معدل الاستجابة
await FirebaseFirestore.instance
  .collection('notification_analytics')
  .add({
    'requestId': requestId,
    'sentAt': FieldValue.serverTimestamp(),
    'deliveredCount': 0,
    'openedCount': 0,
  });
```

---

## ✅ الخلاصة

### **ما تم تنفيذه**:

- ✅ نظام Topics بدلاً من Tokens
- ✅ اشتراك تلقائي لأصحاب الصيدليات
- ✅ إرسال إشعار عند كل طلب جديد
- ✅ Cloud Functions للإرسال الفعلي
- ✅ معالجة الإشعارات في التطبيق
- ✅ اختبار وتوثيق شامل

### **التالي (اختياري)**:

- 🔲 إضافة local notifications
- 🔲 إشعارات مجدولة
- 🔲 Topics حسب المنطقة
- 🔲 تحليلات متقدمة
- 🔲 Rich notifications (صور، أزرار)

---

## 📞 الدعم

إذا واجهت مشكلة:

1. تحقق من Firebase Console Logs
2. تحقق من Flutter console
3. تحقق من `functions:log`
4. تأكد من الصلاحيات والإعدادات

---

**تم بحمد الله ✅**
