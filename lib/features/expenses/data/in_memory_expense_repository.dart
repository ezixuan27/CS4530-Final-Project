import 'dart:async';

import '../../../models/expense.dart';
import 'expense_repository.dart';

/// Fake for tests: data lives in memory and is lost on restart.
class InMemoryExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];
  final StreamController<void> _changes = StreamController.broadcast();
  int _nextId = 1;

  List<Expense> _forTrip(String tripId) {
    final list = _expenses.where((e) => e.tripId == tripId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Stream<List<Expense>> watchExpenses(String tripId) {
    // A controller (not async*) so cancelling the stream stops listening
    // to _changes right away.
    StreamSubscription<void>? changesSub;
    late final StreamController<List<Expense>> controller;
    controller = StreamController(
      onListen: () {
        controller.add(_forTrip(tripId));
        changesSub = _changes.stream.listen(
          (_) => controller.add(_forTrip(tripId)),
        );
      },
      onCancel: () => changesSub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> addExpense({
    required String tripId,
    required String description,
    required int amountInCents,
    required String paidBy,
    required String paidByName,
  }) async {
    _expenses.add(
      Expense(
        id: 'expense${_nextId++}',
        tripId: tripId,
        description: description,
        amountInCents: amountInCents,
        paidBy: paidBy,
        paidByName: paidByName,
        createdAt: DateTime.now(),
      ),
    );
    _changes.add(null);
  }
}
