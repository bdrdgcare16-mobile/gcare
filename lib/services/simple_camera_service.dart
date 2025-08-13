import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class SimpleCameraService {
  static final SimpleCameraService _instance = SimpleCameraService._internal();
  factory SimpleCameraService() => _instance;
  SimpleCameraService._internal();

  CameraController? controller;
  bool _isInitialized = false;

  /// Initialize the camera service
  Future<bool> initialize() async {
    if (kDebugMode) {
      print('Initializing Simple Camera Service...');
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (kDebugMode) {
          print('No cameras found');
        }
        return false;
      }

      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller!.initialize();
      _isInitialized = true;

      if (kDebugMode) {
        print('Camera initialized successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing camera: $e');
      }
      return false;
    }
  }

  /// Take a photo
  Future<Uint8List?> takePhoto() async {
    if (kDebugMode) {
      print('Taking photo...');
    }

    try {
      if (controller == null || !_isInitialized) {
        if (kDebugMode) {
          print('Camera not initialized');
        }
        return null;
      }

      final image = await controller!.takePicture();
      final bytes = await image.readAsBytes();

      if (kDebugMode) {
        print('Photo taken successfully');
      }
      return bytes;
    } catch (e) {
      if (kDebugMode) {
        print('Error taking photo: $e');
      }
      return null;
    }
  }

  /// Stop camera preview
  Future<void> stopPreview() async {
    if (kDebugMode) {
      print('Stopping camera preview...');
    }

    try {
      if (controller != null && _isInitialized) {
        await controller!.stopImageStream();
        if (kDebugMode) {
          print('Camera preview stopped');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping camera preview: $e');
      }
    }
  }

  /// Dispose the camera service
  void dispose() {
    if (kDebugMode) {
      print('Disposing camera service...');
    }

    try {
      controller?.dispose();
      _isInitialized = false;
      if (kDebugMode) {
        print('Camera service disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing camera service: $e');
      }
    }
  }

  bool get isInitialized => _isInitialized;
} 