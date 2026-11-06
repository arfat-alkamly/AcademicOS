import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'تأكيد الهوية'}) async {
    if (kIsWeb) return false;
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
