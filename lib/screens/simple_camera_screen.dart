import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleCameraScreen extends StatefulWidget {
  final String purpose; // 'register' or 'verify'
  
  const SimpleCameraScreen({Key? key, required this.purpose}) : super(key: key);

  @override
  State<SimpleCameraScreen> createState() => _SimpleCameraScreenState();
}

class _SimpleCameraScreenState extends State<SimpleCameraScreen> {
  bool _isProcessing = false;
  String _status = 'Ready';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Face ${widget.purpose.toUpperCase()}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera Placeholder
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue, width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Camera Simulator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap below to simulate\nface ${widget.purpose}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Status
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                _status,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Action Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _simulateFaceProcess,
              icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.camera_alt),
              label: Text(_isProcessing ? 'Processing...' : 'Simulate ${widget.purpose}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Info Text
            Container(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This is a demo version for submission.\nReal camera functionality will be implemented later.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulateFaceProcess() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing face...';
    });

    // Simulate processing time
    await Future.delayed(Duration(seconds: 2));

    try {
      bool success = false;
      String resultMessage = '';

      if (widget.purpose == 'register') {
        // Simulate face registration
        success = await _simulateRegisterFace();
        resultMessage = success 
          ? 'Face ID registered successfully!' 
          : 'Registration failed. Please try again.';
      } else {
        // Simulate face verification
        success = await _simulateVerifyFace();
        resultMessage = success 
          ? 'Face verification successful!' 
          : 'Face verification failed. Please try again.';
      }

      setState(() {
        _status = resultMessage;
        _isProcessing = false;
      });

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(success ? 'Success!' : 'Failed'),
            content: Text(resultMessage),
            backgroundColor: success ? Colors.green[50] : Colors.red[50],
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  if (success) {
                    Navigator.pop(context, success); // Return to previous screen
                  }
                },
                child: Text(success ? 'OK' : 'Try Again'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  // Simulate face registration
  Future<bool> _simulateRegisterFace() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('face_id_registered', timestamp);
      await prefs.setBool('face_registered', true);
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  // Simulate face verification
  Future<bool> _simulateVerifyFace() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool('face_registered') ?? false;
      return isRegistered;
    } catch (e) {
      print('Verification error: $e');
      return false;
    }
  }
} 