import 'package:flutter/foundation.dart';

import '../../data/database/database_helper.dart';
import '../platform/app_platform.dart';
import '../security/secure_storage_service.dart';

class AppInitializer {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SecureStorageService _secureStorageService = SecureStorageService();

  Future<void> initialize() async {
    try {
      if (AppPlatform.shouldUseNativeSecurity()) {
        await _secureStorageService.getDatabasePassword();
      } else {
        debugPrint(
            'Web mode detected: skipping secure storage initialization.');
      }

      await Future.microtask(() async {
        try {
          await _databaseHelper.database;
        } catch (error, stackTrace) {
          debugPrint('Database initialization warning: $error\n$stackTrace');
        }
      });

      debugPrint('Application initialized successfully.');
    } catch (error, stackTrace) {
      debugPrint('AppInitializer failed: $error\n$stackTrace');
    }
  }
}
