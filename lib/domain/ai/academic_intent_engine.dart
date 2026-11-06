import 'dart:collection';

enum AcademicIntent {
  createTask,
  addSchedule,
  queryExams,
  calculateGpa,
  attendanceCheck,
  studyPlanRequest,
  motivation,
  generalQuery,
}

class AcademicIntentContext {
  final String? courseName;
  final String? dayName;
  final String? timeText;
  final double? gradeValue;
  final String? rawText;

  const AcademicIntentContext({
    this.courseName,
    this.dayName,
    this.timeText,
    this.gradeValue,
    this.rawText,
  });
}

class ParsedAcademicIntent {
  final AcademicIntent intent;
  final AcademicIntentContext context;
  final String responseHint;
  final bool needsFollowUp;
  final String? followUpQuestion;

  const ParsedAcademicIntent({
    required this.intent,
    required this.context,
    required this.responseHint,
    this.needsFollowUp = false,
    this.followUpQuestion,
  });
}

class AcademicIntentEngine {
  final Queue<String> _conversationHistory = Queue<String>();
  String? _lastCourseName;
  AcademicIntent? _lastIntent;

  ParsedAcademicIntent parse(String input) {
    final message = input.trim();
    if (message.isEmpty) {
      return const ParsedAcademicIntent(
        intent: AcademicIntent.generalQuery,
        context: AcademicIntentContext(),
        responseHint: 'أحتاج تعليماتك لتحديد المطلوب بدقة.',
      );
    }

    _conversationHistory.addLast(message);
    final lower = message.toLowerCase();

    final courseName = _extractCourseName(message);
    final dayName = _extractDay(message);
    final timeText = _extractTime(message);
    final gradeValue = _extractGrade(message);

    if (_containsAny(
        lower, ['مذاكرة', 'خطة مذاكرة', 'توزيع', 'دراسة', 'study plan'])) {
      _lastIntent = AcademicIntent.studyPlanRequest;
      return ParsedAcademicIntent(
        intent: AcademicIntent.studyPlanRequest,
        context: AcademicIntentContext(
          courseName: courseName ?? _lastCourseName,
          dayName: dayName,
          timeText: timeText,
          rawText: message,
        ),
        responseHint: 'سأوزع لك خطة مذاكرة منطقية حسب الوقت المتاح.',
        needsFollowUp: courseName == null,
        followUpQuestion:
            courseName == null ? 'أي مادة تريد أن أضع لها خطة المذاكرة؟' : null,
      );
    }

    if (_containsAny(
        lower, ['محاضرة', 'جدول', 'schedule', 'الساعة', 'حصة', 'lecture'])) {
      _lastIntent = AcademicIntent.addSchedule;
      return ParsedAcademicIntent(
        intent: AcademicIntent.addSchedule,
        context: AcademicIntentContext(
          courseName: courseName ?? _lastCourseName,
          dayName: dayName ?? 'اليوم',
          timeText: timeText ?? 'الساعة المحددة',
          rawText: message,
        ),
        responseHint: 'سأضيف المحاضرة في الجدول حسب اليوم والساعة.',
        needsFollowUp: courseName == null || timeText == null,
        followUpQuestion: courseName == null || timeText == null
            ? 'أخبرني باسم المادة واليوم والساعة بالتفصيل.'
            : null,
      );
    }

    if (_containsAny(
        lower, ['مهمة', 'task', 'تذكير', 'أضف', 'إضافة', 'add task'])) {
      _lastIntent = AcademicIntent.createTask;
      _lastCourseName = courseName ?? _lastCourseName;
      return ParsedAcademicIntent(
        intent: AcademicIntent.createTask,
        context: AcademicIntentContext(
          courseName: courseName ?? _lastCourseName,
          dayName: dayName,
          timeText: timeText,
          rawText: message,
        ),
        responseHint: 'سأنشئ المهمة وربطها بالمادة إن أمكن.',
        needsFollowUp: courseName == null,
        followUpQuestion:
            courseName == null ? 'في أي مادة تريد إنشاء المهمة؟' : null,
      );
    }

    if (_containsAny(
        lower, ['اختبار', 'امتحان', 'exam', 'باقي', 'كم باقي', 'تاريخ'])) {
      _lastIntent = AcademicIntent.queryExams;
      return ParsedAcademicIntent(
        intent: AcademicIntent.queryExams,
        context: AcademicIntentContext(
          courseName: courseName ?? _lastCourseName,
          dayName: dayName,
          rawText: message,
        ),
        responseHint: 'سأراجع المواعيد المتبقية وأعطيك صورة واضحة.',
        needsFollowUp: false,
      );
    }

    if (_containsAny(
        lower, ['معدل', 'gpa', 'توقع', 'درجة', 'grade', 'مجموع'])) {
      _lastIntent = AcademicIntent.calculateGpa;
      return ParsedAcademicIntent(
        intent: AcademicIntent.calculateGpa,
        context: AcademicIntentContext(
          courseName: courseName ?? _lastCourseName,
          gradeValue: gradeValue,
          rawText: message,
        ),
        responseHint: 'سأحسب توقعك الحالي وأرشدك إلى ما تحتاجه للهدف.',
        needsFollowUp: false,
      );
    }

    if (_containsAny(
        lower, ['غياب', 'حضور', 'attendance', 'حرمان', 'failed'])) {
      _lastIntent = AcademicIntent.attendanceCheck;
      return ParsedAcademicIntent(
        intent: AcademicIntent.attendanceCheck,
        context: AcademicIntentContext(
          courseName: courseName ?? _lastCourseName,
          rawText: message,
        ),
        responseHint: 'سأقيّم نسبة الحضور وأوضحك نقطة الخطر.',
        needsFollowUp: courseName == null,
        followUpQuestion:
            courseName == null ? 'في أي مادة تريد فحص نسبة الحضور؟' : null,
      );
    }

    if (_containsAny(lower, ['تشجيع', 'تحفيز', 'motiv', 'شجع', 'أشعر']) ||
        _containsAny(lower, ['كيف أبدأ', 'مساعدة', 'help'])) {
      _lastIntent = AcademicIntent.motivation;
      return ParsedAcademicIntent(
        intent: AcademicIntent.motivation,
        context: AcademicIntentContext(rawText: message),
        responseHint: 'سأعطيك دفعة نفسية ومرحلة عمل عملية.',
      );
    }

    _lastIntent = AcademicIntent.generalQuery;
    return ParsedAcademicIntent(
      intent: AcademicIntent.generalQuery,
      context: AcademicIntentContext(
        courseName: courseName ?? _lastCourseName,
        dayName: dayName,
        timeText: timeText,
        gradeValue: gradeValue,
        rawText: message,
      ),
      responseHint: 'سأساعدك في تنظيم الدراسة والمهام بشكل عملي.',
      needsFollowUp: true,
      followUpQuestion: 'هل تقصد إنشاء مهمة، جدولة محاضرة، أو حساب المعدل؟',
    );
  }

