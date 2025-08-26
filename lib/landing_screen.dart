import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:flutter/services.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _statusMessage = 'Checking device capabilities...';

  @override
  void initState() {
    super.initState();
    _checkBiometricsAndAuthenticate();
  }

  // Check if device supports biometric authentication
  Future<void> _checkBiometricsAndAuthenticate() async {
    bool canAuthenticate = false;
    List<BiometricType> availableBiometrics = [];
    
    try {
      // Check if biometric authentication is available
      canAuthenticate = await _localAuth.canCheckBiometrics || 
          await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        _showError('Biometric authentication not available on this device');
        return;
      }

      // Get available biometric types
      availableBiometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('Available biometrics: $availableBiometrics');
      
      if (availableBiometrics.isEmpty) {
        _showError('No biometric authentication methods enrolled. Please set up face authentication in device settings.');
        return;
      }
      
      // Check specifically for face authentication
      final hasFaceAuth = availableBiometrics.contains(BiometricType.face);
      debugPrint('Face authentication available: $hasFaceAuth');

      if (!hasFaceAuth) {
        _showError('Face authentication is not available on this device');
        return;
      }

      setState(() {
        _isAuthenticating = true;
        _statusMessage = 'Looking for face...';
      });

      // Android-specific configuration
      final androidAuthStrings = AndroidAuthMessages(
        signInTitle: 'Face Authentication',
        cancelButton: 'Cancel',
        biometricHint: 'Verify your identity',
        biometricNotRecognized: 'Face not recognized. Try again.',
        biometricRequiredTitle: 'Biometric required',
        biometricSuccess: 'Authentication successful!',
        goToSettingsButton: 'Settings',
        goToSettingsDescription: 'Please set up face authentication',
      );

      // Try to authenticate with biometrics
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate with Face ID to continue',
        authMessages: [
          androidAuthStrings,
          const IOSAuthMessages(
            cancelButton: 'Cancel',
            goToSettingsButton: 'Settings',
            goToSettingsDescription: 'Please enable Face ID',
            lockOut: 'Face ID is locked. Please try again later.',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      // Handle authentication result
      if (didAuthenticate) {
        setState(() {
          _isAuthenticating = true;
          _statusMessage = 'Authenticated';
        });
        // Navigate to admin dashboard on success
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/admin-dashboard');
        }
      } else {
        _showError('Authentication failed');
      }
    } on PlatformException catch (e) {
      _showError('Authentication error: ${e.message}');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    setState(() {
      _statusMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            const Icon(
              Icons.fingerprint,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            // Authentication status message
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Loading indicator when authenticating
            if (_isAuthenticating)
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            // Retry button in case of failure
            if (!_isAuthenticating && _statusMessage != 'Authenticating...')
              ElevatedButton.icon(
                onPressed: _checkBiometricsAndAuthenticate,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
          ],
        ),
      ),
    );
  }
}
