// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyA4zO9Mo8bAmnQw6P0KvPDmrIPdNy6I9rc',
    appId: '1:969598559240:web:bd4fc74128e162a15d9dbd',
    messagingSenderId: '969598559240',
    projectId: 'globecast-df08c',
    authDomain: 'globecast-df08c.firebaseapp.com',
    storageBucket: 'globecast-df08c.firebasestorage.app',
    measurementId: 'G-LJXS7C1E2X',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXIz35r4IbKOOEMK6KboTILHov7I7KlfU',
    appId: '1:969598559240:android:ce9981245c6e4f285d9dbd',
    messagingSenderId: '969598559240',
    projectId: 'globecast-df08c',
    storageBucket: 'globecast-df08c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyARKixqt_Eyo1StX4uocHsSbmLPffbRMYc',
    appId: '1:969598559240:ios:4f5fdf5adcad0ca35d9dbd',
    messagingSenderId: '969598559240',
    projectId: 'globecast-df08c',
    storageBucket: 'globecast-df08c.firebasestorage.app',
    iosBundleId: 'com.example.globeCast',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA4zO9Mo8bAmnQw6P0KvPDmrIPdNy6I9rc',
    appId: '1:969598559240:web:657d36af954be5a75d9dbd',
    messagingSenderId: '969598559240',
    projectId: 'globecast-df08c',
    authDomain: 'globecast-df08c.firebaseapp.com',
    storageBucket: 'globecast-df08c.firebasestorage.app',
    measurementId: 'G-NXJ2FGVRY0',
  );
}
