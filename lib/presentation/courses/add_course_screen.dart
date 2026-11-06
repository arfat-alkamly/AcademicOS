import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/course_model.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  String _semester = 'الفصل الأول';
  Color _selectedColor = const Color(0xFF2196F3);
  bool _lectureReminderEnabled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _instructorController.dispose();
    _codeController.dispose();
    _creditsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final course = CourseModel(
      name: _nameController.text.trim(),
      instructor: _instructorController.text.trim(),
      code: _codeController.text.trim(),
      credits: int.tryParse(_creditsController.text) ?? 0,
      semester: _semester,
      notes: _notesController.text.trim(),
      colorHex:
          '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      lectureReminderEnabled: _lectureReminderEnabled,
    );

    try {
      await DatabaseHelper.instance.insertCourse(course).timeout(
            const Duration(seconds: 4),
            onTimeout: () => throw TimeoutException(
              'انتهت مهلة حفظ المادة. حاول مرة أخرى.',
            ),
          );

      scheduleMicrotask(() {
        // e.g., NotificationService.instance.syncCourses();
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('AddCourseScreen._saveCourse error: $e\n$st');
      final errorMessage = e is TimeoutException
          ? (e.message ?? 'انتهت مهلة حفظ المادة. حاول مرة أخرى.')
          : 'حدث خطأ أثناء حفظ المادة.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecorationTheme(
      filled: true,
      fillColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مادة'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المادة',
                        hintText: 'أدخل اسم المادة',
                        prefixIcon: const Icon(Icons.book_outlined),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'أدخل اسم المادة'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instructorController,
                      decoration: InputDecoration(
                        labelText: 'المحاضر',
                        hintText: 'أدخل اسم المحاضر',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'رمز المادة',
                        hintText: 'مثل: CS101',
                        prefixIcon: const Icon(Icons.code_outlined),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _creditsController,
                      decoration: InputDecoration(
                        labelText: 'عدد الوحدات',
                        hintText: 'عدد الساعات المعتمدة',
                        prefixIcon: const Icon(Icons.numbers_outlined),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _semester,
                      items: const [
                        DropdownMenuItem(
                            value: 'الفصل الأول', child: Text('الفصل الأول')),
                        DropdownMenuItem(
                            value: 'الفصل الثاني', child: Text('الفصل الثاني')),
                        DropdownMenuItem(
                            value: 'الصيفي', child: Text('الصيفي')),
                      ],
                      onChanged: (v) =>
                          setState(() => _semester = v ?? 'الفصل الأول'),
                      decoration: InputDecoration(
                        labelText: 'الفصل الدراسي',
                        prefixIcon: const Icon(Icons.calendar_month_outlined),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildColorPicker(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات',
                        hintText: 'أضف ملاحظات إضافية (اختياري)',
                        prefixIcon: const Icon(Icons.note_outlined),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        title: const Text('تذكير بالمحاضرة',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle:
                            const Text('سيوجد تنبيه قبل موعد المحاضرة مباشرة.'),
                        value: _lectureReminderEnabled,
                        onChanged: (v) =>
                            setState(() => _lectureReminderEnabled = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveCourse,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text('حفظ المادة'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final presets = [
      const Color(0xFF2196F3),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('لون المادة',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _selectedColor,
              child: Container(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: presets.map((c) {
                  final selected = c.value == _selectedColor.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: c,
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
