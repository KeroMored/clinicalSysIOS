# ملوي كير - MallawyC are 🏥

تطبيق صحي شامل لإدارة الخدمات الطبية في مدينة ملوي

## 📱 عن التطبيق

**ملوي كير** هو تطبيق صحي متكامل يوفر:
- 🏥 إدارة العيادات والمستشفيات
- 💊 إدارة الصيدليات
- 🔬 إدارة المختبرات الطبية
- 👨‍⚕️ حجز المواعيد مع الأطباء
- 📊 متابعة السجلات الصحية
- 🔔 إشعارات وتنبيهات طبية

---

## 🔄 Rebranding في تقدم

> **ملاحظة مهمة:** هذا المشروع في مرحلة تحويل الهوية (Rebranding)

### الهوية الجديدة
- **اسم التطبيق:** ملوي كير - MallawyC are
- **Bundle ID (iOS):** `com.mallawy.mallawycare`
- **Package (Android):** `com.mallawy.mallawycare`
- **Version:** 1.0.0+1

### 📚 أدلة Rebranding

إذا كنت تعمل على تحويل التطبيق، ابدأ من هنا:

1. **[START_HERE.md](START_HERE.md)** - نقطة البداية الرئيسية
2. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - مرجع سريع
3. **[FIREBASE_SETUP_CHECKLIST.md](FIREBASE_SETUP_CHECKLIST.md)** - قائمة تحقق Firebase
4. **[REBRAND_GUIDE.md](REBRAND_GUIDE.md)** - الدليل الشامل
5. **[CHANGES_MADE.md](CHANGES_MADE.md)** - التعديلات المنفذة

---

## 🚀 البدء

### المتطلبات
- Flutter SDK 3.9.0 أو أحدث
- Dart 3.9.0 أو أحدث
- Xcode 15+ (للـ iOS)
- Android Studio (للـ Android)
- CocoaPods (للـ iOS)

### التثبيت

```bash
# استنساخ المشروع
git clone https://github.com/KeroMored/clinicalSysIOS.git
cd clinicalSys-main

# تثبيت الحزم
flutter pub get

# للـ iOS
cd ios
pod install
cd ..

# تشغيل التطبيق
flutter run
```

---

## 🏗️ بنية المشروع

```
lib/
├── core/              # الوظائف الأساسية المشتركة
├── features/          # Features المنظمة حسب Clean Architecture
│   ├── auth/         # Authentication
│   ├── clinic/       # إدارة العيادات
│   ├── pharmacy/     # إدارة الصيدليات
│   ├── laboratory/   # إدارة المختبرات
│   └── ...
└── main.dart         # نقطة بداية التطبيق
```

---

## 🔧 التكوين

### Firebase
يحتاج التطبيق إلى Firebase للعمل:
- Authentication
- Cloud Firestore
- Cloud Storage
- Cloud Messaging (FCM)

راجع **[FIREBASE_SETUP_CHECKLIST.md](FIREBASE_SETUP_CHECKLIST.md)** للتفاصيل.

### ملفات التكوين
- `android/app/google-services.json` - تكوين Firebase للأندرويد
- `ios/Runner/GoogleService-Info.plist` - تكوين Firebase للـ iOS
- `ios/Runner/Info.plist` - تكوين التطبيق للـ iOS

---

## 📦 الحزم الرئيسية

- **State Management:** flutter_bloc
- **Backend:** Firebase (Auth, Firestore, Storage, Messaging)
- **UI:** Google Fonts, Flutter SVG
- **Maps & Location:** google_maps_flutter, geolocator
- **Authentication:** Google Sign-In, Apple Sign-In
- **Notifications:** firebase_messaging, flutter_local_notifications
- **Media:** image_picker, video_player, youtube_player_flutter

---

## 🧪 الاختبار

```bash
# تشغيل الاختبارات
flutter test

# بناء للنشر
flutter build ios --release
flutter build appbundle --release
```

---

## 📱 المنصات المدعومة

- ✅ iOS 14.0+
- ✅ Android API 24+
- ⚠️ Web (قيد التطوير)
- ⚠️ macOS (قيد التطوير)
- ⚠️ Windows (قيد التطوير)

---

## 🔐 الأمان والخصوصية

- تشفير البيانات الحساسة باستخدام `flutter_secure_storage`
- مصادقة ثنائية العوامل
- Firebase Security Rules محدّثة
- لا يتم تخزين معلومات طبية حساسة محلياً

---

## 🤝 المساهمة

هذا مشروع خاص. للمساهمة:
1. Fork المشروع
2. أنشئ branch جديد (`git checkout -b feature/amazing-feature`)
3. Commit تعديلاتك (`git commit -m 'Add amazing feature'`)
4. Push للـ branch (`git push origin feature/amazing-feature`)
5. افتح Pull Request

---

## 📄 الترخيص

هذا المشروع محمي بحقوق الطبع والنشر. جميع الحقوق محفوظة.

---

## 📞 الاتصال

- **المطور:** George Sadek
- **GitHub:** [KeroMored](https://github.com/KeroMored)
- **Repository:** [clinicalSysIOS](https://github.com/KeroMored/clinicalSysIOS)

---

## 📝 ملاحظات إضافية

### للمطورين الجدد:
1. ابدأ بقراءة **[START_HERE.md](START_HERE.md)**
2. راجع بنية المشروع في `lib/`
3. اتبع أدلة Rebranding إذا كنت تعمل على تحويل الهوية

### للنشر:
1. تأكد من إكمال خطوات Rebranding
2. راجع **[FIREBASE_SETUP_CHECKLIST.md](FIREBASE_SETUP_CHECKLIST.md)**
3. اختبر على أجهزة حقيقية
4. Build للنشر واتبع إرشادات App Store / Play Store

---

## 🎉 شكر خاص

شكراً لكل من ساهم في تطوير هذا التطبيق!

---

**آخر تحديث:** 11 يونيو 2026  
**الإصدار:** 1.0.0+1
