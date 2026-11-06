import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/academic_scaffold_background.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../../domain/usecases/course_use_cases.dart';
import '../../domain/usecases/task_use_cases.dart';
import '../home/home_screen.dart';

class StudentProfileSetupScreen extends StatefulWidget {
  final TaskUseCases taskUseCases;
  final CourseUseCases courseUseCases;
  final AuthUseCases authUseCases;
  final bool isDarkMode;
  final bool isArabic;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;

  const StudentProfileSetupScreen({
    super.key,
    required this.taskUseCases,
    required this.courseUseCases,
    required this.authUseCases,
    required this.isDarkMode,
    required this.isArabic,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<StudentProfileSetupScreen> createState() =>
      _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _targetGpaController = TextEditingController();

  String _selectedAvatar = 'student';
  bool _isLoading = false;
  bool _profileExists = false;
  bool _isHoveringAction = false;

  static const String _storageKey = 'academic_os_student_profile';

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  Future<void> _checkExistingProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (!mounted) return;
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final profile = StudentProfile.fromJson(decoded);
        if (profile.fullName.trim().isNotEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                taskUseCases: widget.taskUseCases,
                courseUseCases: widget.courseUseCases,
                authUseCases: widget.authUseCases,
                isDarkMode: widget.isDarkMode,
                isArabic: widget.isArabic,
                onThemeChanged: widget.onThemeChanged,
                onLanguageChanged: widget.onLanguageChanged,
              ),
            ),
          );
          return;
        }
      }
    }
    setState(() => _profileExists = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final profile = StudentProfile(
      fullName: _nameController.text.trim(),
      university: _universityController.text.trim(),
      major: _majorController.text.trim(),
      academicLevel: _levelController.text.trim(),
      targetGpa: _targetGpaController.text.trim(),
      avatar: _selectedAvatar,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(profile.toJson()));

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          taskUseCases: widget.taskUseCases,
          courseUseCases: widget.courseUseCases,
          authUseCases: widget.authUseCases,
          isDarkMode: widget.isDarkMode,
          isArabic: widget.isArabic,
          onThemeChanged: widget.onThemeChanged,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _levelController.dispose();
    _targetGpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return AcademicScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 560;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary.withOpacity(0.18),
                                  primary.withOpacity(0.06),
                                ],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: primary.withOpacity(0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primary,
                                        primary.withOpacity(0.75),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Academic OS',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontSize: 28,
                                              letterSpacing: 0.2,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'مرحباً بك في رحلتك الأكاديمية الرقمية',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: textColor.withOpacity(0.8),
                                              fontSize: 15,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: primary.withOpacity(0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إعداد ملفك الشخصي',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'أضف بياناتك الأساسية لإنشاء تجربة أكاديمية متكاملة ومرنة.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: textColor.withOpacity(0.72),
                                        height: 1.6,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Wrap(
                            spacing: isWide ? 18 : 0,
                            runSpacing: 18,
                            children: [
                              SizedBox(
                                width: isWide
                                    ? (constraints.maxWidth - 56) / 2
                                    : double.infinity,
                                child: _buildTextField(
                                  label: 'اسم الطالب',
                                  controller: _nameController,
                                  prefix: Icons.person_outline,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'يرجى إدخال الاسم'
                                          : null,
                                ),
                              ),
                              SizedBox(
                                width: isWide
                                    ? (constraints.maxWidth - 56) / 2
                                    : double.infinity,
                                child: _buildTextField(
                                  label: 'الجامعة / الكلية',
                                  controller: _universityController,
                                  prefix: Icons.school_outlined,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'يرجى إدخال الجامعة'
                                          : null,
                                ),
                              ),
                              SizedBox(
                                width: isWide
                                    ? (constraints.maxWidth - 56) / 2
                                    : double.infinity,
                                child: _buildTextField(
                                  label: 'التخصص الدراسي',
                                  controller: _majorController,
                                  prefix: Icons.menu_book_rounded,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'يرجى إدخال التخصص'
                                          : null,
                                ),
                              ),
                              SizedBox(
                                width: isWide
                                    ? (constraints.maxWidth - 56) / 2
                                    : double.infinity,
                                child: _buildTextField(
                                  label: 'المستوى الدراسي',
                                  controller: _levelController,
                                  prefix: Icons.analytics_outlined,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'يرجى إدخال المستوى'
                                          : null,
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: _buildTextField(
                                  label: 'المعدل المستهدف',
                                  controller: _targetGpaController,
                                  prefix: Icons.flag_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'يرجى إدخال المعدل المستهدف'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: primary.withOpacity(0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اختر صورتك الرمزية',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    ('student', '🎓'),
                                    ('laptop', '💻'),
                                    ('book', '📘'),
                                    ('rocket', '🚀'),
                                    ('brain', '🧠'),
                                    ('code', '🧑‍💻'),
                                  ].map((entry) {
                                    final key = entry.$1;
                                    final emoji = entry.$2;
                                    final selected = _selectedAvatar == key;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedAvatar = key),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? primary.withOpacity(0.12)
                                              : Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: selected
                                                ? primary
                                                : Colors.transparent,
                                            width: selected ? 1.5 : 0,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            emoji,
                                            style:
                                                const TextStyle(fontSize: 30),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) =>
                                setState(() => _isHoveringAction = true),
                            onExit: (_) =>
                                setState(() => _isHoveringAction = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: _isHoveringAction
                                    ? [
                                        BoxShadow(
                                          color: primary.withOpacity(0.25),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _saveProfile,
                                icon: const Icon(Icons.rocket_launch_rounded),
                                label: Text(
                                  _isLoading
                                      ? 'جاري التهيئة...'
                                      : 'ابدأ رحلتك الأكاديمية',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  minimumSize: const Size(double.infinity, 58),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? prefix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: prefix != null
            ? Icon(prefix, color: primary.withOpacity(0.9))
            : null,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: primary.withOpacity(0.12),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
