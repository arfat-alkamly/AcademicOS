import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academic_os/core/security/auth_secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('Auth session cleanup', () {
    test('clearSessionData removes session and stored account info', () async {
      final service = AuthSecureStorageService();

      await service.saveAuthUsername('student@example.com');
      await service.savePasswordHash('hash-value');
      await service.savePasswordSalt('salt-value');
      await service.saveGoogleAccountData(
        id: 'google-123',
        email: 'student@example.com',
        name: 'Student User',
      );
      await service.saveAuthSessionActive(true);

      await service.clearSessionData();

      expect(await service.getAuthUsername(), isNull);
      expect(await service.getPasswordHash(), isNull);
      expect(await service.getPasswordSalt(), isNull);
      expect(await service.isAuthSessionActive(), isFalse);

      final googleData = await service.getGoogleAccountData();
      expect(googleData['id'], isNull);
      expect(googleData['email'], isNull);
      expect(googleData['name'], isNull);
    });
  });
}
