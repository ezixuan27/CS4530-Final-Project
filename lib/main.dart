import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // The real app uses Firestore. Tests build TripSyncApp() without this, so
  // they get the in-memory repositories and never touch the database.
  runApp(TripSyncApp(repositories: Repositories.firestore()));
}
