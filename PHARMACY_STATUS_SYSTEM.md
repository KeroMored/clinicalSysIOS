# نظام الموافقة على الصيدليات - Status System

## التحديثات المنجزة

### 1. إضافة حقل Status للصيدليات

تم إضافة حقل `status` إلى `PharmacyModel` مع القيم التالية:
- `pending` - في انتظار الموافقة (القيمة الافتراضية)
- `approved` - تمت الموافقة عليها
- `rejected` - تم رفضها

```dart
final String status; // 'pending', 'approved', 'rejected'
```

### 2. آلية عمل النظام

#### الصيدليات الجديدة:
- جميع الصيدليات الجديدة تُنشأ بحالة `pending` افتراضياً
- لا تظهر في قائمة الصيدليات العامة
- تظهر فقط في صفحة الموافقات للأدمن

#### عند الموافقة:
- عندما يوافق الأدمن على صيدلية، تتغير حالتها إلى `approved`
- يتم نقل بيانات الصيدلية من `pharmacy_requests` إلى `pharmacies`
- تصبح مرئية في قائمة الصيدليات العامة

#### عند الإضافة من الأدمن مباشرة:
- الصيدليات التي يضيفها الأدمن تُنشأ مباشرة بحالة `approved`
- تظهر فوراً في قائمة الصيدليات

### 3. التعديلات على الكود

#### PharmacyModel
```dart
// تم إضافة حقل status
final String status;

// في Constructor
this.status = 'pending', // default

// في fromJson
status: json['status'] ?? 'pending',

// في toJson
'status': status,

// في copyWith
String? status,
status: status ?? this.status,
```

#### PharmacyRepository
```dart
// تم تعديل getAllPharmacies لعرض الصيدليات المعتمدة فقط
Future<List<PharmacyModel>> getAllPharmacies() async {
  final snapshot = await _firestore
      .collection('pharmacies')
      .where('status', isEqualTo: 'approved')  // فقط المعتمدة
      .get();
  // ...
}
```

#### AdminRepository
```dart
// عند الموافقة على طلب صيدلية
Future<void> approvePharmacyRequest(String requestId) async {
  // إنشاء الصيدلية بحالة approved
  final pharmacyData = PharmacyModel(
    // ... بيانات الصيدلية
    status: 'approved', // معتمدة
  ).toJson();
  
  await _firestore.collection('pharmacies').add(pharmacyData);
}

// عند إضافة صيدلية مباشرة من الأدمن
Future<void> addPharmacyDirectly(PharmacyRequestModel request) async {
  final pharmacyData = PharmacyModel(
    // ... بيانات الصيدلية
    status: 'approved', // معتمدة مباشرة
  ).toJson();
  
  await _firestore.collection('pharmacies').add(pharmacyData);
}
```

### 4. رفع الصور (Image Upload)

تم إضافة إمكانية رفع صور للصيدلية في صفحة طلب إضافة صيدلية:

#### الحزم المضافة:
```yaml
dependencies:
  image_picker: ^1.0.7
```

#### الميزات:
- ✅ اختيار صور متعددة للصيدلية
- ✅ معاينة الصور المختارة
- ✅ حذف صورة معينة
- ✅ واجهة مستخدم سهلة وجميلة

#### الكود:
```dart
// في AddPharmacyScreen
List<XFile> _selectedImages = [];
final ImagePicker _imagePicker = ImagePicker();

// اختيار الصور
Future<void> _pickImages() async {
  final List<XFile> images = await _imagePicker.pickMultiImage();
  if (images.isNotEmpty) {
    setState(() {
      _selectedImages = images;
    });
  }
}

// حذف صورة
void _removeImage(int index) {
  setState(() {
    _selectedImages.removeAt(index);
  });
}
```

## تدفق العمل الكامل

### للمستخدم العادي:
1. يقدم طلب إضافة صيدلية جديدة
2. الصيدلية تُنشأ بحالة `pending`
3. لا تظهر في قائمة الصيدليات
4. ينتظر موافقة الأدمن

### للأدمن:
1. يدخل إلى صفحة "الموافقة على الصيدليات"
2. يشاهد قائمة الطلبات المعلقة (`pending`)
3. يراجع تفاصيل كل طلب
4. يوافق أو يرفض الطلب
5. عند الموافقة: تُنقل الصيدلية إلى `pharmacies` بحالة `approved`

### إضافة مباشرة من الأدمن:
1. الأدمن يدخل إلى صفحة "إضافة صيدلية"
2. يملأ البيانات ويختار الصور
3. عند الحفظ: تُضاف الصيدلية مباشرة بحالة `approved`
4. تظهر فوراً في قائمة الصيدليات

## الفوائد

✅ **أمان أفضل**: لا يمكن لأي شخص إضافة صيدلية دون موافقة
✅ **تحكم كامل**: الأدمن يراجع كل صيدلية قبل نشرها
✅ **جودة المحتوى**: فحص البيانات والصور قبل العرض
✅ **مرونة**: الأدمن يمكنه إضافة صيدليات مباشرة عند الحاجة
✅ **صور واضحة**: المستخدمون يرون صوراً حقيقية للصيدليات

## ملاحظات مهمة

⚠️ **رفع الصور**: حالياً يتم اختيار الصور فقط. لرفعها إلى Firebase Storage، تحتاج إلى:
1. إضافة كود رفع الصور إلى Firebase Storage
2. الحصول على روابط الصور
3. حفظ الروابط في حقل `images` في PharmacyModel

📱 **الأذونات**: تأكد من إضافة أذونات الكاميرا والمعرض في:
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`

## الخطوات التالية (اختياري)

1. ⬜ إضافة كود رفع الصور إلى Firebase Storage
2. ⬜ إضافة ميزة تعديل بيانات الصيدلية
3. ⬜ إضافة إشعارات للمستخدم عند الموافقة/الرفض
4. ⬜ إضافة إحصائيات للأدمن (عدد الطلبات المعلقة، المقبولة، المرفوضة)
5. ⬜ إضافة نظام مراجعة وتقييم الصيدليات
