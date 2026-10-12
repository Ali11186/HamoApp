// File generated for the Ali Offers Firebase project.
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBDNfnSymqooU1TVMI3tUze6bqBw9rOdaE',
    appId: '1:1060700733682:android:d0d48eb33b4b46c49d906b',
    messagingSenderId: '1060700733682',
    projectId: 'ali-offer',
    storageBucket: 'ali-offer.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDNfnSymqooU1TVMI3tUze6bqBw9rOdaE',
    appId: '1:1060700733682:android:d0d48eb33b4b46c49d906b',
    messagingSenderId: '1060700733682',
    projectId: 'ali-offer',
    storageBucket: 'ali-offer.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDNfnSymqooU1TVMI3tUze6bqBw9rOdaE',
    appId: '1:1060700733682:android:d0d48eb33b4b46c49d906b',
    messagingSenderId: '1060700733682',
    projectId: 'ali-offer',
    storageBucket: 'ali-offer.firebasestorage.app',
    iosBundleId: 'com.mohammed.store',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBDNfnSymqooU1TVMI3tUze6bqBw9rOdaE',
    appId: '1:1060700733682:android:d0d48eb33b4b46c49d906b',
    messagingSenderId: '1060700733682',
    projectId: 'ali-offer',
    storageBucket: 'ali-offer.firebasestorage.app',
  );
}
