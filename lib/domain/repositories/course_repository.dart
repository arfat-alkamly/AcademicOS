import '../entities/course_entity.dart';

abstract class CourseRepository {
  Future<List<CourseEntity>> fetchCourses();
  Future<CourseEntity?> fetchCourseById(int id);
  Future<int> addCourse(CourseEntity course);
  Future<int> updateCourse(CourseEntity course);
  Future<int> deleteCourse(int id);
}
