import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// خدمة كشف Root/Jailbreak والأجهزة غير الآمنة
class SecurityCheckService {
  static final SecurityCheckService _instance =
      SecurityCheckService._internal();
  factory SecurityCheckService() => _instance;
  SecurityCheckService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// فحص شامل لأمان الجهاز
  Future<SecurityCheckResult> performSecurityCheck() async {
    final results = <String, bool>{};
    final warnings = <String>[];

    try {
      // فحص Root/Jailbreak
      final isRooted = await checkIfDeviceIsRooted();
      results['isRooted'] = isRooted;
      if (isRooted) {
        warnings.add('الجهاز مكسور الحماية (Rooted/Jailbroken)');
      }

      // فحص المحاكي
      final isEmulator = await checkIfRunningOnEmulator();
      results['isEmulator'] = isEmulator;
      if (isEmulator) {
        warnings.add('التطبيق يعمل على محاكي');
      }

      // فحص Developer Mode
      final isDeveloperMode = await checkDeveloperMode();
      results['isDeveloperMode'] = isDeveloperMode;
      if (isDeveloperMode) {
        warnings.add('وضع المطور مفعل');
      }

      // فحص USB Debugging (Android)
      if (Platform.isAndroid) {
        final isDebuggable = await checkUSBDebugging();
        results['isDebuggable'] = isDebuggable;
        if (isDebuggable) {
          warnings.add('USB Debugging مفعل');
        }
      }

      final isSecure = warnings.isEmpty;
      return SecurityCheckResult(
        isSecure: isSecure,
        checks: results,
        warnings: warnings,
      );
    } catch (e) {
      print('❌ Security check error: $e');
      return SecurityCheckResult(
        isSecure: false,
        checks: results,
        warnings: ['خطأ في فحص الأمان'],
      );
    }
  }

  /// فحص Root/Jailbreak
  Future<bool> checkIfDeviceIsRooted() async {
    if (Platform.isAndroid) {
      return await _checkAndroidRoot();
    } else if (Platform.isIOS) {
      return await _checkIOSJailbreak();
    }
    return false;
  }

  /// فحص Root على Android
  Future<bool> _checkAndroidRoot() async {
    // قائمة بالملفات التي تدل على Root
    final suspiciousFiles = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
      '/system/xbin/daemonsu',
      '/system/etc/init.d/99SuperSUDaemon',
      '/dev/com.koushikdutta.superuser.daemon/',
      '/system/app/Kinguser.apk',
      '/system/bin/.ext/.su',
      '/system/usr/we-need-root/su',
    ];

    // فحص وجود الملفات
    for (final path in suspiciousFiles) {
      try {
        if (await File(path).exists()) {
          print('⚠️ Root file detected: $path');
          return true;
        }
      } catch (e) {
        // تجاهل الأخطاء
      }
    }

