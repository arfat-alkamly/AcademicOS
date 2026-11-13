import 'package:academic_os/core/academic/academic_dashboard_service.dart';
import 'package:academic_os/data/models/course_model.dart';
import 'package:academic_os/data/models/exam_model.dart';
import 'package:academic_os/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcademicDashboardService', () {
    test('summarizes real academic workload correctly', () {
      final service = AcademicDashboardService();

      final summary = service.analyze(
        courses: const [
          CourseModel(
            id: 1,
            name: 'Math',
            instructor: 'Dr. Ali',
            code: 'MTH101',
            creditHours: 3,
            midGrade: 80,
            practicalGrade: 85,
            finalGrade: 90,
          ),
          CourseModel(
            id: 2,
            name: 'Physics',
            instructor: 'Dr. Noor',
            code: 'PHY201',
            creditHours: 4,
            midGrade: 70,
            practicalGrade: 75,
            finalGrade: 80,
          ),
        ],
        tasks: const [
          TaskModel(
            id: 1,
            title: 'Assignment 1',
            description: 'Submit',
            dueDate: null,
            isCompleted: true,
          ),
          TaskModel(
            id: 2,
            title: 'Assignment 2',
            description: 'Solve',
            dueDate: null,
            isCompleted: false,
          ),
        ],
        exams: [
          ExamModel(
            id: 1,
            title: 'Midterm',
            examDate: DateTime.now().add(const Duration(days: 7)),
            courseName: 'Math',
          ),
        ],
      );

      expect(summary.totalCourses, 2);
      expect(summary.totalTasks, 2);
      expect(summary.completedTasks, 1);
      expect(summary.pendingTasks, 1);
      expect(summary.upcomingExams, 1);
      expect(summary.averageCourseScore, closeTo(80.0, 0.01));
      expect(summary.taskCompletionRate, closeTo(50.0, 0.01));
      expect(summary.focusMessage, isNotEmpty);
    });
  });
}
