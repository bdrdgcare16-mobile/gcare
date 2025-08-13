import 'package:flutter/material.dart';
import 'simple_camera_screen.dart';

class SimpleCameraTest extends StatelessWidget {
  const SimpleCameraTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Test Registration Camera
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SimpleCameraScreen(purpose: 'register'),
              ),
            );
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('Test Camera for Registration'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Test Verification Camera
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SimpleCameraScreen(purpose: 'verify'),
              ),
            );
          },
          icon: const Icon(Icons.verified_user),
          label: const Text('Test Camera for Verification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Info Text
        Text(
          'This will open camera in a new screen',
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