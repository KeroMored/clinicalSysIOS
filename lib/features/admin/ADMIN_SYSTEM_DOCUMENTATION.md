# 🔐 نظام الأدمن - Admin System

## ✅ تم إنجاز نظام الأدمن بنجاح!

### 📋 ما تم إنجازه:

#### 1. **صفحة الأدمن الرئيسية (Admin Home Page)**
- ✅ 3 أقسام للموافقات:
  - 💊 الموافقة على الصيدليات (جاهز!)
  - 🏥 الموافقة على العيادات (قريباً)
  - 💉 الموافقة على التمريض (قريباً)
- ✅ عداد الطلبات المعلقة على كل زر
- ✅ واجهة مستخدم احترافية

#### 2. **صفحة الموافقة على الصيدليات (Approve Pharmacies)**
- ✅ عرض جميع طلبات إضافة الصيدليات المعلقة
- ✅ بطاقات تفصيلية لكل طلب تحتوي على:
  - اسم الصيدلية
  - معلومات المالك
  - العنوان والهاتف
  - رقم الترخيص
  - تاريخ الطلب
  - حالة الطلب (في الانتظار/تمت الموافقة/مرفوض)
- ✅ زر "عرض التفاصيل" لكل طلب
- ✅ Pull to refresh

#### 3. **صفحة تفاصيل الطلب (Pharmacy Request Details)**
- ✅ عرض شامل لجميع معلومات الطلب:
  - معلومات المالك (الاسم، البريد، الهاتف، رقم الترخيص)
  - معلومات الصيدلية (الاسم، الوصف، العنوان، الهاتف، واتساب)
  - مواعيد العمل والإجازات
  - معلومات التوصيل (الرسوم، الحد الأدنى)
  - الخدمات المتوفرة
  - الموقع (خط العرض والطول)
  - معرض الصور
  - المستندات
- ✅ زر عرض الموقع على خرائط جوجل
- ✅ أزرار الموافقة أو الرفض
- ✅ حوار تأكيد الموافقة
- ✅ حوار الرفض مع إدخال السبب

---

## 🏗️ البنية المعمارية

### الهيكل الكامل:

```
lib/features/admin/
├── data/
│   ├── models/
│   │   └── pharmacy_request_model.dart     # نموذج طلب الصيدلية
│   └── repositories/
│       └── admin_repository.dart            # مستودع الأدمن
│
└── presentation/
    ├── cubit/
    │   ├── admin_cubit.dart                 # إدارة حالة الأدمن
    │   └── admin_state.dart                 # حالات الأدمن
    ├── screens/
    │   ├── admin_home_page.dart             # الصفحة الرئيسية
    │   ├── approve_pharmacies_screen.dart   # صفحة الموافقات
    │   └── pharmacy_request_details_screen.dart  # تفاصيل الطلب
    └── widgets/
        └── pharmacy_request_card.dart       # بطاقة الطلب
```

---

## 📊 النماذج (Models)

### PharmacyRequestModel

```dart
{
  // معلومات الصيدلية الأساسية
  id: String
  name: String
  address: String
  phone: String
  whatsapp: String
  description: String
  latitude: double
  longitude: double
  workingHours: String
  holidays: String
  images: List<String>
  
  // معلومات التوصيل
  hasHomeDelivery: bool
  deliveryFee: double?
  minimumOrderForDelivery: double?
  services: List<String>
  
  // معلومات الطلب
  status: String  // 'pending', 'approved', 'rejected'
  requestDate: DateTime
  rejectionReason: String?
  
  // معلومات المالك
  ownerName: String
  ownerEmail: String
  ownerPhone: String
  pharmacyLicense: String  // رقم الترخيص
  licenseDocuments: List<String>  // صور المستندات
}
```

---

## 🔄 إدارة الحالة (State Management)

### States:

- `AdminInitial` - الحالة الأولية
- `AdminLoading` - جاري التحميل
- `PharmacyRequestsLoaded` - تم تحميل الطلبات
- `AdminError` - حدث خطأ
- `RequestDetailsLoading` - جاري تحميل التفاصيل
- `RequestDetailsLoaded` - تم تحميل التفاصيل
- `RequestApproving` - جاري الموافقة
- `RequestApproved` - تمت الموافقة
- `RequestRejecting` - جاري الرفض
- `RequestRejected` - تم الرفض
- `RequestSubmitting` - جاري إرسال الطلب
- `RequestSubmitted` - تم إرسال الطلب

