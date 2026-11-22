import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/expenses/data/expense_repository.dart';
import '../features/expenses/data/firestore_expense_repository.dart';
import '../features/expenses/data/in_memory_expense_repository.dart';
import 'firestore_trip_repository.dart';
import 'in_memory_trip_repository.dart';
import 'trip_repository.dart';

/// Every repository the app uses, in one place. `app.dart` provides each one
/// so screens can `context.read<XRepository>()`.
///
/// - The real app uses [Repositories.firestore] (see `main.dart`).
/// - Tests use `Repositories()`, which fills every slot with the in-memory
///   version. Override just the ones a test cares about:
///   `Repositories(trips: seededTripRepo)`.
///
/// Adding your repository: see "Adding your Firestore repository" in the
/// README.
class Repositories {
  final TripRepository trips;
  final ExpenseRepository expenses;

  Repositories({TripRepository? trips, ExpenseRepository? expenses})
    : trips = trips ?? InMemoryTripRepository(),
      expenses = expenses ?? InMemoryExpenseRepository();

  /// The Firestore-backed versions. Call only after `Firebase.initializeApp`.
  factory Repositories.firestore() {
    final db = FirebaseFirestore.instance;
    return Repositories(
      trips: FirestoreTripRepository(firestore: db),
      expenses: FirestoreExpenseRepository(db),
    );
  }
}
