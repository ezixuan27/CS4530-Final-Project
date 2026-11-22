import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';
import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_trip_repository.dart';
import 'package:final_project/data/repositories.dart';

void main() {
  Future<InMemoryTripRepository> seededRepo() async {
    final repo = InMemoryTripRepository();
    final me = AuthService.testUser.id;
    await repo.createTrip(
      name: 'Italy Getaway',
      destination: 'Rome',
      startDate: DateTime(2027, 4, 10),
      endDate: DateTime(2027, 4, 18),
      organizerId: me,
    );
    final other = await repo.createTrip(
      name: 'Lisbon Weekend',
      destination: 'Lisbon',
      startDate: DateTime(2027, 5, 1),
      endDate: DateTime(2027, 5, 3),
      organizerId: 'someone-else',
    );
    await repo.joinTrip(other.inviteCode, me);
    await repo.createTrip(
      name: 'Not My Trip',
      destination: 'Oslo',
      startDate: DateTime(2027, 6, 1),
      endDate: DateTime(2027, 6, 3),
      organizerId: 'someone-else',
    );
    return repo;
  }

  Future<void> openMyTrips(
    WidgetTester tester,
    InMemoryTripRepository repo,
  ) async {
    await tester.pumpWidget(
      TripSyncApp(repositories: Repositories(trips: repo)),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();
  }

  testWidgets('My Trips lists trips the current user created or joined', (
    tester,
  ) async {
    await openMyTrips(tester, await seededRepo());

    expect(find.text('Italy Getaway'), findsOneWidget);
    expect(find.text('Lisbon Weekend'), findsOneWidget);
    expect(find.text('Not My Trip'), findsNothing);
    expect(find.textContaining('sample'), findsNothing);
  });

  testWidgets('tapping a trip opens its itinerary', (tester) async {
    await openMyTrips(tester, await seededRepo());

    await tester.tap(find.text('Italy Getaway'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Itinerary'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('My Trips shows an empty state with no trips', (tester) async {
    await openMyTrips(tester, InMemoryTripRepository());
    expect(
      find.text('No trips yet. Create one or join with a code.'),
      findsOneWidget,
    );
  });
}
