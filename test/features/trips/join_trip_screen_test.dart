import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';
import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_trip_repository.dart';
import 'package:final_project/data/repositories.dart';
import 'package:final_project/models/trip.dart';

void main() {
  late InMemoryTripRepository trips;
  late Trip friendsTrip;

  Finder codeField() => find.widgetWithText(TextField, 'Invite code');
  Finder appBarTitle(String title) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(title));

  // signed in by default, so this starts on My Trips
  Future<void> openJoinTrip(WidgetTester tester) async {
    trips = InMemoryTripRepository();
    friendsTrip = await trips.createTrip(
      name: 'Lisbon Weekend',
      destination: 'Lisbon',
      startDate: DateTime(2027, 5, 1),
      endDate: DateTime(2027, 5, 3),
      organizerId: 'friend',
    );
    await tester.pumpWidget(
      TripSyncApp(repositories: Repositories(trips: trips)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Join Trip'));
    await tester.pumpAndSettle();
  }

  Future<void> join(WidgetTester tester, String code) async {
    await tester.enterText(codeField(), code);
    await tester.tap(find.widgetWithText(FilledButton, 'Join'));
    await tester.pumpAndSettle();
  }

  testWidgets('right code opens the trip, back goes to My Trips', (
    tester,
  ) async {
    await openJoinTrip(tester);
    await join(tester, friendsTrip.inviteCode.toLowerCase());

    expect(appBarTitle('Itinerary'), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.byType(Scaffold).last));
    expect(route?.settings.arguments, friendsTrip.id);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(appBarTitle('My Trips'), findsOneWidget);
    expect(find.text('Lisbon Weekend'), findsOneWidget);
  });

  testWidgets('unknown code shows an error and stays', (tester) async {
    await openJoinTrip(tester);
    await join(tester, 'ZZZZZZ');
    expect(find.text('No trip found with that code.'), findsOneWidget);
    expect(appBarTitle('Join Trip'), findsOneWidget);
    expect(await trips.tripsForUser(AuthService.testUser.id), isEmpty);
  });

  testWidgets('error goes away when you type', (tester) async {
    await openJoinTrip(tester);
    await join(tester, 'ZZZZZZ');
    await tester.enterText(codeField(), 'ZZZZZ');
    await tester.pump();
    expect(find.text('No trip found with that code.'), findsNothing);
  });

  testWidgets('empty code shows an error', (tester) async {
    await openJoinTrip(tester);
    await join(tester, '');
    expect(find.text('Enter an invite code.'), findsOneWidget);
  });

  testWidgets('only letters and numbers can be typed', (tester) async {
    await openJoinTrip(tester);
    await tester.enterText(codeField(), 'ab-c/1 2');
    await tester.pump();
    expect(find.text('abc12'), findsOneWidget);
  });
}
