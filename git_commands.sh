#!/bin/bash

# تنظيف المشروع
echo "🧹 تنظيف المشروع..."
flutter clean

# تحديث التبعيات
echo "📦 تحديث التبعيات..."
flutter pub get

# إضافة جميع التغييرات
echo "➕ إضافة التغييرات إلى Git..."
git add .

# عمل commit
echo "💾 حفظ التغييرات..."
git commit -m "fix: حل مشكلة IconData final class - استبدال جميع أيقونات font_awesome و material_design_icons بـ Material Icons

- إزالة font_awesome_flutter من pubspec.yaml
- إزالة material_design_icons_flutter من pubspec.yaml
- استبدال جميع MdiIcons.whatsapp بـ Icons.chat
- استبدال أيقونات الأقسام الطبية في clinic_home_page.dart
- إزالة جميع imports لـ material_design_icons_flutter
- حذف مجلد patches
- الحل متوافق مع Flutter 3.27+ حيث IconData أصبح final class

التغييرات شملت أكثر من 40 ملف في:
- features/clinic
- features/pharmacy
- features/laboratory
- features/radiology
- features/rehabilitation
- features/admin
- features/gym
- features/nursing
- features/medicine_requests
- features/medicine_offers
- features/delivery
- features/home
- core/services"

# رفع التغييرات
echo "🚀 رفع التغييرات إلى GitHub..."
git push

echo "✅ تم بنجاح!"
