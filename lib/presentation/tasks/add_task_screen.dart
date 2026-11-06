import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;
  // New UI state (preserve existing names above)
  String _priority = 'متوسطة';
  String _taskType = 'أخرى';
  String _repeat = 'مرة واحدة';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final Map<String, dynamic> taskMap = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'isCompleted': 0,
      'priority': _priority,
      'type': _taskType,
      'repeat': _repeat,
      'dueDate': _dueDate?.toIso8601String(),
      'dueTime': _dueTime != null
          ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
          : null,
    };

    try {
      await DatabaseHelper.instance.insertTask(taskMap);

      scheduleMicrotask(() {});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المهمة بنجاح.')),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('AddTaskScreen._saveTask error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حفظ المهمة.')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('إضافة مهمة'), centerTitle: true, elevation: 0),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'أدخل عنوان المهمة',
                        labelText: 'عنوان المهمة',
                        prefixIcon: const Icon(Icons.title_outlined),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'أدخل عنوان المهمة'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        hintText: 'وصف تفصيلي للمهمة (اختياري)',
                        labelText: 'وصف المهمة',
                        prefixIcon: const Icon(Icons.description_outlined),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _buildPrioritySelector(),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildTaskTypeDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildRepeatDropdown()),
                    ]),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 12),
                    _buildTimePicker(),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'ملاحظات داخلية',
                        prefixIcon: const Icon(Icons.note_outlined),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveTask,
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary))
                              : const Text('حفظ المهمة'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final colors = {
      'منخفضة': Colors.green,
      'متوسطة': Colors.amber,
      'عالية': Colors.red,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          spacing: 8,
          children: colors.keys.map((k) {
            final selected = k == _priority;
            return ChoiceChip(
              label: Text(k),
              selected: selected,
              onSelected: (_) => setState(() => _priority = k),
              selectedColor: colors[k]!.withValues(alpha: 0.16),
            );
          }).toList()),
      const SizedBox(height: 8),
      Container(
          height: 4,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          child: FractionallySizedBox(
              widthFactor: _priority == 'منخفضة'
                  ? 0.33
                  : _priority == 'متوسطة'
                      ? 0.66
                      : 1.0,
              child: Container(
                  decoration: BoxDecoration(
                      color: colors[_priority]!.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4))))),
    ]);
  }

  Widget _buildTaskTypeDropdown() {
    final items = ['أخرى', 'دراسة', 'تسليم', 'قراءة', 'مراجعة'];
    return DropdownButtonFormField<String>(
      value: _taskType,
      items:
          items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: (v) => setState(() => _taskType = v ?? 'أخرى'),
      decoration: InputDecoration(
        labelText: 'نوع المهمة',
        prefixIcon: const Icon(Icons.category_outlined),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildRepeatDropdown() {
    final items = ['مرة واحدة', 'يومي', 'أسبوعي', 'شهري'];
    return DropdownButtonFormField<String>(
      value: _repeat,
      items:
          items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: (v) => setState(() => _repeat = v ?? 'مرة واحدة'),
      decoration: InputDecoration(
        labelText: 'تكرار المهمة',
        prefixIcon: const Icon(Icons.repeat_outlined),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDatePicker() {
    final text = _dueDate == null
        ? 'اختر تاريخ الاستحقاق'
        : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
            context: context,
            initialDate: _dueDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100));
        if (picked != null) setState(() => _dueDate = picked);
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          const Icon(Icons.arrow_drop_down)
        ]),
      ),
    );
  }

  Widget _buildTimePicker() {
    final text =
        _dueTime == null ? 'اختر وقت الاستحقاق' : _dueTime!.format(context);
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
            context: context, initialTime: _dueTime ?? TimeOfDay.now());
        if (picked != null) setState(() => _dueTime = picked);
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          const Icon(Icons.access_time_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          const Icon(Icons.arrow_drop_down)
        ]),
      ),
    );
  }
}
