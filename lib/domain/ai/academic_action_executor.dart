import 'dart:math' as math;

import '../../data/database/database_helper.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/task_entity.dart';

class AcademicActionExecutor {
  final DatabaseHelper _databaseHelper;

  AcademicActionExecutor(this._databaseHelper);

  Future<Map<String, dynamic>> execute(
      String action, Map<String, dynamic> payload) async {
    final db = await _databaseHelper.database;

    if (action == 'register_schedule') {
      final day = payload['day'] ?? 'اليوم';
      final time = payload['time'] ?? '09:00';
      final hall = payload['hall'] ?? 'المبنى الرئيسي';
      final courseName = payload['courseName'] ?? 'مادة';

      final courseRows = await db.query(
        'courses',
        where: 'name = ?',
        whereArgs: [courseName],
        limit: 1,
      );
      final courseId =
          courseRows.isNotEmpty ? courseRows.first['id'] as int? : null;

      final scheduleId = await db.insert(
        'schedule',
        {
          'course_id': courseId,
          'day_of_week': day,
          'start_time': time,
          'end_time': time,
          'location': hall,
          'reminder_enabled': 1,
        },
      );

      return {
        'success': true,
        'message': 'تم تسجيل المحاضرة في الجدول: $courseName • $day • $time',
        'scheduleId': scheduleId,
      };
    }

    if (action == 'create_task') {
      final title = payload['title'] ?? 'مهمة جديدة';
      final courseName = payload['courseName'];
      final dueDate = payload['dueDate'];
      final priority = payload['priority'] ?? 'medium';

      final courseRows = courseName != null
          ? await db.query(
              'courses',
              where: 'name = ?',
              whereArgs: [courseName],
              limit: 1,
            )
          : const [];

      final courseId =
          courseRows.isNotEmpty ? courseRows.first['id'] as int? : null;
      final taskId = await db.insert(
        'tasks',
        {
          'title': title,
          'description':
              payload['description'] ?? 'تمت الإضافة من المساعد الأكاديمي.',
          'type': payload['type'] ?? 'study',
          'due_date': dueDate ?? DateTime.now().toIso8601String(),
          'is_completed': 0,
          'course_id': courseId,
          'course_name': courseName,
          'priority': priority,
          'recurrence': 'once',
          'notes': '',
          'reminder_enabled': 0,
          'reminder_offset_minutes': 30,
        },
      );

      return {
        'success': true,
        'message': 'تم إنشاء المهمة بنجاح في $courseName.',
        'taskId': taskId,
      };
    }

    if (action == 'calculate_target') {
      final currentEarned = (payload['currentEarned'] as num?)?.toDouble() ?? 0;
      final maxScore = (payload['maxScore'] as num?)?.toDouble() ?? 50;
      final finalWeight = (payload['finalWeight'] as num?)?.toDouble() ?? 50;

      final currentPercent =
          maxScore == 0 ? 0 : (currentEarned / maxScore) * 100;
      final weightedCurrent = currentPercent * ((100 - finalWeight) / 100);

      final Map<String, double> results = {
        'A': _requiredFinalScore(90, weightedCurrent, finalWeight),
        'B': _requiredFinalScore(80, weightedCurrent, finalWeight),
        'C': _requiredFinalScore(70, weightedCurrent, finalWeight),
        'Pass50': _requiredFinalScore(50, weightedCurrent, finalWeight),
        'Pass60': _requiredFinalScore(60, weightedCurrent, finalWeight),
      };

      return {
        'success': true,
        'results': results,
        'message': 'تم حساب متطلبات الدرجة النهائية حسب هدفك.',
      };
    }

    if (action == 'attendance_check') {
      final attended = (payload['attended'] as num?)?.toDouble() ?? 0;
      final total = (payload['total'] as num?)?.toDouble() ?? 1;
      final percent = total == 0 ? 0 : (attended / total) * 100;
      final alert = percent < 75
          ? 'تحذير: نسبة الحضور قريبة من الحد المسموح.'
          : 'الحضور جيد.';

      return {
        'success': true,
        'attendancePercent': percent,
        'status': alert,
      };
    }

    if (action == 'study_plan') {
      final chapters = (payload['chapters'] as num?)?.toInt() ?? 10;
      final days = (payload['days'] as num?)?.toInt() ?? 5;
      final hours = (payload['hours'] as num?)?.toInt() ?? 2;
      final items = <Map<String, dynamic>>[];
      final perDay = math.max(1, (chapters / days).ceil());

      for (var i = 1; i <= days; i++) {
        final start = (i - 1) * perDay + 1;
        final end = math.min(chapters, i * perDay);
        final last = i == days;
        items.add({
          'day': 'Day $i',
          'title': last
              ? 'مراجعة شاملة + أسئلة'
              : 'الفصول ${start.toString()}-${end.toString()}',
          'hours': hours,
          'summary': last
              ? 'مراجعة شاملة، أسئلة سريعة، وتلخيص للنقاط المهمة.'
              : 'دراسة الفصل ${start.toString()} إلى ${end.toString()} مع تمرين قصير.',
        });
      }

      return {
        'success': true,
        'plan': items,
      };
    }

    return {
      'success': false,
      'message': 'إجراء غير مدعوم في المساعد الأكاديمي.',
    };
  }

  double _requiredFinalScore(
      double target, double weightedCurrent, double finalWeight) {
    if (finalWeight <= 0 || finalWeight >= 100) return 0;
    final required = ((target - weightedCurrent) / finalWeight) * 100;
    return required.clamp(0, 100);
  }
}
