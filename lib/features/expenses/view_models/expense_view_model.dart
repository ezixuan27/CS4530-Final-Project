import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/auth_service.dart';
import '../../../models/expense.dart';
import '../data/expense_repository.dart';

/// State and logic for a trip's Expenses screen (Story 8).
class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository;
  final AuthService _auth;
  final String tripId;

  late final StreamSubscription<List<Expense>> _subscription;
  bool _isLoading = true;
  bool _isSaving = false;
  List<Expense> _expenses = const [];

  /// Starts listening to the trip's expenses right away, once.
  ExpenseViewModel({
    required this._repository,
    required this._auth,
    required this.tripId,
  }) {
    _subscription = _repository.watchExpenses(tripId).listen((expenses) {
      _expenses = expenses;
      _isLoading = false;
      notifyListeners();
    });
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  /// Newest first.
  List<Expense> get expenses => _expenses;

  /// Saves an expense paid by the current user.
  /// Returns an error message to show, or null on success.
  Future<String?> addExpense({
    required String description,
    required String amount,
  }) async {
    final trimmed = description.trim();
    if (trimmed.isEmpty) return 'Enter what the expense was for.';
    final cents = parseAmountToCents(amount);
    if (cents == null) {
      return 'Enter an amount greater than 0, e.g. 48 or 12.50.';
    }

    final user = _auth.currentUser;
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.addExpense(
        tripId: tripId,
        description: trimmed,
        amountInCents: cents,
        paidBy: user.id,
        paidByName: user.name,
      );
      return null;
    } catch (_) {
      return 'Could not save the expense. Try again.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// "48" -> 4800, "12.5" -> 1250. Null if not a positive amount with at
  /// most two decimals. Parses digits directly to avoid float rounding.
  static int? parseAmountToCents(String input) {
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(input.trim());
    if (match == null) return null;
    final euros = int.parse(match.group(1)!);
    final cents = int.parse((match.group(2) ?? '0').padRight(2, '0'));
    final total = euros * 100 + cents;
    return total > 0 ? total : null;
  }

  /// 4800 -> "€48", 4850 -> "€48.50".
  static String formatCents(int cents) {
    final euros = cents ~/ 100;
    final rest = cents % 100;
    return rest == 0 ? '€$euros' : '€$euros.${rest.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
