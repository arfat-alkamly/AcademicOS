import 'package:flutter/material.dart';

import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/course_use_cases.dart';

class TargetGradeCalculatorScreen extends StatefulWidget {
  final CourseUseCases courseUseCases;

  const TargetGradeCalculatorScreen({
    super.key,
    required this.courseUseCases,
  });

  @override
  State<TargetGradeCalculatorScreen> createState() =>
      _TargetGradeCalculatorScreenState();
}

class _TargetGradeCalculatorScreenState
    extends State<TargetGradeCalculatorScreen> {
  List<CourseEntity> _courses = [];
  bool _loading = true;
  String? _selectedCourseName;

  final TextEditingController _earnedMarksController = TextEditingController();
  final TextEditingController _currentMaxController = TextEditingController(
    text: '50',
  );
  final TextEditingController _finalWeightController = TextEditingController(
    text: '50',
  );

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _earnedMarksController.dispose();
    _currentMaxController.dispose();
    _finalWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await widget.courseUseCases.getCourses();
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
      setState(() => _loading = false);
    }
  }

  double _parseValue(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  double _requiredFinalScore(double targetPercent) {
    final earned = _parseValue(_earnedMarksController);
    final currentMax = _parseValue(_currentMaxController);
    final finalWeight = _parseValue(_finalWeightController);

    if (currentMax <= 0 || finalWeight <= 0 || finalWeight >= 100) {
      return 0;
    }

    final currentPercent = currentMax == 0 ? 0 : (earned / currentMax) * 100;
    final weightedCurrent = currentPercent * ((100 - finalWeight) / 100);
    final neededPercent = ((targetPercent - weightedCurrent) / finalWeight) * 100;

    return neededPercent.clamp(0, 100);
  }

  String _statusMessage(double requiredScore) {
    if (requiredScore <= 20) {
      return 'الهدف ممكن جداً.. شد حيلك!';
    }
    if (requiredScore <= 35) {
      return 'متبقي قليل على الامتياز!';
    }
    if (requiredScore <= 50) {
      return 'مستوى جيد، لكن تحتاج تركيز أكبر في النهائي.';
    }
    if (requiredScore <= 75) {
      return 'سير العمل مضبوط، لكن الهدف يحتاج مجهود أكبر.';
    }
    return 'المطلوب أكبر من الواقع الحالي، لكن التزامك سيصل بك للهدف.';
  }

  Color _statusColor(double requiredScore) {
    if (requiredScore <= 20) return Colors.green;
    if (requiredScore <= 35) return Colors.amber.shade700;
    if (requiredScore <= 50) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final aRequired = _requiredFinalScore(90);
    final bRequired = _requiredFinalScore(80);
    final cRequired = _requiredFinalScore(70);
    final pass50Required = _requiredFinalScore(50);
    final pass60Required = _requiredFinalScore(60);

    final strongest = [aRequired, bRequired, cRequired, pass50Required, pass60Required]
        .reduce((value, element) => value > element ? value : element);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة الهدف والدرجات المتوقعة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                            'معلومات المادة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCourseName,
                            decoration: const InputDecoration(
                              labelText: 'اختر المادة أو اكتب اسمها يدويًا',
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'إدخال يدوي',
                                child: Text('إدخال يدوي'),
                              ),
                              ..._courses.map(
                                (course) => DropdownMenuItem<String>(
                                  value: course.name,
                                  child: Text(course.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedCourseName = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _earnedMarksController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'المجموع الحالي المكتسب حتى الآن',
                              hintText: 'مثل: 35',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _currentMaxController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'أقصى مجموع سابق للامتحان النهائي',
                              hintText: 'مثل: 50',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _finalWeightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'وزن الامتحان النهائي (%)',
                              hintText: 'مثل: 50 أو 60',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trending_up_rounded, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'ملخص الهدف',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag_circle_rounded,
                                  color: _statusColor(strongest),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _statusMessage(strongest),
                                    style: TextStyle(
                                      color: _statusColor(strongest),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildRequirementRow(
                            'الامتياز (90%)',
                            aRequired,
                            Colors.green,
                          ),
                          _buildRequirementRow(
                            'جيد جدًا (80%)',
                            bRequired,
                            Colors.blue,
                          ),
                          _buildRequirementRow(
                            'جيد (70%)',
                            cRequired,
                            Colors.orange,
                          ),
                          _buildRequirementRow(
                            'النجاح (50%)',
                            pass50Required,
                            Colors.purple,
                          ),
                          _buildRequirementRow(
                            'النجاح (60%)',
                            pass60Required,
                            Colors.indigo,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRequirementRow(String title, double requiredScore, Color color) {
    final label = requiredScore > 100
        ? 'أكثر من 100'
        : '${requiredScore.toStringAsFixed(1)} / 100';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
