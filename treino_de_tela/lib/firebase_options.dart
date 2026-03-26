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
    apiKey: 'AIzaSyAFOZURBmwtEihYIkV3RkM6Y7q7UEKJbr4',
    appId: '1:582584576199:web:b5d238295e1639b66a76e2',
    messagingSenderId: '582584576199',
    projectId: 'bancopi3',
    authDomain: 'bancopi3.firebaseapp.com',
    storageBucket: 'bancopi3.firebasestorage.app',
    measurementId: 'G-LZBN31SCMT',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBbFseb2qoFIuz3PfghKTP-3B7pUNam9Sc',
    appId: '1:582584576199:ios:a7c0e6ada5372d806a76e2',
    messagingSenderId: '582584576199',
    projectId: 'bancopi3',
    storageBucket: 'bancopi3.firebasestorage.app',
    iosBundleId: 'com.example.treinoDeTela',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBbFseb2qoFIuz3PfghKTP-3B7pUNam9Sc',
    appId: '1:582584576199:ios:a7c0e6ada5372d806a76e2',
    messagingSenderId: '582584576199',
    projectId: 'bancopi3',
    storageBucket: 'bancopi3.firebasestorage.app',
    iosBundleId: 'com.example.treinoDeTela',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0pAHA6shJd6WZONSqNgRN8NbtfSmxUb4',
    appId: '1:582584576199:android:908ea23dc4dd4ff96a76e2',
    messagingSenderId: '582584576199',
    projectId: 'bancopi3',
    storageBucket: 'bancopi3.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAFOZURBmwtEihYIkV3RkM6Y7q7UEKJbr4',
    appId: '1:582584576199:web:50f4fb0cbcfee6766a76e2',
    messagingSenderId: '582584576199',
    projectId: 'bancopi3',
    authDomain: 'bancopi3.firebaseapp.com',
    storageBucket: 'bancopi3.firebasestorage.app',
    measurementId: 'G-GRMMZYWVR7',
  );

}