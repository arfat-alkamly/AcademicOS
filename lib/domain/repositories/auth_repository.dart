import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<bool> loginWithUsername(String username, String password);
  Future<bool> registerLocalUser(
    String username,
    String password, {
    String? email,
    String? displayName,
  });
  Future<bool> loginWithGoogle();
  Future<bool> loginWithCachedGoogleAccount();
  Future<bool> isLoggedIn();
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
}
