import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/in_memory_trip_repository.dart';
import 'features/expenses/data/firestore_expense_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = FirebaseFirestore.instance;

  // Swap InMemoryTripRepository for a Firebase-backed one later.
  runApp(
    TripSyncApp(
      repository: InMemoryTripRepository(),
      expenseRepository: FirestoreExpenseRepository(db),
    ),
  );
}
