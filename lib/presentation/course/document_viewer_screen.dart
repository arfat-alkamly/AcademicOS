import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DocumentViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const DocumentViewerScreen(
      {super.key, required this.filePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kIsWeb) ...[
                const Icon(Icons.insert_drive_file,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('عرض المستند غير مدعوم في الويب داخل التطبيق.'),
                const SizedBox(height: 8),
                Text('المسار: ' + filePath, textAlign: TextAlign.center),
              ] else ...[
                const Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                    'معاينة المستند داخل التطبيق غير متاحة في هذه النسخة.'),
                const SizedBox(height: 8),
                Text('المسار: ' + filePath, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
