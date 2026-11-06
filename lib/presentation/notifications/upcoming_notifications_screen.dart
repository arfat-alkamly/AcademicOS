import 'package:flutter/material.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/course_use_cases.dart';
import '../../domain/usecases/task_use_cases.dart';

class UpcomingNotificationsScreen extends StatefulWidget {
  final TaskUseCases taskUseCases;
  final CourseUseCases courseUseCases;

  const UpcomingNotificationsScreen({
    super.key,
    required this.taskUseCases,
    required this.courseUseCases,
  });

  @override
  State<UpcomingNotificationsScreen> createState() =>
      _UpcomingNotificationsScreenState();
}

class _UpcomingNotificationsScreenState
    extends State<UpcomingNotificationsScreen> {
  bool _isLoading = true;
  List<TaskEntity> _tasks = [];
  List<CourseEntity> _courses = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await widget.taskUseCases.getTasks();
      final courses = await widget.courseUseCases.getCourses();
      if (!mounted) return;
      setState(() {
        _tasks = tasks
            .where((task) => task.reminderEnabled && task.reminderDate != null)
            .toList();
        _courses = courses
            .where(
              (course) =>
                  course.lectureReminderEnabled && course.lectureDate != null,
            )
            .toList();
      });
    } catch (error, stackTrace) {
      debugPrint(
        'UpcomingNotificationsScreen._loadData error: $error\n$stackTrace',
      );
      if (!mounted) return;
      setState(() => _errorMessage = 'تعذر تحميل الإشعارات القادمة.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 72,
              color: Colors.blueGrey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد إشعارات قادمة حالياً',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف تذكيرات للمهام أو المحاضرات لرؤية قائمة مرتبة هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = [
      ..._tasks.map(
        (task) => _ReminderItem(
          type: 'task',
          title: task.title,
          subtitle: task.description,
          date: task.reminderDate!,
          badge: 'مهمة',
        ),
      ),
      ..._courses.map(
        (course) => _ReminderItem(
          type: 'course',
          title: course.name,
          subtitle: course.notes ?? 'محاضرة مقررة',
          date: course.lectureDate!,
          badge: 'محاضرة',
        ),
      ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات القادمة'), centerTitle: true),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : allItems.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: allItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: item.type == 'course'
                            ? Colors.indigo.shade100
                            : Colors.amber.shade100,
                        child: Icon(
                          item.type == 'course'
                              ? Icons.school_outlined
                              : Icons.task_alt_outlined,
                          color: item.type == 'course'
                              ? Colors.indigo
                              : Colors.amber.shade800,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Chip(
                                label: Text(item.badge),
                                backgroundColor: Colors.blueGrey.shade50,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateTime(item.date),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ReminderItem {
  final String type;
  final String title;
  final String subtitle;
  final DateTime date;
  final String badge;

  const _ReminderItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.badge,
  });
}
