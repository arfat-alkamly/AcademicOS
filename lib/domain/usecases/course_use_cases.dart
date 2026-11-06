import '../entities/course_entity.dart';
import '../repositories/course_repository.dart';

class GetCoursesUseCase {
  final CourseRepository repository;

  GetCoursesUseCase(this.repository);

  Future<List<CourseEntity>> call() => repository.fetchCourses();
}

class GetCourseByIdUseCase {
  final CourseRepository repository;

  GetCourseByIdUseCase(this.repository);

  Future<CourseEntity?> call(int id) => repository.fetchCourseById(id);
}

class AddCourseUseCase {
  final CourseRepository repository;

  AddCourseUseCase(this.repository);

  Future<int> call(CourseEntity course) => repository.addCourse(course);
}

class UpdateCourseUseCase {
  final CourseRepository repository;

  UpdateCourseUseCase(this.repository);

  Future<int> call(CourseEntity course) => repository.updateCourse(course);
}

class DeleteCourseUseCase {
  final CourseRepository repository;

  DeleteCourseUseCase(this.repository);

  Future<int> call(int id) => repository.deleteCourse(id);
}

class CourseUseCases {
  final GetCoursesUseCase getCourses;
  final GetCourseByIdUseCase getCourseById;
  final AddCourseUseCase addCourse;
  final UpdateCourseUseCase updateCourse;
  final DeleteCourseUseCase deleteCourse;

  const CourseUseCases({
    required this.getCourses,
    required this.getCourseById,
    required this.addCourse,
    required this.updateCourse,
    required this.deleteCourse,
  });
}
