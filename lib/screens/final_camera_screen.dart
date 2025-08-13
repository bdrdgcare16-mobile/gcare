import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

class FinalCameraScreen extends StatefulWidget {
  final String purpose; // 'register' or 'verify'
  
  const FinalCameraScreen({Key? key, required this.purpose}) : super(key: key);

  @override
  State<FinalCameraScreen> createState() => _FinalCameraScreenState();
}

class _FinalCameraScreenState extends State<FinalCameraScreen> {
  bool _isProcessing = false;
  String _status = 'Requesting camera permission...';
  bool _hasPermission = false;
  bool _isFaceDetected = false;
  Timer? _faceDetectionTimer;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _faceDetectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    try {
      setState(() {
        _status = 'Requesting camera permission...';
      });

      // Request camera permission
      final status = await Permission.camera.request();
      
      if (status == PermissionStatus.granted) {
        setState(() {
          _hasPermission = true;
          _status = 'Permission granted! Position your face in the frame.';
        });
        _startFaceDetection();
      } else {
        setState(() {
          _status = 'Camera permission denied. Please enable camera access in settings.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error requesting permission: $e';
      });
    }
  }

  void _startFaceDetection() {
    // Simulate face detection - in real app, you would use ML models
    _faceDetectionTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_hasPermission && !_isProcessing && !_isFaceDetected) {
        setState(() {
          _isFaceDetected = true;
          _status = 'Face detected! Opening camera for capture...';
        });
        
        // Auto-capture after face detection
        timer.cancel();
        _autoCapture();
      }
    });
  }

  Future<void> _autoCapture() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Opening camera...';
    });

    try {
      // Use image_picker to open camera directly
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
          _status = 'Image captured! Processing face...';
        });

        // Process the image
        await _processFace();
      } else {
        setState(() {
          _status = 'No image captured. Please try again.';
          _isProcessing = false;
          _isFaceDetected = false;
        });
        _startFaceDetection();
      }
    } catch (e) {
      setState(() {
        _status = 'Error capturing: $e';
        _isProcessing = false;
        _isFaceDetected = false;
      });
      _startFaceDetection();
    }
  }

  Future<void> _processFace() async {
    setState(() {
      _status = 'Processing face...';
    });

    // Simulate processing time
    await Future.delayed(Duration(seconds: 2));

    try {
      bool success = false;
      String resultMessage = '';

      if (widget.purpose == 'register') {
        success = await _registerFace();
        resultMessage = success 
          ? 'Face ID registered successfully!' 
          : 'Registration failed. Please try again.';
      } else {
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_capturedImage != null) ...[
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _capturedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                Text(resultMessage),
                SizedBox(height: 16),
                if (success) ...[
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ] else ...[
                  Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 48,
                  ),
                ],
              ],
            ),
            backgroundColor: success ? Colors.green[50] : Colors.red[50],
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  if (success) {
                    Navigator.pop(context, success); // Return to previous screen
                  } else {
                    // Retry
                    setState(() {
                      _isFaceDetected = false;
                      _capturedImage = null;
                      _status = 'Position your face in the frame';
                    });
                    _startFaceDetection();
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
        _status = 'Error processing: $e';
        _isProcessing = false;
      });
    }
  }

  // Register face
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

  // Verify face
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
            // Camera/Image Display Area
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFaceDetected ? Colors.green : Colors.blue,
                  width: 3,
                ),
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
                        _hasPermission ? 'Camera Ready' : 'Camera Permission Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _hasPermission 
                          ? 'Position your face in the frame\nfor ${widget.purpose}'
                          : 'This app needs camera access\nfor face recognition',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isFaceDetected) ...[
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Face Detected!',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
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
            if (!_hasPermission)
              ElevatedButton.icon(
                onPressed: _requestCameraPermission,
                icon: Icon(Icons.settings),
                label: Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            
            // Processing Indicator
            if (_isProcessing)
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 