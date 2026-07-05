# 🔍 Debug Push Notifications - خطوات التشخيص

## الخطوة 1: تأكد من الـ Cloud Functions deployed

### افتح Terminal واكتب:
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
firebase functions:list
```

**لو طلع Functions زي:**
- `notifyClinicOnNewBooking`
- `notifyUsersOnNewOffer`
- `notifyPharmaciesOnNewRequest`

**= معناها deployed ✅**

**لو مطلعش حاجة = محتاج Deploy:**
```bash
firebase deploy --only functions
```

---

## الخطوة 2: شوف الـ Functions Logs

```bash
firebase functions:log --only notifyClinicOnNewBooking
```

**لو شفت:**
- ❌ "No logs found" = الـ Function مش بتشتغل
- ✅ "Booking notification sent" = الـ Function شغالة

---

## الخطوة 3: تأكد من Topic Subscription

### افتح Firebase Console Firestore وشوف:

#### للدكتور (Clinic Bookings):
```
Collection: clinic_subscriptions
Document ID: {clinicId}
Field: isActive = true
Field: topic = "clinic_{clinicId}"
Field: fcmToken = (موجود)
```

#### للمستخدمين (Offers):
```
Collection: users
Document ID: {userId}
Field: subscribedToAllUsers = true
Field: fcmToken = (موجود)
```

**لو مفيش fcmToken = مشكلة!**

---

## الخطوة 4: Test من Firebase Console

### A. Test Push Notification:
```
1. افتح: https://console.firebase.google.com
2. Cloud Messaging → Send test message
3. Add FCM token (من Console logs)
4. اكتب Title + Body
5. اضغط Test
```

**لو وصل = APNs شغال ✅**  
**لو موصلش = مشكلة في APNs ❌**

---

## الخطوة 5: شوف Console Logs في التطبيق

### لما تفتح التطبيق، شوف في Xcode Console:

**لازم تلاقي:**
```
✅ "📱 FCM Token: abc123..."
✅ "✅ Subscribed to clinic topic: clinic_xyz"
✅ "✅ Subscribed to all_users topic"
✅ "🍎 iOS permissions granted: true"
```

**لو مش موجود FCM Token:**
```
❌ معناها APNs مش شغال
→ شوف APNs Key على Firebase Console
```

---

## 🔧 الحلول حسب المشكلة

### مشكلة 1: FCM Token = null
**الحل:**
```
1. تأكد APNs Key موجود على Firebase Console
2. Key ID = 9QY3DKL5BG
3. Team ID = YRJ4DLXDZ2
4. Bundle ID = com.mored.mallawicure
```

### مشكلة 2: Functions مش deployed
**الحل:**
```bash
firebase deploy --only functions
```

### مشكلة 3: مفيش Topic Subscription
**الحل:** التطبيق المفروض يعمل subscribe تلقائي.  
شوف في الكود:
- `NotificationService.subscribeToClinicTopic()`
- `NotificationService.subscribeToAllUsersTopic()`

### مشكلة 4: Notification بتوصل لكن مش بتظهر
**الحل:**
```
1. Settings → App → Notifications
2. Allow Notifications = ON
3. Alerts, Sounds, Badges = ON
```

---

## 📋 Quick Checklist

- [ ] Firebase CLI installed: `firebase --version`
- [ ] Logged in: `firebase login`
- [ ] Functions deployed: `firebase functions:list`
- [ ] APNs Key على Firebase Console
- [ ] FCM Token يظهر في Console
- [ ] Topic subscription موجودة في Firestore
- [ ] Notification permissions = granted

---

## 🧪 Test النهائي

### Test 1: Manual Test من Firebase Console
```
1. Cloud Messaging → Send test message
2. FCM Token: (احطه من Console)
3. Send
4. لو وصل = APNs شغال ✅
```

### Test 2: Real Booking Test
```
1. احجز موعد أونلاين
2. شوف Firebase Console → Functions logs
3. لازم تلاقي: "Booking notification sent"
4. لو مش موجود = Function مش شغالة
```

### Test 3: Real Offer Test
```
1. انزل عرض من صيدلية
2. شوف Functions logs
3. لازم تلاقي: "Offer notification sent to all_users"
```

---

## 🚨 أكتر مشكلة شائعة:

### **Functions مش deployed!**

**التأكد:**
```bash
firebase functions:list
```

**لو فاضي:**
```bash
firebase deploy --only functions
```

**ده هياخد 5-10 دقايق، استنى لحد ما يخلص!**

---

## 📞 إذا لسه مش شغالة

### اعمل الخطوات دي بالترتيب:

1. **شوف Firebase Console → Functions**
   - لو مفيش functions = Deploy!
   
2. **شوف Functions Logs**
   ```bash
   firebase functions:log
   ```
   - لو مفيش logs = Functions مش بتشتغل
   
3. **Test من Console**
   - Cloud Messaging → Send test message
   - لو موصلش = APNs مشكلة
   
4. **شوف Firestore**
   - clinic_subscriptions → fcmToken موجود؟
   - users → fcmToken موجود؟
   - لو مش موجود = مشكلة في registration

---

## 🎯 الخلاصة

**99% المشكلة في واحدة من 3 حاجات:**
1. ❌ Functions مش deployed
2. ❌ FCM Token مش موجود (APNs مشكلة)
3. ❌ Topic subscription مش موجودة

**اعمل الخطوات فوق بالترتيب وهتعرف المشكلة فين!** 🔍
