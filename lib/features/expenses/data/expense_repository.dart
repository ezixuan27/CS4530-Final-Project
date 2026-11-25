import '../../../models/expense.dart';

/// Data access for a trip's shared expenses (Story 8).
abstract class ExpenseRepository {
  /// The trip's expenses, newest first. Emits again whenever one is added,
  /// including by other trip members (10-second sync NFR).
  Stream<List<Expense>> watchExpenses(String tripId);

  Future<void> addExpense({
    required String tripId,
    required String description,
    required int amountInCents,
    required String paidBy,
    required String paidByName,
  });

  /// Changes an expense's description and amount; the payer stays the same.
  /// Throws if the expense doesn't exist.
  Future<void> updateExpense({
    required String tripId,
    required String expenseId,
    required String description,
    required int amountInCents,
  });
}
