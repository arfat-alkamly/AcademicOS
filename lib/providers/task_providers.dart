import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/academic/academic_analyzer.dart';
import '../core/initializer/app_initializer.dart';
import '../data/datasources/task_local_data_source.dart';
import '../data/repositories/task_repository_impl.dart';
import '../domain/entities/task_entity.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/usecases/auth_use_cases.dart';
import '../domain/usecases/course_use_cases.dart';
import '../domain/usecases/task_use_cases.dart';
import '../data/database/database_helper.dart';

final databaseHelperProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final localDataSource = TaskLocalDataSourceImpl(databaseHelper);
  return TaskRepositoryImpl(localDataSource);
});

final taskUseCasesProvider = Provider<TaskUseCases>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskUseCases(
    getTasks: GetTasksUseCase(repository),
    getTaskById: GetTaskByIdUseCase(repository),
    addTask: AddTaskUseCase(repository),
    updateTask: UpdateTaskUseCase(repository),
    deleteTask: DeleteTaskUseCase(repository),
  );
});

final courseUseCasesProvider = Provider<CourseUseCases>((ref) {
  throw UnimplementedError('Course use cases are provided from main().');
});

final authUseCasesProvider = Provider<AuthUseCases>((ref) {
  throw UnimplementedError('Auth use cases are provided from main().');
});

final academicAnalyzerProvider = Provider<AcademicAnalyzer>(
  (ref) => const AcademicAnalyzer(),
);

final appInitializerProvider = Provider<AppInitializer>(
  (ref) => AppInitializer(),
);

class TaskListState {
  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.insight,
  });

  final List<TaskEntity> tasks;
  final bool isLoading;
  final String? errorMessage;
  final AcademicInsight? insight;

  TaskListState copyWith({
    List<TaskEntity>? tasks,
    bool? isLoading,
    String? errorMessage,
    AcademicInsight? insight,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      insight: insight ?? this.insight,
    );
  }
}

class TaskListNotifier extends Notifier<TaskListState> {
  late final TaskRepository _repository;
  late final AcademicAnalyzer _academicAnalyzer;
  bool _hasLoadedOnce = false;

  @override
  TaskListState build() {
    _repository = ref.watch(taskRepositoryProvider);
    _academicAnalyzer = ref.watch(academicAnalyzerProvider);

    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.microtask(() => loadTasks());
    }

    return const TaskListState(isLoading: true);
  }

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tasks = await _repository.fetchTasks();
      final insight = _academicAnalyzer.analyze(tasks);

      if (tasks.isEmpty) {
        state = state.copyWith(
          tasks: const [],
          isLoading: false,
          insight: insight,
          errorMessage: null,
        );
        return;
      }

      state = state.copyWith(tasks: tasks, isLoading: false, insight: insight);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل المهام.',
      );
    }
  }

  Future<void> toggleCompletion(TaskEntity task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    try {
      await _repository.updateTask(updatedTask);
      await loadTasks();
    } catch (error) {
      state = state.copyWith(errorMessage: 'تعذر تحديث حالة الإنجاز.');
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _repository.deleteTask(id);
      await loadTasks();
    } catch (error) {
      state = state.copyWith(errorMessage: 'تعذر حذف المهمة.');
    }
  }

  Future<void> addTask(TaskEntity task) async {
    try {
      await _repository.addTask(task);
      await loadTasks();
    } catch (error) {
      state = state.copyWith(errorMessage: 'تعذر إضافة المهمة.');
    }
  }
}

final taskListProvider = NotifierProvider<TaskListNotifier, TaskListState>(
  TaskListNotifier.new,
);
