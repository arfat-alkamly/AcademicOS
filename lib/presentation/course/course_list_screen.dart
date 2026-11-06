import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/course_use_cases.dart';
import '../../domain/usecases/task_use_cases.dart';
import 'add_edit_course_screen.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  final CourseUseCases courseUseCases;
  final TaskUseCases taskUseCases;

  const CourseListScreen({
    super.key,
    required this.courseUseCases,
    required this.taskUseCases,
  });

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  List<CourseEntity> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final courses = await widget.courseUseCases.getCourses();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(() => _searchQuery = query),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _courses
        .where((course) => course.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('المقررات الدراسية')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      labelText: 'بحث',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('لا توجد مقررات دراسية مضافة'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (_, index) {
                            final course = filtered[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(course.name),
                                subtitle: Text('${course.code} • ${course.instructor}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    if (course.id == null) return;
                                    await widget.courseUseCases.deleteCourse(course.id!);
                                    await _loadCourses();
                                  },
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailScreen(
                                        course: course,
                                        taskUseCases: widget.taskUseCases,
                                        courseUseCases: widget.courseUseCases,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditCourseScreen(useCases: widget.courseUseCases),
            ),
          );
          if (result == true) {
            await _loadCourses();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
