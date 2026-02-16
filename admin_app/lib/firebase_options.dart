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
    apiKey: 'AIzaSyDemoKey123456789012345678901234',
    appId: '1:123456789012:web:abcdef1234567892',
    messagingSenderId: '123456789012',
    projectId: 'fish-market-demo',
    authDomain: 'fish-market-demo.firebaseapp.com',
    storageBucket: 'fish-market-demo.appspot.com',
    measurementId: 'G-MEASUREMENT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey123456789012345678901234',
    appId: '1:123456789012:android:abcdef1234567892',
    messagingSenderId: '123456789012',
    projectId: 'fish-market-demo',
    storageBucket: 'fish-market-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey123456789012345678901234',
    appId: '1:123456789012:ios:abcdef1234567892',
    messagingSenderId: '123456789012',
    projectId: 'fish-market-demo',
    storageBucket: 'fish-market-demo.appspot.com',
    iosBundleId: 'com.fishmarket.adminapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey123456789012345678901234',
    appId: '1:123456789012:ios:abcdef1234567892',
    messagingSenderId: '123456789012',
    projectId: 'fish-market-demo',
    storageBucket: 'fish-market-demo.appspot.com',
    iosBundleId: 'com.fishmarket.adminapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey123456789012345678901234',
    appId: '1:123456789012:web:abcdef1234567892',
    messagingSenderId: '123456789012',
    projectId: 'fish-market-demo',
    authDomain: 'fish-market-demo.firebaseapp.com',
    storageBucket: 'fish-market-demo.appspot.com',
    measurementId: 'G-MEASUREMENT',
  );
}
