import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';

class AttendanceAuthScreen extends StatefulWidget {
  const AttendanceAuthScreen({super.key});

  @override
  State<AttendanceAuthScreen> createState() => _AttendanceAuthScreenState();
}

class _AttendanceAuthScreenState extends State<AttendanceAuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _status = 'Checking device capabilities...';

  @override
  void initState() {
    super.initState();
    _startAuth();
  }

  Future<void> _startAuth() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool supported = await _localAuth.isDeviceSupported();

      if (!canCheck && !supported) {
        if (mounted) Navigator.pop(context, false);
        return;
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      if (biometrics.isEmpty) {
        if (mounted) Navigator.pop(context, false);
        return;
      }

      setState(() {
        _isAuthenticating = true;
        _status = 'Awaiting biometric authentication...';
      });

      final isFace = biometrics.contains(BiometricType.face);
      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to check in',
        authMessages: [
          AndroidAuthMessages(
            signInTitle: isFace ? 'Face Authentication' : 'Fingerprint Authentication',
            cancelButton: 'Cancel',
            biometricHint: 'Verify your identity',
            biometricNotRecognized: isFace
                ? 'Face not recognized. Try again.'
                : 'Fingerprint not recognized. Try again.',
            biometricRequiredTitle: 'Biometric required',
            biometricSuccess: 'Authentication successful',
            goToSettingsButton: 'Settings',
            goToSettingsDescription: 'Enable biometrics in Settings.',
          ),
          const IOSAuthMessages(
            cancelButton: 'Cancel',
            goToSettingsButton: 'Settings',
            goToSettingsDescription: 'Enable biometrics in Settings.',
            lockOut: 'Biometric is locked. Try later.',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (!mounted) return;
      setState(() => _isAuthenticating = false);
      Navigator.pop(context, ok);
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _status = 'Authentication error';
      });
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (_isAuthenticating) const CircularProgressIndicator(),
            const SizedBox(height: 12),
            if (!_isAuthenticating)
              ElevatedButton.icon(
                onPressed: _startAuth,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
          ],
        ),
      ),
    );
  }
}
