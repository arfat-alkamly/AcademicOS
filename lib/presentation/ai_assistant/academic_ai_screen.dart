import 'package:flutter/material.dart';

import '../../core/academic/academic_assistant_service.dart';
import '../../data/models/exam_model.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/task_entity.dart';

class AcademicAiScreen extends StatefulWidget {
  final List<CourseEntity> courses;
  final List<TaskEntity> tasks;
  final List<ExamModel> exams;

  const AcademicAiScreen({
    super.key,
    this.courses = const [],
    this.tasks = const [],
    this.exams = const [],
  });

  @override
  State<AcademicAiScreen> createState() => _AcademicAiScreenState();
}

class _AcademicAiScreenState extends State<AcademicAiScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'مرحباً، أنا المساعد الأكاديمي الذكي.. سأقوم بتحليل مهامك، موادك، ومواعيدك الحالية وأعطيك اقتراحات عملية في الوقت الحقيقي.',
      isUser: false,
      accent: Color(0xFF1D4ED8),
    ),
  ];

  final List<String> _suggestedPrompts = [
    'عندي محاضرة أمن شبكات غداً الساعة 10',
    'كم باقي على أول اختبار وماذا أحتاج للمذاكرة؟',
    'احسب درجاتي وتوقع معدلي الفصلي',
    'وزع لي خطة مذاكرة لمادة التشفير خلال 3 أيام',
    'سجل غياب في مادة الخوارزميات ونبهني إذا اقترب الحرمان',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendPrompt(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages
          .add(_ChatMessage(text: trimmed, isUser: true, accent: Colors.green));
      _messages.add(
        _ChatMessage(
          text: _buildAssistantReply(trimmed),
          isUser: false,
          accent: const Color(0xFF0EA5E9),
        ),
      );
    });

    _messageController.clear();
  }

  String _buildAssistantReply(String input) {
    final result = const AcademicAssistantService().buildResponse(
      input: input,
      courses: widget.courses,
      tasks: widget.tasks,
      exams: widget.exams,
    );

    if (result.needsFollowUp && result.followUpQuestion != null) {
      return '${result.response}\n\n${result.followUpQuestion}';
    }

    return result.response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد الأكاديمي الذكي'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _messages.clear()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'متصل ومستعد لمساعدتك',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _sendPrompt(prompt),
                  backgroundColor: Colors.indigo.shade50,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color:
                          message.isUser ? Colors.blue.shade600 : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: message.isUser
                            ? Colors.blue.shade500
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, -3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.mic_none_rounded),
                  tooltip: 'تحويل الصوت إلى نص',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب طلبك أو سؤالك...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _sendPrompt,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: () => _sendPrompt(_messageController.text),
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final Color accent;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.accent,
  });
}
