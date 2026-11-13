import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academic_os/core/security/auth_secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth session cleanup', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('clearSessionData ends the session but preserves local credentials',
        () async {
      final service = AuthSecureStorageService();

      await service.saveAuthUsername('student01');
      await service.savePasswordHash('hash-value');
      await service.savePasswordSalt('salt-value');
      await service.saveGoogleAccountData(
        id: 'google-123',
        email: 'student@example.com',
        name: 'Student User',
      );
      await service.saveAuthSessionActive(true);

      await service.clearSessionData();

      expect(await service.getAuthUsername(), 'student01');
      expect(await service.getPasswordHash(), 'hash-value');
      expect(await service.getPasswordSalt(), 'salt-value');
      expect(await service.isAuthSessionActive(), isFalse);
      expect(await service.isAuthLogoutRequired(), isTrue);

      final googleData = await service.getGoogleAccountData();
      expect(googleData['id'], isNull);
      expect(googleData['email'], isNull);
      expect(googleData['name'], isNull);
    });

    test('successful session activation clears the logout requirement',
        () async {
      final service = AuthSecureStorageService();

      await service.clearSessionData();
      expect(await service.isAuthLogoutRequired(), isTrue);

      await service.saveAuthSessionActive(true);

      expect(await service.isAuthLogoutRequired(), isFalse);
      expect(await service.isAuthSessionActive(), isTrue);
    });
  });
}
