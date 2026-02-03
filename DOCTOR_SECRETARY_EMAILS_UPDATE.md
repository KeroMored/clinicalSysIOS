# تحديث نظام إدارة الإيميلات للدكاترة والسكرتيرة

## التاريخ: 2026-01-15

## نظرة عامة
تم تطوير نظام إدارة الإيميلات في العيادات ليدعم إيميلات متعددة للدكاترة وإضافة إمكانية تعديل هذه الإيميلات في صفحة تعديل بيانات العيادة، مع تقييد صلاحية التعديل للدكاترة فقط.

## التغييرات الرئيسية

### 1. تحديث ClinicModel
**الملف:** `lib/features/clinic/data/models/clinic_model.dart`

#### قبل التحديث:
```dart
final String? doctorEmail;  // إيميل واحد فقط
final List<String> secretaryEmails;
```

#### بعد التحديث:
```dart
final List<String> doctorEmails;  // إيميلات متعددة للدكاترة
final List<String> secretaryEmails;  // إيميلات متعددة للسكرتيرة
```

#### المميزات:
- **التوافق مع البيانات القديمة:** يتم تحويل `doctorEmail` القديم تلقائياً إلى `doctorEmails` عند القراءة من Firestore
- **دعم إيميلات متعددة:** يمكن إضافة أكثر من دكتور للعيادة الواحدة
- **الحفظ في Firestore:** يتم حفظ `doctorEmails` و `secretaryEmails` كـ arrays

### 2. تحديث صفحة إضافة العيادة
**الملف:** `lib/features/admin/presentation/screens/add_clinic_screen.dart`

#### التغييرات:
- تغيير `_doctorEmailController` (واحد) إلى `_doctorEmailControllers` (قائمة)
- إضافة UI لإضافة إيميلات دكاترة متعددة
- **إيميل الدكتور الأول إجباري** - يجب إدخاله
- إيميلات الدكاترة الإضافية اختيارية
- إيميلات السكرتيرة كلها اختيارية
- أزرار إضافة/حذف لكل نوع من الإيميلات

#### مثال UI:
```dart
// إيميلات الدكاترة (صلاحيات كاملة)
Container(
  decoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      // إيميل الدكتور الأساسي * (إجباري)
      TextFormField(
        validator: (value) {
          if (index == 0 && (value == null || value.isEmpty)) {
            return 'يجب إدخال إيميل الدكتور الأساسي';
          }
        },
      ),
      // زر إضافة إيميل دكتور إضافي
      TextButton.icon(
        icon: Icon(Icons.add_circle_outline),
        label: Text('إضافة إيميل دكتور إضافي'),
      ),
    ],
  ),
)
```

### 3. إضافة إدارة الإيميلات في صفحة تعديل العيادة
**الملف:** `lib/features/clinic/presentation/screens/edit_clinic_screen.dart`

#### المميزات الجديدة:
- إضافة `_doctorEmailControllers` و `_secretaryEmailControllers`
- Initialize من بيانات العيادة الحالية
- UI sections منفصلة لإيميلات الدكاترة وإيميلات السكرتيرة
- إمكانية إضافة/حذف/تعديل الإيميلات
- حفظ التغييرات في Firestore عند Update

#### التحديثات في _updateClinic():
```dart
await FirebaseFirestore.instance
    .collection('clinics')
    .doc(widget.clinic.id)
    .update({
  'doctorEmails': _doctorEmailControllers
      .map((c) => c.text.trim())
      .where((email) => email.isNotEmpty)
      .toList(),
  'secretaryEmails': _secretaryEmailControllers
      .map((c) => c.text.trim())
      .where((email) => email.isNotEmpty)
      .toList(),
  // ... باقي الحقول
});
```

### 4. تقييد صلاحية تعديل بيانات العيادة للدكتور فقط
**الملف:** `lib/features/clinic/presentation/screens/clinic_control_page.dart`

#### التغييرات:
1. **تحديث isDoctor check:**
```dart
// قبل
final bool isDoctor = _clinic!.doctorEmail != null && 
                      currentUserEmail != null &&
                      _clinic!.doctorEmail!.toLowerCase() == currentUserEmail.toLowerCase();

// بعد
final bool isDoctor = currentUserEmail != null &&
                      _clinic!.doctorEmails.any((email) => 
                          email.toLowerCase() == currentUserEmail!.toLowerCase());
```

2. **إخفاء زر التعديل من السكرتيرة:**
```dart
// Edit Clinic (Doctor only)
if (isDoctor) // فقط الدكتور يمكنه تعديل بيانات العيادة
  _buildControlButton(
    icon: Icons.edit,
    title: 'تعديل بيانات العيادة',
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditClinicScreen(clinic: _clinic!),
        ),
      );
    },
  ),
```

### 5. تحديثات إضافية

#### bookings_management_screen.dart
تحديث `_isDoctorUser()` ليستخدم `doctorEmails` بدلاً من `doctorEmail`:
```dart
final doctorEmails = clinicData['doctorEmails'] != null
    ? List<String>.from(clinicData['doctorEmails'])
    : (clinicData['doctorEmail'] != null ? [clinicData['doctorEmail']] : []);

return doctorEmails.any((email) => 
       email.toLowerCase() == userEmail.toLowerCase());
```

