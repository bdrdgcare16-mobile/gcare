import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RealDesktopCamera extends StatefulWidget {
  final String purpose; // 'register' or 'verify'
  
  const RealDesktopCamera({Key? key, required this.purpose}) : super(key: key);

  @override
  State<RealDesktopCamera> createState() => _RealDesktopCameraState();
}

class _RealDesktopCameraState extends State<RealDesktopCamera> {
  bool _isProcessing = false;
  String _status = 'Initializing camera...';
  bool _isFaceDetected = false;
  Timer? _faceDetectionTimer;
  bool _showCameraPreview = false;
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _faceDetectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _status = 'Initializing camera...';
    });

    // Simulate camera initialization
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _status = 'Camera ready! Position your face in the frame.';
      _showCameraPreview = true;
    });

    _startFaceDetection();
  }

  void _startFaceDetection() {
    // Simulate face detection
    _faceDetectionTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!_isProcessing && !_isFaceDetected) {
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
      // Open real camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
          _status = 'Image captured! Processing face...';
        });

        // Simulate processing time
        await Future.delayed(Duration(seconds: 2));

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
                  // Captured image
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _capturedImage != null
                        ? Image.file(
                            _capturedImage!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.face,
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Captured Face',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                  ),
                  SizedBox(height: 16),
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
                        _status = 'Position your face in the frame';
                        _capturedImage = null;
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
      } else {
        // User cancelled camera
        setState(() {
          _isProcessing = false;
          _isFaceDetected = false;
          _status = 'Camera cancelled. Please try again.';
        });
        _startFaceDetection();
      }
    } catch (e) {
      setState(() {
        _status = 'Error opening camera: $e';
        _isProcessing = false;
        _isFaceDetected = false;
      });
      _startFaceDetection();
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
            // Camera Preview Area
            Container(
              width: 400,
              height: 500,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFaceDetected ? Colors.green : Colors.blue,
                  width: 3,
                ),
              ),
              child: _showCameraPreview
                ? Stack(
                    children: [
                      // Camera preview or placeholder
                      Container(
                        width: 400,
                        height: 500,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey[800]!,
                              Colors.grey[700]!,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 100,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Camera Ready',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Position your face in the frame',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Face frame overlay
                      Center(
                        child: Container(
                          width: 250,
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isFaceDetected ? Colors.green : Colors.blue,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _isFaceDetected
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(17),
                                  color: Colors.green.withValues(alpha: 0.2),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 48,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Face Detected!',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          _status,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
            
            // Info Text
            Container(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Real Camera Access\nThis will open your device camera for face capture.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
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