import 'package:flutter/material.dart';

import '../core/academic/academic_dashboard_service.dart';
import '../data/database/database_helper.dart';

class GradeDistributionScreen extends StatefulWidget {
  const GradeDistributionScreen({super.key});

  @override
  State<GradeDistributionScreen> createState() =>
      _GradeDistributionScreenState();
}

class _CourseGrade {
  String title;
  String code;
  bool isPractical;
  double coursework;
  double assignments;
  double midterm;
  double lab; // used for practical
  double finalExam;
  int credits;
  int? id;
  double? totalScore;

  _CourseGrade({
    required this.title,
    required this.code,
    this.isPractical = false,
    this.coursework = 0,
    this.assignments = 0,
    this.midterm = 0,
    this.lab = 0,
    this.finalExam = 0,
    this.credits = 3,
    this.id,
    this.totalScore,
  });

  double get total =>
      (totalScore ??
              (coursework + assignments + midterm + lab + finalExam))
          .clamp(0, 100)
          .toDouble();
}

class _GradeBreakdown {
  final double earned;
  final double deficit;
  final double remaining;
  _GradeBreakdown(this.earned, this.deficit, this.remaining);
}

class _GradeProjection {
  final double percentage;
  final double scale4;
  final double scale5;
  _GradeProjection(this.percentage, this.scale4, this.scale5);
}

