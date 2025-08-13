import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import '../services/user_session.dart';
import '../services/simple_face_service.dart';
import '../services/simple_camera_service.dart';
import '../providers/realtime_provider.dart';

class SimpleProfileScreen extends StatefulWidget {
  const SimpleProfileScreen({Key? key}) : super(key: key);

  @override
  State<SimpleProfileScreen> createState() => _SimpleProfileScreenState();
}

class _SimpleProfileScreenState extends State<SimpleProfileScreen> {
  final SimpleFaceService _faceService = SimpleFaceService();
  final SimpleCameraService _cameraService = SimpleCameraService();
  
  bool _isFaceRegistered = false;
  bool _isLoading = false;
  bool _showCamera = false;
  String _statusMessage = '';
  Uint8List? _capturedImage;

  @override
  void initState() {
    super.initState();
    _loadFaceStatus();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _loadFaceStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simple status check - in real app this would check stored data
      setState(() {
        _isFaceRegistered = false; // Default to false for demo
        _statusMessage = 'Face ID not registered';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading face ID status';
        _isLoading = false;
      });
    }
  }

  Future<void> _registerFaceID() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing camera...';
    });

    try {
      print('🎯 Starting face registration...');
      
      // Initialize camera
      final cameraInitialized = await _cameraService.initialize();
      if (!cameraInitialized) {
        print('❌ Camera initialization failed');
        setState(() {
          _statusMessage = 'Failed to initialize camera. Please check permissions.';
          _isLoading = false;
        });
        return;
      }

      print('✅ Camera initialized, showing camera view');
      setState(() {
        _showCamera = true;
        _statusMessage = 'Position your face in the camera frame';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error in registration: $e');
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _captureAndRegister() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Capturing image...';
    });

    try {
      print('📸 Capturing photo for registration...');
      
      // Take photo
      final imageData = await _cameraService.takePhoto();
      if (imageData == null) {
        print('❌ Failed to capture image');
        setState(() {
          _statusMessage = 'Failed to capture image';
          _isLoading = false;
        });
        return;
      }

      print('✅ Image captured, processing face...');
      setState(() {
        _capturedImage = imageData;
        _statusMessage = 'Processing face...';
      });

      // Register face - using simple service
      final success = await _faceService.registerFaceFromBytes('user@example.com', imageData);
      
      if (success) {
        print('✅ Face registration successful');
        setState(() {
          _isFaceRegistered = true;
          _statusMessage = 'Face ID registered successfully!';
          _showCamera = false;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face ID registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ Face registration failed');
        setState(() {
          _statusMessage = 'No face detected. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error in capture and register: $e');
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyFaceID() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing camera for verification...';
    });

    try {
      print('🎯 Starting face verification...');
      
      // Initialize camera
      final cameraInitialized = await _cameraService.initialize();
      if (!cameraInitialized) {
        print('❌ Camera initialization failed for verification');
        setState(() {
          _statusMessage = 'Failed to initialize camera. Please check permissions.';
          _isLoading = false;
        });
        return;
      }

      print('✅ Camera initialized for verification');
      setState(() {
        _showCamera = true;
        _statusMessage = 'Position your face for verification';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error in verification: $e');
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _captureAndVerify() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verifying face...';
    });

    try {
      print('📸 Capturing photo for verification...');
      
      // Take photo
      final imageData = await _cameraService.takePhoto();
      if (imageData == null) {
        print('❌ Failed to capture image for verification');
        setState(() {
          _statusMessage = 'Failed to capture image';
          _isLoading = false;
        });
        return;
      }

      print('✅ Image captured for verification');
      // Verify face - using simple service
      final success = await _faceService.recognizeFaceFromBytes(imageData);
      
      if (success != null) {
        print('✅ Face verification successful');
        setState(() {
          _statusMessage = 'Face verification successful!';
          _showCamera = false;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face verification successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ Face verification failed');
        setState(() {
          _statusMessage = 'Face verification failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error in capture and verify: $e');
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFaceID() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Face ID'),
        content: const Text('Are you sure you want to delete your registered Face ID?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Deleting Face ID...';
      });

      try {
        final success = await _faceService.deleteFace();
        if (success) {
          setState(() {
            _isFaceRegistered = false;
            _statusMessage = 'Face ID deleted successfully';
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Face ID deleted successfully'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          setState(() {
            _statusMessage = 'Failed to delete Face ID';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _statusMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile (Simple)'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          Consumer<RealtimeProvider>(
            builder: (context, realtimeProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(
                      realtimeProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                      color: realtimeProvider.isConnected ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      realtimeProvider.isConnected ? 'Live' : 'Offline',
                      style: TextStyle(
                        color: realtimeProvider.isConnected ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _showCamera ? _buildCameraView() : _buildProfileView(user),
    );
  }

  Widget _buildProfileView(Map<String, dynamic>? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['name'] ?? 'User Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?['email'] ?? 'user@example.com',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user?['role'] ?? 'EMPLOYEE',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Face ID Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.face,
                        color: _isFaceRegistered ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Face ID (Simple)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isFaceRegistered ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isFaceRegistered ? Colors.green[200]! : Colors.orange[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isFaceRegistered ? Icons.check_circle : Icons.warning,
                          color: _isFaceRegistered ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: _isFaceRegistered ? Colors.green[700] : Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  if (!_isFaceRegistered) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _registerFaceID,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Register Face ID (Simple)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _verifyFaceID,
                            icon: const Icon(Icons.verified_user),
                            label: const Text('Verify Face'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _deleteFaceID,
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await UserSession.instance.clearUserSession();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Scaffold(
      backgroundColor: Colors.black,
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
                      'Initializing Camera...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
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
          
          // Instructions
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
                // Cancel Button
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _showCamera = false;
                      _isLoading = false;
                      _statusMessage = '';
                    });
                  },
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                
                // Capture Button
                FloatingActionButton(
                  onPressed: _isLoading ? null : (_isFaceRegistered ? _captureAndVerify : _captureAndRegister),
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
} 