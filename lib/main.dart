import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/security/auth_secure_storage_service.dart';
import 'data/database/database_helper.dart';
import 'data/datasources/auth_google_data_source.dart';
import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/course_local_data_source.dart';
import 'data/datasources/task_local_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/course_repository_impl.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/usecases/auth_use_cases.dart';
import 'domain/usecases/course_use_cases.dart';
import 'domain/usecases/task_use_cases.dart';
import 'core/initializer/app_initializer.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'package:academic_os/presentation/auth/auth_gate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseHelper = DatabaseHelper.instance;
  final appInitializer = AppInitializer();

  if (!kIsWeb) {
    try {
      await NotificationService.instance.initialize();
    } catch (error, stackTrace) {
      debugPrint(
          'NotificationService initialization failed: $error\n$stackTrace');
    }
  }

  try {
    await appInitializer.initialize();
  } catch (error, stackTrace) {
    debugPrint('AppInitializer failed during startup: $error\n$stackTrace');
  }

  final authSecureStorageService = AuthSecureStorageService();
  final authLocalDataSource = AuthLocalDataSourceImpl(authSecureStorageService);
  final authGoogleDataSource = AuthGoogleDataSourceImpl(
    googleSignIn: GoogleSignIn(),
  );
  final authRepository = AuthRepositoryImpl(
    authLocalDataSource,
    authGoogleDataSource,
    authSecureStorageService,
  );

  final taskLocalDataSource = TaskLocalDataSourceImpl(databaseHelper);
  final taskRepository = TaskRepositoryImpl(taskLocalDataSource);
  final taskUseCases = TaskUseCases(
    getTasks: GetTasksUseCase(taskRepository),
    getTaskById: GetTaskByIdUseCase(taskRepository),
    addTask: AddTaskUseCase(taskRepository),
    updateTask: UpdateTaskUseCase(taskRepository),
    deleteTask: DeleteTaskUseCase(taskRepository),
  );

  final courseLocalDataSource = CourseLocalDataSourceImpl(databaseHelper);
  final courseRepository = CourseRepositoryImpl(courseLocalDataSource);
  final courseUseCases = CourseUseCases(
    getCourses: GetCoursesUseCase(courseRepository),
    getCourseById: GetCourseByIdUseCase(courseRepository),
    addCourse: AddCourseUseCase(courseRepository),
    updateCourse: UpdateCourseUseCase(courseRepository),
    deleteCourse: DeleteCourseUseCase(courseRepository),
  );

  final authUseCases = AuthUseCases(
    loginWithUsername: LoginWithUsernameUseCase(authRepository),
    registerLocalUser: RegisterLocalUserUseCase(authRepository),
    loginWithGoogle: LoginWithGoogleUseCase(authRepository),
    loginWithCachedGoogleAccount: LoginWithCachedGoogleAccountUseCase(
      authRepository,
    ),
    isLoggedIn: IsLoggedInUseCase(authRepository),
    getCurrentUser: GetCurrentUserUseCase(authRepository),
    logout: LogoutUseCase(authRepository),
  );

  debugPrint('App initialization finished successfully');
  runApp(
    ProviderScope(
      child: MyApp(
        authUseCases: authUseCases,
        taskUseCases: taskUseCases,
        courseUseCases: courseUseCases,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthUseCases authUseCases;
  final TaskUseCases taskUseCases;
  final CourseUseCases courseUseCases;

  const MyApp({
    super.key,
    required this.authUseCases,
    required this.taskUseCases,
    required this.courseUseCases,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  bool _isArabic = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academic OS',
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: AuthGateScreen(
        authUseCases: widget.authUseCases,
        taskUseCases: widget.taskUseCases,
        courseUseCases: widget.courseUseCases,
        isDarkMode: _isDarkMode,
        isArabic: _isArabic,
        onThemeChanged: (value) => setState(() => _isDarkMode = value),
        onLanguageChanged: (value) => setState(() => _isArabic = value),
      ),
    );
  }
}
