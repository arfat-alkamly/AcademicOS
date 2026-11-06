class CourseEntity {
  final int? id;
  final String name;
  final String instructor;
  final String code;
  final int credits;
  final String semester;
  final String? notes;
  final String colorHex;
  final bool lectureReminderEnabled;
  final DateTime? lectureDate;
  final int lectureReminderOffsetMinutes;
  final double? midGrade;
  final double? practicalGrade;
  final double? finalGrade;
  final int? creditHours;

  const CourseEntity({
    this.id,
    required this.name,
    required this.instructor,
    required this.code,
    this.credits = 0,
    this.semester = '',
    this.notes,
    this.colorHex = '#2196F3',
    this.lectureReminderEnabled = false,
    this.lectureDate,
    this.lectureReminderOffsetMinutes = 30,
    this.midGrade,
    this.practicalGrade,
    this.finalGrade,
    this.creditHours,
  });

  CourseEntity copyWith({
    int? id,
    String? name,
    String? instructor,
    String? code,
    int? credits,
    String? semester,
    String? notes,
    String? colorHex,
    bool? lectureReminderEnabled,
    DateTime? lectureDate,
    int? lectureReminderOffsetMinutes,
    double? midGrade,
    double? practicalGrade,
    double? finalGrade,
    int? creditHours,
  }) {
    return CourseEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      instructor: instructor ?? this.instructor,
      code: code ?? this.code,
      credits: credits ?? this.credits,
      semester: semester ?? this.semester,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
      lectureReminderEnabled:
          lectureReminderEnabled ?? this.lectureReminderEnabled,
      lectureDate: lectureDate ?? this.lectureDate,
      lectureReminderOffsetMinutes:
          lectureReminderOffsetMinutes ?? this.lectureReminderOffsetMinutes,
      midGrade: midGrade ?? this.midGrade,
      practicalGrade: practicalGrade ?? this.practicalGrade,
      finalGrade: finalGrade ?? this.finalGrade,
      creditHours: creditHours ?? this.creditHours,
    );
  }
}