  String? _extractCourseName(String message) {
    final match = RegExp(
      r'(?:مادة|course|subject|كورس)\s*[:\-]?\s*([\p{L}\p{N}\s]+)',
      unicode: true,
    ).firstMatch(message);
    if (match != null) {
      final raw = match.group(1)?.trim();
      if (raw != null && raw.isNotEmpty) {
        _lastCourseName = raw;
        return raw;
      }
    }

    final fallback = RegExp(
      r'([\p{L}]+(?:\s+[\p{L}]+){0,3})',
      unicode: true,
    ).allMatches(message).map((m) => m.group(0)).toList();
    for (final candidate in fallback) {
      if (candidate != null && _isLikelyCourseToken(candidate)) {
        _lastCourseName = candidate.trim();
        return candidate.trim();
      }
    }

    return _lastCourseName;
  }

  bool _isLikelyCourseToken(String value) {
    final cleaned = value.trim().toLowerCase();
    return cleaned.isNotEmpty &&
        !cleaned.contains('أنا') &&
        !cleaned.contains('اريد') &&
        !cleaned.contains('أريد') &&
        !cleaned.contains('كم') &&
        !cleaned.contains('ماذا') &&
        !cleaned.contains('كيف');
  }

  String? _extractDay(String message) {
    final lower = message.toLowerCase();
    final map = {
      'اليوم': 'اليوم',
      'غداً': 'غداً',
      'غدا': 'غداً',
      'الأحد': 'الأحد',
      'الاثنين': 'الاثنين',
      'الثلاثاء': 'الثلاثاء',
      'الأربعاء': 'الأربعاء',
      'الخميس': 'الخميس',
      'الجمعة': 'الجمعة',
      'السبت': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'tomorrow': 'غداً',
      'today': 'اليوم',
    };

    for (final entry in map.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  String? _extractTime(String message) {
    final match = RegExp(
      r'(?:الساعة|at|time)\s*(\d{1,2}(?::\d{2})?\s*(?:صباحاً|ظهراً|مساءً|pm|am|م|ص))',
      caseSensitive: false,
    ).firstMatch(message);
    if (match != null) return match.group(1)?.trim();

    final compact = RegExp(
      r'(\d{1,2}:\d{2})',
      caseSensitive: false,
    ).firstMatch(message);
    if (compact != null) return compact.group(1)?.trim();

    return null;
  }

  double? _extractGrade(String message) {
    final match = RegExp(
      r'(?:درجة|mark|score|total)\s*(?:[:=])?\s*(\d{1,3}(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(message);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  bool _containsAny(String lower, List<String> values) {
    for (final value in values) {
      if (lower.contains(value)) return true;
    }
    return false;
  }
}
