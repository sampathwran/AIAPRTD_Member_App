// ==========================================
// FIREBASE OPTIONS CONFIGURATION
// ==========================================
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // 🌐 වෙබ් එකෙන් ඇප් එක රන් වෙද්දී මේ කීස් ටික වැඩ කරනවා
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // 🌐 WEB CONFIGURATION (උඹ දැන් බ්‍රවුසර් එකෙන් ගත්තු නිවැරදිම ටික 🎯)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCDBGrVPwHFh3gNs_AXY7o1lFfsBw_1B00',
    appId: '1:1012060339384:web:2d4cceffb2f8ed8dcac84d',
    messagingSenderId: '1012060339384',
    projectId: 'aiaprtd-member',
    authDomain: 'aiaprtd-member.firebaseapp.com',
    storageBucket: 'aiaprtd-member.firebasestorage.app',
    measurementId: 'G-YZ9MZ3LF8R',
  );

  // 🤖 ANDROID CONFIGURATION (අපි කලින් හොයාගත්ත ටික 🎯)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAHlq6b4elQt8tff-dhSSujgl7iaYA9Lsc',
    appId: '1:1012060339384:android:a21989d5cce6398ecac84d',
    messagingSenderId: '1012060339384',
    projectId: 'aiaprtd-member',
    storageBucket: 'aiaprtd-member.appspot.com',
  );
}