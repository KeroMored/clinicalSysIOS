# تحديث نظام أرقام الهواتف المتعددة 📱

## نظرة عامة

تم تحديث النظام لدعم إضافة أرقام هواتف متعددة للعيادات والصيدليات، مع إمكانية عرضها في الواجهة بأزرار مرقمة.

---

## التغييرات الرئيسية

### 1. تحديث النماذج (Models) ✅

#### ClinicModel
```dart
// قبل
final String phone;

// بعد
final List<String> phones;
```

#### PharmacyModel
```dart
// قبل
final String phone;

// بعد
final List<String> phones;
```

**التوافق مع البيانات القديمة:**
- تم إضافة كود في `fromFirestore` و `fromJson` للتحويل التلقائي من `phone` القديم إلى `phones` الجديد
- البيانات القديمة تُحوّل تلقائياً إلى قائمة تحتوي على رقم واحد

---

### 2. صفحات إضافة العيادات والصيدليات ✅

#### الملفات المحدثة:
- `add_clinic_screen.dart`
- `add_pharmacy_screen.dart`

#### المميزات:
- ✅ واجهة ديناميكية لإضافة/حذف أرقام الهواتف
- ✅ الرقم الأول إلزامي (*)
- ✅ الأرقام الإضافية اختيارية
- ✅ حد أقصى 5 أرقام
- ✅ أزرار إضافة/حذف مع تصميم عصري

```dart
// Controllers
final List<TextEditingController> _phoneControllers = [TextEditingController()];

// UI
Container(
  child: Column(
    children: [
      Row(
        children: [
          Text('أرقام الهاتف'),
          if (_phoneControllers.length < 5)
            TextButton.icon(
              onPressed: () => setState(() => _phoneControllers.add(TextEditingController())),
              icon: Icon(Icons.add),
              label: Text('إضافة رقم'),
            ),
        ],
      ),
      ...List.generate(_phoneControllers.length, (index) {
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneControllers[index],
                decoration: InputDecoration(
                  labelText: index == 0 ? 'رقم الهاتف الأساسي *' : 'رقم ${index + 1}',
                ),
                validator: index == 0 ? (v) => v?.isEmpty ?? true ? 'مطلوب' : null : null,
              ),
            ),
            if (index > 0)
              IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => setState(() {
                  _phoneControllers[index].dispose();
                  _phoneControllers.removeAt(index);
                }),
              ),
          ],
        );
      }),
    ],
  ),
)
```

---

### 3. صفحات تعديل العيادات والصيدليات ✅

#### الملفات المحدثة:
- `edit_clinic_screen.dart`
- `edit_pharmacy_screen.dart`

#### التغييرات:
- ✅ تهيئة المتحكمات من البيانات الموجودة
- ✅ نفس واجهة الإضافة/حذف الديناميكية
- ✅ حفظ جميع الأرقام في Firestore

```dart
// Initialize from existing data
_phoneControllers = widget.clinic.phones.isNotEmpty
    ? widget.clinic.phones.map((phone) => TextEditingController(text: phone)).toList()
    : [TextEditingController()];

// Save
await FirebaseFirestore.instance
    .collection('clinics')
    .doc(widget.clinic.id)
    .update({
      'phones': _phoneControllers
          .map((c) => c.text.trim())
          .where((phone) => phone.isNotEmpty)
          .toList(),
    });
```

---

### 4. صفحات عرض التفاصيل ✅

#### الملفات المحدثة:
- `clinic_details_screen.dart`
- `pharmacy_details_screen.dart`

#### المميزات الجديدة:
- ✅ عرض جميع أرقام الهواتف
- ✅ أزرار مرقمة لكل رقم
- ✅ عرض الرقم على الزر نفسه
- ✅ تصميم موحد مع الواتساب

```dart
// Multiple Phone Buttons
if (clinic.phones.isNotEmpty) ...[
  ...List.generate(clinic.phones.length, (index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: () => _makePhoneCall(context, clinic.phones[index]),
        icon: const Icon(Icons.phone),
        label: Text(
          clinic.phones.length > 1 
              ? 'رقم ${index + 1}: ${clinic.phones[index]}'
              : 'اتصال: ${clinic.phones[index]}',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }),
],
```

#### تحديث دالة المكالمات:
```dart
// قبل
Future<void> _makePhoneCall(BuildContext context) async {
  final Uri launchUri = Uri(scheme: 'tel', path: _clinic.phone);
  await launchUrl(launchUri);
}

// بعد
Future<void> _makePhoneCall(BuildContext context, String phone) async {
  final Uri launchUri = Uri(scheme: 'tel', path: phone);
  await launchUrl(launchUri);
}
```

---

### 5. صفحات التحكم (Control Pages) ✅

#### الملفات المحدثة:
- `clinic_control_page.dart`
- `pharmacy_control_page.dart`

#### التغييرات:
- ✅ استخدام `phones` بدلاً من `phone`
- ✅ عرض جميع الأرقام مفصولة بفاصلة

