enum TaskType {
  homework,
  project,
  exam,
  review,
  attendance,
  academicActivity,
  other,
}

extension TaskTypeX on TaskType {
  String get label {
    switch (this) {
      case TaskType.homework:
        return 'واجب';
      case TaskType.project:
        return 'مشروع';
      case TaskType.exam:
        return 'اختبار';
      case TaskType.review:
        return 'مراجعة';
      case TaskType.attendance:
        return 'حضور';
      case TaskType.academicActivity:
        return 'نشاط أكاديمي';
      case TaskType.other:
        return 'أخرى';
    }
  }

  static TaskType fromName(String? name) {
    return TaskType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => TaskType.other,
    );
  }
}

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'منخفضة';
      case TaskPriority.medium:
        return 'متوسطة';
      case TaskPriority.high:
        return 'عالية';
      case TaskPriority.urgent:
        return 'عاجلة';
    }
  }

  static TaskPriority fromName(String? name) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.name == name,
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskRecurrence { once, daily, weekly, monthly }

extension TaskRecurrenceX on TaskRecurrence {
  String get label {
    switch (this) {
      case TaskRecurrence.daily:
        return 'يوميًا';
      case TaskRecurrence.weekly:
        return 'أسبوعيًا';
      case TaskRecurrence.monthly:
        return 'شهريًا';
      case TaskRecurrence.once:
        return 'مرة واحدة';
    }
  }

  static TaskRecurrence fromName(String? name) {
    return TaskRecurrence.values.firstWhere(
      (recurrence) => recurrence.name == name,
      orElse: () => TaskRecurrence.once,
    );
  }
}

class TaskEntity {
  final int? id;
  final String title;
  final String description;
  final TaskType type;
  final TaskPriority priority;
  final TaskRecurrence recurrence;
  final DateTime? dueDate;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool isCompleted;
  final int? courseId;
  final String? courseName;
  final String notes;
  final bool reminderEnabled;
  final DateTime? reminderDate;
  final int reminderOffsetMinutes;

  const TaskEntity({
    this.id,
    required this.title,
    required this.description,
    this.type = TaskType.other,
    this.priority = TaskPriority.medium,
    this.recurrence = TaskRecurrence.once,
    this.dueDate,
    this.startDateTime,
    this.endDateTime,
    this.isCompleted = false,
    this.courseId,
    this.courseName,
    this.notes = '',
    this.reminderEnabled = false,
    this.reminderDate,
    this.reminderOffsetMinutes = 30,
  });

  TaskEntity copyWith({
    int? id,
    String? title,
    String? description,
    TaskType? type,
    TaskPriority? priority,
    TaskRecurrence? recurrence,
    DateTime? dueDate,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isCompleted,
    int? courseId,
    String? courseName,
    String? notes,
    bool? reminderEnabled,
    DateTime? reminderDate,
    int? reminderOffsetMinutes,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      dueDate: dueDate ?? this.dueDate,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderOffsetMinutes:
          reminderOffsetMinutes ?? this.reminderOffsetMinutes,
    );
  }
}
