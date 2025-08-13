import 'package:flutter/material.dart';

class ImageService {
  // Placeholder images for missing assets
  static const String placeholderAvatar = 'https://via.placeholder.com/100x100/4CAF50/FFFFFF?text=User';
  static const String placeholderClock = 'https://via.placeholder.com/50x50/2196F3/FFFFFF?text=Time';
  
  // Get avatar image with fallback
  static String getAvatarImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return placeholderAvatar;
    }
    return imagePath;
  }
  
  // Get clock image with fallback
  static String getClockImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return placeholderClock;
    }
    return imagePath;
  }
  
  // Check if image exists
  static bool imageExists(String? imagePath) {
    return imagePath != null && imagePath.isNotEmpty;
  }
} 