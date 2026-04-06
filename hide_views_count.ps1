# ===============================================
# إخفاء عدد المشاهدات في جميع العروض
# ===============================================
# هذا السكريبت يغير showViewsCount إلى false
# ===============================================

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  إخفاء عدد المشاهدات  " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  تأكد من وجود Firebase مُهيأ في المشروع" -ForegroundColor Yellow
Write-Host ""
Write-Host "هل تريد المتابعة؟ (Y/N): " -NoNewline -ForegroundColor White
$confirm = Read-Host

if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "تم الإلغاء." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host "طريقة التحديث اليدوية:" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. افتح Firebase Console" -ForegroundColor White
Write-Host "2. اذهب إلى Firestore Database" -ForegroundColor White
Write-Host "3. افتح المجموعة: app_control" -ForegroundColor White
Write-Host "4. افتح المستند: offers_settings" -ForegroundColor White
Write-Host "5. غير showViewsCount من true إلى false" -ForegroundColor White
Write-Host "6. احفظ التغييرات" -ForegroundColor White
Write-Host ""
Write-Host "أو استخدم هذا الكود في Flutter:" -ForegroundColor Cyan
Write-Host ""
Write-Host "await FirebaseFirestore.instance" -ForegroundColor Gray
Write-Host "    .collection('app_control')" -ForegroundColor Gray
Write-Host "    .doc('offers_settings')" -ForegroundColor Gray
Write-Host "    .update({'showViewsCount': false});" -ForegroundColor Gray
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "  تعليمات جاهزة  " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
