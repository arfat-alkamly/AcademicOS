import 'package:flutter_test/flutter_test.dart';
import 'package:academic_os/core/notifications/notification_service.dart';
import 'package:academic_os/domain/entities/task_entity.dart';
import 'package:academic_os/domain/repositories/task_repository.dart';
import 'package:academic_os/domain/usecases/task_use_cases.dart';

class MockTaskRepository implements TaskRepository {
  final List<TaskEntity> tasks = [];

  @override
  Future<int> addTask(TaskEntity task) async {
    final newTask = TaskEntity(
      id: tasks.length + 1,
      title: task.title,
      description: task.description,
      type: task.type,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
    );
    tasks.add(newTask);
    return newTask.id!;
  }

  @override
  Future<int> deleteTask(int id) async {
    tasks.removeWhere((task) => task.id == id);
    return 1;
  }

  @override
  Future<TaskEntity?> fetchTaskById(int id) async {
    final match = tasks.where((task) => task.id == id).toList();
    if (match.isEmpty) {
      return null;
    }
    return match.first;
  }

  @override
  Future<List<TaskEntity>> fetchTasks() async {
    return tasks;
  }

  @override
  Future<int> updateTask(TaskEntity task) async {
    final index = tasks.indexWhere((existing) => existing.id == task.id);
    if (index < 0) {
      throw ArgumentError('Task id is required for update.');
    }
    tasks[index] = TaskEntity(
      id: task.id,
      title: task.title,
      description: task.description,
      type: task.type,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
    );
    return 1;
  }
}

void main() {
  group('TaskUseCases', () {
    late MockTaskRepository repository;
    late TaskUseCases useCases;

    setUp(() {
      repository = MockTaskRepository();
      useCases = TaskUseCases(
        getTasks: GetTasksUseCase(repository),
        getTaskById: GetTaskByIdUseCase(repository),
        addTask: AddTaskUseCase(repository),
        updateTask: UpdateTaskUseCase(repository),
        deleteTask: DeleteTaskUseCase(repository),
      );
    });

    test('adds, updates, fetches, and deletes a task successfully', () async {
      final task = TaskEntity(
        title: 'Test Task',
        description: 'Test description',
        type: TaskType.homework,
        dueDate: DateTime(2026, 1, 1),
        isCompleted: false,
      );

      final addedId = await useCases.addTask(task);
      expect(addedId, 1);

      final tasks = await useCases.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Test Task');

      final fetched = await useCases.getTaskById(addedId);
      expect(fetched, isNotNull);
      expect(fetched!.description, 'Test description');

      final updatedTask = fetched.copyWith(
        title: 'Updated Task',
        isCompleted: true,
      );
      final updatedCount = await useCases.updateTask(updatedTask);
      expect(updatedCount, 1);

      final updatedFetched = await useCases.getTaskById(addedId);
      expect(updatedFetched, isNotNull);
      expect(updatedFetched!.title, 'Updated Task');
      expect(updatedFetched.isCompleted, isTrue);

      final deleted = await useCases.deleteTask(addedId);
      expect(deleted, 1);
      final afterDelete = await useCases.getTasks();
      expect(afterDelete, isEmpty);
    });

    test('filters and sorts tasks in use case layer', () {
      final tasks = [
        TaskEntity(
          id: 1,
          title: 'Math homework',
          description: 'Practice algebra',
          dueDate: DateTime(2026, 1, 3),
          priority: TaskPriority.low,
          isCompleted: false,
          courseName: 'Math',
        ),
        TaskEntity(
          id: 2,
          title: 'Physics project',
          description: 'Build model',
          dueDate: DateTime(2026, 1, 1),
          priority: TaskPriority.high,
          isCompleted: true,
          courseName: 'Physics',
        ),
        TaskEntity(
          id: 3,
          title: 'History review',
          description: 'Read chapter two',
          dueDate: null,
          priority: TaskPriority.medium,
          isCompleted: false,
          courseName: 'History',
        ),
      ];

      final result = useCases.filterAndSortTasks(
        tasks,
        searchQuery: 'math',
        statusFilter: 'pending',
        courseFilter: 'Math',
        sortMode: 'dueDateAsc',
      );

      expect(result.map((task) => task.id), [1]);

      final sorted = useCases.filterAndSortTasks(
        tasks,
        sortMode: 'priorityDesc',
      );

      expect(sorted.first.id, 2);
      expect(sorted[1].id, 3);
      expect(sorted[2].id, 1);
    });

    test(
        'computes reminder date from due date when no explicit reminder time is set',
        () {
      final dueDate = DateTime(2026, 1, 10, 9, 0);

      final reminderDate = NotificationService.resolveReminderDate(
        reminderEnabled: true,
        dueDate: dueDate,
        reminderDate: null,
        reminderOffsetMinutes: 30,
      );

      expect(reminderDate, dueDate.subtract(const Duration(minutes: 30)));
    });

    test(
        'computes the next lecture reminder time from weekday and lecture time',
        () {
      final now = DateTime(2026, 1, 6, 8, 0);

      final reminderAt = NotificationService.resolveLectureReminderDate(
        now: now,
        weekdayName: 'الثلاثاء',
        startTime: '09:30',
        reminderOffsetMinutes: 15,
      );

      expect(reminderAt, isNotNull);
      expect(reminderAt!.weekday, 2);
      expect(reminderAt.hour, 9);
      expect(reminderAt.minute, 15);
    });
  });
}
