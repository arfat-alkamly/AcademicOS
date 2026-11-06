import 'package:flutter/material.dart';

enum CourseType { theoryOnly, theoryAndPractical }

class GradeSimulatorScreen extends StatefulWidget {
  const GradeSimulatorScreen({super.key});

  @override
  State<GradeSimulatorScreen> createState() => _GradeSimulatorScreenState();
}

class _GradeSimulatorScreenState extends State<GradeSimulatorScreen> {
  CourseType _type = CourseType.theoryOnly;
  double _target = 90;

  // Theory only parts
  double _mid = 0;
  double _assign = 0;
  double _attend = 0;
  double _final = 0;

  // Practical variant parts
  double _practical = 0;
  double _midSmall = 0;
  double _assignAttend = 0;
  double _finalLarge = 0;

  double _clamp(double v, double max) =>
      v.isNaN ? 0 : (v < 0 ? 0 : (v > max ? max : v));

  @override
  Widget build(BuildContext context) {
    final isTheory = _type == CourseType.theoryOnly;

    final midMax = isTheory ? 20.0 : 10.0;
    final assignMax = isTheory ? 10.0 : 10.0; // combined for practical
    final attendMax = isTheory ? 10.0 : 0.0;
    final practicalMax = isTheory ? 0.0 : 30.0;
    final finalMax = isTheory ? 60.0 : 50.0;

    final other = isTheory
        ? _clamp(_mid, midMax) +
            _clamp(_assign, assignMax) +
            _clamp(_attend, attendMax)
        : _clamp(_practical, practicalMax) +
            _clamp(_midSmall, midMax) +
            _clamp(_assignAttend, assignMax);

    final currentFinal = _clamp(isTheory ? _final : _finalLarge, finalMax);
    final currentTotal = other + currentFinal;
    final maxPossible = other + finalMax;
    final remainingToTarget =
        (_target - currentTotal).clamp(0, double.infinity);
    final requiredFinal = ((_target - other)).clamp(0, double.infinity);

    String statusLabel;
    Color statusColor;
    if (maxPossible >= _target) {
      statusLabel = 'على المسار الصحيح — يمكنك الوصول للهدف';
      statusColor = Colors.green;
    } else {
      statusLabel =
          'تحذير: الهدف غير ممكن. أقصى ما يمكنك الحصول عليه: ${maxPossible.toStringAsFixed(1)}';
      statusColor = Colors.red;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('محاكي ومخطط الدرجات الذكي')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('نوع المقرر',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<CourseType>(
                              title: const Text('نظري فقط'),
                              value: CourseType.theoryOnly,
                              groupValue: _type,
                              onChanged: (v) => setState(() => _type = v!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<CourseType>(
                              title: const Text('نظري وعملي'),
                              value: CourseType.theoryAndPractical,
                              groupValue: _type,
                              onChanged: (v) => setState(() => _type = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الهدف (درجة من 100)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _target,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: _target.round().toString(),
                              onChanged: (v) => setState(() => _target = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 56,
                            child: TextFormField(
                              initialValue: _target.round().toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (s) {
                                final p = double.tryParse(s) ?? _target;
                                setState(() => _target = p.clamp(0, 100));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Inputs
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isTheory
                              ? 'عناصر التقدير (نظري)'
                              : 'عناصر التقدير (نظري وعملي)',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (isTheory) ...[
                        _buildNumberField('الاختبار النصفي (من 20)', _mid, 20,
                            (v) => setState(() => _mid = v)),
                        const SizedBox(height: 8),
                        _buildNumberField('الواجبات (من 10)', _assign, 10,
                            (v) => setState(() => _assign = v)),
                        const SizedBox(height: 8),
                        _buildNumberField('الحضور (من 10)', _attend, 10,
                            (v) => setState(() => _attend = v)),
                        const SizedBox(height: 8),
                        _buildNumberField('النهائي (من 60)', _final, 60,
                            (v) => setState(() => _final = v)),
                      ] else ...[
                        _buildNumberField('العملي (من 30)', _practical, 30,
                            (v) => setState(() => _practical = v)),
                        const SizedBox(height: 8),
                        _buildNumberField('الاختبار (من 10)', _midSmall, 10,
                            (v) => setState(() => _midSmall = v)),
                        const SizedBox(height: 8),
                        _buildNumberField(
                            'الواجبات+الحضور (من 10)',
                            _assignAttend,
                            10,
                            (v) => setState(() => _assignAttend = v)),
                        const SizedBox(height: 8),
                        _buildNumberField('النهائي (من 50)', _finalLarge, 50,
                            (v) => setState(() => _finalLarge = v)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Results
              Card(
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('النتائج',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                                  'المجموع الحالي: ${currentTotal.toStringAsFixed(1)} / 100')),
                          _statusBadge(statusLabel, statusColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                          value: (currentTotal / _target).clamp(0, 1),
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          color: statusColor),
                      const SizedBox(height: 8),
                      Text(
                          'المتبقي للوصول للهدف: ${remainingToTarget.toStringAsFixed(1)}'),
                      const SizedBox(height: 8),
                      Text(
                          'المطلوب في النهائي: ${requiredFinal.clamp(0, finalMax).toStringAsFixed(1)} من ${finalMax.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      Text(
                          'أقصى درجة ممكنة بالمقرر: ${maxPossible.toStringAsFixed(1)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(
      String label, double value, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: max,
                divisions: max.round(),
                label: value.toStringAsFixed(1),
                onChanged: (v) => onChanged(v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: value.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (s) {
                  final p = double.tryParse(s) ?? value;
                  onChanged(p.clamp(0, max));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
