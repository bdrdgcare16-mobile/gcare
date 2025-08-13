import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import '../services/direct_camera_service.dart';

class CameraTestButton extends StatefulWidget {
  const CameraTestButton({Key? key}) : super(key: key);

  @override
  State<CameraTestButton> createState() => _CameraTestButtonState();
}

class _CameraTestButtonState extends State<CameraTestButton> {
  final DirectCameraService _cameraService = DirectCameraService();
  bool _isLoading = false;
  bool _showCamera = false;
  String _status = 'Ready to test camera';

  @override
  void dispose() {
    _cameraService.forceDispose();
    super.dispose();
  }

  Future<void> _testCamera() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing camera...';
    });

    try {
      print('🎯 Testing camera...');
      
      // Force initialize camera
      final success = await _cameraService.forceInitialize();
      if (success) {
        print('✅ Camera test successful');
        setState(() {
          _showCamera = true;
          _status = 'Camera opened successfully!';
          _isLoading = false;
        });
      } else {
        print('❌ Camera test failed');
        setState(() {
          _status = 'Camera test failed. Check permissions.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Camera test error: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _takeTestPhoto() async {
    setState(() {
      _isLoading = true;
      _status = 'Taking test photo...';
    });

    try {
      final imageData = await _cameraService.forceTakePhoto();
      if (imageData != null) {
        setState(() {
          _status = 'Test photo taken! Size: ${imageData.length} bytes';
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Test photo taken! Size: ${imageData.length} bytes'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _status = 'Failed to take test photo';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error taking photo: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCamera) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Camera Test'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            // Camera Preview
            if (_cameraService.controller != null && _cameraService.isInitialized)
              SizedBox.expand(
                child: CameraPreview(_cameraService.controller!),
              )
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Opening Camera...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
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
                  // Close Button
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showCamera = false;
                        _status = 'Ready to test camera';
                      });
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  
                  // Take Photo Button
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _takeTestPhoto,
                    backgroundColor: Colors.blue,
                    child: _isLoading 
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Test Button
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testCamera,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Test Camera (Direct)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Status Text
        Text(
          _status,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 