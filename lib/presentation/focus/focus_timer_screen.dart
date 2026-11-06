import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/course_model.dart';
import '../../data/models/task_model.dart';
import '../../domain/entities/task_entity.dart';

enum _TimerPhase { focus, shortBreak, longBreak }

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final List<String> _quotes = [
    'المذاكرة المتواصلة تخلق التقدم الحقيقي.',
    'التركيز 25 دقيقة يفتح باب الإنجاز.',
    'كل جلسة قصيرة تبني رصيدك الأكاديمي.',
    'استثمر في اليوم، واحتفظ بهدوءك.',
    'الاستمرار هو ما يغير النتيجة.',
  ];

  List<CourseModel> _courses = const [];
  int? _selectedCourseId;

  _TimerPhase _phase = _TimerPhase.focus;
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;

  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  int _completedFocusSessions = 0;

  String _quote = '';

  @override
  void initState() {
    super.initState();
    _quote = _quotes.first;
    _loadCourses();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final courses = await _databaseHelper.getCourses();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      if (courses.isNotEmpty && _selectedCourseId == null) {
        _selectedCourseId = courses.first.id;
      }
    });
  }

  int get _phaseDurationInSeconds {
    switch (_phase) {
      case _TimerPhase.focus:
        return _focusMinutes * 60;
      case _TimerPhase.shortBreak:
        return _shortBreakMinutes * 60;
      case _TimerPhase.longBreak:
        return _longBreakMinutes * 60;
    }
  }

  double get _progressPercent {
    final total = _phaseDurationInSeconds;
    if (total <= 0) return 0;
    final elapsed = total - _remainingSeconds;
    final percent = (elapsed / total) * 100;
    return percent.clamp(0.0, 100.0);
  }

  String get _phaseLabel {
    switch (_phase) {
      case _TimerPhase.focus:
        return 'جلسة تركيز';
      case _TimerPhase.shortBreak:
        return 'استراحة قصيرة';
      case _TimerPhase.longBreak:
        return 'استراحة طويلة';
    }
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _setRandomQuote() {
    final index = DateTime.now().millisecondsSinceEpoch % _quotes.length;
    setState(() => _quote = _quotes[index]);
  }

  void _resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _phaseDurationInSeconds;
    if (!mounted) return;
    setState(() {});
  }

  void _switchPhase(_TimerPhase nextPhase) {
    _phase = nextPhase;
    _remainingSeconds = _phaseDurationInSeconds;
    _isRunning = false;
    _timer?.cancel();
    setState(() {});
  }

  void _startTimer() {
    if (_isRunning) return;
    _setRandomQuote();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleSessionCompletion();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    if (mounted) {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _handleSessionCompletion() async {
    final sessionMinutes = (_phase == _TimerPhase.focus)
        ? _focusMinutes
        : (_phase == _TimerPhase.shortBreak)
            ? _shortBreakMinutes
            : _longBreakMinutes;

    if (_phase == _TimerPhase.focus) {
      _completedFocusSessions += 1;
      await _saveFocusLog(sessionMinutes);
      final nextPhase = _completedFocusSessions % 4 == 0
          ? _TimerPhase.longBreak
          : _TimerPhase.shortBreak;
      _switchPhase(nextPhase);
      return;
    }

    _switchPhase(_TimerPhase.focus);
  }

  Future<void> _saveFocusLog(int minutes) async {
    final selectedCourse = _courses.firstWhere(
      (course) => course.id == _selectedCourseId,
      orElse: () => _courses.first,
    );

    if (_selectedCourseId == null && _courses.isEmpty) {
      return;
    }

    final title = 'جلسة تركيز - ${selectedCourse.name}';
    final task = TaskModel(
      title: title,
      description: 'تمت دراسة مركزة لمدة $minutes دقيقة في موضوع ${selectedCourse.name}.',
      type: TaskType.review,
      priority: TaskPriority.medium,
      recurrence: TaskRecurrence.once,
      dueDate: DateTime.now(),
      isCompleted: true,
      courseId: selectedCourse.id,
      courseName: selectedCourse.name,
      notes: 'Focus Mode Session',
      reminderEnabled: false,
    );

    await _databaseHelper.insertTask(task);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل ${minutes} دقيقة من الدراسة في ${selectedCourse.name}.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCourse = _courses.firstWhere(
      (course) => course.id == _selectedCourseId,
      orElse: () => CourseModel(
        name: 'غير محدد',
        instructor: '',
        code: '',
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Focus Mode'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'جلسة المذاكرة الحالية',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedCourseId,
                      dropdownColor: const Color(0xFF111827),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1F2937),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: _courses.isEmpty
                          ? const [
                              DropdownMenuItem<int>(
                                value: null,
                                child: Text('لا توجد مواد', style: TextStyle(color: Colors.white70)),
                              ),
                            ]
                          : _courses.map((course) {
                              return DropdownMenuItem<int>(
                                value: course.id,
                                child: Text(course.name),
                              );
                            }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedCourseId = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: CustomPaint(
                  painter: _CircularTimerPainter(
                    progress: _progressPercent / 100,
                    color: _phase == _TimerPhase.focus
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF22C55E),
                    backgroundColor: Colors.white12,
                  ),
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _phaseLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formattedTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          selectedCourse.name,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeChip(
                        label: 'تركيز 25',
                        selected: _phase == _TimerPhase.focus,
                        onTap: () => _switchPhase(_TimerPhase.focus),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeChip(
                        label: 'استراحة 5',
                        selected: _phase == _TimerPhase.shortBreak,
                        onTap: () => _switchPhase(_TimerPhase.shortBreak),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeChip(
                        label: 'استراحة 15',
                        selected: _phase == _TimerPhase.longBreak,
                        onTap: () => _switchPhase(_TimerPhase.longBreak),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isRunning ? null : _startTimer,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('ابدأ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isRunning ? _pauseTimer : null,
                      icon: const Icon(Icons.pause_rounded),
                      label: const Text('إيقاف'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('إعادة'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _quote,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F2937) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF8B5CF6) : Colors.white10,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularTimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 18;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
