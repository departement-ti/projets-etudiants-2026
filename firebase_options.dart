import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Options par défaut pour Firebase
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne supporte pas cette plateforme.',
        );
    }
  }

  // --- CONFIGURATION WEB (sur Chrome) ---
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBIURbTYq7CKDdy8dUzj_VRcrM34ncJodk',
    appId: '1:467464423636:web:82f1fc8652e4e4d4f59341',
    messagingSenderId: '467464423636',
    projectId: 'valortash',
    authDomain: 'valortash.firebaseapp.com',
    storageBucket: 'valortash.firebasestorage.app',
  );

  // --- CONFIGURATION ANDROID ( sur Emulateur) ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvxplamgBOPZcdWUT867wJy5Dd6Y7FtIQ',
    appId: '1:467464423636:android:5536e830a00310daf59341',
    messagingSenderId: '467464423636',
    projectId: 'valortash',
    storageBucket: 'valortash.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvxplamgBOPZcdWUT867wJy5Dd6Y7FtIQ',
    appId: '1:467464423636:android:5536e830a00310daf59341',
    messagingSenderId: '467464423636',
    projectId: 'valortash',
    storageBucket: 'valortash.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );
  
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDvxplamgBOPZcdWUT867wJy5Dd6Y7FtIQ',
    appId: '1:467464423636:android:5536e830a00310daf59341',
    messagingSenderId: '467464423636',
    projectId: 'valortash',
    storageBucket: 'valortash.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );
  
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDvxplamgBOPZcdWUT867wJy5Dd6Y7FtIQ',
    appId: '1:467464423636:android:5536e830a00310daf59341',
    messagingSenderId: '467464423636',
    projectId: 'valortash',
    storageBucket: 'valortash.firebasestorage.app',
  );
  
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDvxplamgBOPZcdWUT867wJy5Dd6Y7FtIQ',
    appId: '1:467464423636:android:5536e830a00310daf59341',
    messagingSenderId: '467464423636',
    projectId: 'valortash',
    storageBucket: 'valortash.firebasestorage.app',
  );
}