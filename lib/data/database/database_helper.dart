import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/course_model.dart';
import '../models/exam_model.dart';
import '../models/task_model.dart';

/// مساعد قاعدة البيانات المسؤول عن إنشاء قاعدة البيانات والتعامل
/// مع عمليات CRUD الخاصة بالمهام والمواد.
class DatabaseHelper {
  DatabaseHelper._() {
    if (kIsWeb && !_webFactoryInitialized) {
      _webFactoryInitialized = _initializeWebFactory();
    }

    if (!kIsWeb && _shouldUseNativeFactory() && !_nativeFactoryInitialized) {
      _nativeFactoryInitialized = _initializeNativeFactory();
    }
  }

  static bool _shouldUseNativeFactory() {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static bool _initializeWebFactory() {
    try {
      databaseFactory = databaseFactoryFfiWeb;
      debugPrint('SQLite FFI web factory initialized once.');
      return true;
    } catch (error) {
      debugPrint(
          'SQLite FFI web factory unavailable; keeping fallback mode. $error');
      return false;
    }
  }

  static bool _initializeNativeFactory() {
    try {
      databaseFactory = databaseFactoryFfi;
      debugPrint('SQLite FFI native factory initialized once.');
      return true;
    } catch (error) {
      debugPrint(
          'SQLite FFI native factory unavailable; keeping fallback mode. $error');
      return false;
    }
  }

  static final DatabaseHelper instance = DatabaseHelper._();
  static bool _webFactoryInitialized = false;
  static bool _nativeFactoryInitialized = false;

  static const String _databaseName = 'academic_os.db';
  static const int _databaseVersion = 10;
  static const String _materialsTable = 'course_materials';
  static const String _taskTable = 'tasks';
  static const String _courseTable = 'courses';
  static const String _examTable = 'exams';
  static const String scheduleTable = 'schedule';

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb && !_webFactoryInitialized) {
      try {
        databaseFactory = databaseFactoryFfiWeb;
        _webFactoryInitialized = true;
        debugPrint('SQLite FFI web factory initialized during DB setup.');
      } catch (error) {
        debugPrint(
            'SQLite FFI web factory unavailable; keeping fallback mode. $error');
      }
    }

