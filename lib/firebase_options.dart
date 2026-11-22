// Firebase config for the CS4530FinalProject Firebase project.
// Same shape `flutterfire configure` generates; values come from
// ios/Runner/GoogleService-Info.plist. The app is iOS only.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are only configured for iOS. '
      'Run `flutterfire configure` to add another platform.',
    );
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-xmBBPsUYtYJo_ohpMXICERCCaQHwtpc',
    appId: '1:384347571838:ios:0c8b2fc6f9ad574377ba2f',
    messagingSenderId: '384347571838',
    projectId: 'cs4530finalproject',
    storageBucket: 'cs4530finalproject.firebasestorage.app',
    iosBundleId: 'com.example.finalProject',
  );
}
