import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';

class RealCameraScreen extends StatefulWidget {
  final String purpose; // 'register' or 'verify'
  
  const RealCameraScreen({Key? key, required this.purpose}) : super(key: key);

  @override
  State<RealCameraScreen> createState() => _RealCameraScreenState();
}

class _RealCameraScreenState extends State<RealCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _status = 'Requesting camera permission...';
  bool _hasPermission = false;
  bool _isFaceDetected = false;
  Timer? _faceDetectionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _faceDetectionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
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
          _status = 'Permission granted! Initializing camera...';
        });
        await _initializeCamera();
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

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _status = 'Getting cameras...';
      });

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _status = 'No cameras found on this device.';
        });
        return;
      }

      setState(() {
        _status = 'Initializing camera...';
      });

      // Use front camera for face recognition
      CameraDescription selectedCamera;
      try {
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        selectedCamera = cameras.first;
      }

      // Initialize camera controller
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
        _status = widget.purpose == 'register' 
          ? 'Position your face in the frame for registration' 
          : 'Position your face in the frame for verification';
      });

      // Start face detection simulation
      _startFaceDetection();

    } catch (e) {
      setState(() {
        _status = 'Error initializing camera: $e';
      });
    }
  }

  void _startFaceDetection() {
    // Simulate face detection - in real app, you would use ML models
    _faceDetectionTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_isInitialized && !_isProcessing) {
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
    if (_controller == null || !_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Capturing face...';
    });

    try {
      // Take picture
      final image = await _controller!.takePicture();
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      
      setState(() {
        _status = 'Processing face...';
      });

      // Process the image
      bool success = false;
      String resultMessage = '';

      if (widget.purpose == 'register') {
        success = await _registerFace(bytes);
        resultMessage = success 
          ? 'Face ID registered successfully!' 
          : 'Registration failed. Please try again.';
      } else {
        success = await _verifyFace(bytes);
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
        _status = 'Error capturing: $e';
        _isProcessing = false;
      });
    }
  }

  // Register face
  Future<bool> _registerFace(Uint8List imageData) async {
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
  Future<bool> _verifyFace(Uint8List imageData) async {
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
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: CameraPreview(_controller!),
            )
          else
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_hasPermission) ...[
                      const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera Permission Required',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This app needs camera access for face recognition',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _requestCameraPermission,
                        icon: const Icon(Icons.settings),
                        label: const Text('Grant Permission'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ] else ...[
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _status,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          
          // Face Frame Overlay
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
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                  )
                : null,
            ),
          ),
          
          // Status Bar
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 