import '../../core/security/auth_secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_google_data_source.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;
  final AuthGoogleDataSource _googleDataSource;
  final AuthSecureStorageService _secureStorageService;

  AuthRepositoryImpl(
    this._localDataSource,
    this._googleDataSource,
    this._secureStorageService,
  );

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _localDataSource.getCachedUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _localDataSource.isSessionActive();
  }

  @override
  Future<void> logout() async {
    try {
      await _googleDataSource.signOut();
    } catch (_) {
      // Ignore Google sign-out failures; the local session must still be cleared.
    }
    await _localDataSource.clearSession();
  }

  @override
  Future<bool> loginWithGoogle() async {
    final account = await _googleDataSource.signIn();
    if (account == null) {
      return false;
    }
    await _secureStorageService.saveGoogleAccountData(
      id: account.id,
      email: account.email,
      name: account.displayName ?? account.email,
    );
    await _secureStorageService.saveAuthUsername(account.email);
    await _secureStorageService.saveAuthSessionActive(true);
    return true;
  }

  @override
  Future<bool> loginWithCachedGoogleAccount() async {
    final cached = await _secureStorageService.getGoogleAccountData();
    final email = cached['email'];
    final id = cached['id'];
    if (email == null || id == null) {
      return false;
    }
    await _secureStorageService.saveAuthUsername(email);
    await _secureStorageService.saveAuthSessionActive(true);
    return true;
  }

  @override
  Future<bool> loginWithUsername(String username, String password) {
    return _localDataSource.verifyCredentials(username, password);
  }

  @override
  Future<bool> registerLocalUser(
    String username,
    String password, {
    String? email,
    String? displayName,
  }) async {
    await _localDataSource.persistLocalUser(
      username,
      password,
      email: email,
      displayName: displayName,
    );
    return true;
  }
}
