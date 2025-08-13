import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  // Get camera controller
  CameraController? get controller => _controller;
  
  // Check if camera is initialized
  bool get isInitialized => _isInitialized;
  
  // Get available cameras
  List<CameraDescription>? get cameras => _cameras;

  // Initialize camera
  Future<bool> initialize() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        print('❌ Camera permission denied');
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        print('❌ No cameras available');
        return false;
      }

      // Use front camera for face recognition
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Initialize camera controller
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.yuv420 
          : ImageFormatGroup.bgra8888,
      );

      // Initialize camera
      await _controller!.initialize();
      _isInitialized = true;
      
      print('✅ Camera initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing camera: $e');
      return false;
    }
  }

  // Start camera preview
  Future<void> startPreview() async {
    try {
      if (_controller != null && _isInitialized) {
        // For face recognition, we don't need image stream
        // Just ensure camera is ready for capture
        print('✅ Camera preview ready');
      }
    } catch (e) {
      print('❌ Error starting camera preview: $e');
    }
  }

  // Stop camera preview
  Future<void> stopPreview() async {
    try {
      if (_controller != null) {
        // Stop image stream if it's running
        try {
          await _controller!.stopImageStream();
        } catch (e) {
          // Image stream might not be running, that's okay
        }
        print('✅ Camera preview stopped');
      }
    } catch (e) {
      print('❌ Error stopping camera preview: $e');
    }
  }

  // Take a photo
  Future<Uint8List?> takePhoto() async {
    try {
      if (_controller == null || !_isInitialized) {
        print('❌ Camera not initialized');
        return null;
      }

      final image = await _controller!.takePicture();
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      
      print('✅ Photo taken successfully');
      return bytes;
    } catch (e) {
      print('❌ Error taking photo: $e');
      return null;
    }
  }

  // Save photo to gallery
  Future<String?> savePhotoToGallery(Uint8List imageData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'face_id_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(imageData);
      
      print('✅ Photo saved to: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error saving photo: $e');
      return null;
    }
  }

  // Dispose camera resources
  Future<void> dispose() async {
    try {
      await stopPreview();
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      print('✅ Camera disposed successfully');
    } catch (e) {
      print('❌ Error disposing camera: $e');
    }
  }

  // Check camera permission
  Future<bool> checkPermission() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.granted;
  }

  // Request camera permission
  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }
} 