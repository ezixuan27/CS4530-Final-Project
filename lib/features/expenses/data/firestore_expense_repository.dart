import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/expense.dart';
import 'expense_repository.dart';

/// Stores expenses in Firestore at `trips/{tripId}/expenses/{expenseId}`.
class FirestoreExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _db;

  FirestoreExpenseRepository(this._db);

  CollectionReference<Map<String, dynamic>> _collection(String tripId) =>
      _db.collection('trips').doc(tripId).collection('expenses');

  @override
  Stream<List<Expense>> watchExpenses(String tripId) => _collection(tripId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) _fromDoc(tripId, doc.id, doc.data()),
        ],
      );

  @override
  Future<void> addExpense({
    required String tripId,
    required String description,
    required int amountInCents,
    required String paidBy,
    required String paidByName,
  }) async {
    await _collection(tripId).add({
      'description': description,
      'amountInCents': amountInCents,
      'paidBy': paidBy,
      'paidByName': paidByName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Expense _fromDoc(String tripId, String id, Map<String, dynamic> data) {
    // createdAt is null locally until the server sets the timestamp.
    final createdAt = data['createdAt'] as Timestamp?;
    return Expense(
      id: id,
      tripId: tripId,
      description: data['description'] as String,
      amountInCents: data['amountInCents'] as int,
      paidBy: data['paidBy'] as String,
      paidByName: data['paidByName'] as String,
      createdAt: createdAt?.toDate() ?? DateTime.now(),
    );
  }
}
