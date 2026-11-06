import '../../domain/entities/course_entity.dart';

class CourseModel extends CourseEntity {
  const CourseModel({
    super.id,
    required super.name,
    required super.instructor,
    required super.code,
    super.credits,
    super.semester,
    super.notes,
    super.colorHex,
    super.lectureReminderEnabled,
    super.lectureDate,
    super.lectureReminderOffsetMinutes,
    super.midGrade,
    super.practicalGrade,
    super.finalGrade,
    super.creditHours,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    final idValue = map['id'];
    return CourseModel(
      id: idValue is int ? idValue : int.tryParse(idValue.toString()),
      name: map['name']?.toString() ?? '',
      instructor: map['instructor']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      credits: map['credits'] is int
          ? map['credits'] as int
          : int.tryParse(map['credits']?.toString() ?? '') ?? 0,
      semester: map['semester']?.toString() ?? '',
      notes: map['notes']?.toString(),
      colorHex: map['color_hex']?.toString() ?? '#2196F3',
      lectureReminderEnabled:
          map['lecture_reminder_enabled'] == 1 ||
          map['lecture_reminder_enabled'] == true,
      lectureDate: map['lecture_date'] != null
          ? DateTime.tryParse(map['lecture_date'].toString())
          : null,
      lectureReminderOffsetMinutes:
          map['lecture_reminder_offset_minutes'] is int
          ? map['lecture_reminder_offset_minutes'] as int
          : int.tryParse(
                  map['lecture_reminder_offset_minutes']?.toString() ?? '',
                ) ??
                30,
      midGrade: map['mid_grade'] is num
          ? (map['mid_grade'] as num).toDouble()
          : double.tryParse(map['mid_grade']?.toString() ?? '') ?? 0,
      practicalGrade: map['practical_grade'] is num
          ? (map['practical_grade'] as num).toDouble()
          : double.tryParse(map['practical_grade']?.toString() ?? '') ?? 0,
      finalGrade: map['final_grade'] is num
          ? (map['final_grade'] as num).toDouble()
          : double.tryParse(map['final_grade']?.toString() ?? '') ?? 0,
      creditHours: map['credit_hours'] is int
          ? map['credit_hours'] as int
          : int.tryParse(map['credit_hours']?.toString() ?? '') ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'name': name,
      'instructor': instructor,
      'code': code,
      'credits': credits,
      'semester': semester,
      'notes': notes,
      'color_hex': colorHex,
      'lecture_reminder_enabled': lectureReminderEnabled ? 1 : 0,
      'lecture_date': lectureDate?.toIso8601String(),
      'lecture_reminder_offset_minutes': lectureReminderOffsetMinutes,
      'mid_grade': midGrade ?? 0,
      'practical_grade': practicalGrade ?? 0,
      'final_grade': finalGrade ?? 0,
      'credit_hours': creditHours ?? 3,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
