import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_session.dart';
import '../services/simple_face_service.dart';
import '../providers/realtime_provider.dart';
import 'face_recognition_screen.dart';

class FinalProfileScreen extends StatefulWidget {
  const FinalProfileScreen({Key? key}) : super(key: key);

  @override
  State<FinalProfileScreen> createState() => _FinalProfileScreenState();
}

class _FinalProfileScreenState extends State<FinalProfileScreen> {
  final SimpleFaceService _faceService = SimpleFaceService();
  
  bool _isFaceRegistered = false;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFaceStatus();
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

  Future<void> _openCameraForRegistration() async {
    print('🎯 Opening camera for registration...');
    
    // Navigate to face recognition screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceRecognitionScreen(),
      ),
    );

    // Handle result if needed
    if (result != null) {
      print('✅ Camera returned with result');
      // You can handle the result here if needed
    }
  }

  Future<void> _openCameraForVerification() async {
    print('🎯 Opening camera for verification...');
    
    // Navigate to face recognition screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceRecognitionScreen(),
      ),
    );

    // Handle result if needed
    if (result != null) {
      print('✅ Camera returned with result');
      // You can handle the result here if needed
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
        title: const Text('Profile (Final)'),
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
      body: SingleChildScrollView(
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
                          'Face ID (Final)',
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
                          onPressed: _isLoading ? null : _openCameraForRegistration,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Open Camera for Face Registration'),
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
                              onPressed: _isLoading ? null : _openCameraForVerification,
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
      ),
    );
  }
} 