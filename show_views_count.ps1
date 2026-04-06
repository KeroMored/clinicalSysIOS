# ===============================================
# إظهار عدد المشاهدات في جميع العروض
# ===============================================
# هذا السكريبت يغير showViewsCount إلى true
# ===============================================

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  إظهار عدد المشاهدات  " -ForegroundColor Cyan
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
Write-Host "جاري تحديث الإعدادات..." -ForegroundColor Yellow

# استخدام Firebase CLI
$command = @"
const admin = require('firebase-admin');

// تهيئة Firebase Admin
admin.initializeApp();

const db = admin.firestore();

// تحديث الإعداد
db.collection('app_control').doc('offers_settings').set({
    showViewsCount: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
}, { merge: true })
.then(() => {
    console.log('✅ تم تفعيل عرض عدد المشاهدات');
    process.exit(0);
})
.catch((error) => {
    console.error('❌ خطأ:', error);
    process.exit(1);
});
"@

# طريقة بديلة: استخدام Firestore REST API
Write-Host ""
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host "طريقة التحديث اليدوية:" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. افتح Firebase Console" -ForegroundColor White
Write-Host "2. اذهب إلى Firestore Database" -ForegroundColor White
Write-Host "3. افتح المجموعة: app_control" -ForegroundColor White
Write-Host "4. افتح المستند: offers_settings" -ForegroundColor White
Write-Host "5. غير showViewsCount من false إلى true" -ForegroundColor White
Write-Host "6. احفظ التغييرات" -ForegroundColor White
Write-Host ""
Write-Host "أو استخدم هذا الكود في Flutter:" -ForegroundColor Cyan
Write-Host ""
Write-Host "await FirebaseFirestore.instance" -ForegroundColor Gray
Write-Host "    .collection('app_control')" -ForegroundColor Gray
Write-Host "    .doc('offers_settings')" -ForegroundColor Gray
Write-Host "    .update({'showViewsCount': true});" -ForegroundColor Gray
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "  تعليمات جاهزة  " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
