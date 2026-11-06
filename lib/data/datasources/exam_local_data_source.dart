import '../database/database_helper.dart';
import '../models/exam_model.dart';

abstract class ExamLocalDataSource {
  Future<int> insertExam(ExamModel exam);
  Future<List<ExamModel>> fetchExams();
  Future<ExamModel?> fetchExamById(int id);
  Future<int> updateExam(ExamModel exam);
  Future<int> deleteExam(int id);
}

class ExamLocalDataSourceImpl implements ExamLocalDataSource {
  final DatabaseHelper databaseHelper;

  ExamLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<int> deleteExam(int id) => databaseHelper.deleteExam(id);

  @override
  Future<ExamModel?> fetchExamById(int id) => databaseHelper.getExamById(id);

  @override
  Future<List<ExamModel>> fetchExams() => databaseHelper.getExams();

  @override
  Future<int> insertExam(ExamModel exam) => databaseHelper.insertExam(exam);

  @override
  Future<int> updateExam(ExamModel exam) => databaseHelper.updateExam(exam);
}
