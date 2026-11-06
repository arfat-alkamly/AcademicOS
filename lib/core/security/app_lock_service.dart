import 'auth_secure_storage_service.dart';
import 'local_auth_service.dart';

class AppLockService {
  final AuthSecureStorageService _secureStorageService;
  final LocalAuthService _localAuthService;

  AppLockService(this._secureStorageService, this._localAuthService);

  Future<bool> isPinSet() async {
    final pinHash = await _secureStorageService.getAppLockPinHash();
    return pinHash != null && pinHash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final salt = _secureStorageService.generateSalt();
    final pinHash = _secureStorageService.hashPassword(pin, salt);
    await _secureStorageService.saveAppLockPinHash(pinHash);
    await _secureStorageService.saveAppLockPinSalt(salt);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorageService.getAppLockPinHash();
    final salt = await _secureStorageService.getAppLockPinSalt();
    if (storedHash == null || salt == null) {
      return false;
    }
    final computedHash = _secureStorageService.hashPassword(pin, salt);
    return computedHash == storedHash;
  }

  Future<void> removePin() async {
    await _secureStorageService.deleteAppLockPin();
    await _secureStorageService.saveAppLockBiometricEnabled(false);
  }

  Future<bool> isBiometricAvailable() {
    return _localAuthService.isBiometricAvailable();
  }

  Future<bool> authenticateBiometric() {
    return _localAuthService.authenticate();
  }

  Future<void> updateLastActive() async {
    await _secureStorageService.saveAppLockLastActiveAt(DateTime.now());
  }

  Future<DateTime?> getLastActiveAt() async {
    final raw = await _secureStorageService.getAppLockLastActiveAt();
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> shouldLockApp() async {
    if (!await isPinSet()) {
      return false;
    }
    final lastActive = await getLastActiveAt();
    if (lastActive == null) {
      return true;
    }
    final timeoutMinutes = await getLockTimeout();
    final elapsed = DateTime.now().difference(lastActive);
    return elapsed.inMinutes >= timeoutMinutes;
  }

  Future<void> enableBiometric(bool enabled) async {
    await _secureStorageService.saveAppLockBiometricEnabled(enabled);
  }

  Future<bool> isBiometricEnabled() async {
    return _secureStorageService.isAppLockBiometricEnabled();
  }

  Future<int> getLockTimeout() {
    return _secureStorageService.getAppLockTimeout();
  }

  Future<void> setLockTimeout(int minutes) {
    return _secureStorageService.saveAppLockTimeout(minutes);
  }
}
