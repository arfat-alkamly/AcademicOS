import 'package:academic_os/core/academic/academic_assistant_service.dart';
import 'package:academic_os/data/models/course_model.dart';
import 'package:academic_os/data/models/exam_model.dart';
import 'package:academic_os/data/models/task_model.dart';
import 'package:academic_os/domain/entities/task_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcademicAssistantService', () {
    test('builds a response from real course and task data', () {
      final courses = [
        const CourseModel(
          id: 1,
          name: 'المنطق',
          instructor: 'د. أحمد',
          code: 'LOG-101',
          midGrade: 80,
          practicalGrade: 85,
          finalGrade: 90,
        ),
        const CourseModel(
          id: 2,
          name: 'البرمجة',
          instructor: 'د. سارة',
          code: 'PRO-204',
          midGrade: 70,
          practicalGrade: 75,
          finalGrade: 65,
        ),
      ];

      final tasks = [
        const TaskModel(
          id: 1,
          title: 'حل واجب المنطق',
          description: 'حل أسئلة الوحدة الثالثة',
          courseName: 'المنطق',
          dueDate: null,
          priority: TaskPriority.high,
          isCompleted: false,
        ),
        const TaskModel(
          id: 2,
          title: 'تجربة البرمجة',
          description: 'إرسال المشروع التقني',
          courseName: 'البرمجة',
          dueDate: null,
          priority: TaskPriority.urgent,
          isCompleted: false,
        ),
      ];

      final exams = [
        ExamModel(
          id: 1,
          title: 'اختبار المنطق',
          courseName: 'المنطق',
          examDate: DateTime.now().add(const Duration(days: 3)),
        ),
      ];

      final service = const AcademicAssistantService();
      final result = service.buildResponse(
        input: 'ما هو رأيك في حالتي الأكاديمية؟',
        courses: courses,
        tasks: tasks,
        exams: exams,
      );

      expect(result.response, contains('المنطق'));
      expect(result.response, contains('البرمجة'));
      expect(result.response, contains('مهمة عاجلة'));
    });
  });
}
