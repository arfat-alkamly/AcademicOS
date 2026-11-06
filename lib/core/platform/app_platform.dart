import 'package:flutter/foundation.dart';

class AppPlatform {
  const AppPlatform._();

  static bool shouldUseNativeSecurity({bool? isWeb}) {
    return !(isWeb ?? kIsWeb);
  }
}
