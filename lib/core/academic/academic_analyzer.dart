import '../../domain/entities/task_entity.dart';

class AcademicInsight {
  const AcademicInsight({
    required this.completedCount,
    required this.pendingCount,
    required this.urgentCount,
    required this.summary,
    required this.nextAction,
  });

  final int completedCount;
  final int pendingCount;
  final int urgentCount;
  final String summary;
  final String nextAction;
}

class AcademicAnalyzer {
  const AcademicAnalyzer();

  AcademicInsight analyze(List<TaskEntity> tasks) {
    final completedCount = tasks.where((task) => task.isCompleted).length;
    final pendingCount = tasks.length - completedCount;
    final urgentCount = tasks.where((task) {
      return !task.isCompleted && task.priority == TaskPriority.urgent;
    }).length;

    final summary = pendingCount == 0
        ? 'لا توجد مهام معلقة حالياً.'
        : 'لديك $pendingCount مهمة معلقة و$urgentCount مهمة عاجلة.';

    final nextAction = pendingCount == 0
        ? 'جميع المهام في وضع ممتاز.'
        : 'ابدأ بالمهمات العاجلة أو التي تقترب من الاستحقاق.';

    return AcademicInsight(
      completedCount: completedCount,
      pendingCount: pendingCount,
      urgentCount: urgentCount,
      summary: summary,
      nextAction: nextAction,
    );
  }
}
