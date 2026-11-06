import 'package:flutter/material.dart';

import '../../data/database/database_helper.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/course_use_cases.dart';
import '../../domain/usecases/task_use_cases.dart';
import '../task/add_edit_task_screen.dart';
import 'widgets/course_materials_tab.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseEntity? course;
  final int? courseId;
  final TaskUseCases taskUseCases;
  final CourseUseCases courseUseCases;

  const CourseDetailScreen({
    super.key,
    this.course,
    this.courseId,
    required this.taskUseCases,
    required this.courseUseCases,
  }) : assert(course != null || courseId != null);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  CourseEntity? _course;
  List<TaskEntity> _tasks = [];
  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> _exams = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initCourse();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initCourse() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.course != null) {
        _course = widget.course;
      } else if (widget.courseId != null) {
        _course = await widget.courseUseCases.getCourseById(widget.courseId!);
      }

      await _loadData();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'تعذر تحميل بيانات المقرر.');
    }
  }

  Future<void> _loadData() async {
    if (_course == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'المقرر غير موجود.';
      });
      return;
    }

    try {
      final tasks = await widget.taskUseCases.getTasks();
      final db = await DatabaseHelper.instance.database;
      final schedules = await db.query(
        'schedule',
        where: 'course_id = ?',
        whereArgs: [_course!.id],
      );
      final exams = await db.query(
        'exams',
        where: 'course_id = ?',
        whereArgs: [_course!.id],
      );

      if (!mounted) return;
      setState(() {
        _tasks = tasks.where((task) => task.courseId == _course!.id).toList();
        _schedule = schedules;
        _exams = exams;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'فشل تحميل بيانات المقرر.');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  double get _coursePerformancePercent {
    if (_course == null) return 0;
    final mid = _course!.midGrade ?? 0;
    final practical = _course!.practicalGrade ?? 0;
    final finalValue = _course!.finalGrade ?? 0;
    return ((mid * 0.3) + (practical * 0.3) + (finalValue * 0.4))
        .clamp(0, 100)
        .toDouble();
  }

  Future<void> _toggleTask(TaskEntity task) async {
    try {
      await widget.taskUseCases
          .updateTask(task.copyWith(isCompleted: !task.isCompleted));
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث حالة المهمة.')),
      );
    }
  }

  Future<void> _openTaskEditor([TaskEntity? task]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(
          useCases: widget.taskUseCases,
          courseUseCases: widget.courseUseCases,
          existingTask: task,
          initialCourse: _course,
        ),
      ),
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _openQuickAddMenu() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.task_alt),
                title: const Text('إضافة مهمة'),
                onTap: () => Navigator.pop(context, 'task'),
              ),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('إضافة امتحان'),
                onTap: () => Navigator.pop(context, 'exam'),
              ),
            ],
          ),
        );
      },
    );

    if (chosen == 'task') {
      await _openTaskEditor();
      return;
    }

    if (chosen == 'exam') {
      final titleController = TextEditingController();
      final locationController = TextEditingController();
      DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (dialogContext, setStateDialog) {
              return AlertDialog(
                title: const Text('إضافة امتحان للمقرر'),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration:
                            const InputDecoration(labelText: 'عنوان الامتحان'),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (time == null) return;
                          setStateDialog(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(labelText: 'المكان'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('حفظ'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true) return;
      final title = titleController.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل عنوان الامتحان.')),
        );
        return;
      }
      final db = await DatabaseHelper.instance.database;
      await db.insert('exams', {
        'course_id': _course!.id,
        'title': title,
        'exam_date': selectedDate.toIso8601String(),
        'location': locationController.text.trim().isEmpty
            ? null
            : locationController.text.trim(),
        'notes': null,
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_course == null && !_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('المقرر')),
        body: const Center(child: Text('لم يتم العثور على هذا المقرر.')),
      );
    }

    final pendingTasks = _tasks.where((task) => !task.isCompleted).length;
    final nextExam = _exams
        .where((exam) => (exam['exam_date'] as String?) != null)
        .map((exam) =>
            DateTime.tryParse(exam['exam_date'] as String) ?? DateTime.now())
        .where((date) => date.isAfter(DateTime.now()))
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.name ?? 'المقرر'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _course?.name ?? '',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '$pendingTasks مهمة معلقة',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  Chip(label: Text(_course?.code ?? '')),
                                  Chip(
                                      label: Text(
                                          '${_course?.credits ?? 0} وحدة')),
                                  if (_course?.instructor != null &&
                                      _course!.instructor.trim().isNotEmpty)
                                    Chip(label: Text(_course!.instructor)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.event_available_outlined,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    nextExam.isNotEmpty
                                        ? 'القادم: ${_formatDate(nextExam.first)}'
                                        : 'لا توجد امتحانات قادمة',
                                    style: TextStyle(
                                      color: nextExam.isNotEmpty
                                          ? Colors.green.shade700
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ملخص الأداء الأكاديمي',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      label: 'المتوسط المتوقع',
                                      value:
                                          '${_coursePerformancePercent.toStringAsFixed(1)}%',
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      label: 'النهائي',
                                      value: (_course?.finalGrade ?? 0)
                                          .toStringAsFixed(1),
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'المهام'),
                        Tab(text: 'الجدول'),
                        Tab(text: 'الامتحانات'),
                        Tab(text: 'المحاضرات والمرفقات'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTasksTab(),
                          _buildScheduleTab(),
                          _buildExamsTab(),
                          // Materials tab
                          CourseMaterialsTab(courseId: _course!.id!),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickAddMenu,
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    if (_tasks.isEmpty) {
      return const Center(child: Text('لا توجد مهام مرتبطة بهذا المقرر.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: CheckboxListTile(
            value: task.isCompleted,
            onChanged: (_) => _toggleTask(task),
            title: Text(task.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(task.description),
                const SizedBox(height: 6),
                if (task.dueDate != null)
                  Text('استحقاق: ${_formatDate(task.dueDate!)}'),
              ],
            ),
            secondary: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openTaskEditor(task),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleTab() {
    if (_schedule.isEmpty) {
      return const Center(child: Text('لا توجد محاضرات مسجلة لهذا المقرر.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedule.length,
      itemBuilder: (context, index) {
        final item = _schedule[index];
        final start = item['start_time'] ?? '00:00';
        final end = item['end_time'] ?? '00:00';
        final day = item['day_of_week'] ?? '—';
        final location = item['location'] ?? 'غير محدد';
        final reminder = item['reminder_enabled'] == 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(day),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('$start - $end'),
                const SizedBox(height: 4),
                Text(location),
              ],
            ),
            trailing: reminder
                ? const Icon(Icons.notifications_active_outlined,
                    color: Colors.orange)
                : const Icon(Icons.notifications_off_outlined),
          ),
        );
      },
    );
  }

  Widget _buildExamsTab() {
    if (_exams.isEmpty) {
      return const Center(child: Text('لا توجد امتحانات مسجلة لهذا المقرر.'));
    }

    final sorted = List<Map<String, dynamic>>.from(_exams)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['exam_date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['exam_date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final exam = sorted[index];
        final examDate =
            DateTime.tryParse(exam['exam_date'] as String? ?? '') ??
                DateTime.now();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: Text(exam['title'] ?? 'امتحان'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(_formatDateTime(examDate)),
                if ((exam['location'] ?? '').toString().isNotEmpty)
                  Text(exam['location'] as String),
              ],
            ),
          ),
        );
      },
    );
  }
}
