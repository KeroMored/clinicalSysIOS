# تعليمات بناء App Bundle للـ Release

## المشكلة الحالية:
في مشكلة SSL certificate مع Gradle على Windows بتمنع الـ build من Flutter CLI.

## الحل البديل - استخدام Android Studio:

### الطريقة 1: من Android Studio
1. افتح المشروع في Android Studio
2. من القائمة اختار: **Build** → **Flutter** → **Build App Bundle (Release)**
3. أو من Terminal داخل Android Studio:
   ```
   flutter build appbundle --release
   ```

### الطريقة 2: حل مشكلة SSL
1. افتح Android Studio
2. File → Settings → Appearance & Behavior → System Settings → HTTP Proxy
3. اختار "No proxy" أو تأكد من الإعدادات
4. جرب تاني:
   ```
   flutter build appbundle --release
   ```

### الطريقة 3: استخدام Gradle مباشرة
```bash
cd android
.\gradlew clean
.\gradlew bundleRelease
```

## مكان الملف بعد الـ Build:
```
build/app/outputs/bundle/release/app-release.aab
```

## ملاحظات:
- تأكد إن ملف `android/key.properties` موجود وصحيح
- تأكد إن الـ keystore file موجود في المكان الصحيح
- الإصدار الحالي: 1.0.0+42
