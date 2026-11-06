import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  Future<List<TaskEntity>> call() {
    return repository.fetchTasks();
  }
}

class GetTaskByIdUseCase {
  final TaskRepository repository;

  GetTaskByIdUseCase(this.repository);

  Future<TaskEntity?> call(int id) {
    return repository.fetchTaskById(id);
  }
}

class AddTaskUseCase {
  final TaskRepository repository;

  AddTaskUseCase(this.repository);

  Future<int> call(TaskEntity task) {
    return repository.addTask(task);
  }
}

class UpdateTaskUseCase {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  Future<int> call(TaskEntity task) {
    return repository.updateTask(task);
  }
}

class DeleteTaskUseCase {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  Future<int> call(int id) {
    return repository.deleteTask(id);
  }
}

class TaskUseCases {
  final GetTasksUseCase getTasks;
  final GetTaskByIdUseCase getTaskById;
  final AddTaskUseCase addTask;
  final UpdateTaskUseCase updateTask;
  final DeleteTaskUseCase deleteTask;

  const TaskUseCases({
    required this.getTasks,
    required this.getTaskById,
    required this.addTask,
    required this.updateTask,
    required this.deleteTask,
  });

  List<TaskEntity> filterAndSortTasks(
    List<TaskEntity> tasks, {
    String searchQuery = '',
    String? courseFilter,
    String statusFilter = 'all',
    String sortMode = 'none',
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();

    var filtered = tasks.where((task) {
      final matchesQuery = normalizedQuery.isEmpty ||
          task.title.toLowerCase().contains(normalizedQuery) ||
          task.description.toLowerCase().contains(normalizedQuery) ||
          (task.courseName?.toLowerCase().contains(normalizedQuery) ?? false);

      final matchesCourse = courseFilter == null ||
          (courseFilter == 'بدون كورس'
              ? (task.courseName == null || task.courseName!.trim().isEmpty)
              : task.courseName?.trim() == courseFilter);

      final matchesStatus = switch (statusFilter) {
        'completed' => task.isCompleted,
        'pending' => !task.isCompleted,
        'overdue' => task.dueDate != null &&
            task.dueDate!.isBefore(DateTime.now()) &&
            !task.isCompleted,
        _ => true,
      };

      return matchesQuery && matchesCourse && matchesStatus;
    }).toList();

    switch (sortMode) {
      case 'dueDateAsc':
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'dueDateDesc':
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case 'taskType':
        filtered.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;
      case 'priorityAsc':
        filtered.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
      case 'priorityDesc':
        filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case 'recurrence':
        filtered.sort((a, b) => a.recurrence.name.compareTo(b.recurrence.name));
        break;
      case 'none':
      default:
        break;
    }

    return filtered;
  }
}
