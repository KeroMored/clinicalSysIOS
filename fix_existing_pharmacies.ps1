# Script to manually link existing users to their pharmacies
# يمكنك تشغيل هذا السكريبت لتحديث الصيدليات الموجودة

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Fix Existing Pharmacies - ربط المستخدمين بالصيدليات الموجودة" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "هذا السكريبت يساعدك على ربط المستخدمين الموجودين بالصيدليات" -ForegroundColor Yellow
Write-Host ""
Write-Host "الخطوات:" -ForegroundColor Green
Write-Host "1. افتح Firebase Console" -ForegroundColor White
Write-Host "2. اذهب إلى Firestore Database" -ForegroundColor White
Write-Host "3. لكل صيدلية قم بالآتي:" -ForegroundColor White
Write-Host ""

Write-Host "للصيدلية التي ID لها = [pharmacy_id]:" -ForegroundColor Cyan
Write-Host "   - تأكد أن authEmails تحتوي على الإيميل الصحيح" -ForegroundColor White
Write-Host "   - في collection users، ابحث عن المستخدم بهذا الإيميل" -ForegroundColor White
Write-Host "   - قم بتحديث المستخدم:" -ForegroundColor White
Write-Host "     * role = 'pharmacy'" -ForegroundColor Yellow
Write-Host "     * pharmacyId = '[pharmacy_id]'" -ForegroundColor Yellow
Write-Host "   - في collection pharmacy_subscriptions، أضف document بـ ID المستخدم:" -ForegroundColor White
Write-Host "     {" -ForegroundColor Yellow
Write-Host "       'subscribedAt': [timestamp]," -ForegroundColor Yellow
Write-Host "       'topic': 'pharmacy_requests'," -ForegroundColor Yellow
Write-Host "       'isActive': true," -ForegroundColor Yellow
Write-Host "       'pharmacyId': '[pharmacy_id]'" -ForegroundColor Yellow
Write-Host "     }" -ForegroundColor Yellow
Write-Host ""

Write-Host "================================" -ForegroundColor Green
Write-Host "أو بدلاً من ذلك:" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "1. افتح التطبيق كـ Admin" -ForegroundColor White
Write-Host "2. اذهب إلى أي صيدلية موجودة" -ForegroundColor White
Write-Host "3. اضغط على 'تعديل'" -ForegroundColor White
Write-Host "4. تأكد أن إيميل المصادقة صحيح" -ForegroundColor White
Write-Host "5. اضغط 'حفظ' - سيتم الربط تلقائياً!" -ForegroundColor White
Write-Host ""

Write-Host "✅ التحديثات الجديدة ستطبق تلقائياً على:" -ForegroundColor Green
Write-Host "   - إضافة صيدلية جديدة من الأدمن" -ForegroundColor White
Write-Host "   - الموافقة على صيدلية pending" -ForegroundColor White
Write-Host "   - تعديل بيانات صيدلية موجودة" -ForegroundColor White
Write-Host ""

Read-Host "اضغط Enter للإغلاق..."