```dart
_buildInfoRow(
  icon: Icons.phone_rounded,
  label: 'رقم الهاتف',
  value: pharmacy.phones.isNotEmpty ? pharmacy.phones.join(', ') : 'غير متوفر',
  color: const Color(0xFF3B82F6),
),
```

---

### 6. ملفات أخرى محدثة ✅

#### offer_card.dart
```dart
// استخدام أول رقم متاح من القائمة
if (pharmacy.phones.isEmpty) {
  // show error
}
final Uri launchUri = Uri(scheme: 'tel', path: pharmacy.phones[0]);
```

#### medicine_offer_card.dart
```dart
// نفس التعديل
if (pharmacy.phones.isNotEmpty) {
  final Uri launchUri = Uri(scheme: 'tel', path: pharmacy.phones[0]);
  await launchUrl(launchUri);
}
```

#### admin_repository.dart
```dart
// تحويل الرقم الواحد من PharmacyRequestModel إلى قائمة
final pharmacyData = PharmacyModel(
  phones: [request.phone],
  // ...
);
```

---

## التوافق مع البيانات القديمة

### في Models:
```dart
// ClinicModel.fromFirestore
phones: data['phones'] != null
    ? List<String>.from(data['phones'])
    : (data['phone'] != null ? [data['phone']] : [])

// PharmacyModel.fromFirestore
phones: json['phones'] != null
    ? List<String>.from(json['phones'])
    : (json['phone'] != null ? [json['phone']] : [])
```

### النتيجة:
- ✅ العيادات/الصيدليات القديمة تُحمّل تلقائياً
- ✅ الرقم القديم يتحول إلى قائمة من رقم واحد
- ✅ لا حاجة لتحديث بيانات يدوي

---

## الملفات المحدثة (جميعها ✅)

### Models:
- ✅ `lib/features/clinic/data/models/clinic_model.dart`
- ✅ `lib/features/pharmacy/data/models/pharmacy_model.dart`

### Add Screens:
- ✅ `lib/features/admin/presentation/screens/add_clinic_screen.dart`
- ✅ `lib/features/admin/presentation/screens/add_pharmacy_screen.dart`

### Edit Screens:
- ✅ `lib/features/clinic/presentation/screens/edit_clinic_screen.dart`
- ✅ `lib/features/pharmacy/presentation/screens/edit_pharmacy_screen.dart`

### Details Screens:
- ✅ `lib/features/clinic/presentation/screens/clinic_details_screen.dart`
- ✅ `lib/features/pharmacy/presentation/screens/pharmacy_details_screen.dart`

### Control Pages:
- ✅ `lib/features/clinic/presentation/screens/clinic_control_page.dart`
- ✅ `lib/features/pharmacy/presentation/screens/pharmacy_control_page.dart`

### Other:
- ✅ `lib/features/pharmacy/presentation/screens/offer_card.dart`
- ✅ `lib/features/medicine_offers/presentation/widgets/medicine_offer_card.dart`
- ✅ `lib/features/admin/data/repositories/admin_repository.dart`

---

## الاختبار

### للإدمن (عند إضافة عيادة/صيدلية جديدة):
1. افتح صفحة إضافة عيادة/صيدلية
2. أدخل الرقم الأساسي
3. اضغط "إضافة رقم" لإضافة أرقام إضافية
4. أدخل حتى 5 أرقام
5. احفظ البيانات

### للمستخدمين (عرض التفاصيل):
1. افتح صفحة تفاصيل العيادة/الصيدلية
2. ستجد أزرار مرقمة لكل رقم هاتف
3. اضغط على أي زر للاتصال بالرقم المطلوب

### للمالكين (تعديل البيانات):
1. افتح صفحة التعديل
2. يمكنك إضافة/حذف أرقام
3. الرقم الأول غير قابل للحذف
4. احفظ التعديلات

---

## ملاحظات مهمة

### واجهة المستخدم:
- ✅ الرقم الأول دائماً إلزامي
- ✅ الأرقام الإضافية اختيارية
- ✅ حد أقصى 5 أرقام
- ✅ أزرار مرقمة لسهولة التمييز
- ✅ عرض الرقم على الزر نفسه

### التخزين:
- ✅ يُحفظ في Firestore كـ `Array`
- ✅ الأرقام الفارغة تُستبعد تلقائياً
- ✅ التوافق مع البيانات القديمة

### الأداء:
- ✅ لا يوجد تأثير على الأداء
- ✅ التحميل سريع (Array صغير)

---

## الخلاصة

✅ **جميع التحديثات تمت بنجاح**

- نظام أرقام هواتف متعددة للعيادات والصيدليات
- واجهة مستخدم سهلة ومرنة
- توافق كامل مع البيانات القديمة
- تصميم عصري ومتجاوب
- أزرار مرقمة لسهولة التمييز

---

**تاريخ التحديث:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**حالة الأخطاء:** ✅ لا توجد أخطاء
**الحالة:** 🟢 جاهز للإنتاج
