# 🔧 حل مشكلة Provisioning Profile في Codemagic

## ❌ المشكلة:
```
Provisioning profile doesn't include the Associated Domains capability.
```

---

## ✅ الحل: تحديث Provisioning Profile

### الخطوة 1: تحديث App ID في Apple Developer

🔗 **رابط:** https://developer.apple.com/account/resources/identifiers/list

1. **ابحث عن App ID:** `com.mored.mallawycare`
2. **اضغط عليه للفتح**
3. **تحقق من Capabilities:**
   - [ ] ✅ Sign In with Apple
   - [ ] ✅ **Associated Domains** ← **مهم!**
   - [ ] ✅ Push Notifications

4. **إذا لم تكن Associated Domains مفعّلة:**
   - فعّلها ✅
   - اضغط **Save**

---

### الخطوة 2: إعادة إنشاء Provisioning Profile

🔗 **رابط:** https://developer.apple.com/account/resources/profiles/list

#### أ. حذف Profile القديم:
1. ابحث عن: **"mallawycareID ios_app_store"**
2. اضغط عليه
3. اضغط **Delete** أو **Edit**

#### ب. إنشاء Profile جديد:
1. اضغط **+ (زر جديد)**
2. اختر **App Store**
3. اضغط Continue

4. **App ID:**
   - اختر: `com.mored.mallawycare`
   - تأكد أن **Associated Domains** ظاهرة في القائمة

5. **Certificate:**
   - اختر Distribution Certificate الخاص بك
   - إذا لم يكن موجود، أنشئ واحد جديد

6. **Profile Name:**
   - اسمه: `mallawycare App Store`
   - أو استخدم نفس الاسم القديم

7. **Generate:**
   - اضغط **Generate**
   - اضغط **Download**

---

### الخطوة 3: تحديث Profile في Codemagic

🔗 **رابط:** https://codemagic.io/teams

1. **اذهب إلى:** Team settings → Code signing identities
2. **iOS Profiles:**
   - احذف Profile القديم: `mallawycareID ios_app_store 1781138035`
   - اضغط **+ Add profile**
   - ارفع Profile الجديد الذي حمّلته

3. **تأكد من:**
   - Profile name ظاهر
   - Bundle ID: `com.mored.mallawycare`
   - Capabilities تتضمن: **Associated Domains** ✅

---

### الخطوة 4: إعادة Build في Codemagic

1. اذهب إلى Build الفاشل
2. اضغط **Rebuild**
3. أو ابدأ **Start new build**

---

## 🎯 البديل السريع: إزالة Associated Domains مؤقتاً

**إذا كنت تريد build سريع دون Associated Domains:**

### تعديل `Runner.entitlements`:

