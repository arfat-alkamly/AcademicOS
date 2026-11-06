import 'package:flutter/material.dart';
import '../../core/security/app_lock_service.dart';

class PinLockScreen extends StatefulWidget {
  final AppLockService appLockService;
  final Future<void> Function() onVerified;

  const PinLockScreen({
    super.key,
    required this.appLockService,
    required this.onVerified,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إدخال رمز PIN.';
        _isLoading = false;
      });
      return;
    }

    final success = await widget.appLockService.verifyPin(pin);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      await widget.onVerified();
      return;
    }

    setState(() {
      _errorMessage = 'رمز PIN غير صحيح. حاول مرة أخرى.';
    });
  }

  Future<void> _authenticateBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.appLockService.authenticateBiometric();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      await widget.onVerified();
      return;
    }

    setState(() {
      _errorMessage = 'فشل التحقق البيومتري. حاول مجدداً.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قفل التطبيق')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text('أدخل رمز PIN للوصول إلى التطبيق.'),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: 'PIN'),
              obscureText: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyPin,
              child: const Text('تأكيد PIN'),
            ),
            const SizedBox(height: 12),
            FutureBuilder<bool>(
              future: widget.appLockService.isBiometricEnabled(),
              builder: (context, snapshot) {
                final enabled = snapshot.data ?? false;
                if (!enabled) {
                  return const SizedBox.shrink();
                }
                return ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateBiometric,
                  child: const Text('فتح بالبصمة أو الوجه'),
                );
              },
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
