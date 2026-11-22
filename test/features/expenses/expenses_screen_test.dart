import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';
import 'package:final_project/data/repositories.dart';
import 'package:final_project/features/expenses/data/in_memory_expense_repository.dart';
import 'package:final_project/routes.dart';

void main() {
  late InMemoryExpenseRepository expenses;

  Future<void> openExpenses(WidgetTester tester) async {
    expenses = InMemoryExpenseRepository();
    await tester.pumpWidget(
      TripSyncApp(repositories: Repositories(expenses: expenses)),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(Routes.expenses, arguments: 'trip1');
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSave(
    WidgetTester tester,
    String description,
    String amount,
  ) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'What was it for?'),
      description,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Amount (€)'),
      amount,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty state', (tester) async {
    await openExpenses(tester);
    expect(find.text('No expenses yet.'), findsOneWidget);
  });

  testWidgets('adding an expense shows it in the list', (tester) async {
    await openExpenses(tester);
    await fillAndSave(tester, 'Tickets', '48');

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('€48'), findsOneWidget);
    expect(find.text('Paid by Test User'), findsOneWidget);
  });

  testWidgets('invalid input keeps the dialog open with an error', (
    tester,
  ) async {
    await openExpenses(tester);
    await fillAndSave(tester, 'Tickets', 'abc');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Enter an amount greater than 0, e.g. 48 or 12.50.'),
      findsOneWidget,
    );
  });

  testWidgets('shows expenses others add without reloading', (tester) async {
    await openExpenses(tester);
    await expenses.addExpense(
      tripId: 'trip1',
      description: 'Dinner',
      amountInCents: 3050,
      paidBy: 'u2',
      paidByName: 'Ben',
    );
    await tester.pumpAndSettle();

    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('€30.50'), findsOneWidget);
    expect(find.text('Paid by Ben'), findsOneWidget);
  });
}
