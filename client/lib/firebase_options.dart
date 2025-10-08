// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      case TargetPlatform.macOS:   return ios;     // ok to reuse in dev
      case TargetPlatform.windows: return web;     // ok to reuse in dev
      case TargetPlatform.linux:   return web;     // ok to reuse in dev
      default:                     return web;
    }
  }

  // ---- Fill from Firebase Console Web config ----
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCjXE72mzUKRA8XrhLFwbWMQRaOMACsE_o',
    authDomain: 'servappbackend.firebaseapp.com',
    projectId: 'servappbackend',
    storageBucket: 'servappbackend.firebasestorage.app',
    messagingSenderId: '227341863889',
    appId: '1:227341863889:web:a2048ffeed9d39307e6ef0',
  );

  // Optional (fill later if you build these platforms)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.serv.yourbundle', // replace if you have one
  );
}
