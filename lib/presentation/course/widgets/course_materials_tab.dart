import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../data/database/database_helper.dart';
import '../../../data/models/course_material_model.dart';
import '../document_viewer_screen.dart';

class CourseMaterialsTab extends StatefulWidget {
  final int courseId;
  const CourseMaterialsTab({super.key, required this.courseId});

  @override
  State<CourseMaterialsTab> createState() => _CourseMaterialsTabState();
}

class _CourseMaterialsTabState extends State<CourseMaterialsTab> {
  List<CourseMaterialModel> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);
    final rows =
        await DatabaseHelper.instance.getMaterialsByCourseId(widget.courseId);
    setState(() {
      _materials = rows.map(CourseMaterialModel.fromMap).toList();
      _isLoading = false;
    });
  }

  Future<void> _pickAndSave() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (result == null) return;
    final file = result.files.first;
    String? path = file.path;
    if (path == null && file.bytes != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('معاينة الملفات غير مدعومة في المتصفح.')));
      return;
    }

    final fileName = p.basename(path!);
    final ext = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    try {
      final appDir = Directory.systemTemp.path;
      final dest = p.join(appDir, 'academic_os_materials');
      await Directory(dest).create(recursive: true);
      final destPath =
          p.join(dest, '${DateTime.now().millisecondsSinceEpoch}_$fileName');
      await File(path).copy(destPath);

      final model = CourseMaterialModel(
        courseId: widget.courseId,
        title: fileName,
        filePath: destPath,
        fileType: ext,
      );
      await DatabaseHelper.instance.insertMaterial(model.toMap());
      await _loadMaterials();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم إضافة الملف بنجاح.')));
    } catch (e) {
      debugPrint('Failed to save material: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فشل حفظ الملف.')));
    }
  }

  Future<void> _openMaterial(CourseMaterialModel material) async {
    if (material.fileType == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DocumentViewerScreen(
                filePath: material.filePath, title: material.title)),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(material.title),
          content: const Text(
              'معاينة هذا النوع من الملفات غير مدعومة داخل التطبيق حالياً.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق')),
          ],
        ),
      );
    }
  }

  Future<void> _deleteMaterial(int id) async {
    await DatabaseHelper.instance.deleteMaterial(id);
    await _loadMaterials();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                  child: Text('المحاضرات والمرفقات',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ElevatedButton.icon(
                  onPressed: _pickAndSave,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('إضافة محاضرة / ملف')),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _materials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('لا توجد محاضرات مضافة بعد.'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                              onPressed: _pickAndSave,
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة محاضرة')),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _materials.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = _materials[index];
                        return ListTile(
                          leading: _fileBadge(m.fileType),
                          title: Text(m.title),
                          subtitle: Text(m.fileType.toUpperCase()),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteMaterial(m.id!)),
                          onTap: () => _openMaterial(m),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _fileBadge(String type) {
    final t = type.toLowerCase();
    IconData icon;
    Color color;
    switch (t) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        color = Colors.orange;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }
    return CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color));
  }
}
