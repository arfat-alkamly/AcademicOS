import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_local_data_source.dart';
import '../models/course_model.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseLocalDataSource localDataSource;

  CourseRepositoryImpl(this.localDataSource);

  @override
  Future<int> addCourse(CourseEntity course) {
    final model = CourseModel(
      name: course.name,
      instructor: course.instructor,
      code: course.code,
      credits: course.credits,
      semester: course.semester,
      notes: course.notes,
      colorHex: course.colorHex,
    );
    return localDataSource.insertCourse(model);
  }

  @override
  Future<int> deleteCourse(int id) {
    return localDataSource.deleteCourse(id);
  }

  @override
  Future<CourseEntity?> fetchCourseById(int id) {
    return localDataSource.fetchCourseById(id);
  }

  @override
  Future<List<CourseEntity>> fetchCourses() async {
    return localDataSource.fetchCourses();
  }

  @override
  Future<int> updateCourse(CourseEntity course) {
    if (course.id == null) {
      throw ArgumentError('Course id is required for update.');
    }
    final model = CourseModel(
      id: course.id,
      name: course.name,
      instructor: course.instructor,
      code: course.code,
      credits: course.credits,
      semester: course.semester,
      notes: course.notes,
      colorHex: course.colorHex,
    );
    return localDataSource.updateCourse(model);
  }
}
