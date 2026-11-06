// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/academic/academic_dashboard_service.dart';
import '../../core/security/auth_secure_storage_service.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/security/local_auth_service.dart';
import '../../core/security/secure_storage_service.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../../domain/usecases/course_use_cases.dart';
import '../../domain/usecases/task_use_cases.dart';
import '../../providers/task_providers.dart';
import '../../core/widgets/academic_scaffold_background.dart';
import '../auth/auth_gate_screen.dart';
import '../auth/pin_lock_screen.dart';
import '../ai_assistant/academic_ai_screen.dart';
import '../about/about_screen.dart';
import '../course/add_edit_course_screen.dart';
import '../course/course_detail_screen.dart';
import '../course/course_list_screen.dart';
import '../../core/notifications/notification_service.dart';
import '../notifications/upcoming_notifications_screen.dart';
import '../schedule/weekly_schedule_screen.dart';
import '../focus/focus_timer_screen.dart';
import '../settings/backup_export_screen.dart';
import '../study_plan/study_planner_screen.dart';
import '../task/add_edit_task_screen.dart';
import '../screens/grade_distribution_screen.dart';

class _DrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    String? title,
    String? label,
    required this.onTap,
  }) : label = label ?? title ?? '';

  String get title => label;
}

class _DrawerSwitchItem {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DrawerSwitchItem({
    required this.icon,
    String? title,
    String? label,
    required this.value,
    required this.onChanged,
  }) : label = label ?? title ?? '';

  String get title => label;
}

class StudentProfile {
  static const String storageKey = 'academic_os_student_profile';

  final String fullName;
  final String university;
  final String major;
  final String academicLevel;
  final String targetGpa;
  final String avatar;

  const StudentProfile({
    required this.fullName,
    required this.university,
    required this.major,
    required this.academicLevel,
    required this.targetGpa,
    required this.avatar,
  });

