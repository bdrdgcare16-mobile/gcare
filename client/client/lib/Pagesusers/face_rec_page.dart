import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceRecPage extends StatefulWidget {
  final VoidCallback onFaceDetected;
  const FaceRecPage({super.key, required this.onFaceDetected});

  @override
  _FaceRecPageState createState() => _FaceRecPageState();
}

class _FaceRecPageState extends State<FaceRecPage> {
  late CameraController _controller;
  bool isCameraReady = false;
  bool faceDetected = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print("No cameras found on device.");
      return;
    }

    _controller = CameraController(cameras[1], ResolutionPreset.medium);
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() {
        isCameraReady = true;
      });
    } catch (e) {
      print("Camera init error: $e");
    }
  }

  Future<void> _captureAndDetect() async {
    if (!_controller.value.isInitialized) return;

    try {
      final image = await _controller.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faceDetector = GoogleMlKit.vision.faceDetector();
      final faces = await faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isNotEmpty) {
        setState(() => faceDetected = true);
        widget.onFaceDetected();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => faceDetected = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ No Face Detected")),
          );
        }
      }
    } catch (e) {
      print("Face detection error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Face Detection")),
      body: isCameraReady
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: CameraPreview(_controller),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _captureAndDetect,
                  child: Text("Capture & Detect Face"),
                ),
                SizedBox(height: 12),
                if (faceDetected)
                  Text("✅ Face Detected", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}