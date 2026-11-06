import 'package:flutter/material.dart';
import '../../core/platform/app_platform.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/security/auth_secure_storage_service.dart';
import '../../core/security/local_auth_service.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../../domain/usecases/course_use_cases.dart';
import '../../domain/usecases/task_use_cases.dart';
import 'pin_lock_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

class AuthGateScreen extends StatefulWidget {
  final AuthUseCases authUseCases;
  final TaskUseCases taskUseCases;
  final CourseUseCases courseUseCases;
  final bool isDarkMode;
  final bool isArabic;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;

  const AuthGateScreen({
    super.key,
    required this.authUseCases,
    required this.taskUseCases,
    required this.courseUseCases,
    required this.isDarkMode,
    required this.isArabic,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthSecureStorageService _secureStorageService =
      AuthSecureStorageService();
  final LocalAuthService _localAuthService = LocalAuthService();
  AppLockService? _appLockService;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isAppLocked = false;

  @override
  void initState() {
    super.initState();
    _appLockService = AppLockService(_secureStorageService, _localAuthService);
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final active = await widget.authUseCases.isLoggedIn.call();

      if (!AppPlatform.shouldUseNativeSecurity()) {
        setState(() {
          _isLoggedIn = active;
          _isAppLocked = false;
          _isLoading = false;
        });
        return;
      }

      if (active) {
        final locked = await _appLockService?.shouldLockApp() ?? false;
        setState(() {
          _isAppLocked = locked;
          _isLoggedIn = true;
          _isLoading = false;
        });
        return;
      }

      final cachedGoogle =
          await widget.authUseCases.loginWithCachedGoogleAccount.call();
      final locked = cachedGoogle
          ? (await _appLockService?.shouldLockApp() ?? false)
          : false;
      setState(() {
        _isLoggedIn = cachedGoogle;
        _isAppLocked = locked;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'AuthGateScreen._checkAuthentication error: $error\n$stackTrace',
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAppLockVerified() async {
    await _appLockService?.updateLastActive();
    if (!mounted) return;
    setState(() {
      _isAppLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn && _isAppLocked) {
      return PinLockScreen(
        appLockService: _appLockService!,
        onVerified: _handleAppLockVerified,
      );
    }

    if (_isLoggedIn) {
      return HomeScreen(
        taskUseCases: widget.taskUseCases,
        courseUseCases: widget.courseUseCases,
        isDarkMode: widget.isDarkMode,
        isArabic: widget.isArabic,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
        authUseCases: widget.authUseCases,
      );
    }

    return StudentProfileSetupScreen(
      taskUseCases: widget.taskUseCases,
      courseUseCases: widget.courseUseCases,
      authUseCases: widget.authUseCases,
      isDarkMode: widget.isDarkMode,
      isArabic: widget.isArabic,
      onThemeChanged: widget.onThemeChanged,
      onLanguageChanged: widget.onLanguageChanged,
    );
  }
}
