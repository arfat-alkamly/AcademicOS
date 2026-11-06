import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خدمة تخزين آمن لتخزين كلمات المرور والحساسية المحلية.
/// تفصل هذا عن قاعدة البيانات لتمنحنا مرونة في تغيير آلية التخزين لاحقًا.
class SecureStorageService {
  static const String _dbPasswordKey = 'academic_os_db_password';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _taskFilterKey = 'task_filter_course';
  static const String _taskSortModeKey = 'task_sort_mode';
  static const String _taskStatusFilterKey = 'task_status_filter';

  /// يعيد كلمة المرور الخاصة بقاعدة البيانات.
  /// إذا لم توجد، يتم إنشاؤها وتخزينها آمنًا.
  Future<String> getDatabasePassword() async {
    final existingPassword = await _secureStorage.read(key: _dbPasswordKey);
    if (existingPassword != null && existingPassword.isNotEmpty) {
      return existingPassword;
    }

    final newPassword = _generateSecurePassword();
    await _secureStorage.write(key: _dbPasswordKey, value: newPassword);
    return newPassword;
  }

  Future<void> saveTaskFilter(String? courseName) async {
    if (courseName == null) {
      await _secureStorage.delete(key: _taskFilterKey);
      return;
    }
    await _secureStorage.write(key: _taskFilterKey, value: courseName);
  }

  Future<String?> getSavedTaskFilter() async {
    return await _secureStorage.read(key: _taskFilterKey);
  }

  Future<void> saveTaskSortMode(String sortModeName) async {
    await _secureStorage.write(key: _taskSortModeKey, value: sortModeName);
  }

  Future<String?> getSavedTaskSortMode() async {
    return await _secureStorage.read(key: _taskSortModeKey);
  }

  Future<void> saveTaskStatusFilter(String statusName) async {
    await _secureStorage.write(key: _taskStatusFilterKey, value: statusName);
  }

  Future<String?> getSavedTaskStatusFilter() async {
    return await _secureStorage.read(key: _taskStatusFilterKey);
  }

  String _generateSecurePassword() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// يحذف كلمة المرور من التخزين الآمن.
  /// مفيد في حالات إعادة الضبط أو تسجيل الخروج الآمن.
  Future<void> deleteDatabasePassword() async {
    await _secureStorage.delete(key: _dbPasswordKey);
  }
}
