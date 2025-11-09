import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase 옵션 클래스
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      '현재 플랫폼은 지원되지 않습니다. Firebase 구성을 추가해주세요.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMs8Er9vK95okEIt_diWzbXaCEMtL8YsY',
    authDomain: 'project-eidos.firebaseapp.com',
    projectId: 'project-eidos',
    storageBucket: 'project-eidos.firebasestorage.app',
    messagingSenderId: '266795635550',
    appId: '1:266795635550:web:989235c1be0d3e2fcc75cf',
    measurementId: 'G-FGG9L7D5PQ',
  );
}

