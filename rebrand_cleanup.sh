#!/bin/bash

# Script لتنظيف المشروع قبل إعادة البناء بالهوية الجديدة
# ملوي كير - MallawyC are Rebranding Script

echo "🚀 بدء عملية التنظيف للتطبيق الجديد..."

# تنظيف build cache
echo "🧹 حذف ملفات البناء المؤقتة..."
rm -rf build/
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

echo "✅ تم حذف الملفات المؤقتة"

# تنظيف iOS
echo "🍎 تنظيف مشروع iOS..."
cd ios
if [ -f "Podfile.lock" ]; then
    pod deintegrate
fi
pod cache clean --all
echo "✅ تم تنظيف iOS"

cd ..

# تنظيف Flutter
echo "🎯 تنظيف Flutter..."
flutter clean
flutter pub get

echo ""
echo "✅ تمت عملية التنظيف بنجاح!"
echo ""
echo "⚠️  الخطوات التالية:"
echo "1. قم بتحديث ملفات Firebase:"
echo "   - android/app/google-services.json"
echo "   - ios/Runner/GoogleService-Info.plist"
echo ""
echo "2. قم بتحديث Bundle ID في Xcode:"
echo "   - افتح: ios/Runner.xcworkspace"
echo "   - غيّر Bundle Identifier إلى: com.mallawy.mallawycare"
echo ""
echo "3. شغّل الأوامر التالية:"
echo "   cd ios && pod install && cd .."
echo "   dart run flutter_launcher_icons"
echo "   dart run flutter_native_splash:create"
echo ""
echo "4. اختبر التطبيق:"
echo "   flutter run -d ios"
echo "   flutter run -d android"
echo ""
echo "🎉 جاهز للبدء!"
