import 'dart:async';

class Summary {
  final List<String> coreConcepts; // المفاهيم الأساسية
  final List<String> keyPoints; // النقاط الجوهرية (جمل مهمة)
  final String quickSummary; // ملخص سريع

  Summary({
    required this.coreConcepts,
    required this.keyPoints,
    required this.quickSummary,
  });
}

class LocalSummarizerService {
  LocalSummarizerService._();
  static final LocalSummarizerService instance = LocalSummarizerService._();

  static final Set<String> _stopwords = {
    'و', 'في', 'على', 'من', 'إلى', 'عن', 'أن', 'فيه', 'فيها', 'هو', 'هي', 'هذا', 'هذه',
    'مع', 'كان', 'كما', 'ما', 'لم', 'لن', 'قد', 'كل', 'بين', 'بعد', 'قبل', 'حتى',
    'the', 'is', 'in', 'and', 'of', 'to', 'a', 'for', 'on', 'with', 'that', 'this',
  };

  static final RegExp _tokenRegExp =
      RegExp(r"[A-Za-z0-9\u0600-\u06FF']+", caseSensitive: false);

  static final RegExp _sentenceRegExp = RegExp(r'[^.!?؟;]+[.!?؟;]?');

  Future<Summary> summarize(String text,
      {int maxSentences = 5, int maxConcepts = 8}) async {
    return await Future<Summary>.microtask(() {
      if (text.trim().isEmpty) {
        return Summary(coreConcepts: [], keyPoints: [], quickSummary: '');
      }

      final maxChars = 200000;
      if (text.length > maxChars) text = text.substring(0, maxChars);

      text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      final rawLines = text.split('\n');
      final Set<String> headingWords = {};
      for (final raw in rawLines) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        final words = _tokenRegExp
            .allMatches(line)
            .map((m) => m.group(0)!.toLowerCase())
            .where((w) => w.length > 1)
            .toList();
        if (words.length <= 6 && words.isNotEmpty) {
          headingWords.addAll(words.where((w) => !_stopwords.contains(w)));
        }
      }

      final sentences = <String>[];
      for (final m in _sentenceRegExp.allMatches(text)) {
        final s = m.group(0)!.trim();
        if (s.isEmpty) continue;
        if (s.replaceAll(RegExp(r'[^A-Za-z0-9\u0600-\u06FF]'), '').length < 6)
          continue;
        sentences.add(s);
      }
      if (sentences.isEmpty) {
        return Summary(coreConcepts: [], keyPoints: [], quickSummary: '');
      }

      final Map<String, int> freq = {};
      final List<List<String>> sentenceTokens =
          List.generate(sentences.length, (_) => []);

      for (var i = 0; i < sentences.length; i++) {
        final s = sentences[i].toLowerCase();
        final tokens = _tokenRegExp
            .allMatches(s)
            .map((m) => m.group(0)!)
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .map((t) => t.toLowerCase())
            .where((t) => !_stopwords.contains(t))
            .toList();
        sentenceTokens[i] = tokens;
        for (final t in tokens) {
          freq[t] = (freq[t] ?? 0) + 1;
        }
      }

      final Map<int, double> scores = {};
      for (var i = 0; i < sentenceTokens.length; i++) {
        final tokens = sentenceTokens[i];
        if (tokens.isEmpty) {
          scores[i] = 0.0;
          continue;
        }
        double sum = 0;
        for (final t in tokens) {
          sum += (freq[t] ?? 0);
        }
        final base = sum / (tokens.length);
        final containsHeading = tokens.any((t) => headingWords.contains(t));
        final headingBoost = containsHeading ? 1.4 : 1.0;
        final hasDigits = RegExp(r'\d').hasMatch(sentences[i]) ? 1.1 : 1.0;
        scores[i] = base * headingBoost * hasDigits;
      }

      final sortedIndices = scores.keys.toList()
        ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

      final selectedSet = <int>{};
      for (final idx in sortedIndices) {
        if (selectedSet.length >= maxSentences) break;
        selectedSet.add(idx);
      }

      final selectedIndices = selectedSet.toList()..sort();
      final keyPoints = selectedIndices.map((i) => sentences[i]).toList();

      final concepts = freq.keys.toList()
        ..sort((a, b) => freq[b]!.compareTo(freq[a]!));
      final coreConcepts = concepts.take(maxConcepts).toList();

      final quickSummary = keyPoints.join(' ');

      return Summary(
        coreConcepts: coreConcepts,
        keyPoints: keyPoints,
        quickSummary: quickSummary,
      );
    });
  }
}
