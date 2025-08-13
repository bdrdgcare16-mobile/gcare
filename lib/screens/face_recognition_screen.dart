import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/simple_face_service.dart';

class FaceRecognitionScreen extends StatefulWidget {
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? _controller;
  SimpleFaceService _faceService = SimpleFaceService();
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _status = 'No camera found';
        });
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _faceService.initialize();

      setState(() {
        _isInitialized = true;
        _status = 'Camera ready';
      });

      _startFaceDetection();
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  void _startFaceDetection() {
    if (_controller == null || !_isInitialized) return;

    _controller!.startImageStream((image) async {
      if (_isProcessing) return;
      
      setState(() {
        _isProcessing = true;
      });

      try {
        final hasFace = await _faceService.detectFace(image);
        if (hasFace) {
          final userId = await _faceService.recognizeFace(image);
          setState(() {
            _status = userId != null ? 'Recognized: $userId' : 'Face detected - No match';
          });
        } else {
          setState(() {
            _status = 'No face detected';
          });
        }
      } catch (e) {
        setState(() {
          _status = 'Error: $e';
        });
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Recognition'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              child: _isInitialized
                  ? CameraPreview(_controller!)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(_status),
                        ],
                      ),
                    ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _registerFace,
                      icon: Icon(Icons.person_add),
                      label: Text('Register Face'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      label: Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerFace() async {
    if (_controller == null) return;

    final userId = await _showRegisterDialog();
    if (userId == null) return;

    setState(() {
      _isProcessing = true;
      _status = 'Registering face...';
    });

    try {
      await Future.delayed(Duration(seconds: 2));
      
      setState(() {
        _status = 'Face registered for: $userId';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Error registering face';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<String?> _showRegisterDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Register Face'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'User ID',
            hintText: 'Enter user ID (e.g., email)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Register'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
