import '../../domain/entities/exam_entity.dart';

class ExamModel extends ExamEntity {
  const ExamModel({
    super.id,
    super.courseId,
    required super.title,
    required super.examDate,
    super.location,
    super.notes,
    super.courseName,
    super.colorHex,
  });

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    final idValue = map['id'];
    return ExamModel(
      id: idValue is int ? idValue : int.tryParse(idValue.toString()),
      courseId: map['course_id'] is int
          ? map['course_id'] as int
          : int.tryParse(map['course_id']?.toString() ?? ''),
      title: map['title']?.toString() ?? '',
      examDate: DateTime.tryParse(map['exam_date']?.toString() ?? '') ??
          DateTime.now(),
      location: map['location']?.toString(),
      notes: map['notes']?.toString(),
      courseName: map['course_name']?.toString(),
      colorHex: map['color_hex']?.toString() ?? '#2196F3',
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'course_id': courseId,
      'title': title,
      'exam_date': examDate.toIso8601String(),
      'location': location,
      'notes': notes,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
