import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:academic_os/data/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Database schema', () {
    test(
        'initial database creation should not add duplicate course grade columns',
        () async {
      final helper = DatabaseHelper.instance;
      await helper.close();

      final db = await helper.database;
      final result = await db.rawQuery(
        "PRAGMA table_info(courses)",
      );

      final columnNames = result.map((row) => row['name'].toString()).toList();
      expect(columnNames, contains('mid_grade'));
      expect(columnNames, contains('practical_grade'));
      expect(columnNames, contains('final_grade'));
      expect(columnNames, contains('credit_hours'));

      final duplicates = <String, int>{};
      for (final column in columnNames) {
        duplicates[column] = (duplicates[column] ?? 0) + 1;
      }

      for (final entry in duplicates.entries) {
        expect(entry.value, 1,
            reason: 'Duplicate column detected: ${entry.key}');
      }

      await helper.close();
    });
  });
}
