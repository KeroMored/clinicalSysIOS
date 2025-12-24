# دليل التصميم السريع - نظام الألوان والاستخدام

## Quick Design Reference Guide

---

## 🎨 الألوان والتدرجات

### استخدم هذه التدرجات حسب الخدمة

```dart
import '../../../core/theme/app_theme.dart';
```

| الخدمة | التدرج | المثال |
|--------|--------|--------|
| **عام** | `AppTheme.primaryGradient` | الصفحة الرئيسية، أزرار عامة |
| **العيادات** | `AppTheme.clinicGradient` | 🔵 أزرق-بنفسجي |
| **الصيدليات** | `AppTheme.pharmacyGradient` | 🔷 تيل-سماوي |
| **المعامل** | `AppTheme.laboratoryGradient` | 🟠 برتقالي-أحمر |
| **الأشعة** | `AppTheme.radiologyGradient` | 🟣 بنفسجي-وردي |
| **التمريض** | `AppTheme.nursingGradient` | 🟢 أخضر |
| **التأهيل** | `AppTheme.rehabilitationGradient` | 💜 بنفسجي فاتح |
| **الأدمن/خروج** | `AppTheme.accentGradient` | 🔴 أحمر مرجاني |

---

## 🔧 أمثلة الاستخدام السريع

### 1. AppBar مع تدرج

```dart
import '../../../core/widgets/gradient_appbar.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: GradientAppBar(
      title: 'الصيدليات',
      gradient: AppTheme.pharmacyGradient, // غيّر حسب الخدمة
    ),
    ...
  );
}
```

### 2. زر مع تدرج

```dart
import '../../../core/widgets/gradient_button.dart';

GradientButton(
  text: 'حفظ',
  icon: Icons.save_rounded,
  gradient: AppTheme.primaryGradient,
  onPressed: () {
    // الإجراء
  },
  isLoading: _isLoading, // اختياري
)
```

### 3. بطاقة حديثة

```dart
import '../../../core/widgets/modern_card.dart';

ModernCard(
  child: Column(
    children: [
      Text('العنوان'),
      Text('المحتوى'),
    ],
  ),
  onTap: () {
    // عند الضغط
  },
)
```

### 4. Container مع تدرج

```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.clinicGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppTheme.primaryColor.withValues(alpha: 0.3),
        blurRadius: 15,
        offset: Offset(0, 8),
      ),
    ],
  ),
  child: ...
)
```

### 5. FloatingActionButton مع تدرج

```dart
FloatingActionButton.extended(
  onPressed: () {},
  label: Text('إضافة'),
  icon: Icon(Icons.add),
  backgroundColor: Colors.transparent, // شفاف
  elevation: 0,
  // ثم لفّه في Container بتدرج:
)

// أو بشكل أفضل:
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.pharmacyGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppTheme.secondaryColor.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text('إضافة', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),
  ),
)
```

---

## 📐 القياسات الموصى بها

```dart
BorderRadius: 12-20 (عادة 16)
Padding: 16-24
Elevation/Blur: 8-15
Icon Size: 24-50
Button Height: 48-56
```

---

## 🎯 نصائح سريعة

1. **استخدم دائماً** `AppTheme.xxxGradient` بدلاً من ألوان مباشرة
2. **أضف ظلال** لكل Container/Card مهم
3. **استخدم** `withValues(alpha: 0.3)` للظلال
4. **اجعل النص أبيض** على التدرجات الملونة
5. **أضف** `borderRadius` لكل عنصر (16 هو الأفضل)

---

## ✅ Checklist للتطبيق على صفحة جديدة

- [ ] استخدمت `GradientAppBar` بدلاً من AppBar عادي
- [ ] استخدمت `GradientButton` للأزرار المهمة
- [ ] لف الـ Cards في `ModernCard`
- [ ] أضفت تدرج الخدمة المناسب
- [ ] أضفت ظلال للعناصر الرئيسية
- [ ] استخدمت `BorderRadius.circular(16)` للعناصر
- [ ] النصوص على التدرجات بيضاء مع shadow

---

**كل شيء جاهز! 🚀**
