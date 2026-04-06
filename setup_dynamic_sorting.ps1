# setup_dynamic_sorting.ps1
# سكريبت إعداد نظام الترتيب الديناميكي للعروض

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Dynamic Offer Sorting Setup Script   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# التحقق من وجود Firebase CLI
Write-Host "🔍 التحقق من Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "✅ Firebase CLI موجود: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI غير موجود" -ForegroundColor Red
    Write-Host "📥 تثبيت Firebase CLI: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📋 خطوات الإعداد:" -ForegroundColor Cyan
Write-Host "1. إنشاء وثيقة app_control/offers_settings في Firestore" -ForegroundColor White
Write-Host "2. تحديث العروض الحالية (إضافة viewsCount و category)" -ForegroundColor White
Write-Host "3. التحقق من الإعدادات" -ForegroundColor White
Write-Host ""

# تأكيد من المستخدم
$confirm = Read-Host "هل تريد المتابعة؟ (y/n)"
if ($confirm -ne 'y') {
    Write-Host "❌ تم الإلغاء" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "📝 إنشاء ملف JavaScript مؤقت..." -ForegroundColor Yellow

# إنشاء سكريبت JavaScript للتنفيذ
$jsScript = @"
// setup_dynamic_sorting.js
const admin = require('firebase-admin');

// تهيئة Firebase Admin
// ملاحظة: يجب أن يكون لديك serviceAccountKey.json
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (error) {
  console.error('❌ خطأ في تهيئة Firebase Admin:', error.message);
  console.log('💡 تأكد من وجود serviceAccountKey.json في المجلد الحالي');
  process.exit(1);
}

const db = admin.firestore();

async function setupDynamicSorting() {
  console.log('🚀 بدء الإعداد...\n');

  // 1. إنشاء/تحديث وثيقة offers_settings
  try {
    console.log('📄 إنشاء وثيقة app_control/offers_settings...');
    await db.collection('app_control').doc('offers_settings').set({
      showViewsCount: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log('✅ تم إنشاء وثيقة offers_settings\n');
  } catch (error) {
    console.error('❌ خطأ في إنشاء offers_settings:', error.message);
  }

  // 2. تحديث العروض الحالية
  try {
    console.log('🔄 جلب العروض الحالية...');
    const offersSnapshot = await db.collection('medicine_offers').get();
    console.log(`📦 تم العثور على ${offersSnapshot.size} عرض\n`);

    if (offersSnapshot.empty) {
      console.log('ℹ️  لا توجد عروض للتحديث');
      return;
    }

    // تحديث على دفعات (500 عملية/دفعة)
    const batchSize = 500;
    let batch = db.batch();
    let operationCount = 0;
    let totalUpdated = 0;

    console.log('⚙️  تحديث العروض...');
    for (const doc of offersSnapshot.docs) {
      const data = doc.data();
      
      // التحقق إذا كان العرض يحتاج تحديث
      const needsUpdate = !data.hasOwnProperty('viewsCount') || !data.hasOwnProperty('category');
      
      if (needsUpdate) {
        batch.update(doc.ref, {
          viewsCount: data.viewsCount || 0,
          category: data.category || 'عام',
        });
        operationCount++;
        totalUpdated++;

        // تنفيذ الدفعة عند الوصول للحد الأقصى
        if (operationCount === batchSize) {
          await batch.commit();
          console.log(`  ✓ تم تحديث ${totalUpdated} عرض...`);
          batch = db.batch();
          operationCount = 0;
        }
      }
    }

    // تنفيذ الدفعة المتبقية
    if (operationCount > 0) {
      await batch.commit();
    }

    console.log(`✅ تم تحديث ${totalUpdated} عرض بنجاح\n`);
  } catch (error) {
    console.error('❌ خطأ في تحديث العروض:', error.message);
  }

  // 3. التحقق من الإعدادات
  try {
    console.log('🔍 التحقق من الإعدادات...');
    const settingsDoc = await db.collection('app_control').doc('offers_settings').get();
    const settings = settingsDoc.data();
    console.log('📊 الإعدادات الحالية:');
    console.log(`   - showViewsCount: ${settings.showViewsCount}`);
    console.log(`   - createdAt: ${settings.createdAt?.toDate().toLocaleString('ar-EG')}`);
    console.log(`   - updatedAt: ${settings.updatedAt?.toDate().toLocaleString('ar-EG')}`);
    console.log('');
  } catch (error) {
    console.error('❌ خطأ في التحقق:', error.message);
  }

  console.log('🎉 تم الإعداد بنجاح!');
  console.log('');
  console.log('📱 الخطوات التالية:');
  console.log('   1. قم بتشغيل التطبيق');
  console.log('   2. افتح شاشة عروض الأدوية');
  console.log('   3. تأكد من الترتيب الديناميكي (أيقونة shuffle في AppBar)');
  console.log('');
}

// تنفيذ
setupDynamicSorting()
  .then(() => {
    console.log('✅ العملية اكتملت');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ خطأ:', error);
    process.exit(1);
  });
"@

# حفظ السكريبت
$jsScript | Out-File -FilePath "setup_dynamic_sorting.js" -Encoding UTF8

Write-Host "✅ تم إنشاء setup_dynamic_sorting.js" -ForegroundColor Green
Write-Host ""

# التحقق من وجود serviceAccountKey.json
if (-not (Test-Path "serviceAccountKey.json")) {
    Write-Host "⚠️  تحذير: serviceAccountKey.json غير موجود" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📥 للحصول على serviceAccountKey.json:" -ForegroundColor Cyan
    Write-Host "   1. اذهب إلى Firebase Console" -ForegroundColor White
    Write-Host "   2. Project Settings > Service Accounts" -ForegroundColor White
    Write-Host "   3. Generate New Private Key" -ForegroundColor White
    Write-Host "   4. احفظ الملف باسم serviceAccountKey.json" -ForegroundColor White
    Write-Host ""
    
    $continue = Read-Host "هل لديك serviceAccountKey.json وتريد المتابعة؟ (y/n)"
    if ($continue -ne 'y') {
        Write-Host "❌ تم الإلغاء" -ForegroundColor Red
        Write-Host "ℹ️  احصل على serviceAccountKey.json وأعد تشغيل السكريبت" -ForegroundColor Cyan
        exit 0
    }
}

Write-Host ""
Write-Host "🚀 تنفيذ السكريبت..." -ForegroundColor Yellow
Write-Host ""

try {
    # تنفيذ السكريبت
    node setup_dynamic_sorting.js
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "           ✅ تم الإعداد بنجاح          " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # تنظيف
    Write-Host "🧹 تنظيف الملفات المؤقتة..." -ForegroundColor Yellow
    Remove-Item "setup_dynamic_sorting.js" -ErrorAction SilentlyContinue
    Write-Host "✅ تم التنظيف" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "❌ حدث خطأ أثناء التنفيذ" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 تأكد من:" -ForegroundColor Yellow
    Write-Host "   - تثبيت Node.js و npm" -ForegroundColor White
    Write-Host "   - تثبيت firebase-admin: npm install firebase-admin" -ForegroundColor White
    Write-Host "   - وجود serviceAccountKey.json" -ForegroundColor White
    Write-Host ""
}

Write-Host ""
Write-Host "📚 للمزيد من المعلومات، راجع:" -ForegroundColor Cyan
Write-Host "   - DYNAMIC_OFFER_SORTING_GUIDE.md" -ForegroundColor White
Write-Host ""

# Pause
Read-Host "اضغط Enter للخروج..."
