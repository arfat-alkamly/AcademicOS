// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academic_os/main.dart';
import 'package:academic_os/domain/repositories/auth_repository.dart';
import 'package:academic_os/domain/repositories/task_repository.dart';
import 'package:academic_os/domain/repositories/course_repository.dart';
import 'package:academic_os/domain/usecases/auth_use_cases.dart';
import 'package:academic_os/domain/usecases/task_use_cases.dart';
import 'package:academic_os/domain/usecases/course_use_cases.dart';
import 'package:academic_os/domain/entities/user_entity.dart';
import 'package:academic_os/domain/entities/task_entity.dart';
import 'package:academic_os/domain/entities/course_entity.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<bool> loginWithUsername(String username, String password) async =>
      true;

  @override
  Future<bool> registerLocalUser(String username, String password,
          {String? email, String? displayName}) async =>
      true;

  @override
  Future<bool> loginWithGoogle() async => true;

  @override
  Future<bool> loginWithCachedGoogleAccount() async => false;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<void> logout() async {}
}

class _FakeTaskRepository implements TaskRepository {
  @override
  Future<int> addTask(TaskEntity task) async => 1;

  @override
  Future<int> deleteTask(int id) async => 1;

  @override
  Future<List<TaskEntity>> fetchTasks() async => <TaskEntity>[];

  @override
  Future<TaskEntity?> fetchTaskById(int id) async => null;

  @override
  Future<int> updateTask(TaskEntity task) async => 1;
}

class _FakeCourseRepository implements CourseRepository {
  @override
  Future<int> addCourse(CourseEntity course) async => 1;

  @override
  Future<int> deleteCourse(int id) async => 1;

  @override
  Future<List<CourseEntity>> fetchCourses() async => <CourseEntity>[];

  @override
  Future<CourseEntity?> fetchCourseById(int id) async => null;

  @override
  Future<int> updateCourse(CourseEntity course) async => 1;
}

void main() {
  testWidgets('App builds with provided use cases',
      (WidgetTester tester) async {
    final authRepo = _FakeAuthRepository();
    final taskRepo = _FakeTaskRepository();
    final courseRepo = _FakeCourseRepository();

    final authUseCases = AuthUseCases(
      loginWithUsername: LoginWithUsernameUseCase(authRepo),
      registerLocalUser: RegisterLocalUserUseCase(authRepo),
      loginWithGoogle: LoginWithGoogleUseCase(authRepo),
      loginWithCachedGoogleAccount:
          LoginWithCachedGoogleAccountUseCase(authRepo),
      isLoggedIn: IsLoggedInUseCase(authRepo),
      getCurrentUser: GetCurrentUserUseCase(authRepo),
      logout: LogoutUseCase(authRepo),
    );

    final taskUseCases = TaskUseCases(
      getTasks: GetTasksUseCase(taskRepo),
      getTaskById: GetTaskByIdUseCase(taskRepo),
      addTask: AddTaskUseCase(taskRepo),
      updateTask: UpdateTaskUseCase(taskRepo),
      deleteTask: DeleteTaskUseCase(taskRepo),
    );

    final courseUseCases = CourseUseCases(
      getCourses: GetCoursesUseCase(courseRepo),
      getCourseById: GetCourseByIdUseCase(courseRepo),
      addCourse: AddCourseUseCase(courseRepo),
      updateCourse: UpdateCourseUseCase(courseRepo),
      deleteCourse: DeleteCourseUseCase(courseRepo),
    );

    await tester.pumpWidget(
      MyApp(
        authUseCases: authUseCases,
        taskUseCases: taskUseCases,
        courseUseCases: courseUseCases,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
