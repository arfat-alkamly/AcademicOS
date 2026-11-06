import '../entities/exam_entity.dart';

abstract class ExamRepository {
  Future<List<ExamEntity>> fetchExams();
  Future<ExamEntity?> fetchExamById(int id);
  Future<int> addExam(ExamEntity exam);
  Future<int> updateExam(ExamEntity exam);
  Future<int> deleteExam(int id);
}
