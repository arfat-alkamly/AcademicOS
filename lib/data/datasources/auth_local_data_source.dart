import '../../core/security/auth_secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthLocalDataSource {
  Future<bool> verifyCredentials(String username, String password);
  Future<void> persistLocalUser(
    String username,
    String password, {
    String? email,
    String? displayName,
  });
  Future<bool> isSessionActive();
  Future<UserEntity?> getCachedUser();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final AuthSecureStorageService _secureStorageService;

  AuthLocalDataSourceImpl(this._secureStorageService);

  @override
  Future<bool> verifyCredentials(String username, String password) async {
    final storedUsername = await _secureStorageService.getAuthUsername();
    final storedHash = await _secureStorageService.getPasswordHash();
    final salt = await _secureStorageService.getPasswordSalt();
    if (storedUsername == null || storedHash == null || salt == null) {
      return false;
    }
    if (storedUsername != username) {
      return false;
    }
    final computedHash = _secureStorageService.hashPassword(password, salt);
    final success = computedHash == storedHash;
    if (success) {
      await _secureStorageService.saveAuthSessionActive(true);
    }
    return success;
  }

  @override
  Future<void> persistLocalUser(
    String username,
    String password, {
    String? email,
    String? displayName,
  }) async {
    final salt = _secureStorageService.generateSalt();
    final hash = _secureStorageService.hashPassword(password, salt);
    await _secureStorageService.saveAuthUsername(username);
    await _secureStorageService.savePasswordSalt(salt);
    await _secureStorageService.savePasswordHash(hash);
    await _secureStorageService.saveAuthSessionActive(true);
  }

  @override
  Future<bool> isSessionActive() {
    return _secureStorageService.isAuthSessionActive();
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final username = await _secureStorageService.getAuthUsername();
    if (username == null) return null;
    final googleData = await _secureStorageService.getGoogleAccountData();
    return UserEntity(
      id: username,
      username: username,
      email: googleData['email'],
      displayName: googleData['name'] ?? username,
      isGoogleLinked: googleData['id'] != null,
      isBiometricEnabled:
          await _secureStorageService.isAppLockBiometricEnabled(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> clearSession() async {
    await _secureStorageService.clearSessionData();
  }
}