### Methods (AdminCubit):

```dart
loadPendingPharmacyRequests()    // تحميل الطلبات المعلقة
loadAllPharmacyRequests()        // تحميل جميع الطلبات
loadRequestDetails(String id)    // تحميل تفاصيل طلب معين
approveRequest(String id)        // الموافقة على طلب
rejectRequest(String id, reason) // رفض طلب
submitPharmacyRequest(request)   // إرسال طلب جديد
getPendingCount()                // الحصول على عدد الطلبات المعلقة
```

---

## 🗄️ قاعدة البيانات (Firestore)

### Collection: `pharmacy_requests`

```json
{
  "name": "صيدلية النور",
  "address": "شارع الجمهورية، المنصورة",
  "phone": "+201234567890",
  "whatsapp": "201234567890",
  "description": "صيدلية متكاملة...",
  "latitude": 31.0364,
  "longitude": 31.3785,
  "workingHours": "من 9 صباحاً إلى 11 مساءً",
  "holidays": "الجمعة",
  "images": ["url1", "url2"],
  "hasHomeDelivery": true,
  "deliveryFee": 15.0,
  "minimumOrderForDelivery": 50.0,
  "services": ["قياس الضغط", "قياس السكر"],
  "status": "pending",
  "requestDate": "2025-01-07T10:00:00.000Z",
  "rejectionReason": null,
  "ownerName": "أحمد محمد",
  "ownerEmail": "ahmed@example.com",
  "ownerPhone": "+201234567890",
  "pharmacyLicense": "PH-12345",
  "licenseDocuments": ["doc_url1", "doc_url2"]
}
```

---

## ⚙️ كيفية عمل النظام

### سير العمل (Workflow):

1. **إرسال الطلب:**
   - صاحب الصيدلية يملأ البيانات
   - يتم حفظ الطلب في `pharmacy_requests` بحالة `pending`

2. **مراجعة الطلب:**
   - الأدمن يدخل إلى صفحة "الموافقة على الصيدليات"
   - يشاهد جميع الطلبات المعلقة
   - يضغط على طلب لعرض التفاصيل

3. **الموافقة على الطلب:**
   - الأدمن يراجع جميع التفاصيل
   - يضغط زر "موافقة"
   - يتم:
     * نقل البيانات إلى collection `pharmacies`
     * تحديث حالة الطلب إلى `approved`
     * إظهار رسالة نجاح

4. **رفض الطلب:**
   - الأدمن يضغط زر "رفض"
   - يدخل سبب الرفض
   - يتم:
     * تحديث حالة الطلب إلى `rejected`
     * حفظ سبب الرفض
     * إظهار رسالة

---

## 🎨 الميزات التقنية

### ✅ المميزات:

- **Clean Architecture** - كود منظم ومفصول
- **Cubit State Management** - إدارة حالة بسيطة وفعالة
- **Isolated Widgets** - ويدجيت معزولة قابلة لإعادة الاستخدام
- **Firebase Integration** - متكامل مع Firestore
- **Error Handling** - معالجة شاملة للأخطاء
- **Loading States** - حالات تحميل واضحة
- **User Feedback** - رسائل توضيحية للمستخدم
- **Confirmation Dialogs** - حوارات تأكيد قبل الإجراءات المهمة
- **Validation** - التحقق من البيانات
- **Arabic UI** - واجهة عربية كاملة

---

## 🚀 التشغيل والاختبار

### 1. تثبيت الحزم:
```bash
flutter pub get  # تم بالفعل ✅
```

### 2. إضافة بيانات تجريبية:

أضف طلبات تجريبية في Firestore:

