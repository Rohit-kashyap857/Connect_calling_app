import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyBLffbTEPyIhC1ptP79zSfXlKG1ZTe1-MQ',
    appId: '1:632545682579:web:11e97e8df523329faa1966',
    messagingSenderId: '632545682579',
    projectId: 'spotify-a4c66',
    authDomain: 'spotify-a4c66.firebaseapp.com',
    storageBucket: 'spotify-a4c66.firebasestorage.app',
    measurementId: 'G-EFX9Z2YYFT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsj3zCO4arM_pn67vr4i6hULp_HnINsOc',
    appId: '1:632545682579:android:ba263923e418d640aa1966',
    messagingSenderId: '632545682579',
    projectId: 'spotify-a4c66',
    storageBucket: 'spotify-a4c66.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArifxr_ZEx4p5vTLFjvinftxvIokTnA9s',
    appId: '1:632545682579:ios:19417b2769016b6caa1966',
    messagingSenderId: '632545682579',
    projectId: 'spotify-a4c66',
    storageBucket: 'spotify-a4c66.firebasestorage.app',
    iosBundleId: 'com.example.connectCall',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyArifxr_ZEx4p5vTLFjvinftxvIokTnA9s',
    appId: '1:632545682579:ios:19417b2769016b6caa1966',
    messagingSenderId: '632545682579',
    projectId: 'spotify-a4c66',
    storageBucket: 'spotify-a4c66.firebasestorage.app',
    iosBundleId: 'com.example.connectCall',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAGJYYkHYTcL9T15y95QcgyNhk1WnxaGgU',
    appId: '1:632545682579:web:bcca3573aea3cf6eaa1966',
    messagingSenderId: '632545682579',
    projectId: 'spotify-a4c66',
    authDomain: 'spotify-a4c66.firebaseapp.com',
    storageBucket: 'spotify-a4c66.firebasestorage.app',
    measurementId: 'G-JN4T24SQTD',
  );
}
