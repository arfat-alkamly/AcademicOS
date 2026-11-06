import 'package:flutter_test/flutter_test.dart';
import 'package:academic_os/data/models/course_model.dart';

void main() {
  group('CourseModel', () {
    test('fromMap and toMap preserve all fields', () {
      final course = CourseModel(
        id: 10,
        name: 'Physics',
        instructor: 'Prof. Samir',
        code: 'PHY101',
        credits: 4,
        semester: 'Fall',
        notes: 'Introduction to mechanics',
        colorHex: '#4285F4',
        lectureReminderEnabled: true,
        lectureDate: DateTime(2026, 1, 5, 9),
        lectureReminderOffsetMinutes: 20,
      );

      final map = course.toMap();

      expect(map['id'], 10);
      expect(map['name'], 'Physics');
      expect(map['instructor'], 'Prof. Samir');
      expect(map['code'], 'PHY101');
      expect(map['credits'], 4);
      expect(map['semester'], 'Fall');
      expect(map['notes'], 'Introduction to mechanics');
      expect(map['color_hex'], '#4285F4');
      expect(map['lecture_reminder_enabled'], 1);
      expect(map['lecture_date'], '2026-01-05T09:00:00.000');
      expect(map['lecture_reminder_offset_minutes'], 20);

      final parsed = CourseModel.fromMap(map);
      expect(parsed.id, 10);
      expect(parsed.name, 'Physics');
      expect(parsed.instructor, 'Prof. Samir');
      expect(parsed.code, 'PHY101');
      expect(parsed.credits, 4);
      expect(parsed.semester, 'Fall');
      expect(parsed.notes, 'Introduction to mechanics');
      expect(parsed.colorHex, '#4285F4');
      expect(parsed.lectureReminderEnabled, isTrue);
      expect(parsed.lectureDate, DateTime(2026, 1, 5, 9));
      expect(parsed.lectureReminderOffsetMinutes, 20);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 2,
        'name': 'Chemistry',
        'instructor': 'Dr. Lana',
        'code': 'CHM101',
        'credits': '3',
      };

      final parsed = CourseModel.fromMap(map);
      expect(parsed.id, 2);
      expect(parsed.name, 'Chemistry');
      expect(parsed.instructor, 'Dr. Lana');
      expect(parsed.code, 'CHM101');
      expect(parsed.credits, 3);
      expect(parsed.semester, '');
      expect(parsed.notes, isNull);
      expect(parsed.colorHex, '#2196F3');
      expect(parsed.lectureReminderEnabled, isFalse);
      expect(parsed.lectureReminderOffsetMinutes, 30);
    });
  });
}
