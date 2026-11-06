import '../../domain/entities/exam_entity.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_local_data_source.dart';
import '../models/exam_model.dart';

class ExamRepositoryImpl implements ExamRepository {
  final ExamLocalDataSource localDataSource;

  ExamRepositoryImpl(this.localDataSource);

  @override
  Future<List<ExamEntity>> fetchExams() async {
    return localDataSource.fetchExams();
  }

  @override
  Future<ExamEntity?> fetchExamById(int id) {
    return localDataSource.fetchExamById(id);
  }

  @override
  Future<int> addExam(ExamEntity exam) {
    final model = ExamModel(
      courseId: exam.courseId,
      title: exam.title,
      examDate: exam.examDate,
      location: exam.location,
      notes: exam.notes,
      courseName: exam.courseName,
      colorHex: exam.colorHex,
    );
    return localDataSource.insertExam(model);
  }

  @override
  Future<int> updateExam(ExamEntity exam) {
    if (exam.id == null) {
      throw ArgumentError('Exam id is required for update.');
    }
    final model = ExamModel(
      id: exam.id,
      courseId: exam.courseId,
      title: exam.title,
      examDate: exam.examDate,
      location: exam.location,
      notes: exam.notes,
      courseName: exam.courseName,
      colorHex: exam.colorHex,
    );
    return localDataSource.updateExam(model);
  }

  @override
  Future<int> deleteExam(int id) {
    return localDataSource.deleteExam(id);
  }
}
