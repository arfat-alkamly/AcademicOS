import 'dart:convert';

import '../../data/models/course_model.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/task_model.dart';
import '../../domain/entities/task_entity.dart';

class AcademicReportService {
  const AcademicReportService();

  Map<String, dynamic> buildBackupPayload({
    required List<CourseModel> courses,
    required List<TaskModel> tasks,
    required List<ExamModel> exams,
    required List<Map<String, dynamic>> schedule,
    String schema = 'academic_os_backup_v1',
  }) {
    final payload = <String, dynamic>{
      'schema': schema,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'courses': courses.map((course) => course.toMap()).toList(),
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'exams': exams.map((exam) => exam.toMap()).toList(),
      'schedule': schedule,
    };
    return payload;
  }

  String encodeBackupJson(Map<String, dynamic> payload) {
    final compactJson = const JsonEncoder.withIndent('  ').convert(payload);
    return base64.encode(utf8.encode(compactJson));
  }

  String generateAcademicReport({
    required List<CourseModel> courses,
    required List<TaskModel> tasks,
    required List<ExamModel> exams,
    required List<Map<String, dynamic>> schedule,
  }) {
    final sortedSchedule = [...schedule]..sort((a, b) {
        final aTime = a['start_time']?.toString() ?? '00:00';
        final bTime = b['start_time']?.toString() ?? '00:00';
        return aTime.compareTo(bTime);
      });

    final upcomingExams = [...exams]
      ..sort((a, b) => a.examDate.compareTo(b.examDate));

    final totalCredits = courses.fold<int>(0, (sum, course) {
      final credits = course.creditHours ?? 3;
      return sum + credits;
    });

    double weightedGpa = 0;
    for (final course in courses) {
      final average = ((course.midGrade ?? 0) +
              (course.practicalGrade ?? 0) +
              (course.finalGrade ?? 0)) /
          3;
      final credits = course.creditHours ?? 3;
      weightedGpa += average * credits;
    }

    final averageGpa = totalCredits == 0 ? 0.0 : weightedGpa / totalCredits;
    final pendingTasks = tasks.where((task) => !task.isCompleted).length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final urgentTasks = tasks
        .where(
            (task) => !task.isCompleted && task.priority == TaskPriority.urgent)
        .length;

    final lines = <String>[
      'Academic OS — Academic Report',
      'Generated: ${DateTime.now().toLocal()}',
      '',
      'Summary:',
      '• Completed tasks: $completedTasks',
      '• Pending tasks: $pendingTasks',
      '• Urgent tasks: $urgentTasks',
      '• Estimated GPA: ${averageGpa.toStringAsFixed(2)}',
      '',
      'GPA Breakdown:',
    ];

    if (courses.isEmpty) {
      lines.add('• No courses available.');
    } else {
      for (final course in courses) {
        final average = ((course.midGrade ?? 0) +
                (course.practicalGrade ?? 0) +
                (course.finalGrade ?? 0)) /
            3;
        lines.add(
          '• ${course.name} (${course.code}) | average: ${average.toStringAsFixed(1)} | credit hours: ${course.creditHours ?? 3}',
        );
      }
    }

    lines.add('');
    lines.add('Upcoming Exam Timetable:');
    if (upcomingExams.isEmpty) {
      lines.add('• No upcoming exams found.');
    } else {
      for (final exam in upcomingExams.take(5)) {
        lines.add(
          '• ${exam.title} | ${exam.examDate.toLocal().toString().split(' ').first} | ${exam.courseName ?? 'General'}',
        );
      }
    }

    lines.add('');
    lines.add('Current Schedule:');
    if (sortedSchedule.isEmpty) {
      lines.add('• No lecture sessions added.');
    } else {
      for (final item in sortedSchedule) {
        final day = item['day_of_week'] ?? 'Unknown';
        final time = item['start_time'] ?? '00:00';
        final location = item['location'] ?? 'Unknown';
        lines.add('• $day | $time | $location');
      }
    }

    return lines.join('\n');
  }
}
