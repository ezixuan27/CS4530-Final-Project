import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/auth_service.dart';
import 'package:final_project/features/expenses/data/in_memory_expense_repository.dart';
import 'package:final_project/features/expenses/view_models/expense_view_model.dart';

void main() {
  group('parseAmountToCents', () {
    final cases = <String, int?>{
      '48': 4800,
      '48.5': 4850,
      '48.50': 4850,
      '0.05': 5,
      ' 12 ': 1200,
      '1,000': null,
      '0': null,
      '0.00': null,
      '-1': null,
      'abc': null,
      '': null,
      '48.555': null,
      '.5': null,
    };
    cases.forEach((input, expected) {
      test('"$input" -> $expected', () {
        expect(ExpenseViewModel.parseAmountToCents(input), expected);
      });
    });
  });

  test('formatCents shows whole euros without decimals', () {
    expect(ExpenseViewModel.formatCents(4800), '€48');
    expect(ExpenseViewModel.formatCents(4850), '€48.50');
    expect(ExpenseViewModel.formatCents(5), '€0.05');
  });

  group('ExpenseViewModel', () {
    late InMemoryExpenseRepository repo;
    late ExpenseViewModel vm;

    setUp(() {
      repo = InMemoryExpenseRepository();
      vm = ExpenseViewModel(
        repository: repo,
        auth: AuthService(),
        tripId: 'trip1',
      );
    });

    tearDown(() => vm.dispose());

    test('starts loading, then shows the empty list', () async {
      // Fresh VM: setUp's VM already got its first emission before the test.
      final fresh = ExpenseViewModel(
        repository: repo,
        auth: AuthService(),
        tripId: 'trip1',
      );
      expect(fresh.isLoading, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(fresh.isLoading, isFalse);
      expect(fresh.expenses, isEmpty);
      fresh.dispose();
    });

    test('addExpense saves with the current user as payer', () async {
      final error = await vm.addExpense(description: ' Tickets ', amount: '48');
      await Future<void>.delayed(Duration.zero);

      expect(error, isNull);
      final e = vm.expenses.single;
      expect(e.description, 'Tickets');
      expect(e.amountInCents, 4800);
      expect(e.paidBy, AuthService.testUser.id);
      expect(e.paidByName, AuthService.testUser.name);
    });

    test('addExpense rejects an empty description', () async {
      final error = await vm.addExpense(description: '  ', amount: '48');
      expect(error, 'Enter what the expense was for.');
      expect(await repo.watchExpenses('trip1').first, isEmpty);
    });

    test('addExpense rejects an invalid amount', () async {
      final error = await vm.addExpense(description: 'Tickets', amount: '0');
      expect(error, 'Enter an amount greater than 0, e.g. 48 or 12.50.');
      expect(await repo.watchExpenses('trip1').first, isEmpty);
    });

    test('shows expenses added by someone else without reloading', () async {
      await Future<void>.delayed(Duration.zero);
      await repo.addExpense(
        tripId: 'trip1',
        description: 'Dinner',
        amountInCents: 3000,
        paidBy: 'u2',
        paidByName: 'Ben',
      );
      await Future<void>.delayed(Duration.zero);

      expect(vm.expenses.map((e) => e.description), ['Dinner']);
    });
  });
}
