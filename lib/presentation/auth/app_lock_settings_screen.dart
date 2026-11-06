import 'package:flutter/material.dart';
import '../../core/security/app_lock_service.dart';

class AppLockSettingsScreen extends StatefulWidget {
  final AppLockService appLockService;

  const AppLockSettingsScreen({super.key, required this.appLockService});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  bool _biometricEnabled = false;
  bool _isPinSet = false;
  int _lockTimeout = 5;
  final TextEditingController _pinController = TextEditingController();
  bool _isSettingPin = false;
  bool _isDeletingPin = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final enabled = await widget.appLockService.isBiometricEnabled();
    final pinSet = await widget.appLockService.isPinSet();
    final timeout = await widget.appLockService.getLockTimeout();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
      _isPinSet = pinSet;
      _lockTimeout = timeout;
    });
  }

  Future<void> _setPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _message = 'يجب أن يتكون PIN من 4 أرقام أو أكثر.';
      });
      return;
    }

    setState(() {
      _isSettingPin = true;
      _message = null;
    });

    await widget.appLockService.setPin(pin);
    if (!mounted) return;
    setState(() {
      _isSettingPin = false;
      _isPinSet = true;
      _message = 'تم إعداد PIN بنجاح.';
      _pinController.clear();
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value && !await widget.appLockService.isBiometricAvailable()) {
      if (!mounted) return;
      setState(() {
        _message = 'المصادقة البيومترية غير متاحة على هذا الجهاز.';
      });
      return;
    }

    await widget.appLockService.enableBiometric(value);
    if (!mounted) return;
    setState(() {
      _biometricEnabled = value;
      _message = value
          ? 'تم تفعيل المصادقة البيومترية.'
          : 'تم تعطيل المصادقة البيومترية.';
    });
  }

  Future<void> _deletePin() async {
    setState(() {
      _isDeletingPin = true;
      _message = null;
    });

    await widget.appLockService.removePin();
    if (!mounted) return;
    setState(() {
      _isDeletingPin = false;
      _isPinSet = false;
      _biometricEnabled = false;
      _message = 'تم حذف PIN وتعطيل المصادقة البيومترية.';
    });
  }

  Future<void> _setLockTimeout(int minutes) async {
    await widget.appLockService.setLockTimeout(minutes);
    if (!mounted) return;
    setState(() {
      _lockTimeout = minutes;
      _message = 'تم حفظ مهلة القفل بنجاح.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات قفل التطبيق')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isPinSet
                  ? 'PIN مفعل حالياً لحماية التطبيق.'
                  : 'لا يوجد PIN مفعل حالياً.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: _isPinSet
                    ? 'أدخل PIN جديد لتحديثه'
                    : 'أدخل PIN جديد',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSettingPin ? null : _setPin,
              child: Text(_isPinSet ? 'تحديث PIN' : 'إعداد PIN'),
            ),
            const SizedBox(height: 20),
            if (_isPinSet)
              ElevatedButton(
                onPressed: _isDeletingPin ? null : _deletePin,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('حذف PIN'),
              ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('تفعيل المصادقة البيومترية'),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: _lockTimeout,
              decoration: const InputDecoration(
                labelText: 'مهلة القفل (دقائق)',
              ),
              items: [5, 10, 15, 30]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text('$value دقائق'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _setLockTimeout(value);
                }
              },
            ),
            if (_message != null) ...[
              const SizedBox(height: 24),
              Text(_message!, style: const TextStyle(color: Colors.green)),
            ],
          ],
        ),
      ),
    );
  }
}