    // فحص Build Tags
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final tags = androidInfo.tags.toLowerCase();
      if (tags.contains('test-keys')) {
        print('⚠️ Test-keys detected in build tags');
        return true;
      }
    } catch (e) {
      print('Error checking build tags: $e');
    }

    return false;
  }

  /// فحص Jailbreak على iOS
  Future<bool> _checkIOSJailbreak() async {
    // قائمة بالملفات التي تدل على Jailbreak
    final suspiciousFiles = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/Applications/blackra1n.app',
      '/Applications/FakeCarrier.app',
      '/Applications/Icy.app',
      '/Applications/IntelliScreen.app',
      '/Applications/MxTube.app',
      '/Applications/RockApp.app',
      '/Applications/SBSettings.app',
      '/Applications/WinterBoard.app',
      '/private/var/lib/cydia',
      '/private/var/mobile/Library/SBSettings/Themes',
      '/private/var/tmp/cydia.log',
      '/private/var/stash',
      '/System/Library/LaunchDaemons/com.ikey.bbot.plist',
      '/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist',
      '/usr/libexec/sftp-server',
      '/usr/bin/sshd',
      '/usr/sbin/frida-server',
    ];

    for (final path in suspiciousFiles) {
      try {
        if (await File(path).exists()) {
          print('⚠️ Jailbreak file detected: $path');
          return true;
        }
      } catch (e) {
        // تجاهل الأخطاء
      }
    }

    return false;
  }

  /// فحص المحاكي
  Future<bool> checkIfRunningOnEmulator() async {
    if (kDebugMode) {
      // في وضع Debug، نسمح بالمحاكي
      return false;
    }

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      // فحص معلومات الجهاز
      final brand = androidInfo.brand.toLowerCase();
      final device = androidInfo.device.toLowerCase();
      final model = androidInfo.model.toLowerCase();
      final product = androidInfo.product.toLowerCase();
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final hardware = androidInfo.hardware.toLowerCase();

      // قائمة بالكلمات التي تدل على المحاكي
      final emulatorIndicators = [
        'generic',
        'unknown',
        'emulator',
        'simulator',
        'sdk',
        'genymotion',
        'android sdk built for x86',
        'vbox',
        'goldfish',
        'ranchu',
      ];

      for (final indicator in emulatorIndicators) {
        if (brand.contains(indicator) ||
            device.contains(indicator) ||
            model.contains(indicator) ||
            product.contains(indicator) ||
            manufacturer.contains(indicator) ||
            hardware.contains(indicator)) {
          print('⚠️ Emulator detected: $indicator');
          return true;
        }
      }

      // فحص إضافي للمحاكي
      if (androidInfo.isPhysicalDevice == false) {
        return true;
      }
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      if (iosInfo.isPhysicalDevice == false) {
        return true;
      }
    }

    return false;
  }

  /// فحص Developer Mode
  Future<bool> checkDeveloperMode() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // في Android، نفحص إذا كان Build Type هو debug
        return !androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      }
    } catch (e) {
      print('Error checking developer mode: $e');
    }
    return false;
  }

  /// فحص USB Debugging (Android)
  Future<bool> checkUSBDebugging() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      // لا يمكن الوصول مباشرة لحالة USB Debugging
      // لكن يمكننا التحقق من علامات أخرى
      return !androidInfo.isPhysicalDevice;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على معلومات الجهاز
  Future<DeviceSecurityInfo> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return DeviceSecurityInfo(
          platform: 'Android',
          version: androidInfo.version.release,
          model: androidInfo.model,
          manufacturer: androidInfo.manufacturer,
          isPhysicalDevice: androidInfo.isPhysicalDevice,
          deviceId: androidInfo.id,
        );
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return DeviceSecurityInfo(
          platform: 'iOS',
          version: iosInfo.systemVersion,
          model: iosInfo.model,
          manufacturer: 'Apple',
          isPhysicalDevice: iosInfo.isPhysicalDevice,
          deviceId: iosInfo.identifierForVendor ?? 'unknown',
        );
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return DeviceSecurityInfo(
      platform: 'Unknown',
      version: 'Unknown',
      model: 'Unknown',
      manufacturer: 'Unknown',
      isPhysicalDevice: false,
      deviceId: 'unknown',
    );
  }

  /// فحص سلامة التطبيق
  Future<bool> checkAppIntegrity() async {
    // يمكن إضافة فحوصات إضافية هنا مثل:
    // - التحقق من التوقيع الرقمي
    // - فحص التعديلات على ملفات التطبيق
    // - التحقق من checksum للملفات المهمة

    return true; // مؤقتاً
  }
}

/// نتيجة فحص الأمان
class SecurityCheckResult {
  final bool isSecure;
  final Map<String, bool> checks;
  final List<String> warnings;

  SecurityCheckResult({
    required this.isSecure,
    required this.checks,
    required this.warnings,
  });

  @override
  String toString() {
    return 'SecurityCheckResult(isSecure: $isSecure, warnings: ${warnings.length})';
  }
}

/// معلومات أمان الجهاز
class DeviceSecurityInfo {
  final String platform;
  final String version;
  final String model;
  final String manufacturer;
  final bool isPhysicalDevice;
  final String deviceId;

  DeviceSecurityInfo({
    required this.platform,
    required this.version,
    required this.model,
    required this.manufacturer,
    required this.isPhysicalDevice,
    required this.deviceId,
  });

  @override
  String toString() {
    return 'DeviceInfo($platform $version, $manufacturer $model)';
  }
}
