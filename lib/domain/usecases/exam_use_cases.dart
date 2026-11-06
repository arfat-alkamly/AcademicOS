import '../entities/exam_entity.dart';
import '../repositories/exam_repository.dart';

class GetExamsUseCase {
  final ExamRepository repository;

  GetExamsUseCase(this.repository);

  Future<List<ExamEntity>> call() => repository.fetchExams();
}

class GetExamByIdUseCase {
  final ExamRepository repository;

  GetExamByIdUseCase(this.repository);

  Future<ExamEntity?> call(int id) => repository.fetchExamById(id);
}

class AddExamUseCase {
  final ExamRepository repository;

  AddExamUseCase(this.repository);

  Future<int> call(ExamEntity exam) => repository.addExam(exam);
}

class UpdateExamUseCase {
  final ExamRepository repository;

  UpdateExamUseCase(this.repository);

  Future<int> call(ExamEntity exam) => repository.updateExam(exam);
}

class DeleteExamUseCase {
  final ExamRepository repository;

  DeleteExamUseCase(this.repository);

  Future<int> call(int id) => repository.deleteExam(id);
}

class ExamUseCases {
  final GetExamsUseCase getExams;
  final GetExamByIdUseCase getExamById;
  final AddExamUseCase addExam;
  final UpdateExamUseCase updateExam;
  final DeleteExamUseCase deleteExam;

  const ExamUseCases({
    required this.getExams,
    required this.getExamById,
    required this.addExam,
    required this.updateExam,
    required this.deleteExam,
  });
}
