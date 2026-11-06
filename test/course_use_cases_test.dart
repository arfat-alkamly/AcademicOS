import 'package:flutter_test/flutter_test.dart';
import 'package:academic_os/domain/entities/course_entity.dart';
import 'package:academic_os/domain/repositories/course_repository.dart';
import 'package:academic_os/domain/usecases/course_use_cases.dart';

class MockCourseRepository implements CourseRepository {
  final List<CourseEntity> courses = [];

  @override
  Future<int> addCourse(CourseEntity course) async {
    final newCourse = CourseEntity(
      id: courses.length + 1,
      name: course.name,
      instructor: course.instructor,
      code: course.code,
      credits: course.credits,
      semester: course.semester,
      notes: course.notes,
      colorHex: course.colorHex,
    );
    courses.add(newCourse);
    return newCourse.id!;
  }

  @override
  Future<int> deleteCourse(int id) async {
    courses.removeWhere((course) => course.id == id);
    return 1;
  }

  @override
  Future<CourseEntity?> fetchCourseById(int id) async {
    final match = courses.where((course) => course.id == id).toList();
    if (match.isEmpty) {
      return null;
    }
    return match.first;
  }

  @override
  Future<List<CourseEntity>> fetchCourses() async {
    return courses;
  }

  @override
  Future<int> updateCourse(CourseEntity course) async {
    final index = courses.indexWhere((existing) => existing.id == course.id);
    if (index < 0) {
      throw ArgumentError('Course id is required for update.');
    }
    courses[index] = CourseEntity(
      id: course.id,
      name: course.name,
      instructor: course.instructor,
      code: course.code,
      credits: course.credits,
      semester: course.semester,
      notes: course.notes,
      colorHex: course.colorHex,
    );
    return 1;
  }
}

void main() {
  group('CourseUseCases', () {
    late MockCourseRepository repository;
    late CourseUseCases useCases;

    setUp(() {
      repository = MockCourseRepository();
      useCases = CourseUseCases(
        getCourses: GetCoursesUseCase(repository),
        getCourseById: GetCourseByIdUseCase(repository),
        addCourse: AddCourseUseCase(repository),
        updateCourse: UpdateCourseUseCase(repository),
        deleteCourse: DeleteCourseUseCase(repository),
      );
    });

    test('adds, updates, fetches, and deletes a course successfully', () async {
      final course = CourseEntity(
        name: 'Math 101',
        instructor: 'Dr. Ali',
        code: 'MTH101',
        credits: 3,
        semester: 'Spring',
        notes: 'First semester course',
      );

      final addedId = await useCases.addCourse(course);
      expect(addedId, 1);

      final courses = await useCases.getCourses();
      expect(courses.length, 1);
      expect(courses.first.name, 'Math 101');

      final fetched = await useCases.getCourseById(addedId);
      expect(fetched, isNotNull);
      expect(fetched!.code, 'MTH101');

      final updatedCourse = fetched.copyWith(name: 'Math 102', credits: 4);
      final updatedCount = await useCases.updateCourse(updatedCourse);
      expect(updatedCount, 1);

      final updatedFetched = await useCases.getCourseById(addedId);
      expect(updatedFetched, isNotNull);
      expect(updatedFetched!.name, 'Math 102');
      expect(updatedFetched.credits, 4);

      final deleted = await useCases.deleteCourse(addedId);
      expect(deleted, 1);
      final afterDelete = await useCases.getCourses();
      expect(afterDelete, isEmpty);
    });
  });
}
