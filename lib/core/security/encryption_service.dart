import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// خدمة التشفير المتقدمة - تشفير البيانات الحساسة
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // Secure Storage لحفظ المفاتيح بشكل آمن
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  late encrypt.Key _encryptionKey;
  late encrypt.IV _iv;
  bool _initialized = false;

  /// تهيئة خدمة التشفير
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // محاولة تحميل المفتاح المحفوظ
      String? savedKey = await _secureStorage.read(key: 'encryption_key');
      String? savedIV = await _secureStorage.read(key: 'encryption_iv');

      if (savedKey != null && savedIV != null) {
        _encryptionKey = encrypt.Key.fromBase64(savedKey);
        _iv = encrypt.IV.fromBase64(savedIV);
      } else {
        // إنشاء مفتاح جديد
        await _generateNewKey();
      }

      _initialized = true;
      print('🔐 Encryption Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing encryption: $e');
      // في حالة الخطأ، إنشاء مفتاح جديد
      await _generateNewKey();
      _initialized = true;
    }
  }

  /// إنشاء مفتاح تشفير جديد وحفظه
  Future<void> _generateNewKey() async {
    final key = encrypt.Key.fromSecureRandom(32); // AES-256
    final iv = encrypt.IV.fromSecureRandom(16);

    await _secureStorage.write(key: 'encryption_key', value: key.base64);
    await _secureStorage.write(key: 'encryption_iv', value: iv.base64);

    _encryptionKey = key;
    _iv = iv;
  }

  /// تشفير نص
  String encryptText(String plainText) {
    if (!_initialized) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('❌ Encryption error: $e');
      rethrow;
    }
  }

  /// فك تشفير نص
  String decryptText(String encryptedText) {
    if (!_initialized) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      print('❌ Decryption error: $e');
      rethrow;
    }
  }

  /// تشفير Map (JSON)
  String encryptJson(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return encryptText(jsonString);
  }

  /// فك تشفير Map (JSON)
  Map<String, dynamic> decryptJson(String encryptedJson) {
    final jsonString = decryptText(encryptedJson);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// حساب Hash لكلمة المرور (SHA-256)
  String hashPassword(String password, {String? salt}) {
    salt ??= _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  /// التحقق من كلمة المرور
  bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;

      final salt = parts[0];
      final hash = parts[1];

      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);

      return digest.toString() == hash;
    } catch (e) {
      return false;
    }
  }

  /// إنشاء Salt عشوائي
  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// حفظ بيانات حساسة بشكل آمن
  Future<void> saveSecureData(String key, String value) async {
    final encrypted = encryptText(value);
    await _secureStorage.write(key: key, value: encrypted);
  }

  /// قراءة بيانات حساسة
  Future<String?> readSecureData(String key) async {
    final encrypted = await _secureStorage.read(key: key);
    if (encrypted == null) return null;

    try {
      return decryptText(encrypted);
    } catch (e) {
      print('❌ Error reading secure data: $e');
      return null;
    }
  }

  /// حذف بيانات حساسة
  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// حذف جميع البيانات المحفوظة
  Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
  }

  /// تشفير البيانات الثنائية (للملفات)
  Uint8List encryptBytes(Uint8List data) {
    if (!_initialized) {
      throw Exception('Encryption service not initialized');
    }

    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypter.encryptBytes(data, iv: _iv);
    return encrypted.bytes;
  }

  /// فك تشفير البيانات الثنائية
  Uint8List decryptBytes(Uint8List encryptedData) {
    if (!_initialized) {
      throw Exception('Encryption service not initialized');
    }

    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypt.Encrypted(encryptedData);
    return Uint8List.fromList(encrypter.decryptBytes(encrypted, iv: _iv));
  }

  /// RSA Key Generation للتشفير غير المتماثل
  Future<AsymmetricKeyPair<PublicKey, PrivateKey>> generateRSAKeyPair() async {
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          SecureRandom('Fortuna')..seed(
            KeyParameter(
              Uint8List.fromList(
                List.generate(32, (i) => Random.secure().nextInt(256)),
              ),
            ),
          ),
        ),
      );

    return keyGen.generateKeyPair();
  }

  /// تشفير باستخدام RSA Public Key
  String encryptWithPublicKey(String plainText, RSAPublicKey publicKey) {
    final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
    return encrypter.encrypt(plainText).base64;
  }

  /// فك التشفير باستخدام RSA Private Key
  String decryptWithPrivateKey(String encryptedText, RSAPrivateKey privateKey) {
    final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
    return encrypter.decrypt64(encryptedText);
  }

  /// توليد HMAC للتحقق من سلامة البيانات
  String generateHMAC(String data, String secretKey) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// التحقق من HMAC
  bool verifyHMAC(String data, String hmac, String secretKey) {
    final calculated = generateHMAC(data, secretKey);
    return calculated == hmac;
  }

  /// توليد Token عشوائي آمن
  String generateSecureToken({int length = 32}) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// حساب SHA-512 Hash
  String sha512Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }
}