    if (!kIsWeb && _shouldUseNativeFactory() && !_nativeFactoryInitialized) {
      try {
        databaseFactory = databaseFactoryFfi;
        _nativeFactoryInitialized = true;
        debugPrint('SQLite FFI native factory initialized during DB setup.');
      } catch (error) {
        debugPrint(
            'SQLite FFI native factory unavailable; keeping fallback mode. $error');
      }
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    try {
      return await openDatabase(
        path,
        version: _databaseVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreateDatabase,
        onUpgrade: _onUpgradeDatabase,
      );
    } catch (error, stackTrace) {
      if (kIsWeb) {
        debugPrint(
          'SQLite web DB init failed; using in-memory fallback. $error\n$stackTrace',
        );
        return await openDatabase(
          inMemoryDatabasePath,
          version: _databaseVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreateDatabase,
          onUpgrade: _onUpgradeDatabase,
        );
      }
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = WAL');
  }

  Future<void> _ensureColumn(
    Database db,
    String tableName,
    String columnName,
    String columnDefinition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = columns.any((column) => column['name'] == columnName);
    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition',
      );
    }
  }

  Future<void> _onCreateDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_taskTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'other',
        due_date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        course_id INTEGER,
        course_name TEXT,
        priority TEXT NOT NULL DEFAULT 'medium',
        recurrence TEXT NOT NULL DEFAULT 'once',
        start_date_time TEXT,
        end_date_time TEXT,
        notes TEXT NOT NULL DEFAULT '',
        reminder_enabled INTEGER NOT NULL DEFAULT 0,
        reminder_date TEXT,
        reminder_offset_minutes INTEGER NOT NULL DEFAULT 30
      )
    ''');

    await db.execute('''
      CREATE TABLE $_courseTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        instructor TEXT NOT NULL,
        code TEXT NOT NULL,
        credits INTEGER NOT NULL DEFAULT 0,
        semester TEXT NOT NULL DEFAULT '',
        notes TEXT,
        color_hex TEXT NOT NULL DEFAULT '#2196F3',
        lecture_reminder_enabled INTEGER NOT NULL DEFAULT 0,
        lecture_date TEXT,
        lecture_reminder_offset_minutes INTEGER NOT NULL DEFAULT 30,
        mid_grade REAL DEFAULT 0,
        practical_grade REAL DEFAULT 0,
        final_grade REAL DEFAULT 0,
        credit_hours INTEGER DEFAULT 3
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_course_id ON $_taskTable (course_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_reminder_enabled ON $_taskTable (reminder_enabled)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_courses_lecture_reminder_enabled ON $_courseTable (lecture_reminder_enabled)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_examTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        title TEXT NOT NULL,
        exam_date TEXT NOT NULL,
        location TEXT,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $scheduleTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        day_of_week TEXT,
        start_time TEXT,
        end_time TEXT,
        location TEXT,
        reminder_enabled INTEGER DEFAULT 1,
        reminder_offset_minutes INTEGER NOT NULL DEFAULT 15
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_materialsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        created_at TEXT
      )
    ''');
  }

  Future<void> _onUpgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_materialsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          course_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          created_at TEXT
        )
      ''');
    }
    if (oldVersion < 2) {
      await _ensureColumn(
        db,
        _taskTable,
        'type',
        "TEXT NOT NULL DEFAULT 'other'",
      );
      await _ensureColumn(db, _taskTable, 'due_date', 'TEXT');
      await _ensureColumn(
        db,
        _taskTable,
        'is_completed',
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_courseTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          instructor TEXT NOT NULL,
          code TEXT NOT NULL,
          credits INTEGER NOT NULL DEFAULT 0,
          semester TEXT NOT NULL DEFAULT '',
          notes TEXT,
          color_hex TEXT NOT NULL DEFAULT '#2196F3'
        )
      ''');
    }
    if (oldVersion < 4) {
      await _ensureColumn(db, _taskTable, 'course_id', 'INTEGER');
      await _ensureColumn(db, _taskTable, 'course_name', 'TEXT');
    }
    if (oldVersion < 5) {
      await _ensureColumn(
        db,
        _taskTable,
        'reminder_enabled',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _ensureColumn(db, _taskTable, 'reminder_date', 'TEXT');
      await _ensureColumn(
        db,
        _taskTable,
        'reminder_offset_minutes',
        'INTEGER NOT NULL DEFAULT 30',
      );
      await _ensureColumn(
        db,
        _courseTable,
        'lecture_reminder_enabled',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _ensureColumn(db, _courseTable, 'lecture_date', 'TEXT');
      await _ensureColumn(
        db,
        _courseTable,
        'lecture_reminder_offset_minutes',
        'INTEGER NOT NULL DEFAULT 30',
      );
    }
    if (oldVersion < 6) {
      await _ensureColumn(
        db,
        _taskTable,
        'priority',
        "TEXT NOT NULL DEFAULT 'medium'",
      );
      await _ensureColumn(
        db,
        _taskTable,
        'recurrence',
        "TEXT NOT NULL DEFAULT 'once'",
      );
      await _ensureColumn(db, _taskTable, 'start_date_time', 'TEXT');
      await _ensureColumn(db, _taskTable, 'end_date_time', 'TEXT');
      await _ensureColumn(
        db,
        _taskTable,
        'notes',
        "TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 7) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_course_id ON $_taskTable (course_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_reminder_enabled ON $_taskTable (reminder_enabled)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_courses_lecture_reminder_enabled ON $_courseTable (lecture_reminder_enabled)',
      );
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_examTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          course_id INTEGER,
          title TEXT NOT NULL,
          exam_date TEXT NOT NULL,
          location TEXT,
          notes TEXT
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $scheduleTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          course_id INTEGER,
          day_of_week TEXT,
          start_time TEXT,
          end_time TEXT,
          location TEXT,
          reminder_enabled INTEGER DEFAULT 1
        )
      ''');
    }

    await _ensureColumn(
      db,
      scheduleTable,
      'reminder_offset_minutes',
      'INTEGER NOT NULL DEFAULT 15',
    );

    await _ensureColumn(
      db,
      _courseTable,
      'mid_grade',
      'REAL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      _courseTable,
      'practical_grade',
      'REAL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      _courseTable,
      'final_grade',
      'REAL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      _courseTable,
      'credit_hours',
      'INTEGER DEFAULT 3',
    );
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Future<int> insertTask(TaskModel task) async {
    final db = await database;
    return await db.insert(
      _taskTable,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TaskModel>> getTasks() async {
    final db = await database;
    final rows = await db.query(_taskTable, orderBy: 'id DESC');
    return rows.map(TaskModel.fromMap).toList();
  }

  Future<TaskModel?> getTaskById(int id) async {
    final db = await database;
    final rows = await db.query(_taskTable, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return TaskModel.fromMap(rows.first);
  }

  Future<int> updateTask(TaskModel task) async {
    if (task.id == null) {
      throw ArgumentError('Task id is required to update a task.');
    }
    final db = await database;
    return await db.update(
      _taskTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(_taskTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertCourse(CourseModel course) async {
    final db = await database;
    return await db.insert(
      _courseTable,
      course.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CourseModel>> getCourses() async {
    final db = await database;
    final rows = await db.query(_courseTable, orderBy: 'name ASC');
    return rows.map(CourseModel.fromMap).toList();
  }

  Future<CourseModel?> getCourseById(int id) async {
    final db = await database;
    final rows = await db.query(_courseTable, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return CourseModel.fromMap(rows.first);
  }

  Future<int> updateCourse(CourseModel course) async {
    if (course.id == null) {
      throw ArgumentError('Course id is required to update a course.');
    }
    final db = await database;
    return await db.update(
      _courseTable,
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(int id) async {
    final db = await database;
    return await db.delete(_courseTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCourseGrades(
    int courseId, {
    double midGrade = 0,
    double practicalGrade = 0,
    double finalGrade = 0,
    int creditHours = 3,
  }) async {
    final db = await database;
    return await db.update(
      _courseTable,
      {
        'mid_grade': midGrade,
        'practical_grade': practicalGrade,
        'final_grade': finalGrade,
        'credit_hours': creditHours,
      },
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  Future<int> insertExam(ExamModel exam) async {
    final db = await database;
    return await db.insert(
      _examTable,
      exam.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExamModel>> getExams() async {
    final db = await database;
    final rows = await db.query(_examTable, orderBy: 'exam_date ASC');
    return rows.map(ExamModel.fromMap).toList();
  }

  Future<ExamModel?> getExamById(int id) async {
    final db = await database;
    final rows = await db.query(_examTable, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ExamModel.fromMap(rows.first);
  }

  Future<int> updateExam(ExamModel exam) async {
    if (exam.id == null) {
      throw ArgumentError('Exam id is required to update an exam.');
    }
    final db = await database;
    return await db.update(
      _examTable,
      exam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  Future<int> deleteExam(int id) async {
    final db = await database;
    return await db.delete(_examTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertSchedule(Map<String, dynamic> schedule) async {
    final db = await database;
    return await db.insert(
      scheduleTable,
      schedule,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSchedules() async {
    final db = await database;
    return await db.query(scheduleTable, orderBy: 'start_time ASC');
  }

  Future<int> updateSchedule(Map<String, dynamic> schedule) async {
    if (schedule['id'] == null) {
      throw ArgumentError('Schedule id is required to update a schedule item.');
    }
    final db = await database;
    return await db.update(
      scheduleTable,
      schedule,
      where: 'id = ?',
      whereArgs: [schedule['id']],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final db = await database;
    return await db.delete(scheduleTable, where: 'id = ?', whereArgs: [id]);
  }

  // Course materials CRUD
  Future<int> insertMaterial(Map<String, dynamic> material) async {
    final db = await database;
    return await db.insert(_materialsTable, material,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMaterialsByCourseId(
      int courseId) async {
    final db = await database;
    return await db.query(_materialsTable,
        where: 'course_id = ?',
        whereArgs: [courseId],
        orderBy: 'created_at DESC');
  }

  Future<int> deleteMaterial(int id) async {
    final db = await database;
    return await db.delete(_materialsTable, where: 'id = ?', whereArgs: [id]);
  }
}
