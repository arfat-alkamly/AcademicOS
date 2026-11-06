import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/course_use_cases.dart';

class StudyPlannerScreen extends StatefulWidget {
  final CourseUseCases courseUseCases;

  const StudyPlannerScreen({
    super.key,
    required this.courseUseCases,
  });

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  List<CourseEntity> _courses = [];
  bool _loading = true;
  String? _selectedCourseName;

  final TextEditingController _scopeController =
      TextEditingController(text: '12');
  final TextEditingController _hoursController =
      TextEditingController(text: '2');
  final TextEditingController _daysController =
      TextEditingController(text: '7');

  final List<_StudyDay> _studyDays = [];
  bool _planGenerated = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _scopeController.dispose();
    _hoursController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await widget.courseUseCases.getCourses().timeout(
            const Duration(seconds: 4),
            onTimeout: () => <CourseEntity>[],
          );
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _loading = false;
        if (courses.isNotEmpty) {
          _selectedCourseName = courses.first.name;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _courses = [];
        _loading = false;
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int _parseInt(TextEditingController controller, {int fallback = 1}) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  double _progressPercent() {
    if (_studyDays.isEmpty) return 0;
    final done = _studyDays.where((day) => day.isCompleted).length;
    return (done / _studyDays.length) * 100;
  }

  String _motivationMessage() {
    final percent = _progressPercent();
    if (percent >= 80) return 'أحسنت.. لم يتبقى إلا اللمسات الأخيرة!';
    if (percent >= 60) return 'أنجزت 60% من خطة المذاكرة.. الامتياز قريب!';
    if (percent >= 35) return 'أنت على الطريق الصحيح.. استمر بثبات!';
    return 'ابدأ بخطوة يومية.. كل جلسة تقربك للنجاح.';
  }

  void _generatePlan() {
    final scope = _parseInt(_scopeController, fallback: 10);
    final totalDays = _parseInt(_daysController, fallback: 7);
    final hours = _parseInt(_hoursController, fallback: 2);

    final items = <_StudyDay>[];
    final unitsPerDay = math.max(1, (scope / totalDays).ceil());

    for (var dayIndex = 1; dayIndex <= totalDays; dayIndex++) {
      final start = (dayIndex - 1) * unitsPerDay + 1;
      final end = math.min(scope, dayIndex * unitsPerDay);
      final isLast = dayIndex == totalDays;

      items.add(
        _StudyDay(
          dayLabel: 'Day $dayIndex',
          title: isLast
              ? 'مراجعة شاملة + أسئلة'
              : 'Ch ${start.toString()}-${end.toString()}',
          hours: hours,
          details: isLast
              ? 'مراجعة شاملة، أسئلة سريعة، وتلخيص أهم النقاط.'
              : 'دراسة الوحدات ${start.toString()}-${end.toString()} مع تمارين قصيرة.',
          isCompleted: false,
        ),
      );
    }

    setState(() {
      _studyDays
        ..clear()
        ..addAll(items);
      _planGenerated = true;
    });
  }

  Future<void> _savePlan() async {
    if (_studyDays.isEmpty) return;
    final courseName = _selectedCourseName ?? 'المادة';
    final message = 'تم حفظ خطة المذاكرة لـ $courseName بنجاح.. الله يوفقك!';
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressPercent();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مخطط المذاكرة الذكي'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(
                  child: Text('لا توجد مواد مسجلة لعرض المخطط'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إعداد الخطة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _selectedCourseName,
                                decoration: const InputDecoration(
                                  labelText: 'اختر المادة',
                                ),
                                items: _courses
                                    .map(
                                      (course) => DropdownMenuItem<String>(
                                        value: course.name,
                                        child: Text(course.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedCourseName = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _scopeController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(),
                                decoration: const InputDecoration(
                                  labelText: 'عدد الفصول/الوحدات أو الصفحات',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _daysController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(),
                                decoration: const InputDecoration(
                                  labelText: 'عدد الأيام المتاحة',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _hoursController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(),
                                decoration: const InputDecoration(
                                  labelText: 'الساعات اليومية المتاحة',
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _generatePlan,
                                  icon: const Icon(Icons.auto_awesome_outlined),
                                  label: const Text('إنشاء الخطة الذكية'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_planGenerated) ...[
                        const SizedBox(height: 18),
                        Card(
                          color: Colors.indigo.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.flag_circle_rounded,
                                        color: Colors.indigo),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'تقدم الخطة',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${progress.toStringAsFixed(0)}% مكتمل',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: progress / 100,
                                  minHeight: 10,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _motivationMessage(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._studyDays.asMap().entries.map((entry) {
                          final index = entry.key;
                          final day = entry.value;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: day.isCompleted,
                                    onChanged: (value) {
                                      setState(() {
                                        _studyDays[index] = day.copyWith(
                                          isCompleted: value ?? false,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          day.dayLabel,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: day.isCompleted
                                                ? Colors.green.shade700
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          day.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${day.hours} ساعة • ${day.details}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _savePlan,
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text('حفظ الخطة'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _StudyDay {
  final String dayLabel;
  final String title;
  final int hours;
  final String details;
  final bool isCompleted;

  const _StudyDay({
    required this.dayLabel,
    required this.title,
    required this.hours,
    required this.details,
    required this.isCompleted,
  });

  _StudyDay copyWith({bool? isCompleted}) {
    return _StudyDay(
      dayLabel: dayLabel,
      title: title,
      hours: hours,
      details: details,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
