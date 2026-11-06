import '../database/database_helper.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<int> insertTask(TaskModel task);
  Future<List<TaskModel>> fetchTasks();
  Future<TaskModel?> fetchTaskById(int id);
  Future<int> updateTask(TaskModel task);
  Future<int> deleteTask(int id);
}

/// طبقة التخزين المحلية التي تتعامل مع قاعدة البيانات فقط.
/// هذا يسمح لنا بفصل مصدر البيانات عن طبقة المستودع والـ Domain.
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final DatabaseHelper databaseHelper;

  TaskLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<int> insertTask(TaskModel task) {
    return databaseHelper.insertTask(task);
  }

  @override
  Future<List<TaskModel>> fetchTasks() {
    return databaseHelper.getTasks();
  }

  @override
  Future<TaskModel?> fetchTaskById(int id) {
    return databaseHelper.getTaskById(id);
  }

  @override
  Future<int> updateTask(TaskModel task) {
    return databaseHelper.updateTask(task);
  }

  @override
  Future<int> deleteTask(int id) {
    return databaseHelper.deleteTask(id);
  }
}
