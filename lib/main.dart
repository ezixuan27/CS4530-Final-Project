import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/firestore_trip_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // The real app uses Firestore. Tests build TripSyncApp with
  // InMemoryTripRepository, so they never touch the database.
  runApp(TripSyncApp(repository: FirestoreTripRepository()));
}
