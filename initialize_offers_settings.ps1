# ===============================================
# إنشاء مستند إعدادات العروض في Firestore
# ===============================================
# هذا السكريبت ينشئ app_control/offers_settings
# مع القيمة الافتراضية showViewsCount = false
# ===============================================

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  إنشاء إعدادات العروض في Firestore  " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# تشغيل flutter run لتنفيذ الكود
Write-Host "[1] جاري إنشاء المستند..." -ForegroundColor Yellow

$code = @"
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // الاتصال بـ Firestore
    final firestore = FirebaseFirestore.instance;
    
    // التحقق من وجود المستند
    final doc = await firestore
        .collection('app_control')
        .doc('offers_settings')
        .get();
    
    if (doc.exists) {
      print('✅ المستند موجود بالفعل');
      print('   القيمة الحالية: showViewsCount = \${doc.data()?['showViewsCount']}');
    } else {
      // إنشاء المستند
      await firestore
          .collection('app_control')
          .doc('offers_settings')
          .set({
        'showViewsCount': false,  // مخفي بشكل افتراضي
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ تم إنشاء المستند بنجاح');
      print('   showViewsCount = false (مخفي)');
    }
  } catch (e) {
    print('❌ خطأ: \$e');
  }
}
"@

# حفظ الكود في ملف مؤقت
$tempFile = "temp_init_settings.dart"
$code | Out-File -FilePath $tempFile -Encoding UTF8

Write-Host "[2] تشغيل الكود..." -ForegroundColor Yellow

# تشغيل dart
dart run $tempFile

# حذف الملف المؤقت
Remove-Item $tempFile -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "  تم الانتهاء!  " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "الآن يمكنك استخدام السكريبتات التالية:" -ForegroundColor Cyan
Write-Host "  • .\show_views_count.ps1     - لإظهار عدد المشاهدات" -ForegroundColor White
Write-Host "  • .\hide_views_count.ps1     - لإخفاء عدد المشاهدات" -ForegroundColor White
Write-Host ""
