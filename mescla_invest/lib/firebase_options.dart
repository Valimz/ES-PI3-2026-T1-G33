import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAY_pcQLgPuzkH-vlSAVYSLCJac6FsG6hg',
    appId: '1:969947583204:web:34e6220cd02660cdb092f1',
    messagingSenderId: '969947583204',
    projectId: 'projetointegrador-13b6e',
    authDomain: 'projetointegrador-13b6e.firebaseapp.com',
    storageBucket: 'projetointegrador-13b6e.firebasestorage.app',
    measurementId: 'G-GBNV77JBL1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBu6HdYRqulJDwv09cpOFu0Yyel8O5YaFc',
    appId: '1:969947583204:ios:f73ec6d10f51ee0ab092f1',
    messagingSenderId: '969947583204',
    projectId: 'projetointegrador-13b6e',
    storageBucket: 'projetointegrador-13b6e.firebasestorage.app',
    iosBundleId: 'com.example.treinoDeTela',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBu6HdYRqulJDwv09cpOFu0Yyel8O5YaFc',
    appId: '1:969947583204:ios:f73ec6d10f51ee0ab092f1',
    messagingSenderId: '969947583204',
    projectId: 'projetointegrador-13b6e',
    storageBucket: 'projetointegrador-13b6e.firebasestorage.app',
    iosBundleId: 'com.example.treinoDeTela',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVJV96pu6Ib4LUMRD6C4-yYcRv-n3mhhc',
    appId: '1:969947583204:android:54bbb6db1224c39ab092f1',
    messagingSenderId: '969947583204',
    projectId: 'projetointegrador-13b6e',
    storageBucket: 'projetointegrador-13b6e.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAY_pcQLgPuzkH-vlSAVYSLCJac6FsG6hg',
    appId: '1:969947583204:web:d0ec463c83da05f3b092f1',
    messagingSenderId: '969947583204',
    projectId: 'projetointegrador-13b6e',
    authDomain: 'projetointegrador-13b6e.firebaseapp.com',
    storageBucket: 'projetointegrador-13b6e.firebasestorage.app',
    measurementId: 'G-ZVTRCB6JB6',
  );

}