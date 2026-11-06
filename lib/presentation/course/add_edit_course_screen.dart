import 'package:flutter/material.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/course_use_cases.dart';

class AddEditCourseScreen extends StatefulWidget {
  final CourseUseCases useCases;
  final CourseEntity? existingCourse;

  const AddEditCourseScreen({
    super.key,
    required this.useCases,
    this.existingCourse,
  });

  @override
  State<AddEditCourseScreen> createState() => _AddEditCourseScreenState();
}

class _AddEditCourseScreenState extends State<AddEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _instructorController;
  late final TextEditingController _codeController;
  late final TextEditingController _semesterController;
  late final TextEditingController _notesController;
  late final TextEditingController _creditsController;
  late final TextEditingController _creditHoursController;
  late final TextEditingController _midGradeController;
  late final TextEditingController _practicalGradeController;
  late final TextEditingController _finalGradeController;
  late int _credits;
  late int _creditHours;
  late String _selectedColorHex;
  bool _isSaving = false;
  bool _lectureReminderEnabled = false;
  DateTime? _lectureDate;
  int _lectureReminderOffsetMinutes = 30;

  final List<String> _colorOptions = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#9C27B0',
    '#F44336',
  ];

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingCourse?.name ?? '',
    );
    _instructorController = TextEditingController(
      text: widget.existingCourse?.instructor ?? '',
    );
    _codeController = TextEditingController(
      text: widget.existingCourse?.code ?? '',
    );
    _semesterController = TextEditingController(
      text: widget.existingCourse?.semester ?? '',
    );
    _notesController = TextEditingController(
      text: widget.existingCourse?.notes ?? '',
    );
    _creditsController = TextEditingController(
      text: (widget.existingCourse?.credits ?? 0).toString(),
    );
    _creditHoursController = TextEditingController(
      text: (widget.existingCourse?.creditHours ??
              widget.existingCourse?.credits ??
              0)
          .toString(),
    );
    _midGradeController = TextEditingController(
      text: (widget.existingCourse?.midGrade ?? 0).toString(),
    );
    _practicalGradeController = TextEditingController(
      text: (widget.existingCourse?.practicalGrade ?? 0).toString(),
    );
    _finalGradeController = TextEditingController(
      text: (widget.existingCourse?.finalGrade ?? 0).toString(),
    );
    _credits = widget.existingCourse?.credits ?? 0;
    _creditHours = widget.existingCourse?.creditHours ??
        widget.existingCourse?.credits ??
        0;
    _selectedColorHex = widget.existingCourse?.colorHex ?? '#2196F3';
    _lectureReminderEnabled =
        widget.existingCourse?.lectureReminderEnabled ?? false;
    _lectureDate = widget.existingCourse?.lectureDate;
    _lectureReminderOffsetMinutes =
        widget.existingCourse?.lectureReminderOffsetMinutes ?? 30;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructorController.dispose();
    _codeController.dispose();
    _semesterController.dispose();
    _notesController.dispose();
    _creditsController.dispose();
    _creditHoursController.dispose();
    _midGradeController.dispose();
    _practicalGradeController.dispose();
    _finalGradeController.dispose();
    super.dispose();
  }

  Future<void> _pickLectureDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _lectureDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (selectedDate == null) return;

    if (!mounted) return;
    final selectedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(_lectureDate ?? selectedDate),
    );
    if (selectedTime == null) return;

    setState(() {
      _lectureDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final mid = double.tryParse(_midGradeController.text.trim()) ?? 0;
    final practical =
        double.tryParse(_practicalGradeController.text.trim()) ?? 0;
    final finalValue = double.tryParse(_finalGradeController.text.trim()) ?? 0;
    final course = CourseEntity(
      id: widget.existingCourse?.id,
      name: _nameController.text.trim(),
      instructor: _instructorController.text.trim(),
      code: _codeController.text.trim(),
      credits: _credits,
      semester: _semesterController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      colorHex: _selectedColorHex,
      lectureReminderEnabled: _lectureReminderEnabled,
      lectureDate: _lectureReminderEnabled ? _lectureDate : null,
      lectureReminderOffsetMinutes: _lectureReminderOffsetMinutes,
      midGrade: mid,
      practicalGrade: practical,
      finalGrade: finalValue,
      creditHours: _creditHours == 0 ? _credits : _creditHours,
    );

    setState(() => _isSaving = true);

    try {
      if (widget.existingCourse == null) {
        await widget.useCases.addCourse(course);
      } else {
        await widget.useCases.updateCourse(course);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('AddEditCourseScreen._saveCourse error: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حفظ المادة.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCourse != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل المادة' : 'إضافة مادة')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'اسم المادة'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'أدخل اسم المادة'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instructorController,
                      decoration: const InputDecoration(labelText: 'المحاضر'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'أدخل اسم المحاضر'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration:
                          const InputDecoration(labelText: 'رمز المادة'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'أدخل رمز المادة'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _creditsController,
                            decoration: const InputDecoration(
                              labelText: 'عدد الوحدات',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final parsed = int.tryParse(value) ?? 0;
                              setState(() {
                                _credits = parsed;
                                if (_creditHours == 0) {
                                  _creditHours = parsed;
                                  _creditHoursController.text =
                                      parsed.toString();
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _semesterController,
                            decoration: const InputDecoration(
                              labelText: 'الفصل الدراسي',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _creditHoursController,
                            decoration: const InputDecoration(
                              labelText: 'ساعات الاعتماد',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final parsed = int.tryParse(value) ?? _credits;
                              setState(() => _creditHours = parsed);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _midGradeController,
                            decoration: const InputDecoration(
                              labelText: 'درجة المتوسط',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _practicalGradeController,
                            decoration: const InputDecoration(
                              labelText: 'العملي',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _finalGradeController,
                            decoration: const InputDecoration(
                              labelText: 'النهائي',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'لون المادة',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _colorOptions.map((colorHex) {
                              final color = _parseColor(colorHex);
                              final isSelected = _selectedColorHex == colorHex;
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _selectedColorHex = colorHex),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.black87
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'ملاحظات'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      value: _lectureReminderEnabled,
                      onChanged: (value) =>
                          setState(() => _lectureReminderEnabled = value),
                      title: const Text('تذكير بالمحاضرة'),
                      subtitle: const Text(
                        'سيوجد تنبيه قبل موعد المحاضرة مباشرةً.',
                      ),
                    ),
                    if (_lectureReminderEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.event),
                              label: Text(
                                _lectureDate == null
                                    ? 'اختر وقت المحاضرة'
                                    : 'المحاضرة: ${_lectureDate!.year}-${_lectureDate!.month.toString().padLeft(2, '0')}-${_lectureDate!.day.toString().padLeft(2, '0')} ${_lectureDate!.hour.toString().padLeft(2, '0')}:${_lectureDate!.minute.toString().padLeft(2, '0')}',
                              ),
                              onPressed: _pickLectureDate,
                            ),
                          ),
                          if (_lectureDate != null)
                            IconButton(
                              onPressed: () =>
                                  setState(() => _lectureDate = null),
                              icon: const Icon(Icons.clear),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _lectureReminderOffsetMinutes,
                        decoration: const InputDecoration(
                          labelText: 'التنبيه قبل (دقيقة)',
                        ),
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('5 دقائق')),
                          DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                          DropdownMenuItem(value: 30, child: Text('30 دقيقة')),
                          DropdownMenuItem(value: 60, child: Text('1 ساعة')),
                          DropdownMenuItem(value: 1440, child: Text('1 يوم')),
                        ],
                        onChanged: (value) => setState(
                          () => _lectureReminderOffsetMinutes = value ?? 30,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveCourse,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEditing ? 'تحديث' : 'حفظ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
