import 'package:flutter_test/flutter_test.dart';
import 'package:academic_os/core/platform/app_platform.dart';

void main() {
  group('AppPlatform web-safe startup', () {
    test('should disable native security on web', () {
      expect(AppPlatform.shouldUseNativeSecurity(isWeb: true), isFalse);
    });

    test('should keep native security on native platforms', () {
      expect(AppPlatform.shouldUseNativeSecurity(isWeb: false), isTrue);
    });
  });
}
