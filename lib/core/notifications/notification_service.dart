import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/course_entity.dart';
import '../../domain/entities/task_entity.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      } catch (_) {
        // Fallback to local timezone if the region is unavailable.
      }

      const androidInitializationSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
      );
      await _plugin.initialize(initializationSettings);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      const taskChannel = AndroidNotificationChannel(
        'academic_os_tasks',
        'Task reminders',
        description: 'Reminders for tasks and deadlines',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const courseChannel = AndroidNotificationChannel(
        'academic_os_courses',
        'Lecture reminders',
        description: 'Reminders for lectures and course events',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidPlugin?.createNotificationChannel(taskChannel);
      await androidPlugin?.createNotificationChannel(courseChannel);
    } catch (error, stackTrace) {
      debugPrint('NotificationService.initialize error: $error\n$stackTrace');
    }
  }

  static DateTime? resolveReminderDate({
    required bool reminderEnabled,
    required DateTime? dueDate,
    required DateTime? reminderDate,
    required int reminderOffsetMinutes,
  }) {
    if (!reminderEnabled) {
      return null;
    }

    if (reminderDate != null) {
      return reminderDate;
    }

    if (dueDate == null) {
      return null;
    }

    return dueDate.subtract(Duration(minutes: reminderOffsetMinutes));
  }

  int _taskNotificationId(int id) => id + 10000;

  int _courseNotificationId(int id) => id + 20000;

  int _lectureNotificationId(int id) => id + 30000;

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      final canScheduleExact = await androidPlugin?.canScheduleExactNotifications();
      if (canScheduleExact == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService exact-alarm permission check failed: $error\\n$stackTrace',
      );
    }

    // Keep reminders working when Android exact-alarm access is unavailable.
    // Delivery may be delayed by Android battery optimizations.
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static int? _arabicWeekdayToDateTimeWeekday(String? weekdayName) {
    switch (weekdayName) {
      case 'السبت':
        return 6;
      case 'الأحد':
        return 7;
      case 'الاثنين':
        return 1;
      case 'الثلاثاء':
        return 2;
      case 'الأربعاء':
        return 3;
      case 'الخميس':
        return 4;
      case 'الجمعة':
        return 5;
      default:
        return null;
    }
  }

  static DateTime? resolveLectureReminderDate({
    required DateTime now,
    required String weekdayName,
    required String startTime,
    required int reminderOffsetMinutes,
  }) {
    final targetWeekday = _arabicWeekdayToDateTimeWeekday(weekdayName);
    if (targetWeekday == null) return null;

    final timeParts = startTime.split(':');
    final hour = int.tryParse(timeParts.first) ?? 0;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
    final lectureStart = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    var diffDays = (targetWeekday - now.weekday + 7) % 7;
    if (diffDays == 0 && lectureStart.isBefore(now)) {
      diffDays = 7;
    }

    final nextLectureDate = now.add(Duration(days: diffDays));
    final reminder = DateTime(
      nextLectureDate.year,
      nextLectureDate.month,
      nextLectureDate.day,
      hour,
      minute,
    ).subtract(Duration(minutes: reminderOffsetMinutes));

    return reminder.isBefore(now)
        ? reminder.add(const Duration(days: 7))
        : reminder;
  }

  Future<void> scheduleTaskReminder(TaskEntity task) async {
    if (kIsWeb || task.id == null) {
      return;
    }

    final scheduledAt = resolveReminderDate(
      reminderEnabled: task.reminderEnabled,
      dueDate: task.dueDate,
      reminderDate: task.reminderDate,
      reminderOffsetMinutes: task.reminderOffsetMinutes,
    );

    if (scheduledAt == null || scheduledAt.isBefore(DateTime.now())) {
      await cancelTaskReminder(task.id!);
      return;
    }

    try {
      await _plugin.zonedSchedule(
        _taskNotificationId(task.id!),
        'تذكير: ${task.title}',
        task.description.isNotEmpty
            ? task.description
            : 'لا تنسَ المهمة التي أضفتها.',
        tz.TZDateTime.from(scheduledAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'academic_os_tasks',
            'Task reminders',
            channelDescription: 'Reminders for tasks and deadlines',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: await _resolveAndroidScheduleMode(),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService.scheduleTaskReminder error: $error\n$stackTrace',
      );
    }
  }

  Future<void> scheduleCourseReminder(CourseEntity course) async {
    if (kIsWeb || course.id == null) {
      return;
    }

    final scheduledAt = resolveReminderDate(
      reminderEnabled: course.lectureReminderEnabled,
      dueDate: course.lectureDate,
      reminderDate: course.lectureDate,
      reminderOffsetMinutes: course.lectureReminderOffsetMinutes,
    );

    if (scheduledAt == null || scheduledAt.isBefore(DateTime.now())) {
      await cancelCourseReminder(course.id!);
      return;
    }

    try {
      await _plugin.zonedSchedule(
        _courseNotificationId(course.id!),
        'محاضرة قريبة: ${course.name}',
        course.notes?.isNotEmpty == true
            ? course.notes!
            : 'لا تنسَ موعد المحاضرة القادمة.',
        tz.TZDateTime.from(scheduledAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'academic_os_courses',
            'Lecture reminders',
            channelDescription: 'Reminders for lectures and course events',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: await _resolveAndroidScheduleMode(),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService.scheduleCourseReminder error: $error\n$stackTrace',
      );
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    try {
      await _plugin.cancel(_taskNotificationId(taskId));
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService.cancelTaskReminder error: $error\n$stackTrace',
      );
    }
  }

  Future<void> cancelCourseReminder(int courseId) async {
    try {
      await _plugin.cancel(_courseNotificationId(courseId));
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService.cancelCourseReminder error: $error\n$stackTrace',
      );
    }
  }

  Future<void> scheduleLectureReminder({
    required int id,
    required String title,
    required String weekdayName,
    required String startTime,
    required bool reminderEnabled,
    String? location,
    int reminderOffsetMinutes = 15,
  }) async {
    if (kIsWeb || !reminderEnabled) {
      await cancelLectureReminder(id);
      return;
    }

    final scheduledAt = resolveLectureReminderDate(
      now: DateTime.now(),
      weekdayName: weekdayName,
      startTime: startTime,
      reminderOffsetMinutes: reminderOffsetMinutes,
    );

    if (scheduledAt == null || scheduledAt.isBefore(DateTime.now())) {
      await cancelLectureReminder(id);
      return;
    }

    try {
      await _plugin.zonedSchedule(
        _lectureNotificationId(id),
        'محاضرة قريبة: $title',
        location != null && location.isNotEmpty
            ? 'الموقع: $location'
            : 'لا تنس موعد المحاضرة القادمة.',
        tz.TZDateTime.from(scheduledAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'academic_os_courses',
            'Lecture reminders',
            channelDescription: 'Reminders for lectures and course events',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: await _resolveAndroidScheduleMode(),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService.scheduleLectureReminder error: $error\n$stackTrace',
      );
    }
  }

  Future<void> cancelLectureReminder(int scheduleId) async {
    try {
      await _plugin.cancel(_lectureNotificationId(scheduleId));
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService.cancelLectureReminder error: $error\n$stackTrace',
      );
    }
  }

  Future<void> syncReminders({
    required List<TaskEntity> tasks,
    required List<CourseEntity> courses,
  }) async {
    if (kIsWeb) return;

    for (final task in tasks) {
      if (task.id == null) {
        continue;
      }
      if (task.reminderEnabled) {
        await scheduleTaskReminder(task);
      } else {
        await cancelTaskReminder(task.id!);
      }
    }

    for (final course in courses) {
      if (course.id == null) {
        continue;
      }
      if (course.lectureReminderEnabled) {
        await scheduleCourseReminder(course);
      } else {
        await cancelCourseReminder(course.id!);
      }
    }
  }
}
