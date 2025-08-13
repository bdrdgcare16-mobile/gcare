import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class WorkingCameraFinal extends StatefulWidget {
  final String purpose; // 'register' or 'verify'
  
  const WorkingCameraFinal({Key? key, required this.purpose}) : super(key: key);

  @override
  State<WorkingCameraFinal> createState() => _WorkingCameraFinalState();
}

class _WorkingCameraFinalState extends State<WorkingCameraFinal> {
  bool _isProcessing = false;
  String _status = 'Ready to capture';
  File? _capturedImage;

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
            // Image Display Area
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue, width: 3),
              ),
              child: _capturedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.file(
                      _capturedImage!,
                      fit: BoxFit.cover,
                      width: 300,
                      height: 400,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Camera Ready',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tap below to capture\nface for ${widget.purpose}',
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
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Capture Button
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _captureImage,
                  icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.camera_alt),
                  label: Text(_isProcessing ? 'Processing...' : 'Capture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                
                // Process Button (only show if image captured)
                if (_capturedImage != null)
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processFace,
                    icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.check),
                    label: Text(_isProcessing ? 'Processing...' : 'Process'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Retake Button (only show if image captured)
            if (_capturedImage != null)
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _retakeImage,
                icon: Icon(Icons.refresh),
                label: Text('Retake'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _status = 'Opening camera...';
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
          _status = 'Image captured! Tap Process to continue.';
          _isProcessing = false;
        });
      } else {
        setState(() {
          _status = 'No image captured';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processFace() async {
    if (_capturedImage == null) return;

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
        success = await _registerFace();
        resultMessage = success 
          ? 'Face ID registered successfully!' 
          : 'Registration failed. Please try again.';
      } else {
        // Simulate face verification
        success = await _verifyFace();
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

  void _retakeImage() {
    setState(() {
      _capturedImage = null;
      _status = 'Ready to capture';
    });
  }

  // Simulate face registration
  Future<bool> _registerFace() async {
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
  Future<bool> _verifyFace() async {
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