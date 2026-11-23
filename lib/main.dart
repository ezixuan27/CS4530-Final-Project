import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/firebase_auth_service.dart';
import 'data/repositories.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // wait for Firebase to restore a saved sign in, so we know which screen
  // to start on
  await FirebaseAuth.instance.authStateChanges().first;

  // The real app uses Firebase. Tests build TripSyncApp() without this, so
  // they get the in-memory versions and never touch Firebase.
  runApp(
    TripSyncApp(
      repositories: Repositories.firestore(),
      auth: FirebaseAuthService(),
    ),
  );
}
