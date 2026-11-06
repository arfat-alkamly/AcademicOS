import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSecureStorageService {
  static const String _dbPasswordKey = 'academic_os_db_password';
  static const String _authUsernameKey = 'academic_os_auth_username';
  static const String _authPasswordHashKey = 'academic_os_auth_password_hash';
  static const String _authPasswordSaltKey = 'academic_os_auth_password_salt';
  static const String _googleAccountIdKey = 'academic_os_google_account_id';
  static const String _googleAccountEmailKey =
      'academic_os_google_account_email';
  static const String _googleAccountNameKey = 'academic_os_google_account_name';
  static const String _authSessionActiveKey = 'academic_os_auth_session_active';
  static const String _appLockPinHashKey = 'academic_os_app_lock_pin_hash';
  static const String _appLockPinSaltKey = 'academic_os_app_lock_pin_salt';
  static const String _appLockBiometricEnabledKey =
      'academic_os_app_lock_biometric_enabled';
  static const String _appLockTimeoutKey = 'academic_os_app_lock_timeout';
  static const String _appLockLastActiveAtKey =
      'academic_os_app_lock_last_active_at';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String> getDatabasePassword() async {
    final existingPassword = await _secureStorage.read(key: _dbPasswordKey);
    if (existingPassword != null && existingPassword.isNotEmpty) {
      return existingPassword;
    }

    final newPassword = _generateSecurePassword();
    await _secureStorage.write(key: _dbPasswordKey, value: newPassword);
    return newPassword;
  }

  Future<void> deleteDatabasePassword() async {
    await _secureStorage.delete(key: _dbPasswordKey);
  }

  Future<void> saveAuthUsername(String username) async {
    await _secureStorage.write(key: _authUsernameKey, value: username);
  }

  Future<String?> getAuthUsername() async {
    return await _secureStorage.read(key: _authUsernameKey);
  }

  Future<void> savePasswordHash(String hash) async {
    await _secureStorage.write(key: _authPasswordHashKey, value: hash);
  }

  Future<String?> getPasswordHash() async {
    return await _secureStorage.read(key: _authPasswordHashKey);
  }

  Future<void> savePasswordSalt(String salt) async {
    await _secureStorage.write(key: _authPasswordSaltKey, value: salt);
  }

  Future<String?> getPasswordSalt() async {
    return await _secureStorage.read(key: _authPasswordSaltKey);
  }

  Future<void> saveGoogleAccountData({
    required String id,
    required String email,
    required String name,
  }) async {
    await _secureStorage.write(key: _googleAccountIdKey, value: id);
    await _secureStorage.write(key: _googleAccountEmailKey, value: email);
    await _secureStorage.write(key: _googleAccountNameKey, value: name);
  }

  Future<void> clearGoogleAccountData() async {
    await _secureStorage.delete(key: _googleAccountIdKey);
    await _secureStorage.delete(key: _googleAccountEmailKey);
    await _secureStorage.delete(key: _googleAccountNameKey);
  }

  Future<Map<String, String?>> getGoogleAccountData() async {
    final id = await _secureStorage.read(key: _googleAccountIdKey);
    final email = await _secureStorage.read(key: _googleAccountEmailKey);
    final name = await _secureStorage.read(key: _googleAccountNameKey);
    return {'id': id, 'email': email, 'name': name};
  }

  Future<void> saveAuthSessionActive(bool isActive) async {
    await _secureStorage.write(
      key: _authSessionActiveKey,
      value: isActive ? 'true' : 'false',
    );
  }

  Future<void> clearSessionData() async {
    await _secureStorage.delete(key: _authUsernameKey);
    await _secureStorage.delete(key: _authPasswordHashKey);
    await _secureStorage.delete(key: _authPasswordSaltKey);
    await clearGoogleAccountData();
    await saveAuthSessionActive(false);
  }

  Future<bool> isAuthSessionActive() async {
    final value = await _secureStorage.read(key: _authSessionActiveKey);
    return value == 'true';
  }

  Future<void> saveAppLockPinHash(String pinHash) async {
    await _secureStorage.write(key: _appLockPinHashKey, value: pinHash);
  }

  Future<String?> getAppLockPinHash() async {
    return await _secureStorage.read(key: _appLockPinHashKey);
  }

  Future<void> saveAppLockPinSalt(String salt) async {
    await _secureStorage.write(key: _appLockPinSaltKey, value: salt);
  }

  Future<String?> getAppLockPinSalt() async {
    return await _secureStorage.read(key: _appLockPinSaltKey);
  }

  Future<void> deleteAppLockPin() async {
    await _secureStorage.delete(key: _appLockPinHashKey);
    await _secureStorage.delete(key: _appLockPinSaltKey);
  }

  Future<void> saveAppLockBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _appLockBiometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> isAppLockBiometricEnabled() async {
    final value = await _secureStorage.read(key: _appLockBiometricEnabledKey);
    return value == 'true';
  }

  Future<void> saveAppLockTimeout(int minutes) async {
    await _secureStorage.write(
      key: _appLockTimeoutKey,
      value: minutes.toString(),
    );
  }

  Future<void> saveAppLockLastActiveAt(DateTime dateTime) async {
    await _secureStorage.write(
      key: _appLockLastActiveAtKey,
      value: dateTime.toIso8601String(),
    );
  }

  Future<String?> getAppLockLastActiveAt() async {
    return await _secureStorage.read(key: _appLockLastActiveAtKey);
  }

  Future<int> getAppLockTimeout() async {
    final value = await _secureStorage.read(key: _appLockTimeoutKey);
    return int.tryParse(value ?? '') ?? 5;
  }

  String _generateSecurePassword() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String hashPassword(String password, String salt) {
    final key = utf8.encode(password + salt);
    final digest = sha256.convert(key);
    return digest.toString();
  }

  String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }
}
