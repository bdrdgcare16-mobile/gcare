import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';

class MobileCameraScreen extends StatefulWidget {
  final String purpose; // 'register' or 'verify'
  
  const MobileCameraScreen({Key? key, required this.purpose}) : super(key: key);

  @override
  State<MobileCameraScreen> createState() => _MobileCameraScreenState();
}

class _MobileCameraScreenState extends State<MobileCameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _status = 'Initializing camera...';
  bool _isFaceDetected = false;
  Timer? _faceDetectionTimer;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _status = 'Requesting camera permission...';
    });

    // Request camera permission
    final status = await Permission.camera.request();
    
    if (status.isDenied) {
      setState(() {
        _status = 'Camera permission denied. Please grant permission to continue.';
      });
      return;
    }

    setState(() {
      _status = 'Initializing camera...';
    });

    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _status = 'No camera found on device.';
        });
        return;
      }

      // Use front camera for face detection
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Initialize camera controller
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _status = 'Camera ready! Position your face in the frame.';
        });

        _startFaceDetection();
      }
    } catch (e) {
      setState(() {
        _status = 'Error initializing camera: $e';
      });
    }
  }

  void _startFaceDetection() {
    // Simulate face detection
    _faceDetectionTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isProcessing && !_isFaceDetected && _isInitialized) {
        setState(() {
          _isFaceDetected = true;
          _status = 'Face detected! Capturing automatically...';
        });
        
        // Auto-capture after face detection
        timer.cancel();
        _autoCapture();
      }
    });
  }

  Future<void> _autoCapture() async {
    if (_isProcessing || !_isInitialized) return;

    setState(() {
      _isProcessing = true;
      _status = 'Capturing face...';
    });

    try {
      // Capture image
      final image = await _controller!.takePicture();
      
      setState(() {
        _capturedImage = image;
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
                          File(_capturedImage!.path),
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
    } catch (e) {
      setState(() {
        _status = 'Error capturing image: $e';
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
              child: _isInitialized && _controller != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Stack(
                      children: [
                        // Camera preview
                        CameraPreview(_controller!),
                        
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
                    ),
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
                'Mobile Camera Access\nThis uses your device camera for face capture.',
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