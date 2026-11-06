import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

/// تنفيذ المستودع الذي يربط طبقة الـ Domain بطبقة البيانات المحلية.
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl(this.localDataSource);

  @override
  Future<int> addTask(TaskEntity task) async {
    final model = TaskModel(
      title: task.title,
      description: task.description,
      type: task.type,
      priority: task.priority,
      recurrence: task.recurrence,
      dueDate: task.dueDate,
      startDateTime: task.startDateTime,
      endDateTime: task.endDateTime,
      isCompleted: task.isCompleted,
      courseId: task.courseId,
      courseName: task.courseName,
      notes: task.notes,
      reminderEnabled: task.reminderEnabled,
      reminderDate: task.reminderDate,
      reminderOffsetMinutes: task.reminderOffsetMinutes,
    );
    return localDataSource.insertTask(model);
  }

  @override
  Future<int> deleteTask(int id) {
    return localDataSource.deleteTask(id);
  }

  @override
  Future<TaskEntity?> fetchTaskById(int id) {
    return localDataSource.fetchTaskById(id);
  }

  @override
  Future<List<TaskEntity>> fetchTasks() async {
    return localDataSource.fetchTasks();
  }

  @override
  Future<int> updateTask(TaskEntity task) async {
    if (task.id == null) {
      throw ArgumentError('Task id is required for update.');
    }
    final model = TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      type: task.type,
      priority: task.priority,
      recurrence: task.recurrence,
      dueDate: task.dueDate,
      startDateTime: task.startDateTime,
      endDateTime: task.endDateTime,
      isCompleted: task.isCompleted,
      courseId: task.courseId,
      courseName: task.courseName,
      notes: task.notes,
      reminderEnabled: task.reminderEnabled,
      reminderDate: task.reminderDate,
      reminderOffsetMinutes: task.reminderOffsetMinutes,
    );
    return localDataSource.updateTask(model);
  }
}