```javascript
// في Firebase Console -> Firestore
// أنشئ collection جديد: pharmacy_requests

// أضف document:
{
  "name": "صيدلية النور",
  "address": "شارع الجمهورية، المنصورة",
  "phone": "+201234567890",
  "whatsapp": "201234567890",
  "description": "صيدلية متكاملة تقدم جميع أنواع الأدوية",
  "latitude": 31.0364,
  "longitude": 31.3785,
  "workingHours": "من 9 صباحاً إلى 11 مساءً يومياً",
  "holidays": "الجمعة",
  "images": [
    "https://via.placeholder.com/400x300?text=Pharmacy"
  ],
  "hasHomeDelivery": true,
  "deliveryFee": 15.0,
  "minimumOrderForDelivery": 50.0,
  "services": ["قياس الضغط", "قياس السكر", "استشارة صيدلي"],
  "status": "pending",
  "requestDate": "2025-01-07T10:00:00.000Z",
  "rejectionReason": null,
  "ownerName": "أحمد محمد",
  "ownerEmail": "ahmed@example.com",
  "ownerPhone": "+201234567890",
  "pharmacyLicense": "PH-12345-2025",
  "licenseDocuments": [
    "https://via.placeholder.com/400x300?text=License"
  ]
}
```

### 3. اختبار النظام:

1. شغّل التطبيق
2. من الصفحة الرئيسية، اضغط على زر "الأدمن"
3. اضغط على "الموافقة على الصيدليات"
4. شاهد الطلبات المعلقة
5. اضغط على أي طلب لعرض التفاصيل
6. جرب الموافقة أو الرفض

---

## 📝 قواعد Firestore المطلوبة

للسماح للأدمن بالقراءة والكتابة:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // قواعد طلبات الصيدليات
    match /pharmacy_requests/{requestId} {
      // السماح بالقراءة للجميع (أو للأدمن فقط)
      allow read: if true;
      
      // السماح بالكتابة للمستخدمين المصرح لهم
      allow create: if request.auth != null;
      
      // السماح بالتحديث للأدمن فقط
      allow update: if request.auth != null 
                    && request.auth.token.admin == true;
    }
    
    // قواعد الصيدليات
    match /pharmacies/{pharmacyId} {
      allow read: if true;
      allow write: if request.auth != null 
                   && request.auth.token.admin == true;
    }
  }
}
```

---

## 🎯 التحسينات المستقبلية

### 🔜 قادم قريباً:

- [ ] نظام الإشعارات للأدمن عند طلب جديد
- [ ] صفحة إحصائيات (عدد الطلبات المقبولة/المرفوضة/المعلقة)
- [ ] تصفية وفرز الطلبات (حسب التاريخ، الحالة، إلخ)
- [ ] البحث في الطلبات
- [ ] تصدير التقارير
- [ ] سجل التغييرات (Audit Log)
- [ ] رفع المستندات مباشرة
- [ ] معاينة الصور والمستندات بشكل أفضل
- [ ] نظام التعليقات على الطلبات
- [ ] الموافقة على العيادات والتمريض

---

## 🔐 الأمان

### ⚠️ ملاحظات أمنية:

1. **Authentication:** يجب إضافة نظام مصادقة للأدمن
2. **Authorization:** التحقق من صلاحيات المستخدم قبل السماح بالموافقة/الرفض
3. **Validation:** التحقق من صحة البيانات قبل الحفظ
4. **Logging:** تسجيل جميع عمليات الموافقة/الرفض
5. **Rate Limiting:** منع الإساءة في استخدام النظام

---

## 📱 الاستخدام

### للأدمن:

1. افتح التطبيق
2. اضغط على "الأدمن"
3. اختر "الموافقة على الصيدليات"
4. راجع الطلبات
5. اضغط على طلب لعرض التفاصيل
6. وافق أو ارفض حسب المعايير

### لصاحب الصيدلية (قريباً):

1. سيتم إضافة صفحة تسجيل الصيدلية
2. ملء البيانات المطلوبة
3. رفع المستندات
4. إرسال الطلب
5. انتظار الموافقة

---

## ✅ الحالة النهائية

### 🎉 تم الانتهاء من:

- [x] صفحة الأدمن الرئيسية
- [x] صفحة الموافقة على الصيدليات
- [x] صفحة تفاصيل الطلب
- [x] نموذج طلب الصيدلية
- [x] Repository للأدمن
- [x] Cubit للأدمن
- [x] Widgets معزولة
- [x] التكامل مع Firebase
- [x] معالجة الأخطاء
- [x] واجهة مستخدم احترافية
- [x] التوثيق الكامل

---

**تم التطوير بنجاح! ✨**

**التاريخ:** نوفمبر 2025
**الإصدار:** 1.0.0
**الحالة:** ✅ جاهز للاستخدام
