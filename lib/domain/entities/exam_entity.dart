class ExamEntity {
  final int? id;
  final int? courseId;
  final String title;
  final DateTime examDate;
  final String? location;
  final String? notes;
  final String? courseName;
  final String colorHex;

  const ExamEntity({
    this.id,
    this.courseId,
    required this.title,
    required this.examDate,
    this.location,
    this.notes,
    this.courseName,
    this.colorHex = '#2196F3',
  });

  ExamEntity copyWith({
    int? id,
    int? courseId,
    String? title,
    DateTime? examDate,
    String? location,
    String? notes,
    String? courseName,
    String? colorHex,
  }) {
    return ExamEntity(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      examDate: examDate ?? this.examDate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      courseName: courseName ?? this.courseName,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
