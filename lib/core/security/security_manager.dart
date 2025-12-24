import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'encryption_service.dart';
import 'security_check_service.dart';

/// مدير الأمان الرئيسي - يدير كل جوانب الأمان في التطبيق
class SecurityManager {
  static final SecurityManager _instance = SecurityManager._internal();
  factory SecurityManager() => _instance;
  SecurityManager._internal();

  final EncryptionService _encryption = EncryptionService();
  final SecurityCheckService _securityCheck = SecurityCheckService();
  final Connectivity _connectivity = Connectivity();

  bool _isInitialized = false;
  SecurityCheckResult? _lastSecurityCheck;
  DateTime? _lastCheckTime;

  /// تهيئة مدير الأمان
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔐 Initializing Security Manager...');

      // تهيئة خدمة التشفير
      await _encryption.initialize();

      // إجراء فحص أمني أولي
      await performSecurityCheck();

      // مراقبة الاتصال بالإنترنت
      _setupConnectivityMonitoring();

      _isInitialized = true;
      print('✅ Security Manager initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Security Manager: $e');
      rethrow;
    }
  }

  /// إجراء فحص أمني شامل
  Future<SecurityCheckResult> performSecurityCheck() async {
    try {
      print('🔍 Performing security check...');
      
      final result = await _securityCheck.performSecurityCheck();
      _lastSecurityCheck = result;
      _lastCheckTime = DateTime.now();

      if (!result.isSecure) {
        print('⚠️ Security issues detected:');
        for (final warning in result.warnings) {
          print('  - $warning');
        }
      } else {
        print('✅ Device is secure');
      }

      return result;
    } catch (e) {
      print('❌ Security check failed: $e');
      rethrow;
    }
  }

  /// التحقق من أمان الجهاز قبل الاستمرار
  Future<bool> validateDeviceSecurity({
    bool allowInDebug = true,
  }) async {
    // في وضع Debug، نسمح بالتشغيل
    if (kDebugMode && allowInDebug) {
      print('🐛 Running in debug mode - security checks relaxed');
      return true;
    }

    // إجراء الفحص إذا لم يتم أو مر وقت طويل
    if (_lastSecurityCheck == null ||
        _lastCheckTime == null ||
        DateTime.now().difference(_lastCheckTime!).inMinutes > 30) {
      await performSecurityCheck();
    }

    return _lastSecurityCheck?.isSecure ?? false;
  }

  /// التحقق من الاتصال الآمن
  Future<bool> checkSecureConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // التحقق من وجود اتصال
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('⚠️ No internet connection');
        return false;
      }

      // تفضيل WiFi أو Mobile Data
      if (connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile)) {
        print('✅ Secure connection available');
        return true;
      }

      return true;
    } catch (e) {
      print('❌ Error checking connection: $e');
      return false;
    }
  }

  /// مراقبة تغيرات الاتصال
  void _setupConnectivityMonitoring() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.none)) {
        print('📡 Connection lost');
      } else {
        print('📡 Connection restored: $result');
      }
    });
  }

  /// تشفير البيانات الحساسة
  String encryptSensitiveData(String data) {
    try {
      return _encryption.encryptText(data);
    } catch (e) {
      print('❌ Encryption failed: $e');
      rethrow;
    }
  }

  /// فك تشفير البيانات
  String decryptSensitiveData(String encryptedData) {
    try {
      return _encryption.decryptText(encryptedData);
    } catch (e) {
      print('❌ Decryption failed: $e');
      rethrow;
    }
  }

  /// حفظ بيانات حساسة
  Future<void> saveSecureData(String key, String value) async {
    try {
      await _encryption.saveSecureData(key, value);
      print('✅ Secure data saved: $key');
    } catch (e) {
      print('❌ Failed to save secure data: $e');
      rethrow;
    }
  }

  /// قراءة بيانات حساسة
  Future<String?> readSecureData(String key) async {
    try {
      final value = await _encryption.readSecureData(key);
      if (value != null) {
        print('✅ Secure data read: $key');
      }
      return value;
    } catch (e) {
      print('❌ Failed to read secure data: $e');
      return null;
    }
  }

  /// حذف بيانات حساسة
  Future<void> deleteSecureData(String key) async {
    try {
      await _encryption.deleteSecureData(key);
      print('✅ Secure data deleted: $key');
    } catch (e) {
      print('❌ Failed to delete secure data: $e');
    }
  }

  /// مسح جميع البيانات الآمنة (عند تسجيل الخروج)
  Future<void> clearAllSecureData() async {
    try {
      await _encryption.clearAllSecureData();
      print('✅ All secure data cleared');
    } catch (e) {
      print('❌ Failed to clear secure data: $e');
    }
  }

  /// تشفير كلمة المرور
  String hashPassword(String password) {
    return _encryption.hashPassword(password);
  }

  /// التحقق من كلمة المرور
  bool verifyPassword(String password, String hashedPassword) {
    return _encryption.verifyPassword(password, hashedPassword);
  }

  /// توليد token آمن
  String generateSecureToken() {
    return _encryption.generateSecureToken();
  }

  /// توليد HMAC للتحقق من سلامة البيانات
  String generateDataSignature(String data, String secretKey) {
    return _encryption.generateHMAC(data, secretKey);
  }

  /// التحقق من توقيع البيانات
  bool verifyDataSignature(String data, String signature, String secretKey) {
    return _encryption.verifyHMAC(data, signature, secretKey);
  }

  /// الحصول على معلومات الجهاز
  Future<DeviceSecurityInfo> getDeviceInfo() async {
    return await _securityCheck.getDeviceInfo();
  }

  /// آخر نتيجة فحص أمني
  SecurityCheckResult? get lastSecurityCheck => _lastSecurityCheck;

  /// هل الجهاز آمن؟
  bool get isDeviceSecure => _lastSecurityCheck?.isSecure ?? false;

  /// تسجيل حدث أمني
  void logSecurityEvent(String event, {Map<String, dynamic>? details}) {
    final timestamp = DateTime.now().toIso8601String();
    print('🔐 Security Event [$timestamp]: $event');
    if (details != null) {
      print('   Details: $details');
    }
    
    // يمكن إرسال هذه الأحداث إلى Firebase Analytics أو Crashlytics
  }

  /// التحقق من صلاحية الجلسة
  bool validateSession(DateTime? sessionStartTime, {int maxHours = 24}) {
    if (sessionStartTime == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(sessionStartTime);
    
    if (difference.inHours > maxHours) {
      logSecurityEvent('Session expired', details: {
        'started': sessionStartTime.toIso8601String(),
        'duration_hours': difference.inHours,
      });
      return false;
    }
    
    return true;
  }

  /// قفل التطبيق (يمكن استخدامه مع البصمة أو PIN)
  Future<void> lockApp() async {
    await saveSecureData('app_locked', 'true');
    await saveSecureData('lock_timestamp', DateTime.now().toIso8601String());
    logSecurityEvent('App locked');
  }

  /// فتح قفل التطبيق
  Future<void> unlockApp() async {
    await deleteSecureData('app_locked');
    await deleteSecureData('lock_timestamp');
    logSecurityEvent('App unlocked');
  }

  /// هل التطبيق مقفل؟
  Future<bool> isAppLocked() async {
    final locked = await readSecureData('app_locked');
    return locked == 'true';
  }

  /// فرض قفل بعد فترة عدم نشاط
  Future<bool> shouldAutoLock({int inactivityMinutes = 5}) async {
    final lockTimestamp = await readSecureData('lock_timestamp');
    if (lockTimestamp == null) return false;
    
    try {
      final lockTime = DateTime.parse(lockTimestamp);
      final difference = DateTime.now().difference(lockTime);
      
      return difference.inMinutes >= inactivityMinutes;
    } catch (e) {
      return false;
    }
  }

  /// تنظيف عند الخروج
  Future<void> dispose() async {
    print('🔐 Security Manager disposing...');
    // يمكن إضافة عمليات تنظيف إضافية هنا
  }
}
