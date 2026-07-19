# 🧪 اختبار بسيط للإشعارات على iOS

## الهدف
نتأكد إن iPhone بيستقبل إشعارات من Firebase أصلاً (قبل ما نختبر الحجوزات والعروض)

---

## 📱 الخطوات (5 دقائق فقط)

### 1️⃣ شغل التطبيق على iPhone

```bash
# افتح Xcode
open /Users/georgesadek/Downloads/clinicalSys-main/ios/Runner.xcworkspace
```

**في Xcode**:
1. وصّل iPhone بالكمبيوتر (USB)
2. اختر جهازك من القائمة (فوق)
3. اضغط Run (▶️)
4. **مهم**: افتح Console (Cmd + Shift + Y)

---

### 2️⃣ احصل على FCM Token

**في Xcode Console، ابحث عن**:
```
📱 FCM Token: dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**انسخ الـ Token كامل** (163 حرف تقريباً)

---

### 3️⃣ أرسل إشعار من Firebase Console

1. **افتح**: https://console.firebase.google.com
2. **اختر Project**: `clinicalsystem-4da35`
3. **من القائمة اليمين**: Messaging (أو Engage → Messaging)
4. **اضغط**: "Send your first message" أو "New campaign"
5. **املأ**:
   - **Title**: اختبار iOS
   - **Text**: رسالة تجريبية

6. **اضغط**: "Send test message"
7. **الصق FCM Token** اللي نسخته
8. **اضغط**: "Test"

---

## 📊 النتيجة المتوقعة

### ✅ إذا وصل الإشعار:

**معنى ده**:
- ✅ APNs يعمل بنجاح
- ✅ FCM Token صحيح
- ✅ APNs Keys على Firebase صحيحة
- ✅ Provisioning Profile صحيح

**المشكلة إذن في**:
- ❌ Topic Subscription
- ❌ Cloud Function
- ❌ Firestore data

**الحل**:
- نفحص Firestore ونشوف هل الـ subscription اتحفظ صح
- نفحص Cloud Function logs

---

### ❌ إذا لم يصل الإشعار:

**معنى ده**:
- ❌ مشكلة في APNs Configuration

**الأسباب المحتملة**:
1. **APNs Key** على Firebase غلط أو منتهي
2. **Team ID** مش مطابق
3. **Bundle ID** مش مطابق
4. **Provisioning Profile** مش بيدعم Push Notifications

**الحل**:
انظر: `XCODE_NOTIFICATION_DEBUG_GUIDE.md` → Problem 2

---

## 🔍 تشخيص إضافي

### في Xcode Console، ابحث عن:

#### ✅ إذا شفت ده:
```
🔧 [DEBUG] Starting notification initialization...
✅ User granted notification permission
✅ [DEBUG] FCM Token obtained successfully!
📱 FCM Token: dxxx...xxx
📱 Token length: 163 characters
```
→ **APNs شغال من ناحية التطبيق**

#### ❌ إذا شفت ده:
```
❌ [DEBUG] FAILED to get FCM Token!
📱 FCM Token: null
```
→ **APNs مش شغال**

---

## 🎯 بعد النتيجة

### إذا Test نجح (الإشعار وصل):

**نكمل Test 2**: اختبار Topic Subscription

1. سجل دخول **كصاحب عيادة**
2. انظر Console، لازم تشوف:
   ```
   ✅ Subscribed to clinic topic: clinic_xxx
   ```
3. من Android، احجز موعد
4. شوف هل الإشعار وصل

---

### إذا Test فشل (الإشعار لم يصل):

**نصلح APNs Configuration**:

1. **تحقق من Firebase Console**:
   - Project Settings → Cloud Messaging
   - Apple app configuration
   - APNs Authentication Key:
     - Key ID: `9QY3DKL5BG`
     - Team ID: `YRJ4DLXDZ2`

2. **إذا غير موجود أو غلط**:
   - احذف القديم
   - أنشئ Key جديد من: https://developer.apple.com/account/resources/authkeys/list
   - ارفعه على Firebase

3. **أعد Test**

---

## 📋 Quick Checklist

قبل الاختبار، تأكد:

- [ ] iPhone موصول بالكمبيوتر
- [ ] التطبيق شغال من Xcode (ليس Simulator)
- [ ] Console مفتوح في Xcode
- [ ] FCM Token ظهر في Console
- [ ] الإنترنت متصل على iPhone
- [ ] Notification permissions ممنوحة

---

## 💡 نصيحة

**إذا FCM Token = null**:
1. امسح التطبيق من iPhone
2. في Xcode: Product → Clean Build Folder (Cmd + Shift + K)
3. أعد التشغيل
4. أعطي الأذونات من جديد

---

**جاهز؟ جرب الـ Test وقول لي النتيجة! 🚀**

**السؤال الوحيد**: هل الإشعار من Firebase Console وصل؟ (نعم/لا)
