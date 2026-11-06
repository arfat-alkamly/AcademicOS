import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    super.id,
    required super.title,
    required super.description,
    super.type,
    super.priority,
    super.recurrence,
    super.dueDate,
    super.startDateTime,
    super.endDateTime,
    super.isCompleted,
    super.courseId,
    super.courseName,
    super.notes,
    super.reminderEnabled,
    super.reminderDate,
    super.reminderOffsetMinutes,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final idValue = map['id'];
    return TaskModel(
      id: idValue is int ? idValue : int.tryParse(idValue.toString()),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      type: TaskTypeX.fromName(map['type']?.toString()),
      priority: TaskPriorityX.fromName(map['priority']?.toString()),
      recurrence: TaskRecurrenceX.fromName(map['recurrence']?.toString()),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString())
          : null,
      startDateTime: map['start_date_time'] != null
          ? DateTime.tryParse(map['start_date_time'].toString())
          : null,
      endDateTime: map['end_date_time'] != null
          ? DateTime.tryParse(map['end_date_time'].toString())
          : null,
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
      courseId: map['course_id'] is int
          ? map['course_id'] as int
          : int.tryParse(map['course_id']?.toString() ?? ''),
      courseName: map['course_name']?.toString(),
      notes: map['notes']?.toString() ?? '',
      reminderEnabled:
          map['reminder_enabled'] == 1 || map['reminder_enabled'] == true,
      reminderDate: map['reminder_date'] != null
          ? DateTime.tryParse(map['reminder_date'].toString())
          : null,
      reminderOffsetMinutes: map['reminder_offset_minutes'] is int
          ? map['reminder_offset_minutes'] as int
          : int.tryParse(map['reminder_offset_minutes']?.toString() ?? '') ??
                30,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'recurrence': recurrence.name,
      'due_date': dueDate?.toIso8601String(),
      'start_date_time': startDateTime?.toIso8601String(),
      'end_date_time': endDateTime?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'course_id': courseId,
      'course_name': courseName,
      'notes': notes,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_date': reminderDate?.toIso8601String(),
      'reminder_offset_minutes': reminderOffsetMinutes,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
