// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAoFM53tNBpG-LQCg1bcMfP2DVLlo4Gx7M',
    appId: '1:398245586926:web:f2e89a74abc32214b590ff',
    messagingSenderId: '398245586926',
    projectId: 'db-fix',
    authDomain: 'db-fix.firebaseapp.com',
    storageBucket: 'db-fix.appspot.com',
    measurementId: 'G-54620XME2R',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAxLpEqDzqESiI5T3Xod8zk7TGuDDNnEH8',
    appId: '1:398245586926:android:4ca927a566287ac6b590ff',
    messagingSenderId: '398245586926',
    projectId: 'db-fix',
    storageBucket: 'db-fix.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBT-F1xyJRRBF4MlehNdOnIvBHMEKV2dXE',
    appId: '1:398245586926:ios:83018cb75c4ec7d7b590ff',
    messagingSenderId: '398245586926',
    projectId: 'db-fix',
    storageBucket: 'db-fix.appspot.com',
    iosBundleId: 'com.example.darkTodo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBT-F1xyJRRBF4MlehNdOnIvBHMEKV2dXE',
    appId: '1:398245586926:ios:83018cb75c4ec7d7b590ff',
    messagingSenderId: '398245586926',
    projectId: 'db-fix',
    storageBucket: 'db-fix.appspot.com',
    iosBundleId: 'com.example.darkTodo',
  );
}
