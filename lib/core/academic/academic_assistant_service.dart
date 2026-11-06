import '../../data/models/exam_model.dart';
import '../../domain/ai/academic_intent_engine.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/task_entity.dart';
import 'academic_dashboard_service.dart';

class AcademicAssistantResult {
  final String response;
  final bool needsFollowUp;
  final String? followUpQuestion;

  const AcademicAssistantResult({
    required this.response,
    this.needsFollowUp = false,
    this.followUpQuestion,
  });
}

class AcademicAssistantService {
  const AcademicAssistantService();

  AcademicAssistantResult buildResponse({
    required String input,
    required List<CourseEntity> courses,
    required List<TaskEntity> tasks,
    required List<ExamModel> exams,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const AcademicAssistantResult(
        response: 'أحتاج منك كلمة أو سؤال حتى أتمكن من مساعدتك بشكل دقيق.',
      );
    }

    final parsedIntent = AcademicIntentEngine().parse(trimmed);
    final dashboard = const AcademicDashboardService().analyze(
      courses: courses,
      tasks: tasks,
      exams: exams,
    );

    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
    final urgentTasks = pendingTasks
        .where((task) => task.priority == TaskPriority.urgent)
        .toList();
    final nextExam = [...exams]
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
    final upcomingExam = nextExam
        .where((exam) => exam.examDate.isAfter(DateTime.now()))
        .firstOrNull;

    final averageText = dashboard.averageCourseScore == 0
        ? 'لا توجد درجات حالياً'
        : dashboard.averageCourseScore.toStringAsFixed(1);

    String response;
    switch (parsedIntent.intent) {
      case AcademicIntent.calculateGpa:
        response =
            'متوسط المواد الحالي هو ${averageText}، بينما لديك ${dashboard.totalCourses} مادة و${dashboard.totalTasks} مهمة إجمالية.'
            ' ${dashboard.atRiskCourses.isEmpty ? 'لا توجد مواد في خطر حاليًا.' : 'المواد الأكثر احتياجًا: ${dashboard.atRiskCourses.join('، ')}.'}'
            ' ${dashboard.studyHealthScore >= 75 ? 'حالتك الأكاديمية جيدة.' : 'تحتاج إلى تركيز أكبر في الخطة التالية.'}';
        break;
      case AcademicIntent.queryExams:
        if (upcomingExam == null) {
          response =
              'لا توجد اختبارات قادمة في سجلك الحالي، ويمكنك استخدام الوقت لتجهيز خطة مذاكرة جديدة.';
        } else {
          final remainingDays =
              upcomingExam.examDate.difference(DateTime.now()).inDays;
          response =
              'أقرب اختبار قادم هو "${upcomingExam.title}" في ${upcomingExam.examDate.day}/${upcomingExam.examDate.month}/${upcomingExam.examDate.year}. '
              'يبقى ${remainingDays} يومًا فقط. أفضل خطة: مراجعة الوحدة الأساسية، ثم حل أسئلة سابقة، ثم اختبار قصير قبل الموعد.';
        }
        break;
      case AcademicIntent.createTask:
        response =
            'لديك ${pendingTasks.length} مهمة معلقة، منها ${urgentTasks.length} مهمة عاجلة. '
            'أفضل ترتيب اليوم يبدأ بـ ${urgentTasks.isNotEmpty ? urgentTasks.first.title : (pendingTasks.isNotEmpty ? pendingTasks.first.title : 'إنجازاتك المكتملة')}.';
        break;
      case AcademicIntent.addSchedule:
        if (parsedIntent.context.courseName != null) {
          response =
              'سأركز على مادة ${parsedIntent.context.courseName}. تذكر أن جلسة التزامك الأفضل تبدأ بالترتيب التالي: مراجعة قصيرة، ثم حل الأسئلة، ثم إغلاق الخطة بنقطة مراجعة.';
        } else {
          response =
              'يمكنني تنظيم المحاضرة لك وفق اليوم والساعة، فقط أخبرني باسم المادة والوقت المطلوب.';
        }
        break;
      case AcademicIntent.studyPlanRequest:
        final focusCourse =
            courses.isNotEmpty ? courses.first.name : 'المادة الأساسية';
        response =
            'خطة المذاكرة المقترحة: تبدأ بـ 25 دقيقة مراجعة في ${focusCourse}، ثم 15 دقيقة تمارين، ثم 10 دقائق مراجعة سريعة. '
            'الأولوية اليوم هي إكمال ${urgentTasks.isNotEmpty ? urgentTasks.first.title : 'أهم مهمة معلقة لديك'}.';
        break;
      case AcademicIntent.attendanceCheck:
        response =
            'حالة حضورك العامة تحتاج تقييمًا حقيقيًا من سجلاتك. الآن لديك ${dashboard.totalTasks} مهمة و${dashboard.pendingTasks} معلقة، وقد تم إنجاز ${completedTasks} مهمة.'
            ' ${dashboard.atRiskCourses.isEmpty ? 'لا توجد مواد ضمن الخطر الحالي من الحضور.' : 'المواد التي تحتاج متابعة: ${dashboard.atRiskCourses.join('، ')}.'}';
        break;
      case AcademicIntent.motivation:
        response =
            'أنت تعمل بشكل ممتاز؛ الترتيب اليومي ومراجعة أولويتك القريبة يمنحك نتائج قوية. ابدأ بأهم مهمة وركز 25 دقيقة فقط، ثم راجع هدفك.';
        break;
      case AcademicIntent.generalQuery:
      default:
        response =
            'ملفك الأكاديمي الآن: لديك ${courses.length} مادة، ${tasks.length} مهمة، ${dashboard.urgentTasks} مهمة عاجلة، و${dashboard.upcomingExams} اختبار/اختبارات قادمة. '
            'حالة الدراسة الحالية ${dashboard.studyHealthScore.round()}%، والرسالة الذهبية اليوم: ${dashboard.nextPriorityAction}';
        break;
    }

    if (parsedIntent.needsFollowUp && parsedIntent.followUpQuestion != null) {
      return AcademicAssistantResult(
        response: response,
        needsFollowUp: true,
        followUpQuestion: parsedIntent.followUpQuestion,
      );
    }

    return AcademicAssistantResult(response: response);
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
