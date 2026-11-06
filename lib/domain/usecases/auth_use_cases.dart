import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithUsernameUseCase {
  final AuthRepository repository;

  LoginWithUsernameUseCase(this.repository);

  Future<bool> call(String username, String password) {
    return repository.loginWithUsername(username, password);
  }
}

class RegisterLocalUserUseCase {
  final AuthRepository repository;

  RegisterLocalUserUseCase(this.repository);

  Future<bool> call(
    String username,
    String password, {
    String? email,
    String? displayName,
  }) {
    return repository.registerLocalUser(
      username,
      password,
      email: email,
      displayName: displayName,
    );
  }
}

class LoginWithGoogleUseCase {
  final AuthRepository repository;

  LoginWithGoogleUseCase(this.repository);

  Future<bool> call() {
    return repository.loginWithGoogle();
  }
}

class LoginWithCachedGoogleAccountUseCase {
  final AuthRepository repository;

  LoginWithCachedGoogleAccountUseCase(this.repository);

  Future<bool> call() {
    return repository.loginWithCachedGoogleAccount();
  }
}

class IsLoggedInUseCase {
  final AuthRepository repository;

  IsLoggedInUseCase(this.repository);

  Future<bool> call() {
    return repository.isLoggedIn();
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<UserEntity?> call() {
    return repository.getCurrentUser();
  }
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}

class AuthUseCases {
  final LoginWithUsernameUseCase loginWithUsername;
  final RegisterLocalUserUseCase registerLocalUser;
  final LoginWithGoogleUseCase loginWithGoogle;
  final LoginWithCachedGoogleAccountUseCase loginWithCachedGoogleAccount;
  final IsLoggedInUseCase isLoggedIn;
  final GetCurrentUserUseCase getCurrentUser;
  final LogoutUseCase logout;

  const AuthUseCases({
    required this.loginWithUsername,
    required this.registerLocalUser,
    required this.loginWithGoogle,
    required this.loginWithCachedGoogleAccount,
    required this.isLoggedIn,
    required this.getCurrentUser,
    required this.logout,
  });
}
