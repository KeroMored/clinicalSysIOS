# Clinical System - Android Development

## 📱 تطوير Android فقط

هذا الـ branch مخصص لتطوير الـ Android فقط على Windows.

### البيئة المطلوبة:
- Flutter SDK
- Android Studio
- JDK 17+

### أوامر البناء:

```bash
# Get dependencies
flutter pub get

# Run on Android device/emulator
flutter run

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### ملاحظات مهمة:
- تم حذف مجلدات `ios/` و `macos/` من هذا الـ branch
- للعمل على iOS، استخدم الـ repo المنفصل: https://github.com/KeroMored/clinicalSysIOS
- هذا الـ setup يضمن عدم حدوث conflicts بين iOS و Android

### الـ Firebase Configuration:
- Android: `google-services.json` موجود في `android/app/`
- Bundle ID: `com.mored.clinicalsystem`

### الـ Branches:
- `android-only` - للتطوير على Windows (Android فقط)
- `updates` - الـ branch القديم (يحتوي على iOS و Android)
