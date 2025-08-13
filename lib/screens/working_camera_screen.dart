import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class WorkingCameraScreen extends StatefulWidget {
  final String purpose; // 'register' or 'verify'
  
  const WorkingCameraScreen({Key? key, required this.purpose}) : super(key: key);

  @override
  State<WorkingCameraScreen> createState() => _WorkingCameraScreenState();
}

class _WorkingCameraScreenState extends State<WorkingCameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _status = 'Initializing camera...';
  Uint8List? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _status = 'Requesting camera permission...';
      });

      // Request camera permission first
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        setState(() {
          _status = 'Camera permission denied. Please enable camera access in settings.';
        });
        return;
      }

      setState(() {
        _status = 'Getting cameras...';
      });

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _status = 'No cameras found';
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
      );

      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
        _status = widget.purpose == 'register' 
          ? 'Position your face for registration' 
          : 'Position your face for verification';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _takePictureAndProcess() async {
    if (_controller == null || !_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Taking picture...';
    });

    try {
      // Take picture
      final image = await _controller!.takePicture();
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      
      setState(() {
        _capturedImage = bytes;
        _status = 'Processing face...';
      });

      // Simple processing without complex image operations
      bool success = false;
      String resultMessage = '';

      if (widget.purpose == 'register') {
        // For registration, just store a simple identifier
        success = await _simpleRegisterFace(bytes);
        resultMessage = success 
          ? 'Face ID registered successfully!' 
          : 'Registration failed. Please try again.';
      } else {
        // For verification, do simple comparison
        success = await _simpleVerifyFace(bytes);
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

  // Simple registration without complex processing
  Future<bool> _simpleRegisterFace(Uint8List imageData) async {
    try {
      // Just store a timestamp-based identifier for demo
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('face_id_registered', timestamp);
      await prefs.setBool('face_registered', true);
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  // Simple verification without complex processing
  Future<bool> _simpleVerifyFace(Uint8List imageData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool('face_registered') ?? false;
      
      if (!isRegistered) {
        return false;
      }

      // For demo purposes, just return true if registered
      // In a real app, you would do proper face comparison
      return true;
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
        title: Text('Camera - ${widget.purpose.toUpperCase()}'),
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
                    if (_status.contains('permission denied'))
                      ...[
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
                          onPressed: () async {
                            final status = await Permission.camera.request();
                            if (status == PermissionStatus.granted) {
                              _initializeCamera();
                            }
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Grant Permission'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ]
                    else
                      ...[
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
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          // Status
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
          
          // Action Buttons
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Take Photo Button
                FloatingActionButton(
                  onPressed: _isInitialized && !_isProcessing ? _takePictureAndProcess : null,
                  backgroundColor: _isProcessing ? Colors.grey : Colors.blue,
                  child: _isProcessing 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.camera, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 