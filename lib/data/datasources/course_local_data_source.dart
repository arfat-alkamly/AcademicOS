import '../database/database_helper.dart';
import '../models/course_model.dart';

abstract class CourseLocalDataSource {
  Future<int> insertCourse(CourseModel course);
  Future<List<CourseModel>> fetchCourses();
  Future<CourseModel?> fetchCourseById(int id);
  Future<int> updateCourse(CourseModel course);
  Future<int> deleteCourse(int id);
}

class CourseLocalDataSourceImpl implements CourseLocalDataSource {
  final DatabaseHelper databaseHelper;

  CourseLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<int> deleteCourse(int id) {
    return databaseHelper.deleteCourse(id);
  }

  @override
  Future<CourseModel?> fetchCourseById(int id) {
    return databaseHelper.getCourseById(id);
  }

  @override
  Future<List<CourseModel>> fetchCourses() {
    return databaseHelper.getCourses();
  }

  @override
  Future<int> insertCourse(CourseModel course) {
    return databaseHelper.insertCourse(course);
  }

  @override
  Future<int> updateCourse(CourseModel course) {
    return databaseHelper.updateCourse(course);
  }
}