#### clinic_approval_screen.dart
تحديث عرض إيميل الدكتور ليعرض الإيميل الأول من القائمة:
```dart
_buildInfoRow(Icons.email, 
    (clinicData['doctorEmails'] as List<dynamic>?)?.isNotEmpty == true
        ? (clinicData['doctorEmails'] as List<dynamic>).first.toString()
        : clinicData['doctorEmail'] ?? 'لا يوجد'),
```

#### edit_place_details_screen.dart
تحديث `_getEmailField()` للاشتراكات:
```dart
case PlaceType.clinic:
  return 'doctorEmails'; // بدلاً من 'doctorEmail'
```

## الصلاحيات والأدوار

### الدكاترة (Doctor Emails):
**الصلاحيات الكاملة:**
- ✅ متابعة المرضى
- ✅ إدارة الحجوزات
- ✅ تعديل بيانات العيادة
- ✅ إدارة الإيميلات (إضافة/حذف دكاترة وسكرتيرة)
- ✅ تفعيل/إخفاء العيادة

### السكرتيرة (Secretary Emails):
**الصلاحيات المحدودة:**
- ✅ إدارة الحجوزات فقط
- ❌ متابعة المرضى
- ❌ تعديل بيانات العيادة
- ❌ إدارة الإيميلات

## قواعد التحقق (Validation Rules)

### في صفحة الإضافة (add_clinic_screen):
1. **إيميل الدكتور الأول:** إجباري ويجب أن يحتوي على @
2. **إيميلات دكاترة إضافية:** اختيارية، إذا أُدخلت يجب أن تكون صحيحة
3. **إيميلات السكرتيرة:** اختيارية بالكامل، إذا أُدخلت يجب أن تكون صحيحة

### في صفحة التعديل (edit_clinic_screen):
- نفس قواعد صفحة الإضافة
- يمكن حذف جميع الإيميلات الإضافية
- لا يمكن حذف إيميل الدكتور الأول (يمكن تعديله فقط)

## التوافق مع البيانات القديمة

### في ClinicModel.fromFirestore():
```dart
doctorEmails: data['doctorEmails'] != null
    ? List<String>.from(data['doctorEmails'])
    : (data['doctorEmail'] != null ? [data['doctorEmail']] : []),
```

هذا يضمن:
- قراءة `doctorEmails` إذا كانت موجودة (البيانات الجديدة)
- تحويل `doctorEmail` القديم إلى array إذا كان موجوداً (البيانات القديمة)
- إرجاع array فارغ إذا لم يكن هناك إيميلات

## الملفات المعدلة

### Core Files:
1. `lib/features/clinic/data/models/clinic_model.dart`
2. `lib/features/admin/presentation/screens/add_clinic_screen.dart`
3. `lib/features/clinic/presentation/screens/edit_clinic_screen.dart`
4. `lib/features/clinic/presentation/screens/clinic_control_page.dart`

### Supporting Files:
5. `lib/features/clinic/presentation/screens/bookings_management_screen.dart`
6. `lib/features/admin/presentation/screens/clinic_approval_screen.dart`
7. `lib/features/subscriptions/presentation/screens/edit_place_details_screen.dart`

## الاختبار المطلوب

### سيناريوهات الاختبار:
1. ✅ إضافة عيادة جديدة بإيميل دكتور واحد فقط
2. ✅ إضافة عيادة بإيميلات دكاترة متعددة
3. ✅ إضافة عيادة بدكاترة وسكرتيرة
4. ✅ محاولة إضافة عيادة بدون إيميل دكتور (يجب أن يفشل)
5. ✅ تعديل إيميلات العيادة من قبل الدكتور
6. ✅ محاولة تعديل العيادة من قبل السكرتيرة (يجب ألا يظهر الزر)
7. ✅ التحقق من أن الصلاحيات تعمل بشكل صحيح
8. ✅ التحقق من التوافق مع البيانات القديمة

## ملاحظات مهمة

1. **الأمان:** يتم التحقق من الصلاحيات على مستوى UI فقط، يُنصح بإضافة قواعد أمان في Firestore Rules
2. **التوافق:** جميع التحديثات متوافقة مع البيانات القديمة
3. **التحقق من الإيميل:** يتم فقط التحقق البسيط من وجود @ في الإيميل
4. **Case Sensitivity:** يتم مقارنة الإيميلات بدون تحسس لحالة الأحرف (toLowerCase)

## Firestore Structure الجديدة

```json
{
  "clinics": {
    "clinicId": {
      "doctorName": "د. أحمد محمد",
      "doctorEmails": ["doctor1@example.com", "doctor2@example.com"],
      "secretaryEmails": ["secretary1@example.com", "secretary2@example.com"],
      "authEmails": ["doctor1@example.com", "doctor2@example.com", "secretary1@example.com", "secretary2@example.com"],
      "department": "pediatrics",
      "phone": "01234567890",
      "address": "123 شارع الجمهورية",
      ...
    }
  }
}
```

## الخلاصة

هذا التحديث يوفر:
- ✅ مرونة أكبر في إدارة فريق العيادة
- ✅ دعم لأكثر من دكتور في نفس العيادة
- ✅ صلاحيات واضحة ومحددة لكل دور
- ✅ واجهة مستخدم سهلة لإدارة الإيميلات
- ✅ حماية بيانات العيادة من التعديل غير المصرح به
- ✅ توافق كامل مع البيانات القديمة
