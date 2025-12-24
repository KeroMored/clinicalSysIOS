# 🚀 دليل البدء السريع - Quick Start Guide

## ✅ تم تثبيت جميع الـ Packages بنجاح!

## 📋 الخطوات التالية:

### 1. ⚙️ إعداد Firebase (إذا لم يتم بعد)

#### Firebase Console:
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك
3. اذهب إلى **Firestore Database**
4. قم بإنشاء قاعدة بيانات (Production mode أو Test mode)

#### إضافة البيانات التجريبية:
راجع ملف [`SAMPLE_DATA.md`](./SAMPLE_DATA.md) للحصول على بيانات جاهزة للإضافة.

---

### 2. 🏃‍♂️ تشغيل التطبيق

```bash
# تأكد من أنك في مجلد المشروع
cd w:\projects\clinicalsystem

# شغل التطبيق
flutter run
```

---

### 3. 🧭 التنقل في التطبيق

#### الصفحة الرئيسية:
عند فتح التطبيق ستجد 3 أزرار:
- 🏥 **العيادات** (قيد التطوير)
- 💊 **الصيدليات** ← اضغط هنا! ✅
- 💉 **التمريض** (قيد التطوير)

#### صفحة الصيدليات:
ستجد:
- 📋 قائمة الخيارات الرئيسية
- 🎁 العروض المميزة (slider أفقي)
- 🏪 الصيدليات القريبة

#### التفاعل:
- اضغط على "الصيدليات" → لعرض جميع الصيدليات
- اضغط على أي صيدلية → لعرض التفاصيل
- استخدم البحث 🔍 → للبحث عن صيدلية

---

### 4. 🗄️ هيكل قاعدة البيانات المطلوب

#### Collection: `pharmacies`
أضف documents بالحقول التالية:
- name (String)
- address (String)
- phone (String)
- whatsapp (String)
- description (String)
- latitude (number)
- longitude (number)
- workingHours (String)
- holidays (String)
- images (Array)
- hasHomeDelivery (boolean)
- deliveryFee (number) - optional
- minimumOrderForDelivery (number) - optional
- rating (number)
- reviewsCount (number)
- isOpen (boolean)
- closingTime (String) - optional
- services (Array)

#### Collection: `pharmacy_offers`
أضف documents بالحقول التالية:
- pharmacyId (String)
- pharmacyName (String)
- title (String)
- description (String)
- imageUrl (String)
- discountPercentage (number) - optional
- startDate (timestamp)
- endDate (timestamp)
- isActive (boolean)

**💡 نصيحة:** استخدم البيانات من ملف `SAMPLE_DATA.md` كنموذج.

---

### 5. 🧪 اختبار الميزات

#### ✅ اختبر:
- [ ] عرض الصيدليات
- [ ] البحث عن صيدلية
- [ ] فتح تفاصيل صيدلية
- [ ] عرض العروض
- [ ] الاتصال برقم الصيدلية
- [ ] فتح واتساب
- [ ] فتح الموقع على الخريطة
- [ ] Pull to refresh

---

### 6. 🎨 التخصيص (اختياري)

#### تغيير الألوان:
في `main.dart`:
```dart
colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
```

#### تغيير الخط:
في `main.dart`:
```dart
fontFamily: 'Cairo',  // غير هذا إلى الخط المفضل
```

---

### 7. ⚠️ حل المشاكل الشائعة

#### المشكلة: "لا توجد صيدليات"
**الحل:** تأكد من إضافة بيانات في Firestore collection `pharmacies`

#### المشكلة: "حدث خطأ"
**الحل:** 
1. تحقق من اتصال الإنترنت
2. تأكد من إعدادات Firebase
3. تحقق من قواعد Firestore

#### المشكلة: الصور لا تظهر
**الحل:** استخدم روابط صور صحيحة في حقل `images`

---

### 8. 📱 الميزات المتاحة الآن

✅ **جاهز للاستخدام:**
- عرض الصيدليات
- البحث والتصفية
- عرض التفاصيل
- الاتصال والواتساب
- فتح الموقع على الخريطة
- عرض العروض
- حالات التحميل والأخطاء

🔜 **قادم قريباً:**
- طلب الأدوية
- نظام التقييمات
- المفضلة
- الإشعارات

---

### 9. 📚 مصادر إضافية

- [`README.md`](./README.md) - معلومات شاملة عن النظام
- [`SAMPLE_DATA.md`](./SAMPLE_DATA.md) - بيانات تجريبية جاهزة
- [`IMPLEMENTATION_SUMMARY.md`](./IMPLEMENTATION_SUMMARY.md) - ملخص التطوير

---

### 10. 🆘 الدعم

إذا واجهت أي مشاكل:
1. راجع الملفات التوثيقية
2. تحقق من console logs
3. راجع Firebase Console
4. تأكد من صحة البيانات

---

## 🎉 كل شيء جاهز!

الآن يمكنك:
1. ✅ تشغيل التطبيق
2. ✅ إضافة البيانات
3. ✅ اختبار الميزات
4. ✅ البدء في التطوير

**استمتع بالتطوير! 🚀**

---

**آخر تحديث:** نوفمبر 2025
**الإصدار:** 1.0.0
**الحالة:** ✅ جاهز للاستخدام
