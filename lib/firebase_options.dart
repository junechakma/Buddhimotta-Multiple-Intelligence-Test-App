import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Generated from Firebase Console — buddhimotta-e7d07
// For Android/iOS: run `flutterfire configure` or fill in the TODOs below
// after adding your app in Firebase Console > Project Settings.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBR6jS-s_0hJeIO_HjAvIUw2iR1GruU96I',
    authDomain: 'buddhimotta-e7d07.firebaseapp.com',
    projectId: 'buddhimotta-e7d07',
    storageBucket: 'buddhimotta-e7d07.firebasestorage.app',
    messagingSenderId: '793434997793',
    appId: '1:793434997793:web:29e104d3c23a1f720b0f60',
    measurementId: 'G-0GWSPCNE71',
  );

  // TODO: Add Android app in Firebase Console, download google-services.json
  // to android/app/, then replace appId below.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBR6jS-s_0hJeIO_HjAvIUw2iR1GruU96I',
    appId: '1:793434997793:android:REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: '793434997793',
    projectId: 'buddhimotta-e7d07',
    storageBucket: 'buddhimotta-e7d07.firebasestorage.app',
  );

  // TODO: Add iOS app in Firebase Console, download GoogleService-Info.plist
  // to ios/Runner/, then replace appId and iosBundleId below.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBR6jS-s_0hJeIO_HjAvIUw2iR1GruU96I',
    appId: '1:793434997793:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '793434997793',
    projectId: 'buddhimotta-e7d07',
    storageBucket: 'buddhimotta-e7d07.firebasestorage.app',
    iosBundleId: 'com.example.buddhimotta',
  );
}
