import 'package:flutter/material.dart';

import '../../domain/usecases/auth_use_cases.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthUseCases authUseCases;
  final Future<void> Function() onLoginSuccess;
  final Future<void> Function()? onContinueAsGuest;

  const LoginScreen({
    super.key,
    required this.authUseCases,
    required this.onLoginSuccess,
    this.onContinueAsGuest,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithUsername() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.authUseCases.loginWithUsername.call(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      if (!success) {
        setState(() {
          _errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة.';
          _isLoading = false;
        });
        return;
      }

      await widget.onLoginSuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذّر إكمال تسجيل الدخول. حاول مرة أخرى.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.authUseCases.loginWithGoogle.call();
      if (!mounted) return;

      if (!success) {
        setState(() {
          _errorMessage = 'تعذّر تسجيل الدخول عبر Google. حاول مجدداً.';
          _isLoading = false;
        });
        return;
      }

      await widget.onLoginSuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'حدث خطأ أثناء الاتصال بـ Google. حاول لاحقاً.';
        _isLoading = false;
      });
    }
  }

  Future<void> _continueAsGuest() async {
    if (_isLoading || widget.onContinueAsGuest == null) return;
    setState(() => _isLoading = true);
    try {
      await widget.onContinueAsGuest!();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذّر المتابعة الآن. حاول مرة أخرى.';
        _isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.42),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withOpacity(isDark ? 0.16 : 0.07),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(21),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withOpacity(0.22),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'AcademicOS',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'مساحتك الأكاديمية، منظمة في مكان واحد',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.12 : 0.045),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'مرحباً بعودتك',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'سجّل الدخول للمتابعة إلى مساحتك الأكاديمية.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _usernameController,
                              enabled: !_isLoading,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                              decoration: _inputDecoration(
                                label: 'اسم المستخدم',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'أدخل اسم المستخدم';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _loginWithUsername(),
                              decoration: _inputDecoration(
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'إظهار كلمة المرور'
                                      : 'إخفاء كلمة المرور',
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(
                                            () => _obscurePassword = !_obscurePassword,
                                          ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'أدخل كلمة المرور';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.errorContainer.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: colors.onErrorContainer,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: colors.onErrorContainer,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _loginWithUsername,
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login_rounded, size: 20),
                                          SizedBox(width: 9),
                                          Text(
                                            'تسجيل الدخول',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _loginWithGoogle,
                              icon: const Icon(Icons.g_mobiledata_rounded, size: 25),
                              label: const Text('المتابعة باستخدام Google'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب؟',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => RegisterScreen(
                                          authUseCases: widget.authUseCases,
                                          onRegistrationSuccess:
                                              widget.onLoginSuccess,
                                        ),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'إنشاء حساب',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      if (widget.onContinueAsGuest != null) ...[
                        const SizedBox(height: 2),
                        TextButton(
                          onPressed: _isLoading ? null : _continueAsGuest,
                          child: const Text('المتابعة كزائر'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'بياناتك المحلية تبقى على هذا الجهاز.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
