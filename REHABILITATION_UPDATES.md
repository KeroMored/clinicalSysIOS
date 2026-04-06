# تحديثات نظام مراكز التأهيل

## التغييرات المطبقة

### 1. تحديث Model (rehabilitation_center_model.dart)

**الحقول المحذوفة:**

- `licenseImageUrl` - صورة الترخيص
- `sessionPrice` - سعر الجلسة
- `experienceYears` - سنوات الخبرة
- `workingHours` (String) - ساعات العمل النصية
- `governorate` - المحافظة
- `city` - المدينة
- `latitude` - خط العرض
- `longitude` - خط الطول
- `email` (اختياري) - البريد الإلكتروني

**الحقول المضافة:**

- `ownerEmail` (إجباري) - البريد الإلكتروني للمصادقة والتحكم
- `workingDays` (Map<String, WorkingHours>) - أيام ومواعيد العمل (مثل نظام العيادات)
- `holidays` (List<String>) - أيام العطلات الرسمية

**Class جديد:**

- `WorkingHours` - يحتوي على from, to, isClosed لكل يوم

### 2. شاشة إضافة مركز (add_rehabilitation_center_screen.dart)

**التحديثات:**

- إزالة حقول: صورة الترخيص، سعر الجلسة، سنوات الخبرة، المحافظة، المدينة
- إزالة حقول خطوط الطول والعرض اليدوية
- البريد الإلكتروني أصبح إجباري (مع رسالة توضيحية)
- إضافة نظام مواعيد العمل (7 أيام مع From/To Times)
- إضافة نظام اختيار العطلات الرسمية (8 عطلات)
- الاحتفاظ بزر "تحديد الموقع التلقائي" فقط

### 3. شاشة التفاصيل (rehabilitation_center_detail_screen.dart)

**التحديثات:**

- إزالة عرض: البريد الإلكتروني، سعر الجلسة، سنوات الخبرة، ساعات العمل
- إزالة قسم الخريطة والإحداثيات
- إزالة عرض المحافظة والمدينة
- **إضافة زر "أعمالنا وعروضنا"** ينقل إلى صفحة عرض محتوى المركز

### 4. شاشة القائمة (rehabilitation_centers_list_screen.dart)

**التحديثات:**

- إزالة فلتر المحافظة
- استبدال عرض "محافظة - مدينة" بعرض العنوان الكامل
- **إضافة زر في AppBar** (أيقونة Settings) للوصول إلى لوحة التحكم

### 5. الملفات الجديدة

#### أ) center_content_model.dart

Model لمحتوى المركز (عروض، فيديوهات، صور):

- `type`: offer, video, image
- `title`, `description`, `imageUrl`, `videoUrl`
- `createdAt`, `isActive`

#### ب) rehabilitation_center_control_page.dart

لوحة التحكم الرئيسية لصاحب المركز:

- التحقق من البريد الإلكتروني
- عرض حالة الموافقة (pending/approved/rejected)
- 4 بطاقات تحكم:
  1. تعديل بيانات المركز
  2. إدارة المحتوى والعروض
  3. معلومات المركز
  4. تسجيل الخروج

#### ج) edit_rehabilitation_center_screen.dart

شاشة تعديل بيانات المركز (مماثلة لتعديل العيادة):

- تعديل الاسم، المدير، الهاتف، واتساب، العنوان، الوصف
- تعديل أنواع الخدمات
- **تعديل مواعيد العمل** (7 أيام مع مفتاح إجازة لكل يوم)
- **تعديل أيام العطلات**
- مفتاح الخدمة المنزلية
- تعديل صورة المركز

#### د) center_content_management_screen.dart

شاشة إدارة المحتوى (للمالك):

- إضافة محتوى جديد (عرض/فيديو/صورة)
- حقول: العنوان، الوصف، صورة، رابط فيديو YouTube
- قائمة المحتوى الحالي مع إمكانية الحذف
- الحفظ في Firebase: `rehabilitation_content` collection

#### هـ) center_works_screen.dart

شاشة عرض أعمال المركز (للمستخدمين):

- عرض جميع العروض والفيديوهات والصور
- تصميم Cards جذاب
- رابط مباشر لفيديوهات YouTube
- عرض تاريخ النشر بصيغة منذ X دقيقة/ساعة/يوم

#### و) center_owner_login_screen.dart

شاشة تسجيل دخول صاحب المركز:

- تسجيل دخول بالبريد والباسورد
- إنشاء حساب جديد
- Firebase Authentication
- الانتقال التلقائي للوحة التحكم بعد الدخول

## كيفية الاستخدام

### للمستخدمين

1. تصفح مراكز التأهيل من الصفحة الرئيسية
2. فتح تفاصيل المركز
3. الضغط على "أعمالنا وعروضنا" لمشاهدة أعمال وعروض المركز

### لأصحاب المراكز

1. الضغط على أيقونة Settings في شاشة مراكز التأهيل
2. تسجيل الدخول أو إنشاء حساب جديد
3. سيتم عرض لوحة التحكم:
   - إذا لم يكن هناك مركز: رسالة توضيحية
   - إذا كان المركز pending: رسالة انتظار الموافقة
   - إذا تمت الموافقة: إدارة كاملة
4. من لوحة التحكم:
   - تعديل بيانات المركز (مواعيد العمل والعطلات)
   - إضافة عروض وفيديوهات وصور
   - عرض معلومات المركز
   - تسجيل الخروج

### للإدارة

- يتم إضافة المراكز من شاشة Admin كالمعتاد
- البريد الإلكتروني أصبح إجباري
- المالك يمكنه إنشاء حساب بنفس البريد للتحكم

## Firebase Collections

### rehabilitation_centers

- الحقول المحدثة كما هو موضح أعلاه

### rehabilitation_content (جديد)

```
{
  id: string
  centerId: string
  type: 'offer' | 'video' | 'image'
  title: string
  description: string?
  imageUrl: string?
  videoUrl: string?
  createdAt: Timestamp
  isActive: boolean
}
```

## الملاحظات

- لا توجد أخطاء compilation
- فقط 12 info warnings (deprecations بسيطة)
- النظام جاهز للاستخدام الفوري
- Authentication يعتمد على Firebase Auth
- التخزين يعتمد على Firestore و Storage

## الملفات المعدلة

1. `rehabilitation_center_model.dart` - تحديث Model
2. `add_rehabilitation_center_screen.dart` - إعادة كتابة كاملة
3. `rehabilitation_center_detail_screen.dart` - إزالة حقول وإضافة زر
4. `rehabilitation_centers_list_screen.dart` - إزالة فلتر وإضافة زر

## الملفات المضافة (6 ملفات)

1. `center_content_model.dart`
2. `rehabilitation_center_control_page.dart`
3. `edit_rehabilitation_center_screen.dart`
4. `center_content_management_screen.dart`
5. `center_works_screen.dart`
6. `center_owner_login_screen.dart`
