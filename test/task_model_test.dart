import 'package:flutter_test/flutter_test.dart';
import 'package:academic_os/data/models/task_model.dart';
import 'package:academic_os/domain/entities/task_entity.dart';

void main() {
  group('TaskModel', () {
    test('fromMap and toMap preserve fields correctly', () {
      final task = TaskModel(
        id: 5,
        title: 'Sample',
        description: 'Sample description',
        type: TaskType.exam,
        priority: TaskPriority.urgent,
        recurrence: TaskRecurrence.weekly,
        dueDate: DateTime(2026, 12, 31),
        startDateTime: DateTime(2026, 12, 30, 18),
        endDateTime: DateTime(2026, 12, 30, 20),
        isCompleted: true,
        courseId: 3,
        courseName: 'Math 101',
        notes: 'Review chapters 1-3',
        reminderEnabled: true,
        reminderDate: DateTime(2026, 12, 30, 20),
        reminderOffsetMinutes: 15,
      );

      final map = task.toMap();
      expect(map['id'], 5);
      expect(map['title'], 'Sample');
      expect(map['description'], 'Sample description');
      expect(map['type'], 'exam');
      expect(map['priority'], 'urgent');
      expect(map['recurrence'], 'weekly');
      expect(map['due_date'], '2026-12-31T00:00:00.000');
      expect(map['start_date_time'], '2026-12-30T18:00:00.000');
      expect(map['end_date_time'], '2026-12-30T20:00:00.000');
      expect(map['is_completed'], 1);
      expect(map['course_id'], 3);
      expect(map['course_name'], 'Math 101');
      expect(map['notes'], 'Review chapters 1-3');
      expect(map['reminder_enabled'], 1);
      expect(map['reminder_date'], '2026-12-30T20:00:00.000');
      expect(map['reminder_offset_minutes'], 15);

      final parsed = TaskModel.fromMap(map);
      expect(parsed.id, 5);
      expect(parsed.title, 'Sample');
      expect(parsed.description, 'Sample description');
      expect(parsed.type, TaskType.exam);
      expect(parsed.priority, TaskPriority.urgent);
      expect(parsed.recurrence, TaskRecurrence.weekly);
      expect(parsed.dueDate, DateTime(2026, 12, 31));
      expect(parsed.startDateTime, DateTime(2026, 12, 30, 18));
      expect(parsed.endDateTime, DateTime(2026, 12, 30, 20));
      expect(parsed.isCompleted, isTrue);
      expect(parsed.courseId, 3);
      expect(parsed.courseName, 'Math 101');
      expect(parsed.notes, 'Review chapters 1-3');
      expect(parsed.reminderEnabled, isTrue);
      expect(parsed.reminderDate, DateTime(2026, 12, 30, 20));
      expect(parsed.reminderOffsetMinutes, 15);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 2,
        'title': 'No due date',
        'description': 'No due date description',
        'type': 'homework',
        'is_completed': 0,
      };

      final parsed = TaskModel.fromMap(map);
      expect(parsed.id, 2);
      expect(parsed.dueDate, isNull);
      expect(parsed.type, TaskType.homework);
      expect(parsed.priority, TaskPriority.medium);
      expect(parsed.recurrence, TaskRecurrence.once);
      expect(parsed.isCompleted, isFalse);
      expect(parsed.reminderEnabled, isFalse);
      expect(parsed.reminderOffsetMinutes, 30);
    });
  });
}
