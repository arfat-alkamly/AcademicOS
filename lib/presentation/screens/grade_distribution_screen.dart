import 'package:flutter/material.dart';

class GradeDistributionScreen extends StatefulWidget {
  const GradeDistributionScreen({super.key});

  @override
  State<GradeDistributionScreen> createState() =>
      _GradeDistributionScreenState();
}

class _GradeDistributionScreenState extends State<GradeDistributionScreen> {
  // Schemas: theoretical and practical components
  final Map<String, List<int>> schemas = {
    'Theoretical': [10, 10, 20, 60],
    'Practical': [10, 10, 30, 50],
  };

  String _selectedSchema = 'Theoretical';
  // scores for components
  List<double> _scores = [0, 0, 0, 0];

  double get _totalPercent => _scores
      .asMap()
      .entries
      .fold(0.0, (p, e) => p + (e.value / schemas[_selectedSchema]![e.key]));

  void _setScore(int idx, double val) {
    setState(() =>
        _scores[idx] = val.clamp(0, schemas[_selectedSchema]![idx].toDouble()));
  }

  @override
  void didUpdateWidget(covariant GradeDistributionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = schemas[_selectedSchema]!;

    return Scaffold(
      appBar: AppBar(title: const Text('توزيع الدرجات والمعدل')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: schemas.keys
                              .map((k) =>
                                  ButtonSegment(value: k, label: Text(k)))
                              .toList(),
                          selected: <String>{_selectedSchema},
                          onSelectionChanged: (s) {
                            final next =
                                s.isNotEmpty ? s.first : _selectedSchema;
                            setState(() {
                              _selectedSchema = next;
                              _scores = List<double>.filled(4, 0);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Card(
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('مخطط التقييم ($_selectedSchema)',
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          ...List.generate(schema.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Component ${i + 1}',
                                          style: theme.textTheme.bodyLarge),
                                      Text(
                                          '${_scores[i].toStringAsFixed(1)} / ${schema[i]}',
                                          style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                  Slider(
                                    value: _scores[i],
                                    min: 0,
                                    max: schema[i].toDouble(),
                                    divisions: schema[i],
                                    label: _scores[i].toStringAsFixed(0),
                                    onChanged: (v) => _setScore(i, v),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          Text('الناتج المتوقع:',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (_scores.asMap().entries.fold<double>(
                                    0.0,
                                    (p, e) =>
                                        p +
                                        (e.value *
                                            schemas[_selectedSchema]![e.key] /
                                            (schemas[_selectedSchema]!
                                                    .reduce((a, b) => a + b) *
                                                schemas[_selectedSchema]![
                                                    e.key])))) /
                                1.0,
                            minHeight: 14,
                            color: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                          ),
                          const SizedBox(height: 12),
                          Text(
                              'مجموع النقاط: ${_scores.reduce((a, b) => a + b).toStringAsFixed(1)}',
                              textAlign: TextAlign.end,
                              style: theme.textTheme.titleSmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
