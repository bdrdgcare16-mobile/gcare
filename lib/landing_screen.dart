import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
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

  // Check if device supports biometrics and start authentication
  Future<void> _checkBiometricsAndAuthenticate() async {
    bool canAuthenticate = false;
    List<BiometricType> availableBiometrics = [];
    
    try {
      // Check if device supports biometric authentication
      canAuthenticate = await _localAuth.canCheckBiometrics;
      
      if (!canAuthenticate) {
        _showError('Biometric authentication not available');
        return;
      }

      // Get available biometric types
      availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        _showError('No biometric authentication methods available');
        return;
      }

      setState(() {
        _isAuthenticating = true;
        _statusMessage = 'Authenticating...';
      });

      // Try to authenticate with biometrics
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Only use biometrics, not device credentials
        ),
      );

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
