import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> fetchTasks();
  Future<TaskEntity?> fetchTaskById(int id);
  Future<int> addTask(TaskEntity task);
  Future<int> updateTask(TaskEntity task);
  Future<int> deleteTask(int id);
}