  factory StudentProfile.empty() => const StudentProfile(
        fullName: '',
        university: '',
        major: '',
        academicLevel: '',
        targetGpa: '',
        avatar: 'student',
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'university': university,
        'major': major,
        'academicLevel': academicLevel,
        'targetGpa': targetGpa,
        'avatar': avatar,
      };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        fullName: json['fullName']?.toString() ?? '',
        university: json['university']?.toString() ?? '',
        major: json['major']?.toString() ?? '',
        academicLevel: json['academicLevel']?.toString() ?? '',
        targetGpa: json['targetGpa']?.toString() ?? '',
        avatar: json['avatar']?.toString() ?? 'student',
      );

  static Future<StudentProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return StudentProfile.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return StudentProfile.fromJson(decoded);
      }
    } catch (_) {}
    return StudentProfile.empty();
  }

  static Future<void> save(StudentProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(profile.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}

enum TaskSortMode {
  none,
  dueDateAsc,
  dueDateDesc,
  taskType,
  priorityAsc,
  priorityDesc,
  recurrence,
}

enum TaskSearchStatus { all, completed, pending, overdue }

extension TaskSortModeX on TaskSortMode {
  String get label {
    switch (this) {
      case TaskSortMode.dueDateAsc:
        return 'أقرب استحقاق';
      case TaskSortMode.dueDateDesc:
        return 'أبعد استحقاق';
      case TaskSortMode.taskType:
        return 'حسب النوع';
      case TaskSortMode.priorityAsc:
        return 'أولوية تصاعدي';
      case TaskSortMode.priorityDesc:
        return 'أولوية تنازلي';
      case TaskSortMode.recurrence:
        return 'حسب التكرار';
      case TaskSortMode.none:
        return 'بدون فرز';
    }
  }
}

extension TaskSearchStatusX on TaskSearchStatus {
  String get label {
    switch (this) {
      case TaskSearchStatus.completed:
        return 'مكتملة';
      case TaskSearchStatus.pending:
        return 'معلقة';
      case TaskSearchStatus.overdue:
        return 'متأخرة';
      case TaskSearchStatus.all:
        return 'الكل';
    }
  }
}

class HomeScreen extends ConsumerWidget {
  final TaskUseCases taskUseCases;
  final CourseUseCases courseUseCases;
  final AuthUseCases authUseCases;
  final bool isDarkMode;
  final bool isArabic;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.taskUseCases,
    required this.courseUseCases,
    required this.authUseCases,
    required this.isDarkMode,
    required this.isArabic,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskListProvider);
    final taskNotifier = ref.read(taskListProvider.notifier);

    return _HomeScreenContent(
      taskUseCases: taskUseCases,
      courseUseCases: courseUseCases,
      authUseCases: authUseCases,
      isDarkMode: isDarkMode,
      isArabic: isArabic,
      onThemeChanged: onThemeChanged,
      onLanguageChanged: onLanguageChanged,
      taskState: taskState,
      onRefresh: taskNotifier.loadTasks,
      onToggleCompletion: taskNotifier.toggleCompletion,
      onDeleteTask: taskNotifier.deleteTask,
      onAddTask: taskNotifier.addTask,
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  final TaskUseCases taskUseCases;
  final CourseUseCases courseUseCases;
  final AuthUseCases authUseCases;
  final bool isDarkMode;
  final bool isArabic;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;
  final TaskListState taskState;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TaskEntity task) onToggleCompletion;
  final Future<void> Function(int id) onDeleteTask;
  final Future<void> Function(TaskEntity task) onAddTask;

  const _HomeScreenContent({
    required this.taskUseCases,
    required this.courseUseCases,
    required this.authUseCases,
    required this.isDarkMode,
    required this.isArabic,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.taskState,
    required this.onRefresh,
    required this.onToggleCompletion,
    required this.onDeleteTask,
    required this.onAddTask,
  });

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent>
    with WidgetsBindingObserver {
  static const List<String> _yemeniMotivationQuotes = [
    'من طلب العلا سهر الليالي.. شيد همتك يا بطل!',
    'خطوة بخطوة توصل لأعلى الدرجات.. شمر عن ساعديك!',
    'العلم نور.. وكل دقيقة مذاكرة تبني مستقبلك.',
    'قوة العزيمة أهم من الوقت.. ابدأ اليوم بثقة!',
    'كل جهد صغير اليوم يفتح باب نجاحك غداً.',
  ];

  final SecureStorageService _secureStorageService = SecureStorageService();
  final AuthSecureStorageService _authSecureStorageService =
      AuthSecureStorageService();
  final LocalAuthService _localAuthService = LocalAuthService();
  late final AppLockService _appLockService;
  final TextEditingController _searchController = TextEditingController();
  List<CourseEntity> _courses = [];
  bool _isAppLocked = false;
  bool _showMotivationCard = true;
  int _selectedBottomNav = 0;
  String _motivationQuote = _yemeniMotivationQuotes.first;
  String _searchQuery = '';
  String? _selectedCourseFilter;
  StudentProfile _studentProfile = StudentProfile.empty();
  TaskSearchStatus _statusFilter = TaskSearchStatus.all;
  TaskSortMode _sortMode = TaskSortMode.none;

  int get _completedTasksCount =>
      widget.taskState.tasks.where((task) => task.isCompleted).length;
  int get _pendingTasksCount =>
      widget.taskState.tasks.length - _completedTasksCount;

  int get _urgentTasksCount => widget.taskState.tasks
      .where(
          (task) => !task.isCompleted && task.priority == TaskPriority.urgent)
      .length;

  int get _todayTasksCount => widget.taskState.tasks
      .where((task) =>
          !task.isCompleted &&
          task.dueDate != null &&
          task.dueDate!.year == DateTime.now().year &&
          task.dueDate!.month == DateTime.now().month &&
          task.dueDate!.day == DateTime.now().day)
      .length;

  double _percentageToGpa(double percent) {
    if (percent >= 95) return 4.0;
    if (percent >= 90) return 3.8;
    if (percent >= 85) return 3.6;
    if (percent >= 80) return 3.3;
    if (percent >= 75) return 3.0;
    if (percent >= 70) return 2.7;
    if (percent >= 65) return 2.3;
    if (percent >= 60) return 2.0;
    if (percent >= 50) return 1.5;
    return 1.0;
  }

  double get _estimatedGpa {
    if (_courses.isEmpty) return 0;

    var totalWeighted = 0.0;
    var totalCredits = 0;

    for (final course in _courses) {
      final credits = (course.creditHours ?? course.credits);
      final mid = course.midGrade ?? 0;
      final practical = course.practicalGrade ?? 0;
      final finalGrade = course.finalGrade ?? 0;
      final percent = ((mid * 0.3) + (practical * 0.3) + (finalGrade * 0.4))
          .clamp(0, 100)
          .toDouble();
      totalWeighted += _percentageToGpa(percent) * credits;
      totalCredits += credits;
    }

    if (totalCredits == 0) return 0;
    return (totalWeighted / totalCredits).clamp(0, 4.0);
  }

  double get _targetGpaProgress {
    final target = double.tryParse(_studentProfile.targetGpa) ?? 0;
    if (target <= 0) return 0;
    return (_estimatedGpa / target).clamp(0, 1.0);
  }

  Future<void> _showGlobalSearch() async {
    if (!mounted) return;
    final allTasks = widget.taskState.tasks;
    final matchCount = allTasks
        .where((task) =>
            task.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          matchCount > 0
              ? 'تم العثور على $matchCount مهمة متطابقة مع البحث الحالي.'
              : 'لا توجد نتائج مطابقة في المهام الحالية.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required List<Object> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
          ...items.map((item) {
            if (item is Widget) return item;
            if (item is _DrawerSwitchItem) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.02)
                      : primary.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  dense: true,
                  activeColor: primary,
                  secondary: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 18, color: primary),
                  ),
                  title: Text(item.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  value: item.value,
                  onChanged: item.onChanged,
                ),
              );
            }
            if (item is _DrawerItem) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.02)
                      : primary.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 18, color: primary),
                  ),
                  title: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Icon(Icons.chevron_left_rounded,
                      size: 18, color: Colors.grey.shade500),
                  onTap: item.onTap,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLockService = AppLockService(
      _authSecureStorageService,
      _localAuthService,
    );
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text);
    });
    _loadStudentProfile();
    _loadCourses();
    _loadSavedSettingsAndTasks();
    _appLockService.updateLastActive();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await widget.courseUseCases.getCourses();
      if (!mounted) return;
      setState(() => _courses = courses);
    } catch (error, stackTrace) {
      debugPrint('HomeScreen._loadCourses error: $error\n$stackTrace');
    }
  }

  Future<void> _loadStudentProfile() async {
    final profile = await StudentProfile.load();
    if (!mounted) return;
    setState(() => _studentProfile = profile);
  }

  Future<void> _loadSavedSettingsAndTasks() async {
    _motivationQuote = _pickMotivationQuote();
    await _loadSavedSettings();
    await _loadTasks();
  }

  List<String> get _courseFilterOptions {
    final options = _courses
        .map((course) => course.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['الكل', ...options, 'بدون كورس'];
  }

  Future<void> _saveCourseFilter(String? value) async {
    final newValue = value == 'الكل' ? null : value;
    setState(() => _selectedCourseFilter = newValue);
    await _secureStorageService.saveTaskFilter(newValue);
  }

  Future<void> _saveSortMode(TaskSortMode mode) async {
    setState(() => _sortMode = mode);
    await _secureStorageService.saveTaskSortMode(mode.name);
  }

  Future<void> _saveStatusFilter(TaskSearchStatus status) async {
    setState(() => _statusFilter = status);
    await _secureStorageService.saveTaskStatusFilter(status.name);
  }

  String _pickMotivationQuote() {
    final now = DateTime.now();
    final index = (now.millisecondsSinceEpoch % _yemeniMotivationQuotes.length);
    return _yemeniMotivationQuotes[index];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'صباح الهمة والنشاط';
    }
    return 'مساء الإنجاز';
  }

  void _showWarmSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleAppResume() async {
    final shouldLock = await _appLockService.shouldLockApp();
    if (!mounted || !shouldLock) {
      await _appLockService.updateLastActive();
      return;
    }
    setState(() {
      _isAppLocked = true;
    });
  }

  Future<void> _loadSavedSettings() async {
    try {
      final courseFilter = await _secureStorageService.getSavedTaskFilter();
      final sortModeName = await _secureStorageService.getSavedTaskSortMode();
      final statusName = await _secureStorageService.getSavedTaskStatusFilter();
      setState(() {
        _selectedCourseFilter = courseFilter;
        _sortMode = TaskSortMode.values.firstWhere(
          (mode) => mode.name == sortModeName,
          orElse: () => TaskSortMode.none,
        );
        _statusFilter = TaskSearchStatus.values.firstWhere(
          (status) => status.name == statusName,
          orElse: () => TaskSearchStatus.all,
        );
      });
    } catch (error, stackTrace) {
      debugPrint('HomeScreen._loadSavedSettings error: $error\n$stackTrace');
    }
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    await widget.onRefresh();
    try {
      final tasks = widget.taskState.tasks;
      final courses = await widget.courseUseCases.getCourses();
      await NotificationService.instance.syncReminders(
        tasks: tasks,
        courses: courses,
      );
    } catch (error, stackTrace) {
      debugPrint('HomeScreen._loadTasks error: $error\n$stackTrace');
    }
  }

  Future<void> _deleteTask(TaskEntity task) async {
    if (task.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المهمة "${task.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.onDeleteTask(task.id!);
      await _loadTasks();
    } catch (error, stackTrace) {
      debugPrint('HomeScreen._deleteTask error: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حذف المهمة.')),
      );
    }
  }

  Future<void> _toggleTaskCompletion(TaskEntity task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    try {
      await widget.onToggleCompletion(updatedTask);
      await _loadTasks();
      if (!mounted) return;
      _showWarmSnackBar(
        updatedTask.isCompleted
            ? 'تم إكمال المهمة بنجاح.. الله يوفقك!'
            : 'تمت إعادة المهمة إلى قائمة الأعمال.. استمر!',
      );
    } catch (error, stackTrace) {
      debugPrint('HomeScreen._toggleTaskCompletion error: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذّر تحديث حالة المهمة.')));
    }
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primary.withOpacity(0.12),
                        child: Icon(Icons.school, size: 40, color: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Academic OS',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                  'الإصدار 1.0.0 (Offline-First Edition)',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Academic OS هي بيئة تشغيل وإنتاجية أكاديمية متكاملة مصممة خصيصاً لطلاب الجامعات لتنظيم وإدارة مسيرتهم الدراسية بكفاءة واحترافية، وجمع كافة الأدوات الأكاديمية في منصة واحدة تعمل دون اتصال بالإنترنت مع خصوصية تامة.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('📚  ', style: TextStyle(fontSize: 18)),
                        Expanded(
                            child: Text(
                                'إدارة المقررات: متابعة تفاصيل المواد، المحاضرين، والساعات المعتمدة.'))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Text('📝  ', style: TextStyle(fontSize: 18)),
                        Expanded(
                            child: Text(
                                'إدارة المهام: تنظيم الواجبات والتكاليف ومواعيد التسليم حسب الأولوية.'))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Text('📅  ', style: TextStyle(fontSize: 18)),
                        Expanded(
                            child: Text(
                                'الجدول الدراسي: تتبع أوقات المحاضرات، القاعات والمعامل، والمحاضرات النشطة.'))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Text('📊  ', style: TextStyle(fontSize: 18)),
                        Expanded(
                            child: Text(
                                'توزيع الدرجات والمعدل: رصد درجات النظري والعملي واحتساب المعدل الفعلي ومؤشرات التقدم.'))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Text('⏱️  ', style: TextStyle(fontSize: 18)),
                        Expanded(
                            child: Text(
                                'أدوات الإنتاجية: جلسات التركيز والنسخ الاحتياطي المحلي للبيانات.'))
                      ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('تطوير: عرفات عبدالله حسين الكاملي',
                      style: theme.textTheme.bodySmall),
                  Text('التخصص: أمن سيبراني وشبكات',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToAddEdit(TaskEntity? task) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(
          useCases: widget.taskUseCases,
          courseUseCases: widget.courseUseCases,
          existingTask: task,
        ),
      ),
    );
    if (result == true) {
      await _loadTasks();
      _showWarmSnackBar('تم حفظ التعديلات بنجاح.. الله يوفقك!');
    }
  }

  List<TaskEntity> _searchTasks(List<TaskEntity> tasks) {
    if (_searchQuery.trim().isEmpty) return tasks;
    final query = _searchQuery.trim().toLowerCase();
    return tasks.where((task) {
      return task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          (task.courseName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<TaskEntity> _filterByStatus(List<TaskEntity> tasks) {
    switch (_statusFilter) {
      case TaskSearchStatus.completed:
        return tasks.where((task) => task.isCompleted).toList();
      case TaskSearchStatus.pending:
        return tasks.where((task) => !task.isCompleted).toList();
      case TaskSearchStatus.overdue:
        return tasks.where((task) {
          return task.dueDate != null &&
              task.dueDate!.isBefore(DateTime.now()) &&
              !task.isCompleted;
        }).toList();
      case TaskSearchStatus.all:
        return tasks;
    }
  }

  Future<void> _openCourseDetailFromTask(TaskEntity task) async {
    if (task.courseId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذه المهمة غير مرتبطة بمقرر.')),
      );
      return;
    }

    try {
      final course = await widget.courseUseCases.getCourseById(task.courseId!);
      if (course == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على المقرر المرتبط.')),
        );
        return;
      }

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(
            course: course,
            taskUseCases: widget.taskUseCases,
            courseUseCases: widget.courseUseCases,
          ),
        ),
      );
      if (result == true) await _loadTasks();
    } catch (error, stackTrace) {
      debugPrint(
        'HomeScreen._openCourseDetailFromTask error: $error\n$stackTrace',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذّر فتح تفاصيل المقرر.')));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMotivationCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.indigo.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _motivationQuote = _pickMotivationQuote());
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'اقرأ رسالة جديدة',
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _showMotivationCard = false),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'إغلاق',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _motivationQuote,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.18), color.withOpacity(0.07)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final completionRate = widget.taskState.tasks.isEmpty
        ? 0
        : ((_completedTasksCount / widget.taskState.tasks.length) * 100)
            .round();
    final targetGpa = double.tryParse(_studentProfile.targetGpa) ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.14),
            Theme.of(context).cardColor,
            Theme.of(context).colorScheme.primary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك في Academic OS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'لديك ${widget.taskState.tasks.length} مهمة${widget.taskState.tasks.length == 1 ? '' : 'ات'} في قائمة اليوم',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'معدل الإنجاز: $completionRate%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: completionRate / 100,
                    minHeight: 9,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  ),
                ),
                if (targetGpa > 0) ...[
                  const SizedBox(height: 14),
                  Text(
                    'هدف المعدل: ${_estimatedGpa.toStringAsFixed(2)} / ${targetGpa.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _targetGpaProgress,
                      minHeight: 9,
                      color: const Color(0xFF7C3AED),
                      backgroundColor:
                          const Color(0xFF7C3AED).withOpacity(0.14),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _avatarText(_studentProfile.avatar),
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    final targetGpa = double.tryParse(_studentProfile.targetGpa) ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildQuickStatCard(
          icon: Icons.check_circle_outline,
          label: 'مكتملة',
          value: '$_completedTasksCount',
          color: const Color(0xFF16A34A),
        ),
        _buildQuickStatCard(
          icon: Icons.notifications_active_outlined,
          label: 'اليوم',
          value: '$_todayTasksCount',
          color: const Color(0xFF2563EB),
        ),
        _buildQuickStatCard(
          icon: Icons.pending_actions_rounded,
          label: 'معلقة',
          value: '$_pendingTasksCount',
          color: const Color(0xFFF59E0B),
        ),
        _buildQuickStatCard(
          icon: Icons.warning_amber_rounded,
          label: 'عاجلة',
          value: '$_urgentTasksCount',
          color: const Color(0xFFEA580C),
        ),
        _buildQuickStatCard(
          icon: Icons.trending_up_rounded,
          label: targetGpa > 0 ? 'المعدل / الهدف' : 'المعدل',
          value: targetGpa > 0
              ? '${_estimatedGpa.toStringAsFixed(2)} / ${targetGpa.toStringAsFixed(2)}'
              : _estimatedGpa.toStringAsFixed(2),
          color: const Color(0xFF7C3AED),
        ),
        _buildQuickStatCard(
          icon: Icons.school_rounded,
          label: 'الكورسات',
          value: '${_courses.length}',
          color: const Color(0xFF0EA5E9),
        ),
      ],
    );
  }

  Widget _buildSmartAcademicCard(BuildContext context) {
    final dashboard = const AcademicDashboardService().analyze(
      courses: _courses,
      tasks: widget.taskState.tasks,
      exams: const [],
    );

    final healthText = dashboard.studyHealthScore.round();
    final riskText = dashboard.atRiskCourses.isEmpty
        ? 'لا توجد مواد في خطر حاليًا.'
        : 'مواد تحتاج عناية إضافية: ${dashboard.atRiskCourses.join(' • ')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'القلب الذكي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$healthText%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            dashboard.focusMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            dashboard.nextPriorityAction,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.timeline_rounded, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dashboard.recommendedFocusBlock,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            riskText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummaryCard(BuildContext context) {
    final profile = _studentProfile;
    final major = profile.major.trim().isNotEmpty ? profile.major : 'غير محدد';
    final university =
        profile.university.trim().isNotEmpty ? profile.university : 'غير محدد';
    final target = double.tryParse(profile.targetGpa) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.12),
            Theme.of(context).cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _avatarText(profile.avatar),
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName.trim().isNotEmpty
                      ? profile.fullName
                      : 'ملف الطالب',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$major • $university',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  target > 0
                      ? 'هدف المعدل: ${target.toStringAsFixed(2)}'
                      : 'حدد هدفك الأكاديمي',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              OutlinedButton.icon(
                onPressed: _showProfileEditor,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('تعديل'),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => _showAboutDialog(context),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('عن النظام'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).colorScheme.primary.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDDEBFF), Color(0xFFEDE9FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1D4ED8),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 70,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'لا يوجد شيء هنا بعد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف أول مادة أو أول مهمة لبدء تنظيم دراستك',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditCourseScreen(
                          useCases: widget.courseUseCases,
                        ),
                      ),
                    );
                    await _loadTasks();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('إضافة أول مادة'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddEdit(null),
                  icon: const Icon(Icons.add_task_outlined),
                  label: const Text('إضافة أول مهمة'),
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _appLockService.updateLastActive();
    }
    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  List<TaskEntity> _filteredTasks() {
    return widget.taskUseCases.filterAndSortTasks(
      widget.taskState.tasks,
      searchQuery: _searchController.text,
      courseFilter: _selectedCourseFilter,
      statusFilter: _statusFilter.name,
      sortMode: _sortMode.name,
    );
  }

  Map<String, List<TaskEntity>> _groupTasksByCourse() {
    final groups = <String, List<TaskEntity>>{};
    for (final task in _filteredTasks()) {
      final groupName =
          (task.courseName != null && task.courseName!.trim().isNotEmpty)
              ? task.courseName!
              : 'بدون كورس';
      groups.putIfAbsent(groupName, () => []).add(task);
    }
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == 'بدون كورس') return 1;
        if (b == 'بدون كورس') return -1;
        return a.compareTo(b);
      });
    return {for (final key in sortedKeys) key: groups[key]!};
  }

  Widget _buildTaskCard(TaskEntity task) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;
    final dueDateLabel =
        task.dueDate != null ? 'استحقاق: ${_formatDate(task.dueDate!)}' : null;
    final timeWindowLabel = task.startDateTime != null ||
            task.endDateTime != null
        ? 'المدة: ${task.startDateTime != null ? _formatDateTime(task.startDateTime!) : '—'} → ${task.endDateTime != null ? _formatDateTime(task.endDateTime!) : '—'}'
        : null;

    return Dismissible(
      key: ValueKey(task.id ?? '${task.title}-${task.dueDate}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('تأكيد الحذف'),
                content: Text('هل تريد حذف المهمة "${task.title}"؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _deleteTask(task),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _navigateToAddEdit(task),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: task.isCompleted
                          ? [Colors.green.shade100, Colors.green.shade50]
                          : [Colors.blue.shade100, Colors.blue.shade50],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    task.isCompleted ? Icons.check_circle : Icons.task_alt,
                    color:
                        task.isCompleted ? Colors.green : Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: task.isCompleted,
                            onChanged: (_) => _toggleTaskCompletion(task),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (task.courseName != null &&
                              task.courseName!.isNotEmpty)
                            ActionChip(
                              label: Text(task.courseName!),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              onPressed: () => _openCourseDetailFromTask(task),
                            ),
                          if (dueDateLabel != null)
                            Chip(
                              label: Text(dueDateLabel),
                              backgroundColor: isOverdue
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              labelStyle: TextStyle(
                                color: isOverdue
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide.none,
                            ),
                          Chip(
                            label: Text(task.type.label),
                            backgroundColor: Colors.grey.shade200,
                            labelStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                            side: BorderSide.none,
                          ),
                          Chip(
                            label: Text('أولوية ${task.priority.label}'),
                            backgroundColor: Colors.orange.shade50,
                            labelStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                            side: BorderSide.none,
                          ),
                          Chip(
                            label: Text(task.recurrence.label),
                            backgroundColor: Colors.purple.shade50,
                            labelStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                      if (timeWindowLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          timeWindowLabel,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (task.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          task.notes,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteTask(task),
                  tooltip: 'حذف المهمة',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _avatarText(String avatar) {
    switch (avatar) {
      case 'laptop':
        return '💻';
      case 'book':
        return '📘';
      case 'rocket':
        return '🚀';
      case 'brain':
        return '🧠';
      case 'code':
        return '🧑‍💻';
      case 'graduation':
        return '🎓';
      default:
        return '🎓';
    }
  }

  Future<void> _showProfileEditor() async {
    final controllerName =
        TextEditingController(text: _studentProfile.fullName);
    final controllerUniversity =
        TextEditingController(text: _studentProfile.university);
    final controllerMajor = TextEditingController(text: _studentProfile.major);
    final controllerLevel =
        TextEditingController(text: _studentProfile.academicLevel);
    final controllerTarget =
        TextEditingController(text: _studentProfile.targetGpa);
    String selectedAvatar = _studentProfile.avatar;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final avatarItems = [
              ('student', '🎓'),
              ('laptop', '💻'),
              ('book', '📘'),
              ('rocket', '🚀'),
              ('brain', '🧠'),
              ('code', '🧑‍💻'),
            ];

            return AlertDialog(
              title: const Text('تعديل الملف الأكاديمي'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controllerName,
                      decoration:
                          const InputDecoration(labelText: 'اسم الطالب'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controllerUniversity,
                      decoration:
                          const InputDecoration(labelText: 'الجامعة / الكلية'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controllerMajor,
                      decoration:
                          const InputDecoration(labelText: 'التخصص الدراسي'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controllerLevel,
                      decoration:
                          const InputDecoration(labelText: 'المستوى الدراسي'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controllerTarget,
                      decoration:
                          const InputDecoration(labelText: 'المعدل المستهدف'),
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('اختيار الصورة الرمزية'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: avatarItems.map((entry) {
                        final key = entry.$1;
                        final emoji = entry.$2;
                        final isSelected = selectedAvatar == key;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedAvatar = key),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFDBEAFE)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;
    final profile = StudentProfile(
      fullName: controllerName.text.trim(),
      university: controllerUniversity.text.trim(),
      major: controllerMajor.text.trim(),
      academicLevel: controllerLevel.text.trim(),
      targetGpa: controllerTarget.text.trim(),
      avatar: selectedAvatar,
    );
    await StudentProfile.save(profile);
    if (!mounted) return;
    setState(() => _studentProfile = profile);
    _showWarmSnackBar('تم تحديث الملف الأكاديمي بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    if (_isAppLocked) {
      return PinLockScreen(
        appLockService: _appLockService,
        onVerified: () async {
          await _appLockService.updateLastActive();
          if (!mounted) return;
          setState(() {
            _isAppLocked = false;
          });
        },
      );
    }

    final isDark = widget.isDarkMode;

    return AcademicScaffoldBackground(
      padding: const EdgeInsets.all(0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 12,
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.isArabic ? 'مرحباً' : 'Welcome',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _studentProfile.fullName.isNotEmpty
                          ? _studentProfile.fullName
                          : 'Academic OS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _avatarText(_studentProfile.avatar),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: widget.isArabic ? 'بحث عام' : 'Global search',
              onPressed: () => _showGlobalSearch(),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined),
              tooltip: widget.isArabic
                  ? 'الإشعارات القادمة'
                  : 'Upcoming notifications',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpcomingNotificationsScreen(
                      taskUseCases: widget.taskUseCases,
                      courseUseCases: widget.courseUseCases,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          width: 330,
          backgroundColor: Colors.transparent,
          child: Container(
            margin:
                const EdgeInsets.only(top: 12, bottom: 12, left: 8, right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.96)
                  : Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E293B),
                        const Color(0xFF2563EB),
                        const Color(0xFF7C3AED),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.18),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _avatarText(_studentProfile.avatar),
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _studentProfile.fullName.isNotEmpty
                            ? _studentProfile.fullName
                            : 'Academic OS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _studentProfile.major.isNotEmpty
                              ? _studentProfile.major
                              : (widget.isArabic
                                  ? 'أمن سيبراني وشبكات'
                                  : 'Cyber Security & Networks'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDrawerSection(
                  title: 'القسم الأكاديمي',
                  items: [
                    _DrawerItem(
                      icon: Icons.dashboard_customize_rounded,
                      label: widget.isArabic ? 'لوحة التحكم' : 'Dashboard',
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerItem(
                      icon: Icons.school_rounded,
                      label: widget.isArabic ? 'الكورسات' : 'Courses',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseListScreen(
                              courseUseCases: widget.courseUseCases,
                              taskUseCases: widget.taskUseCases,
                            ),
                          ),
                        ).then((res) {
                          if (res == true) _loadCourses();
                        });
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.analytics_outlined,
                      label: widget.isArabic
                          ? 'توزيع الدرجات والمعدل'
                          : 'Grade distribution',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GradeDistributionScreen()),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.task_alt_rounded,
                      label: widget.isArabic ? 'المهام' : 'Tasks',
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerItem(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Copilot',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AcademicAiScreen(
                              courses: _courses,
                              tasks: widget.taskState.tasks,
                              exams: const [],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDrawerSection(
                  title: 'أدوات الإنتاجية',
                  items: [
                    _DrawerItem(
                      icon: Icons.book_online_rounded,
                      label: widget.isArabic
                          ? 'مخطط المذاكرة الذكي'
                          : 'Study Planner',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudyPlannerScreen(
                              courseUseCases: widget.courseUseCases,
                            ),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.timer_rounded,
                      label: widget.isArabic ? 'وضع التركيز' : 'Focus Mode',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FocusTimerScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.backup_table_rounded,
                      label: widget.isArabic
                          ? 'النسخ الاحتياطي والتقارير'
                          : 'Backup & Reports',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BackupExportScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDrawerSection(
                  title: 'إدارة الحساب',
                  items: [
                    _DrawerItem(
                      icon: Icons.person_2_rounded,
                      label: widget.isArabic
                          ? 'تعديل الملف الأكاديمي'
                          : 'Edit profile',
                      onTap: () {
                        Navigator.pop(context);
                        _showProfileEditor();
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.account_circle_outlined,
                      label: widget.isArabic ? 'بيانات الطالب' : 'Student info',
                      onTap: () {
                        Navigator.pop(context);
                        _showProfileEditor();
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.info_rounded,
                      label: widget.isArabic ? 'عن المطور' : 'About developer',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.logout_rounded,
                      label: widget.isArabic ? 'تسجيل الخروج' : 'Logout',
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await widget.authUseCases.logout.call();
                        } catch (error, stackTrace) {
                          debugPrint(
                            'HomeScreen.logout error: $error\n$stackTrace',
                          );
                        }
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => AuthGateScreen(
                              authUseCases: widget.authUseCases,
                              taskUseCases: widget.taskUseCases,
                              courseUseCases: widget.courseUseCases,
                              isDarkMode: widget.isDarkMode,
                              isArabic: widget.isArabic,
                              onThemeChanged: widget.onThemeChanged,
                              onLanguageChanged: widget.onLanguageChanged,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDrawerSection(
                  title: 'التفضيلات والنظام',
                  items: [
                    _DrawerSwitchItem(
                      icon: Icons.dark_mode_rounded,
                      label: widget.isArabic ? 'الوضع الداكن' : 'Dark mode',
                      value: widget.isDarkMode,
                      onChanged: widget.onThemeChanged,
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: const Icon(Icons.info_outline, size: 22),
                      title: const Text(
                        'عن النظام والمنظومة',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text(
                        'نبذة عن Academic OS ورؤيته الأكاديمية',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_left, size: 18),
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: widget.taskState.errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.taskState.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadTasks,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTasks,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_showMotivationCard) _buildMotivationCard(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildHeaderSection(context),
                            ),
                            const SizedBox(height: 12),
                            _buildAccountSummaryCard(context),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildSummaryRow(context),
                            ),
                            const SizedBox(height: 16),
                            _buildSmartAcademicCard(context),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: TextFormField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search_outlined),
                                  hintText: 'ابحث عن مادة، مهمة، أو ملاحظة...',
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                      TaskSearchStatus.values.map((status) {
                                    final isSelected = _statusFilter == status;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: ChoiceChip(
                                        label: Text(status.label),
                                        selected: isSelected,
                                        onSelected: (_) async =>
                                            _saveStatusFilter(status),
                                        selectedColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.18),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCourseFilter ?? 'الكل',
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Theme.of(context).cardColor,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                      ),
                                      items: _courseFilterOptions
                                          .map((option) => DropdownMenuItem(
                                                value: option,
                                                child: Text(option),
                                              ))
                                          .toList(),
                                      onChanged: (value) async {
                                        if (value == null) return;
                                        await _saveCourseFilter(value);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<TaskSortMode>(
                                    initialValue: _sortMode,
                                    tooltip: 'ترتيب المهام',
                                    icon: const Icon(Icons.sort_rounded),
                                    onSelected: (mode) async =>
                                        _saveSortMode(mode),
                                    itemBuilder: (context) =>
                                        TaskSortMode.values
                                            .map((mode) => PopupMenuItem(
                                                  value: mode,
                                                  child: Text(mode.label),
                                                ))
                                            .toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.35,
                                children: [
                                  _buildServiceCard(
                                    icon: Icons.checklist_rtl_outlined,
                                    title: 'المهام',
                                    subtitle: 'إدارة الواجبات والمهام',
                                    onTap: () => _navigateToAddEdit(null),
                                  ),
                                  _buildServiceCard(
                                    icon: Icons.calendar_month_outlined,
                                    title: 'الجدول',
                                    subtitle: 'مواعيد المحاضرات',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ScheduleScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildServiceCard(
                                    icon: Icons.timer_outlined,
                                    title: 'وضع التركيز',
                                    subtitle: 'جلسات بومودورو',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const FocusTimerScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildServiceCard(
                                    icon: Icons.menu_book_outlined,
                                    title: 'الكورسات',
                                    subtitle: 'المقررات والمواد الدراسية',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CourseListScreen(
                                            courseUseCases:
                                                widget.courseUseCases,
                                            taskUseCases: widget.taskUseCases,
                                          ),
                                        ),
                                      ).then((res) {
                                        if (res == true) _loadCourses();
                                      });
                                    },
                                  ),
                                  _buildServiceCard(
                                    icon: Icons.smart_toy_outlined,
                                    title: 'المساعد الذكي',
                                    subtitle: 'خطة ذكية ومشورة أكاديمية',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AcademicAiScreen(
                                            courses: _courses,
                                            tasks: widget.taskState.tasks,
                                            exams: const [],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildServiceCard(
                                    icon: Icons.auto_stories_outlined,
                                    title: 'خطة المذاكرة',
                                    subtitle: 'خطة أسبوعية للمواد',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudyPlannerScreen(
                                            courseUseCases:
                                                widget.courseUseCases,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildServiceCard(
                                    icon: Icons.backup_table_outlined,
                                    title: 'النسخ الاحتياطي',
                                    subtitle: 'احتياطيات وتقارير أكاديمية',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const BackupExportScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildServiceCard(
                                    icon: Icons.notifications_active_outlined,
                                    title: 'التذكيرات',
                                    subtitle: 'مهام قادمة ومواعيدك',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              UpcomingNotificationsScreen(
                                            taskUseCases: widget.taskUseCases,
                                            courseUseCases:
                                                widget.courseUseCases,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: widget.taskState.tasks.isEmpty
                                  ? _buildEmptyState(context)
                                  : Column(
                                      children: _groupTasksByCourse()
                                          .entries
                                          .expand((entry) {
                                        final groupTitle = entry.key;
                                        final tasks = entry.value;
                                        return [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                24, 20, 16, 8),
                                            child: Text(
                                              groupTitle,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24),
                                            child: Text(
                                              '${tasks.length} ${widget.isArabic ? 'مهمة' : 'task'}${tasks.length == 1 ? '' : widget.isArabic ? 'ات' : 's'}',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...tasks.map(_buildTaskCard),
                                        ];
                                      }).toList(),
                                    ),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: NavigationBar(
              height: 68,
              backgroundColor: Theme.of(context).cardColor,
              surfaceTintColor: Colors.transparent,
              selectedIndex: _selectedBottomNav,
              onDestinationSelected: (index) {
                setState(() => _selectedBottomNav = index);
                switch (index) {
                  case 1:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                    );
                    break;
                  case 2:
                    _navigateToAddEdit(null);
                    break;
                  case 3:
                    _showProfileEditor();
                    break;
                  default:
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'الجداول',
                ),
                NavigationDestination(
                  icon: Icon(Icons.task_alt_outlined),
                  selectedIcon: Icon(Icons.task_alt_rounded),
                  label: 'المهام',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'الملف الشخصي',
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FloatingActionButton.extended(
            onPressed: () => _navigateToAddEdit(null),
            icon: const Icon(Icons.add_task_outlined),
            label: Text(widget.isArabic ? 'مهمة جديدة' : 'New task'),
          ),
        ),
      ),
    );
  }
}
