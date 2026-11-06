import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/database_helper.dart';
import '../../../../data/datasources/exam_local_data_source.dart';
import '../../../../data/repositories/exam_repository_impl.dart';
import '../../../../domain/entities/exam_entity.dart';
import '../../../../domain/usecases/exam_use_cases.dart';

final examDatabaseHelperProvider =
    Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final examRepositoryProvider = Provider<ExamRepositoryImpl>((ref) {
  final db = ref.watch(examDatabaseHelperProvider);
  return ExamRepositoryImpl(ExamLocalDataSourceImpl(db));
});

final examUseCasesProvider = Provider<ExamUseCases>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return ExamUseCases(
    getExams: GetExamsUseCase(repository),
    getExamById: GetExamByIdUseCase(repository),
    addExam: AddExamUseCase(repository),
    updateExam: UpdateExamUseCase(repository),
    deleteExam: DeleteExamUseCase(repository),
  );
});

class ExamListState {
  const ExamListState({
    this.exams = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ExamEntity> exams;
  final bool isLoading;
  final String? errorMessage;

  ExamListState copyWith({
    List<ExamEntity>? exams,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExamListState(
      exams: exams ?? this.exams,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ExamListNotifier extends Notifier<ExamListState> {
  late final ExamUseCases _useCases;

  @override
  ExamListState build() {
    _useCases = ref.watch(examUseCasesProvider);
    Future.microtask(() => loadExams());
    return const ExamListState(isLoading: true);
  }

  Future<void> loadExams() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final exams = await _useCases.getExams();
      final sorted = [...exams]
        ..sort((a, b) => a.examDate.compareTo(b.examDate));
      state = state.copyWith(exams: sorted, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل خطة الامتحانات.',
      );
    }
  }

  Future<void> addExam(ExamEntity exam) async {
    try {
      await _useCases.addExam(exam);
      await loadExams();
    } catch (error) {
      state = state.copyWith(errorMessage: 'تعذر إضافة امتحان جديد.');
    }
  }

  Future<void> updateExam(ExamEntity exam) async {
    try {
      await _useCases.updateExam(exam);
      await loadExams();
    } catch (error) {
      state = state.copyWith(errorMessage: 'تعذر تحديث الامتحان.');
    }
  }

  Future<void> deleteExam(int id) async {
    try {
      await _useCases.deleteExam(id);
      await loadExams();
    } catch (error) {
      state = state.copyWith(errorMessage: 'تعذر حذف الامتحان.');
    }
  }
}

final examListProvider = NotifierProvider<ExamListNotifier, ExamListState>(
  ExamListNotifier.new,
);
