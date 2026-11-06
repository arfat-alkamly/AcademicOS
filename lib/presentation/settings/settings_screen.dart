import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isProcessing = false;

  Future<void> _exportBackup() async {
    setState(() => _isProcessing = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final courses = await db.query('courses');
      final tasks = await db.query('tasks');
      final exams = await db.query('exams');
      final schedules = await db.query('schedule');

      final payload = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'courses': courses,
        'tasks': tasks,
        'exams': exams,
        'schedules': schedules,
      };

      final encoded = const JsonEncoder.withIndent('  ').convert(payload);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('نسخة احتياطية'),
          content: SingleChildScrollView(
            child: SelectableText(encoded),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير النسخة الاحتياطية: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importBackup() async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('استيراد نسخة احتياطية'),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: controller,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: 'ألصق JSON هنا',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('استيراد'),
            ),
          ],
        );
      },
    );

    if (text == null || text.trim().isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSON غير صالح.');
      }

      final coursesData = decoded['courses'];
      final tasksData = decoded['tasks'];
      final examsData = decoded['exams'];
      final schedulesData = decoded['schedules'];

      if (coursesData == null || tasksData == null || examsData == null || schedulesData == null) {
        throw const FormatException('الملف لا يحتوي على البيانات المطلوبة.');
      }

      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        await txn.delete('tasks');
        await txn.delete('courses');
        await txn.delete('exams');
        await txn.delete('schedule');

        for (final row in (coursesData as List<dynamic>)) {
          await txn.insert('courses', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final row in (tasksData as List<dynamic>)) {
          await txn.insert('tasks', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final row in (examsData as List<dynamic>)) {
          await txn.insert('exams', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final row in (schedulesData as List<dynamic>)) {
          await txn.insert('schedule', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استيراد النسخة الاحتياطية بنجاح.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل استيراد النسخة الاحتياطية: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف كل البيانات؟'),
        content: const Text('سيتم حذف كل المهام، الكورسات، الامتحانات، والجدول الدراسي بشكل دائم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('tasks');
      await db.delete('courses');
      await db.delete('exams');
      await db.delete('schedule');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف جميع البيانات.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف البيانات: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'النسخ الاحتياطي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _exportBackup,
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Export Backup'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _importBackup,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Import Backup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المظهر',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: widget.isDarkMode,
                    onChanged: widget.onThemeChanged,
                    title: const Text('الوضع الداكن'),
                    subtitle: const Text('Light / Dark mode switcher'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إدارة البيانات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _clearAllData,
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('Clear All Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
