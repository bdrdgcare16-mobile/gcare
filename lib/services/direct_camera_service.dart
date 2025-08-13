import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class DirectCameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  List<CameraDescription>? get cameras => _cameras;

  // Force camera initialization
  Future<bool> forceInitialize() async {
    try {
      print('🔧 DirectCameraService: Force initializing camera...');
      
      // Force camera permission request
      print('🔧 Requesting camera permission...');
      final status = await Permission.camera.request();
      print('📱 Camera permission status: $status');
      
      if (status != PermissionStatus.granted) {
        print('❌ Camera permission denied. Status: $status');
        return false;
      }
      print('✅ Camera permission granted');

      // Get available cameras with error handling
      print('🔧 Getting available cameras...');
      try {
        _cameras = await availableCameras();
        print('📱 Found ${_cameras?.length ?? 0} cameras');
      } catch (e) {
        print('❌ Error getting cameras: $e');
        return false;
      }

      if (_cameras == null || _cameras!.isEmpty) {
        print('❌ No cameras available');
        return false;
      }

      // Select camera (prefer front camera)
      CameraDescription selectedCamera;
      try {
        selectedCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
        print('✅ Using front camera: ${selectedCamera.name}');
      } catch (e) {
        selectedCamera = _cameras!.first;
        print('⚠️ Front camera not found, using: ${selectedCamera.name}');
      }

      // Dispose any existing controller
      if (_controller != null) {
        print('🔧 Disposing existing controller...');
        await _controller!.dispose();
        _controller = null;
      }

      // Create new controller with specific settings
      print('🔧 Creating camera controller...');
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.yuv420 
          : ImageFormatGroup.bgra8888,
      );

      // Initialize with timeout
      print('🔧 Initializing camera controller...');
      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ Camera initialization timeout');
          throw Exception('Camera initialization timeout');
        },
      );

      _isInitialized = true;
      print('✅ Camera initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error in force initialization: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Take photo with error handling
  Future<Uint8List?> forceTakePhoto() async {
    try {
      if (_controller == null || !_isInitialized) {
        print('❌ Camera not ready for photo');
        return null;
      }

      print('📸 Taking photo...');
      
      // Take picture with timeout
      final image = await _controller!.takePicture().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('❌ Photo capture timeout');
          throw Exception('Photo capture timeout');
        },
      );
      
      print('📱 Image captured: ${image.path}');
      
      // Read file bytes
      final file = File(image.path);
      if (!await file.exists()) {
        print('❌ Image file does not exist');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      print('✅ Photo taken successfully: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      print('❌ Error taking photo: $e');
      return null;
    }
  }

  // Dispose resources
  Future<void> forceDispose() async {
    try {
      print('🔧 Force disposing camera...');
      if (_controller != null) {
        await _controller!.dispose();
      }
      _controller = null;
      _isInitialized = false;
      print('✅ Camera disposed successfully');
    } catch (e) {
      print('❌ Error disposing camera: $e');
    }
  }

  // Check if camera is ready
  bool get isReady => _controller != null && _isInitialized;

  // Get camera status
  String get status {
    if (!_isInitialized) return 'Not initialized';
    if (_controller == null) return 'No controller';
    return 'Ready';
  }
} 