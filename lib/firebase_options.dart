// lib/firebase_options.dart (수동 생성)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyAOwRKRj2nOFuM-tbdJsQQE-Pb-68xEsPw",
      authDomain: "iot-fall-prevention-new-v1.firebaseapp.com",
      projectId: "iot-fall-prevention-new-v1",
      storageBucket: "iot-fall-prevention-new-v1.firebasestorage.app",
      messagingSenderId: "658587234554",
      appId: "1:658587234554:web:3dc2f76e647c897d9a1943");
}
