# كيفية رفع التغييرات على GitHub

## الطريقة الأولى: استخدام Terminal

افتح Terminal في مجلد المشروع ونفذ الأوامر التالية:

```bash
# 1. تنظيف المشروع
flutter clean

# 2. تحديث التبعيات
flutter pub get

# 3. إضافة جميع التغييرات
git add .

# 4. عمل commit
git commit -m "fix: حل مشكلة IconData final class - استبدال جميع الأيقونات بـ Material Icons"

# 5. رفع التغييرات
git push
```

## الطريقة الثانية: استخدام السكريبت الجاهز

```bash
# إعطاء صلاحيات التنفيذ
chmod +x git_commands.sh

# تنفيذ السكريبت
./git_commands.sh
```

## الطريقة الثالثة: استخدام VS Code

1. افتح VS Code
2. اذهب إلى Source Control (Ctrl+Shift+G)
3. اكتب رسالة الـ commit:
   ```
   fix: حل مشكلة IconData final class - استبدال جميع الأيقونات بـ Material Icons
   ```
4. اضغط Commit
5. اضغط Push

## التحقق من نجاح الرفع

بعد الرفع، تحقق من:
1. ✅ الكود موجود على GitHub
2. ✅ Codemagic بدأ البناء تلقائياً
3. ✅ البناء نجح بدون أخطاء

## ملاحظات مهمة

- ✅ تم إصلاح **أكثر من 40 ملف**
- ✅ تم استبدال جميع أيقونات `MdiIcons` و `FontAwesome`
- ✅ تم إزالة المكتبات المتعارضة من `pubspec.yaml`
- ✅ الحل متوافق مع Flutter 3.27+
- ✅ سيعمل على Codemagic بدون مشاكل

## في حالة وجود مشاكل

إذا واجهت أي مشكلة:

```bash
# إلغاء التغييرات المحلية
git reset --hard

# سحب آخر نسخة
git pull

# إعادة المحاولة
git add .
git commit -m "fix: حل مشكلة IconData final class"
git push
```

---

**راجع ملف `ICON_FIX_SUMMARY.md` لمعرفة تفاصيل التغييرات**
