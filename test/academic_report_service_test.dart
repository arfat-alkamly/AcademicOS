import 'package:flutter_test/flutter_test.dart';
import 'package:academic_os/core/academic/academic_report_service.dart';
import 'package:academic_os/data/models/course_model.dart';
import 'package:academic_os/data/models/exam_model.dart';
import 'package:academic_os/data/models/task_model.dart';

void main() {
  group('AcademicReportService', () {
    test('builds a valid backup payload structure', () {
      final service = AcademicReportService();

      final payload = service.buildBackupPayload(
        courses: [
          const CourseModel(
            id: 1,
            name: 'Math',
            instructor: 'Dr. Ali',
            code: 'MTH101',
            creditHours: 3,
            midGrade: 80,
            practicalGrade: 85,
            finalGrade: 90,
          ),
        ],
        tasks: [
          const TaskModel(
            id: 1,
            title: 'Finish homework',
            description: 'Submit assignment',
            dueDate: null,
          ),
        ],
        exams: [
          ExamModel(
            id: 1,
            title: 'Midterm',
            examDate: DateTime(2026, 10, 20),
            courseName: 'Math',
          ),
        ],
        schedule: [
          {
            'day_of_week': 'Monday',
            'start_time': '09:00',
            'location': 'Room 1'
          },
        ],
      );

      expect(payload['schema'], 'academic_os_backup_v1');
      expect(payload['courses'], isA<List>());
      expect(payload['tasks'], hasLength(1));
      expect(payload['exams'], hasLength(1));
      expect(payload['schedule'], hasLength(1));
    });

    test('generates a readable academic report', () {
      final service = AcademicReportService();

      final report = service.generateAcademicReport(
        courses: [
          const CourseModel(
            id: 1,
            name: 'Math',
            instructor: 'Dr. Ali',
            code: 'MTH101',
            creditHours: 3,
            midGrade: 80,
            practicalGrade: 85,
            finalGrade: 90,
          ),
        ],
        tasks: const [
          TaskModel(
            id: 1,
            title: 'Homework',
            description: 'Solve 5 questions',
            dueDate: null,
            isCompleted: false,
          ),
        ],
        exams: [
          ExamModel(
            id: 1,
            title: 'Midterm',
            examDate: DateTime(2026, 10, 20),
            courseName: 'Math',
          ),
        ],
        schedule: [
          {
            'day_of_week': 'Monday',
            'start_time': '09:00',
            'location': 'Room 1'
          },
        ],
      );

      expect(report, contains('Academic OS'));
      expect(report, contains('GPA Breakdown'));
      expect(report, contains('Math'));
    });
  });
}
