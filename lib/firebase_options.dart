// File: lib/firebase_options.dart
// ignore_for_file: flutter_lints, avoid_web_libraries_in_flutter
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: "AIzaSyAX-0-Dfm-UU5KOo_RaYFBvRq6x6-NVOWg",
    appId: "1:382276671542:web:5dc33c854157c620662097",
    messagingSenderId: "382276671542",
    projectId: "duewise-app-bc53f",
    authDomain: "duewise-app-bc53f.firebaseapp.com",
    storageBucket: "duewise-app-bc53f.firebasestorage.app",
    measurementId: "G-2P7NNVZZ8P",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBwW9h-W7zb2iEfQpvt4RgXUtN5RsG4LWY",
    appId: "1:382276671542:android:25c20b0337934f86662097",
    messagingSenderId: "382276671542",
    projectId: "duewise-app-bc53f",
    storageBucket: "duewise-app-bc53f.firebasestorage.app",
  );
}
