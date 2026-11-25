import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/features/expenses/data/expense_repository.dart';
import 'package:final_project/features/expenses/data/firestore_expense_repository.dart';
import 'package:final_project/features/expenses/data/in_memory_expense_repository.dart';

/// Both implementations must behave the same, so the same tests run on each.
void main() {
  final implementations = <String, ExpenseRepository Function()>{
    'InMemoryExpenseRepository': InMemoryExpenseRepository.new,
    'FirestoreExpenseRepository': () =>
        FirestoreExpenseRepository(FakeFirebaseFirestore()),
  };

  implementations.forEach((name, create) {
    group(name, () {
      late ExpenseRepository repo;
      setUp(() => repo = create());

      Future<void> add(String tripId, String description, int cents) =>
          repo.addExpense(
            tripId: tripId,
            description: description,
            amountInCents: cents,
            paidBy: 'u2',
            paidByName: 'Ben',
          );

      test('starts with an empty list', () async {
        expect(await repo.watchExpenses('trip1').first, isEmpty);
      });

      test('added expense is stored with all fields', () async {
        await add('trip1', 'Tickets', 4800);

        final list = await repo.watchExpenses('trip1').first;
        expect(list, hasLength(1));
        final e = list.single;
        expect(e.id, isNotEmpty);
        expect(e.tripId, 'trip1');
        expect(e.description, 'Tickets');
        expect(e.amountInCents, 4800);
        expect(e.paidBy, 'u2');
        expect(e.paidByName, 'Ben');
      });

      test('only returns expenses for the requested trip', () async {
        await add('trip1', 'Tickets', 4800);
        await add('trip2', 'Dinner', 3000);

        final list = await repo.watchExpenses('trip1').first;
        expect(list.map((e) => e.description), ['Tickets']);
      });

      test('newest expense comes first', () async {
        await add('trip1', 'First', 100);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await add('trip1', 'Second', 200);

        final list = await repo.watchExpenses('trip1').first;
        expect(list.map((e) => e.description), ['Second', 'First']);
      });

      test(
        'watchers see expenses added after they started listening',
        () async {
          final emissions = <List<String>>[];
          final sub = repo
              .watchExpenses('trip1')
              .listen(
                (l) => emissions.add(l.map((e) => e.description).toList()),
              );
          await Future<void>.delayed(Duration.zero);

          await add('trip1', 'Tickets', 4800);
          await Future<void>.delayed(Duration.zero);

          expect(emissions.last, ['Tickets']);
          await sub.cancel();
        },
      );

      test('updateExpense changes description and amount only', () async {
        await add('trip1', 'Tickets', 4800);
        final before = (await repo.watchExpenses('trip1').first).single;

        await repo.updateExpense(
          tripId: 'trip1',
          expenseId: before.id,
          description: 'Museum tickets',
          amountInCents: 5000,
        );

        final after = (await repo.watchExpenses('trip1').first).single;
        expect(after.id, before.id);
        expect(after.description, 'Museum tickets');
        expect(after.amountInCents, 5000);
        expect(after.paidBy, 'u2');
        expect(after.paidByName, 'Ben');
      });

      test('updateExpense throws for a missing expense', () async {
        await expectLater(
          repo.updateExpense(
            tripId: 'trip1',
            expenseId: 'nope',
            description: 'X',
            amountInCents: 100,
          ),
          throwsA(anything),
        );
      });
    });
  });
}
