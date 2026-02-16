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
    apiKey: 'AIzaSyCy-AfEXeselSilJVGkRqJKv6RcoEhu3to',
    appId: '1:253929981076:web:b917b17159bd6196c86081',
    messagingSenderId: '253929981076',
    projectId: 'planning-with-ai-3f007',
    authDomain: 'planning-with-ai-3f007.firebaseapp.com',
    storageBucket: 'planning-with-ai-3f007.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9aLWF8C82HR27HAgbcssMiV4AimmuWwk',
    appId: '1:253929981076:android:76d9db8d6915ebf7c86081',
    messagingSenderId: '253929981076',
    projectId: 'planning-with-ai-3f007',
    storageBucket: 'planning-with-ai-3f007.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyABbJnDnskVUhZSKXyOjDK083fIzSvDEk4',
    appId: '1:253929981076:ios:77e1c954a0e91f39c86081',
    messagingSenderId: '253929981076',
    projectId: 'planning-with-ai-3f007',
    storageBucket: 'planning-with-ai-3f007.firebasestorage.app',
    iosBundleId: 'com.example.adminApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyABbJnDnskVUhZSKXyOjDK083fIzSvDEk4',
    appId: '1:253929981076:ios:77e1c954a0e91f39c86081',
    messagingSenderId: '253929981076',
    projectId: 'planning-with-ai-3f007',
    storageBucket: 'planning-with-ai-3f007.firebasestorage.app',
    iosBundleId: 'com.example.adminApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCy-AfEXeselSilJVGkRqJKv6RcoEhu3to',
    appId: '1:253929981076:web:b917b17159bd6196c86081',
    messagingSenderId: '253929981076',
    projectId: 'planning-with-ai-3f007',
    authDomain: 'planning-with-ai-3f007.firebaseapp.com',
    storageBucket: 'planning-with-ai-3f007.firebasestorage.app',
  );

}