class _GradeDistributionScreenState extends State<GradeDistributionScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final AcademicDashboardService _academicDashboardService =
      const AcademicDashboardService();
  final List<_CourseGrade> _courses = [];
  AcademicDashboardSummary? _dashboardSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  Future<void> _loadAcademicData() async {
    try {
      final courses = await _databaseHelper.getCourses();
      final tasks = await _databaseHelper.getTasks();
      final exams = await _databaseHelper.getExams();

      final converted = courses.map((course) {
        final courseAverage = ((course.midGrade ?? 0) +
                    (course.practicalGrade ?? 0) +
                    (course.finalGrade ?? 0)) /
                3;
        final isPractical = (course.practicalGrade ?? 0) > 0 ||
            course.code.toLowerCase().contains('lab') ||
            course.name.toLowerCase().contains('lab');

        return _CourseGrade(
          title: course.name,
          code: course.code,
          isPractical: isPractical,
          coursework: 0,
          assignments: 0,
          midterm: course.midGrade ?? 0,
          lab: course.practicalGrade ?? 0,
          finalExam: course.finalGrade ?? 0,
          credits: course.creditHours ?? 3,
          id: course.id,
          totalScore: courseAverage,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _courses
          ..clear()
          ..addAll(converted);
        _dashboardSummary = _academicDashboardService.analyze(
          courses: courses,
          tasks: tasks,
          exams: exams,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _pickMotivation(double pct) {
    if (pct > 85) {
      return 'أداء استثنائي! حافظ على هذا الزخم نحو مرتبة الشرف 🚀';
    }
    if (pct >= 70) {
      return 'خطواتك ثابتة وممتازة! التركيز في القادم سيصنع الفارق 🎯';
    }
    if (pct >= 60) {
      return 'ما زالت كل الفرص بيدك، ركز على التعويض في النهائي والعملي 💪';
    }
    return 'البدايات لا تحدد النهاية، نظّم خطتك وابدأ جني درجات النهائي الآن ⚡';
  }

  _GradeBreakdown _computeBreakdown() {
    double totalEarned = 0;
    double totalPossible = 0;
    for (final c in _courses) {
      totalEarned += c.total;
      totalPossible += 100;
    }
    if (totalPossible == 0) return _GradeBreakdown(0, 0, 0);
    final earned = (totalEarned / totalPossible) * 100;
    final deficit = (100 - earned).clamp(0, 100).toDouble();
    final remaining = (100 - earned).clamp(0, 100).toDouble();
    return _GradeBreakdown(earned, deficit, remaining);
  }

  _GradeProjection _projectGpa(double pct) {
    final scale4 = (pct / 100) * 4.0;
    final scale5 = (pct / 100) * 5.0;
    return _GradeProjection(
      pct,
      double.parse(scale4.toStringAsFixed(2)),
      double.parse(scale5.toStringAsFixed(2)),
    );
  }

  String _letterGrade(double pct) {
    if (pct >= 95) return 'A+';
    if (pct >= 90) return 'A';
    if (pct >= 85) return 'B+';
    if (pct >= 80) return 'B';
    if (pct >= 75) return 'C+';
    if (pct >= 70) return 'C';
    if (pct >= 60) return 'D';
    return 'F';
  }

  Future<void> _showAddCourseDialog() async {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: '3');
    bool isPractical = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'إضافة مادة للمخطط',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtrl,
                        decoration:
                            const InputDecoration(labelText: 'اسم المادة'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: codeCtrl,
                        decoration:
                            const InputDecoration(labelText: 'رمز المادة'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: creditsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'ساعات الاعتماد',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<bool>(
                            value: isPractical,
                            items: const [
                              DropdownMenuItem(
                                value: false,
                                child: Text('نظرية 📖'),
                              ),
                              DropdownMenuItem(
                                value: true,
                                child: Text('عملية 💻'),
                              ),
                            ],
                            onChanged: (v) =>
                                setStateDialog(() => isPractical = v ?? false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final t = titleCtrl.text.trim();
                              if (t.isEmpty) return;
                              final code = codeCtrl.text.trim();
                              final credits =
                                  int.tryParse(creditsCtrl.text) ?? 3;
                              setState(() {
                                _courses.add(
                                  _CourseGrade(
                                    title: t,
                                    code: code,
                                    isPractical: isPractical,
                                    credits: credits,
                                  ),
                                );
                              });
                              if (mounted) Navigator.pop(context, true);
                            },
                            child: const Text('أضف'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (result == true) setState(() {});
  }

  Future<void> _showEditGradeDialog(_CourseGrade course) async {
    final cwCtrl = TextEditingController(text: course.coursework.toString());
    final asCtrl = TextEditingController(text: course.assignments.toString());
    final midCtrl = TextEditingController(text: course.midterm.toString());
    final labCtrl = TextEditingController(text: course.lab.toString());
    final finalCtrl = TextEditingController(text: course.finalExam.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تعديل مكونات الدرجة - ${course.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cwCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'أعمال الفصل (Max 10)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: asCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: course.isPractical
                          ? 'أعمال وتكاليف (Max 10)'
                          : 'التكاليف والواجبات (Max 10)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: midCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: course.isPractical
                          ? 'الاختبار النصفي (Max 10)'
                          : 'الاختبار النصفي (Max 20)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (course.isPractical)
                    TextField(
                      controller: labCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الاختبار العملي والمعمل (Max 30)',
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: finalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: course.isPractical
                          ? 'الاختبار النهائي (Max 50)'
                          : 'الاختبار النهائي (Max 60)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final cw = (double.tryParse(cwCtrl.text) ?? 0)
                                .clamp(0, 10)
                                .toDouble();
                            final asg = (double.tryParse(asCtrl.text) ?? 0)
                                .clamp(0, 10)
                                .toDouble();
                            final mid = (double.tryParse(midCtrl.text) ?? 0)
                                .clamp(0, course.isPractical ? 10 : 20)
                                .toDouble();
                            final lab = course.isPractical
                                ? (double.tryParse(labCtrl.text) ?? 0)
                                    .clamp(0, 30)
                                    .toDouble()
                                : 0.0;
                            final fin = (double.tryParse(finalCtrl.text) ?? 0)
                                .clamp(0, course.isPractical ? 50 : 60)
                                .toDouble();
                            setState(() {
                              course.coursework = cw;
                              course.assignments = asg;
                              course.midterm = mid;
                              course.lab = lab;
                              course.finalExam = fin;
                              course.totalScore =
                                  (cw + asg + mid + lab + fin)
                                      .clamp(0, 100)
                                      .toDouble();
                            });
                            if (course.id != null) {
                              await _databaseHelper.updateCourseGrades(
                                course.id!,
                                midGrade: mid,
                                practicalGrade: lab,
                                finalGrade: fin,
                                creditHours: course.credits,
                              );
                            }
                            if (!mounted) return;
                            setState(() {
                              course.coursework = cw;
                              course.assignments = asg;
                              course.midterm = mid;
                              course.lab = lab;
                              course.finalExam = fin;
                              course.totalScore =
                                  (cw + asg + mid + lab + fin)
                                      .clamp(0, 100)
                                      .toDouble();
                            });
                            Navigator.pop(context, true);
                          } catch (_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('حدث خطأ في الإدخال'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result == true) setState(() {});
  }

  Widget _buildHeroAnalyticsCard() {
    final bd = _computeBreakdown();
    final proj = _projectGpa(bd.earned);
    final summary = _dashboardSummary ??
        const AcademicDashboardSummary(
          totalCourses: 0,
          totalTasks: 0,
          completedTasks: 0,
          pendingTasks: 0,
          averageCourseScore: 0,
          urgentTasks: 0,
          upcomingExams: 0,
          taskCompletionRate: 0,
          focusMessage: 'Start by adding your academic data.',
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
            Theme.of(context).cardColor,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'توزيع الدرجات والمعدل الأكاديمي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                child: Icon(
                  Icons.auto_graph_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBreakdown(bd),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _analyticsMetricTile(
                  label: 'Average score',
                  value: '${summary.averageCourseScore.toStringAsFixed(1)}%',
                  icon: Icons.school_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _analyticsMetricTile(
                  label: 'Task completion',
                  value: '${summary.taskCompletionRate.toStringAsFixed(0)}%',
                  icon: Icons.task_alt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _analyticsMetricTile(
                  label: 'Upcoming exams',
                  value: summary.upcomingExams.toString(),
                  icon: Icons.event_available_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _analyticsMetricTile(
                  label: 'Urgent tasks',
                  value: summary.urgentTasks.toString(),
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المعدل المتوقع',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${proj.percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${proj.scale4} / 4.0  •  ${proj.scale5} / 5.0',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  summary.focusMessage,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _analyticsMetricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBreakdown(_GradeBreakdown bd) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'النسبة المكتسبة',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: bd.earned / 100,
                    minHeight: 8,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${bd.earned.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'نقص ${bd.deficit.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (bd.earned / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourseGradeCard(_CourseGrade course) {
    final pct = course.total;
    final letter = _letterGrade(pct);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(course.code.isNotEmpty ? course.code : '—'),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(course.isPractical ? 'عملي' : 'نظري')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(letter),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('أعمال الفصل'),
                  onPressed: () => _showEditGradeDialog(course),
                ),
                ActionChip(
                  label: Text(
                    course.isPractical ? 'الاختبار العملي' : 'الاختبار النصفي',
                  ),
                  onPressed: () => _showEditGradeDialog(course),
                ),
                ActionChip(
                  label: const Text('الاختبار النهائي'),
                  onPressed: () => _showEditGradeDialog(course),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _showEditGradeDialog(course),
                  child: const Text('رصد وتعديل الدرجات'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() => _courses.remove(course));
                  },
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(
              Icons.auto_graph_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ابدأ رسم خريطة درجاتك ومعدلك',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف موادك النظرية والعملية لرؤية شريط التقدم وفرص التعويض أولاً بأول',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _showAddCourseDialog,
            child: const Text('إضافة أول مادة للمخطط'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bd = _computeBreakdown();
    return Scaffold(
      appBar: AppBar(
        title: const Text('توزيع الدرجات والمعدل الأكاديمي'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_courses.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroAnalyticsCard(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'المقررّات',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _showAddCourseDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('إضافة مادة'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_courses.isEmpty)
                              _buildEmptyState()
                            else
                              Column(
                                children:
                                    _courses.map(_buildCourseGradeCard).toList(),
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      )),
        ),
      ),
    ),
    );
  }
}
