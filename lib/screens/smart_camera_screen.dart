import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'mobile_camera_screen.dart';
import 'real_desktop_camera.dart';

class SmartCameraScreen extends StatelessWidget {
  final String purpose; // 'register' or 'verify'
  
  const SmartCameraScreen({Key? key, required this.purpose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Detect platform and use appropriate camera
    if (kIsWeb) {
      // Web platform - use desktop camera
      return RealDesktopCamera(purpose: purpose);
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platform - use mobile camera
      return MobileCameraScreen(purpose: purpose);
    } else {
      // Desktop platform - use desktop camera
      return RealDesktopCamera(purpose: purpose);
    }
  }
} 