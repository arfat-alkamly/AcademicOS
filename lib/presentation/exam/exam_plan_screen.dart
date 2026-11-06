import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/course_entity.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/usecases/course_use_cases.dart';
import '../../features/exam/presentation/providers/exam_provider.dart';

class ExamPlanScreen extends ConsumerStatefulWidget {
  final CourseUseCases courseUseCases;

  const ExamPlanScreen({
    super.key,
    required this.courseUseCases,
  });

  @override
  ConsumerState<ExamPlanScreen> createState() => _ExamPlanScreenState();
}

class _ExamPlanScreenState extends ConsumerState<ExamPlanScreen> {
  Timer? _timer;
  List<CourseEntity> _courses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _loadCourses();
    ref.read(examListProvider.notifier).loadExams();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await widget.courseUseCases.getCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _isLoadingCourses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCourses = false);
    }
  }

  String _courseNameForExam(ExamEntity exam) {
    if (exam.courseName != null && exam.courseName!.trim().isNotEmpty) {
      return exam.courseName!;
    }
    final course = _courses.firstWhere(
      (item) => item.id == exam.courseId,
      orElse: () => const CourseEntity(
        name: 'عام',
        instructor: '',
        code: '',
      ),
    );
    return course.name;
  }

  Color _courseColorForExam(ExamEntity exam) {
    final fromExam = exam.colorHex;
    if (fromExam.isNotEmpty) {
      try {
        return Color(int.parse(fromExam.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    final course = _courses.firstWhere(
      (item) => item.id == exam.courseId,
      orElse: () => const CourseEntity(
        name: 'عام',
        instructor: '',
        code: '',
        colorHex: '#2196F3',
      ),
    );
    try {
      return Color(int.parse(course.colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }

  Duration _remainingDuration(DateTime target) {
    return target.difference(DateTime.now());
  }

  String _countdownLabel(DateTime target) {
    final diff = _remainingDuration(target);
    if (diff.isNegative) {
      return 'انتهى';
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    return '${days}d • ${hours}h • ${minutes}m';
  }

  ExamEntity? _nearestExam() {
    final exams = ref.watch(examListProvider).exams;
    if (exams.isEmpty) return null;
    final futureExams =
        exams.where((exam) => exam.examDate.isAfter(DateTime.now())).toList();
    if (futureExams.isEmpty) return exams.first;
    futureExams.sort((a, b) => a.examDate.compareTo(b.examDate));
    return futureExams.first;
  }

  Future<void> _pickDateTime(
      {DateTime? initial, required Function(DateTime) onPicked}) async {
    final now = DateTime.now();
    final initialDate = initial ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 3650)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;
    onPicked(DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ));
  }

  Future<void> _openExamEditor({ExamEntity? exam}) async {
    final notifier = ref.read(examListProvider.notifier);
    final existingExam = exam;
    final isEditing = existingExam != null;
    final selectedCourseId = existingExam?.courseId ?? _courses.firstOrNull?.id;
    final controllerTitle =
        TextEditingController(text: existingExam?.title ?? '');
    final controllerLocation =
        TextEditingController(text: existingExam?.location ?? '');
    final controllerNotes =
        TextEditingController(text: existingExam?.notes ?? '');
    DateTime selectedDate =
        existingExam?.examDate ?? DateTime.now().add(const Duration(days: 7));
    int? selectedCourse = existingExam?.courseId ?? selectedCourseId;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'تعديل الامتحان' : 'إضافة امتحان'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int?>(
                        value: selectedCourse,
                        decoration: const InputDecoration(labelText: 'المادة'),
                        items: [
                          const DropdownMenuItem<int?>(
                              value: null, child: Text('بدون مادة')),
                          ..._courses.map(
                            (course) => DropdownMenuItem<int?>(
                              value: course.id,
                              child: Text(course.name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => selectedCourse = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controllerTitle,
                        decoration:
                            const InputDecoration(labelText: 'عنوان الامتحان'),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          await _pickDateTime(
                            initial: selectedDate,
                            onPicked: (picked) =>
                                setDialogState(() => selectedDate = picked),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')} • ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controllerLocation,
                        decoration: const InputDecoration(labelText: 'المكان'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controllerNotes,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'ملاحظات'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(isEditing ? 'تحديث' : 'حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) return;
    final title = controllerTitle.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عنوان الامتحان.')),
      );
      return;
    }

    final examToSave = ExamEntity(
      id: existingExam?.id,
      courseId: selectedCourse,
      title: title,
      examDate: selectedDate,
      location: controllerLocation.text.trim().isEmpty
          ? null
          : controllerLocation.text.trim(),
      notes: controllerNotes.text.trim().isEmpty
          ? null
          : controllerNotes.text.trim(),
      courseName: _courses
          .firstWhere(
            (course) => course.id == selectedCourse,
            orElse: () => const CourseEntity(
              name: 'عام',
              instructor: '',
              code: '',
            ),
          )
          .name,
      colorHex: _courses
          .firstWhere(
            (course) => course.id == selectedCourse,
            orElse: () => const CourseEntity(
              name: 'عام',
              instructor: '',
              code: '',
              colorHex: '#2196F3',
            ),
          )
          .colorHex,
    );

    if (isEditing) {
      await notifier.updateExam(examToSave);
    } else {
      await notifier.addExam(examToSave);
    }
  }

  @override
  Widget build(BuildContext context) {
    final examState = ref.watch(examListProvider);
    final nearest = _nearestExam();

    return Scaffold(
      appBar: AppBar(
        title: const Text('خطة الامتحانات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openExamEditor(),
          ),
        ],
      ),
      body: SafeArea(
        child: examState.isLoading && examState.exams.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(examListProvider.notifier).loadExams(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (nearest != null)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _courseColorForExam(nearest)
                                  .withValues(alpha: 0.92),
                              _courseColorForExam(nearest)
                                  .withValues(alpha: 0.72),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.timer_outlined,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'القادم',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _courseNameForExam(nearest),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              nearest.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '${nearest.examDate.year}-${nearest.examDate.month.toString().padLeft(2, '0')}-${nearest.examDate.day.toString().padLeft(2, '0')} • ${nearest.examDate.hour.toString().padLeft(2, '0')}:${nearest.examDate.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _countdownLabel(nearest.examDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (examState.exams.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(22),
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد امتحانات مضافة بعد',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'أضف أول امتحان لتتبع مواعيده والوقت المتبقي.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      const SizedBox(height: 14),
                      Text(
                        'كل الامتحانات',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      ...examState.exams.map((exam) {
                        final color = _courseColorForExam(exam);
                        final remaining = _remainingDuration(exam.examDate);
                        final isPassed = remaining.isNegative;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(exam.title),
                            subtitle: Text(
                              '${_courseNameForExam(exam)} • ${_countdownLabel(exam.examDate)}',
                              style: TextStyle(
                                color: isPassed
                                    ? Colors.red
                                    : Colors.grey.shade700,
                              ),
                            ),
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${exam.examDate.year}-${exam.examDate.month.toString().padLeft(2, '0')}-${exam.examDate.day.toString().padLeft(2, '0')} • ${exam.examDate.hour.toString().padLeft(2, '0')}:${exam.examDate.minute.toString().padLeft(2, '0')}',
                                        ),
                                      ],
                                    ),
                                    if (exam.location != null &&
                                        exam.location!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(exam.location!)),
                                        ],
                                      ),
                                    ],
                                    if (exam.notes != null &&
                                        exam.notes!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.note_outlined,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(exam.notes!)),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              _openExamEditor(exam: exam),
                                          icon: const Icon(Icons.edit_outlined),
                                          label: const Text('تعديل'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () async {
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title:
                                                    const Text('تأكيد الحذف'),
                                                content: Text(
                                                    'هل تريد حذف امتحان "${exam.title}"؟'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('إلغاء'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: const Text('حذف'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) {
                                              await ref
                                                  .read(
                                                      examListProvider.notifier)
                                                  .deleteExam(exam.id!);
                                            }
                                          },
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          label: const Text('حذف'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExamEditor(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة امتحان'),
      ),
    );
  }
}

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
