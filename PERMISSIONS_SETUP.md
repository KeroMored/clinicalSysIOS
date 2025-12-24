# إعداد أذونات الكاميرا والمعرض - Image Picker Permissions

## الحل البسيط ✅

تم استخدام `image_picker` مباشرة بدون الحاجة لـ `permission_handler`.
حزمة `image_picker` تتعامل مع الأذونات تلقائياً!

## الأذونات المضافة

### Android (AndroidManifest.xml)
تم إضافة الأذونات التالية في `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

**ملاحظات:**
- `READ_MEDIA_IMAGES` مطلوب لـ Android 13+ (API 33+)
- `WRITE_EXTERNAL_STORAGE` فقط حتى Android 12 (API 32)
- `CAMERA` لالتقاط الصور مباشرة
- `READ_EXTERNAL_STORAGE` للوصول إلى المعرض

### iOS (Info.plist)
تم إضافة المفاتيح التالية في `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>نحتاج إلى الوصول إلى الكاميرا لالتقاط صور الصيدلية</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>نحتاج إلى الوصول إلى معرض الصور لاختيار صور الصيدلية</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>نحتاج إلى الوصول إلى معرض الصور لحفظ الصور</string>
```

## الحزم المستخدمة

### 1. image_picker: ^1.0.7
- لاختيار الصور من المعرض
- لالتقاط صور من الكاميرا
- يدعم اختيار صور متعددة

### 2. permission_handler: ^11.3.0
- لإدارة أذونات التطبيق بشكل برمجي
- طلب الأذونات في وقت التشغيل
- التحقق من حالة الأذونات
- فتح إعدادات التطبيق

## آلية عمل الأذونات

### في add_pharmacy_screen.dart

```dart
Future<void> _pickImages() async {
  // 1. التحقق من نظام التشغيل
  if (Platform.isAndroid) {
    // للأندرويد 13+
    status = await Permission.photos.request();
    // Fallback للنسخ القديمة
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
  } else {
    // لـ iOS
    status = await Permission.photos.request();
  }

  // 2. التعامل مع النتيجة
  if (status.isGranted || status.isLimited) {
    // فتح المعرض
    final images = await _imagePicker.pickMultiImage();
  } else if (status.isPermanentlyDenied) {
    // عرض حوار لفتح الإعدادات
    showDialog(...);
  } else {
    // الإذن مرفوض
    showSnackBar('تم رفض الإذن');
  }
}
```

## حالات الأذونات

### 1. **Granted** (مسموح)
- المستخدم منح الإذن
- يمكن الوصول إلى المعرض/الكاميرا

### 2. **Denied** (مرفوض)
- المستخدم رفض الإذن مؤقتاً
- يمكن طلب الإذن مرة أخرى

### 3. **PermanentlyDenied** (مرفوض نهائياً)
- المستخدم رفض الإذن وحدد "عدم السؤال مجدداً"
- يجب فتح إعدادات التطبيق يدوياً
- يتم عرض حوار مع زر "فتح الإعدادات"

### 4. **Limited** (محدود - iOS فقط)
- المستخدم منح إذن محدود لبعض الصور فقط
- يعامل كـ Granted

## تجربة المستخدم

### السيناريو 1: أول مرة
1. المستخدم يضغط "اختر صور"
2. يظهر طلب إذن من النظام
3. المستخدم يوافق → يفتح المعرض

### السيناريو 2: الإذن مرفوض نهائياً
1. المستخدم يضغط "اختر صور"
2. يظهر حوار من التطبيق:
   - "يجب السماح بالوصول إلى المعرض..."
   - زر "إلغاء"
   - زر "فتح الإعدادات"
3. عند الضغط "فتح الإعدادات" → يفتح إعدادات التطبيق
4. المستخدم يفعل الإذن يدوياً

### السيناريو 3: الإذن مرفوض مؤقتاً
1. المستخدم يضغط "اختر صور"
2. يظهر Snackbar: "تم رفض الإذن"
3. يمكن المحاولة مرة أخرى

## الاختبار

### Android
1. قم بتشغيل التطبيق على Android 13+ أو أقل
2. اضغط "اختر صور" في صفحة إضافة صيدلية
3. تحقق من ظهور طلب الإذن
4. جرب السيناريوهات المختلفة (قبول، رفض، رفض نهائي)

### iOS
1. قم بتشغيل التطبيق على iOS Simulator أو جهاز حقيقي
2. اضغط "اختر صور"
3. تحقق من ظهور طلب الإذن مع الرسالة العربية
4. جرب السيناريوهات المختلفة

## استكشاف الأخطاء

### المشكلة: "لا يفتح المعرض"
**الحل:**
1. تأكد من إضافة الأذونات في AndroidManifest.xml
2. تأكد من إضافة المفاتيح في Info.plist
3. قم بعمل Clean Build:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### المشكلة: "الإذن مرفوض دائماً"
**الحل:**
1. إلغاء تثبيت التطبيق
2. إعادة التثبيت
3. أو فتح الإعدادات يدوياً

### المشكلة: "iOS لا يظهر طلب الإذن"
**الحل:**
1. تأكد من وجود المفاتيح في Info.plist
2. تأكد من كتابة الرسائل بشكل صحيح
3. أعد تشغيل التطبيق بعد تعديل Info.plist

## ملاحظات مهمة

⚠️ **Android 13+**: يجب استخدام `READ_MEDIA_IMAGES` بدلاً من `READ_EXTERNAL_STORAGE`

⚠️ **iOS**: يجب إضافة Usage Descriptions وإلا سيتم رفض التطبيق من App Store

✅ **Best Practice**: دائماً اشرح للمستخدم لماذا تحتاج الإذن قبل طلبه

✅ **UX**: وفر خيار "فتح الإعدادات" عندما يكون الإذن مرفوضاً نهائياً
