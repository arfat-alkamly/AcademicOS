import 'package:flutter/material.dart';
import '../../domain/usecases/auth_use_cases.dart';

class RegisterScreen extends StatefulWidget {
  final AuthUseCases authUseCases;
  final Future<void> Function() onRegistrationSuccess;

  const RegisterScreen({
    super.key,
    required this.authUseCases,
    required this.onRegistrationSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final email = _emailController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى تعبئة جميع الحقول الأساسية.';
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'كلمة المرور وتأكيدها غير متطابقين.';
        _isLoading = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'يجب أن تكون كلمة المرور 6 أحرف على الأقل.';
        _isLoading = false;
      });
      return;
    }

    final success = await widget.authUseCases.registerLocalUser.call(
      username,
      password,
      email: email.isEmpty ? null : email,
      displayName: displayName.isEmpty ? null : displayName,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التسجيل. يرجى المحاولة مرة أخرى.';
        _isLoading = false;
      });
      return;
    }

    final loginSuccessful = await widget.authUseCases.loginWithUsername.call(
      username,
      password,
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (loginSuccessful) {
      await widget.onRegistrationSuccess();
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _errorMessage =
          'تم التسجيل، لكن فشل تسجيل الدخول تلقائياً. حاول تسجيل الدخول يدوياً.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل حساب جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'اسم المستخدم'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني (اختياري)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الظاهر (اختياري)',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: const Text('إنشاء حساب'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
