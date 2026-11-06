import '../../data/models/exam_model.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/task_entity.dart';

class AcademicDashboardSummary {
  const AcademicDashboardSummary({
    required this.totalCourses,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.averageCourseScore,
    required this.urgentTasks,
    required this.upcomingExams,
    required this.taskCompletionRate,
    required this.focusMessage,
    this.studyHealthScore = 0,
    this.nextPriorityAction = 'ابدأ بتحديد أولويتك اليوم.',
    this.recommendedFocusBlock = 'ركز على أحسن 25 دقيقة من اليوم.',
    this.atRiskCourses = const [],
  });

  final int totalCourses;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final double averageCourseScore;
  final int urgentTasks;
  final int upcomingExams;
  final double taskCompletionRate;
  final String focusMessage;
  final double studyHealthScore;
  final String nextPriorityAction;
  final String recommendedFocusBlock;
  final List<String> atRiskCourses;
}

class AcademicDashboardService {
  const AcademicDashboardService();

  AcademicDashboardSummary analyze({
    required List<CourseEntity> courses,
    required List<TaskEntity> tasks,
    required List<ExamModel> exams,
  }) {
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final pendingTasks = tasks.length - completedTasks;
    final urgentTasks = tasks
        .where(
            (task) => !task.isCompleted && task.priority == TaskPriority.urgent)
        .length;

    final averageCourseScore = courses.isEmpty
        ? 0.0
        : courses.fold<double>(0, (sum, course) {
              final value = ((course.midGrade ?? 0) +
                      (course.practicalGrade ?? 0) +
                      (course.finalGrade ?? 0)) /
                  3;
              return sum + value;
            }) /
            courses.length;

    final upcomingExams =
        exams.where((exam) => exam.examDate.isAfter(DateTime.now())).length;

    final taskCompletionRate =
        tasks.isEmpty ? 0.0 : (completedTasks / tasks.length) * 100;

    String focusMessage;
    if (pendingTasks == 0) {
      focusMessage = 'إنجاز ممتاز، أنت على المسار الصحيح.';
    } else if (urgentTasks > 0) {
      focusMessage = 'لديك $urgentTasks مهمة عاجلة تحتاج أولويتها الآن.';
    } else if (upcomingExams > 0) {
      focusMessage = 'لديك $upcomingExams اختبار قريب تحتاج لهدف تركيز خاص.';
    } else {
      focusMessage = 'استمر في الزخم، وانهِ المهام المتبقية بثبات.';
    }

    final atRiskCourses = courses
        .where((course) {
          final average = ((course.midGrade ?? 0) +
                  (course.practicalGrade ?? 0) +
                  (course.finalGrade ?? 0)) /
              3;
          return average < 60;
        })
        .map((course) => course.name)
        .take(3)
        .toList();

    final healthScore = tasks.isEmpty && courses.isEmpty
        ? 0.0
        : ((taskCompletionRate * 0.55) + ((averageCourseScore / 100) * 45))
            .clamp(0, 100)
            .toDouble();

    final nextPriorityAction = urgentTasks > 0
        ? 'حل المهمة العاجلة أولاً، ثم استأنف مراجعة اليوم.'
        : upcomingExams > 0
            ? 'خصص 45 دقيقة لمراجعة $upcomingExams اختبار/اختبارات قادمة.'
            : pendingTasks > 0
                ? 'اكمل المهمة التالية وأغلق الحلقة الحالية.'
                : 'أنت في حالة ممتازة؛ حافظ على التوازن بين المراجعة والراحة.';

    final recommendedFocusBlock = atRiskCourses.isNotEmpty
        ? 'ركز أولاً على: ${atRiskCourses.join(' • ')}'
        : 'أكمل جلسة مراجعة مركزة 45 دقيقة على أهم مادة اليوم.';

    return AcademicDashboardSummary(
      totalCourses: courses.length,
      totalTasks: tasks.length,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      averageCourseScore: averageCourseScore,
      urgentTasks: urgentTasks,
      upcomingExams: upcomingExams,
      taskCompletionRate: taskCompletionRate,
      focusMessage: focusMessage,
      studyHealthScore: healthScore,
      nextPriorityAction: nextPriorityAction,
      recommendedFocusBlock: recommendedFocusBlock,
      atRiskCourses: atRiskCourses,
    );
  }
}
